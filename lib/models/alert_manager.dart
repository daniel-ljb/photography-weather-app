import 'alert.dart';

class AlertManager {
  static final AlertManager _instance = AlertManager._internal();
  factory AlertManager() => _instance;
  AlertManager._internal();

  final List<Alert> _alerts = [];

  List<Alert> get alerts => List.unmodifiable(_alerts);

  void addAlert(Alert alert) {
    _alerts.add(alert);
  }

  void removeAlert(int index) {
    _alerts.removeAt(index);
  }

  void updateAlert(int index, Alert alert) {
    _alerts[index] = alert;
  }
}
