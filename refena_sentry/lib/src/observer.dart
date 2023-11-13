import 'package:refena/refena.dart';
import 'package:sentry/sentry.dart';

/// An observer that sends breadcrumbs to Sentry.
class RefenaSentryObserver extends RefenaObserver {
  @override
  void handleEvent(RefenaEvent event) {
    switch (event) {
      case ActionDispatchedEvent():
        Sentry.addBreadcrumb(Breadcrumb(
          type: 'transaction',
          category: 'refena.action',
          message: event.action.debugLabel,
        ));
      case ActionErrorEvent():
        Sentry.addBreadcrumb(Breadcrumb(
          type: 'error',
          category: 'refena.action',
          message: event.action.debugLabel,
          data: {
            'error': event.error.toString(),
          },
        ));
        break;
      case MessageEvent():
        Sentry.addBreadcrumb(Breadcrumb(
          type: 'info',
          category: 'refena.message',
          message: event.message,
        ));
        break;
      default:
    }
  }
}
