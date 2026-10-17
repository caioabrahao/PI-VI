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

  // Criar conta e salvar os dados no Firestore
  static Future<UserCredential> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String casa,
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
        'casa': casa.trim(),
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Se o cadastro no banco falhar, remove a conta criada
      // para evitar uma conta parcialmente cadastrada.
      try {
        await usuario.delete();
      } catch (_) {}
      rethrow;
    }

    return credencial;
  }

  // Enviar e-mail para redefinir a senha
  static Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Encerrar a sessão
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Obter os dados do usuário no Firestore
  static Future<Map<String, dynamic>?> obterPerfil(String uid) async {
    final documento = await _db.collection('usuarios').doc(uid).get();

    if (!documento.exists) return null;

    return documento.data();
  }
}
