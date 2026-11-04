import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart';
import '../widgets/cos_app_navigation.dart';

// =====================================================
// TEMA DO PERFIL
// =====================================================

final perfilThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

// =====================================================
// TELA DE PERFIL
// =====================================================

class PerfilScreen extends StatelessWidget {
  final List<String> ambientesCasa;
  final List<String> dispositivosCasa;
  final ValueChanged<int> onNavigate;

  // A dashboard será responsável pelo logout.
  final Future<void> Function() onLogout;

  const PerfilScreen({
    super.key,
    required this.ambientesCasa,
    required this.dispositivosCasa,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: perfilThemeMode,
      builder: (context, mode, _) {
        final dark =
            mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        final scheme =
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF00836F),
              brightness: dark ? Brightness.dark : Brightness.light,
            ).copyWith(
              primary: dark ? const Color(0xFF4FE0C0) : const Color(0xFF007C68),
              surface: dark ? const Color(0xFF10151B) : Colors.white,
              onSurface: dark
                  ? const Color(0xFFF1F5F8)
                  : const Color(0xFF172C30),
              onSurfaceVariant: dark
                  ? const Color(0xFF96A5B1)
                  : const Color(0xFF566970),
              outlineVariant: dark
                  ? const Color(0xFF293640)
                  : const Color(0xFFD6E2DF),
              primaryContainer: dark
                  ? const Color(0xFF173D35)
                  : const Color(0xFFDDF5ED),
            );

        return Theme(
          data: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: dark
                ? const Color(0xFF080B0F)
                : const Color(0xFFF3F7F6),
          ),
          child: _PerfilBody(
            ambientesCasa: ambientesCasa,
            dispositivosCasa: dispositivosCasa,
            onNavigate: onNavigate,
            onLogout: onLogout,
          ),
        );
      },
    );
  }
}

// =====================================================
// CORPO DO PERFIL
// =====================================================

class _PerfilBody extends StatefulWidget {
  final List<String> ambientesCasa;
  final List<String> dispositivosCasa;
  final ValueChanged<int> onNavigate;
  final Future<void> Function() onLogout;

