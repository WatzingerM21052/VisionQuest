const tf = require('@tensorflow/tfjs');
const cocoSsd = require('@tensorflow-models/coco-ssd');
const Jimp = require('jimp');
const fs = require('fs/promises');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

let modelPromise = null;

const MAX_IMAGE_SIDE = 960;
const FOCUS_RADIUS_RATIO = 0.31;
const YOLO_CONFIDENCE = 0.22;

const yoloScriptPath = path.join(__dirname, 'yolo_detect.py');

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

function parsePythonCommand() {
    const configured = process.env.VISION_PYTHON_CMD;
    if (configured && configured.trim().length > 0) {
        const [cmd, ...args] = configured.trim().split(/\s+/);
        return [{ cmd, args }];
    }

    return [
        { cmd: 'py', args: ['-3'] },
        { cmd: 'python', args: [] },
        { cmd: 'python3', args: [] }
    ];
}

function runProcess(command, args) {
    return new Promise((resolve, reject) => {
        const child = spawn(command, args, { windowsHide: true });
        let stdout = '';
        let stderr = '';

        child.stdout.on('data', (chunk) => {
            stdout += chunk.toString();
        });

        child.stderr.on('data', (chunk) => {
            stderr += chunk.toString();
        });

        child.on('error', (error) => reject(error));
        child.on('close', (code) => {
            if (code === 0) {
                resolve({ stdout, stderr, code });
                return;
            }
            reject(new Error(stderr || `Process exited with code ${code}`));
        });
    });
}

async function detectWithYolo(imagePath) {
    const pythonCommands = parsePythonCommand();
    let lastError = null;

    for (const candidate of pythonCommands) {
        try {
            const { stdout } = await runProcess(
                candidate.cmd,
                [...candidate.args, yoloScriptPath, imagePath]
            );

            const parsed = JSON.parse(stdout || '{}');
            if (parsed.error) {
                throw new Error(parsed.error);
            }

            return parsed.predictions || [];
        } catch (error) {
            lastError = error;
        }
    }

    throw lastError || new Error('YOLO konnte nicht gestartet werden.');
}

function preprocessImage(image) {
    if (typeof image.exifRotate === 'function') {
        image.exifRotate();
    }

    const scale = Math.min(
        MAX_IMAGE_SIDE / image.bitmap.width,
        MAX_IMAGE_SIDE / image.bitmap.height,
        1
    );

    const targetWidth = Math.max(1, Math.round(image.bitmap.width * scale));
    const targetHeight = Math.max(1, Math.round(image.bitmap.height * scale));
    image.resize(targetWidth, targetHeight, Jimp.RESIZE_BILINEAR);
}

function createFocusCrop(image, focusMode = 'balanced') {
    const { width, height } = image.bitmap;
    const shortestSide = Math.min(width, height);
    const circleRadius = Math.max(1, shortestSide * FOCUS_RADIUS_RATIO);
    const contextScale = focusMode === 'strict' ? 1.35 : 1.85;
    const contextDiameter = Math.min(shortestSide, circleRadius * 2 * contextScale);

    const centerX = width / 2;
    const centerY = height / 2;
    const cropSize = Math.max(1, Math.round(contextDiameter));
    const cropX = Math.max(0, Math.round(centerX - cropSize / 2));
    const cropY = Math.max(0, Math.round(centerY - cropSize / 2));

    const boundedCropX = Math.min(cropX, Math.max(0, width - cropSize));
    const boundedCropY = Math.min(cropY, Math.max(0, height - cropSize));
    const boundedCropSize = Math.min(cropSize, width - boundedCropX, height - boundedCropY);

    const crop = image.clone().crop(
        boundedCropX,
        boundedCropY,
        boundedCropSize,
        boundedCropSize
    );

    return {
        crop,
        circle: {
            cx: boundedCropSize / 2,
            cy: boundedCropSize / 2,
            radius: Math.min(circleRadius, boundedCropSize / 2)
        }
    };
}

