import 'package:flutter/foundation.dart';

enum WaterLevel { normal, warning, critical }
enum FreonStatus { optimal, lowRefrigerant, evaluating, standby }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final WaterLevel waterLevel;
  final bool acState;
  final String note;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
    required this.acState,
    required this.note,
  });

  String get waterLevelLabel {
    switch (waterLevel) {
      case WaterLevel.normal:
        return 'Normal';
      case WaterLevel.warning:
        return 'Warning';
      case WaterLevel.critical:
        return 'Critical';
    }
  }
}

class SensorData extends ChangeNotifier {
  double _temperature = 0.0;
  double _humidity = 0.0;
  WaterLevel _waterLevel = WaterLevel.normal;
  bool _acOn = false;
  bool _relayOn = false;
  bool _isConnected = false;
  String _connectedDevice = '';
  String _systemStatus = 'Offline — Connect Bluetooth';

  // Thermodynamic Telemetry
  double _returnTemperature = 26.5; // Room Return Air Temp

  // Active Alert Notification state
  bool _hasActiveAlert = false;
  String _lastAlertMessage = '';
  DateTime? _lastAlertTime;
  DateTime? _lastTempAlertTime;
  DateTime? _lastHumidityAlertTime;

  final List<LogEntry> _logs = [];
  int _logCounter = 0;

  SensorData();

  // ─── Getters ─────────────────────────────────────────────────────────────

  double get temperature => _temperature;
  double get humidity => _humidity;
  WaterLevel get waterLevel => _waterLevel;
  bool get acOn => _acOn;
  bool get relayOn => _relayOn;
  bool get isConnected => _isConnected;
  String get connectedDevice => _connectedDevice;
  String get systemStatus => _systemStatus;
  bool get hasActiveAlert => _hasActiveAlert;
  String get lastAlertMessage => _lastAlertMessage;
  DateTime? get lastAlertTime => _lastAlertTime;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  bool get hasRealTelemetry => _isConnected && (_temperature > 0.0 || _humidity > 0.0);

  // Thermodynamics & Diagnostics Getters
  double get returnTemperature => _returnTemperature;
  double get deltaT => (_returnTemperature > _temperature && _temperature > 0.0)
      ? (_returnTemperature - _temperature)
      : 0.0;

  FreonStatus get freonStatus {
    if (!_isConnected || !_acOn) return FreonStatus.standby;
    if (deltaT < 7.0 && deltaT > 0.0) {
      return FreonStatus.lowRefrigerant;
    }
    if (deltaT >= 7.0) {
      return FreonStatus.optimal;
    }
    return FreonStatus.evaluating;
  }

  int get systemHealthIndex {
    if (!_isConnected) return 100;
    int score = 100;
    if (_waterLevel == WaterLevel.critical) {
      score -= 50;
    } else if (_waterLevel == WaterLevel.warning) {
      score -= 20;
    }

    if (freonStatus == FreonStatus.lowRefrigerant) score -= 30;
    if (_temperature > 32.0 && _acOn) score -= 20;

    return score.clamp(5, 100);
  }

  String get waterLevelLabel {
    switch (_waterLevel) {
      case WaterLevel.normal:
        return 'Normal';
      case WaterLevel.warning:
        return 'Warning';
      case WaterLevel.critical:
        return 'Critical';
    }
  }

  void dismissAlert() {
    _hasActiveAlert = false;
    notifyListeners();
  }

  bool get canControlAC => _isConnected && _waterLevel != WaterLevel.critical;

  String _nextId() {
    _logCounter++;
    return 'LOG-${_logCounter.toString().padLeft(4, '0')}';
  }

  // ─── Log management ───────────────────────────────────────────────────────

