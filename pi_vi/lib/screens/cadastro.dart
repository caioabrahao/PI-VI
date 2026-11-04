import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_service.dart';
import 'login.dart';

const Color bg = Color(0xFF080B0F);
const Color panel = Color(0xFF10151B);
const Color panel2 = Color(0xFF171E26);
const Color border = Color(0xFF293640);
const Color muted = Color(0xFF8A98A5);
const Color fg = Color(0xFFF1F5F8);
const Color mint = Color(0xFF4FE0C0);

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
    if (!form.currentState!.validate()) {
      return;
    }

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

      if (!mounted) {
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: panel2,
          title: const Text(
            'Confirme o seu e-mail',
            style: TextStyle(color: fg),
          ),
          content: Text(
            'Enviamos um link de confirmação para ${email.text}. Acesse a sua caixa de entrada e clique no link para ativar a sua conta.',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: mint,
                foregroundColor: bg,
              ),
              child: const Text('OK, ir para o login'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      mensagem(erroCadastro(e));
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
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
                            backgroundColor: panel2,
                            foregroundColor: fg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Criar conta',
                            style: TextStyle(
                              color: fg,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Bem-vindo ao COS.',
                      style: TextStyle(
                        color: fg,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Comece pela sua conta. A casa vem logo depois.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    _label('Nome completo'),
                    const SizedBox(height: 7),
                    _campo(
                      nome,
                      Icons.person_outline,
                      'Seu nome',
                      autofillHints: const [AutofillHints.name],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _label('E-mail'),
                    const SizedBox(height: 7),
                    _campo(
                      email,
                      Icons.mail_outline,
                      'voce@exemplo.com',
                      teclado: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) {
                        if (v == null || !v.contains('@')) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _label('Senha'),
                    const SizedBox(height: 7),
                    _campo(
                      senha,
                      Icons.lock_outline,
                      'Mínimo de 6 caracteres',
                      ocultar: !mostrarSenha,
                      autofillHints: const [AutofillHints.newPassword],
                      sufixo: IconButton(
                        onPressed: () {
                          setState(() => mostrarSenha = !mostrarSenha);
                        },
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: muted,
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

                    _label('Confirmar senha'),
                    const SizedBox(height: 7),
                    _campo(
                      confirmarSenha,
                      Icons.lock_outline,
                      'Digite a senha novamente',
                      ocultar: !mostrarSenha,
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
                      activeColor: mint,
                      checkColor: bg,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Li e aceito os termos de uso e a política de privacidade.',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: carregando ? null : criarConta,
                        icon: carregando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: bg,
                                ),
                              )
                            : const Icon(Icons.arrow_forward, size: 18),
                        label: Text(
                          carregando ? 'Criando conta...' : 'Criar minha conta',
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
                    const SizedBox(height: 16),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Já tem conta? ',
                          style: const TextStyle(color: muted, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Entrar',
                              style: const TextStyle(
                                color: mint,
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

Widget _label(String texto) {
  return Text(
    texto,
    style: const TextStyle(
      color: muted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

Widget _campo(
  TextEditingController controller,
  IconData icone,
  String dica, {
  bool ocultar = false,
  Widget? sufixo,
  TextInputType? teclado,
  Iterable<String>? autofillHints,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: ocultar,
    keyboardType: teclado,
    autofillHints: autofillHints,
    validator: validator,
    style: const TextStyle(color: fg, fontSize: 14),
    decoration: InputDecoration(
      hintText: dica,
      hintStyle: const TextStyle(color: muted),
      prefixIcon: Icon(icone, color: muted, size: 19),
      suffixIcon: sufixo,
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
    ),
  );
}
