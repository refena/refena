import 'package:flutter/material.dart';
import 'package:refena/refena.dart';

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

/// Extend this class to create a custom snack bar action.
/// Access the [ScaffoldMessengerState] with
/// [ref.read(snackBarProvider).key.currentState].
abstract class BaseShowSnackBarAction extends GlobalAction {}

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
    ref.read(snackBarProvider).showMessage(
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
