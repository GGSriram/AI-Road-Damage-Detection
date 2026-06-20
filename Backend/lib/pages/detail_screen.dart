import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:road_damage_detector/models/detection_model.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatelessWidget {
  final Detection detection;
  
  const DetailScreen({super.key, required this.detection});

  Future<void> _openMap() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${detection.latitude},${detection.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _share() async {
    final message = '''
🚧 ROAD DAMAGE ALERT 🚧

📍 Location: ${detection.latitude}, ${detection.longitude}
📏 Depth: ${detection.depth.toStringAsFixed(1)} cm
⚠️ Severity: ${detection.severity}
🕐 Time: ${DateFormat('dd MMM yyyy, HH:mm:ss').format(detection.timestamp)}
🤖 AI Confidence: ${(detection.aiConfidence * 100).toInt()}%

🔗 Map: https://maps.google.com/?q=${detection.latitude},${detection.longitude}

-- SmartRoad AI Detection System --
''';
    
    await Share.share(message);
  }

  String _getSeverityDescription(String severity) {
    switch (severity) {
      case 'LOW':
        return 'Minor damage, schedule repair within 30 days';
      case 'MEDIUM':
        return 'Moderate damage, schedule repair within 15 days';
      case 'HIGH':
        return 'Severe damage, immediate repair required!';
      default:
        return 'Unknown severity';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = Color(int.parse(detection.severityColor.replaceFirst('#', '0xff')));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (File(detection.photoPath).exists())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(detection.photoPath),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            
            // Severity Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: severityColor, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      detection.severityIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Severity: ${detection.severity}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSeverityDescription(detection.severity),
                          style: TextStyle(color: severityColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Details Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: const Text('Coordinates'),
                      subtitle: Text('${detection.latitude.toStringAsFixed(6)}, ${detection.longitude.toStringAsFixed(6)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: _openMap,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer, color: Colors.blue),
                      title: const Text('Date & Time'),
                      subtitle: Text(DateFormat('dd MMM yyyy, HH:mm:ss').format(detection.timestamp)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.rule, color: Colors.green),
                      title: const Text('Pothole Depth'),
                      subtitle: Text('${detection.depth.toStringAsFixed(1)} cm'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                      title: const Text('AI Confidence'),
                      subtitle: Text('${(detection.aiConfidence * 100).toInt()}%'),
                      trailing: SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: detection.aiConfidence,
                          backgroundColor: Colors.grey,
                          color: Colors.green,
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openMap,
                    icon: const Icon(Icons.map),
                    label: const Text('Open in Maps'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}