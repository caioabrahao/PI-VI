import 'package:flutter/material.dart';

import '../widgets/cos_app_navigation.dart';

class DispositivoListaItem {
  final String nome;
  final String ambiente;
  final IconData icone;
  final bool ligado;
  final bool online;

  const DispositivoListaItem({
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
  final ValueChanged<DispositivoListaItem> onAddDevice;
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
  late final List<_DeviceItemState> _devices;
  final _searchController = TextEditingController();
  String _search = '';
  String _filter = 'Todos';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _devices = widget.dispositivos
        .map(_DeviceItemState.fromItem)
        .toList(growable: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _onlineCount => _devices.where((device) => device.online).length;

  List<String> get _filters {
    final rooms =
        _devices
            .map((device) => device.ambiente)
            .where((room) => room != 'Sem ambiente')
            .toSet()
            .toList()
          ..sort();
    return ['Todos', 'Offline', 'Iluminação', ...rooms];
  }

  List<_DeviceItemState> get _visibleDevices {
    final query = _search.trim().toLowerCase();
    final visible = _devices.where((device) {
      final matchesSearch =
          query.isEmpty ||
          device.nome.toLowerCase().contains(query) ||
          device.ambiente.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        'Todos' => true,
        'Iluminação' => _isLight(device),
        'Offline' => !device.online,
        _ => device.ambiente == _filter,
      };
      return matchesSearch && matchesFilter;
    }).toList();
    if (_sortAscending) {
      visible.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
    }
    return visible;
  }

  bool _isLight(_DeviceItemState device) =>
      device.icone == Icons.lightbulb_outline_rounded ||
      device.nome.toLowerCase().contains('luz') ||
      device.nome.toLowerCase().contains('lâmpada');

  Future<void> _adicionarDispositivo() async {
    final rooms = widget.ambientes.isEmpty
        ? ['Sem ambiente']
        : [...widget.ambientes, 'Sem ambiente'];
    final item = await Navigator.of(context).push<DispositivoListaItem>(
      MaterialPageRoute(
        builder: (_) => AdicionarDispositivoScreen(
          ambientes: rooms,
          nomesExistentes: _devices.map((device) => device.nome).toSet(),
        ),
      ),
    );
    if (item == null || !mounted) return;
    widget.onAddDevice(item);
    setState(() {
      _devices.add(_DeviceItemState.fromItem(item));
      _filter = 'Todos';
      _search = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleDevices = _visibleDevices;
    return Scaffold(
      backgroundColor: cosBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      CosAppHeader(
                        title: 'Dispositivos',
                        subtitle:
                            '$_onlineCount online · ${_devices.length - _onlineCount} offline',
                        trailing: IconButton(
                          tooltip: 'Adicionar dispositivo',
                          onPressed: _adicionarDispositivo,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: cosForeground,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: cosPanelElevated,
                            fixedSize: const Size(44, 44),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _search = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome ou ambiente',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: _search.isEmpty
                                ? null
                                : () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                            icon: const Icon(Icons.tune_rounded),
                          ),
                          filled: true,
                          fillColor: cosPanel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: cosBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: cosBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final filter in _filters)
                              Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: _FilterChip(
                                  label: filter == 'Todos'
                                      ? 'Todos · ${_devices.length}'
                                      : filter == 'Offline'
                                      ? 'Offline · ${_devices.where((device) => !device.online).length}'
                                      : filter,
                                  selected: _filter == filter,
                                  onTap: () => setState(() => _filter = filter),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Casa do Paulo',
                              style: TextStyle(
                                color: cosForeground,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => _sortAscending = !_sortAscending,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: cosMint,
                            ),
                            child: Text(
                              _sortAscending ? 'Ordenado A–Z' : 'Ordenar',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (visibleDevices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              _devices.isEmpty
                                  ? 'Nenhum dispositivo cadastrado.'
                                  : 'Nenhum dispositivo encontrado.',
                              style: const TextStyle(color: cosMuted),
                            ),
                          ),
                        )
                      else
                        for (final device in visibleDevices) ...[
                          _DeviceTile(
                            device: device,
                            onToggle: (value) {
                              setState(() => device.ligado = value);
                              widget.onToggle(device.nome);
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                    ]),
                  ),
                ),
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
}

class _DeviceItemState {
  final String nome;
  final String ambiente;
  final IconData icone;
  bool ligado;
  final bool online;

  _DeviceItemState({
    required this.nome,
    required this.ambiente,
    required this.icone,
    required this.ligado,
    required this.online,
  });

  factory _DeviceItemState.fromItem(DispositivoListaItem item) =>
      _DeviceItemState(
        nome: item.nome,
        ambiente: item.ambiente,
        icone: item.icone,
        ligado: item.ligado,
        online: item.online,
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? cosMint.withValues(alpha: 0.15) : cosPanelElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? cosMint : cosMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final _DeviceItemState device;
  final ValueChanged<bool> onToggle;

  const _DeviceTile({required this.device, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final statusColor = device.online ? cosMint : const Color(0xFFE45D72);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cosPanel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: device.online ? cosBorder : const Color(0xFF382832),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: device.online
                  ? cosMint.withValues(alpha: 0.13)
                  : cosPanelElevated,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              device.icone,
              color: device.online ? cosMint : cosMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: device.online ? cosForeground : cosMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  device.online
                      ? '${device.ambiente} · ${device.ligado ? 'Ligado' : 'Desligado'}'
                      : '${device.ambiente} · Sem resposta à rede Wi-Fi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: cosMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          if (device.online)
            Switch.adaptive(
              value: device.ligado,
              onChanged: onToggle,
              activeThumbColor: cosMint,
              activeTrackColor: cosMint.withValues(alpha: 0.4),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'OFFLINE',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NovoDispositivoDialog extends StatefulWidget {
  final _DeviceCategory categoria;
  final List<String> ambientes;
  final Set<String> nomesExistentes;
  final String nomeInicial;

  const _NovoDispositivoDialog({
    required this.categoria,
    required this.ambientes,
    required this.nomesExistentes,
    required this.nomeInicial,
  });

  @override
  State<_NovoDispositivoDialog> createState() => _NovoDispositivoDialogState();
}

class _NovoDispositivoDialogState extends State<_NovoDispositivoDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  late String _ambiente;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nomeInicial);
    _ambiente = widget.ambientes.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cosPanel,
      title: Text('Adicionar ${widget.categoria.title.toLowerCase()}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do dispositivo.';
                  }
                  if (widget.nomesExistentes.any(
                    (name) => name.toLowerCase() == value.trim().toLowerCase(),
                  )) {
                    return 'Já existe um dispositivo com esse nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _ambiente,
                decoration: const InputDecoration(labelText: 'Ambiente'),
                items: [
                  for (final ambiente in widget.ambientes)
                    DropdownMenuItem(value: ambiente, child: Text(ambiente)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _ambiente = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              DispositivoListaItem(
                nome: _controller.text.trim(),
                ambiente: _ambiente,
                icone: widget.categoria.icon,
                ligado: false,
              ),
            );
          },
          child: const Text('Adicionar'),
        ),
      ],
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
  final _searchController = TextEditingController();
  String _query = '';

  static const _categories = [
    _DeviceCategory(
      title: 'Iluminação',
      description: 'Lâmpadas e fitas',
      icon: Icons.lightbulb_outline_rounded,
    ),
    _DeviceCategory(
      title: 'Tomada',
      description: 'Switches e relés',
      icon: Icons.electrical_services_outlined,
    ),
    _DeviceCategory(
      title: 'Clima',
      description: 'Ar e sensores',
      icon: Icons.thermostat_outlined,
    ),
    _DeviceCategory(
      title: 'Segurança',
      description: 'Câmeras e trancas',
      icon: Icons.shield_outlined,
    ),
    _DeviceCategory(
      title: 'Hub / DIY',
      description: 'Raspberry Pi e bridges',
      icon: Icons.memory_rounded,
    ),
    _DeviceCategory(
      title: 'Outros',
      description: 'Mais dispositivos',
      icon: Icons.dashboard_customize_outlined,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DeviceCategory> get _filteredCategories {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories.where((category) {
      return category.title.toLowerCase().contains(query) ||
          category.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _selecionarCategoria(_DeviceCategory category) async {
    final item = await showDialog<DispositivoListaItem>(
      context: context,
      builder: (_) => _NovoDispositivoDialog(
        categoria: category,
        ambientes: widget.ambientes,
        nomesExistentes: widget.nomesExistentes,
        nomeInicial: _query,
      ),
    );
    if (item != null && mounted) {
      Navigator.of(context).pop(item);
    }
  }

  Future<void> _mostrarBuscaProxima() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cosPanel,
        title: const Text('Procurar por perto'),
        content: const Text(
          'A busca automática por Bluetooth ou Wi-Fi ainda não está '
          'configurada. Escolha um tipo de dispositivo para cadastrá-lo '
          'manualmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _selecionarCategoria(_categories.last);
            },
            child: const Text('Adicionar manualmente'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarAvisoQr() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cosPanel,
        title: const Text('Adicionar por QR code'),
        content: const Text(
          'A leitura de QR code ainda não está disponível. Você pode '
          'selecionar o tipo de dispositivo para cadastrá-lo manualmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _selecionarCategoria(_categories.last);
            },
            child: const Text('Adicionar manualmente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;
    return Scaffold(
      backgroundColor: cosBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Voltar',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: cosPanelElevated,
                              fixedSize: const Size(44, 44),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adicionar dispositivo',
                                  style: TextStyle(
                                    color: cosForeground,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Escolha como deseja começar',
                                  style: TextStyle(
                                    color: cosMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _NearbySearchCard(onTap: _mostrarBuscaProxima),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar marca ou modelo',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: cosPanel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Selecionar por tipo',
                        style: TextStyle(
                          color: cosForeground,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (categories.isEmpty)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                'Nenhum tipo encontrado para "$_query".',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: cosMuted),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _selecionarCategoria(_categories.last),
                              child: const Text('Adicionar em Outros'),
                            ),
                          ],
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth < 360 ? 1 : 2;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: categories.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 92,
                                  ),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return _CategoryCard(
                                  category: category,
                                  onTap: () => _selecionarCategoria(category),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Não encontrou? ',
                              style: TextStyle(color: cosMuted, fontSize: 11),
                            ),
                            TextButton(
                              onPressed: _mostrarAvisoQr,
                              style: TextButton.styleFrom(
                                foregroundColor: cosMint,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                              ),
                              child: const Text(
                                'Adicionar por QR code',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceCategory {
  final String title;
  final String description;
  final IconData icon;

  const _DeviceCategory({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _NearbySearchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NearbySearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF163B37),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: cosMint.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: cosMint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: cosBackground,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Procurar por perto',
                      style: TextStyle(
                        color: cosForeground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Encontre dispositivos compatíveis na sua rede.',
                      style: TextStyle(
                        color: cosMuted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Busca automática ainda não configurada',
                      style: TextStyle(
                        color: cosMint,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: cosMint),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _DeviceCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cosPanel,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cosBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, color: cosMint, size: 19),
              const SizedBox(height: 7),
              Text(
                category.title,
                style: const TextStyle(
                  color: cosForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                category.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: cosMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
