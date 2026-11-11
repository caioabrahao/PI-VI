import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';
import '../theme.dart';
import 'login.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final form = GlobalKey<FormState>();
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final confirmarSenha = TextEditingController();

  bool aceitou = false;
  bool mostrarSenha = false;
  bool carregando = false;

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    confirmarSenha.dispose();
    super.dispose();
  }

  void mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String erroCadastro(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'email-already-in-use':
          return 'Este e-mail já possui uma conta.';
        case 'invalid-email':
          return 'O e-mail informado é inválido.';
        case 'weak-password':
          return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
        case 'network-request-failed':
          return 'Sem conexão. Verifique sua internet.';
        default:
          return 'Não foi possível criar a conta (${erro.code}).';
      }
    }
    return 'Não foi possível salvar os dados. Tente novamente.';
  }

  Future<void> criarConta() async {
    if (!form.currentState!.validate()) return;
    if (!aceitou) {
      mensagem('Aceite os termos para continuar.');
      return;
    }

    setState(() => carregando = true);

    try {
      await FirebaseService.cadastrar(
        nome: nome.text,
        email: email.text,
        senha: senha.text,
      );

      if (!mounted) return;

      final c = CosColors.of(context);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.panel2,
          title: Text('Confirme o seu e-mail', style: TextStyle(color: c.fg)),
          content: Text(
            'Enviamos um link de confirmação para ${email.text}. '
            'Acesse a sua caixa de entrada e clique no link para ativar a sua conta.',
            style: TextStyle(color: c.muted, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.mint,
                foregroundColor: c.bg,
              ),
              child: const Text('OK, ir para o login'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      mensagem(erroCadastro(e));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  InputDecoration _campo(
    CosColors c,
    String dica, {
    IconData? icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: TextStyle(color: c.muted),
      prefixIcon: icone == null ? null : Icon(icone, color: c.muted, size: 19),
      suffixIcon: sufixo,
      filled: true,
      fillColor: c.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.mint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 38),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.chevron_left),
                          style: IconButton.styleFrom(
                            backgroundColor: c.panel2,
                            foregroundColor: c.fg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Criar conta',
                            style: TextStyle(
                              color: c.fg,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bem-vindo ao COS.',
                      style: TextStyle(
                        color: c.fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Comece pela sua conta. A casa vem logo depois.',
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nome completo',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: nome,
                      style: TextStyle(color: c.fg, fontSize: 14),
                      autofillHints: const [AutofillHints.name],
                      decoration: _campo(
                        c,
                        'Seu nome',
                        icone: Icons.person_outline,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'E-mail',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: email,
                      style: TextStyle(color: c.fg, fontSize: 14),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: _campo(
                        c,
                        'voce@exemplo.com',
                        icone: Icons.mail_outline,
                      ),
                      validator: (v) {
                        if (v == null || !v.contains('@')) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Senha',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: senha,
                      style: TextStyle(color: c.fg, fontSize: 14),
                      obscureText: !mostrarSenha,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _campo(
                        c,
                        'Mínimo de 6 caracteres',
                        icone: Icons.lock_outline,
                        sufixo: IconButton(
                          onPressed: () =>
                              setState(() => mostrarSenha = !mostrarSenha),
                          icon: Icon(
                            mostrarSenha
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: c.muted,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Use pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Confirmar senha',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: confirmarSenha,
                      style: TextStyle(color: c.fg, fontSize: 14),
                      obscureText: !mostrarSenha,
                      decoration: _campo(
                        c,
                        'Digite a senha novamente',
                        icone: Icons.lock_outline,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirme sua senha.';
                        }
                        if (v != senha.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: aceitou,
                      onChanged: (v) => setState(() => aceitou = v ?? false),
                      activeColor: c.mint,
                      checkColor: c.bg,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'Li e aceito os termos de uso e a política de privacidade.',
                        style: TextStyle(color: c.muted, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: carregando ? null : criarConta,
                        icon: carregando
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: c.bg,
                                ),
                              )
                            : const Icon(Icons.arrow_forward, size: 18),
                        label: Text(
                          carregando ? 'Criando conta...' : 'Criar minha conta',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.mint,
                          foregroundColor: c.bg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Já tem conta? ',
                          style: TextStyle(color: c.muted, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Entrar',
                              style: TextStyle(
                                color: c.mint,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
