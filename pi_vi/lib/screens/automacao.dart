import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/cos_app_navigation.dart';

enum AutomacaoDeviceType { lampada, tomada, hub }

class AutomacaoDevice {
  final String id;
  final String name;
  final String location;
  final AutomacaoDeviceType type;
  final bool online;
  final bool isOn;

  const AutomacaoDevice({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.online,
    required this.isOn,
  });
}

class AutomacaoData {
  final Map<String, _AutomacaoDeviceState> _states = {};
  final List<ConsumoRegistro> registros = [];

  _AutomacaoDeviceState _stateFor(AutomacaoDevice device) {
    return _states.putIfAbsent(
      device.id,
      () => _AutomacaoDeviceState(isOn: device.isOn),
    );
  }

  bool isOn(AutomacaoDevice device) => _stateFor(device).isOn;

  double brightness(AutomacaoDevice device) => _stateFor(device).brightness;
  double temperature(AutomacaoDevice device) => _stateFor(device).temperature;
  Color color(AutomacaoDevice device) => _stateFor(device).color;

  double consumptionKwh(AutomacaoDevice device) {
    final state = _stateFor(device);
    return _estimatedConsumption(
      state.registeredKwh,
      state.poweredOnAt,
      device.type == AutomacaoDeviceType.lampada ? 9 : 60,
    );
  }

  void syncPower(AutomacaoDevice device) {
    final state = _stateFor(device);
    if (state.isOn != device.isOn) setPower(device, device.isOn);
  }

  DateTime? timerEndsAt(AutomacaoDevice device) =>
      _stateFor(device).timerEndsAt;

  bool weeklyScheduleEnabled(AutomacaoDevice device) =>
      _stateFor(device).weeklyScheduleEnabled;

  Set<int> scheduleDays(AutomacaoDevice device) =>
      _stateFor(device).scheduleDays;

  void setWeeklyScheduleEnabled(AutomacaoDevice device, bool enabled) {
    _stateFor(device).weeklyScheduleEnabled = enabled;
  }

  void toggleScheduleDay(AutomacaoDevice device, int day) {
    final days = _stateFor(device).scheduleDays;
    if (!days.add(day)) days.remove(day);
  }

  void setTimerEnd(AutomacaoDevice device, DateTime? end) {
    _stateFor(device).timerEndsAt = end;
  }

  void setBrightness(AutomacaoDevice device, double value) {
    _stateFor(device).brightness = value;
  }

  void setTemperature(AutomacaoDevice device, double value) {
    _stateFor(device).temperature = value;
  }

  void setColor(AutomacaoDevice device, Color value) {
    _stateFor(device).color = value;
  }

  void setPower(AutomacaoDevice device, bool enabled) {
    final state = _stateFor(device);
    if (enabled == state.isOn) return;
    final agora = DateTime.now();
    if (state.isOn) {
      state.registeredKwh = _estimatedConsumption(
        state.registeredKwh,
        state.poweredOnAt,
        device.type == AutomacaoDeviceType.lampada ? 9 : 60,
        agora: agora,
      );
      state.poweredOnAt = null;
    } else {
      state.poweredOnAt = agora;
    }
    state.isOn = enabled;
    if (!enabled) state.timerEndsAt = null;
  }

  void registrarConsumo(AutomacaoDevice device) {
    final state = _stateFor(device);
    state.registeredKwh = consumptionKwh(device);
    if (state.isOn) state.poweredOnAt = DateTime.now();
    registros.insert(
      0,
      ConsumoRegistro(
        data: DateTime.now(),
        deviceId: device.id,
        deviceName: device.name,
        totalKwh: state.registeredKwh,
      ),
    );
  }

  void addTimerMinutes(AutomacaoDevice device, int minutes) {
    final currentEnd = timerEndsAt(device);
    final now = DateTime.now();
    setTimerEnd(
      device,
      (currentEnd != null && currentEnd.isAfter(now) ? currentEnd : now).add(
        Duration(minutes: minutes),
      ),
    );
  }

