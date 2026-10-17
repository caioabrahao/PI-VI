import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';
import 'cadastro.dart';
import 'dashboard.dart';

const bg = Color(0xFF080B0F);
const panel = Color(0xFF10151B);
const panel2 = Color(0xFF171E26);
const border = Color(0xFF293640);
const muted = Color(0xFF8A98A5);
const fg = Color(0xFFF1F5F8);
const mint = Color(0xFF4FE0C0);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final senha = TextEditingController();

  bool mostrarSenha = false;
  bool carregando = false;
  bool enviandoRecuperacao = false;

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  void mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String erroFirebase(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'invalid-email':
          return 'O formato do e-mail é inválido.';
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'E-mail ou senha incorretos.';
        case 'user-disabled':
          return 'Esta conta foi desativada.';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente novamente mais tarde.';
        case 'network-request-failed':
          return 'Sem conexão. Verifique sua internet.';
        case 'operation-not-allowed':
          return 'Ative o login por e-mail e senha no Firebase.';
        default:
          return 'Não foi possível entrar. (${erro.code})';
      }
    }

    return 'Ocorreu um erro. Verifique sua conexão e tente novamente.';
  }

  Future<void> entrar() async {
    if (!form.currentState!.validate()) return;

    setState(() => carregando = true);

    try {
      await FirebaseService.login(email: email.text, senha: senha.text);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } catch (e) {
      mensagem(erroFirebase(e));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> recuperarSenha() async {
    final controller = TextEditingController(text: email.text.trim());

    final emailRecuperacao = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel2,
        title: const Text('Recuperar senha', style: TextStyle(color: fg)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          style: const TextStyle(color: fg),
          decoration: const InputDecoration(
            labelText: 'Seu e-mail',
            hintText: 'voce@exemplo.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (emailRecuperacao == null || emailRecuperacao.isEmpty) return;

    setState(() => enviandoRecuperacao = true);

    try {
      await FirebaseService.recuperarSenha(emailRecuperacao);
      mensagem(
        'Se o e-mail estiver cadastrado, você receberá as instruções de recuperação.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        mensagem('Digite um e-mail válido.');
      } else if (e.code == 'network-request-failed') {
        mensagem('Sem conexão. Verifique sua internet.');
      } else {
        mensagem('Não foi possível enviar o e-mail. Tente novamente.');
      }
    } catch (_) {
      mensagem('Erro ao enviar o e-mail de recuperação.');
    } finally {
      if (mounted) setState(() => enviandoRecuperacao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 46, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 70),
              child: IntrinsicHeight(
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF153D36),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.home_work_outlined,
                              color: mint,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Text(
                            'COS',
                            style: TextStyle(
                              color: fg,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Sua casa, em\nsintonia.',
                        style: TextStyle(
                          color: fg,
                          fontSize: 36,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Controle ambientes, economize energia e cuide\nde quem importa.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text('E-mail', style: TextStyle(color: muted)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: fg),
                        decoration: _decoracao(
                          'Seu e-mail',
                          Icons.mail_outline,
                        ),
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return 'Informe um e-mail válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Senha', style: TextStyle(color: muted)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: senha,
                        obscureText: !mostrarSenha,
                        style: const TextStyle(color: fg),
                        decoration: _decoracao('Sua senha', Icons.lock_outline)
                            .copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => mostrarSenha = !mostrarSenha,
                                ),
                                icon: Icon(
                                  mostrarSenha
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: muted,
                                ),
                              ),
                            ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe sua senha.';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: enviandoRecuperacao
                              ? null
                              : recuperarSenha,
                          child: Text(
                            enviandoRecuperacao
                                ? 'Enviando...'
                                : 'Esqueci minha senha',
                            style: const TextStyle(color: mint, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: carregando ? null : entrar,
                          icon: carregando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: bg,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward, size: 19),
                          label: Text(
                            carregando ? 'Entrando...' : 'Entrar',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mint,
                            foregroundColor: bg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 50),
                      const Center(
                        child: Icon(Icons.fingerprint, color: mint, size: 32),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Entre com seu e-mail e senha',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            const Text(
                              'Ainda não tem conta? ',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CadastroScreen(),
                                ),
                              ),
                              child: const Text(
                                'Criar cadastro',
                                style: TextStyle(
                                  color: mint,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoracao(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: muted),
    prefixIcon: Icon(icon, color: muted, size: 19),
    filled: true,
    fillColor: panel,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: mint),
    ),
  );
}
