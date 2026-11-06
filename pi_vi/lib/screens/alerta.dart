import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../widgets/cos_app_navigation.dart';

const _red = Color(0xFFFF6077);
const _amber = Color(0xFFFFC64D);
const _blue = Color(0xFF65B7FF);

enum _Filtro { todas, criticas, dispositivos, energia }

class AlertasScreen extends StatefulWidget {
  final AlertasData data;
  final ValueChanged<int> onNavigate;

  const AlertasScreen({
    super.key,
    required this.data,
    required this.onNavigate,
  });

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  _Filtro _filtro = _Filtro.todas;

  bool _aceita(Alerta alerta) => switch (_filtro) {
    _Filtro.todas => true,
    _Filtro.criticas => alerta.critico,
    _Filtro.dispositivos =>
      alerta.tipo == AlertaTipo.dispositivo ||
          alerta.tipo == AlertaTipo.atualizacao,
    _Filtro.energia => alerta.tipo == AlertaTipo.energia,
  };

  String _grupo(DateTime data, DateTime agora) {
    final dia = DateTime(data.year, data.month, data.day);
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (dia == hoje) return 'Hoje';
    if (dia == DateTime(agora.year, agora.month, agora.day - 1)) return 'Ontem';
    return '${_dois(data.day)}/${_dois(data.month)}/${data.year}';
  }

  String _dois(int numero) => numero.toString().padLeft(2, '0');

  String _horario(Alerta alerta, DateTime agora) {
    final diferenca = agora.difference(alerta.criadoEm);
    if (!diferenca.isNegative && diferenca.inMinutes < 60) {
      return diferenca.inMinutes < 1 ? 'Agora' : 'Há ${diferenca.inMinutes} min';
    }
    return '${_grupo(alerta.criadoEm, agora)}, '
        '${_dois(alerta.criadoEm.hour)}:${_dois(alerta.criadoEm.minute)}';
  }