  double _estimatedConsumption(
    double accumulatedKwh,
    DateTime? startedAt,
    double watts, {
    DateTime? agora,
  }) {
    if (startedAt == null) return accumulatedKwh;
    final elapsedSeconds = (agora ?? DateTime.now())
        .difference(startedAt)
        .inSeconds;
    if (elapsedSeconds <= 0) return accumulatedKwh;
    return accumulatedKwh + watts * elapsedSeconds / 3600000;
  }
}

class ConsumoRegistro {
  final DateTime data;
  final String deviceId;
  final String deviceName;
  final double totalKwh;

  const ConsumoRegistro({
    required this.data,
    required this.deviceId,
    required this.deviceName,
    required this.totalKwh,
  });
}

class _AutomacaoDeviceState {
  bool isOn;
  double brightness = 0.78;
  double temperature = 3000;
  Color color = cosMint;
  double registeredKwh = 0;
  DateTime? poweredOnAt;
  DateTime? timerEndsAt;
  bool weeklyScheduleEnabled = true;
  final Set<int> scheduleDays = {1, 2, 3, 4, 5};

  _AutomacaoDeviceState({required this.isOn}) {
    if (isOn) poweredOnAt = DateTime.now();
    if (isOn) timerEndsAt = DateTime.now().add(const Duration(minutes: 45));
  }
}

class AutomacaoScreen extends StatefulWidget {
  final AutomacaoData data;
  final List<AutomacaoDevice> devices;
  final void Function(String deviceId, bool enabled) onPowerChanged;
  final ValueChanged<int> onNavigate;

  const AutomacaoScreen({
    super.key,
    required this.data,
    required this.devices,
    required this.onPowerChanged,
    required this.onNavigate,
  });

  @override
  State<AutomacaoScreen> createState() => _AutomacaoScreenState();
}

class _AutomacaoScreenState extends State<AutomacaoScreen> {
  static const _categories = [
    _AutomationDevice(
      type: AutomacaoDeviceType.lampada,
      title: 'Lâmpada',
      subtitle: 'Luz principal',
      icon: Icons.lightbulb_outline_rounded,
    ),
    _AutomationDevice(
      type: AutomacaoDeviceType.tomada,
      title: 'Tomada Smart',
      subtitle: 'Tomada da TV',
      icon: Icons.electrical_services_outlined,
    ),
    _AutomationDevice(
      type: AutomacaoDeviceType.hub,
      title: 'Raspberry Hub',
      subtitle: 'Central da casa',
      icon: Icons.memory_rounded,
    ),
  ];

