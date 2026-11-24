import 'package:flutter/material.dart';
import 'splash.dart';
import 'theme.dart';
import 'ui_home.dart';

void main() => runApp(const TriPhotosApp());

class TriPhotosApp extends StatefulWidget {
  const TriPhotosApp({super.key});

  @override
  State<TriPhotosApp> createState() => _TriPhotosAppState();
}

class _TriPhotosAppState extends State<TriPhotosApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tri Photos',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _splashDone
            ? const HomeScreen(key: ValueKey('home'))
            : SplashScreen(
                key: const ValueKey('splash'),
                onDone: () => setState(() => _splashDone = true),
              ),
      ),
    );
  }
}
