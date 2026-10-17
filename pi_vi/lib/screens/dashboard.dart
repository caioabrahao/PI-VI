import 'package:flutter/material.dart';

const Color _bg = Color(0xFF080B0F);
const Color _panel = Color(0xFF10151B);
const Color _panel2 = Color(0xFF171E26);
const Color _border = Color(0xFF293640);
const Color _muted = Color(0xFF8A98A5);
const Color _fg = Color(0xFFF1F5F8);
const Color _mint = Color(0xFF4FE0C0);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _luzSalaLigada = true;
  bool _arLigado = false;
  bool _luzQuartoLigada = false;
  bool _tomadaLigada = true;

  int get _dispositivosLigados => [
    _luzSalaLigada,
    _arLigado,
    _luzQuartoLigada,
    _tomadaLigada,
  ].where((ligado) => ligado).length;

  void _alternarDispositivo(String nome, bool valor) {
    setState(() {
      switch (nome) {
        case 'Luz da sala':
          _luzSalaLigada = valor;
          break;
        case 'Ar-condicionado':
          _arLigado = valor;
          break;
        case 'Luz do quarto':
          _luzQuartoLigada = valor;
          break;
        case 'Tomada inteligente':
          _tomadaLigada = valor;
          break;
      }
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: _panel2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _novoAtalho() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panel,
        title: const Text(
          'Criar atalho',
          style: TextStyle(color: _fg, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'A criação de rotinas será conectada à automação da casa em uma próxima etapa.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi', style: TextStyle(color: _mint)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _cabecalho(),
                  const SizedBox(height: 28),
                  _saudacao(),
                  const SizedBox(height: 22),
                  _cartaoClima(),
                  const SizedBox(height: 14),
                  _resumoDispositivos(),
                  const SizedBox(height: 28),
                  _tituloSecao(
                    'Dispositivos',
                    '$_dispositivosLigados de 4 ligados',
                    acao: 'Ver todos',
                    onAcao: () => _mostrarMensagem(
                      'Você está vendo os dispositivos cadastrados nesta demonstração.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _gradeDispositivos(),
                  const SizedBox(height: 28),
                  _tituloSecao('Consumo de energia', 'Hoje'),
                  const SizedBox(height: 14),
                  _cartaoEnergia(),
                  const SizedBox(height: 28),
                  _tituloSecao(
                    'Ambientes',
                    '4 ambientes',
                    acao: 'Gerenciar',
                    onAcao: () => _mostrarMensagem(
                      'O gerenciamento de ambientes será integrado futuramente.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _gradeAmbientes(),
                  const SizedBox(height: 28),
                  _tituloSecao(
                    'Atalhos',
                    'Suas rotinas',
                    acao: '＋ Criar',
                    onAcao: _novoAtalho,
                  ),
                  const SizedBox(height: 14),
                  _atalhos(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'COS  •  CONTROLE DA SUA CASA',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _barraNavegacao(),
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _mint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _mint.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.home_rounded, color: _mint, size: 25),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COS',
              style: TextStyle(
                color: _fg,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'CASA INTELIGENTE',
              style: TextStyle(color: _muted, fontSize: 9, letterSpacing: 1.2),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Notificações',
          onPressed: () => _mostrarMensagem('Você não tem novas notificações.'),
          icon: const Icon(Icons.notifications_none_rounded, color: _fg),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _panel2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.person_outline_rounded, color: _fg),
        ),
      ],
    );
  }

  Widget _saudacao() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seu espaço, suas regras.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        SizedBox(height: 7),
        Text(
          'Olá, seja bem-vindo!',
          style: TextStyle(
            color: _fg,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Veja o que está acontecendo na sua casa.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _cartaoClima() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163B3B), _panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _mint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: _mint, size: 18),
                    SizedBox(width: 7),
                    Text(
                      'AMBIENTE DA CASA',
                      style: TextStyle(
                        color: _mint,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '22°C',
                  style: TextStyle(
                    color: _fg,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Temperatura ilustrativa',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _mint.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.thermostat_rounded, color: _mint, size: 42),
          ),
        ],
      ),
    );
  }

  Widget _resumoDispositivos() {
    return Row(
      children: [
        Expanded(
          child: _cartaoResumo(
            icone: Icons.power_settings_new_rounded,
            titulo: 'Dispositivos',
            valor: '$_dispositivosLigados/4',
            descricao: 'em funcionamento',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cartaoResumo(
            icone: Icons.bolt_rounded,
            titulo: 'Energia hoje',
            valor: '8,4 kWh',
            descricao: 'valor ilustrativo',
          ),
        ),
      ],
    );
  }

  Widget _cartaoResumo({
    required IconData icone,
    required String titulo,
    required String valor,
    required String descricao,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: _mint, size: 21),
          const SizedBox(height: 14),
          Text(titulo, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            valor,
            style: const TextStyle(
              color: _fg,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(descricao, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _tituloSecao(
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
                style: const TextStyle(
                  color: _fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitulo,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        if (acao != null)
          TextButton(
            onPressed: onAcao,
            style: TextButton.styleFrom(
              foregroundColor: _mint,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              acao,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _gradeDispositivos() {
    final dispositivos = [
      _DeviceData(
        nome: 'Luz da sala',
        local: 'Sala de estar',
        icone: Icons.lightbulb_outline_rounded,
        ligado: _luzSalaLigada,
      ),
      _DeviceData(
        nome: 'Ar-condicionado',
        local: 'Sala de estar',
        icone: Icons.ac_unit_rounded,
        ligado: _arLigado,
      ),
      _DeviceData(
        nome: 'Luz do quarto',
        local: 'Quarto principal',
        icone: Icons.lightbulb_outline_rounded,
        ligado: _luzQuartoLigada,
      ),
      _DeviceData(
        nome: 'Tomada inteligente',
        local: 'Cozinha',
        icone: Icons.power_rounded,
        ligado: _tomadaLigada,
      ),
    ];

    return GridView.builder(
      itemCount: dispositivos.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 158,
      ),
      itemBuilder: (context, index) {
        final dispositivo = dispositivos[index];

        return _DeviceCard(
          data: dispositivo,
          onChanged: (valor) {
            _alternarDispositivo(dispositivo.nome, valor);
          },
        );
      },
    );
  }

  Widget _cartaoEnergia() {
    const dias = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    const valores = [0.42, 0.68, 0.51, 0.83, 0.61, 0.95, 0.72];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumo semanal',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Dados de exemplo',
                      style: TextStyle(
                        color: _fg,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: _mint, size: 26),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(valores.length, (index) {
                final selecionado = index == 5;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: valores[index],
                              widthFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selecionado
                                      ? _mint
                                      : _mint.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dias[index],
                          style: TextStyle(
                            color: selecionado ? _mint : _muted,
                            fontSize: 9,
                            fontWeight: selecionado
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeAmbientes() {
    final ambientes = [
      const _RoomData(
        nome: 'Sala de estar',
        dispositivos: '2 dispositivos',
        icone: Icons.weekend_outlined,
      ),
      const _RoomData(
        nome: 'Quarto',
        dispositivos: '1 dispositivo',
        icone: Icons.bed_outlined,
      ),
      const _RoomData(
        nome: 'Cozinha',
        dispositivos: '1 dispositivo',
        icone: Icons.kitchen_outlined,
      ),
      const _RoomData(
        nome: 'Banheiro',
        dispositivos: 'Nenhum dispositivo',
        icone: Icons.shower_outlined,
      ),
    ];

    return GridView.builder(
      itemCount: ambientes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 106,
      ),
      itemBuilder: (context, index) {
        final ambiente = ambientes[index];

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () =>
              _mostrarMensagem('Ambiente "${ambiente.nome}" selecionado.'),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _panel2,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(ambiente.icone, color: _mint, size: 22),
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
                        style: const TextStyle(
                          color: _fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ambiente.dispositivos,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _atalhos() {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            icone: Icons.nightlight_round,
            titulo: 'Modo noite',
            descricao: 'Preparar para dormir',
            onTap: () => _mostrarMensagem(
              'O modo noite ainda não está conectado aos dispositivos.',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            icone: Icons.wb_sunny_outlined,
            titulo: 'Modo dia',
            descricao: 'Ativar rotina da manhã',
            onTap: () => _mostrarMensagem(
              'O modo dia ainda não está conectado aos dispositivos.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _barraNavegacao() {
    return Container(
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icone: Icons.grid_view_rounded,
                titulo: 'Início',
                selecionado: true,
                onTap: () {},
              ),
              _NavItem(
                icone: Icons.devices_other_rounded,
                titulo: 'Dispositivos',
                onTap: () => _mostrarMensagem(
                  'A lista de dispositivos já aparece nesta tela.',
                ),
              ),
              _NavItem(
                icone: Icons.auto_awesome_outlined,
                titulo: 'Rotinas',
                onTap: _novoAtalho,
              ),
              _NavItem(
                icone: Icons.settings_outlined,
                titulo: 'Ajustes',
                onTap: () => _mostrarMensagem(
                  'As configurações ainda serão implementadas.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceData {
  final String nome;
  final String local;
  final IconData icone;
  final bool ligado;

  const _DeviceData({
    required this.nome,
    required this.local,
    required this.icone,
    required this.ligado,
  });
}

class _DeviceCard extends StatelessWidget {
  final _DeviceData data;
  final ValueChanged<bool> onChanged;

  const _DeviceCard({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ativo = data.ligado;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ativo ? _mint.withValues(alpha: 0.38) : _border,
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
                  color: ativo ? _mint.withValues(alpha: 0.12) : _panel2,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  data.icone,
                  color: ativo ? _mint : _muted,
                  size: 22,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: ativo,
                onChanged: onChanged,
                activeThumbColor: _mint,
                activeTrackColor: _mint.withValues(alpha: 0.35),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: ativo ? _mint : _muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ativo ? 'Ligado' : 'Desligado',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ),
              Flexible(
                child: Text(
                  data.local,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomData {
  final String nome;
  final String dispositivos;
  final IconData icone;

  const _RoomData({
    required this.nome,
    required this.dispositivos,
    required this.icone,
  });
}

class _ShortcutCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: _mint, size: 25),
            const SizedBox(height: 13),
            Text(
              titulo,
              style: const TextStyle(
                color: _fg,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              descricao,
              style: const TextStyle(color: _muted, fontSize: 10, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _NavItem({
    required this.icone,
    required this.titulo,
    this.selecionado = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? _mint : _muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: cor, size: 21),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                color: cor,
                fontSize: 9,
                fontWeight: selecionado ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
