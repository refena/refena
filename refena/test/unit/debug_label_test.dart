import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  test('Should use notifier class type', () {
    final ref = RefenaContainer();
    final provider = NotifierProvider((ref) => _NoDebugLabelNotifier());

    expect(ref.notifier(provider).debugLabel, '_NoDebugLabelNotifier');
    expect(ref.notifier(provider).customDebugLabel, null);
  });

  test('Should use provider label if notifier label does not exist', () {
    final ref = RefenaContainer();
    final provider = NotifierProvider(
      (ref) => _NoDebugLabelNotifier(),
      debugLabel: 'provider-label',
    );

    expect(ref.notifier(provider).debugLabel, 'provider-label');
    expect(ref.notifier(provider).customDebugLabel, 'provider-label');
  });

  test('Should use custom notifier label', () {
    final ref = RefenaContainer();
    final provider = NotifierProvider(
      (ref) => _WithDebugLabelNotifier(),
      debugLabel: 'provider-label',
    );

    expect(ref.notifier(provider).debugLabel, 'notifier-label');
    expect(ref.notifier(provider).customDebugLabel, 'notifier-label');
  });

  test('Provider should use provider class type', () {
    final ref = RefenaContainer();
    final provider = Provider((ref) => 0);

    expect(ref.anyNotifier(provider).debugLabel, 'Provider<int>');
    expect(ref.anyNotifier(provider).customDebugLabel, 'Provider<int>');
  });

  test('ViewProvider should use provider class type', () {
    final ref = RefenaContainer();
    final provider = ViewProvider((ref) => 0);

    expect(ref.anyNotifier(provider).debugLabel, 'ViewProvider<int>');
    expect(ref.anyNotifier(provider).customDebugLabel, 'ViewProvider<int>');
  });

  test('ViewFamilyProvider should use provider class type', () {
    final ref = RefenaContainer();
    final provider = ViewFamilyProvider<int, String>((ref, param) => 0);

    expect(
      ref.anyNotifier(provider).debugLabel,
      'ViewFamilyProvider<int, String>',
    );
    expect(
      ref.anyNotifier(provider).customDebugLabel,
      'ViewFamilyProvider<int, String>',
    );
  });

  test('FutureProvider should use provider class type', () {
    final ref = RefenaContainer();
    final provider = FutureProvider((ref) async => 0);

    expect(
      ref.anyNotifier(provider).debugLabel,
      'FutureProvider<int>',
    );
    expect(
      ref.anyNotifier(provider).customDebugLabel,
      'FutureProvider<int>',
    );
  });

  test('FutureFamilyProvider should use provider class type', () {
    final ref = RefenaContainer();
    final provider = FutureFamilyProvider<int, String>((ref, param) async {
      return 0;
    });

    expect(
      ref.anyNotifier(provider).debugLabel,
      'FutureFamilyProvider<int, String>',
    );
    expect(
      ref.anyNotifier(provider).customDebugLabel,
      'FutureFamilyProvider<int, String>',
    );
  });

  test('StateProvider should use provider class type', () {
    final ref = RefenaContainer();
    final provider = StateProvider((ref) => 0);

    expect(
      ref.anyNotifier(provider).debugLabel,
      'StateProvider<int>',
    );
    expect(
      ref.anyNotifier(provider).customDebugLabel,
      'StateProvider<int>',
    );
  });
}

class _NoDebugLabelNotifier extends Notifier<int> {
  @override
  int init() => 0;
}

class _WithDebugLabelNotifier extends Notifier<int> {
  @override
  int init() => 0;

  @override
  String get customDebugLabel => 'notifier-label';
}
