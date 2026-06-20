import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static BluetoothDevice? connectedDevice;
  static BluetoothCharacteristic? characteristic;
  static bool isScanning = false;
  
  // Stream for received data
  static final _dataStream = StreamController<String>.broadcast();
  static Stream<String> get dataStream => _dataStream.stream;

  // Request Bluetooth permissions
  static Future<bool> requestPermissions() async {
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    return true;
  }

  // Start scanning for ESP32 devices
  static Future<List<ScanResult>> startScan() async {
    await requestPermissions();
    
    List<ScanResult> results = [];
    isScanning = true;
    
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
    );
    
    FlutterBluePlus.scanResults.listen((resultsList) {
      results = resultsList;
    });
    
    await Future.delayed(const Duration(seconds: 10));
    await FlutterBluePlus.stopScan();
    isScanning = false;
    
    return results;
  }

  // Connect to ESP32
  static Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Find characteristic for data transfer
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify || char.properties.read) {
            characteristic = char;
            await char.setNotifyValue(true);
            char.value.listen((value) {
              String received = String.fromCharCodes(value);
              _dataStream.add(received);
            });
            break;
          }
        }
      }
      return true;
    } catch (e) {
      print("Connection error: $e");
      return false;
    }
  }

  // Disconnect from ESP32
  static Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      characteristic = null;
    }
  }

  // Parse received data: "lat,lng,depth"
  static Map<String, double> parseData(String data) {
    try {
      List<String> parts = data.split(',');
      if (parts.length >= 3) {
        return {
          'latitude': double.parse(parts[0]),
          'longitude': double.parse(parts[1]),
          'depth': double.parse(parts[2]),
        };
      }
    } catch (e) {
      print("Parse error: $e");
    }
    return {};
  }
  
  static void dispose() {
    _dataStream.close();
  }
}