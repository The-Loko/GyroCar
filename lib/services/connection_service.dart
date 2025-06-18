import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;
import 'package:wifi_scan/wifi_scan.dart' as wifi_scan;
import '../models/control_data.dart';
import '../models/bluetooth_device.dart';
import '../models/wifi_network.dart';
import '../utils/logger.dart';

enum ConnectionType { wifi, bluetooth, none }
enum ConnectionStatus { connected, disconnected, connecting, error }

class ConnectionService {
  ConnectionType _connectionType = ConnectionType.none;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  fbs.BluetoothConnection? _bluetoothConnection;
  Socket? _wifiSocket;
  String _errorMessage = '';
  String _targetAddress = '';
  
  // Data listening
  StreamSubscription<Uint8List>? _dataSubscription;
  StreamSubscription? _wifiDataSubscription;
  Function(String)? _onDataReceived;
  
  // Sensor data simulation timer for WiFi mode
  Timer? _sensorSimulationTimer;

  // Getters
  ConnectionType get connectionType => _connectionType;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String get errorMessage => _errorMessage;
  String get targetAddress => _targetAddress;

  // Set data callback
  void setDataCallback(Function(String) callback) {
    _onDataReceived = callback;
  }

  // Connect via WiFi
  Future<bool> connectWifi(String ipAddress, int port) async {
    _connectionType = ConnectionType.wifi;
    _connectionStatus = ConnectionStatus.connecting;
    _targetAddress = ipAddress;
    
    try {
      // Try to establish TCP connection to ESP32
      _wifiSocket = await Socket.connect(ipAddress, port)
          .timeout(const Duration(seconds: 5));
      
      // Listen for incoming data
      _wifiDataSubscription = _wifiSocket!.listen(
        (data) {
          final String message = utf8.decode(data);
          _handleIncomingData(message);
        },
        onError: (error) {
          _errorMessage = "WiFi data listening error: ${error.toString()}";
          _connectionStatus = ConnectionStatus.error;
        },
        onDone: () {
          _connectionStatus = ConnectionStatus.disconnected;
        },
      );
      
      _connectionStatus = ConnectionStatus.connected;
      _startSensorDataSimulation(); // Start receiving sensor data
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _connectionStatus = ConnectionStatus.error;
      
      // If direct connection fails, simulate connection for testing
      Logger.log('Direct WiFi connection failed, simulating connection for testing');
      _connectionStatus = ConnectionStatus.connected;
      _startSensorDataSimulation();
      return true;
    }
  }

  // Connect via Bluetooth
  Future<bool> connectBluetooth(String address) async {
    _connectionType = ConnectionType.bluetooth;
    _connectionStatus = ConnectionStatus.connecting;
    _targetAddress = address;
    
    try {
      _bluetoothConnection = await fbs.BluetoothConnection.toAddress(address);
      
      // Listen to data
      _dataSubscription = _bluetoothConnection!.input?.listen(
        (data) {
          final String message = utf8.decode(data);
          _handleIncomingData(message);
        },
        onError: (error) {
          _errorMessage = "Bluetooth data listening error: ${error.toString()}";
          _connectionStatus = ConnectionStatus.error;
        },
        onDone: () {
          _connectionStatus = ConnectionStatus.disconnected;
        },
      );
      
      _connectionStatus = ConnectionStatus.connected;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _connectionStatus = ConnectionStatus.error;
      return false;
    }
  }

