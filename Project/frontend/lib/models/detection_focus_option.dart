enum DetectionFocusOption { strict, balanced }

extension DetectionFocusOptionLabel on DetectionFocusOption {
  String get label {
    switch (this) {
      case DetectionFocusOption.strict:
        return 'Strict';
      case DetectionFocusOption.balanced:
        return 'Balanced';
    }
  }

  String get apiValue {
    switch (this) {
      case DetectionFocusOption.strict:
        return 'strict';
      case DetectionFocusOption.balanced:
        return 'balanced';
    }
  }
}
