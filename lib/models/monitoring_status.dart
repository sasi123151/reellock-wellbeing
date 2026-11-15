class MonitoringStatus {
  final bool usagePermissionGranted;
  final bool accessibilityServiceEnabled;
  final bool isCurrentlyInsideReels;
  final bool isInstagramInstalled;
  final bool isConnected;
  final int reelsSessionStartMs;
  final String detectionConfidence;

  const MonitoringStatus({
    required this.usagePermissionGranted,
    required this.accessibilityServiceEnabled,
    required this.isCurrentlyInsideReels,
    required this.isInstagramInstalled,
    required this.isConnected,
    required this.reelsSessionStartMs,
    this.detectionConfidence = 'NONE',
  });

  bool get isMonitoringActive =>
      usagePermissionGranted && accessibilityServiceEnabled;

  factory MonitoringStatus.initial() {
    return const MonitoringStatus(
      usagePermissionGranted: false,
      accessibilityServiceEnabled: false,
      isCurrentlyInsideReels: false,
      isInstagramInstalled: true,
      isConnected: false,
      reelsSessionStartMs: 0,
      detectionConfidence: 'NONE',
    );
  }

  factory MonitoringStatus.fromMap(Map<dynamic, dynamic> map) {
    final usage = map['usagePermissionGranted'] == true;
    final access = map['accessibilityServiceEnabled'] == true;
    return MonitoringStatus(
      usagePermissionGranted: usage,
      accessibilityServiceEnabled: access,
      isCurrentlyInsideReels: map['isCurrentlyInsideReels'] == true,
      isInstagramInstalled: map['isInstagramInstalled'] == true,
      isConnected: map['isConnected'] == true || (usage && access),
      reelsSessionStartMs: (map['reelsSessionStartMs'] as num?)?.toInt() ?? 0,
      detectionConfidence: map['detectionConfidence']?.toString() ?? 'NONE',
    );
  }
}