  void addLog(String note) {
    final entry = LogEntry(
      id: _nextId(),
      timestamp: DateTime.now(),
      temperature: _temperature,
      humidity: _humidity,
      waterLevel: _waterLevel,
      acState: _acOn,
      note: note,
    );
    _logs.insert(0, entry);
    if (_logs.length > 500) _logs.removeLast();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // ─── Sensor updates (from BT telemetry stream) ───────────────────────────

  void updateTemperature(double val) {
    if ((_temperature - val).abs() > 0.4 && _temperature > 0.0) {
      addLog('Temperature: ${val.toStringAsFixed(1)}°C');
    }
    _temperature = val;

    // Abnormal Temperature Alerts
    final now = DateTime.now();
    if (_acOn && val > 32.0) {
      if (_lastTempAlertTime == null || now.difference(_lastTempAlertTime!).inSeconds > 25) {
        _hasActiveAlert = true;
        _lastAlertMessage = 'WARNING: High Supply Air Temperature (${val.toStringAsFixed(1)}°C) detected while AC is running! Check cooling loop.';
        _lastAlertTime = now;
        _lastTempAlertTime = now;
        addLog('ALERT: High supply air temp (${val.toStringAsFixed(1)}°C)');
      }
    } else if (_acOn && val < 4.0 && val > 0.0) {
      if (_lastTempAlertTime == null || now.difference(_lastTempAlertTime!).inSeconds > 25) {
        _hasActiveAlert = true;
        _lastAlertMessage = 'WARNING: Evaporator coil freeze-up risk (${val.toStringAsFixed(1)}°C)! Potential ice formation.';
        _lastAlertTime = now;
        _lastTempAlertTime = now;
        addLog('ALERT: Low freezing temp (${val.toStringAsFixed(1)}°C)');
      }
    }
    notifyListeners();
  }

  void updateHumidity(double val) {
    _humidity = val;
    final now = DateTime.now();
    if (val > 80.0) {
      if (_lastHumidityAlertTime == null || now.difference(_lastHumidityAlertTime!).inSeconds > 30) {
        _hasActiveAlert = true;
        _lastAlertMessage = 'WARNING: Excessively high humidity (${val.toStringAsFixed(1)}%)! Elevated condensate drip and mold formation risk.';
        _lastAlertTime = now;
        _lastHumidityAlertTime = now;
        addLog('ALERT: Extreme humidity (${val.toStringAsFixed(1)}%)');
      }
    }
    notifyListeners();
  }

  void updateWaterLevel(WaterLevel level) {
    final oldLevel = _waterLevel;
    _waterLevel = level;
    if (level == WaterLevel.critical) {
      _hasActiveAlert = true;
      _lastAlertMessage = 'EMERGENCY: Water leakage detected! AC automatically stopped to prevent damage.';
      _lastAlertTime = DateTime.now();
      if (_acOn) {
        _acOn = false;
        _relayOn = false;
        _systemStatus = 'AC OFF – Water Leakage Emergency!';
        addLog('EMERGENCY SHUTDOWN: Critical water leakage detected! AC automatically stopped.');
      } else {
        _systemStatus = 'LOCKED – Water Leakage Emergency';
        addLog('WARNING: Critical water level detected. AC control locked.');
      }
    } else if (level == WaterLevel.warning && oldLevel != WaterLevel.warning) {
      _hasActiveAlert = true;
      _lastAlertMessage = 'WARNING: Water reservoir rising above 50%. Drain soon.';
      _lastAlertTime = DateTime.now();
      addLog('Water reservoir warning: Level at 50-80% capacity.');
    } else if (level == WaterLevel.normal && oldLevel != WaterLevel.normal) {
      _hasActiveAlert = false;
      addLog('Water reservoir safe: Normal level restored.');
    }
    notifyListeners();
  }

  // ─── Connection ───────────────────────────────────────────────────────────

  void setConnected(bool val, {String device = ''}) {
    _isConnected = val;
    _connectedDevice = device;
    if (val) {
      _systemStatus = 'Connected to $device';
      addLog('Bluetooth connected to $device');
    } else {
      _systemStatus = 'Offline — Connect Bluetooth';
      _temperature = 0.0;
      _humidity = 0.0;
      _acOn = false;
      _relayOn = false;
      addLog('Bluetooth disconnected');
    }
    notifyListeners();
  }

  void updateReturnTemperature(double val) {
    _returnTemperature = val;
    notifyListeners();
  }

  // ─── AC control ───────────────────────────────────────────────────────────

  void toggleAC() {
    if (!canControlAC) return;
    _acOn = !_acOn;
    _relayOn = _acOn;
    _systemStatus = _acOn ? 'AC Running' : 'AC Stopped';
    addLog(_acOn ? 'AC started manually via app' : 'AC stopped manually via app');
    notifyListeners();
  }

  void turnACOn() {
    if (!canControlAC) return;
    _acOn = true;
    _relayOn = true;
    _systemStatus = 'AC Running';
    addLog('AC turned ON (Relay energized)');
    notifyListeners();
  }

  void turnACOff() {
    if (!_isConnected) return;
    _acOn = false;
    _relayOn = false;
    _systemStatus = 'AC Stopped';
    addLog('AC turned OFF (Relay cut off)');
    notifyListeners();
  }
}
