import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../theme.dart';
import '../widgets/cos_app_navigation.dart';

const _red = Color(0xFFFF6077);
const _amber = Color(0xFFFFC64D);
const _blue = Color(0xFF3DB8C9); // Azul atualizado para o novo padrão

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
      return diferenca.inMinutes < 1
          ? 'Agora'
          : 'Há ${diferenca.inMinutes} min';
    }
    return '${_grupo(alerta.criadoEm, agora)}, '
        '${_dois(alerta.criadoEm.hour)}:${_dois(alerta.criadoEm.minute)}';
  }

  void _configuracoes() {
    final c = CosColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.panel,
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
                Text(
                  'Configurações de alertas',
                  style: TextStyle(
                    color: c.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: c.mint,
                  title: Text(
                    'Somente não lidas',
                    style: TextStyle(
                      color: c.fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Ocultar notificações que você já leu.',
                    style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
                  ),
                  value: widget.data.somenteNaoLidas,
                  onChanged: (value) => widget.data.somenteNaoLidas = value,
                ),
                const SizedBox(height: 16),
                Text(
                  'Central de notificações do aplicativo.',
                  style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'As leituras e preferências são mantidas durante esta sessão.',
                  style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirAlerta(Alerta alerta) {
    final c = CosColors.of(context);
    widget.data.marcarLida(alerta);
    final (destino, acao) = switch (alerta.tipo) {
      AlertaTipo.dispositivo ||
      AlertaTipo.atualizacao => (1, 'Ver dispositivos'),
      AlertaTipo.energia || AlertaTipo.rotina => (2, 'Ver automações'),
      AlertaTipo.membro => (4, 'Ver perfil'),
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.panel,
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
              Text(
                alerta.titulo,
                style: TextStyle(
                  color: c.fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alerta.descricao,
                style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                _horario(alerta, DateTime.now()),
                style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
              ),
              if (alerta.critico) ...[
                const SizedBox(height: 16),
                Text(
                  'Verifique a alimentação e a conexão Wi-Fi do dispositivo.',
                  style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.mint,
                  foregroundColor: c.bg,
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
    final c = CosColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
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
              grupos
                  .putIfAbsent(_grupo(alerta.criadoEm, agora), () => [])
                  .add(alerta);
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
                          backgroundColor: c.panelElevated,
                          foregroundColor: c.fg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                        _filtroChip(
                          c,
                          _Filtro.todas,
                          'Todas · ${data.alertas.length}',
                        ),
                        _filtroChip(
                          c,
                          _Filtro.criticas,
                          'Críticas · ${data.criticas}',
                        ),
                        _filtroChip(c, _Filtro.dispositivos, 'Dispositivos'),
                        _filtroChip(c, _Filtro.energia, 'Energia'),
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
                                const Icon(
                                  Icons.gpp_maybe_outlined,
                                  color: _red,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ação recomendada',
                                        style: TextStyle(
                                          color: c.fg,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        recomendada.descricao,
                                        style: TextStyle(
                                          color: c.muted,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: _red,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (grupos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: c.mint,
                              size: 40,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Tudo em dia',
                              style: TextStyle(
                                color: c.fg,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nenhuma notificação neste filtro.',
                              style: TextStyle(
                                color: c.muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
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
                            Text(
                              grupo.key,
                              style: TextStyle(
                                color: c.fg,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (grupo.key == grupos.keys.first)
                              TextButton(
                                onPressed: data.naoLidas == 0
                                    ? null
                                    : data.marcarTodasLidas,
                                style: TextButton.styleFrom(
                                  foregroundColor: c.mint,
                                  disabledForegroundColor: c.muted,
                                ),
                                child: const Text('Marcar como lidas'),
                              ),
                          ],
                        ),
                      ),
                      for (final alerta in grupo.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _card(c, alerta, agora),
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

  Widget _filtroChip(CosColors c, _Filtro filtro, String label) {
    final critico = filtro == _Filtro.criticas;
    final selecionado = _filtro == filtro;
    final cor = critico ? _red : c.mint;
    return ChoiceChip(
      key: ValueKey('filtro-${filtro.name}'),
      label: Text(label),
      selected: selecionado,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtro = filtro),
      backgroundColor: critico ? _red.withValues(alpha: 0.18) : c.panelElevated,
      selectedColor: cor.withValues(alpha: 0.2),
      side: BorderSide(
        color: selecionado ? cor.withValues(alpha: 0.5) : Colors.transparent,
      ),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: selecionado || critico ? cor : c.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _card(CosColors c, Alerta alerta, DateTime agora) {
    final lida = widget.data.estaLida(alerta);
    return Semantics(
      label: lida ? 'Notificação lida' : 'Notificação não lida',
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
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
                      Text(
                        alerta.titulo,
                        style: TextStyle(
                          color: c.fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alerta.descricao,
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _horario(alerta, agora),
                        style: TextStyle(color: c.muted, fontSize: 11),
                      ),
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
                      decoration: BoxDecoration(
                        color: c.mint,
                        shape: BoxShape.circle,
                      ),
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

class _AlertaIcon extends StatelessWidget {
  final AlertaTipo tipo;
  const _AlertaIcon({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final c = CosColors.of(context);
    final (icone, cor) = switch (tipo) {
      AlertaTipo.dispositivo => (Icons.wifi_off_rounded, _red),
      AlertaTipo.energia => (Icons.bolt_outlined, _amber),
      AlertaTipo.rotina => (Icons.meeting_room_outlined, c.mint),
      AlertaTipo.atualizacao => (Icons.sync_rounded, _blue),
      AlertaTipo.membro => (Icons.person_add_alt_outlined, c.mint),
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
