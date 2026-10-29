import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_vi/screens/dashboard.dart';
import 'package:pi_vi/screens/dispositivo.dart';

void main() {
  testWidgets('exibe dispositivos e navegação compartilhada', (tester) async {
    final alterados = <String>[];
    final adicionados = <DispositivoListaItem>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DispositivoScreen(
          dispositivos: const [
            DispositivoListaItem(
              nome: 'Luz da sala',
              ambiente: 'Sala',
              icone: Icons.lightbulb_outline_rounded,
              ligado: true,
            ),
            DispositivoListaItem(
              nome: 'Tomada do quarto',
              ambiente: 'Quarto',
              icone: Icons.power_rounded,
              ligado: false,
              online: false,
            ),
          ],
          ambientes: const ['Sala', 'Quarto'],
          onToggle: alterados.add,
          onAddDevice: adicionados.add,
          onNavigate: (_) {},
        ),
      ),
    );

    expect(find.text('COS'), findsOneWidget);
    expect(find.text('Dispositivos'), findsNWidgets(2));
    expect(find.text('1 online · 1 offline'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Automações'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Luz da sala'), findsOneWidget);
    expect(find.text('Tomada do quarto'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(alterados, ['Luz da sala']);

    await tester.tap(find.byTooltip('Adicionar dispositivo'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha como deseja começar'), findsOneWidget);
    expect(find.text('Procurar por perto'), findsOneWidget);
    expect(find.text('Selecionar por tipo'), findsOneWidget);
    await tester.tap(find.text('Iluminação'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Luz da varanda');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(adicionados, hasLength(1));
    expect(adicionados.single.nome, 'Luz da varanda');
    expect(find.text('Luz da varanda'), findsOneWidget);
    expect(find.text('Casa do Paulo'), findsOneWidget);
  });

  testWidgets('filtra dispositivos pelo ambiente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DispositivoScreen(
          dispositivos: const [
            DispositivoListaItem(
              nome: 'Luz da sala',
              ambiente: 'Sala',
              icone: Icons.lightbulb_outline_rounded,
              ligado: true,
            ),
            DispositivoListaItem(
              nome: 'Tomada do quarto',
              ambiente: 'Quarto',
              icone: Icons.power_rounded,
              ligado: false,
            ),
          ],
          ambientes: const ['Sala', 'Quarto'],
          onToggle: (_) {},
          onAddDevice: (_) {},
          onNavigate: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Quarto').first);
    await tester.pumpAndSettle();

    expect(find.text('Tomada do quarto'), findsOneWidget);
    expect(find.text('Luz da sala'), findsNothing);
  });

  testWidgets('permite continuar por outros ao buscar um modelo', (
    tester,
  ) async {
    final adicionados = <DispositivoListaItem>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DispositivoScreen(
          dispositivos: const [],
          ambientes: const ['Sala'],
          onToggle: (_) {},
          onAddDevice: adicionados.add,
          onNavigate: (_) {},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Adicionar dispositivo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Sensor XYZ');
    await tester.pumpAndSettle();

    expect(find.text('Adicionar em Outros'), findsOneWidget);
    await tester.tap(find.text('Adicionar em Outros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar outros'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      'Sensor XYZ',
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(adicionados.single.nome, 'Sensor XYZ');
    expect(adicionados.single.ambiente, 'Sala');
  });

  testWidgets('navega do dashboard para dispositivos e volta ao início', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    await tester.tap(find.text('Dispositivos').last);
    await tester.pumpAndSettle();

    expect(find.text('Casa do Paulo'), findsOneWidget);
    expect(find.text('Todos · 6'), findsOneWidget);
    expect(find.text('Offline · 1'), findsOneWidget);
    expect(
      find.text('Sala de estar · Sem resposta à rede Wi-Fi'),
      findsOneWidget,
    );
    expect(find.text('OFFLINE'), findsOneWidget);

    await tester.tap(find.text('Início').last);
    await tester.pumpAndSettle();

    expect(find.text('Seu espaço, suas regras.'), findsOneWidget);
    expect(find.text('Casa do Paulo'), findsNothing);
  });
}
