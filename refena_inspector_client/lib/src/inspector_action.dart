import 'package:meta/meta.dart';
import 'package:refena/refena.dart';

enum ParamType {
  string,
  int,
  double,
  bool,
}

/// The specification of a parameter.
class ParamSpec {
  final ParamType type;
  final bool required;
  final Object? defaultValue;

  @internal
  const ParamSpec.internal({
    required this.type,
    required this.required,
    required this.defaultValue,
  });

  factory ParamSpec.string({
    bool required = false,
    String? defaultValue,
  }) {
    return ParamSpec.internal(
      type: ParamType.string,
      required: required,
      defaultValue: defaultValue,
    );
  }

  factory ParamSpec.int({
    bool required = false,
    int? defaultValue,
  }) {
    return ParamSpec.internal(
      type: ParamType.int,
      required: required,
      defaultValue: defaultValue,
    );
  }

  factory ParamSpec.double({
    bool required = false,
    double? defaultValue,
  }) {
    return ParamSpec.internal(
      type: ParamType.double,
      required: required,
      defaultValue: defaultValue,
    );
  }

  factory ParamSpec.bool({
    bool required = false,
    bool? defaultValue,
  }) {
    return ParamSpec.internal(
      type: ParamType.bool,
      required: required,
      defaultValue: defaultValue,
    );
  }
}

class InspectorAction {
  final Map<String, ParamSpec> params;
  final void Function(Ref ref, Map<String, dynamic> params) action;

  InspectorAction({
    required this.params,
    required this.action,
  });
}
