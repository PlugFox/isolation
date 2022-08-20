import 'package:isolation/src/connection.dart';
import 'package:isolation/src/connection_master.dart';
import 'package:isolation/src/controller_base.dart';
import 'package:isolation/src/handler.dart';
import 'package:meta/meta.dart';

/// {@nodoc}
@internal
class IsolateControllerMasterImpl<Input, Output>
    extends IsolateControllerBase<Input, Output> {
  /// {@nodoc}
  IsolateControllerMasterImpl(
    IsolateHandler<Input, Output> handler, {
    bool lazy = true,
    super.debugLabel = 'IsolateControllerMaster',
  }) {
    connection = MasterConnection<Input, Output>(
      handler: handler,
      out: outputController,
      debugName: debugLabel,
    );
    if (!lazy) {
      eventQueue.add(connection.connect);
    }
  }

  @override
  // ignore: close_sinks
  late final Connection<Input, Output> connection;
}
