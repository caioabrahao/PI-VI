import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dispositivo_iot.dart';
import 'firebase_service.dart';

class DispositivoIotService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      throw StateError('Já existe um dispositivo IoT com esse identificador.');
    }

    final agora = FieldValue.serverTimestamp();
    final referencia = await colecao.add({
      'uid': uid,
      'nome': nomeValidado,
      'identificador': identificadorValidado,
      'tipo': tipoValidado,
      'ambienteId': ambienteValidado,
      'statusConexao': 'desconhecido',
      'ultimaConexaoEm': null,
      'criadoEm': agora,
      'atualizadoEm': agora,
    });

    final documento = await referencia.get();
    final dados = documento.data();
    if (!documento.exists || dados == null) {
      throw StateError('Não foi possível carregar o dispositivo IoT cadastrado.');
    }

    return DispositivoIot.fromFirestore(documento.id, dados);
  }

  static Stream<List<DispositivoIot>> observarDispositivos() {
    return _colecaoDoUsuario()
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (documento) => DispositivoIot.fromFirestore(
                  documento.id,
                  documento.data(),
                ),
              )
              .toList(growable: false),
        );
  }

  static Future<DispositivoIot?> obter(String id) async {
    final documento = await _colecaoDoUsuario().doc(id).get();
    final dados = documento.data();
    if (!documento.exists || dados == null) return null;
    return DispositivoIot.fromFirestore(documento.id, dados);
  }

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
      throw StateError('Já existe um dispositivo IoT com esse identificador.');
    }

    await colecao.doc(id).update({
      'nome': nomeValidado,
      'identificador': identificadorValidado,
      'tipo': tipoValidado,
      'ambienteId': ambienteValidado,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> atualizarStatusConexao({
    required String id,
    required String status,
  }) async {
    const statusPermitidos = {'desconhecido', 'conectado', 'desconectado'};
    if (!statusPermitidos.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Status de conexão inválido.');
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

  static Future<void> excluir(String id) async {
    await _colecaoDoUsuario().doc(id).delete();
  }

  static String _validarTexto(String valor, String campo, int tamanhoMaximo) {
    final texto = valor.trim();
    if (texto.isEmpty || texto.length > tamanhoMaximo) {
      throw ArgumentError.value(
        valor,
        campo,
        'Informe um valor entre 1 e $tamanhoMaximo caracteres.',
      );
    }
    return texto;
  }
}
