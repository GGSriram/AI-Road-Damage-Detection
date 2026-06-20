import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:road_damage_detector/models/detection_model.dart';

class DatabaseService {
  static Database? _database;
  static const String dbName = 'road_damage.db';
  static const int dbVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, dbName);
    
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE detections(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        latitude REAL,
        longitude REAL,
        depth REAL,
        photo_path TEXT,
        ai_confidence REAL,
        severity TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Initialize database
  static Future<void> init() async {
    await database;
  }

  // Save detection
  static Future<int> saveDetection(Detection detection) async {
    final db = await database;
    return await db.insert('detections', detection.toMap());
  }

  // Get all detections
  static Future<List<Detection>> getAllDetections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detections',
      orderBy: 'timestamp DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Detection.fromMap(maps[i]);
    });
  }

  // Get detection by ID
  static Future<Detection?> getDetectionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'detections',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Detection.fromMap(maps.first);
    }
    return null;
  }

  // Delete detection
  static Future<int> deleteDetection(int id) async {
    final db = await database;
    return await db.delete(
      'detections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get count
  static Future<int> getCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM detections');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Delete all detections
  static Future<void> deleteAll() async {
    final db = await database;
    await db.delete('detections');
  }
  
  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}