import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_vi/screens/dashboard.dart';

void main() {
  testWidgets('conecta um dispositivo disponível a um ambiente', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    await tester.scrollUntilVisible(
      find.text('Gerenciar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Gerenciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerenciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar ambiente').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar dispositivos'), findsOneWidget);
    await tester.tap(find.text('Lâmpada').last);
    await tester.tap(find.text('Conectar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Banheiro'), findsWidgets);
    expect(find.text('1 dispositivo'), findsWidgets);
  });

  testWidgets('exige duas confirmações para excluir ambiente com dispositivos', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    await tester.scrollUntilVisible(
      find.text('Gerenciar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Gerenciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerenciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir ambiente').first);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Você deseja excluir Sala de estar com os dispositivos Luz da sala e Ar-condicionado?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Tem certeza que deseja excluir?'), findsOneWidget);
    await tester.tap(find.text('Excluir ambiente'));
    await tester.pumpAndSettle();

    expect(find.text('3 ambientes'), findsOneWidget);
  });
}
