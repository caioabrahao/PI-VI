import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dispositivo_iot.dart';
import '../services/dispositivo_iot_service.dart';
import '../theme.dart';
import '../widgets/cos_app_navigation.dart';

class DispositivoListaItem {
  final String? id;
  final String nome;
  final String ambiente;
  final IconData icone;
  final bool ligado;
  final bool online;

  const DispositivoListaItem({
    this.id,
    required this.nome,
    required this.ambiente,
    required this.icone,
    required this.ligado,
    this.online = true,
  });
}

class DispositivoScreen extends StatefulWidget {
  final List<DispositivoListaItem> dispositivos;
  final List<String> ambientes;
  final ValueChanged<String> onToggle;
  final Future<void> Function(DispositivoListaItem) onAddDevice;
  final ValueChanged<int> onNavigate;

  const DispositivoScreen({
    super.key,
    required this.dispositivos,
    required this.ambientes,
    required this.onToggle,
    required this.onAddDevice,
    required this.onNavigate,
  });

  @override
  State<DispositivoScreen> createState() => _DispositivoScreenState();
}

class _DispositivoScreenState extends State<DispositivoScreen> {
  List<DispositivoIot> _dispositivos = [];
  StreamSubscription<List<DispositivoIot>>? _assinatura;
  final TextEditingController _buscaController = TextEditingController();

