import 'dart:convert';

class UpdateManifest {
  final String latestVersion;
  final int latestVersionCode;
  final String apkDownloadUrl;
  final String apkSha256;
  final String releaseNotes;
  final bool mandatoryUpdate;
  final String minimumSupportedVersion;

  const UpdateManifest({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.apkDownloadUrl,
    this.apkSha256 = '',
    required this.releaseNotes,
    this.mandatoryUpdate = false,
    this.minimumSupportedVersion = '1.0.0',
  });

  bool isNewerThan(int currentVersionCode) {
    return latestVersionCode > currentVersionCode;
  }

  Map<String, dynamic> toMap() {
    return {
      'latestVersion': latestVersion,
      'latestVersionCode': latestVersionCode,
      'apkDownloadUrl': apkDownloadUrl,
      'apkSha256': apkSha256,
      'releaseNotes': releaseNotes,
      'mandatoryUpdate': mandatoryUpdate,
      'minimumSupportedVersion': minimumSupportedVersion,
    };
  }

  factory UpdateManifest.fromMap(Map<String, dynamic> map) {
    return UpdateManifest(
      latestVersion: map['latestVersion']?.toString() ?? '1.0.0',
      latestVersionCode: (map['latestVersionCode'] as num?)?.toInt() ?? 1,
      apkDownloadUrl: map['apkDownloadUrl']?.toString() ?? '',
      apkSha256: map['apkSha256']?.toString() ?? '',
      releaseNotes: map['releaseNotes']?.toString() ?? 'New update available.',
      mandatoryUpdate: map['mandatoryUpdate'] as bool? ?? false,
      minimumSupportedVersion: map['minimumSupportedVersion']?.toString() ?? '1.0.0',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UpdateManifest.fromJson(String source) =>
      UpdateManifest.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

