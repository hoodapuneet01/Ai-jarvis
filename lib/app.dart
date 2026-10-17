import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'services/command_store.dart';
import 'theme.dart';

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key, required this.store});

  final CommandStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAssistantName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(store: store),
    );
  }
}
