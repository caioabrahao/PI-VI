import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'theme.dart';

import 'screens/splash_screen.dart';
import 'screens/dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(const COSApp());
}

class COSApp extends StatelessWidget {
  const COSApp({super.key});

  ThemeData _darkTheme() {
    const bg = Color(0xFF080B0F);
    const primary = Color(0xFF4FE0C0);
    const surface = Color(0xFF10151B);
    const text = Color(0xFFF1F5F8);
    const muted = Color(0xFF8A98A5);
    const border = Color(0xFF293640);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
          ).copyWith(
            primary: primary,
            secondary: primary,
            surface: surface,
            onPrimary: bg,
            onSurface: text,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bg,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x6655E6C1),
        selectionHandleColor: primary,
      ),
    );
  }

  ThemeData _lightTheme() {
    const bg = Color(0xFFF3F7F6);
    const primary = Color(0xFF00836F);
    const surface = Color(0xFFFFFFFF);
    const text = Color(0xFF172C30);
    const muted = Color(0xFF566970);
    const border = Color(0xFFD6E2DF);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.light,
          ).copyWith(
            primary: primary,
            secondary: primary,
            surface: surface,
            onPrimary: Colors.white,
            onSurface: text,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x6600836F),
        selectionHandleColor: primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: perfilThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'COS - Casa Inteligente',
          themeMode: mode,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          home: const _VerificadorDeSessao(),
        );
      },
    );
  }
}

class _VerificadorDeSessao extends StatefulWidget {
  const _VerificadorDeSessao();

  @override
  State<_VerificadorDeSessao> createState() => _VerificadorDeSessaoState();
}

class _VerificadorDeSessaoState extends State<_VerificadorDeSessao> {
  late final Future<bool> _sessaoValida;

  @override
  void initState() {
    super.initState();
    _sessaoValida = _verificarSessao();
  }

  Future<bool> _verificarSessao() async {
    try {
      final usuario = await FirebaseAuth.instance.authStateChanges().first;

      if (usuario == null) return false;

      final usaSenha = usuario.providerData.any(
        (provedor) => provedor.providerId == 'password',
      );

      if (usaSenha && !usuario.emailVerified) {
        await FirebaseAuth.instance.signOut();
        return false;
      }

      return true;
    } catch (erro) {
      debugPrint('Erro ao restaurar sessão COS: $erro');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessaoValida,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final c = CosColors.of(context);
          return Scaffold(
            backgroundColor: c.bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, color: c.mint, size: 58),
                  const SizedBox(height: 22),
                  Text(
                    'COS',
                    style: TextStyle(
                      color: c.fg,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verificando sua sessão...',
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: c.mint,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const DashboardScreen();
        }

        return const SplashScreen();
      },
    );
  }
}
