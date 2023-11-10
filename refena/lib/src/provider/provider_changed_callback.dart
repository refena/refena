import 'package:refena/src/ref.dart';

/// A callback that is called when a provider changes.
typedef ProviderChangedCallback<T> = void Function(
  T prev,
  T next,
  Ref ref,
);
