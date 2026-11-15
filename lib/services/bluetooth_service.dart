import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import '../models/sensor_data.dart';

/// Standard SPP (Serial Port Profile) UUID for ESP32 BluetoothSerial.
/// Without this, some Android devices fail to connect.
const String _sppUuid = '00001101-0000-1000-8000-00805F9B34FB';

/// Maximum buffer size to prevent memory leak if ESP32 stops sending '\n'
const int _maxBufferLength = 512;

class BluetoothService extends ChangeNotifier {
  final FlutterBlueClassic _fbc = FlutterBlueClassic();
  BluetoothConnection? _connection;
  final SensorData sensorData;

  bool _isScanning = false;
  List<BluetoothDevice> _devices = [];
  String _statusMessage = 'Ready to scan';
  bool _isConnecting = false;
  bool _autoReconnecting = false;

  StreamSubscription? _dataSubscription;
  StreamSubscription? _scanSubscription;
  String _buffer = '';

  // Reconnect tracking
  BluetoothDevice? _lastDevice;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 2;

  BluetoothService({required this.sensorData});

  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connection != null;
  bool get autoReconnecting => _autoReconnecting;
  List<BluetoothDevice> get devices => _devices;
  String get statusMessage => _statusMessage;

  // ─── Scan ────────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    _isScanning = true;
    _devices = [];
    _statusMessage = 'Scanning for devices...';
    notifyListeners();

    try {
      // Show bonded (paired) devices first
      final bonded = await _fbc.bondedDevices ?? [];
      for (final d in bonded) {
        if (!_devices.any((x) => x.address == d.address)) {
          _devices.add(d);
        }
      }
      _statusMessage = _devices.isEmpty
          ? 'Looking for nearby devices...'
          : 'Found ${_devices.length} paired device(s). Scanning for more...';
      notifyListeners();

      // Also run active scan for discoverable devices (de-duplicated)
      _scanSubscription?.cancel();
      _scanSubscription = _fbc.scanResults.listen((device) {
        if (!_devices.any((d) => d.address == device.address)) {
          _devices.add(device);
          notifyListeners();
        }
      });
      _fbc.startScan();

      // Auto-stop scan after 6 seconds
      Future.delayed(const Duration(seconds: 6), () {
        _stopScan();
      });
    } catch (e) {
      _statusMessage = 'Scan error: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  void _stopScan() {
    try {
      _fbc.stopScan();
    } catch (_) {}
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    _statusMessage = _devices.isEmpty
        ? 'No devices found. Make sure ESP32 is paired.'
        : 'Found ${_devices.length} device(s)';
    notifyListeners();
  }

  // ─── Connect ─────────────────────────────────────────────────────────────

  Future<void> connectTo(BluetoothDevice device) async {
    if (_isConnecting) return;
    _isConnecting = true;
    _reconnectAttempts = 0;
    _lastDevice = device;
    _statusMessage = 'Connecting to ${device.name ?? device.address}...';
    notifyListeners();

    await _doConnect(device);
    _isConnecting = false;
    notifyListeners();
  }

  Future<void> _doConnect(BluetoothDevice device) async {
    try {
      // Use SPP UUID for reliable ESP32 connection on all Android versions
      _connection = await _fbc.connect(device.address, uuid: _sppUuid);

      if (_connection != null) {
        _autoReconnecting = false;
        _reconnectAttempts = 0;
        sensorData.setConnected(true, device: device.name ?? device.address);
        _statusMessage = 'Connected to ${device.name ?? device.address}';
        _listenToData();
      } else {
        _statusMessage = 'Connection failed — no response from device';
        sensorData.setConnected(false);
      }
    } catch (e) {
      _statusMessage = 'Connection error: ${_friendlyError(e)}';
      sensorData.setConnected(false);
      debugPrint('[BT] Connect error: $e');
    }
  }

  // ─── Data Listener ───────────────────────────────────────────────────────

