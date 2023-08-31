import 'package:flutter/material.dart';
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
  final NavigationService _service;

  NavigationReduxService(this._service);

  @override
  void init() {}
}

class NavigateAction {
  NavigateAction._();

  /// Pushes a new route onto the navigator.
  static NavigatePushAction<T> push<T>(Widget widget) {
    return NavigatePushAction<T>._(widget);
  }

  /// Pushes a named route onto the navigator.
  static NavigatePushNamedAction<T> pushNamed<T>(String routeName,
      {Object? arguments}) {
    return NavigatePushNamedAction<T>._(routeName, arguments);
  }

  /// Pops the current route off the navigator.
  static NavigatePopAction pop([Object? result]) {
    return NavigatePopAction._(result);
  }
}

class NavigatePushAction<T>
    extends AsyncReduxActionWithResult<NavigationReduxService, void, T?>
    implements AsyncAddonAction<T> {
  final Widget _widget;

  NavigatePushAction._(this._widget);

  @override
  Future<(void, T?)> reduce() async {
    return (null, await notifier._service.push<T>(_widget));
  }

  @override
  String get debugLabel => 'NavigatePushAction(${_widget.runtimeType})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigatePushAction<T> &&
          runtimeType == other.runtimeType &&
          _widget.runtimeType == other._widget.runtimeType;

  @override
  int get hashCode => _widget.hashCode;
}

class NavigatePushNamedAction<T>
    extends AsyncReduxActionWithResult<NavigationReduxService, void, T?>
    implements AsyncAddonAction<T> {
  final String _routeName;
  final Object? _arguments;

  NavigatePushNamedAction._(this._routeName, this._arguments);

  @override
  Future<(void, T?)> reduce() async {
    return (
      null,
      await notifier._service.pushNamed<T>(_routeName, arguments: _arguments)
    );
  }

  @override
  String get debugLabel =>
      'NavigatePushNamedAction($_routeName, settings: $_arguments)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigatePushNamedAction<T> &&
          runtimeType == other.runtimeType &&
          _routeName == other._routeName &&
          _arguments == other._arguments;

  @override
  int get hashCode => _routeName.hashCode ^ _arguments.hashCode;
}

class NavigatePopAction extends ReduxAction<NavigationReduxService, void>
    implements AddonAction<void> {
  final Object? _result;

  NavigatePopAction._([this._result]);

  @override
  void reduce() {
    notifier._service.pop(_result);
  }

  @override
  String get debugLabel => 'NavigatePopAction($_result)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigatePopAction && _result == other._result;

  @override
  int get hashCode => _result.hashCode;
}
