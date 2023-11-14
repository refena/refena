import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/ref.dart';
import 'package:refena_flutter/src/extension.dart';

mixin Refena<W extends StatefulWidget> on State<W> {
  /// Access this ref inside your [State].
  late final WatchableRef ref = context.ref;

  bool _initialBuild = true;

  /// Call this method inside [initState] to have some
  /// initializations run after the first frame.
  /// The [ref] (without watch) will be available in the callback.
  ///
  /// This is entirely optional but has some nice side effects
  /// that you can even use [ref] in [State.dispose] because [ref] is
  /// guaranteed to be initialized.
  void ensureRef([void Function(Ref ref)? callback]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref; // ignore: unnecessary_statements
      callback?.call(ref);
    });
  }

  /// Call this method inside [build] to initialize a variable
  /// before the first frame.
  ///
  /// This might be needed if you are dealing with
  /// e.g. [TextFormField.initialValue].
  void initialBuild<R>(void Function(Ref ref) callback) {
    if (_initialBuild) {
      _initialBuild = false;

      if (kDebugMode && (context as Element).debugDoingBuild == false) {
        print('''
$_red[Refena] In ${widget.runtimeType}, initialBuild() is called outside a build method$_reset''');
        print('''
$_red[Refena] A non-breaking stacktrace will be printed for easier debugging:$_reset\n${StackTrace.current}''');
        return;
      }

      // ignore: unnecessary_cast
      final result = callback(ref) as Object?;

      assert(() {
        if (result is Future) {
          throw FlutterError.fromParts([
            ErrorSummary('[Refena] initialBuild() returned a Future.'),
            ErrorDescription(
              'initialBuild() must be a void method without an `async` keyword.',
            ),
          ]);
        }
        return true;
      }());
    }
  }
}

const _red = '\x1B[31m';
const _reset = '\x1B[0m';
