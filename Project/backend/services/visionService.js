const tf = require('@tensorflow/tfjs-node');
const mobilenet = require('@tensorflow-models/mobilenet');

let modelPromise = null;

async function loadModel() {
    if (!modelPromise) {
        modelPromise = mobilenet.load();
    }
    return modelPromise;
}

async function detectImage(buffer) {
    const model = await loadModel();
    const imageTensor = tf.node.decodeImage(buffer, 3);

    try {
        const predictions = await model.classify(imageTensor);

        if (!predictions || predictions.length === 0) {
            return {
                label: 'unknown',
                confidence: 0,
                predictions: []
            };
        }

        const top = predictions[0];
        return {
            label: top.className,
            confidence: top.probability,
            predictions
        };
    } finally {
        imageTensor.dispose();
    }
}

module.exports = {
    detectImage
};