  void _listenToData() {
    _dataSubscription?.cancel();
    _buffer = '';

    final inputStream = _connection?.input;
    if (inputStream == null) {
      _statusMessage = 'Warning: No data stream from device';
      sensorData.addLog('BT Warning: Input stream unavailable');
      notifyListeners();
      return;
    }

    _dataSubscription = inputStream.listen(
      (Uint8List data) {
        _buffer += String.fromCharCodes(data);

        // Guard: prevent runaway buffer (e.g. ESP32 not sending '\n')
        if (_buffer.length > _maxBufferLength) {
          debugPrint('[BT] Buffer overflow — flushing');
          final lastNewline = _buffer.lastIndexOf('\n');
          _buffer = lastNewline >= 0 ? _buffer.substring(lastNewline + 1) : '';
        }

        // Process all complete lines
        final lines = _buffer.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty) _parseData(line);
        }
        _buffer = lines.last; // keep incomplete last line
      },
      onDone: () {
        debugPrint('[BT] Stream closed by remote');
        _handleDisconnect(unexpected: true);
      },
      onError: (err) {
        debugPrint('[BT] Stream error: $err');
        _handleDisconnect(unexpected: true);
      },
      cancelOnError: true,
    );
  }

  // ─── Parse ESP32 Data ────────────────────────────────────────────────────

  void _parseData(String line) {
    // Expected: T:25.3,H:60.2,W:0  (W: 0=normal, 1=warning, 2=critical)
    try {
      final parts = line.split(',');
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final key = kv[0].trim().toUpperCase();
          final val = double.tryParse(kv[1].trim());
          if (val == null) continue;
          switch (key) {
            case 'T':
              sensorData.updateTemperature(val);
              break;
            case 'H':
              sensorData.updateHumidity(val);
              break;
            case 'W':
              sensorData.updateWaterLevel(
                val >= 2
                    ? WaterLevel.critical
                    : val >= 1
                        ? WaterLevel.warning
                        : WaterLevel.normal,
              );
              break;
          }
        }
      }
    } catch (e) {
      debugPrint('[BT] Parse error on "$line": $e');
    }
  }

  // ─── Send Command ─────────────────────────────────────────────────────────

  void sendCommand(String cmd) {
    if (!isConnected) {
      _statusMessage = 'Not connected — cannot send command';
      notifyListeners();
      return;
    }
    try {
      _connection!.writeString('$cmd\n');
      debugPrint('[BT] Sent: $cmd');
    } catch (e) {
      _statusMessage = 'Send failed: ${_friendlyError(e)}';
      debugPrint('[BT] Send error: $e');
      notifyListeners();
    }
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _autoReconnecting = false;
    _reconnectAttempts = 0;
    _lastDevice = null;
    await _handleDisconnect(unexpected: false);
  }

  Future<void> _handleDisconnect({required bool unexpected}) async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;

    try {
      _connection?.close();
    } catch (_) {}
    _connection = null;
    _buffer = '';

    if (!unexpected) {
      _statusMessage = 'Disconnected';
      sensorData.setConnected(false);
      notifyListeners();
      return;
    }

    // Unexpected disconnect — try auto-reconnect once
    sensorData.setConnected(false);
    if (_lastDevice != null && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _autoReconnecting = true;
      _statusMessage =
          'Connection lost. Auto-reconnecting ($_reconnectAttempts/$_maxReconnectAttempts)...';
      notifyListeners();

      _reconnectTimer = Timer(const Duration(seconds: 3), () async {
        if (_lastDevice != null) {
          await _doConnect(_lastDevice!);
          _autoReconnecting = false;
          notifyListeners();
        }
      });
    } else {
      _autoReconnecting = false;
      _statusMessage = 'Disconnected — connection lost';
      notifyListeners();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('timeout')) return 'Connection timed out';
    if (s.contains('refused')) return 'Device refused connection';
    if (s.contains('socket')) return 'Socket error — check ESP32 power';
    return e.toString();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    try {
      _fbc.stopScan();
    } catch (_) {}
    try {
      _connection?.close();
    } catch (_) {}
    super.dispose();
  }
}

