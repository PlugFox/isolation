import 'dart:developer' as developer;

/// Tracing information
final void Function(Object? message) fine = _logAll('FINE', 500);

/// Static configuration messages
final void Function(Object? message) config = _logAll('CONF', 700);

/// Iformational messages
final void Function(Object? message) info = _logAll('INFO', 800);

/// Potential problems
final void Function(Object exception, [StackTrace? stackTrace, String? reason])
    warning = _logAll('WARN', 900);

/// Serious failures
final void Function(Object error, [StackTrace stackTrace, String? reason])
    severe = _logAll('ERR!', 1000);

void Function(
  Object? message, [
  StackTrace? stackTrace,
  String? reason,
]) _logAll(String prefix, int level) =>
    (Object? message, [StackTrace? stackTrace, String? reason]) {
      //if (Zone.current[kLogEnabled] != true) return;
      developer.log(
        '[$prefix] ${reason ?? message}',
        level: level,
        name: 'isolation',
        error: message is Exception || message is Error ? message : null,
        stackTrace: stackTrace,
      );
    };
