import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:road_damage_detector/services/ai_service.dart';
import 'package:road_damage_detector/services/database_service.dart';
import 'package:road_damage_detector/models/detection_model.dart';
import 'package:intl/intl.dart';

class CameraScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final double? depth;
  
  const CameraScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.depth,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      setState(() {
        _isCameraReady = true;
      });
      
      // If triggered by ESP32, auto-capture
      if (widget.latitude != null) {
        Future.delayed(const Duration(seconds: 1), () {
          _captureAndDetect();
        });
      }
    } catch (e) {
      print("Camera initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _captureAndDetect() async {
    if (_isProcessing || !_isCameraReady) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Capture photo
      XFile photo = await _controller!.takePicture();
      File photoFile = File(photo.path);
      
      // Save to app directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${directory.path}/pothole_$timestamp.jpg';
      await photoFile.copy(savedPath);
      
      // Run AI detection
      final result = await AIService.detectPothole(photoFile);
      
      if (result['detected'] == true) {
        // Determine severity based on depth
        String severity = 'LOW';
        if (widget.depth != null) {
          if (widget.depth! > 8) {
            severity = 'HIGH';
          } else if (widget.depth! > 5) {
            severity = 'MEDIUM';
          }
        }
        
        // Save detection
        Detection detection = Detection(
          timestamp: DateTime.now(),
          latitude: widget.latitude ?? 0.0,
          longitude: widget.longitude ?? 0.0,
          depth: widget.depth ?? 0.0,
          photoPath: savedPath,
          aiConfidence: result['confidence'],
          severity: severity,
        );
        
        await DatabaseService.saveDetection(detection);
        
        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Pothole confirmed! Confidence: ${(result['confidence'] * 100).toInt()}%'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ No pothole detected in image'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print("Capture error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Road Camera'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera),
            onPressed: _captureAndDetect,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isCameraReady)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator()),
          
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Analyzing with AI...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          
          if (widget.latitude != null)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '⚠️ ESP32 Triggered!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text('📍 ${widget.latitude?.toStringAsFixed(6)}, ${widget.longitude?.toStringAsFixed(6)}'),
                    Text('📏 Depth: ${widget.depth?.toStringAsFixed(1)} cm'),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureAndDetect,
        child: const Icon(Icons.camera),
      ),
    );
  }
}