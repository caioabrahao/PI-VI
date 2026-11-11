import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/firebase_service.dart';
import '../services/social_auth_service.dart';
import '../theme.dart';
import 'dashboard.dart';

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
      fillColor: c.panel,
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
                    Row(
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: c.mint.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: c.mint.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            color: c.mint,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COS',
                              style: TextStyle(
                                color: c.fg,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CASA INTELIGENTE',
                              style: TextStyle(
                                color: c.mint,
                                fontSize: 11,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(
                        color: c.fg,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entre na sua conta para controlar sua casa inteligente.',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _email,
                      enabled: !ocupado,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      style: TextStyle(color: c.fg),
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
                      style: TextStyle(color: c.fg),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: ocupado ? null : _recuperarSenha,
                        child: Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: c.mint, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 27),
                    Row(
                      children: [
                        Expanded(child: Divider(color: c.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ou continue com',
                            style: TextStyle(color: c.muted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: c.border)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: ocupado ? null : _entrarGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.fg,
                          backgroundColor: c.panel,
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Ainda não tem uma conta?',
                          style: TextStyle(color: c.muted, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: ocupado ? null : _abrirCadastro,
                          child: Text(
                            'Criar conta',
                            style: TextStyle(
                              color: c.mint,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'COS  •  CONTROLE DA SUA CASA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 10,
                        letterSpacing: 1.2,
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

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();

  bool _salvando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      await FirebaseService.cadastrar(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        senha: _senha.text,
      );
      await FirebaseService.logout();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;
      final mensagem = erro is FirebaseAuthException
          ? (erro.message ?? erro.code)
          : erro.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
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
      fillColor: c.panel,
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

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.fg,
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: c.mint,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sua casa começa aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.fg,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Crie sua conta COS gratuitamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _nome,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: c.fg),
                      decoration: _campo(
                        c,
                        'Nome completo',
                        Icons.person_outline_rounded,
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().length < 2) {
                          return 'Informe seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _email,
                      enabled: !_salvando,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: c.fg),
                      decoration: _campo(
                        c,
                        'E-mail',
                        Icons.mail_outline_rounded,
                      ),
                      validator: (valor) {
                        if (valor == null ||
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(valor.trim())) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _senha,
                      enabled: !_salvando,
                      obscureText: !_mostrarSenha,
                      style: TextStyle(color: c.fg),
                      decoration: _campo(
                        c,
                        'Senha',
                        Icons.lock_outline_rounded,
                        sufixo: IconButton(
                          onPressed: _salvando
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
                        if (valor == null || valor.length < 6) {
                          return 'Use pelo menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmacao,
                      enabled: !_salvando,
                      obscureText: !_mostrarSenha,
                      style: TextStyle(color: c.fg),
                      decoration: _campo(
                        c,
                        'Confirmar senha',
                        Icons.verified_user_outlined,
                      ),
                      validator: (valor) {
                        if (valor != _senha.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _salvando ? null : _cadastrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.mint,
                          foregroundColor: c.bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _salvando
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: c.bg,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Criar minha conta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Após o cadastro, verifique seu e-mail para entrar no COS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, fontSize: 12),
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
      size: 22,
    );
  }
}
