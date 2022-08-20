import 'package:meta/meta.dart';

/// {@template connection_exception}
/// Wrapper for exceptions to pass between isolates
/// {@endtemplate}
@internal
@immutable
class IsolateException implements Exception {
  /// {@macro connection_exception}
  IsolateException(this.exception, [StackTrace? stackTrace])
      : _stackTraceString = stackTrace?.toString();

  /// Exception
  final Object exception;

  /// Stack trace
  StackTrace? get stackTrace => _stackTraceString == null
      ? null
      : StackTrace.fromString(_stackTraceString!);

  final String? _stackTraceString;
}
