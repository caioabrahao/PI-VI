import 'package:cloud_firestore/cloud_firestore.dart';

class DispositivoIot {
  final String id;
  final String nome;
  final String identificador;
  final String tipo;
  final String? ambienteId;
  final String statusConexao;
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
    required this.ultimaConexaoEm,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory DispositivoIot.fromFirestore(
    String id,
    Map<String, dynamic> dados,
  ) {
    return DispositivoIot(
      id: id,
      nome: dados['nome'] as String,
      identificador: dados['identificador'] as String,
      tipo: dados['tipo'] as String,
      ambienteId: dados['ambienteId'] as String?,
      statusConexao: dados['statusConexao'] as String,
      ultimaConexaoEm: _lerData(dados['ultimaConexaoEm']),
      criadoEm: _lerData(dados['criadoEm'])!,
      atualizadoEm: _lerData(dados['atualizadoEm'])!,
    );
  }

  static DateTime? _lerData(Object? valor) {
    if (valor == null) return null;
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    throw FormatException('Data inválida no cadastro do dispositivo.');
  }
}
