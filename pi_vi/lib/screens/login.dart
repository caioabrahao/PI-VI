import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/firebase_service.dart';
import '../services/social_auth_service.dart';
import 'dashboard.dart';

const Color _bg = Color(0xFF080B0F);
const Color _panel = Color(0xFF10151B);
const Color _border = Color(0xFF293640);
const Color _mint = Color(0xFF4FE0C0);
const Color _fg = Color(0xFFF1F5F8);
const Color _muted = Color(0xFF8A98A5);

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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: erro ? const Color(0xFF67272D) : _panel,
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = 'email';
    });

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
      if (mounted) {
        setState(() {
          _carregando = null;
        });
      }
    }
  }

  Future<void> _entrarGoogle() async {
    if (_carregando != null) return;

    setState(() {
      _carregando = 'google';
    });

    try {
      await SocialAuthService.entrarComGoogle();

      if (!mounted) return;

      _abrirDashboard();
    } catch (erro) {
      _mensagem(SocialAuthService.mensagemErro(erro), erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = null;
        });
      }
    }
  }

  Future<void> _recuperarSenha() async {
    String email = _email.text.trim();

    String? erro;
    bool enviando = false;

    final enviado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizar) {
            return AlertDialog(
              backgroundColor: _panel,
              title: const Text(
                'Recuperar senha',
                style: TextStyle(color: _fg),
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informe seu e-mail para receber '
                      'um link de recuperação.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: email,
                      enabled: !enviando,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: _fg),
                      decoration: _campo('E-mail', Icons.mail_outline_rounded),
                      onChanged: (valor) {
                        email = valor.trim();
                      },
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
                            atualizar(() {
                              erro = 'E-mail inválido.';
                            });
                            return;
                          }

                          atualizar(() {
                            enviando = true;
                            erro = null;
                          });

                          try {
                            await FirebaseService.recuperarSenha(email);

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(dialogContext, true);
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

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
        'Se o e-mail estiver cadastrado, '
        'você receberá um link de recuperação.',
      );
    }
  }

  Future<void> _abrirCadastro() async {
    if (_carregando != null) return;

    final criado = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const _CadastroScreen()));

    if (criado == true) {
      _mensagem(
        'Conta criada! Verifique seu e-mail '
        'antes de entrar.',
      );
    }
  }

  static InputDecoration _campo(
    String titulo,
    IconData icone, {
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: titulo,
      labelStyle: const TextStyle(color: _muted),
      prefixIcon: Icon(icone, color: _muted),
      suffixIcon: sufixo,
      filled: true,
      fillColor: _panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _mint, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _carregando != null;

    return Scaffold(
      backgroundColor: _bg,
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: _mint.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _mint.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: _mint,
                            size: 34,
                          ),
                        ),

                        const SizedBox(width: 16),

                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COS',
                              style: TextStyle(
                                color: _fg,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'CASA INTELIGENTE',
                              style: TextStyle(
                                color: _mint,
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

                    const Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(
                        color: _fg,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Entre na sua conta para '
                      'controlar sua casa inteligente.',
                      style: TextStyle(
                        color: _muted,
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
                      style: const TextStyle(color: _fg),
                      decoration: _campo('E-mail', Icons.mail_outline_rounded),
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
                      style: const TextStyle(color: _fg),
                      decoration: _campo(
                        'Senha',
                        Icons.lock_outline_rounded,
                        sufixo: IconButton(
                          tooltip: _mostrarSenha
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: ocupado
                              ? null
                              : () {
                                  setState(() {
                                    _mostrarSenha = !_mostrarSenha;
                                  });
                                },
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _muted,
                          ),
                        ),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Informe sua senha.';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) {
                        _entrarEmail();
                      },
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: ocupado ? null : _recuperarSenha,
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: _mint, fontSize: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: ocupado ? null : _entrarEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mint,
                          foregroundColor: _bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _carregando == 'email'
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: _bg,
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

                    const Row(
                      children: [
                        Expanded(child: Divider(color: _border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ou continue com',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: _border)),
                      ],
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: ocupado ? null : _entrarGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _fg,
                          backgroundColor: _panel,
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _carregando == 'google'
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: _mint,
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
                        const Text(
                          'Ainda não tem uma conta?',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: ocupado ? null : _abrirCadastro,
                          child: const Text(
                            'Criar conta',
                            style: TextStyle(
                              color: _mint,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'COS  •  CONTROLE DA SUA CASA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
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

class _CadastroScreen extends StatefulWidget {
  const _CadastroScreen();

  @override
  State<_CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<_CadastroScreen> {
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
    if (_salvando || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await FirebaseService.cadastrar(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        senha: _senha.text,
      );

      // O e-mail precisa ser verificado
      // antes de fazer login normalmente.
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
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _fg,
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
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: _mint,
                      size: 48,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Sua casa começa aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _fg,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Crie sua conta COS gratuitamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),

                    const SizedBox(height: 26),

                    TextFormField(
                      controller: _nome,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: _fg),
                      decoration: _LoginScreenState._campo(
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
                      style: const TextStyle(color: _fg),
                      decoration: _LoginScreenState._campo(
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
                      style: const TextStyle(color: _fg),
                      decoration: _LoginScreenState._campo(
                        'Senha',
                        Icons.lock_outline_rounded,
                        sufixo: IconButton(
                          onPressed: _salvando
                              ? null
                              : () {
                                  setState(() {
                                    _mostrarSenha = !_mostrarSenha;
                                  });
                                },
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _muted,
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
                      style: const TextStyle(color: _fg),
                      decoration: _LoginScreenState._campo(
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
                          backgroundColor: _mint,
                          foregroundColor: _bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _salvando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: _bg,
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

                    const Text(
                      'Após o cadastro, verifique '
                      'seu e-mail para entrar no COS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12),
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
