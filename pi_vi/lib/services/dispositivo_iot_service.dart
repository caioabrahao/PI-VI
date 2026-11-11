import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dispositivo_iot.dart';
import '../models/estado_lampada.dart';
import 'firebase_service.dart';
import 'servico_mqtt.dart';

class DispositivoIotService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Coleção exclusiva do usuário autenticado
  static CollectionReference<Map<String, dynamic>> _colecaoDoUsuario({
    String? uid,
  }) {
    final usuarioId = uid ?? FirebaseService.usuarioAtual?.uid;

    if (usuarioId == null) {
      throw StateError('Faça login para gerenciar dispositivos IoT.');
    }

    return _db
        .collection('usuarios')
        .doc(usuarioId)
        .collection('dispositivosIot');
  }

  // Cadastrar dispositivo
  static Future<DispositivoIot> cadastrar({
    required String nome,
    required String identificador,
    required String tipo,
    String? ambienteId,
  }) async {
    final uid = FirebaseService.usuarioAtual?.uid;

    if (uid == null) {
      throw StateError('Faça login para gerenciar dispositivos IoT.');
    }

    final nomeValidado = _validarTexto(nome, 'nome', 80);

    final identificadorValidado = _validarTexto(
      identificador,
      'identificador',
      128,
    );

    final tipoValidado = _validarTexto(tipo, 'tipo', 50);

    final ambienteValidado = ambienteId?.trim();

    if (ambienteValidado != null && ambienteValidado.isEmpty) {
      throw ArgumentError.value(
        ambienteId,
        'ambienteId',
        'Não pode ser vazio.',
      );
    }

    final colecao = _colecaoDoUsuario(uid: uid);

    final existentes = await colecao
        .where('identificador', isEqualTo: identificadorValidado)
        .limit(1)
        .get();

    if (existentes.docs.isNotEmpty) {
      throw StateError(
        'Já existe um dispositivo IoT '
        'com esse identificador.',
      );
    }

    final agora = FieldValue.serverTimestamp();

    final referencia = await colecao.add({
      'uid': uid,
      'nome': nomeValidado,
      'identificador': identificadorValidado,
      'tipo': tipoValidado,
      'ambienteId': ambienteValidado,
      'statusConexao': 'desconhecido',
      'ligado': false,
      'ultimaConexaoEm': null,
      'criadoEm': agora,
      'atualizadoEm': agora,
    });

    final documento = await referencia.get();
    final dados = documento.data();

    if (!documento.exists || dados == null) {
      throw StateError(
        'Não foi possível carregar '
        'o dispositivo IoT cadastrado.',
      );
    }

    return DispositivoIot.fromFirestore(documento.id, dados);
  }

  // Consultar dispositivos em tempo real
  //
  // Lâmpadas SmartLight recebem `ligado` e `statusConexao` ao vivo do MQTT
  // (ver ServicoMqtt.aplicarEstado); os outros dispositivos vêm só do Firestore.
  static Stream<List<DispositivoIot>> observarDispositivos() {
    return _comEstadoMqtt(_observarCadastro());
  }

  static Stream<List<DispositivoIot>> _comEstadoMqtt(
    Stream<List<DispositivoIot>> cadastro,
  ) {
    final mqtt = ServicoMqtt.instancia;
    late final StreamController<List<DispositivoIot>> saida;
    StreamSubscription<List<DispositivoIot>>? assinaturaCadastro;
    StreamSubscription<String>? assinaturaMqtt;
    List<DispositivoIot>? ultimoCadastro;

    void emitir() {
      final lista = ultimoCadastro;
      if (lista == null || saida.isClosed) return;
      saida.add(lista.map(mqtt.aplicarEstado).toList(growable: false));
    }

    saida = StreamController<List<DispositivoIot>>(
      onListen: () {
        assinaturaCadastro = cadastro.listen((lista) {
          ultimoCadastro = lista;
          if (lista.any((d) => d.usaMqtt)) mqtt.garantirConexao();
          emitir();
        }, onError: saida.addError);
        assinaturaMqtt = mqtt.mudancas.listen((_) => emitir());
        mqtt.status.addListener(emitir);
      },
      onCancel: () async {
        mqtt.status.removeListener(emitir);
        await assinaturaMqtt?.cancel();
        await assinaturaCadastro?.cancel();
      },
    );

    return saida.stream;
  }

  static Stream<List<DispositivoIot>> _observarCadastro() {
    return _colecaoDoUsuario()
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((documento) {
                return DispositivoIot.fromFirestore(
                  documento.id,
                  documento.data(),
                );
              })
              .toList(growable: false);
        });
  }

  // Buscar um dispositivo
  static Future<DispositivoIot?> obter(String id) async {
    final documento = await _colecaoDoUsuario().doc(id).get();

    final dados = documento.data();

    if (!documento.exists || dados == null) {
      return null;
    }

    return DispositivoIot.fromFirestore(documento.id, dados);
  }

  // Atualizar cadastro
  static Future<void> atualizarCadastro({
    required String id,
    required String nome,
    required String identificador,
    required String tipo,
    String? ambienteId,
  }) async {
    final nomeValidado = _validarTexto(nome, 'nome', 80);

    final identificadorValidado = _validarTexto(
      identificador,
      'identificador',
      128,
    );

    final tipoValidado = _validarTexto(tipo, 'tipo', 50);

    final ambienteValidado = ambienteId?.trim();

    if (ambienteValidado != null && ambienteValidado.isEmpty) {
      throw ArgumentError.value(
        ambienteId,
        'ambienteId',
        'Não pode ser vazio.',
      );
    }

    final colecao = _colecaoDoUsuario();

    final repetidos = await colecao
        .where('identificador', isEqualTo: identificadorValidado)
        .get();

    if (repetidos.docs.any((documento) => documento.id != id)) {
      throw StateError(
        'Já existe um dispositivo IoT '
        'com esse identificador.',
      );
    }

    await colecao.doc(id).update({
      'nome': nomeValidado,
      'identificador': identificadorValidado,
      'tipo': tipoValidado,
      'ambienteId': ambienteValidado,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Ligar e desligar: lâmpadas SmartLight recebem o comando pelo MQTT;
  // os demais dispositivos só têm o estado salvo no Firestore.
  static Future<void> ligarOuDesligar(
    DispositivoIot dispositivo,
    bool ligado,
  ) async {
    if (dispositivo.usaMqtt) {
      ServicoMqtt.instancia.publicarComando(
        dispositivo.identificador,
        EstadoLampada.comando(ligado: ligado),
      );
      return;
    }
    await alterarEstado(id: dispositivo.id, ligado: ligado);
  }

  // Ligar e desligar dispositivo no Firestore
  static Future<void> alterarEstado({
    required String id,
    required bool ligado,
  }) async {
    await _colecaoDoUsuario().doc(id).update({
      'ligado': ligado,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Atualizar status de conexão
  static Future<void> atualizarStatusConexao({
    required String id,
    required String status,
  }) async {
    const statusPermitidos = {'desconhecido', 'conectado', 'desconectado'};

    if (!statusPermitidos.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Status de conexão inválido.',
      );
    }

    final agora = FieldValue.serverTimestamp();

    final atualizacao = <String, Object?>{
      'statusConexao': status,
      'atualizadoEm': agora,
    };

    if (status == 'conectado') {
      atualizacao['ultimaConexaoEm'] = agora;
    }

    await _colecaoDoUsuario().doc(id).update(atualizacao);
  }

  // Excluir dispositivo
  static Future<void> excluir(String id) async {
    await _colecaoDoUsuario().doc(id).delete();
  }

  // Validar campos
  static String _validarTexto(String valor, String campo, int tamanhoMaximo) {
    final texto = valor.trim();

    if (texto.isEmpty || texto.length > tamanhoMaximo) {
      throw ArgumentError.value(
        valor,
        campo,
        'Informe um valor entre 1 '
        'e $tamanhoMaximo caracteres.',
      );
    }

    return texto;
  }
}
