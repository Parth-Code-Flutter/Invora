import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          tween: Tween(begin: .82, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 1.03 - (.03 * value), child: child),
          ),
          child: Image.asset(
            'assets/images/creovo_warm_splash.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
