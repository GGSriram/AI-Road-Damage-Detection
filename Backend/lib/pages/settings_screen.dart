import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _confidenceThreshold = 0.6;
  bool _autoCapture = true;
  bool _notificationsEnabled = true;
  String _alertEmail = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _confidenceThreshold = prefs.getDouble('confidence_threshold') ?? 0.6;
      _autoCapture = prefs.getBool('auto_capture') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _alertEmail = prefs.getString('alert_email') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('confidence_threshold', _confidenceThreshold);
    await prefs.setBool('auto_capture', _autoCapture);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('alert_email', _alertEmail);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  void _showEmailDialog() {
    TextEditingController controller = TextEditingController(text: _alertEmail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert Email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter email address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _alertEmail = controller.text;
              });
              Navigator.pop(context);
              _saveSettings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // AI Detection Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'AI DETECTION',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Confidence Threshold'),
                    subtitle: Text('${(_confidenceThreshold * 100).toInt()}%'),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: _confidenceThreshold,
                        min: 0.5,
                        max: 0.9,
                        divisions: 40,
                        label: '${(_confidenceThreshold * 100).toInt()}%',
                        onChanged: (value) {
                          setState(() {
                            _confidenceThreshold = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Auto Capture'),
                    subtitle: const Text('Auto-capture when ESP32 triggers'),
                    value: _autoCapture,
                    onChanged: (value) {
                      setState(() {
                        _autoCapture = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notifications Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'NOTIFICATIONS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Alerts'),
                    subtitle: const Text('Receive local notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Alert Email'),
                    subtitle: Text(_alertEmail.isEmpty ? 'Not set' : _alertEmail),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showEmailDialog,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // About Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ABOUT',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.road),
                  title: const Text('SmartRoad AI'),
                  subtitle: const Text('AI-Based Road Damage Detection System'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}