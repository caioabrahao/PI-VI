import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/dashboard.dart';

// =====================================================
// INICIALIZAÇÃO DO COS
// =====================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // No Flutter Web, mantém a sessão mesmo depois
  // que o navegador ou a aba forem fechados.
  //
  // No Android/iOS, o Firebase já persiste a
  // autenticação automaticamente.
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(const COSApp());
}

// =====================================================
// APLICATIVO PRINCIPAL
// =====================================================

class COSApp extends StatelessWidget {
  const COSApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF080B0F);
    const Color primaryColor = Color(0xFF4FE0C0);
    const Color surfaceColor = Color(0xFF10151B);
    const Color textColor = Color(0xFFF1F5F8);
    const Color mutedColor = Color(0xFF8A98A5);
    const Color borderColor = Color(0xFF293640);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COS - Casa Inteligente',

      // =================================================
      // TEMA ORIGINAL
      // =================================================
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        useMaterial3: true,

        colorScheme:
            ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
            ).copyWith(
              primary: primaryColor,
              secondary: primaryColor,
              surface: surfaceColor,
              onPrimary: backgroundColor,
              onSurface: textColor,
            ),

        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          hintStyle: const TextStyle(color: mutedColor),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
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
            backgroundColor: primaryColor,
            foregroundColor: backgroundColor,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: primaryColor,
          selectionColor: Color(0x6655E6C1),
          selectionHandleColor: primaryColor,
        ),
      ),

      // Antes: home: const SplashScreen(),
      //
      // Agora o COS verifica se já existe
      // uma sessão autenticada.
      home: const _VerificadorDeSessao(),
    );
  }
}

// =====================================================
// VERIFICADOR DE SESSÃO
// =====================================================

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

    // A verificação acontece uma única vez
    // quando o aplicativo é iniciado.
    _sessaoValida = _verificarSessao();
  }

  Future<bool> _verificarSessao() async {
    try {
      // Aguarda o Firebase restaurar a autenticação
      // armazenada no dispositivo ou navegador.
      final usuario = await FirebaseAuth.instance.authStateChanges().first;

      // Não há usuário conectado.
      if (usuario == null) {
        return false;
      }

      // Mantém a regra original do COS:
      // contas de e-mail e senha precisam
      // verificar o endereço de e-mail.
      final usaSenha = usuario.providerData.any(
        (provedor) => provedor.providerId == 'password',
      );

      if (usaSenha && !usuario.emailVerified) {
        await FirebaseAuth.instance.signOut();
        return false;
      }

      // Sessão existente e válida para continuar.
      return true;
    } catch (erro) {
      debugPrint('Erro ao restaurar sessão COS: $erro');

      // Se não for possível verificar a sessão,
      // não concede acesso automaticamente.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessaoValida,
      builder: (context, snapshot) {
        // =============================================
        // VERIFICANDO A SESSÃO
        // =============================================

        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF080B0F),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, color: Color(0xFF4FE0C0), size: 58),

                  SizedBox(height: 22),

                  Text(
                    'COS',
                    style: TextStyle(
                      color: Color(0xFFF1F5F8),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Verificando sua sessão...',
                    style: TextStyle(color: Color(0xFF8A98A5), fontSize: 12),
                  ),

                  SizedBox(height: 24),

                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF4FE0C0),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // =============================================
        // USUÁRIO JÁ AUTENTICADO
        // =============================================

        if (snapshot.data == true) {
          return const DashboardScreen();
        }

        // =============================================
        // USUÁRIO SEM SESSÃO
        // =============================================

        return const SplashScreen();
      },
    );
  }
}
