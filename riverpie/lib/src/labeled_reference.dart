/// An arbitrary object that has a [debugLabel] property.
abstract mixin class LabeledReference {
  /// A label to be used in debug messages and
  /// by the [RiverpieTracingPage].
  String get debugLabel;

  /// Compares the identity of two [LabeledReference]s.
  bool compareIdentity(LabeledReference other) {
    return identical(this, other);
  }
}
