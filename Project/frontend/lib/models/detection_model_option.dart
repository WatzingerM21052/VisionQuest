/// Verfügbare Detection-Models für Object-Recognition.
///
/// - [yolo]: YOLO11 Model (schnell, akkurat)
/// - [cocoSsd]: COCO-SSD Model (alternative, nicht implementiert)
enum DetectionModelOption { yolo, cocoSsd }

/// Extension für [DetectionModelOption] zur Anzeige von Model-Namen.
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
