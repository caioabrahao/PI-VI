import 'package:flutter/foundation.dart';

enum AlertaTipo { dispositivo, energia, rotina, atualizacao, membro }

class Alerta {
  final String id;
  final String titulo;
  final String descricao;
  final AlertaTipo tipo;
  final bool critico;
  final DateTime criadoEm;

  const Alerta({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    this.critico = false,
    required this.criadoEm,
  });
}

class AlertasData extends ChangeNotifier {
  AlertasData({required List<Alerta> alertas}) : _alertas = List.of(alertas);

  List<Alerta> _alertas;
  bool _somenteNaoLidas = false;
  final Set<String> _lidas = {};

  List<Alerta> get alertas => List.unmodifiable(_alertas);

  bool get somenteNaoLidas => _somenteNaoLidas;
  set somenteNaoLidas(bool valor) {
    if (_somenteNaoLidas == valor) return;
    _somenteNaoLidas = valor;
    notifyListeners();
  }

  int get naoLidas => _alertas.where((a) => !_lidas.contains(a.id)).length;

  int get criticas => _alertas.where((a) => a.critico).length;

  bool estaLida(Alerta alerta) => _lidas.contains(alerta.id);

  void marcarLida(Alerta alerta) {
    if (_lidas.add(alerta.id)) notifyListeners();
  }

  void marcarTodasLidas() {
    var mudou = false;
    for (final a in _alertas) {
      mudou = _lidas.add(a.id) || mudou;
    }
    if (mudou) notifyListeners();
  }

  /// Usado caso a tela queira atualizar a lista em tempo real.
  void substituirAlertas(List<Alerta> novos) {
    _alertas = List.of(novos);
    notifyListeners();
  }
}
