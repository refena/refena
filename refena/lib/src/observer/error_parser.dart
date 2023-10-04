import 'package:meta/meta.dart';

/// Parses an error to a map.
/// This is used by the tracing page to display the error in a
/// human-readable format.
/// This is also used by the [RefenaInspectorObserver] to to send
/// the error to the inspector.
///
/// Return null to fallback to the default error parser provided by Refena.
/// See [parseErrorDefault] for the default error parser.
typedef ErrorParser = Map<String, dynamic>? Function(Object error);

/// Parses an error to a nested map.
@internal
Map<String, dynamic>? parseError(Object error, ErrorParser? errorParser) {
  if (errorParser == null) {
    return parseErrorDefault(error);
  }
  try {
    final result = errorParser(error);
    if (result != null) {
      return result;
    }
    return parseErrorDefault(error);
  } catch (e) {
    print(e);
    return null;
  }
}

/// The default error parser.
/// It uses [dynamic] to avoid any dependencies.
/// To implement your own, you should use `Object error` instead.
@internal
Map<String, dynamic>? parseErrorDefault(dynamic error) {
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
