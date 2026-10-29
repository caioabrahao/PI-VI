import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_vi/screens/automacao.dart';
import 'package:pi_vi/screens/dashboard.dart';

void main() {
  const devices = [
    AutomacaoDevice(
      id: 'lamp-bedroom',
      name: 'Luz do quarto',
      location: 'Quarto',
      type: AutomacaoDeviceType.lampada,
      online: true,
      isOn: false,
    ),
    AutomacaoDevice(
      id: 'lamp-kitchen',
      name: 'Luz da cozinha',
      location: 'Cozinha',
      type: AutomacaoDeviceType.lampada,
      online: true,
      isOn: true,
    ),
    AutomacaoDevice(
      id: 'plug-tv',
      name: 'Tomada TV',
      location: 'Sala',
      type: AutomacaoDeviceType.tomada,
      online: true,
      isOn: false,
    ),
    AutomacaoDevice(
      id: 'plug-kitchen',
      name: 'Tomada inteligente',
      location: 'Cozinha',
      type: AutomacaoDeviceType.tomada,
      online: true,
      isOn: true,
    ),
  ];

  testWidgets('exibe lâmpada, cenas e aplica configuração selecionada', (
    tester,
  ) async {
    final data = AutomacaoData();
    final alteracoes = <(String, bool)>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AutomacaoScreen(
          data: data,
          devices: devices,
          onPowerChanged: (id, enabled) => alteracoes.add((id, enabled)),
          onNavigate: (_) {},
        ),
      ),
    );

    expect(find.text('Automações'), findsNWidgets(2));
    expect(find.text('Lâmpada'), findsOneWidget);
    expect(find.text('Tomada Smart'), findsOneWidget);
    expect(find.text('Raspberry Hub'), findsOneWidget);
    expect(find.text('Luz do quarto'), findsOneWidget);
    expect(find.text('Luz da cozinha · Cozinha'), findsOneWidget);
    expect(find.text('Brilho'), findsOneWidget);
    expect(find.text('Temperatura'), findsOneWidget);
    expect(find.text('Cenas'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Leitura'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leitura'));
    await tester.pump();

    final bedroomLamp = devices.first;
    expect(data.isOn(bedroomLamp), isTrue);
    expect(data.brightness(bedroomLamp), 0.95);
    expect(data.temperature(bedroomLamp), 5000);
    expect(alteracoes, [('lamp-bedroom', true)]);
  });

  testWidgets('permite escolher cor e registrar estimativa de consumo', (
    tester,
  ) async {
    final data = AutomacaoData();
    final lamp = devices.first;

    await tester.pumpWidget(
      MaterialApp(
        home: AutomacaoScreen(
          data: data,
          devices: devices,
          onPowerChanged: (_, _) {},
          onNavigate: (_) {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Personalizar'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personalizar'));
    await tester.pumpAndSettle();
    expect(find.text('Personalizar cor'), findsOneWidget);

    final colorWheel = find.byKey(const ValueKey('automation-color-wheel'));
    await tester.tapAt(tester.getCenter(colorWheel) + const Offset(70, 0));
    await tester.pump();
    expect(find.text('Personalizar cor'), findsOneWidget);
    await tester.tap(find.text('Usar cor'));
    await tester.pumpAndSettle();
    expect(data.color(lamp), isNot(const Color(0xFF4FE0C0)));

    await tester.scrollUntilVisible(
      find.text('Registrar'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar'));
    await tester.pump();
    expect(data.registros, hasLength(1));
    expect(data.registros.single.deviceId, 'lamp-bedroom');
    expect(find.text('Leitura de consumo registrada.'), findsOneWidget);
    expect(find.textContaining('não é leitura de sensor'), findsOneWidget);
  });

  testWidgets('seleciona a tomada e mantém o rodapé compartilhado', (
    tester,
  ) async {
    final data = AutomacaoData();
    final alteracoes = <(String, bool)>[];
    final navegacao = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AutomacaoScreen(
          data: data,
          devices: devices,
          onPowerChanged: (id, enabled) => alteracoes.add((id, enabled)),
          onNavigate: navegacao.add,
        ),
      ),
    );

    await tester.tap(find.text('Raspberry Hub').first);
    await tester.pump();
    expect(find.text('Central da casa'), findsOneWidget);
    expect(find.text('Raspberry Hub'), findsNWidgets(2));
    expect(find.text('Escritório · Raspberry Pi 5'), findsOneWidget);
    expect(find.text('cos-hub.local'), findsOneWidget);
    expect(find.text('Recursos do sistema'), findsOneWidget);
    expect(find.text('CPU'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('192.168.1.8'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.textContaining('Home Assistant'), findsOneWidget);
    expect(find.textContaining('MQTT Broker'), findsOneWidget);
    expect(find.textContaining('Pi-hole'), findsOneWidget);
    expect(
      find.text(
        'Dados de sistema e serviços são ilustrativos; o Raspberry Pi ainda não está conectado.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Gerenciar'));
    await tester.pumpAndSettle();
    expect(find.text('Serviços do Raspberry Hub'), findsOneWidget);
    expect(
      find.text(
        'A conexão com o Raspberry Pi não está configurada. O status dos serviços é apenas demonstrativo.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reiniciar'));
    await tester.pumpAndSettle();
    expect(find.text('Reiniciar Raspberry Hub?'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Reinício não executado: Raspberry Pi não conectado.'),
      findsOneWidget,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tomada Smart').first);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('automation-device-plug-kitchen')),
    );
    await tester.pump();
    expect(find.text('Tomada inteligente · Cozinha'), findsOneWidget);
    expect(find.text('Tomada TV · Sala'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('Energia ligada'), findsOneWidget);
    expect(find.text('POTÊNCIA AGORA'), findsOneWidget);
    expect(find.text('TENSÃO'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText().contains('221') == true,
      ),
      findsOneWidget,
    );
    expect(find.text('Consumo hoje'), findsOneWidget);
    expect(find.text('Agenda semanal'), findsOneWidget);
    expect(find.text('+ 15 min'), findsOneWidget);
    expect(find.text('Desligar agora'), findsOneWidget);

    await tester.ensureVisible(find.text('Desligar agora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desligar agora'));
    await tester.pump();
    expect(data.isOn(devices.last), isFalse);
    expect(data.isOn(devices[2]), isFalse);
    expect(alteracoes, [('plug-kitchen', false)]);

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Dispositivos'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    await tester.tap(find.text('Perfil').last);
    expect(navegacao, [4]);
  });

  testWidgets('cada lâmpada mantém seu próprio estado e configuração', (
    tester,
  ) async {
    final data = AutomacaoData();

    await tester.pumpWidget(
      MaterialApp(
        home: AutomacaoScreen(
          data: data,
          devices: devices,
          onPowerChanged: (_, _) {},
          onNavigate: (_) {},
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('automation-device-lamp-kitchen')),
    );
    await tester.pump();
    expect(find.text('Luz da cozinha'), findsOneWidget);
    expect(data.isOn(devices[1]), isTrue);
    await tester.scrollUntilVisible(
      find.text('Relaxar'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relaxar'));
    await tester.pump();
    expect(data.brightness(devices[1]), 0.55);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 700));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('automation-device-lamp-bedroom')),
    );
    await tester.pump();
    expect(find.text('Luz do quarto'), findsOneWidget);
    expect(data.isOn(devices[0]), isFalse);
    expect(data.isOn(devices[1]), isTrue);
    expect(data.brightness(devices[0]), 0.78);
    expect(data.brightness(devices[1]), 0.55);
  });

  testWidgets('dashboard abre a tela de automações pelo rodapé compartilhado', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    await tester.tap(find.text('Automações').last);
    await tester.pumpAndSettle();

    expect(find.text('Automações'), findsNWidgets(2));
    expect(find.text('Luz principal'), findsOneWidget);
    expect(find.text('Brilho'), findsOneWidget);
    expect(find.text('Raspberry Hub'), findsOneWidget);
  });
}
