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

        // Resize to 416x416 (good size for COCO-SSD)
        image.resize(416, 416);

        // Convert Jimp image to tensor3d
        const pixels = image.bitmap.data;
        const rgbPixels = [];

        // Convert RGBA to RGB
        for (let i = 0; i < pixels.length; i += 4) {
            rgbPixels.push(pixels[i]);     // R
            rgbPixels.push(pixels[i + 1]); // G
            rgbPixels.push(pixels[i + 2]); // B
        }

        // Create tensor from image data - COCO-SSD expects int32 with values 0-255
        const imageTensor = tf.tidy(() => {
            return tf.tensor3d(
                rgbPixels,
                [416, 416, 3],
                'int32'
            );
        });

        try {
            // COCO-SSD API: detect() method returns predictions
            const predictions = await model.detect(imageTensor);

            if (!predictions || predictions.length === 0) {
                return {
                    label: 'Keine Objekte erkannt',
                    confidence: 0,
                    predictions: []
                };
            }

            // Filter by confidence threshold and sort
            const filtered = predictions
                .filter(p => p.score > 0.3)
                .sort((a, b) => b.score - a.score);

            if (filtered.length === 0) {
                return {
                    label: 'Keine Objekte erkannt',
                    confidence: 0,
                    predictions: []
                };
            }

            // Get top prediction
            const top = filtered[0];

            return {
                label: top.class,
                confidence: Math.round(top.score * 100) / 100,
                predictions: filtered.map(p => ({
                    className: p.class,
                    probability: Math.round(p.score * 100) / 100,
                    bbox: p.bbox  // [x, y, width, height]
                }))
            };
        } finally {
            imageTensor.dispose();
        }
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