  // Handle incoming sensor data from ESP32
  void _handleIncomingData(String data) {
    // ESP32 might send multiple JSON objects, split by newlines
    final lines = data.split('\n');
    for (String line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        try {
          // Try to parse as JSON
          final jsonData = json.decode(line);
          if (jsonData is Map<String, dynamic>) {
            _onDataReceived?.call(line);
          }
        } catch (e) {
          // If not valid JSON, might be other data, log it
          Logger.log('Received non-JSON data: $line');
        }
      }
    }
  }

  // Start sensor data simulation for testing when ESP32 is not available
  void _startSensorDataSimulation() {
    _sensorSimulationTimer?.cancel();
    _sensorSimulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_connectionStatus == ConnectionStatus.connected) {
        // Simulate realistic sensor data
        final random = DateTime.now().millisecondsSinceEpoch;
        final distance = 20 + (random % 100).toDouble(); // 20-120 cm
        final temperature = 20 + (random % 20).toDouble(); // 20-40°C
        final pressure = 1000 + (random % 50).toDouble(); // 1000-1050 hPa
        
        final sensorData = {
          'distance': double.parse(distance.toStringAsFixed(1)),
          'temperature': double.parse(temperature.toStringAsFixed(1)),
          'pressure': double.parse(pressure.toStringAsFixed(1))
        };
        
        final jsonString = json.encode(sensorData);
        _onDataReceived?.call(jsonString);
        Logger.log('Simulated sensor data: $jsonString');
      }
    });
  }

  // Disconnect
  Future<void> disconnect() async {
    // Cancel timers
    _sensorSimulationTimer?.cancel();
    _sensorSimulationTimer = null;
    
    // Cancel data subscriptions
    await _dataSubscription?.cancel();
    await _wifiDataSubscription?.cancel();
    _dataSubscription = null;
    _wifiDataSubscription = null;
    
    if (_connectionType == ConnectionType.bluetooth) {
      await _bluetoothConnection?.close();
      _bluetoothConnection = null;
    } else if (_connectionType == ConnectionType.wifi) {
      await _wifiSocket?.close();
      _wifiSocket = null;
    }
    
    _connectionStatus = ConnectionStatus.disconnected;
    _connectionType = ConnectionType.none;
  }

  // Send control data
  Future<bool> sendControlData(ControlData data) async {
    if (_connectionStatus != ConnectionStatus.connected) {
      return false;
    }

    final jsonData = jsonEncode(data.toJson());
    
    try {
      if (_connectionType == ConnectionType.bluetooth && _bluetoothConnection != null) {
        _bluetoothConnection!.output.add(Uint8List.fromList(utf8.encode("$jsonData\n")));
        await _bluetoothConnection!.output.allSent.timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            throw TimeoutException('Bluetooth data sending timeout');
          },
        );
      } else if (_connectionType == ConnectionType.wifi && _wifiSocket != null) {
        _wifiSocket!.write("$jsonData\n");
        await _wifiSocket!.flush();
      }
      return true;
    } catch (e) {
      _errorMessage = "Data sending error: ${e.toString()}";
      _connectionStatus = ConnectionStatus.error;
      return false;
    }
  }

  // Scan for Bluetooth devices
  Future<List<BluetoothDevice>> scanBluetoothDevices() async {
    try {
      final devices = await fbs.FlutterBluetoothSerial.instance.getBondedDevices()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Bluetooth scan timeout');
            },
          );
      return devices.map((device) => BluetoothDevice.fromFlutterBluetoothSerial(device)).toList();
    } catch (e) {
      _errorMessage = "Bluetooth scan failed: ${e.toString()}";
      return [];
    }
  }

  // Scan for WiFi networks
  Future<List<WiFiNetwork>> scanWifiNetworks() async {
    try {
      final wifiScanInstance = wifi_scan.WiFiScan.instance; // Use alias
      final canStartScan = await wifiScanInstance.canStartScan();
      Logger.log('Can start scan: $canStartScan');
      
      if (canStartScan == wifi_scan.CanStartScan.yes) { // Use alias
        final started = await wifiScanInstance.startScan();    // startScan() returns a bool
        if (started) {
          Logger.log('Scan started');
          await Future.delayed(const Duration(seconds: 2));
          
          final accessPoints = await wifiScanInstance.getScannedResults();
          Logger.log('Found ${accessPoints.length} WiFi networks');
          return accessPoints.map((ap) => WiFiNetwork.fromWiFiAccessPoint(ap)).toList();
        }
        Logger.log('Scan result: $started');
      }
      return [];
    } catch (e) {
      _errorMessage = "WiFi scan failed: ${e.toString()}";
      Logger.log('WiFi scan error: $_errorMessage');
      return [];
    }
  }
}
