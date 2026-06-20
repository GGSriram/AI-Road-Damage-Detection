import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;

  static Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
    }
  }

  static CameraController? get controller => _controller;
  static List<CameraDescription>? get cameras => _cameras;

  static Future<String> captureAndSave() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    
    final XFile photo = await _controller!.takePicture();
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'pothole_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = join(directory.path, fileName);
    
    await File(photo.path).copy(savedPath);
    return savedPath;
  }

  static void dispose() {
    _controller?.dispose();
  }
}