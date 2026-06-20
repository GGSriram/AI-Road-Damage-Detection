import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:road_damage_detector/pages/camera_screen.dart';
import 'package:road_damage_detector/pages/history_screen.dart';
import 'package:road_damage_detector/pages/settings_screen.dart';
import 'package:road_damage_detector/services/bluetooth_service.dart';
import 'package:road_damage_detector/widgets/connection_status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isConnected = false;
  List<ScanResult> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _listenToBluetoothData();
  }

  void _listenToBluetoothData() {
    BluetoothService.dataStream.listen((data) {
      Map<String, double> parsed = BluetoothService.parseData(data);
      if (parsed.isNotEmpty) {
        _showPotholeAlert(parsed);
      }
    });
  }

  Future<void> _scanAndConnect() async {
    setState(() {
      isScanning = true;
    });
    
    devices = await BluetoothService.startScan();
    
    setState(() {
      isScanning = false;
    });
    
    if (devices.isNotEmpty) {
      _showDeviceDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ESP32 devices found')),
      );
    }
  }

  void _showDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select ESP32 Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(devices[index].device.name ?? 'ESP32 Device'),
                subtitle: Text(devices[index].device.remoteId.toString()),
                onTap: () async {
                  Navigator.pop(context);
                  bool success = await BluetoothService.connect(devices[index].device);
                  setState(() {
                    isConnected = success;
                  });
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connected to ESP32!')),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPotholeAlert(Map<String, double> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Pothole Detected!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Latitude: ${data['latitude']?.toStringAsFixed(6)}'),
            Text('📍 Longitude: ${data['longitude']?.toStringAsFixed(6)}'),
            Text('📏 Depth: ${data['depth']?.toStringAsFixed(1)} cm'),
            const SizedBox(height: 10),
            const Text('Opening camera for confirmation...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScreen(
                    latitude: data['latitude']!,
                    longitude: data['longitude']!,
                    depth: data['depth']!,
                  ),
                ),
              );
            },
            child: const Text('Capture'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartRoad AI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ConnectionStatus(isConnected: isConnected),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    icon: Icons.bluetooth,
                    title: 'Connect\nESP32',
                    color: Colors.blue,
                    onTap: _scanAndConnect,
                    isLoading: isScanning,
                  ),
                  _buildMenuCard(
                    icon: Icons.camera_alt,
                    title: 'Live\nDetection',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.history,
                    title: 'History',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.info,
                    title: 'About',
                    color: Colors.purple,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'SmartRoad AI',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.road, size: 40),
                        children: const [
                          Text('AI-Based Road Damage Detection System'),
                          SizedBox(height: 10),
                          Text('© 2024 SmartRoad AI'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 48, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}