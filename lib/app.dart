import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'services/app_services.dart';
import 'theme.dart';

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAssistantName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(services: services),
    );
  }
}
