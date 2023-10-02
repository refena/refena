import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:refena/refena.dart';

final navigationProvider = Provider((ref) => NavigationService());

class NavigationService {
  GlobalKey<NavigatorState> _key = GlobalKey<NavigatorState>();

  /// The [GlobalKey] to access the [NavigatorState].
  GlobalKey<NavigatorState> get key => _key;

  /// Set the [GlobalKey] to access the [NavigatorState].
  /// Use this if you already have a [GlobalKey] for [NavigatorState].
  void setKey(GlobalKey<NavigatorState> key) {
    _key = key;
  }

  /// Access the global [BuildContext] associated with the [NavigatorState].
  BuildContext get context => _key.currentContext!;

  /// Pushes a new route onto the navigator.
  Future<T?> push<T>(Widget widget) async {
    final result = await _key.currentState?.push<T>(
      MaterialPageRoute(
        builder: (_) => widget,
        settings: RouteSettings(name: widget.runtimeType.toString()),
      ),
    );

    return result;
  }

  /// Pushes a named route onto the navigator.
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) async {
    final result = await _key.currentState?.pushNamed<T>(
      routeName,
      arguments: arguments,
    );

    return result;
  }

  /// Pops the current route off the navigator.
  void pop([Object? result]) {
    _key.currentState?.pop(result);
  }
}

class NavigateAction {
  NavigateAction._();

  /// Pushes a new route onto the navigator.
  static NavigationPushAction<T> push<T>(Widget widget) {
    return NavigationPushAction<T>._(widget);
  }

  /// Pushes a named route onto the navigator.
  static NavigationPushNamedAction<T> pushNamed<T>(String routeName,
      {Object? arguments}) {
    return NavigationPushNamedAction<T>._(routeName, arguments);
  }

  /// Pops the current route off the navigator.
  static NavigationPopAction pop([Object? result]) {
    return NavigationPopAction._(result);
  }
}

/// Extend this class to create a custom push action.
abstract class BaseNavigationPushAction<R>
    extends AsyncGlobalActionWithResult<R?> {
  /// Override this method to implement your custom push action.
  /// Access the [NavigatorState] with
  /// [ref.read(navigationProvider).key.currentState].
  Future<R?> navigate();

  @override
  @nonVirtual
  Future<R?> reduce() async {
    return navigate();
  }
}

/// The default push action.
class NavigationPushAction<R> extends BaseNavigationPushAction<R> {
  final Widget _widget;

  NavigationPushAction._(this._widget);

  @override
  Future<R?> navigate() {
    return ref.read(navigationProvider).push<R>(_widget);
  }

  @override
  String get debugLabel => 'NavigationPushAction(${_widget.runtimeType})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationPushAction<R> &&
          runtimeType == other.runtimeType &&
          _widget.runtimeType == other._widget.runtimeType;

  @override
  int get hashCode => _widget.hashCode;

  @override
  String toString() => 'NavigationPushAction(${_widget.runtimeType})';
}

class NavigationPushNamedAction<R> extends BaseNavigationPushAction<R> {
  final String _routeName;
  final Object? _arguments;

  NavigationPushNamedAction._(this._routeName, this._arguments);

  @override
  Future<R?> navigate() {
    return ref
        .read(navigationProvider)
        .pushNamed<R>(_routeName, arguments: _arguments);
  }

  @override
  String get debugLabel =>
      'NavigationPushNamedAction($_routeName, settings: $_arguments)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationPushNamedAction<R> &&
          runtimeType == other.runtimeType &&
          _routeName == other._routeName &&
          _arguments == other._arguments;

  @override
  int get hashCode => _routeName.hashCode ^ _arguments.hashCode;

  @override
  String toString() =>
      'NavigationPushNamedAction($_routeName, settings: $_arguments)';
}

/// Extend this class to create a custom pop action.
abstract class BaseNavigationPopAction extends GlobalAction {}

/// Pops the current route off the navigator.
class NavigationPopAction extends BaseNavigationPopAction {
  final Object? _result;

  NavigationPopAction._([this._result]);

  @override
  void reduce() {
    ref.read(navigationProvider).pop(_result);
  }

  @override
  String get debugLabel => 'NavigationPopAction($_result)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationPopAction && _result == other._result;

  @override
  int get hashCode => _result.hashCode;

  @override
  String toString() => 'NavigationPopAction(result: $_result)';
}
