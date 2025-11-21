/// Physical position of a camera lens.
enum CameraLensPosition { front, back, unspecified, external }

/// High-level category mapped from the native lens type.
enum CameraLensCategory {
  wide,
  ultraWide,
  telephoto,
  trueDepth,
  dual,
  triple,
  continuity,
  external,
  unknown,
}

/// Metadata describing a camera lens exposed by the plugin.
class CameraLensDescriptor {
  CameraLensDescriptor({
    required this.id,
    required this.name,
    required this.position,
    required this.category,
    this.supportsFocus = false,
    this.focalLength,
    this.fieldOfView,
  });

  /// Unique stable identifier from the native platform.
  final String id;

  /// Human-readable lens name.
  final String name;

  /// Physical mount position (front/back/external).
  final CameraLensPosition position;

  /// Lens category (wide/ultraWide/telephoto/etc).
  final CameraLensCategory category;

  /// Whether manual/tap focus is supported on this lens.
  final bool supportsFocus;

  /// Optional focal length in millimetres.
  final double? focalLength;

  /// Optional horizontal field of view in degrees.
  final double? fieldOfView;

  factory CameraLensDescriptor.fromMap(Map<String, Object?> map) {
    final payload = (
      id: _readString(map, 'id'),
      name: _readString(map, 'name'),
      position: map['position'] as String?,
      category: map['category'] as String?,
      supportsFocus: map['supportsFocus'] as bool?,
      focalLength: _readOptionalNum(map, 'focalLength'),
      fieldOfView: _readOptionalNum(map, 'fieldOfView'),
    );

    return CameraLensDescriptor(
      id: payload.id,
      name: payload.name,
      position: _positionFromString(payload.position),
      category: _categoryFromString(payload.category),
      supportsFocus: payload.supportsFocus ?? false,
      focalLength: payload.focalLength?.toDouble(),
      fieldOfView: payload.fieldOfView?.toDouble(),
    );
  }

  static CameraLensPosition _positionFromString(String? value) =>
      switch (value) {
        'front' => CameraLensPosition.front,
        'back' => CameraLensPosition.back,
        'external' => CameraLensPosition.external,
        _ => CameraLensPosition.unspecified,
      };

  static CameraLensCategory _categoryFromString(String? value) =>
      switch (value) {
        'wide' => CameraLensCategory.wide,
        'ultraWide' => CameraLensCategory.ultraWide,
        'telephoto' => CameraLensCategory.telephoto,
        'trueDepth' => CameraLensCategory.trueDepth,
        'dual' => CameraLensCategory.dual,
        'triple' => CameraLensCategory.triple,
        'continuity' => CameraLensCategory.continuity,
        'external' => CameraLensCategory.external,
        _ => CameraLensCategory.unknown,
      };

  static String _readString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String) {
      return value;
    }
    throw FormatException('Expected "$key" to be a String but found "$value"');
  }

  static num? _readOptionalNum(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    throw FormatException('Expected "$key" to be numeric but found "$value"');
  }
}
