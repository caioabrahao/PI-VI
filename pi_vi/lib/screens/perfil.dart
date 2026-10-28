import 'package:flutter/material.dart';
import 'package/services/firebase_service.dart';

final perfilThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

class PerfilScreen extends StatelessWidget {
  final int ambientes;
  final int dispositivos;
  const PerfilScreen({super.key, required this.ambientes, required this.dispositivos});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: perfilThemeMode,
      builder: (context, mode, _) {
        final dark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF00836F),
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: dark ? const Color(0xFF4FE0C0) : const Color(0xFF007C68),
          surface: dark ? const Color(0xFF10151B) : Colors.white,
          onSurface: dark ? const Color(0xFFF1F5F8) : const Color(0xFF172C30),
          onSurfaceVariant: dark ? const Color(0xFF96A5B1) : const Color(0xFF566970),
          outlineVariant: dark ? const Color(0xFF293640) : const Color(0xFFD6E2DF),
          primaryContainer: dark ? const Color(0xFF173D35) : const Color(0xFFDDF5ED),
        );
        return Theme(
          data: ThemeData(useMaterial3: true, colorScheme: scheme,
            scaffoldBackgroundColor: dark ? const Color(0xFF080B0F) : const Color(0xFFF3F7F6)),
          child: _PerfilBody(ambientes: ambientes, dispositivos: dispositivos),
        );
      },
    );
  }
}

class _PerfilBody extends StatelessWidget {
  final int ambientes;
  final int dispositivos;
  const _PerfilBody({required this.ambientes, required this.dispositivos});

  void _details(BuildContext context, String title, String description) {
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: Text(description),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    ));
  }

  void _appearance(BuildContext context) {
    showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Aparência', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final option in [
            (ThemeMode.system, Icons.brightness_auto_outlined, 'Automático — seguir sistema'),
            (ThemeMode.light, Icons.light_mode_outlined, 'Modo dia'),
            (ThemeMode.dark, Icons.dark_mode_outlined, 'Modo noite'),
          ]) ListTile(
            leading: Icon(option.$2), title: Text(option.$3),
            trailing: perfilThemeMode.value == option.$1 ? const Icon(Icons.check) : null,
            onTap: () { perfilThemeMode.value = option.$1; Navigator.pop(sheetContext); },
          ),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final user = FirebaseService.usuarioAtual;
    final name = (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName!.trim() : 'Meu perfil';
    final email = user?.email ?? 'Nenhuma conta conectada';
    final initials = name.split(RegExp(r'\s+')).take(2).map((word) => word.characters.first).join().toUpperCase();
    final modeLabel = switch (perfilThemeMode.value) {
      ThemeMode.system => 'Automático · seguir sistema',
      ThemeMode.light => 'Modo dia',
      ThemeMode.dark => 'Modo noite',
    };

    Widget panel(List<Widget> children) => Card(
      margin: EdgeInsets.zero, elevation: 0, color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
    Widget row(IconData icon, String title, String subtitle, VoidCallback tap) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      leading: Container(padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c.primary, size: 21)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right, size: 19, color: c.onSurfaceVariant), onTap: tap,
    );
    Widget heading(String title, {String? action, VoidCallback? tap}) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        if (action != null) TextButton(onPressed: tap, child: Text(action)),
      ]),
    );
    Widget member(String initials, String name, String role, Color color) => ListTile(
      leading: CircleAvatar(radius: 17, backgroundColor: color,
        child: Text(initials, style: const TextStyle(color: Color(0xFF09231F), fontSize: 11, fontWeight: FontWeight.bold))),
      title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(role, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _details(context, name, '$role\nMembro ilustrativo, sem vínculo com uma casa real.'),
    );

    return Scaffold(
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [
          Row(children: [
            CircleAvatar(radius: 18, backgroundColor: c.primaryContainer, child: Icon(Icons.home_outlined, color: c.primary, size: 21)),
            const SizedBox(width: 10),
            const Text('COS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Perfil e casa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Gerencie sua experiência COS', style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
            ])),
            IconButton(tooltip: 'Alterar aparência', onPressed: () => _appearance(context), icon: const Icon(Icons.settings_outlined)),
          ]),
          const SizedBox(height: 20),
          Card(margin: EdgeInsets.zero, elevation: 0, color: c.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.primary.withValues(alpha: 0.4))),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: ListTile(
              leading: CircleAvatar(radius: 27, backgroundColor: const Color(0xFF4FE0C0),
                child: Text(initials, style: const TextStyle(color: Color(0xFF09231F), fontWeight: FontWeight.bold))),
              title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(email, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text(user?.emailVerified == true ? 'E-MAIL VERIFICADO' : 'PERFIL DA CONTA', style: TextStyle(fontSize: 10, color: c.primary, fontWeight: FontWeight.w600)),
              ]),
              trailing: Icon(Icons.chevron_right, color: c.primary),
              onTap: () => _details(context, 'Minha conta', '$name\n$email'),
            )),
          ),
          heading('Minha casa', action: 'Editar', tap: () => _details(context, 'Minha casa')),
          panel([
            row(Icons.location_on_outlined, 'Informações da casa', 'Nova Odessa, SP', () => _details(context, 'Casa')),
            row(Icons.home_outlined, 'Resumo', '$ambientes ambientes · $dispositivos dispositivos', () => _details(context, 'Resumo da casa', 'Contagens do painel atual:\n$ambientes ambientes\n$dispositivos dispositivos')),
          ]),
          heading('Membros', action: '+ Convidar', tap: () => _details(context, 'Convidar membro')),
          panel([
            member('PC', 'Paulo Cesar', 'Proprietário', const Color(0xFF4FE0C0)),
          ]),
          heading('Segurança e preferências'),
          panel([
            row(Icons.shield_outlined, 'Segurança', 'Informações de acesso', () => _details(context, 'Segurança')),
            row(Icons.notifications_none, 'Notificações', 'Preferências em desenvolvimento', () => _details(context, 'Notificações')),
            row(Icons.palette_outlined, 'Aparência', modeLabel, () => _appearance(context)),
          ]),
        ]),
      ))),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) { if (index == 0) Navigator.pop(context); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
