import 'package:flutter/foundation.dart';

class Logger {
  static const String _tag = "CLUSTY";  // Your app tag

  // ANSI escape codes for colors
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _bold = '\x1B[1m';

  static void v(String message) {
    _log('${_white}VERBOSE$_reset', message);
  }

  static void d(String message) {
    _log('${_cyan}DEBUG$_reset', message);
  }

  static void i(String message) {
    _log('${_green}INFO$_reset', message);
  }

  static void w(String message) {
    _log('${_yellow}WARN$_reset', message);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('${_red}ERROR$_reset', message);
    if (error != null) {
      _log('${_red}ERROR$_reset', 'Error details: $error');
    }
    if (stackTrace != null) {
      _log('${_red}ERROR$_reset', 'Stack trace:\n$stackTrace');
    }
  }

  static void wtf(String message) {
    _log('${_bold}${_red}ASSERT$_reset', message);
  }

  static void _log(String level, String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString().split('.').first;
      print('$_magenta$timestamp$_reset $_bold[$_tag]$_reset $level: $message');
    }
  }
}
