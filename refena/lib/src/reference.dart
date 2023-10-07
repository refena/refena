import 'package:refena/src/util/id_provider.dart';

final _idProvider = IdProvider();

/// An arbitrary object that has an [id].
/// We cannot rely on identical() because this information cannot be
/// serialized.
abstract mixin class IdReference {
  /// The id.
  final int id = _idProvider.getNextId();

  /// Returns true, if the other reference has the same id.
  bool compareIdentity(IdReference other) => id == other.id;

  /// Resets the id to 0.
  static void reset() => _idProvider.reset();
}

/// An arbitrary object that has a [debugLabel] property.
abstract interface class LabeledReference {
  /// A label to be used in debug messages and
  /// by the [RefenaTracingPage].
  String get debugLabel;

  /// Creates a custom [LabeledReference] of any object.
  static LabeledReference custom(String label) {
    return _CustomLabeledReference(label);
  }
}

/// This class allows you to create a custom [LabeledReference].
class _CustomLabeledReference implements LabeledReference {
  final String _label;

  _CustomLabeledReference(this._label);

  @override
  String get debugLabel => _label;
}

/// An arbitrary object that is a [IdReference] and a [LabeledReference].
abstract mixin class LabeledIdReference
    implements IdReference, LabeledReference {}
