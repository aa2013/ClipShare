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
