part of 'tracing_page.dart';

/// Parses an error to a nested map.
Map<String, dynamic>? _parseError(Object error, ErrorParser? errorParser) {
  if (errorParser == null) {
    return _parseErrorDefault(error);
  }
  try {
    final result = errorParser(error);
    if (result != null) {
      return result;
    }
    return _parseErrorDefault(error);
  } catch (e) {
    print(e);
    return null;
  }
}

/// The default error parser.
/// It uses [dynamic] to avoid any dependencies.
/// To implement your own, you should use [Object] instead.
Map<String, dynamic>? _parseErrorDefault(dynamic error) {
  return switch (error.runtimeType.toString()) {
    'DioException' => {
        'url': error.requestOptions.path,
        'statusCode': error.response?.statusCode,
        'statusMessage': error.response?.statusMessage,
        'data': error.response?.data,
      },
    _ => null,
  };
}
