import 'package:refena/refena.dart';
import 'package:refena_sentry/refena_sentry.dart';
import 'package:sentry/sentry.dart';

void main() async {
  await Sentry.init(
    (options) {
      options.dsn = 'https://example@sentry.io/example';
    },
    appRunner: () {
      final container = RefenaContainer(
        observers: [
          RefenaSentryObserver(),
        ],
      );

      container.global.dispatch(ErrorAction());
    },
  );
}

class ErrorAction extends GlobalAction {
  @override
  void reduce() {
    throw Exception('ErrorAction');
  }
}
