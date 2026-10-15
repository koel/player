class UnsupportedTypeException implements Exception {
  final Type type;

  UnsupportedTypeException({required this.type});

  @override
  String toString() {
    return '$type is not a supported type.';
  }

  factory UnsupportedTypeException.fromType(Type type) {
    return UnsupportedTypeException(type: type);
  }

  factory UnsupportedTypeException.fromObject(Object object) {
    return UnsupportedTypeException(type: object.runtimeType);
  }
}
