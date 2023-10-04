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
}
