class VHistoryTagHold implements Comparable<VHistoryTagHold> {
  int hisId;
  String tagName;
  bool hasTag;

  VHistoryTagHold(this.hisId, this.tagName, this.hasTag);

  @override
  bool operator ==(Object other) => identical(this, other) || other is VHistoryTagHold && runtimeType == other.runtimeType && hisId == other.hisId && tagName == other.tagName;

  @override
  int get hashCode => hisId.hashCode ^ tagName.hashCode;

  Map<String, dynamic> toJson() {
    return {'hisId': hisId, 'tagName': tagName, 'hasTag': hasTag};
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  int compareTo(VHistoryTagHold other) {
    //拥有的排序在前
    if (hasTag && !other.hasTag) {
      return -1;
    }
    //按名称升序
    return tagName.compareTo(other.tagName);
  }
}
