import 'package:clipshare/shared/extensions/string_extension.dart';

class AppVersion {
  final String name;
  final String code;

  int get codeNum => code.toInt();

  const AppVersion(this.name, this.code);

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(json['name'], json['code']);
  }

  @override
  String toString() {
    return '$name($code)';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }

  bool operator >=(AppVersion other) {
    return codeNum >= other.codeNum;
  }

  bool operator <=(AppVersion other) {
    return codeNum <= other.codeNum;
  }

  bool operator >(AppVersion other) {
    return codeNum > other.codeNum;
  }

  bool operator <(AppVersion other) {
    return codeNum < other.codeNum;
  }

  int operator -(AppVersion other) {
    return codeNum - other.codeNum;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersion &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;

  const SemanticVersion(this.major, this.minor, this.patch);

  factory SemanticVersion.parse(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid semantic version', value);
    }
    return SemanticVersion(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  int compareTo(SemanticVersion other) {
    final majorDiff = major.compareTo(other.major);
    if (majorDiff != 0) return majorDiff;
    final minorDiff = minor.compareTo(other.minor);
    if (minorDiff != 0) return minorDiff;
    return patch.compareTo(other.patch);
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;

  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  bool operator <(SemanticVersion other) => compareTo(other) < 0;

  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SemanticVersion &&
            runtimeType == other.runtimeType &&
            major == other.major &&
            minor == other.minor &&
            patch == other.patch;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
