import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  group(Provider, () {
    test('Should use default description', () {
      final ref = RefenaContainer();
      final provider = Provider((ref) => 0);
      expect(ref.anyNotifier(provider).describeState(123), '123');
    });

    test('Should use custom description', () {
      final ref = RefenaContainer();
      final provider = Provider(
        (ref) => 0,
        describeState: (value) => (value * 2).toString(),
      );
      expect(ref.anyNotifier(provider).describeState(123), '246');
    });
  });

  group(FutureProvider, () {
    test('Should use default description', () {
      final ref = RefenaContainer();
      final provider = FutureProvider((ref) => Future.value(0));
      expect(
        ref.anyNotifier(provider).describeState(AsyncValue.data(123)),
        'AsyncData<int>(123)',
      );
    });

    test('Should use custom description', () {
      final ref = RefenaContainer();
      final provider = FutureProvider<int>(
        (ref) => Future.value(0),
        describeState: (value) => (value.data! * 2).toString(),
      );
      expect(
        ref.anyNotifier(provider).describeState(AsyncValue.data(123)),
        '246',
      );
    });
  });

  group(StateProvider, () {
    test('Should use default description', () {
      final ref = RefenaContainer();
      final provider = StateProvider((ref) => 0);
      expect(ref.anyNotifier(provider).describeState(123), '123');
    });

    test('Should use custom description', () {
      final ref = RefenaContainer();
      final provider = StateProvider(
        (ref) => 0,
        describeState: (value) => (value * 2).toString(),
      );
      expect(ref.anyNotifier(provider).describeState(123), '246');
    });
  });

  group(StreamProvider, () {
    test('Should use default description', () {
      final ref = RefenaContainer();
      final provider = StreamProvider((ref) => Stream.value(0));
      expect(
        ref.anyNotifier(provider).describeState(AsyncValue.data(123)),
        'AsyncData<int>(123)',
      );
    });

    test('Should use custom description', () {
      final ref = RefenaContainer();
      final provider = StreamProvider<int>(
        (ref) => Stream.value(0),
        describeState: (value) => (value.data! * 2).toString(),
      );
      expect(
        ref.anyNotifier(provider).describeState(AsyncValue.data(123)),
        '246',
      );
    });
  });

  group(ViewProvider, () {
    test('Should use default description', () {
      final ref = RefenaContainer();
      final provider = ViewProvider((ref) => 0);
      expect(ref.anyNotifier(provider).describeState(123), '123');
    });

    test('Should use custom description', () {
      final ref = RefenaContainer();
      final provider = ViewProvider(
        (ref) => 0,
        describeState: (value) => (value * 2).toString(),
      );
      expect(ref.anyNotifier(provider).describeState(123), '246');
    });
  });
}
