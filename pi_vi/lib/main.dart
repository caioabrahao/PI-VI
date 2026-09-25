import 'package:flutter/material.dart';

// Import do Plug-in principal do Firebase
import 'package:firebase_core/firebase_core.dart';

// Import do arquivo de configuração do Firebase
import 'firebase_options.dart';

// Import do Splash Screen inicial
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoS HUB',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
