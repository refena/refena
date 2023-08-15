import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';
import 'package:riverpie/src/widget/scope.dart';

/// A "provider" instructs Riverpie how to create a state.
/// A "provider" is stateless.
///
/// You may add a [debugLabel] for better logging.
abstract class BaseProvider<N extends BaseNotifier<T>, T> {
  final String? debugLabel;

  BaseProvider({this.debugLabel});

  @internal
  N createState(
    RiverpieScope scope,
    RiverpieObserver? observer,
  );
}

/// A flag to indicate that the notifier is accessible from [Ref].
/// Every [NotifyableProvider] is a [BaseProvider] although not
/// visible in the type hierarchy.
abstract class NotifyableProvider<N extends BaseNotifier<T>, T> {}
