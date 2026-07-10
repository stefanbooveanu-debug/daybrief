import 'dart:developer' as developer;

class DayBriefLog {
  DayBriefLog._();

  static void debug(String msg, {Object? error, StackTrace? st}) => developer
      .log(msg, name: 'daybrief', level: 500, error: error, stackTrace: st);

  static void info(String msg) =>
      developer.log(msg, name: 'daybrief', level: 800);

  static void warning(String msg, {Object? error}) =>
      developer.log(msg, name: 'daybrief', level: 900, error: error);

  static void error(String msg, {required Object error, StackTrace? st}) =>
      developer.log(msg,
          name: 'daybrief', level: 1000, error: error, stackTrace: st);
}
