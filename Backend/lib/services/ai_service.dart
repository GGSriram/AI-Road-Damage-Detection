import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIService {
  static Interpreter? _interpreter;
  static bool isModelLoaded = false;

  // Load YOLO model from assets
  static Future<void> loadModel() async {
    try {
      // Load model from assets
      _interpreter = await Interpreter.fromAsset('assets/models/road_damage_model.tflite');
      isModelLoaded = true;
      print("AI Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
      isModelLoaded = false;
    }
  }

  // Detect potholes in image
  static Future<Map<String, dynamic>> detectPothole(File imageFile) async {
    if (!isModelLoaded) {
      await loadModel();
    }
    
    if (!isModelLoaded) {
      return {'detected': false, 'confidence': 0.0, 'error': 'Model not loaded'};
    }
    
    try {
      // Load and preprocess image
      img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) return {'detected': false, 'confidence': 0.0};
      
      // Resize to 320x320 (model input size)
      img.Image resized = img.copyResize(image, width: 320, height: 320);
      
      // Convert to normalized float32 array [1, 320, 320, 3]
      var input = List.filled(1 * 320 * 320 * 3, 0.0);
      int index = 0;
      for (int y = 0; y < 320; y++) {
        for (int x = 0; x < 320; x++) {
          final pixel = resized.getPixel(x, y);
          input[index++] = (pixel.r / 255.0);
          input[index++] = (pixel.g / 255.0);
          input[index++] = (pixel.b / 255.0);
        }
      }
      
      // Prepare input tensor
      var inputTensor = input.reshape([1, 320, 320, 3]);
      
      // Prepare output (adjust based on your model's output shape)
      // For YOLOv8, output shape is [1, 84, 8400] or similar
      var output = List.filled(1 * 8400 * 6, 0.0).reshape([1, 8400, 6]);
      
      // Run inference
      _interpreter?.run(inputTensor, output);
      
      // Parse results (simplified detection)
      double maxConfidence = 0.0;
      for (int i = 0; i < output[0].length; i++) {
        double conf = output[0][i][4];
        if (conf > maxConfidence) {
          maxConfidence = conf;
        }
      }
      
      bool detected = maxConfidence > 0.6;
      
      return {
        'detected': detected,
        'confidence': maxConfidence,
      };
    } catch (e) {
      print("Detection error: $e");
      return {'detected': false, 'confidence': 0.0, 'error': e.toString()};
    }
  }
  
  static void dispose() {
    _interpreter?.close();
  }
}