/// Verfügbare Detection-Focus Modi für Object-Recognition.
///
/// - [strict]: Strenger Modus (höhere Confidence-Schwelle)
/// - [balanced]: Ausgeglichener Modus (Standard-Schwelle)
enum DetectionFocusOption { strict, balanced }

/// Extension für [DetectionFocusOption] zur Anzeige von Focus-Namen.
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
