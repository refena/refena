import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie_flutter/src/addons/action.dart';

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

final navigationReduxProvider = ReduxProvider((ref) {
  return NavigationReduxService(ref.read(navigationProvider));
});

class NavigationReduxService extends ReduxNotifier<void> {
  final NavigationService service;

  NavigationReduxService(this.service);

  @override
  void init() {}
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
abstract class BaseNavigationPushAction<T>
    extends AsyncReduxActionWithResult<NavigationReduxService, void, T?>
    implements AsyncAddonAction<T> {
  /// Override this method to implement your custom push action.
  /// Access the [NavigatorState] with [notifier.service.key.currentState].
  Future<T?> navigate();

  @override
  @nonVirtual
  Future<(void, T?)> reduce() async {
    return (null, await navigate());
  }
}

/// The default push action.
class NavigationPushAction<T> extends BaseNavigationPushAction<T> {
  final Widget _widget;

  NavigationPushAction._(this._widget);

  @override
  Future<T?> navigate() {
    return notifier.service.push<T>(_widget);
  }

  @override
  String get debugLabel => 'NavigationPushAction(${_widget.runtimeType})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationPushAction<T> &&
          runtimeType == other.runtimeType &&
          _widget.runtimeType == other._widget.runtimeType;

  @override
  int get hashCode => _widget.hashCode;
}

class NavigationPushNamedAction<T> extends BaseNavigationPushAction<T> {
  final String _routeName;
  final Object? _arguments;

  NavigationPushNamedAction._(this._routeName, this._arguments);

  @override
  Future<T?> navigate() {
    return notifier.service.pushNamed<T>(_routeName, arguments: _arguments);
  }

  @override
  String get debugLabel =>
      'NavigationPushNamedAction($_routeName, settings: $_arguments)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationPushNamedAction<T> &&
          runtimeType == other.runtimeType &&
          _routeName == other._routeName &&
          _arguments == other._arguments;

  @override
  int get hashCode => _routeName.hashCode ^ _arguments.hashCode;
}

/// Extend this class to create a custom pop action.
abstract class BaseNavigationPopAction
    extends ReduxAction<NavigationReduxService, void>
    implements AddonAction<void> {}

class NavigationPopAction extends BaseNavigationPopAction {
  final Object? _result;

  NavigationPopAction._([this._result]);

  @override
  void reduce() {
    notifier.service.pop(_result);
  }

  @override
  String get debugLabel => 'NavigationPopAction($_result)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationPopAction && _result == other._result;

  @override
  int get hashCode => _result.hashCode;
}
