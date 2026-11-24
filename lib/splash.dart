import 'package:flutter/material.dart';
import 'logo.dart';
import 'theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _title = 'LC STUDIO';
  late final AnimationController _c;
  late final Animation<double> _logo;
  late final Animation<double> _typing;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
    _logo = CurvedAnimation(
        parent: _c,
        curve: const Interval(0, 0.2778, curve: Curves.easeOutCubic));
    _typing = CurvedAnimation(
        parent: _c,
        curve: const Interval(0.2778, 0.7222, curve: Curves.linear));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: appGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final n = (_typing.value * _title.length)
                  .ceil()
                  .clamp(0, _title.length);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: _logo.value,
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * _logo.value,
                      child: CustomPaint(
                          size: const Size(132, 132), painter: LcLogoPainter()),
                    ),
                  ),
                  const SizedBox(height: 36),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                      ),
                      children: [
                        TextSpan(
                            text: _title.substring(0, n),
                            style: const TextStyle(color: AppColors.text)),
                        TextSpan(
                            text: _title.substring(n),
                            style: const TextStyle(color: Colors.transparent)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
