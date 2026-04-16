import 'package:logger/logger.dart';

class LoggerUtil {
  static LoggerUtil _instance = LoggerUtil._();
  LoggerUtil._();
  static LoggerUtil get getInstance => _instance ??= LoggerUtil._();

  Logger logger = Logger(printer: PrettyPrinter());
  Logger loggerNoStack = Logger(printer: PrettyPrinter(methodCount: 0));

  print(dynamic message) {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      loggerNoStack.d('app is in release mode');
    } else {
      loggerNoStack.d(message ?? "null");
    }
  }
}
