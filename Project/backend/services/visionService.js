const tf = require('@tensorflow/tfjs');
const cocoSsd = require('@tensorflow-models/coco-ssd');
const Jimp = require('jimp');

let modelPromise = null;

async function loadModel() {
    if (!modelPromise) {
        console.log('[VISION] Loading COCO-SSD model...');
        try {
            modelPromise = cocoSsd.load();
            const model = await modelPromise;
            console.log('[VISION] COCO-SSD model loaded successfully');
        } catch (error) {
            console.error('[VISION] Failed to load model:', error.message);
            modelPromise = null;
            throw error;
        }
    }
    return modelPromise;
}

function jimpToTensor(image) {
    const pixels = image.bitmap.data;
    const rgbPixels = [];

    for (let i = 0; i < pixels.length; i += 4) {
        rgbPixels.push(pixels[i]);
        rgbPixels.push(pixels[i + 1]);
        rgbPixels.push(pixels[i + 2]);
    }

    return tf.tensor3d(
        rgbPixels,
        [image.bitmap.height, image.bitmap.width, 3],
        'int32'
    );
}

async function detectOnImage(model, image) {
    const imageTensor = tf.tidy(() => jimpToTensor(image));
    try {
        return await model.detect(imageTensor);
    } finally {
        imageTensor.dispose();
    }
}

function mergePredictions(fullPredictions, centerPredictions) {
    const byClass = new Map();

    for (const prediction of fullPredictions) {
        const existing = byClass.get(prediction.class);
        if (!existing || prediction.score > existing.score) {
            byClass.set(prediction.class, {
                ...prediction,
                score: prediction.score,
                source: 'full'
            });
        }
    }

    for (const prediction of centerPredictions) {
        const boosted = Math.min(0.99, prediction.score + 0.08);
        const existing = byClass.get(prediction.class);
        if (!existing || boosted > existing.score) {
            byClass.set(prediction.class, {
                ...prediction,
                score: boosted,
                source: 'center'
            });
        }
    }

    return Array.from(byClass.values()).sort((a, b) => b.score - a.score);
}

async function detectImage(buffer) {
    let model;

    try {
        model = await loadModel();
    } catch (error) {
        return {
            label: 'Model konnte nicht geladen werden',
            confidence: 0,
            predictions: [],
            error: error.message
        };
    }

    try {
        // Decode image buffer using Jimp
        const image = await Jimp.read(buffer);

        if (typeof image.exifRotate === 'function') {
            image.exifRotate();
        }

        // Preserve aspect ratio for better detection quality
        const maxSide = 640;
        const scale = Math.min(maxSide / image.bitmap.width, maxSide / image.bitmap.height, 1);
        const targetWidth = Math.max(1, Math.round(image.bitmap.width * scale));
        const targetHeight = Math.max(1, Math.round(image.bitmap.height * scale));
        image.resize(targetWidth, targetHeight, Jimp.RESIZE_BILINEAR);

        const centerCrop = image.clone();
        const cropSize = Math.max(1, Math.round(Math.min(targetWidth, targetHeight) * 0.72));
        const cropX = Math.max(0, Math.floor((targetWidth - cropSize) / 2));
        const cropY = Math.max(0, Math.floor((targetHeight - cropSize) / 2));
        centerCrop.crop(cropX, cropY, cropSize, cropSize);

        const [fullPredictions, centerPredictions] = await Promise.all([
            detectOnImage(model, image),
            detectOnImage(model, centerCrop)
        ]);

        const merged = mergePredictions(fullPredictions || [], centerPredictions || []);
        const filtered = merged.filter(p => p.score > 0.22);

        if (filtered.length === 0) {
            return {
                label: 'Keine Objekte erkannt',
                confidence: 0,
                predictions: []
            };
        }

        const top = filtered[0];

        return {
            label: top.class,
            confidence: Math.round(top.score * 100) / 100,
            predictions: filtered.slice(0, 8).map(p => ({
                className: p.class,
                probability: Math.round(p.score * 100) / 100,
                bbox: p.bbox,
                source: p.source
            }))
        };
    } catch (error) {
        console.error('[VISION] Detection error:', error.message);
        return {
            label: 'Fehler bei Erkennung',
            confidence: 0,
            predictions: [],
            error: error.message
        };
    }
}

module.exports = {
    detectImage
};
