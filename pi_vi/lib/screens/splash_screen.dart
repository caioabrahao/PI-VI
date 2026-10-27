
import 'package:flutter/material.dart';

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

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF080B0F),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [

            const Icon(
              Icons.hub,
              size: 160,
              color: Color(0xFF4FE0C0),
            ),

            const SizedBox(height: 32),

            const CircularProgressIndicator(
              color: Color(0xFF4FE0C0),
              strokeWidth: 3,
            ),

          ],
        ),
      ),
    );
  }
}
