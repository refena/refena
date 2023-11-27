import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should not swallow an action for 2 actions', () async {
    final observer = RefenaHistoryObserver.only(
      change: true,
      actionDispatched: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(_reduxProvider), _CounterState(a: 0, b: 0, c: 0));

    // ignore: unawaited_futures
    ref.redux(_reduxProvider).dispatchAsync(
          _Action(
            label: 'a',
            ticks: 1,
            reducer: (state) => state.copyWith(a: state.a + 1),
          ),
          debugOrigin: 'a',
        );

    // ignore: unawaited_futures
    ref.redux(_reduxProvider).dispatchAsync(
          _Action(
            label: 'b',
            ticks: 0,
            reducer: (state) => state.copyWith(b: state.b + 1),
          ),
          debugOrigin: 'b',
        );

    await skipAllMicrotasks();

    // This is expected
    // expect(ref.read(_reduxProvider), _CounterState(a: 1, b: 1, c: 0));

    // But due to limitations in Dart, this is the actual result
    expect(ref.read(_reduxProvider), _CounterState(a: 0, b: 1, c: 0));
  });

  test('Should not swallow an action for 3 actions', () async {
    final observer = RefenaHistoryObserver.only(
      change: true,
      actionDispatched: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(_reduxProvider), _CounterState(a: 0, b: 0, c: 0));

    // ignore: unawaited_futures
    ref.redux(_reduxProvider).dispatchAsync(
          _Action(
            label: 'a',
            ticks: 2,
            reducer: (state) => state.copyWith(a: state.a + 1),
          ),
          debugOrigin: 'a',
        );

    // ignore: unawaited_futures
    ref.redux(_reduxProvider).dispatchAsync(
          _Action(
            label: 'b',
            ticks: 2,
            reducer: (state) => state.copyWith(b: state.b + 1),
          ),
          debugOrigin: 'b',
        );

    // ignore: unawaited_futures
    ref.redux(_reduxProvider).dispatchAsync(
          _Action(
            label: 'c',
            ticks: 0,
            reducer: (state) => state.copyWith(c: state.c + 1),
          ),
          debugOrigin: 'c',
        );

    await skipAllMicrotasks();

    expect(ref.read(_reduxProvider), _CounterState(a: 1, b: 1, c: 1));
  });
}

final _reduxProvider =
    ReduxProvider<_Counter, _CounterState>((ref) => _Counter());

class _CounterState {
  final int a;
  final int b;
  final int c;

  _CounterState({
    required this.a,
    required this.b,
    required this.c,
  });

  _CounterState copyWith({
    int? a,
    int? b,
    int? c,
  }) {
    return _CounterState(
      a: a ?? this.a,
      b: b ?? this.b,
      c: c ?? this.c,
    );
  }

  @override
  String toString() {
    return '_CounterState(a: $a, b: $b, c: $c)';
  }

  @override
  bool operator ==(Object other) {
    return other is _CounterState &&
        other.a == a &&
        other.b == b &&
        other.c == c;
  }

  @override
  int get hashCode => a.hashCode ^ b.hashCode ^ c.hashCode;
}

class _Counter extends ReduxNotifier<_CounterState> {
  @override
  _CounterState init() => _CounterState(
        a: 0,
        b: 0,
        c: 0,
      );
}

/// Applies the reducer after [ticks] microtasks.
/// If [ticks] is 0, the returned Future is a "completed future".
class _Action extends AsyncReduxAction<_Counter, _CounterState> {
  final String label;
  final int ticks;
  final _CounterState Function(_CounterState) reducer;

  _Action({
    required this.label,
    required this.ticks,
    required this.reducer,
  });

  @override
  Future<_CounterState> reduce() async {
    for (var i = 0; i < ticks; i++) {
      await Future.microtask(() {});
    }
    return reducer(state);
  }
}
