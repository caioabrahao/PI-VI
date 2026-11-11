import 'package:cloud_firestore/cloud_firestore.dart';

class DispositivoIot {
  final String id;
  final String nome;
  final String identificador;
  final String tipo;
  final String? ambienteId;
  final String statusConexao;
  final bool ligado;
  final DateTime? ultimaConexaoEm;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const DispositivoIot({
    required this.id,
    required this.nome,
    required this.identificador,
    required this.tipo,
    required this.ambienteId,
    required this.statusConexao,
    this.ligado = false,
    required this.ultimaConexaoEm,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  /// Prefixo dos identificadores gerados pelo próprio app para
  /// dispositivos que ainda não têm hardware de verdade.
  static const String prefixoIdentificadorLocal = 'app-';

  bool get ehLampada {
    final t = tipo.toLowerCase();
    return t.contains('lâmpada') || t.contains('lampada') || t.contains('luz');
  }

  /// Lâmpadas com identificador real (ex.: `raphael-01` ou `sl-a1b2c3d4e5f6`)
  /// são controladas pelo MQTT. As demais continuam só no Firestore.
  bool get usaMqtt =>
      ehLampada && !identificador.startsWith(prefixoIdentificadorLocal);

  DispositivoIot copyWith({bool? ligado, String? statusConexao}) {
    return DispositivoIot(
      id: id,
      nome: nome,
      identificador: identificador,
      tipo: tipo,
      ambienteId: ambienteId,
      statusConexao: statusConexao ?? this.statusConexao,
      ligado: ligado ?? this.ligado,
      ultimaConexaoEm: ultimaConexaoEm,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm,
    );
  }

  factory DispositivoIot.fromFirestore(String id, Map<String, dynamic> dados) {
    return DispositivoIot(
      id: id,
      nome: dados['nome'] as String,
      identificador: dados['identificador'] as String,
      tipo: dados['tipo'] as String,
      ambienteId: dados['ambienteId'] as String?,
      statusConexao: dados['statusConexao'] as String? ?? 'desconhecido',
      ligado: dados['ligado'] == true,
      ultimaConexaoEm: _lerData(dados['ultimaConexaoEm']),
      criadoEm:
          _lerData(dados['criadoEm']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      atualizadoEm:
          _lerData(dados['atualizadoEm']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static DateTime? _lerData(Object? valor) {
    if (valor == null) return null;

    if (valor is Timestamp) {
      return valor.toDate();
    }

    if (valor is DateTime) {
      return valor;
    }

    throw FormatException('Data inválida no cadastro do dispositivo.');
  }
}
