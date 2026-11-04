import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SocialAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void>? _inicializacaoGoogle;

  // =====================================================
  // LOGIN COM GOOGLE
  // =====================================================

  static Future<UserCredential> entrarComGoogle() async {
    late final UserCredential resultado;

    if (kIsWeb) {
      // Flutter Web / Edge:
      // abre uma janela de autenticação do Google.
      final provider = GoogleAuthProvider();

      provider.setCustomParameters({'prompt': 'select_account'});

      resultado = await _auth.signInWithPopup(provider);
    } else {
      // Android / iOS:
      // utiliza a conta Google do dispositivo.
      _inicializacaoGoogle ??= GoogleSignIn.instance.initialize();

      await _inicializacaoGoogle;

      final conta = await GoogleSignIn.instance.authenticate();

      final autenticacao = conta.authentication;

      final credencial = GoogleAuthProvider.credential(
        idToken: autenticacao.idToken,
      );

      resultado = await _auth.signInWithCredential(credencial);
    }

    await _garantirPerfil(resultado.user);

    return resultado;
  }

  // =====================================================
  // CRIAR / ATUALIZAR PERFIL NO FIRESTORE
  // =====================================================

  static Future<void> _garantirPerfil(User? usuario) async {
    if (usuario == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Usuário não encontrado após o login.',
      );
    }

    final referencia = _db.collection('usuarios').doc(usuario.uid);

    try {
      // Preserva cidade e configurações existentes.
      // Não cria dispositivos de demonstração.
      await referencia.set({
        'uid': usuario.uid,
        'nome':
            usuario.displayName ??
            usuario.email?.split('@').first ??
            'Usuário COS',
        'email': usuario.email ?? '',
        'fotoUrl': usuario.photoURL,
        'ultimoLoginEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (erro) {
      // O login já foi realizado no Firebase Auth.
      // Uma falha de sincronização não deve forçar
      // o usuário a fazer login novamente.
      debugPrint(
        'Erro ao sincronizar perfil: '
        '${erro.code} - ${erro.message}',
      );
    }
  }

  // =====================================================
  // TRATAMENTO DE ERROS
  // =====================================================

  static String mensagemErro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'web-context-cancelled':
          return 'Login com Google cancelado.';

        case 'popup-blocked':
          return 'O navegador bloqueou a janela '
              'do Google. Permita pop-ups para o COS.';

        case 'operation-not-allowed':
          return 'Ative o provedor Google no '
              'Firebase Authentication.';

        case 'unauthorized-domain':
          return 'O domínio do aplicativo não está '
              'autorizado no Firebase.';

        case 'account-exists-with-different-credential':
          return 'Este e-mail já está associado a outro '
              'método de login. Entre pelo método '
              'original para vincular sua conta.';

        case 'network-request-failed':
          return 'Erro de conexão com a internet.';

        case 'user-disabled':
          return 'Esta conta foi desativada.';

        default:
          return erro.message ?? 'Erro no Google: ${erro.code}';
      }
    }

    if (erro is GoogleSignInException) {
      return 'Não foi possível entrar com Google: '
          '${erro.description ?? erro.code.name}';
    }

    return 'Erro ao entrar com Google: $erro';
  }
}