function rectIntersectsCircle(bbox, circle) {
    const [x, y, w, h] = bbox;
    const closestX = Math.max(x, Math.min(circle.cx, x + w));
    const closestY = Math.max(y, Math.min(circle.cy, y + h));
    const dx = closestX - circle.cx;
    const dy = closestY - circle.cy;
    return (dx * dx + dy * dy) <= (circle.radius * circle.radius);
}

function normalizeYoloPredictions(predictions, circle) {
    return predictions
        .map((prediction) => {
            const [x1, y1, x2, y2] = prediction.xyxy || [];
            if ([x1, y1, x2, y2].some((value) => typeof value !== 'number')) {
                return null;
            }

            const width = Math.max(0, x2 - x1);
            const height = Math.max(0, y2 - y1);

            return {
                className: prediction.className || 'unknown',
                probability: Number(prediction.confidence) || 0,
                bbox: [x1, y1, width, height],
                source: 'yolo'
            };
        })
        .filter(Boolean)
        .filter((prediction) => prediction.probability >= YOLO_CONFIDENCE)
        .filter((prediction) => rectIntersectsCircle(prediction.bbox, circle))
        .sort((a, b) => b.probability - a.probability);
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

async function detectImage(buffer, options = {}) {
    const preferredModel = (options.preferredModel || 'yolo').toLowerCase();
    const focusMode = (options.focusMode || 'balanced').toLowerCase();

    try {
        const image = await Jimp.read(buffer);
        preprocessImage(image);
        const { crop, circle } = createFocusCrop(image, focusMode);

        let yoloPredictions = [];
        let yoloError = null;

        if (preferredModel === 'yolo') {
            const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'visionquest-yolo-'));
            const tempImagePath = path.join(tempDir, 'focus.jpg');

            try {
                await crop.quality(90).writeAsync(tempImagePath);
                const rawPredictions = await detectWithYolo(tempImagePath);
                yoloPredictions = normalizeYoloPredictions(rawPredictions, circle);
            } catch (error) {
                yoloError = error;
                console.warn('[VISION] YOLO failed, fallback to COCO-SSD:', error.message);
            } finally {
                await fs.rm(tempDir, { recursive: true, force: true });
            }
        }

        if (preferredModel === 'yolo' && yoloPredictions.length > 0) {
            const top = yoloPredictions[0];
            return {
                label: top.className,
                confidence: Math.round(top.probability * 100) / 100,
                predictions: yoloPredictions.slice(0, 8).map((prediction) => ({
                    className: prediction.className,
                    probability: Math.round(prediction.probability * 100) / 100,
                    bbox: prediction.bbox,
                    source: prediction.source
                }))
            };
        }

        let model;
        try {
            model = await loadModel();
        } catch (error) {
            return {
                label: 'Model konnte nicht geladen werden',
                confidence: 0,
                predictions: [],
                error: yoloError ? `${yoloError.message}; ${error.message}` : error.message
            };
        }

        const cocoPredictions = await detectOnImage(model, crop);
        const filtered = cocoPredictions
            .filter((prediction) => prediction.score > 0.24)
            .map((prediction) => ({
                className: prediction.class,
                probability: prediction.score,
                bbox: prediction.bbox,
                source: 'coco'
            }))
            .filter((prediction) => rectIntersectsCircle(prediction.bbox, circle))
            .sort((a, b) => b.probability - a.probability);

        if (filtered.length === 0) {
            return {
                label: 'Keine Objekte erkannt',
                confidence: 0,
                predictions: [],
                error: yoloError ? `YOLO unavailable: ${yoloError.message}` : undefined
            };
        }

        const top = filtered[0];

        return {
            label: top.className,
            confidence: Math.round(top.probability * 100) / 100,
            predictions: filtered.slice(0, 8).map(p => ({
                className: p.className,
                probability: Math.round(p.probability * 100) / 100,
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