  static const _scenes = [
    _LightingScene(
      name: 'Leitura',
      icon: Icons.menu_book_outlined,
      color: Color(0xFFFFF1D2),
      brightness: 0.95,
      temperature: 5000,
    ),
    _LightingScene(
      name: 'Relaxar',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFFFFB74D),
      brightness: 0.55,
      temperature: 2700,
    ),
    _LightingScene(
      name: 'Cinema',
      icon: Icons.movie_creation_outlined,
      color: Color(0xFF9575CD),
      brightness: 0.24,
      temperature: 3000,
    ),
    _LightingScene(
      name: 'Foco',
      icon: Icons.center_focus_strong_outlined,
      color: Color(0xFFEAF7FF),
      brightness: 1,
      temperature: 6000,
    ),
    _LightingScene(
      name: 'Noturna',
      icon: Icons.nightlight_outlined,
      color: Color(0xFFFF7043),
      brightness: 0.16,
      temperature: 2200,
    ),
    _LightingScene(
      name: 'Energizar',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFFD54F),
      brightness: 0.88,
      temperature: 4500,
    ),
  ];

  AutomacaoDeviceType _selected = AutomacaoDeviceType.lampada;
  String? _selectedDeviceId;
  _LightingScene? _activeScene;

  List<AutomacaoDevice> get _categoryDevices =>
      widget.devices.where((device) => device.type == _selected).toList();

  AutomacaoDevice? get _selectedDevice {
    for (final device in _categoryDevices) {
      if (device.id == _selectedDeviceId) return device;
    }
    return _categoryDevices.isEmpty ? null : _categoryDevices.first;
  }

  bool get _lampOn =>
      _selectedDevice != null && widget.data.isOn(_selectedDevice!);
  bool get _plugOn =>
      _selectedDevice != null && widget.data.isOn(_selectedDevice!);

  String? _firstDeviceId(Iterable<AutomacaoDevice> devices) {
    final iterator = devices.iterator;
    return iterator.moveNext() ? iterator.current.id : null;
  }

  @override
  void initState() {
    super.initState();
    for (final device in widget.devices) {
      widget.data.syncPower(device);
    }
    _selectedDeviceId = _firstDeviceId(_categoryDevices);
    _deviceTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkPlugTimer(),
    );
  }

  late final Timer _deviceTimer;

  @override
  void dispose() {
    _deviceTimer.cancel();
    super.dispose();
  }

  void _checkPlugTimer() {
    var changed = false;
    for (final device in widget.devices.where(
      (item) => item.type == AutomacaoDeviceType.tomada,
    )) {
      final timerEndsAt = widget.data.timerEndsAt(device);
      if (timerEndsAt == null) continue;
      if (timerEndsAt.isAfter(DateTime.now())) {
        if (device.id == _selectedDeviceId && mounted) setState(() {});
        continue;
      }
      widget.data.setTimerEnd(device, null);
      if (widget.data.isOn(device)) {
        widget.data.setPower(device, false);
        widget.onPowerChanged(device.id, false);
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _selectCategory(AutomacaoDeviceType type) {
    setState(() {
      _selected = type;
      final devices = widget.devices.where((device) => device.type == type);
      _selectedDeviceId = _firstDeviceId(devices);
      _activeScene = null;
    });
  }

  void _setPower(AutomacaoDeviceType type, bool enabled) {
    final device = _selectedDevice;
    if (device == null || device.type != type) return;
    setState(() {
      widget.data.setPower(device, enabled);
    });
    widget.onPowerChanged(device.id, enabled);
  }

  void _applyScene(_LightingScene scene) {
    final device = _selectedDevice;
    if (device == null) return;
    setState(() {
      widget.data.setColor(device, scene.color);
      widget.data.setBrightness(device, scene.brightness);
      widget.data.setTemperature(device, scene.temperature);
      _activeScene = scene;
      widget.data.setPower(device, true);
    });
    widget.onPowerChanged(device.id, true);
  }

  Future<void> _openColorWheel() async {
    final device = _selectedDevice;
    if (device == null) return;
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (_) =>
          _ColorPickerDialog(initialColor: widget.data.color(device)),
    );
    if (selectedColor == null || !mounted) return;
    setState(() {
      widget.data.setColor(device, selectedColor);
      _activeScene = null;
    });
  }

  void _registerConsumption() {
    final device = _selectedDevice;
    if (device == null) return;
    widget.data.registrarConsumo(device);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leitura de consumo registrada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = _categories.firstWhere(
      (device) => device.type == _selected,
    );
    final registeredDevice = _selectedDevice;
    return Scaffold(
      backgroundColor: cosBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      CosAppHeader(
                        title: _selected == AutomacaoDeviceType.hub
                            ? 'Raspberry Hub'
                            : 'Automações',
                        subtitle: _selected == AutomacaoDeviceType.hub
                            ? 'Escritório · Raspberry Pi 5'
                            : 'Controles e cenas da sua casa',
                      ),
                      const SizedBox(height: 17),
                      SizedBox(
                        height: 83,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 9),
                          itemBuilder: (context, index) {
                            final device = _categories[index];
                            return _DeviceSelectorCard(
                              device: device,
                              selected: _selected == device.type,
                              online:
                                  device.type != AutomacaoDeviceType.hub &&
                                  _categoryDevices.any((item) => item.online),
                              onTap: () => _selectCategory(device.type),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selected != AutomacaoDeviceType.hub)
                        _buildRegisteredDeviceSelector(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              registeredDevice?.name ?? selectedDevice.subtitle,
                              style: const TextStyle(
                                color: cosForeground,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            _deviceStatus(registeredDevice),
                            style: TextStyle(
                              color: registeredDevice?.online == true
                                  ? cosMint
                                  : cosMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selected == AutomacaoDeviceType.hub)
                        _buildHubControls()
                      else if (registeredDevice == null)
                        _buildNoRegisteredDevice()
                      else if (_selected == AutomacaoDeviceType.lampada)
                        _buildLampControls()
                      else
                        _buildPlugControls(registeredDevice),
                      if (registeredDevice != null &&
                          _selected != AutomacaoDeviceType.hub) ...[
                        const SizedBox(height: 14),
                        _buildConsumptionCard(registeredDevice),
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
        selectedIndex: 2,
        onSelected: widget.onNavigate,
      ),
    );
  }

  String _deviceStatus(AutomacaoDevice? device) {
    if (_selected == AutomacaoDeviceType.hub) return 'status demonstrativo';
    if (device == null) return 'nenhum cadastrado';
    return '${device.location} · ${device.online ? 'online' : 'offline'}';
  }

  Widget _buildRegisteredDeviceSelector() {
    final devices = _categoryDevices;
    if (devices.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final device = devices[index];
          final selected = device.id == _selectedDevice?.id;
          return ChoiceChip(
            key: ValueKey('automation-device-${device.id}'),
            selected: selected,
            onSelected: (_) => setState(() {
              _selectedDeviceId = device.id;
              _activeScene = null;
            }),
            label: Text(
              '${device.name} · ${device.location}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            avatar: Icon(
              device.type == AutomacaoDeviceType.lampada
                  ? Icons.lightbulb_outline_rounded
                  : Icons.electrical_services_outlined,
              size: 15,
            ),
            labelStyle: TextStyle(
              color: selected ? cosMint : cosForeground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: cosPanel,
            selectedColor: const Color(0xFF163B37),
            side: BorderSide(color: selected ? cosMint : cosBorder),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  Widget _buildNoRegisteredDevice() {
    final label = _selected == AutomacaoDeviceType.lampada
        ? 'lâmpadas'
        : 'dispositivos conectados a uma tomada smart';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cosPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cosBorder),
      ),
      child: Text(
        'Nenhum dispositivo cadastrado em $label. Adicione um pela tela '
        'Dispositivos para configurar aqui.',
        style: const TextStyle(color: cosMuted, fontSize: 12, height: 1.5),
      ),
    );
  }

  Widget _buildLampControls() {
    final device = _selectedDevice!;
    final color = widget.data.color(device);
    final brightness = widget.data.brightness(device);
    final temperature = widget.data.temperature(device);
    final temperatureLabel = temperature < 3500
        ? 'Aconchegante'
        : temperature > 5000
        ? 'Fria'
        : 'Neutra';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _setPower(AutomacaoDeviceType.lampada, !_lampOn),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 146,
                  height: 146,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _lampOn ? color.withValues(alpha: 0.08) : cosPanel,
                    border: Border.all(
                      color: _lampOn
                          ? color.withValues(alpha: 0.55)
                          : cosBorder,
                    ),
                    boxShadow: _lampOn
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.12),
                              blurRadius: 28,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _lampOn ? color : cosPanelElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        color: _lampOn ? cosBackground : cosMuted,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _lampOn ? 'Ligada' : 'Desligada',
                    style: const TextStyle(
                      color: cosForeground,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch.adaptive(
                    value: _lampOn,
                    onChanged: (value) =>
                        _setPower(AutomacaoDeviceType.lampada, value),
                    activeThumbColor: cosMint,
                    activeTrackColor: cosMint.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          decoration: BoxDecoration(
            color: cosPanel,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cosBorder),
          ),
          child: Column(
            children: [
              _SliderLine(
                title: 'Brilho',
                valueLabel: '${(brightness * 100).round()}%',
                value: brightness,
                activeColor: cosMint,
                onChanged: (value) => setState(() {
                  widget.data.setBrightness(device, value);
                  _activeScene = null;
                }),
              ),
              const SizedBox(height: 7),
              _SliderLine(
                title: 'Temperatura',
                valueLabel: '${temperature.round()} K · $temperatureLabel',
                value: (temperature - 2200) / 4300,
                activeColor: const Color(0xFFFFC45C),
                onChanged: (value) => setState(() {
                  widget.data.setTemperature(device, 2200 + value * 4300);
                  _activeScene = null;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cor',
                style: TextStyle(
                  color: cosForeground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: _openColorWheel,
              style: TextButton.styleFrom(foregroundColor: cosMint),
              child: const Text('Personalizar'),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final color in _palette)
              _ColorDot(
                color: color,
                selected: widget.data.color(device) == color,
                onTap: () => setState(() {
                  widget.data.setColor(device, color);
                  _activeScene = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cenas',
                style: TextStyle(
                  color: cosForeground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              _activeScene?.name ?? 'Toque para aplicar',
              style: const TextStyle(color: cosMint, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _scenes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final scene = _scenes[index];
              return _SceneCard(
                scene: scene,
                selected: _activeScene == scene,
                onTap: () => _applyScene(scene),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlugControls(AutomacaoDevice device) {
    final endsAt = widget.data.timerEndsAt(device);
    final minutesLeft = endsAt?.difference(DateTime.now()).inMinutes;
    final days = widget.data.scheduleDays(device);
    final scheduledDays = !widget.data.weeklyScheduleEnabled(device)
        ? 'Agenda desativada'
        : days.isEmpty
        ? 'Sem dias selecionados'
        : days.length == 5 && days.containsAll({1, 2, 3, 4, 5})
        ? 'Seg–Sex'
        : days.length == 7
        ? 'Todos os dias'
        : days
              .map(
                (day) => const [
                  'Seg',
                  'Ter',
                  'Qua',
                  'Qui',
                  'Sex',
                  'Sáb',
                  'Dom',
                ][day - 1],
              )
              .join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _plugOn ? const Color(0xFF163B37) : cosPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _plugOn ? cosMint.withValues(alpha: 0.4) : cosBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _plugOn ? cosMint : cosPanelElevated,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.power_outlined,
                  color: _plugOn ? cosBackground : cosMuted,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plugOn ? 'Energia ligada' : 'Energia desligada',
                      style: const TextStyle(
                        color: cosForeground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _plugOn ? 'Ativa há 2 h 18 min' : 'Tomada em espera',
                      style: const TextStyle(color: cosMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _plugOn ? 'PROTEÇÃO ATIVA' : 'PROTEÇÃO EM ESPERA',
                      style: const TextStyle(
                        color: cosMint,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _plugOn,
                onChanged: (value) =>
                    _setPower(AutomacaoDeviceType.tomada, value),
                activeThumbColor: cosMint,
                activeTrackColor: cosMint.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _PlugMetricCard(
                label: 'POTÊNCIA AGORA',
                value: '42',
                unit: 'W',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _PlugMetricCard(label: 'TENSÃO', value: '221', unit: 'V'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _PlugMetricCard(
                label: 'CORRENTE',
                value: '0,19',
                unit: 'A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
          decoration: BoxDecoration(
            color: cosPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cosBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Consumo hoje',
                      style: TextStyle(
                        color: cosForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Últimos 7 dias',
                    style: TextStyle(
                      color: cosMint,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENERGIA',
                          style: TextStyle(color: cosMuted, fontSize: 9),
                        ),
                        SizedBox(height: 3),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '0,36',
                                style: TextStyle(
                                  color: cosMint,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' kWh',
                                style: TextStyle(color: cosMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '≈ R\$ 0,34',
                    style: TextStyle(color: cosMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _WeeklyConsumptionChart(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Programação',
          style: TextStyle(
            color: cosForeground,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cosPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cosBorder),
          ),
          child: Column(
            children: [
              _PlugScheduleRow(
                icon: Icons.timer_outlined,
                title: 'Temporizador',
                subtitle: minutesLeft == null
                    ? 'Nenhum desligamento programado'
                    : 'Desligar em $minutesLeft minutos',
                trailing: Icon(
                  endsAt == null
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  color: cosMuted,
                  size: 20,
                ),
                onTap: () => setState(() {
                  widget.data.setTimerEnd(
                    device,
                    endsAt == null
                        ? DateTime.now().add(const Duration(minutes: 45))
                        : null,
                  );
                }),
              ),
              const Divider(color: cosBorder, height: 1, indent: 58),
              _PlugScheduleRow(
                icon: Icons.calendar_month_outlined,
                title: 'Agenda semanal',
                subtitle: '$scheduledDays · 18:00 até 23:30',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: cosMuted,
                  size: 20,
                ),
                onTap: () => _editWeeklySchedule(device),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => widget.data.addTimerMinutes(device, 15)),
                icon: const Icon(Icons.add, size: 17),
                label: const Text('+ 15 min'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cosForeground,
                  backgroundColor: cosPanel,
                  side: BorderSide(color: cosBorder),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _setPower(AutomacaoDeviceType.tomada, false),
                icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                label: const Text('Desligar agora'),
                style: FilledButton.styleFrom(
                  backgroundColor: cosMint,
                  foregroundColor: cosBackground,
                  minimumSize: const Size.fromHeight(48),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Valores de potência e consumo exibidos como demonstração; sem medição real da tomada.',
          style: TextStyle(color: cosMuted, fontSize: 9),
        ),
      ],
    );
  }

  Future<void> _editWeeklySchedule(AutomacaoDevice device) async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cosPanel,
          title: const Text('Agenda semanal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ativar tomada',
                  style: TextStyle(color: cosForeground),
                ),
              ),
              Switch.adaptive(
                value: widget.data.weeklyScheduleEnabled(device),
                onChanged: (value) {
                  setDialogState(
                    () => widget.data.setWeeklyScheduleEnabled(device, value),
                  );
                  setState(() {});
                },
                activeThumbColor: cosMint,
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dias da semana',
                  style: TextStyle(color: cosMuted, fontSize: 11),
                ),
              ),
              Wrap(
                spacing: 5,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(
                        const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][day - 1],
                      ),
                      selected: widget.data.scheduleDays(device).contains(day),
                      onSelected: (_) {
                        setDialogState(
                          () => widget.data.toggleScheduleDay(device, day),
                        );
                        setState(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Horário: 18:00 até 23:30',
                style: TextStyle(color: cosMuted, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Concluir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF163B37),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cosMint.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: cosMint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  color: cosBackground,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cos-hub.local',
                      style: TextStyle(
                        color: cosForeground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Debian 12 · kernel 6.6.31',
                      style: TextStyle(color: cosMuted, fontSize: 9),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'ONLINE · 18 DIAS',
                      style: TextStyle(
                        color: cosMint,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '54°',
                style: TextStyle(
                  color: Color(0xFFFFC45C),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _HubSectionTitle(
          title: 'Recursos do sistema',
          trailing: 'Atualizado agora',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: cosPanel,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cosBorder),
          ),
          child: const Column(
            children: [
              _HubResourceRow(
                label: 'CPU',
                value: '24%',
                detail: '4 núcleos · 2,4 GHz',
                fraction: 0.24,
                color: cosMint,
              ),
              SizedBox(height: 10),
              _HubResourceRow(
                label: 'Memória',
                value: '3,1 / 8 GB',
                detail: '38% em uso',
                fraction: 0.38,
                color: Color(0xFF69B5FF),
              ),
              SizedBox(height: 10),
              _HubResourceRow(
                label: 'Armazenamento',
                value: '41 / 128 GB',
                detail: 'SSD · 32% em uso',
                fraction: 0.32,
                color: Color(0xFFFFC45C),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        const _HubSectionTitle(title: 'Rede'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cosPanel,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cosBorder),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _HubNetworkMetric(
                      label: 'ENDEREÇO IP',
                      value: '192.168.1.8',
                    ),
                  ),
                  Expanded(
                    child: _HubNetworkMetric(
                      label: 'TRÁFEGO',
                      value: '18,4',
                      unit: ' MB/s',
                      valueColor: Color(0xFF69B5FF),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Ethernet 1 Gbps · MAC 06:A6:32:••:••:91',
                style: TextStyle(color: cosMuted, fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _HubSectionTitle(
          title: 'Serviços',
          trailing: 'Gerenciar',
          onTrailingTap: _showHubServices,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: cosPanel,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cosBorder),
          ),
          child: const Column(
            children: [
              _HubServiceRow(name: 'Home Assistant', port: ':8123'),
              _HubServiceRow(name: 'MQTT Broker', port: ':1883'),
              _HubServiceRow(name: 'Pi-hole', port: ':80'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmHubAction(restart: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reiniciar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cosForeground,
                  backgroundColor: cosPanelElevated,
                  side: BorderSide(color: cosPanelElevated),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _confirmHubAction(restart: false),
                icon: const Icon(Icons.power_settings_new_rounded, size: 17),
                label: const Text('Desligar seguro'),
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6578),
                  backgroundColor: const Color(0xFF3A1D25),
                  minimumSize: const Size.fromHeight(48),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const Text(
          'Dados de sistema e serviços são ilustrativos; o Raspberry Pi ainda não está conectado.',
          style: TextStyle(color: cosMuted, fontSize: 9),
        ),
      ],
    );
  }

  Future<void> _showHubServices() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cosPanel,
        title: const Text('Serviços do Raspberry Hub'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HubServiceRow(name: 'Home Assistant', port: ':8123'),
            _HubServiceRow(name: 'MQTT Broker', port: ':1883'),
            _HubServiceRow(name: 'Pi-hole', port: ':80'),
            SizedBox(height: 12),
            Text(
              'A conexão com o Raspberry Pi não está configurada. O status dos serviços é apenas demonstrativo.',
              style: TextStyle(color: cosMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmHubAction({required bool restart}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cosPanel,
        title: Text(
          restart ? 'Reiniciar Raspberry Hub?' : 'Desligar Raspberry Hub?',
        ),
        content: Text(
          restart
              ? 'O hub ainda não está conectado. Nenhum comando de reinício será enviado.'
              : 'O hub ainda não está conectado. Nenhum comando de desligamento será enviado.',
          style: const TextStyle(color: cosMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: restart
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3A1D25),
                    foregroundColor: const Color(0xFFFF6578),
                  ),
            child: Text(restart ? 'Entendi' : 'Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restart
              ? 'Reinício não executado: Raspberry Pi não conectado.'
              : 'Desligamento não executado: Raspberry Pi não conectado.',
        ),
      ),
    );
  }

  Widget _buildConsumptionCard(AutomacaoDevice device) {
    final total = widget.data.consumptionKwh(device);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cosPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cosBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consumo estimado da sessão',
                      style: TextStyle(color: cosMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${total.toStringAsFixed(6)} kWh',
                      style: const TextStyle(
                        color: cosMint,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _registerConsumption,
                style: TextButton.styleFrom(foregroundColor: cosMint),
                child: const Text('Registrar'),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${device.name} · estimativa acumulada nesta sessão',
            style: const TextStyle(color: cosMuted, fontSize: 10),
          ),
          if (widget.data.registros.isNotEmpty) ...[
            const Divider(color: cosBorder, height: 20),
            for (final record
                in widget.data.registros
                    .where((record) => record.deviceId == device.id)
                    .take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${TimeOfDay.fromDateTime(record.data).format(context)} · '
                  '${record.deviceName} · ${record.totalKwh.toStringAsFixed(6)} kWh',
                  style: const TextStyle(color: cosMuted, fontSize: 10),
                ),
              ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Estimativa local (9 W lâmpada / 60 W tomada); não é leitura de sensor.',
            style: TextStyle(color: cosMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

const _palette = [
  Color(0xFFFF5C5C),
  Color(0xFFFF984F),
  Color(0xFFFFD15C),
  cosMint,
  Color(0xFF57B7FF),
  Color(0xFF9C75FF),
  Color(0xFFE66BEB),
];

class _HubSectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const _HubSectionTitle({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: cosForeground,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: const TextStyle(
                color: cosMint,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _HubResourceRow extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final double fraction;
  final Color color;

  const _HubResourceRow({
    required this.label,
    required this.value,
    required this.detail,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: cosForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(value, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: cosPanelElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 3),
        Text(detail, style: const TextStyle(color: cosMuted, fontSize: 8)),
      ],
    );
  }
}

class _HubNetworkMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  const _HubNetworkMetric({
    required this.label,
    required this.value,
    this.unit = '',
    this.valueColor = cosForeground,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: cosMuted, fontSize: 8)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(color: cosMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HubServiceRow extends StatelessWidget {
  final String name;
  final String port;

  const _HubServiceRow({required this.name, required this.port});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.widgets_outlined, color: cosMuted, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(color: cosForeground, fontSize: 9),
                  ),
                  TextSpan(
                    text: ' $port',
                    style: const TextStyle(color: cosMuted, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF163B37),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'ATIVO',
              style: TextStyle(
                color: cosMint,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlugMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _PlugMetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: cosPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cosBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: cosMuted, fontSize: 8),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: cosForeground,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(color: cosMuted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyConsumptionChart extends StatelessWidget {
  const _WeeklyConsumptionChart();

  static const _values = [
    0.35,
    0.53,
    0.42,
    0.8,
    0.65,
    0.7,
    0.45,
    0.32,
    0.9,
    0.68,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < _values.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FractionallySizedBox(
                  heightFactor: _values[index],
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: index >= 7
                          ? (index == 8 ? cosMint : const Color(0xFF315D54))
                          : cosPanelElevated,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlugScheduleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _PlugScheduleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cosPanel,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cosPanelElevated,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: cosMint, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: cosForeground,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: cosMuted, fontSize: 9),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _AutomationDevice {
  final AutomacaoDeviceType type;
  final String title;
  final String subtitle;
  final IconData icon;

  const _AutomationDevice({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _DeviceSelectorCard extends StatelessWidget {
  final _AutomationDevice device;
  final bool selected;
  final bool online;
  final VoidCallback onTap;

  const _DeviceSelectorCard({
    required this.device,
    required this.selected,
    required this.online,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Material(
        color: selected ? const Color(0xFF163B37) : cosPanel,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selected ? cosMint : cosBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  device.icon,
                  color: selected ? cosMint : cosMuted,
                  size: 20,
                ),
                const SizedBox(height: 5),
                Text(
                  device.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: cosForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  online ? device.subtitle : 'não integrado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: cosMuted, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderLine extends StatelessWidget {
  final String title;
  final String valueLabel;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _SliderLine({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: cosForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                color: activeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: activeColor,
            inactiveTrackColor: cosPanelElevated,
            thumbColor: activeColor,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(value: value.clamp(0, 1), onChanged: onChanged),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}

class _LightingScene {
  final String name;
  final IconData icon;
  final Color color;
  final double brightness;
  final double temperature;

  const _LightingScene({
    required this.name,
    required this.icon,
    required this.color,
    required this.brightness,
    required this.temperature,
  });
}

class _SceneCard extends StatelessWidget {
  final _LightingScene scene;
  final bool selected;
  final VoidCallback onTap;

  const _SceneCard({
    required this.scene,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Material(
        color: selected ? const Color(0xFF163B37) : cosPanel,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: selected ? cosMint : cosBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  scene.icon,
                  color: selected ? cosMint : cosMuted,
                  size: 19,
                ),
                const SizedBox(height: 5),
                Text(
                  scene.name,
                  style: const TextStyle(color: cosForeground, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  void _updateColor(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final offset = position - center;
    final radius = math.min(size.width, size.height) / 2;
    final distance = math.min(offset.distance / radius, 1.0);
    final hue = (math.atan2(offset.dy, offset.dx) * 180 / math.pi + 360) % 360;
    setState(() {
      _selectedColor = HSVColor.fromAHSV(1, hue, distance, 1).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cosPanel,
      title: const Text('Personalizar cor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onPanDown: (details) =>
                _updateColor(details.localPosition, const Size(220, 220)),
            onPanUpdate: (details) =>
                _updateColor(details.localPosition, const Size(220, 220)),
            child: SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                key: const ValueKey('automation-color-wheel'),
                painter: _ColorWheelPainter(),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: const TextStyle(color: cosMuted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('Usar cor'),
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueShader = const SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
    ).createShader(rect);
    canvas.drawCircle(
      rect.center,
      math.min(size.width, size.height) / 2,
      Paint()..shader = hueShader,
    );
    final saturationShader = const RadialGradient(
      colors: [Colors.white, Color(0x00FFFFFF)],
      stops: [0, 1],
    ).createShader(rect);
    canvas.drawCircle(
      rect.center,
      math.min(size.width, size.height) / 2,
      Paint()..shader = saturationShader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
