enum CameraLensPosition { front, back, unspecified, external }

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

class CameraLensDescriptor {
  CameraLensDescriptor({
    required this.id,
    required this.name,
    required this.position,
    required this.category,
    this.focalLength,
    this.fieldOfView,
  });

  final String id;
  final String name;
  final CameraLensPosition position;
  final CameraLensCategory category;
  final double? focalLength;
  final double? fieldOfView;

  factory CameraLensDescriptor.fromMap(Map<String, Object?> map) {
    final payload = (
      id: _readString(map, 'id'),
      name: _readString(map, 'name'),
      position: map['position'] as String?,
      category: map['category'] as String?,
      focalLength: _readOptionalNum(map, 'focalLength'),
      fieldOfView: _readOptionalNum(map, 'fieldOfView'),
    );

    return CameraLensDescriptor(
      id: payload.id,
      name: payload.name,
      position: _positionFromString(payload.position),
      category: _categoryFromString(payload.category),
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
