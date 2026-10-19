import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get usuarioAtual => _auth.currentUser;

  // Entrar com e-mail e senha
  static Future<UserCredential> login({
    required String email,
    required String senha,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  // Criar conta e salvar somente os dados do perfil no Firestore
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

      await _db.collection('usuarios').doc(usuario.uid).set({
        'uid': usuario.uid,
        'nome': nome.trim(),
        'email': email.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return credencial;
    } catch (e) {
      // Tenta remover a conta caso ocorra uma falha ao salvar o perfil.
      try {
        await usuario.delete();
      } catch (_) {
        // A exclusão pode falhar se a sessão exigir autenticação recente.
      }

      rethrow;
    }
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
    final documento = await _db.collection('usuarios').doc(uid).get();

    if (!documento.exists) {
      return null;
    }

    return documento.data();
  }
}
