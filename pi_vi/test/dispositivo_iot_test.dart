import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_vi/models/dispositivo_iot.dart';

void main() {
  test('converte os dados do Firestore em um dispositivo IoT', () {
    final criadoEm = DateTime.utc(2026, 10, 27);
    final dispositivo = DispositivoIot.fromFirestore('device-1', {
      'nome': 'Lâmpada da sala',
      'identificador': 'LAMPADA-SALA-01',
      'tipo': 'lâmpada',
      'ambienteId': 'sala',
      'statusConexao': 'desconectado',
      'ultimaConexaoEm': null,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'atualizadoEm': Timestamp.fromDate(criadoEm),
    });

    expect(dispositivo.id, 'device-1');
    expect(dispositivo.nome, 'Lâmpada da sala');
    expect(dispositivo.identificador, 'LAMPADA-SALA-01');
    expect(dispositivo.ambienteId, 'sala');
    expect(dispositivo.statusConexao, 'desconectado');
    expect(dispositivo.ultimaConexaoEm, isNull);
    expect(dispositivo.criadoEm.toUtc(), criadoEm);
  });

  test('rejeita data inválida recebida do Firestore', () {
    expect(
      () => DispositivoIot.fromFirestore('device-1', {
        'nome': 'Lâmpada',
        'identificador': 'TOMADA-01',
        'tipo': 'lâmpada',
        'ambienteId': null,
        'statusConexao': 'desconhecido',
        'ultimaConexaoEm': null,
        'criadoEm': 'inválido',
        'atualizadoEm': Timestamp.now(),
      }),
      throwsFormatException,
    );
  });
}
