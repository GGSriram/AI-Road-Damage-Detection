class Detection {
  int? id;
  DateTime timestamp;
  double latitude;
  double longitude;
  double depth;
  String photoPath;
  double aiConfidence;
  String severity;
  bool synced;

  Detection({
    this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.photoPath,
    required this.aiConfidence,
    required this.severity,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'depth': depth,
      'photo_path': photoPath,
      'ai_confidence': aiConfidence,
      'severity': severity,
      'synced': synced ? 1 : 0,
    };
  }

  factory Detection.fromMap(Map<String, dynamic> map) {
    return Detection(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      latitude: map['latitude'],
      longitude: map['longitude'],
      depth: map['depth'],
      photoPath: map['photo_path'],
      aiConfidence: map['ai_confidence'],
      severity: map['severity'],
      synced: map['synced'] == 1,
    );
  }

  String get severityColor {
    switch (severity) {
      case 'LOW':
        return '#4CAF50';
      case 'MEDIUM':
        return '#FF9800';
      case 'HIGH':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
  
  String get severityIcon {
    switch (severity) {
      case 'LOW':
        return '⚠️';
      case 'MEDIUM':
        return '⚠️⚠️';
      case 'HIGH':
        return '⚠️⚠️⚠️';
      default:
        return '❓';
    }
  }
}