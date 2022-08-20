import 'dart:async';

import 'package:isolation/src/channel.dart';
import 'package:isolation/src/exception.dart';
import 'package:isolation/src/logging.dart';
import 'package:meta/meta.dart';

/// {@template connection}
/// Base class for master and slave isolate connections.
/// {@endtemplate}
@internal
abstract class Connection<In, Out> implements EventSink<In> {
  /// {@macro connection}
  Connection({
    required this.dataChannel,
    required this.exceptionChannel,
    required this.serviceChannel,
  });

  /// Channel for data
  @protected
  @nonVirtual
  final IsolateChannel<In, Out> dataChannel;

  /// Channel for exceptions
  @protected
  @nonVirtual
  final IsolateChannel<IsolateException, IsolateException> exceptionChannel;

  /// Channel for service messages
  @protected
  @nonVirtual
  final IsolateChannel<Object?, Object?> serviceChannel;

  /// Connection status
  ConnectionStatus get status => _status;
  ConnectionStatus _status = ConnectionStatus.notConnected;

  /// Establish connection with another isolate
  @mustCallSuper
  Future<void> connect() async {
    _status = ConnectionStatus.connected;
  }

  @override
  @mustCallSuper
  void add(In data) {
    fine('Connection.add(${data.hashCode})');
    assert(_status.isOpened, 'Connection is already closed.');
    if (!_status.isOpened) return;
    dataChannel.add(data);
  }

  @override
  @mustCallSuper
  void addError(Object error, [StackTrace? stackTrace]) {
    fine('Connection.addError(${Error.safeToString(error)})');
    assert(_status.isOpened, 'Connection is already closed.');
    if (!_status.isOpened) return;
    exceptionChannel.add(IsolateException(error, stackTrace));
  }

  /// Add service message
  @protected
  @mustCallSuper
  void addServiceMessage(Object? message) {
    assert(_status.isOpened, 'Connection is not opened.');
    if (!_status.isOpened) return;
    serviceChannel.add(message);
  }

  @override
  @mustCallSuper
  FutureOr<void> close({bool force = false}) {
    if (_status.isClosed) return null;
    _status = ConnectionStatus.disconnected;
    if (!force) {
      // TODO: await graceful closing
      // Matiunin Mikhail <plugfox@gmail.com>, 07 August 2022
      //throw UnimplementedError('Connection.close(force: false)');
    }
    dataChannel.close();
    exceptionChannel.close();
    serviceChannel.close();
  }
}

/// {@nodoc}
@internal
enum ConnectionStatus {
  /// {@nodoc}
  notConnected('Connection is not established yet'),

  /// {@nodoc}
  connected('Connection is established'),

  /// {@nodoc}
  disconnected('Disconnected from isolate');

  /// {@nodoc}
  const ConnectionStatus(this.message);

  /// {@nodoc}
  final String message;

  /// {@nodoc}
  bool get isNotConnected => this == notConnected;

  /// {@nodoc}
  bool get isOpened => this == connected;

  /// {@nodoc}
  bool get isClosed => this == disconnected;

  @override
  String toString() => Error.safeToString(this);
}
