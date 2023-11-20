import 'package:refena/refena.dart';
import 'package:test/test.dart';

/// Tests if [Ref.accessor] works as expected.
void main() {
  test('Should return the latest value', () {
    final ref = RefenaContainer();
    final parentProvider = StateProvider((ref) => 0);
    final childProvider = NotifierProvider<_Notifier, int>((ref) {
      return _Notifier(ref.accessor(parentProvider));
    });

    expect(ref.read(parentProvider), 0);
    expect(ref.read(childProvider), 0);
    expect(ref.notifier(childProvider).getAccessorValue(), 0);

    ref.notifier(parentProvider).setState((old) => old + 1);

    expect(ref.read(parentProvider), 1);
    expect(ref.read(childProvider), 0);
    expect(ref.notifier(childProvider).getAccessorValue(), 1);
  });

  test('Should return the latest value with select', () {
    final ref = RefenaContainer();
    final parentProvider = StateProvider((ref) => 0);
    final childProvider = NotifierProvider<_Notifier, int>((ref) {
      return _Notifier(ref.accessor(parentProvider.select((s) => s * 2)));
    });

    expect(ref.read(parentProvider), 0);
    expect(ref.read(childProvider), 0);
    expect(ref.notifier(childProvider).getAccessorValue(), 0);

    ref.notifier(parentProvider).setState((old) => old + 1);

    expect(ref.read(parentProvider), 1);
    expect(ref.read(childProvider), 0);
    expect(ref.notifier(childProvider).getAccessorValue(), 2);
  });

  test('Should initialize the accessed notifier', () {
    final ref = RefenaContainer();
    final parentProvider = StateProvider((ref) => 0);
    final childProvider = NotifierProvider<_Notifier, int>((ref) {
      return _Notifier(ref.accessor(parentProvider));
    });

    expect(ref.getActiveProviders(), isEmpty);

    ref.read(childProvider);

    expect(ref.getActiveProviders(), [parentProvider, childProvider]);
  });

  test('Should add to dependency graph', () {
    final ref = RefenaContainer();
    final parentProvider = StateProvider((ref) => 0);

    final parentNotifier = ref.notifier(parentProvider);
    expect(parentNotifier.dependents, isEmpty);
    expect(parentNotifier.dependencies, isEmpty);

    final childProvider = NotifierProvider<_Notifier, int>((ref) {
      return _Notifier(ref.accessor(parentProvider));
    });

    final childNotifier = ref.notifier(childProvider);
    expect(parentNotifier.dependents, {childNotifier});
    expect(parentNotifier.dependencies, isEmpty);
    expect(childNotifier.dependents, isEmpty);
    expect(childNotifier.dependencies, {parentNotifier});
  });

  test('Disposing accessor provider should dispose child', () {
    final ref = RefenaContainer();
    final parentProvider = StateProvider((ref) => 0);
    final childProvider = NotifierProvider<_Notifier, int>((ref) {
      return _Notifier(ref.accessor(parentProvider));
    });

    final parentNotifier = ref.notifier(parentProvider);
    final childNotifier = ref.notifier(childProvider);

    expect(ref.getActiveProviders(), [parentProvider, childProvider]);
    expect(parentNotifier.disposed, false);
    expect(childNotifier.disposed, false);

    ref.dispose(parentProvider);

    expect(ref.getActiveProviders(), isEmpty);
    expect(parentNotifier.disposed, true);
    expect(childNotifier.disposed, true);
  });
}

class _Notifier extends Notifier<int> {
  final StateAccessor<int> accessor;

  _Notifier(this.accessor);

  @override
  int init() => 0;

  int getAccessorValue() => accessor.state;
}
