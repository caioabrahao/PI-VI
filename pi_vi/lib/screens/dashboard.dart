import 'dart:async';

import 'package:flutter/material.dart';

import 'automacao.dart';
import 'alerta.dart';
import 'dispositivo.dart';
import 'perfil.dart';
import 'splash_screen.dart';

import '../models/alerta.dart';
import '../models/dispositivo_iot.dart';
import '../services/dispositivo_iot_service.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import '../widgets/cos_app_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DispositivoIot> _dispositivos = [];
  StreamSubscription<List<DispositivoIot>>? _assinatura;

  bool _carregando = true;
  bool _saindo = false;
  String? _erro;

  final AutomacaoData _automacaoData = AutomacaoData();
  final AlertasData _alertasData = AlertasData(alertas: const []);

  final List<_Ambiente> _ambientes = [
    _Ambiente(nome: 'Sala de estar', icone: Icons.weekend_outlined),
    _Ambiente(nome: 'Quarto', icone: Icons.bed_outlined),
    _Ambiente(nome: 'Cozinha', icone: Icons.kitchen_outlined),
    _Ambiente(nome: 'Banheiro', icone: Icons.shower_outlined),
  ];

  final List<_Atalho> _atalhos = [];

  @override
  void initState() {
    super.initState();
    _iniciarDispositivos();
  }

  void _iniciarDispositivos() {
    _assinatura?.cancel();

    if (FirebaseService.usuarioAtual == null) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Faça login para visualizar seus dispositivos.';
        });
      }
      return;
    }

    try {
      _assinatura = DispositivoIotService.observarDispositivos().listen(
        (lista) {
          if (!mounted || _saindo) return;
          setState(() {
            _dispositivos = lista;
            _carregando = false;
            _erro = null;
          });
        },
        onError: (Object erro) {
          if (!mounted || _saindo) return;
          setState(() {
            _carregando = false;
            _erro = erro.toString();
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _alertasData.dispose();
    super.dispose();
  }

  int get _totalDispositivos => _dispositivos.length;
  int get _dispositivosLigados => _dispositivos.where((d) => d.ligado).length;

  String _ambienteDe(DispositivoIot d) {
    final ambiente = d.ambienteId?.trim();
    if (ambiente == null || ambiente.isEmpty) return 'Sem ambiente';
    return ambiente;
  }

  bool _online(DispositivoIot d) => d.statusConexao == 'conectado';

  IconData _iconeDe(DispositivoIot d) {
    final tipo = d.tipo.toLowerCase();
    if (tipo.contains('luz') ||
        tipo.contains('lampada') ||
        tipo.contains('lâmpada')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (tipo.contains('tomada')) return Icons.power_rounded;
    if (tipo.contains('ar-condicionado') || tipo.contains('clima')) {
      return Icons.ac_unit_rounded;
    }
    if (tipo.contains('tv') || tipo.contains('televisão'))
      return Icons.tv_rounded;
    if (tipo.contains('ventilador')) return Icons.air_rounded;
    return Icons.devices_other_rounded;
  }

  String _tipoPeloIcone(IconData icone) {
    if (icone == Icons.lightbulb_outline_rounded) return 'Lâmpada';
    if (icone == Icons.power_rounded ||
        icone == Icons.electrical_services_outlined) {
      return 'Tomada';
    }
    if (icone == Icons.ac_unit_rounded) return 'Ar-condicionado';
    if (icone == Icons.tv_rounded) return 'TV';
    if (icone == Icons.air_rounded) return 'Ventilador';
    return 'Outro';
  }

  List<DispositivoIot> _dispositivosDoAmbiente(String ambiente) {
    return _dispositivos.where((d) => _ambienteDe(d) == ambiente).toList();
  }

  Future<void> _adicionarDispositivo(DispositivoListaItem item) async {
    final identificador = 'app-${DateTime.now().microsecondsSinceEpoch}';
    await DispositivoIotService.cadastrar(
      nome: item.nome,
      identificador: identificador,
      tipo: _tipoPeloIcone(item.icone),
      ambienteId: item.ambiente == 'Sem ambiente' ? null : item.ambiente,
    );
  }

  Future<void> _alterarEstado(DispositivoIot dispositivo, bool ligado) async {
    try {
      await DispositivoIotService.alterarEstado(
        id: dispositivo.id,
        ligado: ligado,
      );
    } catch (e) {
      _mostrarMensagem('Erro ao atualizar dispositivo: $e');
    }
  }

  Future<void> _alternarPorId(String id) async {
    for (final d in _dispositivos) {
      if (d.id == id) {
        await _alterarEstado(d, !d.ligado);
        return;
      }
    }
  }

  Future<void> _confirmarLogout() async {
    if (!mounted || _saindo) return;
    final c = CosColors.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Sair da conta?',
                style: TextStyle(
                  color: c.fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente sair da sua conta COS?\n\n'
          'Seus dispositivos continuarão salvos no Cloud Firestore.',
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            label: const Text(
              'Sair',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    setState(() => _saindo = true);

    try {
      await _assinatura?.cancel();
      _assinatura = null;
      await FirebaseService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Erro ao sair da conta: $e');
      if (FirebaseService.usuarioAtual != null) _iniciarDispositivos();
    } finally {
      if (mounted) setState(() => _saindo = false);
    }
  }

  Future<void> _selecionarAba(int index) async {
    if (!mounted || _saindo) return;

    switch (index) {
      case 0:
        return;

      case 1:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DispositivoScreen(
              dispositivos: _dispositivos.map((d) {
                return DispositivoListaItem(
                  id: d.id,
                  nome: d.nome,
                  ambiente: _ambienteDe(d),
                  icone: _iconeDe(d),
                  ligado: d.ligado,
                  online: _online(d),
                );
              }).toList(),
              ambientes: _ambientes.map((a) => a.nome).toList(),
              onToggle: _alternarPorId,
              onAddDevice: _adicionarDispositivo,
              onNavigate: (aba) => _navegarDaSubtela(aba, 1),
            ),
          ),
        );
        return;

      case 2:
        final dispositivosAutomacao = _dispositivos
            .where((d) {
              final tipo = d.tipo.toLowerCase();
              return tipo.contains('luz') ||
                  tipo.contains('lâmpada') ||
                  tipo.contains('lampada') ||
                  tipo.contains('tomada');
            })
            .map((d) {
              final tipo = d.tipo.toLowerCase();
              return AutomacaoDevice(
                id: d.id,
                name: d.nome,
                location: _ambienteDe(d),
                type: tipo.contains('tomada')
                    ? AutomacaoDeviceType.tomada
                    : AutomacaoDeviceType.lampada,
                online: _online(d),
                isOn: d.ligado,
              );
            })
            .toList();

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AutomacaoScreen(
              data: _automacaoData,
              devices: dispositivosAutomacao,
              onPowerChanged: (id, ligado) {
                for (final d in _dispositivos) {
                  if (d.id == id) {
                    _alterarEstado(d, ligado);
                    return;
                  }
                }
              },
              onNavigate: (aba) => _navegarDaSubtela(aba, 2),
            ),
          ),
        );
        return;

      case 3:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlertasScreen(
              data: _alertasData,
              onNavigate: (aba) => _navegarDaSubtela(aba, 3),
            ),
          ),
        );
        return;

      case 4:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PerfilScreen(
              ambientesCasa: _ambientes.map((a) {
                final quantidade = _dispositivosDoAmbiente(a.nome).length;
                return '${a.nome} — $quantidade dispositivos';
              }).toList(),
              dispositivosCasa: _dispositivos.map((d) {
                return '${d.nome} — ${_ambienteDe(d)} — '
                    '${d.ligado ? 'Ligado' : 'Desligado'}';
              }).toList(),
              onNavigate: (aba) => _navegarDaSubtela(aba, 4),
              onLogout: _confirmarLogout,
            ),
          ),
        );
        return;
    }
  }

  void _navegarDaSubtela(int novaAba, int abaAtual) {
    if (!mounted || _saindo || novaAba == abaAtual) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (novaAba != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_saindo) _selecionarAba(novaAba);
      });
    }
  }

  Future<String?> _pedirNome({
    required String titulo,
    String inicial = '',
  }) async {
    final c = CosColors.of(context);
    final controller = TextEditingController(text: inicial);

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(titulo, style: TextStyle(color: c.fg)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          style: TextStyle(color: c.fg),
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (valor) => Navigator.pop(dialogContext, valor.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    controller.dispose();
    return resultado;
  }

  Future<bool> _confirmar({
    required String titulo,
    required String descricao,
  }) async {
    final c = CosColors.of(context);
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.panel,
        title: Text(titulo, style: TextStyle(color: c.fg)),
        content: Text(descricao, style: TextStyle(color: c.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  int _quantidadeNoAmbiente(String nome) =>
      _dispositivosDoAmbiente(nome).length;

  Future<void> _novoAmbiente() async {
    final nome = await _pedirNome(titulo: 'Novo ambiente');
    if (nome == null || nome.isEmpty || !mounted) return;

    final existe = _ambientes.any(
      (a) => a.nome.toLowerCase() == nome.toLowerCase(),
    );

    if (existe) {
      _mostrarMensagem('Já existe um ambiente com esse nome.');
      return;
    }

    setState(() {
      _ambientes.add(_Ambiente(nome: nome, icone: Icons.meeting_room_outlined));
    });
    _mostrarMensagem('Ambiente criado!');
  }

  Future<void> _editarAmbiente(_Ambiente ambiente) async {
    final novoNome = await _pedirNome(
      titulo: 'Editar ambiente',
      inicial: ambiente.nome,
    );

    if (novoNome == null ||
        novoNome.isEmpty ||
        novoNome == ambiente.nome ||
        !mounted) {
      return;
    }

    final existe = _ambientes.any(
      (a) =>
          !identical(a, ambiente) &&
          a.nome.toLowerCase() == novoNome.toLowerCase(),
    );

    if (existe) {
      _mostrarMensagem('Já existe um ambiente com esse nome.');
      return;
    }

    try {
      final dispositivos = _dispositivosDoAmbiente(ambiente.nome);
      for (final d in dispositivos) {
        await DispositivoIotService.atualizarCadastro(
          id: d.id,
          nome: d.nome,
          identificador: d.identificador,
          tipo: d.tipo,
          ambienteId: novoNome,
        );
      }
      if (!mounted) return;
      setState(() => ambiente.nome = novoNome);
      _mostrarMensagem('Ambiente atualizado!');
    } catch (e) {
      _mostrarMensagem('Erro ao atualizar ambiente: $e');
    }
  }

  Future<void> _excluirAmbiente(_Ambiente ambiente) async {
    final confirmado = await _confirmar(
      titulo: 'Excluir ambiente?',
      descricao:
          'Deseja excluir "${ambiente.nome}"?\n\n'
          'Os dispositivos continuarão cadastrados, mas ficarão sem ambiente.',
    );

    if (!confirmado || !mounted) return;

    try {
      final dispositivos = _dispositivosDoAmbiente(ambiente.nome);
      for (final d in dispositivos) {
        await DispositivoIotService.atualizarCadastro(
          id: d.id,
          nome: d.nome,
          identificador: d.identificador,
          tipo: d.tipo,
          ambienteId: null,
        );
      }
      if (!mounted) return;
      setState(() => _ambientes.remove(ambiente));
      _mostrarMensagem('Ambiente excluído!');
    } catch (e) {
      _mostrarMensagem('Erro ao excluir ambiente: $e');
    }
  }

  Future<void> _gerenciarAmbientes() async {
    final c = CosColors.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.panel,
        title: Text('Gerenciar ambientes', style: TextStyle(color: c.fg)),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: _ambientes.isEmpty
                ? Text(
                    'Nenhum ambiente cadastrado.',
                    style: TextStyle(color: c.muted),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: _ambientes.map((ambiente) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          ambiente.nome,
                          style: TextStyle(color: c.fg),
                        ),
                        subtitle: Text(
                          '${_quantidadeNoAmbiente(ambiente.nome)} dispositivos',
                          style: TextStyle(color: c.muted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              icon: Icon(Icons.edit_outlined, color: c.mint),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _editarAmbiente(ambiente);
                              },
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _excluirAmbiente(ambiente);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _novoAmbiente();
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar ambiente'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, bool>?> _configurarAtalho(
    String titulo,
    Map<String, bool> inicial,
  ) async {
    final c = CosColors.of(context);
    final configuracoes = Map<String, bool>.from(inicial);

    return showDialog<Map<String, bool>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizar) {
            return AlertDialog(
              backgroundColor: c.panel,
              title: Text(titulo, style: TextStyle(color: c.fg)),
              content: SizedBox(
                width: 420,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: _dispositivos.map((d) {
                      final selecionado = configuracoes.containsKey(d.id);
                      return Column(
                        children: [
                          CheckboxListTile(
                            value: selecionado,
                            activeColor: c.mint,
                            title: Text(d.nome, style: TextStyle(color: c.fg)),
                            subtitle: Text(
                              _ambienteDe(d),
                              style: TextStyle(color: c.muted),
                            ),
                            onChanged: (valor) {
                              atualizar(() {
                                if (valor == true) {
                                  configuracoes[d.id] = d.ligado;
                                } else {
                                  configuracoes.remove(d.id);
                                }
                              });
                            },
                          ),
                          if (selecionado)
                            SwitchListTile(
                              value: configuracoes[d.id]!,
                              title: Text(
                                'Ligar ao executar',
                                style: TextStyle(color: c.muted, fontSize: 12),
                              ),
                              activeThumbColor: c.mint,
                              onChanged: (valor) {
                                atualizar(() => configuracoes[d.id] = valor);
                              },
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    Map<String, bool>.from(configuracoes),
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _novoAtalho() async {
    if (_dispositivos.isEmpty) {
      _mostrarMensagem('Cadastre um dispositivo antes de criar um modo.');
      return;
    }

    final nome = await _pedirNome(titulo: 'Criar modo');
    if (nome == null || nome.isEmpty || !mounted) return;

    final existe = _atalhos.any(
      (a) => a.nome.toLowerCase() == nome.toLowerCase(),
    );
    if (existe) {
      _mostrarMensagem('Já existe um modo com esse nome.');
      return;
    }

    final resultado = await _configurarAtalho(nome, {});
    if (!mounted || resultado == null) return;
    if (resultado.isEmpty) {
      _mostrarMensagem('Selecione pelo menos um dispositivo.');
      return;
    }

    setState(() {
      _atalhos.add(_Atalho(nome: nome, configuracoes: resultado));
    });
    _mostrarMensagem('Modo criado!');
  }

  Future<void> _editarAtalho(_Atalho atalho) async {
    final resultado = await _configurarAtalho(
      'Editar ${atalho.nome}',
      atalho.configuracoes,
    );
    if (!mounted || resultado == null) return;
    if (resultado.isEmpty) {
      _mostrarMensagem('Selecione pelo menos um dispositivo.');
      return;
    }
    setState(() {
      atalho.configuracoes
        ..clear()
        ..addAll(resultado);
    });
    _mostrarMensagem('Modo atualizado!');
  }

  Future<void> _excluirAtalho(_Atalho atalho) async {
    final confirmado = await _confirmar(
      titulo: 'Excluir modo?',
      descricao: 'Deseja excluir o modo "${atalho.nome}"?',
    );
    if (!confirmado || !mounted) return;
    setState(() => _atalhos.remove(atalho));
  }

  Future<void> _ativarAtalho(_Atalho atalho) async {
    var atualizados = 0;
    try {
      for (final entrada in atalho.configuracoes.entries) {
        final existe = _dispositivos.any((d) => d.id == entrada.key);
        if (!existe) continue;
        await DispositivoIotService.alterarEstado(
          id: entrada.key,
          ligado: entrada.value,
        );
        atualizados++;
      }
      _mostrarMensagem(
        'Modo "${atalho.nome}" ativado: $atualizados dispositivos atualizados.',
      );
    } catch (e) {
      _mostrarMensagem('Erro ao ativar modo: $e');
    }
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    final c = CosColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: c.panel2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: _carregando
            ? Center(child: CircularProgressIndicator(color: c.mint))
            : _erro != null
            ? _estadoErro(c)
            : _conteudoDashboard(c),
      ),
      bottomNavigationBar: CosAppNavigation(
        selectedIndex: 0,
        onSelected: (aba) {
          if (aba != 0) _selecionarAba(aba);
        },
      ),
    );
  }

  Widget _estadoErro(CosColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 45),
            const SizedBox(height: 14),
            Text(
              'Erro ao carregar dispositivos:\n$_erro',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.fg),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _carregando = true;
                  _erro = null;
                });
                _iniciarDispositivos();
              },
              child: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _confirmarLogout,
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoDashboard(CosColors c) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _cabecalho(c),
              const SizedBox(height: 28),
              _saudacao(c),
              const SizedBox(height: 22),
              _cartaoClima(c),
              const SizedBox(height: 14),
              _resumoDispositivos(c),
              const SizedBox(height: 28),
              _tituloSecao(
                c,
                'Dispositivos',
                '$_dispositivosLigados de $_totalDispositivos ligados',
                acao: 'Ver todos',
                onAcao: () => _selecionarAba(1),
              ),
              const SizedBox(height: 14),
              _gradeDispositivos(c),
              const SizedBox(height: 28),
              _tituloSecao(c, 'Consumo de energia', 'Hoje'),
              const SizedBox(height: 14),
              _cartaoEnergia(c),
              const SizedBox(height: 28),
              _tituloSecao(
                c,
                'Ambientes',
                '${_ambientes.length} ambientes',
                acao: 'Gerenciar',
                onAcao: _gerenciarAmbientes,
              ),
              const SizedBox(height: 14),
              _gradeAmbientes(c),
              const SizedBox(height: 28),
              _tituloSecao(
                c,
                'Atalhos',
                'Suas rotinas',
                acao: '＋ Criar',
                onAcao: _novoAtalho,
              ),
              const SizedBox(height: 14),
              _gradeAtalhos(c),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'COS  •  CONTROLE DA SUA CASA',
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _cabecalho(CosColors c) {
    return CosAppHeader(
      title: 'Início',
      subtitle: 'CASA INTELIGENTE',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Alertas',
            onPressed: () => _selecionarAba(3),
            icon: Icon(Icons.notifications_none_rounded, color: c.fg),
          ),
          PopupMenuButton<String>(
            tooltip: 'Perfil',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            constraints: const BoxConstraints(minWidth: 190, maxWidth: 220),
            color: c.panel2,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.border),
            ),
            icon: Icon(Icons.person_outline_rounded, color: c.fg),
            onSelected: (opcao) {
              if (opcao == 'perfil') {
                _selecionarAba(4);
              } else if (opcao == 'logout') {
                _confirmarLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'perfil',
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings_outlined, color: c.mint, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Configurações do perfil',
                      style: TextStyle(color: c.fg, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'logout',
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Sair da conta',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _saudacao(CosColors c) {
    final nome = FirebaseService.usuarioAtual?.displayName?.trim();
    final primeiroNome = nome == null || nome.isEmpty
        ? 'seja bem-vindo'
        : nome.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seu espaço, suas regras.',
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
        const SizedBox(height: 7),
        Text(
          'Olá, $primeiroNome!',
          style: TextStyle(
            color: c.fg,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Veja o que está acontecendo na sua casa.',
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _cartaoClima(CosColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.mint.withValues(alpha: 0.18), c.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.mint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: c.mint, size: 18),
                    const SizedBox(width: 7),
                    Text(
                      'AMBIENTE DA CASA',
                      style: TextStyle(
                        color: c.mint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '—',
                  style: TextStyle(
                    color: c.fg,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nenhuma leitura de temperatura',
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.mint.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.thermostat_rounded, color: c.mint, size: 42),
          ),
        ],
      ),
    );
  }

  Widget _resumoDispositivos(CosColors c) {
    return Row(
      children: [
        Expanded(
          child: _cartaoResumo(
            c,
            icone: Icons.power_settings_new_rounded,
            titulo: 'Dispositivos',
            valor: '$_dispositivosLigados/$_totalDispositivos',
            descricao: 'em funcionamento',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cartaoResumo(
            c,
            icone: Icons.bolt_rounded,
            titulo: 'Energia hoje',
            valor: '—',
            descricao: 'Sem dados de consumo',
          ),
        ),
      ],
    );
  }

  Widget _cartaoResumo(
    CosColors c, {
    required IconData icone,
    required String titulo,
    required String valor,
    required String descricao,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: c.mint, size: 21),
          const SizedBox(height: 14),
          Text(titulo, style: TextStyle(color: c.muted, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            valor,
            style: TextStyle(
              color: c.fg,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(descricao, style: TextStyle(color: c.muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _tituloSecao(
    CosColors c,
    String titulo,
    String subtitulo, {
    String? acao,
    VoidCallback? onAcao,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: c.fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(subtitulo, style: TextStyle(color: c.muted, fontSize: 11)),
            ],
          ),
        ),
        if (acao != null)
          TextButton(
            onPressed: onAcao,
            style: TextButton.styleFrom(foregroundColor: c.mint),
            child: Text(
              acao,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _gradeDispositivos(CosColors c) {
    if (_dispositivos.isEmpty) return _estadoVazioDispositivos(c);

    return GridView.builder(
      itemCount: _dispositivos.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 158,
      ),
      itemBuilder: (context, index) {
        final d = _dispositivos[index];
        return _DispositivoCard(
          c: c,
          nome: d.nome,
          ambiente: _ambienteDe(d),
          icone: _iconeDe(d),
          ligado: d.ligado,
          onChanged: (valor) => _alterarEstado(d, valor),
        );
      },
    );
  }

  Widget _estadoVazioDispositivos(CosColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.devices_other_rounded, color: c.mint, size: 48),
          const SizedBox(height: 15),
          Text(
            'Nenhum dispositivo cadastrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.fg,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua casa ainda não possui dispositivos.\n'
            'Adicione seu primeiro dispositivo!',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _selecionarAba(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.mint,
              foregroundColor: c.bg,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar dispositivo'),
          ),
        ],
      ),
    );
  }

  Widget _cartaoEnergia(CosColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Consumo semanal',
                  style: TextStyle(
                    color: c.fg,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: c.mint, size: 26),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Icon(Icons.bolt_outlined, color: c.muted, size: 38),
                const SizedBox(height: 10),
                Text(
                  'Nenhum dado de consumo disponível',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeAmbientes(CosColors c) {
    if (_ambientes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Nenhum ambiente cadastrado.',
          style: TextStyle(color: c.muted),
        ),
      );
    }

    return GridView.builder(
      itemCount: _ambientes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 106,
      ),
      itemBuilder: (context, index) {
        final ambiente = _ambientes[index];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.panelElevated,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(ambiente.icone, color: c.mint, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ambiente.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_quantidadeNoAmbiente(ambiente.nome)} dispositivos',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gradeAtalhos(CosColors c) {
    if (_atalhos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Nenhum modo criado. Toque em “＋ Criar” para adicionar um.',
          style: TextStyle(color: c.muted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final atalho in _atalhos)
              SizedBox(
                width: largura,
                child: _AtalhoCard(
                  c: c,
                  nome: atalho.nome,
                  quantidade: atalho.configuracoes.length,
                  onExecutar: () => _ativarAtalho(atalho),
                  onEditar: () => _editarAtalho(atalho),
                  onExcluir: () => _excluirAtalho(atalho),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Ambiente {
  String nome;
  final IconData icone;
  _Ambiente({required this.nome, required this.icone});
}

class _Atalho {
  final String nome;
  final Map<String, bool> configuracoes;
  _Atalho({required this.nome, required this.configuracoes});
}

class _DispositivoCard extends StatelessWidget {
  final CosColors c;
  final String nome;
  final String ambiente;
  final IconData icone;
  final bool ligado;
  final ValueChanged<bool> onChanged;

  const _DispositivoCard({
    required this.c,
    required this.nome,
    required this.ambiente,
    required this.icone,
    required this.ligado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ligado ? c.mint.withValues(alpha: 0.38) : c.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ligado ? c.mint.withValues(alpha: 0.12) : c.panel2,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: ligado ? c.mint : c.muted, size: 22),
              ),
              const Spacer(),
              Switch.adaptive(
                value: ligado,
                onChanged: onChanged,
                activeThumbColor: c.mint,
                activeTrackColor: c.mint.withValues(alpha: 0.35),
              ),
            ],
          ),
          const Spacer(),
          Text(
            nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            ambiente,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.muted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            ligado ? '● Ligado' : '● Desligado',
            style: TextStyle(color: ligado ? c.mint : c.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AtalhoCard extends StatelessWidget {
  final CosColors c;
  final String nome;
  final int quantidade;
  final VoidCallback onExecutar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _AtalhoCard({
    required this.c,
    required this.nome,
    required this.quantidade,
    required this.onExecutar,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onExecutar,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: c.mint, size: 22),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Opções do modo',
                  icon: Icon(Icons.more_vert, color: c.muted, size: 20),
                  onSelected: (opcao) {
                    if (opcao == 'editar') onEditar();
                    if (opcao == 'excluir') onExcluir();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'editar',
                      child: Text('Editar modo'),
                    ),
                    PopupMenuItem<String>(
                      value: 'excluir',
                      child: Text('Excluir modo'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.fg,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$quantidade dispositivos',
              style: TextStyle(color: c.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
