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
