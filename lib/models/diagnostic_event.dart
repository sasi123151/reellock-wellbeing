/// Model representing an individual monitored wellbeing event
class DiagnosticEvent {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final String detectionMethod;
  final String details;
  final String confidence;
  final int durationMs;

  const DiagnosticEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.detectionMethod,
    required this.details,
    this.confidence = 'HIGH',
    this.durationMs = 0,
  });

  factory DiagnosticEvent.fromMap(Map<dynamic, dynamic> map) {
    final rawTs = map['timestamp'];
    DateTime dt;
    if (rawTs is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      dt = DateTime.now();
    }

    return DiagnosticEvent(
      id: map['id']?.toString() ?? '',
      timestamp: dt,
      eventType: map['eventType']?.toString() ?? 'UNKNOWN',
      detectionMethod: map['detectionMethod']?.toString() ?? 'NONE',
      details: map['details']?.toString() ?? '',
      confidence: map['confidence']?.toString() ?? 'HIGH',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
