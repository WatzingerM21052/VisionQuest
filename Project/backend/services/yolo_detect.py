import json
import importlib
import os
import sys


def main() -> int:
    if len(sys.argv) < 2:
        print(json.dumps({"error": "IMAGE_PATH_MISSING"}))
        return 1

    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(json.dumps({"error": "IMAGE_NOT_FOUND"}))
        return 1

    try:
        ultralytics_module = importlib.import_module("ultralytics")
        YOLO = getattr(ultralytics_module, "YOLO")
    except Exception as error:
        print(json.dumps({"error": f"ULTRALYTICS_IMPORT_FAILED: {error}"}))
        return 1

    model_name = os.getenv("VISION_YOLO_MODEL", "yolo11n.pt")
    conf = float(os.getenv("VISION_YOLO_CONF", "0.20"))
    imgsz = int(os.getenv("VISION_YOLO_IMGSZ", "640"))

    try:
        model = YOLO(model_name)
        results = model.predict(
            source=image_path,
            conf=conf,
            imgsz=imgsz,
            verbose=False,
        )

        if not results:
            print(json.dumps({"predictions": []}))
            return 0

        result = results[0]
        names = result.names
        predictions = []

        for box in result.boxes:
            cls_idx = int(box.cls[0].item())
            confidence = float(box.conf[0].item())
            x1, y1, x2, y2 = box.xyxy[0].tolist()
            class_name = names.get(cls_idx, str(cls_idx)) if isinstance(names, dict) else names[cls_idx]

            predictions.append(
                {
                    "className": class_name,
                    "confidence": confidence,
                    "xyxy": [x1, y1, x2, y2],
                }
            )

        print(json.dumps({"predictions": predictions}))
        return 0
    except Exception as error:
        print(json.dumps({"error": f"YOLO_INFERENCE_FAILED: {error}"}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
