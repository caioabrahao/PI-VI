import 'package:flutter/material.dart';

import '../theme.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _abrirLogin();
  }

  Future<void> _abrirLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hub, size: 160, color: c.mint),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: c.mint, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