  void _configuracoes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cosPanel,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: AnimatedBuilder(
          animation: widget.data,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configurações de alertas', style: _heading),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: cosMint,
                  title: const Text('Somente não lidas', style: _title),
                  subtitle: const Text(
                    'Ocultar notificações que você já leu.',
                    style: _description,
                  ),
                  value: widget.data.somenteNaoLidas,
                  onChanged: (value) => widget.data.somenteNaoLidas = value,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Central de notificações do aplicativo.',
                  style: _description,
                ),
                const SizedBox(height: 8),
                const Text(
                  'As leituras e preferências são mantidas durante esta sessão.',
                  style: _description,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirAlerta(Alerta alerta) {
    widget.data.marcarLida(alerta);
    final (destino, acao) = switch (alerta.tipo) {
      AlertaTipo.dispositivo || AlertaTipo.atualizacao => (1, 'Ver dispositivos'),
      AlertaTipo.energia || AlertaTipo.rotina => (2, 'Ver automações'),
      AlertaTipo.membro => (4, 'Ver perfil'),
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cosPanel,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlertaIcon(tipo: alerta.tipo),
              const SizedBox(height: 16),
              Text(alerta.titulo, style: _heading),
              const SizedBox(height: 8),
              Text(alerta.descricao, style: _description),
              const SizedBox(height: 8),
              Text(_horario(alerta, DateTime.now()), style: _description),
              if (alerta.critico) ...[
                const SizedBox(height: 16),
                const Text(
                  'Verifique a alimentação e a conexão Wi-Fi do dispositivo.',
                  style: _description,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cosMint,
                  foregroundColor: cosBackground,
                ),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.onNavigate(destino);
                },
                child: Text(acao),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cosBackground,
      bottomNavigationBar: CosAppNavigation(
        selectedIndex: 3,
        onSelected: widget.onNavigate,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.data,
          builder: (context, _) {
            final data = widget.data;
            final agora = DateTime.now();
            final visiveis = data.alertas.where(
              (a) => _aceita(a) && (!data.somenteNaoLidas || !data.estaLida(a)),
            );
            final grupos = <String, List<Alerta>>{};
            for (final alerta in visiveis) {
              grupos.putIfAbsent(_grupo(alerta.criadoEm, agora), () => []).add(alerta);
            }
            final criticas = visiveis.where((a) => a.critico);
            final recomendada = criticas.isEmpty ? null : criticas.first;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  children: [
                    CosAppHeader(
                      title: 'Alertas',
                      subtitle: switch (data.naoLidas) {
                        0 => 'Nenhuma notificação nova',
                        1 => '1 nova notificação',
                        final n => '$n novas notificações',
                      },
                      trailing: IconButton.filled(
                        tooltip: 'Configurações de alertas',
                        style: IconButton.styleFrom(
                          backgroundColor: cosPanelElevated,
                          foregroundColor: cosForeground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: _configuracoes,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _filtroChip(_Filtro.todas, 'Todas · ${data.alertas.length}'),
                        _filtroChip(_Filtro.criticas, 'Críticas · ${data.criticas}'),
                        _filtroChip(_Filtro.dispositivos, 'Dispositivos'),
                        _filtroChip(_Filtro.energia, 'Energia'),
                      ],
                    ),
                    if (recomendada != null) ...[
                      const SizedBox(height: 16),
                      Material(
                        color: _red.withValues(alpha: 0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: _red.withValues(alpha: 0.4)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _abrirAlerta(recomendada),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.gpp_maybe_outlined, color: _red),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Ação recomendada', style: _title),
                                      const SizedBox(height: 3),
                                      Text(recomendada.descricao, style: _description),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: _red, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (grupos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none_rounded, color: cosMint, size: 40),
                            SizedBox(height: 14),
                            Text('Tudo em dia', style: _heading),
                            SizedBox(height: 8),
                            Text('Nenhuma notificação neste filtro.', style: _description),
                          ],
                        ),
                      ),
                    for (final grupo in grupos.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 12),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          children: [
                            Text(grupo.key, style: _heading),
                            if (grupo.key == grupos.keys.first)
                              TextButton(
                                onPressed: data.naoLidas == 0 ? null : data.marcarTodasLidas,
                                style: TextButton.styleFrom(
                                  foregroundColor: cosMint,
                                  disabledForegroundColor: cosMuted,
                                ),
                                child: const Text('Marcar como lidas'),
                              ),
                          ],
                        ),
                      ),
                      for (final alerta in grupo.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _card(alerta, agora),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _filtroChip(_Filtro filtro, String label) {
    final critico = filtro == _Filtro.criticas;
    final selecionado = _filtro == filtro;
    final cor = critico ? _red : cosMint;
    return ChoiceChip(
      key: ValueKey('filtro-${filtro.name}'),
      label: Text(label),
      selected: selecionado,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtro = filtro),
      backgroundColor: critico ? _red.withValues(alpha: 0.18) : cosPanelElevated,
      selectedColor: cor.withValues(alpha: 0.2),
      side: BorderSide(color: selecionado ? cor.withValues(alpha: 0.5) : Colors.transparent),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: selecionado || critico ? cor : cosMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _card(Alerta alerta, DateTime agora) {
    final lida = widget.data.estaLida(alerta);
    return Semantics(
      label: lida ? 'Notificação lida' : 'Notificação não lida',
      child: Material(
        color: cosPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cosBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('alerta-${alerta.id}'),
          onTap: () => _abrirAlerta(alerta),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlertaIcon(tipo: alerta.tipo),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alerta.titulo, style: _title),
                      const SizedBox(height: 6),
                      Text(alerta.descricao, style: _description),
                      const SizedBox(height: 6),
                      Text(_horario(alerta, agora), style: const TextStyle(color: cosMuted, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!lida)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      key: ValueKey('nao-lida-${alerta.id}'),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: cosMint, shape: BoxShape.circle),
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

const _heading = TextStyle(color: cosForeground, fontSize: 18, fontWeight: FontWeight.w700);
const _title = TextStyle(color: cosForeground, fontSize: 14, fontWeight: FontWeight.w600);
const _description = TextStyle(color: cosMuted, fontSize: 12, height: 1.4);

class _AlertaIcon extends StatelessWidget {
  final AlertaTipo tipo;
  const _AlertaIcon({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = switch (tipo) {
      AlertaTipo.dispositivo => (Icons.wifi_off_rounded, _red),
      AlertaTipo.energia => (Icons.bolt_outlined, _amber),
      AlertaTipo.rotina => (Icons.meeting_room_outlined, cosMint),
      AlertaTipo.atualizacao => (Icons.sync_rounded, _blue),
      AlertaTipo.membro => (Icons.person_add_alt_outlined, cosMint),
    };
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icone, color: cor, size: 23),
    );
  }
}
