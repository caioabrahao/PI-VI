import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pi_vi/screens/dispositivo.dart';

// =====================================================
// TESTES DO COS - DISPOSITIVOS
//
// Estes testes verificam a interface e o cadastro
// manual sem depender de autenticação ou Firestore.
// =====================================================

void main() {
  // ===================================================
  // TESTE 1 - EXIBE A TELA DE ADICIONAR DISPOSITIVO
  // ===================================================

  testWidgets('exibe as opções de cadastro de dispositivo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdicionarDispositivoScreen(
          ambientes: ['Sala', 'Quarto'],
          nomesExistentes: {},
        ),
      ),
    );

    expect(find.text('Adicionar dispositivo'), findsOneWidget);

    expect(find.text('Escolha como deseja começar'), findsOneWidget);

    expect(find.text('Procurar por perto'), findsOneWidget);

    expect(find.text('Selecionar por tipo'), findsOneWidget);

    expect(find.text('Iluminação'), findsOneWidget);

    expect(find.text('Tomada'), findsOneWidget);
  });

  // ===================================================
  // TESTE 2 - CADASTRAR UM DISPOSITIVO POR TIPO
  // ===================================================

  testWidgets('permite cadastrar uma lâmpada na sala', (
    WidgetTester tester,
  ) async {
    DispositivoListaItem? dispositivoAdicionado;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    dispositivoAdicionado = await Navigator.of(context)
                        .push<DispositivoListaItem>(
                          MaterialPageRoute(
                            builder: (_) => const AdicionarDispositivoScreen(
                              ambientes: ['Sala', 'Quarto'],
                              nomesExistentes: {},
                            ),
                          ),
                        );
                  },
                  child: const Text('Abrir cadastro'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Abre a tela de cadastro.
    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha como deseja começar'), findsOneWidget);

    // Seleciona a categoria Iluminação.
    await tester.ensureVisible(find.text('Iluminação'));

    await tester.tap(find.text('Iluminação'));
    await tester.pumpAndSettle();

    // Preenche o nome do dispositivo.
    await tester.enterText(find.byType(TextFormField).first, 'Luz da varanda');

    // Salva o dispositivo.
    await tester.tap(find.text('Adicionar').last);
    await tester.pumpAndSettle();

    // Verifica se os dados foram retornados.
    expect(dispositivoAdicionado, isNotNull);

    expect(dispositivoAdicionado!.nome, 'Luz da varanda');

    expect(dispositivoAdicionado!.ambiente, 'Sala');

    expect(dispositivoAdicionado!.icone, Icons.lightbulb_outline_rounded);

    expect(dispositivoAdicionado!.ligado, isFalse);
  });

  // ===================================================
  // TESTE 3 - BUSCA POR UM MODELO DESCONHECIDO
  // ===================================================

  testWidgets('permite adicionar um modelo desconhecido em Outros', (
    WidgetTester tester,
  ) async {
    DispositivoListaItem? dispositivoAdicionado;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    dispositivoAdicionado = await Navigator.of(context)
                        .push<DispositivoListaItem>(
                          MaterialPageRoute(
                            builder: (_) => const AdicionarDispositivoScreen(
                              ambientes: ['Sala'],
                              nomesExistentes: {},
                            ),
                          ),
                        );
                  },
                  child: const Text('Abrir cadastro'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();

    // Procura um modelo não listado.
    await tester.enterText(find.byType(TextField).first, 'Sensor XYZ');

    await tester.pumpAndSettle();

    expect(find.text('Adicionar em Outros'), findsOneWidget);

    // Seleciona a opção Outros.
    await tester.tap(find.text('Adicionar em Outros'));
    await tester.pumpAndSettle();

    // O nome pesquisado deve aparecer
    // automaticamente no formulário.
    final campoNome = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );

    expect(campoNome.controller?.text, 'Sensor XYZ');

    // Confirma o cadastro.
    await tester.tap(find.text('Adicionar').last);
    await tester.pumpAndSettle();

    expect(dispositivoAdicionado, isNotNull);

    expect(dispositivoAdicionado!.nome, 'Sensor XYZ');

    expect(dispositivoAdicionado!.ambiente, 'Sala');

    expect(dispositivoAdicionado!.ligado, isFalse);
  });

  // ===================================================
  // TESTE 4 - NÃO PERMITIR NOMES DUPLICADOS
  // ===================================================

  testWidgets('não permite cadastrar dois dispositivos com o mesmo nome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdicionarDispositivoScreen(
          ambientes: ['Sala'],
          nomesExistentes: {'Luz da sala'},
        ),
      ),
    );

    // Abre a categoria Iluminação.
    await tester.ensureVisible(find.text('Iluminação'));

    await tester.tap(find.text('Iluminação'));
    await tester.pumpAndSettle();

    // Digita um nome já existente.
    await tester.enterText(find.byType(TextFormField).first, 'Luz da sala');

    // Tenta cadastrar.
    await tester.tap(find.text('Adicionar').last);
    await tester.pumpAndSettle();

    // A validação deve impedir a duplicação.
    expect(
      find.text('Já existe um dispositivo com esse nome.'),
      findsOneWidget,
    );
  });

  // ===================================================
  // TESTE 5 - VALIDAR NOME OBRIGATÓRIO
  // ===================================================

  testWidgets('exige o nome do dispositivo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdicionarDispositivoScreen(
          ambientes: ['Sala'],
          nomesExistentes: {},
        ),
      ),
    );

    // Abre a categoria Iluminação.
    await tester.ensureVisible(find.text('Iluminação'));

    await tester.tap(find.text('Iluminação'));
    await tester.pumpAndSettle();

    // Deixa o nome em branco.
    await tester.enterText(find.byType(TextFormField).first, '');

    // Tenta adicionar sem nome.
    await tester.tap(find.text('Adicionar').last);
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do dispositivo.'), findsOneWidget);
  });

  // ===================================================
  // TESTE 6 - MODELO DO DISPOSITIVO
  // ===================================================

  test('DispositivoListaItem guarda os dados corretamente', () {
    const dispositivo = DispositivoListaItem(
      id: 'dispositivo-123',
      nome: 'Tomada do quarto',
      ambiente: 'Quarto',
      icone: Icons.power_rounded,
      ligado: false,
      online: false,
    );

    expect(dispositivo.id, 'dispositivo-123');

    expect(dispositivo.nome, 'Tomada do quarto');

    expect(dispositivo.ambiente, 'Quarto');

    expect(dispositivo.icone, Icons.power_rounded);

    expect(dispositivo.ligado, isFalse);

    expect(dispositivo.online, isFalse);
  });
}
