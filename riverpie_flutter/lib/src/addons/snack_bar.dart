import 'package:flutter/material.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie_flutter/src/addons/action.dart';

/// The [Provider] for [SnackBarService].
final snackBarProvider = Provider((ref) => SnackBarService());

/// A service to show [SnackBar]s.
///
/// Usage:
/// MaterialApp(
///   scaffoldMessengerKey: ref.watch(snackBarProvider).key,
///   ...
/// )
///
/// ref.read(snackBarProvider).showMessage('Hello World');
class SnackBarService {
  GlobalKey<ScaffoldMessengerState> _key = GlobalKey<ScaffoldMessengerState>();

  /// The [GlobalKey] to access the [ScaffoldMessengerState].
  GlobalKey<ScaffoldMessengerState> get key => _key;

  /// Set the [GlobalKey] to access the [ScaffoldMessengerState].
  /// Use this if you already have a [GlobalKey] for [ScaffoldMessengerState].
  void setKey(GlobalKey<ScaffoldMessengerState> key) {
    _key = key;
  }

  /// Whether to hide the current [SnackBar] before showing a new one.
  bool hideCurrent = true;

  /// Shows a [SnackBar] with the given [message].
  /// Override this method to customize the [SnackBar].
  void showMessage(
    String message, {
    SnackBarAction? action,
    bool? hideCurrent,
  }) {
    if (hideCurrent ?? this.hideCurrent) {
      _key.currentState?.hideCurrentSnackBar();
    }
    _key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
      ),
    );
  }
}

/// The [Provider] for [SnackBarReduxService].
final snackBarReduxProvider = ReduxProvider((ref) {
  return SnackBarReduxService(ref.read(snackBarProvider));
});

/// A service to optionally dispatch [ShowSnackBarAction]s
/// instead of simply calling [SnackBarService.showMessage].
///
/// Usage:
/// MaterialApp(
///   scaffoldMessengerKey: ref.watch(snackBarProvider).snackbarKey,
///   ...
/// )
///
/// ref.dispatch(
///   ShowSnackBarAction(
///     message: 'Hello World',
///   ),
/// );
class SnackBarReduxService extends ReduxNotifier<void> {
  final SnackBarService service;

  SnackBarReduxService(this.service);

  @override
  void init() {}
}

/// Extend this class to create a custom snack bar action.
/// Access the [ScaffoldMessengerState] via [notifier.service.key.currentState].
abstract class BaseShowSnackBarAction
    extends ReduxAction<SnackBarReduxService, void>
    implements AddonAction<void> {}

/// An action to show a [SnackBar].
class ShowSnackBarAction extends BaseShowSnackBarAction {
  /// The message to show.
  final String message;

  /// The optional [SnackBarAction] to show.
  final SnackBarAction? action;

  ShowSnackBarAction({
    required this.message,
    this.action,
  });

  @override
  void reduce() {
    notifier.service.showMessage(
      message,
      action: action,
    );
  }

  @override
  String toString() {
    return 'ShowSnackBarAction(message: "$message")';
  }

  @override
  String get debugLabel => 'ShowSnackBarAction';
}
