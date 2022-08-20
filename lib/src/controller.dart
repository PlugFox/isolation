import 'dart:async';

import 'package:isolation/src/controller_master.dart';
import 'package:isolation/src/handler.dart';

/// {@template isolate_controller}
/// Isolate controller.
/// {@endtemplate}
abstract class IsolateController<Input, Output> implements EventSink<Input> {
  /// {@macro isolate_controller}
  factory IsolateController(
    IsolateHandler<Input, Output> handler, {
    bool lazy,
    String? debugLabel,
  }) = IsolateControllerMasterImpl<Input, Output>;

  /// Output data & error stream
  Stream<Output> get stream;

  /// Whether the stream controller is closed for adding more events.
  ///
  /// The controller becomes closed by calling the [close] method.
  /// New events cannot be added, by calling [add] or [addError],
  /// to a closed controller.
  ///
  /// If the controller is closed,
  /// the "done" event might not have been delivered yet,
  /// but it has been scheduled, and it is too late to add more events.
  bool get isClosed;

  /// Closes the sink.
  ///
  /// Calling this method more than once is allowed, but does nothing.
  ///
  /// Neither [add] nor [addError] must be called after this method.
  ///
  /// Graceful:
  /// close() -> isClosed = true -> close input sink
  /// -> send close service message -> await close service message
  /// -> kill isolate -> close output controller
  ///
  /// Force:
  /// close() -> isClosed = true -> close input sink
  /// -> kill isolate -> close output controller
  @override
  Future<void> close({bool force = false});
}
