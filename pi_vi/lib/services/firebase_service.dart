import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get usuarioAtual => _auth.currentUser;

  // Criar conta e enviar e-mail de verificação nativo
  static Future<UserCredential> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );

    final usuario = credencial.user!;

    try {
      await usuario.updateDisplayName(nome.trim());

      // Salva perfil no Firestore
      await _db.collection('usuarios').doc(usuario.uid).set({
        'uid': usuario.uid,
        'nome': nome.trim(),
        'email': email.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // Dispara o e-mail nativo do Firebase
      await usuario.sendEmailVerification();

      return credencial;
    } catch (e) {
      try {
        await usuario.delete();
      } catch (_) {}
      rethrow;
    }
  }

  // Realizar login e verificar se o e-mail foi confirmado
  static Future<UserCredential> login({
    required String email,
    required String senha,
  }) async {
    final credencial = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );

    // Recarrega os dados do utilizador para atualizar o estado de emailVerified
    await credencial.user?.reload();
    final usuarioAtualizado = _auth.currentUser;

    if (usuarioAtualizado != null && !usuarioAtualizado.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'E-mail não verificado.',
      );
    }

    return credencial;
  }

  // Reenviar e-mail de verificação caso o utilizador não o tenha recebido
  static Future<void> reenviarEmailVerificacao({
    required String email,
    required String senha,
  }) async {
    final credencial = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );

    await credencial.user?.sendEmailVerification();
    await _auth.signOut();
  }

  // Enviar e-mail para redefinir a senha
  static Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Alterar a senha do usuário autenticado
  static Future<void> alterarSenha(String novaSenha) async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Faça login novamente para alterar sua senha.');
    }

    await usuario.updatePassword(novaSenha);
  }

  // Encerrar a sessão
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Obter os dados do usuário no Firestore
  
static Future<Map<String, dynamic>?> obterPerfil(String uid) async {
  final documento = await _db
      .collection('usuarios')
      .doc(uid)
      .get();

  if (!documento.exists) {
    return null;
  }

  return documento.data();
}


  static Future<void> atualizarCidadeCasa(String cidade) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw StateError('Faça login novamente para editar sua casa.');
    }

    await _db.collection('usuarios').doc(usuario.uid).set({
      'cidade': cidade.trim(),
    }, SetOptions(merge: true));
  }
}