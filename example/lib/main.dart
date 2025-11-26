import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        // Surface Flutter framework errors to the console.
        FlutterError.presentError(details);
      };

      runApp(const IrisCameraExampleApp());
    },
    (error, stack) {
      // Catch uncaught async errors and print them for easier debugging.
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'main'),
      );
    },
  );
}
