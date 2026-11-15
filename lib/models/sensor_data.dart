import 'dart:async';
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
  double _temperature = 24.5;
  double _humidity = 58.0;
  WaterLevel _waterLevel = WaterLevel.normal;
  bool _acOn = false;
  bool _relayOn = false;
  bool _isConnected = false;
  String _connectedDevice = '';
  String _systemStatus = 'Idle';

  // Active Alert Notification state
  bool _hasActiveAlert = false;
  String _lastAlertMessage = '';
  DateTime? _lastAlertTime;

  // Demo simulation mode (works without real hardware)
  bool _simulationMode = false;
  Timer? _simTimer;

  final List<LogEntry> _logs = [];
  int _logCounter = 0;

  SensorData() {
    _seedInitialLogs();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────

  double get temperature => _temperature;
  double get humidity => _humidity;
  WaterLevel get waterLevel => _waterLevel;
  bool get acOn => _acOn;
  bool get relayOn => _relayOn;
  bool get isConnected => _isConnected;
  String get connectedDevice => _connectedDevice;
  String get systemStatus => _systemStatus;
  bool get simulationMode => _simulationMode;
  bool get hasActiveAlert => _hasActiveAlert;
  String get lastAlertMessage => _lastAlertMessage;
  DateTime? get lastAlertTime => _lastAlertTime;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void dismissAlert() {
    _hasActiveAlert = false;
    notifyListeners();
  }

  void triggerTestAlert() {
    _hasActiveAlert = true;
    _lastAlertMessage = '⚠️ CRITICAL LEAKAGE DETECTED! Water tank overflowing. AC auto-disabled for safety.';
    _lastAlertTime = DateTime.now();
    updateWaterLevel(WaterLevel.critical);
    notifyListeners();
  }

  bool get canControlAC => _waterLevel != WaterLevel.critical;

  // ─── Seed logs ────────────────────────────────────────────────────────────

  void _seedInitialLogs() {
    final now = DateTime.now();
    final seeds = [
      LogEntry(
        id: _nextId(),
        timestamp: now.subtract(const Duration(minutes: 35)),
        temperature: 26.2,
        humidity: 62.0,
        waterLevel: WaterLevel.normal,
        acState: false,
        note: 'System booted & calibrated by Eng. Mahmoud Zayed',
      ),
      LogEntry(
        id: _nextId(),
        timestamp: now.subtract(const Duration(minutes: 28)),
        temperature: 25.8,
        humidity: 60.5,
        waterLevel: WaterLevel.normal,
        acState: true,
        note: 'AC turned ON (Comfort Mode set to 24°C)',
      ),
      LogEntry(
        id: _nextId(),
        timestamp: now.subtract(const Duration(minutes: 18)),
        temperature: 25.1,
        humidity: 59.0,
        waterLevel: WaterLevel.warning,
        acState: true,
        note: 'Tank Warning: Condensation water rising above 50%',
      ),
      LogEntry(
        id: _nextId(),
        timestamp: now.subtract(const Duration(minutes: 8)),
        temperature: 24.5,
        humidity: 58.0,
        waterLevel: WaterLevel.normal,
        acState: true,
        note: 'Water drained successfully. Normal telemetry restored.',
      ),
    ];
    _logs.addAll(seeds.reversed); // newest first
  }

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
    // Cap at 500 entries to avoid memory growth
    if (_logs.length > 500) _logs.removeLast();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // ─── Sensor updates (from BT) ─────────────────────────────────────────────

  void updateTemperature(double val) {
    if ((_temperature - val).abs() > 0.4) {
      addLog('Temperature reading: ${val.toStringAsFixed(1)}°C');
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
      _lastAlertMessage = 'EMERGENCY: Water leakage / high level! AC auto-disabled to prevent damage.';
      _lastAlertTime = DateTime.now();
      if (_acOn) {
        _acOn = false;
        _relayOn = false;
        _systemStatus = 'AC OFF – Water Leakage Emergency!';
        addLog(
            'EMERGENCY SHUTDOWN: Critical water leakage detected! AC automatically stopped.');
      } else {
        _systemStatus = 'LOCKED – Water Leakage Detected';
        addLog('WARNING: Critical water level detected. AC control locked.');
      }
    } else if (level == WaterLevel.warning && oldLevel != WaterLevel.warning) {
      _hasActiveAlert = true;
      _lastAlertMessage = 'WARNING: Water tank rising above 50%. Drain soon.';
      _lastAlertTime = DateTime.now();
      addLog('Water tank warning: Level at 50-80% capacity.');
    } else if (level == WaterLevel.normal && oldLevel != WaterLevel.normal) {
      _hasActiveAlert = false;
      addLog('Water tank normal: System safe.');
    }
    notifyListeners();
  }

  // ─── Connection ───────────────────────────────────────────────────────────

  void setConnected(bool val, {String device = ''}) {
    _isConnected = val;
    _connectedDevice = device;
    _systemStatus = val ? 'Connected to $device' : 'Disconnected';
    if (!val) {
      _acOn = false;
      _relayOn = false;
    }
    addLog(val
        ? 'Bluetooth connected to $device'
        : 'Bluetooth disconnected');
    notifyListeners();
  }

  // ─── AC control ───────────────────────────────────────────────────────────

  void toggleAC() {
    if (!canControlAC) return;
    _acOn = !_acOn;
    _relayOn = _acOn;
    _systemStatus = _acOn ? 'AC Running' : 'AC Stopped';
    addLog(_acOn
        ? 'AC started manually via app'
        : 'AC stopped manually via app');
    notifyListeners();
  }

  void turnACOn() {
    if (!canControlAC) return;
    _acOn = true;
    _relayOn = true;
    _systemStatus = 'AC Running';
    addLog('AC turned ON (Relay triggered)');
    notifyListeners();
  }

  void turnACOff() {
    _acOn = false;
    _relayOn = false;
    _systemStatus = 'AC Stopped';
    addLog('AC turned OFF (Relay cut off)');
    notifyListeners();
  }

  // ─── Simulation mode (works without real hardware) ────────────────────────

  void toggleSimulationMode() {
    _simulationMode = !_simulationMode;
    if (_simulationMode) {
      addLog('Demo mode activated — using simulated sensor data');
      _startSimTimer();
    } else {
      _simTimer?.cancel();
      _simTimer = null;
      addLog('Demo mode deactivated');
    }
    notifyListeners();
  }

  void _startSimTimer() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_simulationMode) {
        _simTimer?.cancel();
        return;
      }
      simulateData();
    });
  }

  void simulateData() {
    final t = DateTime.now();
    _temperature = 22.0 + (t.second % 10) * 0.5;
    _humidity = 50.0 + (t.second % 12) * 0.9;
    // Periodic log every ~30 seconds in simulation
    if (t.second % 30 == 0) {
      addLog(
          'Sim telemetry: T=${_temperature.toStringAsFixed(1)}°C H=${_humidity.toStringAsFixed(1)}%');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }
}
