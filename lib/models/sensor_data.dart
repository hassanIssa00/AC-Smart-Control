import 'package:flutter/foundation.dart';

enum WaterLevel { normal, warning, critical }
enum FreonStatus { optimal, lowRefrigerant, evaluating, standby }
enum CompressorHealth { normal, lockedRotorOverload, idle }
enum FanHealth { normal, overcurrent, stopped }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final WaterLevel waterLevel;
  final bool acState;
  final double currentDraw;
  final String note;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
    required this.acState,
    this.currentDraw = 0.0,
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

  // Electrical Current Draw Telemetry (Amperes)
  double _compressorCurrent = 0.0;
  double _indoorFanCurrent = 0.0;
  double _outdoorFanCurrent = 0.0;
  double _returnTemperature = 26.5; // Room Return Air Temp

  // Active Alert Notification state
  bool _hasActiveAlert = false;
  String _lastAlertMessage = '';
  DateTime? _lastAlertTime;
  DateTime? _lastTempAlertTime;
  DateTime? _lastHumidityAlertTime;
  DateTime? _lastFreonAlertTime;
  DateTime? _lastFanAlertTime;

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

  // Electrical & Diagnostics Getters
  double get compressorCurrent => _compressorCurrent;
  double get indoorFanCurrent => _indoorFanCurrent;
  double get outdoorFanCurrent => _outdoorFanCurrent;
  double get returnTemperature => _returnTemperature;
  double get totalCurrent => _compressorCurrent + _indoorFanCurrent + _outdoorFanCurrent;
  double get deltaT => (_returnTemperature > _temperature && _temperature > 0.0)
      ? (_returnTemperature - _temperature)
      : 0.0;

  FreonStatus get freonStatus {
    if (!_isConnected || !_acOn) return FreonStatus.standby;
    if (_compressorCurrent > 0.4 && _compressorCurrent < 3.2 && deltaT < 7.0) {
      return FreonStatus.lowRefrigerant;
    }
    if (_compressorCurrent >= 3.2) {
      return FreonStatus.optimal;
    }
    return FreonStatus.evaluating;
  }

  CompressorHealth get compressorHealth {
    if (!_isConnected || !_acOn) return CompressorHealth.idle;
    if (_compressorCurrent > 8.0) {
      return CompressorHealth.lockedRotorOverload;
    }
    return CompressorHealth.normal;
  }

  FanHealth get indoorFanHealth {
    if (!_isConnected || !_acOn) return FanHealth.normal;
    if (_indoorFanCurrent > 0.75) return FanHealth.overcurrent;
    if (_indoorFanCurrent < 0.05 && _acOn) return FanHealth.stopped;
    return FanHealth.normal;
  }

  FanHealth get outdoorFanHealth {
    if (!_isConnected || !_acOn) return FanHealth.normal;
    if (_outdoorFanCurrent > 1.35) return FanHealth.overcurrent;
    if (_outdoorFanCurrent < 0.05 && _acOn) return FanHealth.stopped;
    return FanHealth.normal;
  }

  int get systemHealthIndex {
    if (!_isConnected) return 100;
    int score = 100;
    if (_waterLevel == WaterLevel.critical) {
      score -= 50;
    } else if (_waterLevel == WaterLevel.warning) {
      score -= 20;
    }

    if (compressorHealth == CompressorHealth.lockedRotorOverload) score -= 40;
    if (freonStatus == FreonStatus.lowRefrigerant) score -= 25;
    if (indoorFanHealth != FanHealth.normal) score -= 15;
    if (outdoorFanHealth != FanHealth.normal) score -= 15;

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
      currentDraw: totalCurrent,
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
      _compressorCurrent = 0.0;
      _indoorFanCurrent = 0.0;
      _outdoorFanCurrent = 0.0;
      _acOn = false;
      _relayOn = false;
      addLog('Bluetooth disconnected');
    }
    notifyListeners();
  }

  // ─── Electrical Current Updates (from BT telemetry stream) ─────────────────

  void updateElectrical({
    double? compressor,
    double? fanIn,
    double? fanOut,
    double? returnTemp,
  }) {
    if (compressor != null) _compressorCurrent = compressor;
    if (fanIn != null) _indoorFanCurrent = fanIn;
    if (fanOut != null) _outdoorFanCurrent = fanOut;
    if (returnTemp != null) _returnTemperature = returnTemp;

    // Check for critical electrical overload fault (Locked Rotor / Bad Capacitor)
    final now = DateTime.now();
    if (_compressorCurrent > 8.0 && _acOn) {
      _hasActiveAlert = true;
      _lastAlertMessage = 'CRITICAL OVERLOAD: Compressor current exceeded 8.0A (${_compressorCurrent.toStringAsFixed(1)}A)! Potential locked rotor.';
      _lastAlertTime = now;
      addLog('CRITICAL: Compressor overcurrent (${_compressorCurrent.toStringAsFixed(1)}A)');
    } else if (_compressorCurrent < 3.2 && _compressorCurrent > 0.4 && deltaT < 7.0 && _acOn) {
      if (_lastFreonAlertTime == null || now.difference(_lastFreonAlertTime!).inSeconds > 25) {
        _hasActiveAlert = true;
        _lastAlertMessage = 'WARNING: Refrigerant underload detected (${_compressorCurrent.toStringAsFixed(1)}A, ΔT: ${deltaT.toStringAsFixed(1)}°C)! Potential Freon leak.';
        _lastAlertTime = now;
        _lastFreonAlertTime = now;
        addLog('WARNING: Freon leak underload (${_compressorCurrent.toStringAsFixed(1)}A, ΔT: ${deltaT.toStringAsFixed(1)}°C)');
      }
    } else if (_indoorFanCurrent > 0.75 && _acOn) {
      if (_lastFanAlertTime == null || now.difference(_lastFanAlertTime!).inSeconds > 20) {
        _hasActiveAlert = true;
        _lastAlertMessage = 'WARNING: Indoor Blower Fan Overcurrent (${_indoorFanCurrent.toStringAsFixed(2)}A)! Inspect motor bearings.';
        _lastAlertTime = now;
        _lastFanAlertTime = now;
        addLog('WARNING: Indoor blower overload (${_indoorFanCurrent.toStringAsFixed(2)}A)');
      }
    } else if (_outdoorFanCurrent < 0.05 && _acOn) {
      if (_lastFanAlertTime == null || now.difference(_lastFanAlertTime!).inSeconds > 20) {
        _hasActiveAlert = true;
        _lastAlertMessage = 'CRITICAL: Outdoor Condenser Fan Stalled (0.0A)! Risk of severe head pressure buildup.';
        _lastAlertTime = now;
        _lastFanAlertTime = now;
        addLog('CRITICAL: Outdoor condenser fan stalled (0.0A)');
      }
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

  /// Scenario injector for evaluations, defenses, and lab demonstrations.
  void simulateDiagnosticScenario(String scenario) {
    _isConnected = true;
    _connectedDevice = 'ESP32_HVAC_DEMO';
    _acOn = true;
    _relayOn = true;
    _waterLevel = WaterLevel.normal;
    _returnTemperature = 26.5;

    if (scenario == 'NORMAL') {
      _temperature = 14.5;
      _compressorCurrent = 5.4;
      _indoorFanCurrent = 0.38;
      _outdoorFanCurrent = 0.85;
      _hasActiveAlert = false;
      _systemStatus = 'AC Running — Optimal Condition';
      addLog('DEMO: Injected Normal Operation State (5.4A, ΔT=12.0°C)');
    } else if (scenario == 'LOW_FREON') {
      _temperature = 22.0;
      _compressorCurrent = 2.1;
      _indoorFanCurrent = 0.38;
      _outdoorFanCurrent = 0.85;
      _hasActiveAlert = true;
      _lastAlertMessage = 'WARNING: Refrigerant underload detected (2.1A, ΔT=4.5°C). Potential Freon leak!';
      _lastAlertTime = DateTime.now();
      _systemStatus = 'WARNING — Low Freon / Refrigerant Leak';
      addLog('DEMO: Injected Low Freon Leak State (2.1A, ΔT=4.5°C)');
    } else if (scenario == 'OVERLOAD') {
      _temperature = 18.0;
      _compressorCurrent = 9.6;
      _indoorFanCurrent = 0.42;
      _outdoorFanCurrent = 0.88;
      _hasActiveAlert = true;
      _lastAlertMessage = 'CRITICAL OVERLOAD: Compressor current 9.6A exceeded limit! Locked rotor / bad capacitor.';
      _lastAlertTime = DateTime.now();
      _systemStatus = 'CRITICAL — Compressor Locked Rotor';
      addLog('DEMO: Injected Overload Locked Rotor State (9.6A)');
    } else if (scenario == 'FAN_FAULT') {
      _temperature = 19.5;
      _compressorCurrent = 5.2;
      _indoorFanCurrent = 0.95;
      _outdoorFanCurrent = 0.0;
      _hasActiveAlert = true;
      _lastAlertMessage = 'WARNING: Outdoor fan stopped (0.0A) & indoor blower overload (0.95A)!';
      _lastAlertTime = DateTime.now();
      _systemStatus = 'WARNING — Fan Motor Failure';
      addLog('DEMO: Injected Fan Failure & Seizure State');
    }
    notifyListeners();
  }
}
