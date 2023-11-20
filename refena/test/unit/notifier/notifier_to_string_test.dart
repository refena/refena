import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';
import '../../util/web.dart';

void main() {
  if (kIsWeb) {
    // runtimeType.toString is not consistent on web
    return;
  }

  test(ImmutableNotifier, () {
    final ref = RefenaContainer();
    final provider = Provider((ref) => 11);

    expect(
      ref.anyNotifier(provider).toString(),
      'ImmutableNotifier<int>(label: Provider<int>, state: 11)',
    );
  });

  test(FutureProviderNotifier, () async {
    final ref = RefenaContainer();
    final provider = FutureProvider((ref) async => 22);
    final notifier = ref.anyNotifier(provider);

    expect(
      notifier.toString(),
      'FutureProviderNotifier<int>(label: FutureProvider<int>, state: AsyncLoading<int>)',
    );
    await skipAllMicrotasks();
    expect(
      notifier.toString(),
      'FutureProviderNotifier<int>(label: FutureProvider<int>, state: AsyncData<int>(22))',
    );
  });

  test(Notifier, () {
    expect(_Counter().toString(),
        '_Counter(label: _Counter, state: uninitialized)');

    final ref = RefenaContainer();
    final provider = NotifierProvider<_Counter, int>((ref) => _Counter());

    expect(ref.notifier(provider).toString(),
        '_Counter(label: _Counter, state: 33)');
  });

  test(PureNotifier, () {
    final ref = RefenaContainer();
    final provider =
        NotifierProvider<_PureCounter, int>((ref) => _PureCounter());

    expect(ref.notifier(provider).toString(),
        '_PureCounter(label: _PureCounter, state: 44)');
  });

  test(AsyncNotifier, () async {
    final ref = RefenaContainer();
    final provider =
        AsyncNotifierProvider<_AsyncCounter, int>((ref) => _AsyncCounter());
    final notifier = ref.notifier(provider);

    expect(notifier.toString(),
        '_AsyncCounter(label: _AsyncCounter, state: AsyncLoading<int>)');
    await skipAllMicrotasks();
    expect(notifier.toString(),
        '_AsyncCounter(label: _AsyncCounter, state: AsyncData<int>(55))');
  });

  test(StateNotifier, () {
    final ref = RefenaContainer();
    final provider = StateProvider((ref) => 66);

    expect(
      ref.notifier(provider).toString(),
      'StateNotifier<int>(label: StateProvider<int>, state: 66)',
    );
  });

  test(ViewProviderNotifier, () {
    final ref = RefenaContainer();
    final provider = ViewProvider((ref) => 77);

    expect(
      ref.anyNotifier(provider).toString(),
      'ViewProviderNotifier<int>(label: ViewProvider<int>, state: 77)',
    );
  });
}

class _Counter extends Notifier<int> {
  @override
  int init() => 33;
}

class _PureCounter extends PureNotifier<int> {
  @override
  int init() => 44;
}

class _AsyncCounter extends AsyncNotifier<int> {
  @override
  Future<int> init() async => 55;
}