  const _PerfilBody({
    required this.ambientesCasa,
    required this.dispositivosCasa,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<_PerfilBody> createState() => _PerfilBodyState();
}

class _PerfilBodyState extends State<_PerfilBody> {
  String _cidade = 'Cidade não informada';

  bool _cidadeEditada = false;
  bool _saindo = false;

  @override
  void initState() {
    super.initState();
    _carregarCidade();
  }

  // =====================================================
  // CARREGAR CIDADE DO FIRESTORE
  // =====================================================

  Future<void> _carregarCidade() async {
    final usuario = FirebaseService.usuarioAtual;

    if (usuario == null) return;

    try {
      final perfil = await FirebaseService.obterPerfil(usuario.uid);

      final cidade = perfil?['cidade'];

      if (!mounted || _cidadeEditada) return;

      if (cidade is String && cidade.trim().isNotEmpty) {
        setState(() {
          _cidade = cidade.trim();
        });
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível carregar a cidade: '
            '${error.message ?? error.code}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao carregar cidade: $e');
    }
  }

  // =====================================================
  // JANELA DE DETALHES
  // =====================================================

  void _details(BuildContext context, String titulo, String descricao) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(descricao),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // EDITAR CIDADE
  // =====================================================

  Future<void> _editarCidade(BuildContext context) async {
    final cidade = await showDialog<String>(
      context: context,
      builder: (_) => _EditarCidadeDialog(
        cidadeInicial: _cidade == 'Cidade não informada' ? '' : _cidade,
      ),
    );

    if (cidade == null || !mounted) return;

    setState(() {
      _cidade = cidade;
      _cidadeEditada = true;
    });
  }

  // =====================================================
  // RESUMO DA CASA
  // =====================================================

  void _mostrarResumoCasa(BuildContext context) {
    Widget secao(String titulo, List<String> itens, String mensagemVazia) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (itens.isEmpty)
              Text(
                mensagemVazia,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final item in itens)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('• $item'),
                ),
          ],
        ),
      );
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resumo da casa'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  secao(
                    'Ambientes '
                        '(${widget.ambientesCasa.length})',
                    widget.ambientesCasa,
                    'Nenhum ambiente cadastrado.',
                  ),
                  secao(
                    'Dispositivos '
                        '(${widget.dispositivosCasa.length})',
                    widget.dispositivosCasa,
                    'Nenhum dispositivo cadastrado.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // CONFIGURAÇÃO DE APARÊNCIA
  // =====================================================

  void _appearance(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aparência',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                for (final option in [
                  (
                    ThemeMode.system,
                    Icons.brightness_auto_outlined,
                    'Automático — seguir sistema',
                  ),
                  (ThemeMode.light, Icons.light_mode_outlined, 'Modo dia'),
                  (ThemeMode.dark, Icons.dark_mode_outlined, 'Modo noite'),
                ])
                  ListTile(
                    leading: Icon(option.$2),
                    title: Text(option.$3),
                    trailing: perfilThemeMode.value == option.$1
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      perfilThemeMode.value = option.$1;

                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // NOVO: CONFIGURAÇÕES DO PERFIL
  // =====================================================

  void _abrirConfiguracoesPerfil() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final c = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Configurações do perfil',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ListTile(
                  leading: Icon(Icons.shield_outlined, color: c.primary),
                  title: const Text('Segurança'),
                  subtitle: const Text('Informações de acesso'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _details(
                      context,
                      'Segurança',
                      'Informações de segurança '
                          'da sua conta COS.',
                    );
                  },
                ),

                ListTile(
                  leading: Icon(
                    Icons.notifications_none_rounded,
                    color: c.primary,
                  ),
                  title: const Text('Notificações'),
                  subtitle: const Text('Preferências em desenvolvimento'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _details(
                      context,
                      'Notificações',
                      'As preferências de notificações '
                          'ainda estão em desenvolvimento.',
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.palette_outlined, color: c.primary),
                  title: const Text('Aparência'),
                  subtitle: const Text('Escolher tema da tela'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _appearance(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // NOVO: SOLICITAR LOGOUT À DASHBOARD
  // =====================================================

  Future<void> _solicitarLogout() async {
    if (_saindo) return;

    setState(() {
      _saindo = true;
    });

    try {
      // A dashboard mostra a confirmação,
      // cancela a assinatura do Firestore,
      // executa FirebaseService.logout()
      // e retorna à SplashScreen.
      await widget.onLogout();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao sair da conta: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saindo = false;
        });
      }
    }
  }

  // =====================================================
  // TELA PRINCIPAL
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    final user = FirebaseService.usuarioAtual;

    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Meu perfil';

    final email = user?.email ?? 'Nenhuma conta conectada';

    final initials = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();

    final modeLabel = switch (perfilThemeMode.value) {
      ThemeMode.system => 'Automático · seguir sistema',
      ThemeMode.light => 'Modo dia',
      ThemeMode.dark => 'Modo noite',
    };

    // ===================================================
    // CARTÕES
    // ===================================================

    Widget panel(List<Widget> children) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
    }

    // ===================================================
    // LINHAS DE INFORMAÇÕES
    // ===================================================

    Widget row(IconData icon, String title, String subtitle, VoidCallback tap) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c.primary, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 19,
          color: c.onSurfaceVariant,
        ),
        onTap: tap,
      );
    }

    // ===================================================
    // TÍTULOS DE SEÇÕES
    // ===================================================

    Widget heading(String title, {String? action, VoidCallback? tap}) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (action != null) TextButton(onPressed: tap, child: Text(action)),
          ],
        ),
      );
    }

    // ===================================================
    // MEMBRO ILUSTRATIVO DA TELA ORIGINAL
    // ===================================================

    Widget member(String initials, String name, String role, Color color) {
      return ListTile(
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: color,
          child: Text(
            initials,
            style: const TextStyle(
              color: Color(0xFF09231F),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          role,
          style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {
          _details(
            context,
            name,
            '$role\n'
            'Membro ilustrativo, sem vínculo '
            'com uma casa real.',
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                // ======================================
                // CABEÇALHO
                // ======================================

                const CosAppHeader(
                  title: 'Perfil',
                  subtitle: 'Gerencie sua conta e sua casa',
                ),

                const SizedBox(height: 20),

                // ======================================
                // DADOS DO USUÁRIO
                // ======================================
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: c.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 27,
                        backgroundColor: const Color(0xFF4FE0C0),
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                            color: Color(0xFF09231F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.emailVerified == true
                                ? 'E-MAIL VERIFICADO'
                                : 'PERFIL DA CONTA',
                            style: TextStyle(
                              fontSize: 10,
                              color: c.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right, color: c.primary),
                      onTap: () {
                        _details(context, 'Minha conta', '$name\n$email');
                      },
                    ),
                  ),
                ),

                // ======================================
                // INFORMAÇÕES DA CASA
                // ======================================
                heading(
                  'Minha casa',
                  action: 'Editar',
                  tap: () => _editarCidade(context),
                ),

                panel([
                  row(
                    Icons.location_on_outlined,
                    'Cidade da casa',
                    _cidade,
                    () {
                      _details(context, 'Casa', 'Cidade cadastrada: $_cidade.');
                    },
                  ),
                  row(
                    Icons.home_outlined,
                    'Resumo',
                    '${widget.ambientesCasa.length} ambientes'
                        ' · ${widget.dispositivosCasa.length}'
                        ' dispositivos',
                    () => _mostrarResumoCasa(context),
                  ),
                ]),

                // ======================================
                // MEMBROS
                // ======================================
                heading(
                  'Membros',
                  action: '+ Convidar',
                  tap: () {
                    _details(
                      context,
                      'Convidar membro',
                      'O convite de novos membros '
                          'ainda não está disponível.',
                    );
                  },
                ),

                panel([
                  member(
                    'PC',
                    'Paulo Cesar',
                    'Proprietário',
                    const Color(0xFF4FE0C0),
                  ),
                ]),

                // ======================================
                // SEGURANÇA E PREFERÊNCIAS
                // ======================================
                heading('Segurança e preferências'),

                panel([
                  row(
                    Icons.shield_outlined,
                    'Segurança',
                    'Informações de acesso',
                    () {
                      _details(
                        context,
                        'Segurança',
                        'Gerencie as informações '
                            'de acesso da sua conta.',
                      );
                    },
                  ),
                  row(
                    Icons.notifications_none,
                    'Notificações',
                    'Preferências em desenvolvimento',
                    () {
                      _details(
                        context,
                        'Notificações',
                        'As preferências de notificações '
                            'ainda estão em desenvolvimento.',
                      );
                    },
                  ),
                  row(
                    Icons.palette_outlined,
                    'Aparência',
                    modeLabel,
                    () => _appearance(context),
                  ),
                ]),

                const SizedBox(height: 22),

                // ======================================
                // BOTÃO DE CONFIGURAÇÕES
                // ======================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _abrirConfiguracoesPerfil,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Configurações do perfil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.primary,
                      side: BorderSide(
                        color: c.primary.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ======================================
                // BOTÃO DE LOGOUT CORRIGIDO
                // ======================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saindo ? null : _solicitarLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(_saindo ? 'Saindo...' : 'Sair da conta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // ================================================
      // BARRA DE NAVEGAÇÃO
      // ================================================
      bottomNavigationBar: CosAppNavigation(
        selectedIndex: 4,
        onSelected: widget.onNavigate,
      ),
    );
  }
}

// =====================================================
// DIÁLOGO DE EDIÇÃO DE CIDADE
// =====================================================

class _EditarCidadeDialog extends StatefulWidget {
  final String cidadeInicial;

  const _EditarCidadeDialog({required this.cidadeInicial});

  @override
  State<_EditarCidadeDialog> createState() => _EditarCidadeDialogState();
}

class _EditarCidadeDialogState extends State<_EditarCidadeDialog> {
  late final TextEditingController _controller;

  final _formKey = GlobalKey<FormState>();

  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.cidadeInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando || !_formKey.currentState!.validate()) {
      return;
    }

    final cidade = _controller.text.trim();

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await FirebaseService.atualizarCidadeCasa(cidade);

      if (!mounted) return;

      Navigator.pop(context, cidade);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
        _erro =
            'Não foi possível salvar a cidade: '
            '${error.message ?? error.code}';
      });
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
        _erro = error.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
        _erro = 'Erro ao salvar cidade: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar cidade'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              enabled: !_salvando,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Cidade',
                hintText: 'Ex.: Nova Odessa, SP',
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe a cidade onde você mora.';
                }

                return null;
              },
              onFieldSubmitted: (_) => _salvar(),
            ),

            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
