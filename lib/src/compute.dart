import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:meta/meta.dart';

/// Signature for the callback passed to [compute].
///
/// Instances of [ComputeCallback] must be functions that can be sent to an
/// isolate.
typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

/// The dart:io implementation of [compute].
Future<R> compute<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
}) async {
  debugLabel ??= const bool.fromEnvironment('dart.vm.product')
      ? 'compute'
      : callback.toString();

  final flow = Flow.begin();
  Timeline.startSync('$debugLabel: start', flow: flow);
  final port = RawReceivePort();
  Timeline.finishSync();

  void timeEndAndCleanup() {
    Timeline.startSync('$debugLabel: end', flow: Flow.end(flow.id));
    port.close();
    Timeline.finishSync();
  }

  final completer = Completer<dynamic>();
  port.handler = (dynamic msg) {
    timeEndAndCleanup();
    completer.complete(msg);
  };

  try {
    await Isolate.spawn<_IsolateConfiguration<Q, R>>(
      _spawn,
      _IsolateConfiguration<Q, R>(
        callback,
        message,
        port.sendPort,
        debugLabel,
        flow.id,
      ),
      onExit: port.sendPort,
      onError: port.sendPort,
      debugName: debugLabel,
    );
  } on Object {
    timeEndAndCleanup();
    rethrow;
  }

  final dynamic response = await completer.future;
  if (response == null) {
    throw RemoteError('Isolate exited without result or error.', '');
  }

  assert(response is List<Object?>, 'Unexpected response type: $response');
  response as List<dynamic>;

  final type = response.length;
  assert(1 <= type && type <= 3, 'Unexpected response type: $type');

  switch (type) {
    // success; see _buildSuccessResponse
    case 1:
      return response[0] as R;

    // native error; see Isolate.addErrorListener
    case 2:
      await Future<Never>.error(
        RemoteError(
          response[0] as String,
          response[1] as String,
        ),
      );

    // caught error; see _buildErrorResponse
    case 3:
    default:
      assert(
        type == 3 && response[2] == null,
        'Unexpected response type',
      );

      await Future<Never>.error(
        response[0] as Object,
        response[1] as StackTrace,
      );
  }
}

@immutable
class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
    this.flowId,
  );
  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  FutureOr<R> applyAndTime() => Timeline.timeSync(
        debugLabel,
        () => callback(message),
        flow: Flow.step(flowId),
      );
}

/// The spawn point MUST guarantee only one result event is sent through the
/// [SendPort.send] be it directly or indirectly i.e. [Isolate.exit].
///
/// In case an [Error] or [Exception] are thrown AFTER the data
/// is sent, they will NOT be handled or reported by the main [Isolate] because
/// it stops listening after the first event is received.
///
/// Also use the helpers [_buildSuccessResponse] and [_buildErrorResponse] to
/// build the response
Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, R> configuration) async {
  late final List<dynamic> computationResult;

  try {
    computationResult =
        _buildSuccessResponse<R>(await configuration.applyAndTime());
  } on Object catch (e, s) {
    computationResult = _buildErrorResponse(e, s);
  }

  Isolate.exit(configuration.resultPort, computationResult);
}

/// Wrap in [List] to ensure our expectations in the main [Isolate] are met.
///
/// We need to wrap a success result in a [List] because the user provided type
/// [R] could also be a [List]. Meaning, a check `result is R` could return true
/// for what was an error event.
List<R> _buildSuccessResponse<R>(R result) => List<R>.filled(1, result);

/// Wrap in [List] to ensure our expectations in the main isolate are met.
///
/// We wrap a caught error in a 3 element [List]. Where the last element is
/// always null. We do this so we have a way to know if an error was one we
/// caught or one thrown by the library code.
List<dynamic> _buildErrorResponse(Object error, StackTrace stack) =>
    List<dynamic>.filled(3, null)
      ..[0] = error
      ..[1] = stack;
