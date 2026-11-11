import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/firebase_service.dart';
import '../services/social_auth_service.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'cadastro.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _mostrarSenha = false;
  String? _carregando;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  bool _emailValido(String valor) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(valor.trim());
  }

  String _erroFirebase(Object erro) {
    if (erro is FirebaseAuthException) {
      switch (erro.code) {
        case 'invalid-email':
          return 'Informe um e-mail válido.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'E-mail ou senha incorretos.';
        case 'email-not-verified':
          return 'Verifique seu e-mail antes de entrar.';
        case 'email-already-in-use':
          return 'Este e-mail já possui uma conta.';
        case 'weak-password':
          return 'Escolha uma senha mais forte.';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente mais tarde.';
        case 'network-request-failed':
          return 'Verifique sua conexão com a internet.';
        default:
          return erro.message ?? 'Erro de autenticação: ${erro.code}';
      }
    }
    return erro.toString();
  }

  void _mensagem(String texto, {bool erro = false}) {
    if (!mounted) return;
    final c = CosColors.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: erro ? const Color(0xFF67272D) : c.panel,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _abrirDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _entrarEmail() async {
    if (_carregando != null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = 'email');

    try {
      await FirebaseService.login(
        email: _email.text.trim(),
        senha: _senha.text,
      );
      if (!mounted) return;
      _abrirDashboard();
    } catch (erro) {
      _mensagem(_erroFirebase(erro), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = null);
    }
  }

  Future<void> _entrarGoogle() async {
    if (_carregando != null) return;
    setState(() => _carregando = 'google');

    try {
      await SocialAuthService.entrarComGoogle();
      if (!mounted) return;
      _abrirDashboard();
    } catch (erro) {
      _mensagem(SocialAuthService.mensagemErro(erro), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = null);
    }
  }

  Future<void> _recuperarSenha() async {
    final c = CosColors.of(context);
    String email = _email.text.trim();
    String? erro;
    bool enviando = false;

    final enviado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizar) {
            return AlertDialog(
              backgroundColor: c.panel,
              title: Text('Recuperar senha', style: TextStyle(color: c.fg)),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informe seu e-mail para receber um link de recuperação.',
                      style: TextStyle(color: c.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: email,
                      enabled: !enviando,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: c.fg),
                      decoration: _campo(
                        c,
                        'E-mail',
                        Icons.mail_outline_rounded,
                      ),
                      onChanged: (valor) => email = valor.trim(),
                    ),
                    if (erro != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        erro!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          if (!_emailValido(email)) {
                            atualizar(() => erro = 'E-mail inválido.');
                            return;
                          }
                          atualizar(() {
                            enviando = true;
                            erro = null;
                          });
                          try {
                            await FirebaseService.recuperarSenha(email);
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext, true);
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            atualizar(() {
                              enviando = false;
                              erro = _erroFirebase(e);
                            });
                          }
                        },
                  child: Text(enviando ? 'Enviando...' : 'Enviar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (enviado == true) {
      _mensagem(
        'Se o e-mail estiver cadastrado, você receberá um link de recuperação.',
      );
    }
  }

  Future<void> _abrirCadastro() async {
    if (_carregando != null) return;
    final criado = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CadastroScreen()));
    if (criado == true) {
      _mensagem('Conta criada! Verifique seu e-mail antes de entrar.');
    }
  }

  InputDecoration _campo(
    CosColors c,
    String titulo,
    IconData icone, {
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: titulo,
      labelStyle: TextStyle(color: c.muted),
      prefixIcon: Icon(icone, color: c.muted),
      suffixIcon: sufixo,
      filled: true,
      fillColor: c.panel2, // Cor levemente mais clara que o fundo
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.mint, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);
    final ocupado = _carregando != null;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo mais minimalista e alinhada à esquerda
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: c.mint.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: c.mint.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            color: c.mint,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'COS',
                          style: TextStyle(
                            color: c.fg,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 42),

                    // Título mais equilibrado
                    Text(
                      'Sua casa, em sintonia.',
                      style: TextStyle(
                        color: c.fg,
                        fontSize: 32, // Reduzido de 34 para 32
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Controle ambientes, economize energia e cuide de quem importa.',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 14, // Aumentado para melhor leitura
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Inputs
                    TextFormField(
                      controller: _email,
                      enabled: !ocupado,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: TextStyle(color: c.fg, fontSize: 15),
                      decoration: _campo(
                        c,
                        'E-mail',
                        Icons.mail_outline_rounded,
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Informe seu e-mail.';
                        }
                        if (!_emailValido(valor)) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senha,
                      enabled: !ocupado,
                      obscureText: !_mostrarSenha,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      style: TextStyle(color: c.fg, fontSize: 15),
                      decoration: _campo(
                        c,
                        'Senha',
                        Icons.lock_outline_rounded,
                        sufixo: IconButton(
                          tooltip: _mostrarSenha
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: ocupado
                              ? null
                              : () => setState(
                                  () => _mostrarSenha = !_mostrarSenha,
                                ),
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: c.muted,
                          ),
                        ),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Informe sua senha.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _entrarEmail(),
                    ),

                    // Link "Esqueci minha senha" mais sutil
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: ocupado ? null : _recuperarSenha,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                            color: c.mint,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botão Entrar
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: ocupado ? null : _entrarEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.mint,
                          foregroundColor: c.bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _carregando == 'email'
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: c.bg,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Entrar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Divisor "ou continue com"
                    Row(
                      children: [
                        Expanded(child: Divider(color: c.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou continue com',
                            style: TextStyle(color: c.muted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: c.border)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botão Google
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: ocupado ? null : _entrarGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.fg,
                          backgroundColor: c.panel2,
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _carregando == 'google'
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: c.mint,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleLogo(),
                                  SizedBox(width: 12),
                                  Text(
                                    'Entrar com Google',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Footer
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Ainda não tem uma conta?',
                          style: TextStyle(color: c.muted, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: ocupado ? null : _abrirCadastro,
                          child: Text(
                            'Criar conta',
                            style: TextStyle(
                              color: c.mint,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const FaIcon(
      FontAwesomeIcons.google,
      color: Color(0xFF4285F4),
      size: 20,
    );
  }
}