  String _busca = '';
  String _filtro = 'Todos';
  bool _ordenarAZ = false;
  bool _carregando = true;
  bool _cadastrando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDispositivos();
  }

  void _carregarDispositivos() {
    try {
      _assinatura = DispositivoIotService.observarDispositivos().listen(
        (dispositivos) {
          if (!mounted) return;
          setState(() {
            _dispositivos = dispositivos;
            _carregando = false;
            _erro = null;
          });
        },
        onError: (Object erro) {
          if (!mounted) return;
          setState(() {
            _carregando = false;
            _erro = erro.toString();
          });
        },
      );
    } catch (e) {
      _carregando = false;
      _erro = e.toString();
    }
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  int get _totalDispositivos => _dispositivos.length;
  int get _dispositivosOnline =>
      _dispositivos.where((d) => d.statusConexao == 'conectado').length;
  int get _dispositivosLigados => _dispositivos.where((d) => d.ligado).length;

  String _ambiente(DispositivoIot d) {
    final nome = d.ambienteId?.trim();
    if (nome == null || nome.isEmpty) return 'Sem ambiente';
    return nome;
  }

  IconData _iconeDispositivo(DispositivoIot d) {
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

  bool _ehIluminacao(DispositivoIot d) {
    final tipo = d.tipo.toLowerCase();
    return tipo.contains('lampada') ||
        tipo.contains('lâmpada') ||
        tipo.contains('luz') ||
        d.nome.toLowerCase().contains('luz');
  }

  List<String> get _filtros {
    final ambientes =
        _dispositivos
            .map(_ambiente)
            .where((nome) => nome != 'Sem ambiente')
            .toSet()
            .toList()
          ..sort();
    return ['Todos', 'Online', 'Offline', 'Iluminação', ...ambientes];
  }

  List<DispositivoIot> get _dispositivosFiltrados {
    final busca = _busca.trim().toLowerCase();

    final resultado = _dispositivos.where((dispositivo) {
      final correspondeBusca =
          busca.isEmpty ||
          dispositivo.nome.toLowerCase().contains(busca) ||
          _ambiente(dispositivo).toLowerCase().contains(busca) ||
          dispositivo.tipo.toLowerCase().contains(busca);

      bool correspondeFiltro;
      switch (_filtro) {
        case 'Todos':
          correspondeFiltro = true;
          break;
        case 'Online':
          correspondeFiltro = dispositivo.statusConexao == 'conectado';
          break;
        case 'Offline':
          correspondeFiltro = dispositivo.statusConexao == 'desconectado';
          break;
        case 'Iluminação':
          correspondeFiltro = _ehIluminacao(dispositivo);
          break;
        default:
          correspondeFiltro = _ambiente(dispositivo) == _filtro;
      }

      return correspondeBusca && correspondeFiltro;
    }).toList();

    if (_ordenarAZ) {
      resultado.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
    }

    return resultado;
  }

  Future<void> _adicionarDispositivo() async {
    if (_cadastrando) return;

    final ambientes = [...widget.ambientes, 'Sem ambiente'].toList();

    final item = await Navigator.push<DispositivoListaItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AdicionarDispositivoScreen(
          ambientes: ambientes,
          nomesExistentes: _dispositivos.map((d) => d.nome).toSet(),
        ),
      ),
    );

    if (item == null || !mounted) return;

    setState(() => _cadastrando = true);

    try {
      await widget.onAddDevice(item);
      if (!mounted) return;
      setState(() {
        _filtro = 'Todos';
        _busca = '';
        _buscaController.clear();
      });
      _mensagem('Dispositivo cadastrado com sucesso!');
    } catch (e) {
      _mensagem('Erro ao cadastrar dispositivo: $e');
    } finally {
      if (mounted) setState(() => _cadastrando = false);
    }
  }

  Future<void> _alterarEstado(DispositivoIot dispositivo, bool ligado) async {
    try {
      await DispositivoIotService.alterarEstado(
        id: dispositivo.id,
        ligado: ligado,
      );
    } catch (e) {
      _mensagem('Erro ao alterar dispositivo: $e');
    }
  }

  Future<void> _excluirDispositivo(DispositivoIot dispositivo) async {
    final c = CosColors.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.panel,
        title: Text('Excluir dispositivo?', style: TextStyle(color: c.fg)),
        content: Text(
          'Deseja excluir "${dispositivo.nome}" da sua casa?',
          style: TextStyle(color: c.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await DispositivoIotService.excluir(dispositivo.id);
      _mensagem('Dispositivo excluído com sucesso!');
    } catch (e) {
      _mensagem('Erro ao excluir dispositivo: $e');
    }
  }

  Future<void> _editarDispositivo(DispositivoIot dispositivo) async {
    final c = CosColors.of(context);
    final nomeController = TextEditingController(text: dispositivo.nome);
    final identificadorController = TextEditingController(
      text: dispositivo.identificador,
    );
    final tipoController = TextEditingController(text: dispositivo.tipo);

    String ambienteSelecionado = _ambiente(dispositivo);
    final ambientes = [
      ...widget.ambientes,
      'Sem ambiente',
      ambienteSelecionado,
    ].toList();

    final salvar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: c.panel,
              title: Text('Editar dispositivo', style: TextStyle(color: c.fg)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeController,
                      style: TextStyle(color: c.fg),
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: identificadorController,
                      style: TextStyle(color: c.fg),
                      decoration: const InputDecoration(
                        labelText: 'Identificador',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tipoController,
                      style: TextStyle(color: c.fg),
                      decoration: const InputDecoration(labelText: 'Tipo'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: ambienteSelecionado,
                      dropdownColor: c.panel2,
                      decoration: const InputDecoration(labelText: 'Ambiente'),
                      items: ambientes.map((ambiente) {
                        return DropdownMenuItem(
                          value: ambiente,
                          child: Text(ambiente),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() => ambienteSelecionado = valor);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    final nome = nomeController.text.trim();
    final identificador = identificadorController.text.trim();
    final tipo = tipoController.text.trim();

    nomeController.dispose();
    identificadorController.dispose();
    tipoController.dispose();

    if (salvar != true || !mounted) return;

    try {
      await DispositivoIotService.atualizarCadastro(
        id: dispositivo.id,
        nome: nome,
        identificador: identificador,
        tipo: tipo,
        ambienteId: ambienteSelecionado == 'Sem ambiente'
            ? null
            : ambienteSelecionado,
      );
      _mensagem('Dispositivo atualizado!');
    } catch (e) {
      _mensagem('Erro ao atualizar dispositivo: $e');
    }
  }

  void _mensagem(String texto) {
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
    final visiveis = _dispositivosFiltrados;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                CosAppHeader(
                  title: 'Dispositivos',
                  subtitle:
                      '$_dispositivosOnline online · '
                      '${_totalDispositivos - _dispositivosOnline} não conectados',
                  trailing: IconButton(
                    tooltip: 'Adicionar dispositivo',
                    onPressed: _cadastrando ? null : _adicionarDispositivo,
                    icon: Icon(Icons.add_rounded, color: c.fg),
                  ),
                ),
                const SizedBox(height: 24),
                _resumo(c),
                const SizedBox(height: 22),
                _campoBusca(c),
                const SizedBox(height: 15),
                _barraFiltros(c),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Minha casa',
                        style: TextStyle(
                          color: c.fg,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _ordenarAZ = !_ordenarAZ),
                      child: Text(
                        _ordenarAZ ? 'Ordenado A–Z' : 'Ordenar',
                        style: TextStyle(color: c.mint),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_carregando)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: c.mint),
                    ),
                  )
                else if (_erro != null)
                  _estadoErro(c)
                else if (visiveis.isEmpty)
                  _estadoVazio(c)
                else
                  ...visiveis.map((d) => _cardDispositivo(c, d)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CosAppNavigation(
        selectedIndex: 1,
        onSelected: widget.onNavigate,
      ),
    );
  }

  Widget _resumo(CosColors c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.devices_other_rounded, color: c.mint, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalDispositivos dispositivos',
                  style: TextStyle(
                    color: c.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$_dispositivosLigados ligados',
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoBusca(CosColors c) {
    return TextField(
      controller: _buscaController,
      onChanged: (valor) => setState(() => _busca = valor),
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou ambiente',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _busca.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _buscaController.clear();
                  setState(() => _busca = '');
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: c.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }

  Widget _barraFiltros(CosColors c) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filtros.map((filtro) {
          final selecionado = _filtro == filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filtro),
              selected: selecionado,
              selectedColor: c.mint.withValues(alpha: 0.18),
              backgroundColor: c.panel2,
              labelStyle: TextStyle(
                color: selecionado ? c.mint : c.muted,
                fontSize: 11,
              ),
              side: BorderSide(color: selecionado ? c.mint : c.border),
              onSelected: (_) => setState(() => _filtro = filtro),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _estadoVazio(CosColors c) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.devices_other_rounded, color: c.mint, size: 52),
          const SizedBox(height: 16),
          Text(
            _dispositivos.isEmpty
                ? 'Nenhum dispositivo cadastrado'
                : 'Nenhum dispositivo encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.fg,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _dispositivos.isEmpty
                ? 'Adicione seu primeiro dispositivo para começar a controlar sua casa.'
                : 'Tente alterar os filtros ou a busca.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted),
          ),
          if (_dispositivos.isEmpty) ...[
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _cadastrando ? null : _adicionarDispositivo,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar dispositivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.mint,
                foregroundColor: c.bg,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoErro(CosColors c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar dispositivos:\n$_erro',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.fg),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _assinatura?.cancel();
              setState(() {
                _erro = null;
                _carregando = true;
              });
              _carregarDispositivos();
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _cardDispositivo(CosColors c, DispositivoIot dispositivo) {
    final conectado = dispositivo.statusConexao == 'conectado';
    final ligado = dispositivo.ligado;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ligado ? c.mint.withValues(alpha: 0.4) : c.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ligado ? c.mint.withValues(alpha: 0.13) : c.panel2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _iconeDispositivo(dispositivo),
              color: ligado ? c.mint : c.muted,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dispositivo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_ambiente(dispositivo)} · '
                  '${ligado ? 'Ligado' : 'Desligado'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  conectado
                      ? 'Conectado'
                      : dispositivo.statusConexao == 'desconectado'
                      ? 'Desconectado'
                      : 'Conexão desconhecida',
                  style: TextStyle(
                    color: conectado ? c.mint : c.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: ligado,
            onChanged: (valor) => _alterarEstado(dispositivo, valor),
            activeThumbColor: c.mint,
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções do dispositivo',
            icon: Icon(Icons.more_vert, color: c.muted),
            onSelected: (opcao) {
              if (opcao == 'editar') _editarDispositivo(dispositivo);
              if (opcao == 'excluir') _excluirDispositivo(dispositivo);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'excluir', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

class AdicionarDispositivoScreen extends StatefulWidget {
  final List<String> ambientes;
  final Set<String> nomesExistentes;

  const AdicionarDispositivoScreen({
    super.key,
    required this.ambientes,
    required this.nomesExistentes,
  });

  @override
  State<AdicionarDispositivoScreen> createState() =>
      _AdicionarDispositivoScreenState();
}

class _AdicionarDispositivoScreenState
    extends State<AdicionarDispositivoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  String _tipo = 'Lâmpada';
  String _ambiente = 'Sem ambiente';

  final List<String> _tipos = [
    'Lâmpada',
    'Tomada',
    'Ar-condicionado',
    'TV',
    'Ventilador',
    'Outro',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  IconData get _icone {
    switch (_tipo) {
      case 'Lâmpada':
        return Icons.lightbulb_outline_rounded;
      case 'Tomada':
        return Icons.power_rounded;
      case 'Ar-condicionado':
        return Icons.ac_unit_rounded;
      case 'TV':
        return Icons.tv_rounded;
      case 'Ventilador':
        return Icons.air_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final dispositivo = DispositivoListaItem(
      nome: _nomeController.text.trim(),
      ambiente: _ambiente,
      icone: _icone,
      ligado: false,
      online: false,
    );

    Navigator.pop(context, dispositivo);
  }

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);
    final ambientes = [...widget.ambientes, 'Sem ambiente'].toList();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Adicionar dispositivo'),
        backgroundColor: c.bg,
        foregroundColor: c.fg,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(Icons.devices_other_rounded, color: c.mint, size: 64),
              const SizedBox(height: 15),
              Text(
                'Novo dispositivo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha as informações para cadastrar um dispositivo na sua casa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.panel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        style: TextStyle(color: c.fg),
                        decoration: const InputDecoration(
                          labelText: 'Nome do dispositivo',
                          hintText: 'Ex.: Luz da sala',
                          prefixIcon: Icon(Icons.edit_outlined),
                        ),
                        validator: (valor) {
                          final nome = valor?.trim() ?? '';
                          if (nome.isEmpty) return 'Informe o nome.';
                          if (nome.length > 80) {
                            return 'Máximo de 80 caracteres.';
                          }
                          final existe = widget.nomesExistentes.any(
                            (item) => item.toLowerCase() == nome.toLowerCase(),
                          );
                          if (existe) {
                            return 'Já existe um dispositivo com esse nome.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: _tipo,
                        dropdownColor: c.panel,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de dispositivo',
                        ),
                        items: _tipos.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          if (valor != null) setState(() => _tipo = valor);
                        },
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: _ambiente,
                        dropdownColor: c.panel,
                        decoration: const InputDecoration(
                          labelText: 'Ambiente',
                        ),
                        items: ambientes.map((ambiente) {
                          return DropdownMenuItem(
                            value: ambiente,
                            child: Text(ambiente),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          if (valor != null) setState(() => _ambiente = valor);
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _salvar,
                          icon: const Icon(Icons.add),
                          label: const Text('Cadastrar dispositivo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.mint,
                            foregroundColor: c.bg,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
