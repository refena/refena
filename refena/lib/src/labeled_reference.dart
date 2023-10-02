/// An arbitrary object that has a [debugLabel] property.
abstract mixin class LabeledReference {
  /// A label to be used in debug messages and
  /// by the [RefenaTracingPage].
  String get debugLabel;

  /// Compares the identity of two [LabeledReference]s.
  bool compareIdentity(LabeledReference other) {
    return identical(this, other);
  }

  /// Creates a custom [LabeledReference] of any object.
  static CustomLabeledReference custom(String label) {
    return CustomLabeledReference(label);
  }
}

/// This class allows you to create a custom [LabeledReference]
/// of any object.
class CustomLabeledReference with LabeledReference {
  final String _label;

  CustomLabeledReference(this._label);

  @override
  String get debugLabel => _label;
}
