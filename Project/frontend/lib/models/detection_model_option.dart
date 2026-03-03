enum DetectionModelOption { yolo, cocoSsd }

extension DetectionModelOptionLabel on DetectionModelOption {
  String get label {
    switch (this) {
      case DetectionModelOption.yolo:
        return 'YOLO';
      case DetectionModelOption.cocoSsd:
        return 'COCO-SSD';
    }
  }

  String get apiValue {
    switch (this) {
      case DetectionModelOption.yolo:
        return 'yolo';
      case DetectionModelOption.cocoSsd:
        return 'coco';
    }
  }
}
