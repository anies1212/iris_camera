import 'package:flutter/material.dart';

import 'screens/camera_experience_page.dart';

class IrisCameraExampleApp extends StatelessWidget {
  const IrisCameraExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const CameraExperiencePage(),
    );
  }
}
