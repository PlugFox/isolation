import 'dart:isolate';

import 'package:isolation/src/connection.dart';
import 'package:isolation/src/connection_slave.dart';
import 'package:isolation/src/controller_base.dart';
import 'package:meta/meta.dart';

/// {@nodoc}
@internal
class IsolateControllerSlaveImpl<Input, Output>
    extends IsolateControllerBase<Input, Output> {
  /// {@nodoc}
  IsolateControllerSlaveImpl({
    required SendPort dataSendPort,
    required SendPort exceptiondataSendPort,
    required SendPort servicedataSendPort,
    super.debugLabel = 'IsolateControllerSlave',
  }) {
    connection = SlaveConnection<Input, Output>(
      dataSendPort: dataSendPort,
      exceptiondataSendPort: exceptiondataSendPort,
      servicedataSendPort: servicedataSendPort,
      out: outputController,
    );
  }

  @override
  // ignore: close_sinks
  late final Connection<Input, Output> connection;
}
