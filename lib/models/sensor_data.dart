import 'package:flutter/foundation.dart';

enum WaterLevel { normal, warning, critical }

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

  // Active Alert Notification state
  bool _hasActiveAlert = false;
  String _lastAlertMessage = '';
  DateTime? _lastAlertTime;

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
    notifyListeners();
  }

  void updateHumidity(double val) {
    _humidity = val;
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
