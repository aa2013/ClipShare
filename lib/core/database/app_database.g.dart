// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HistoriesTable extends Histories
    with TableInfo<$HistoriesTable, History> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedMeta = const VerificationMeta(
    'extracted',
  );
  @override
  late final GeneratedColumn<String> extracted = GeneratedColumn<String>(
    'extracted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devIdMeta = const VerificationMeta('devId');
  @override
  late final GeneratedColumn<String> devId = GeneratedColumn<String>(
    'devId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topMeta = const VerificationMeta('top');
  @override
  late final GeneratedColumn<bool> top = GeneratedColumn<bool>(
    'top',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("top" IN (0, 1))',
    ),
  );
  static const VerificationMeta _syncMeta = const VerificationMeta('sync');
  @override
  late final GeneratedColumn<bool> sync = GeneratedColumn<bool>(
    'sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updateTimeMeta = const VerificationMeta(
    'updateTime',
  );
  @override
  late final GeneratedColumn<String> updateTime = GeneratedColumn<String>(
    'updateTime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    time,
    content,
    extracted,
    type,
    devId,
    top,
    sync,
    size,
    updateTime,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'History';
  @override
  VerificationContext validateIntegrity(
    Insertable<History> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('extracted')) {
      context.handle(
        _extractedMeta,
        extracted.isAcceptableOrUnknown(data['extracted']!, _extractedMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('devId')) {
      context.handle(
        _devIdMeta,
        devId.isAcceptableOrUnknown(data['devId']!, _devIdMeta),
      );
    } else if (isInserting) {
      context.missing(_devIdMeta);
    }
    if (data.containsKey('top')) {
      context.handle(
        _topMeta,
        top.isAcceptableOrUnknown(data['top']!, _topMeta),
      );
    } else if (isInserting) {
      context.missing(_topMeta);
    }
    if (data.containsKey('sync')) {
      context.handle(
        _syncMeta,
        sync.isAcceptableOrUnknown(data['sync']!, _syncMeta),
      );
    } else if (isInserting) {
      context.missing(_syncMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('updateTime')) {
      context.handle(
        _updateTimeMeta,
        updateTime.isAcceptableOrUnknown(data['updateTime']!, _updateTimeMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  History map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return History(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      extracted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      devId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devId'],
      )!,
      top: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}top'],
      )!,
      sync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      updateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updateTime'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
    );
  }

  @override
  $HistoriesTable createAlias(String alias) {
    return $HistoriesTable(attachedDatabase, alias);
  }
}

class History extends DataClass implements Insertable<History> {
  final int id;
  final int uid;
  final String time;
  final String content;
  final String? extracted;
  final String type;
  final String devId;
  final bool top;
  final bool sync;
  final int size;
  final String? updateTime;
  final String? source;
  const History({
    required this.id,
    required this.uid,
    required this.time,
    required this.content,
    this.extracted,
    required this.type,
    required this.devId,
    required this.top,
    required this.sync,
    required this.size,
    this.updateTime,
    this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<int>(uid);
    map['time'] = Variable<String>(time);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || extracted != null) {
      map['extracted'] = Variable<String>(extracted);
    }
    map['type'] = Variable<String>(type);
    map['devId'] = Variable<String>(devId);
    map['top'] = Variable<bool>(top);
    map['sync'] = Variable<bool>(sync);
    map['size'] = Variable<int>(size);
    if (!nullToAbsent || updateTime != null) {
      map['updateTime'] = Variable<String>(updateTime);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  HistoriesCompanion toCompanion(bool nullToAbsent) {
    return HistoriesCompanion(
      id: Value(id),
      uid: Value(uid),
      time: Value(time),
      content: Value(content),
      extracted: extracted == null && nullToAbsent
          ? const Value.absent()
          : Value(extracted),
      type: Value(type),
      devId: Value(devId),
      top: Value(top),
      sync: Value(sync),
      size: Value(size),
      updateTime: updateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(updateTime),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
    );
  }

  factory History.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return History(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<int>(json['uid']),
      time: serializer.fromJson<String>(json['time']),
      content: serializer.fromJson<String>(json['content']),
      extracted: serializer.fromJson<String?>(json['extracted']),
      type: serializer.fromJson<String>(json['type']),
      devId: serializer.fromJson<String>(json['devId']),
      top: serializer.fromJson<bool>(json['top']),
      sync: serializer.fromJson<bool>(json['sync']),
      size: serializer.fromJson<int>(json['size']),
      updateTime: serializer.fromJson<String?>(json['updateTime']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<int>(uid),
      'time': serializer.toJson<String>(time),
      'content': serializer.toJson<String>(content),
      'extracted': serializer.toJson<String?>(extracted),
      'type': serializer.toJson<String>(type),
      'devId': serializer.toJson<String>(devId),
      'top': serializer.toJson<bool>(top),
      'sync': serializer.toJson<bool>(sync),
      'size': serializer.toJson<int>(size),
      'updateTime': serializer.toJson<String?>(updateTime),
      'source': serializer.toJson<String?>(source),
    };
  }

  History copyWith({
    int? id,
    int? uid,
    String? time,
    String? content,
    Value<String?> extracted = const Value.absent(),
    String? type,
    String? devId,
    bool? top,
    bool? sync,
    int? size,
    Value<String?> updateTime = const Value.absent(),
    Value<String?> source = const Value.absent(),
  }) => History(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    time: time ?? this.time,
    content: content ?? this.content,
    extracted: extracted.present ? extracted.value : this.extracted,
    type: type ?? this.type,
    devId: devId ?? this.devId,
    top: top ?? this.top,
    sync: sync ?? this.sync,
    size: size ?? this.size,
    updateTime: updateTime.present ? updateTime.value : this.updateTime,
    source: source.present ? source.value : this.source,
  );
  History copyWithCompanion(HistoriesCompanion data) {
    return History(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      time: data.time.present ? data.time.value : this.time,
      content: data.content.present ? data.content.value : this.content,
      extracted: data.extracted.present ? data.extracted.value : this.extracted,
      type: data.type.present ? data.type.value : this.type,
      devId: data.devId.present ? data.devId.value : this.devId,
      top: data.top.present ? data.top.value : this.top,
      sync: data.sync.present ? data.sync.value : this.sync,
      size: data.size.present ? data.size.value : this.size,
      updateTime: data.updateTime.present
          ? data.updateTime.value
          : this.updateTime,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('History(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('extracted: $extracted, ')
          ..write('type: $type, ')
          ..write('devId: $devId, ')
          ..write('top: $top, ')
          ..write('sync: $sync, ')
          ..write('size: $size, ')
          ..write('updateTime: $updateTime, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    time,
    content,
    extracted,
    type,
    devId,
    top,
    sync,
    size,
    updateTime,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is History &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.time == this.time &&
          other.content == this.content &&
          other.extracted == this.extracted &&
          other.type == this.type &&
          other.devId == this.devId &&
          other.top == this.top &&
          other.sync == this.sync &&
          other.size == this.size &&
          other.updateTime == this.updateTime &&
          other.source == this.source);
}

class HistoriesCompanion extends UpdateCompanion<History> {
  final Value<int> id;
  final Value<int> uid;
  final Value<String> time;
  final Value<String> content;
  final Value<String?> extracted;
  final Value<String> type;
  final Value<String> devId;
  final Value<bool> top;
  final Value<bool> sync;
  final Value<int> size;
  final Value<String?> updateTime;
  final Value<String?> source;
  const HistoriesCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.extracted = const Value.absent(),
    this.type = const Value.absent(),
    this.devId = const Value.absent(),
    this.top = const Value.absent(),
    this.sync = const Value.absent(),
    this.size = const Value.absent(),
    this.updateTime = const Value.absent(),
    this.source = const Value.absent(),
  });
  HistoriesCompanion.insert({
    this.id = const Value.absent(),
    required int uid,
    required String time,
    required String content,
    this.extracted = const Value.absent(),
    required String type,
    required String devId,
    required bool top,
    required bool sync,
    required int size,
    this.updateTime = const Value.absent(),
    this.source = const Value.absent(),
  }) : uid = Value(uid),
       time = Value(time),
       content = Value(content),
       type = Value(type),
       devId = Value(devId),
       top = Value(top),
       sync = Value(sync),
       size = Value(size);
  static Insertable<History> custom({
    Expression<int>? id,
    Expression<int>? uid,
    Expression<String>? time,
    Expression<String>? content,
    Expression<String>? extracted,
    Expression<String>? type,
    Expression<String>? devId,
    Expression<bool>? top,
    Expression<bool>? sync,
    Expression<int>? size,
    Expression<String>? updateTime,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (extracted != null) 'extracted': extracted,
      if (type != null) 'type': type,
      if (devId != null) 'devId': devId,
      if (top != null) 'top': top,
      if (sync != null) 'sync': sync,
      if (size != null) 'size': size,
      if (updateTime != null) 'updateTime': updateTime,
      if (source != null) 'source': source,
    });
  }

  HistoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? uid,
    Value<String>? time,
    Value<String>? content,
    Value<String?>? extracted,
    Value<String>? type,
    Value<String>? devId,
    Value<bool>? top,
    Value<bool>? sync,
    Value<int>? size,
    Value<String?>? updateTime,
    Value<String?>? source,
  }) {
    return HistoriesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      time: time ?? this.time,
      content: content ?? this.content,
      extracted: extracted ?? this.extracted,
      type: type ?? this.type,
      devId: devId ?? this.devId,
      top: top ?? this.top,
      sync: sync ?? this.sync,
      size: size ?? this.size,
      updateTime: updateTime ?? this.updateTime,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (extracted.present) {
      map['extracted'] = Variable<String>(extracted.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (devId.present) {
      map['devId'] = Variable<String>(devId.value);
    }
    if (top.present) {
      map['top'] = Variable<bool>(top.value);
    }
    if (sync.present) {
      map['sync'] = Variable<bool>(sync.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (updateTime.present) {
      map['updateTime'] = Variable<String>(updateTime.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoriesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('extracted: $extracted, ')
          ..write('type: $type, ')
          ..write('devId: $devId, ')
          ..write('top: $top, ')
          ..write('sync: $sync, ')
          ..write('size: $size, ')
          ..write('updateTime: $updateTime, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $HistoryTagsTable extends HistoryTags
    with TableInfo<$HistoryTagsTable, HistoryTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagNameMeta = const VerificationMeta(
    'tagName',
  );
  @override
  late final GeneratedColumn<String> tagName = GeneratedColumn<String>(
    'tagName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hisIdMeta = const VerificationMeta('hisId');
  @override
  late final GeneratedColumn<int> hisId = GeneratedColumn<int>(
    'hisId',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, tagName, hisId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'HistoryTag';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tagName')) {
      context.handle(
        _tagNameMeta,
        tagName.isAcceptableOrUnknown(data['tagName']!, _tagNameMeta),
      );
    } else if (isInserting) {
      context.missing(_tagNameMeta);
    }
    if (data.containsKey('hisId')) {
      context.handle(
        _hisIdMeta,
        hisId.isAcceptableOrUnknown(data['hisId']!, _hisIdMeta),
      );
    } else if (isInserting) {
      context.missing(_hisIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tagName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tagName'],
      )!,
      hisId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hisId'],
      )!,
    );
  }

  @override
  $HistoryTagsTable createAlias(String alias) {
    return $HistoryTagsTable(attachedDatabase, alias);
  }
}

class HistoryTag extends DataClass implements Insertable<HistoryTag> {
  final int id;
  final String tagName;
  final int hisId;
  const HistoryTag({
    required this.id,
    required this.tagName,
    required this.hisId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tagName'] = Variable<String>(tagName);
    map['hisId'] = Variable<int>(hisId);
    return map;
  }

  HistoryTagsCompanion toCompanion(bool nullToAbsent) {
    return HistoryTagsCompanion(
      id: Value(id),
      tagName: Value(tagName),
      hisId: Value(hisId),
    );
  }

  factory HistoryTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryTag(
      id: serializer.fromJson<int>(json['id']),
      tagName: serializer.fromJson<String>(json['tagName']),
      hisId: serializer.fromJson<int>(json['hisId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tagName': serializer.toJson<String>(tagName),
      'hisId': serializer.toJson<int>(hisId),
    };
  }

  HistoryTag copyWith({int? id, String? tagName, int? hisId}) => HistoryTag(
    id: id ?? this.id,
    tagName: tagName ?? this.tagName,
    hisId: hisId ?? this.hisId,
  );
  HistoryTag copyWithCompanion(HistoryTagsCompanion data) {
    return HistoryTag(
      id: data.id.present ? data.id.value : this.id,
      tagName: data.tagName.present ? data.tagName.value : this.tagName,
      hisId: data.hisId.present ? data.hisId.value : this.hisId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryTag(')
          ..write('id: $id, ')
          ..write('tagName: $tagName, ')
          ..write('hisId: $hisId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tagName, hisId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryTag &&
          other.id == this.id &&
          other.tagName == this.tagName &&
          other.hisId == this.hisId);
}

class HistoryTagsCompanion extends UpdateCompanion<HistoryTag> {
  final Value<int> id;
  final Value<String> tagName;
  final Value<int> hisId;
  const HistoryTagsCompanion({
    this.id = const Value.absent(),
    this.tagName = const Value.absent(),
    this.hisId = const Value.absent(),
  });
  HistoryTagsCompanion.insert({
    this.id = const Value.absent(),
    required String tagName,
    required int hisId,
  }) : tagName = Value(tagName),
       hisId = Value(hisId);
  static Insertable<HistoryTag> custom({
    Expression<int>? id,
    Expression<String>? tagName,
    Expression<int>? hisId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tagName != null) 'tagName': tagName,
      if (hisId != null) 'hisId': hisId,
    });
  }

  HistoryTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? tagName,
    Value<int>? hisId,
  }) {
    return HistoryTagsCompanion(
      id: id ?? this.id,
      tagName: tagName ?? this.tagName,
      hisId: hisId ?? this.hisId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tagName.present) {
      map['tagName'] = Variable<String>(tagName.value);
    }
    if (hisId.present) {
      map['hisId'] = Variable<int>(hisId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryTagsCompanion(')
          ..write('id: $id, ')
          ..write('tagName: $tagName, ')
          ..write('hisId: $hisId')
          ..write(')'))
        .toString();
  }
}

class VHistoryTagHoldData extends DataClass {
  final int hisId;
  final String tagName;
  final bool hasTag;
  const VHistoryTagHoldData({
    required this.hisId,
    required this.tagName,
    required this.hasTag,
  });
  factory VHistoryTagHoldData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VHistoryTagHoldData(
      hisId: serializer.fromJson<int>(json['hisId']),
      tagName: serializer.fromJson<String>(json['tagName']),
      hasTag: serializer.fromJson<bool>(json['hasTag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hisId': serializer.toJson<int>(hisId),
      'tagName': serializer.toJson<String>(tagName),
      'hasTag': serializer.toJson<bool>(hasTag),
    };
  }

  VHistoryTagHoldData copyWith({int? hisId, String? tagName, bool? hasTag}) =>
      VHistoryTagHoldData(
        hisId: hisId ?? this.hisId,
        tagName: tagName ?? this.tagName,
        hasTag: hasTag ?? this.hasTag,
      );
  @override
  String toString() {
    return (StringBuffer('VHistoryTagHoldData(')
          ..write('hisId: $hisId, ')
          ..write('tagName: $tagName, ')
          ..write('hasTag: $hasTag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(hisId, tagName, hasTag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VHistoryTagHoldData &&
          other.hisId == this.hisId &&
          other.tagName == this.tagName &&
          other.hasTag == this.hasTag);
}

class VHistoryTagHold extends ViewInfo<VHistoryTagHold, VHistoryTagHoldData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  VHistoryTagHold(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [hisId, tagName, hasTag];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'VHistoryTagHold';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite:
        'CREATE VIEW VHistoryTagHold AS SELECT t1.*,(t2.hisId IS NOT NULL)AS hasTag FROM (SELECT DISTINCT h.id AS hisId, tag.tagName FROM history AS h,historyTag AS tag) AS t1 LEFT JOIN (SELECT * FROM HistoryTag) AS t2 ON t2.hisId = t1.hisId AND t2.tagName = t1.tagName',
  };
  @override
  VHistoryTagHold get asDslTable => this;
  @override
  VHistoryTagHoldData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VHistoryTagHoldData(
      hisId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hisId'],
      )!,
      tagName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tagName'],
      )!,
      hasTag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hasTag'],
      )!,
    );
  }

  late final GeneratedColumn<int> hisId = GeneratedColumn<int>(
    'hisId',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<String> tagName = GeneratedColumn<String>(
    'tagName',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<bool> hasTag = GeneratedColumn<bool>(
    'hasTag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hasTag" IN (0, 1))',
    ),
  );
  @override
  VHistoryTagHold createAlias(String alias) {
    return VHistoryTagHold(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {'History', 'HistoryTag'};
}

class $ConfigsTable extends Configs with TableInfo<$ConfigsTable, Config> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, uid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Config';
  @override
  VerificationContext validateIntegrity(
    Insertable<Config> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Config map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Config(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      )!,
    );
  }

  @override
  $ConfigsTable createAlias(String alias) {
    return $ConfigsTable(attachedDatabase, alias);
  }
}

class Config extends DataClass implements Insertable<Config> {
  final String key;
  final String value;
  final int uid;
  const Config({required this.key, required this.value, required this.uid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['uid'] = Variable<int>(uid);
    return map;
  }

  ConfigsCompanion toCompanion(bool nullToAbsent) {
    return ConfigsCompanion(
      key: Value(key),
      value: Value(value),
      uid: Value(uid),
    );
  }

  factory Config.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Config(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      uid: serializer.fromJson<int>(json['uid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'uid': serializer.toJson<int>(uid),
    };
  }

  Config copyWith({String? key, String? value, int? uid}) => Config(
    key: key ?? this.key,
    value: value ?? this.value,
    uid: uid ?? this.uid,
  );
  Config copyWithCompanion(ConfigsCompanion data) {
    return Config(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      uid: data.uid.present ? data.uid.value : this.uid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Config(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('uid: $uid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, uid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Config &&
          other.key == this.key &&
          other.value == this.value &&
          other.uid == this.uid);
}

class ConfigsCompanion extends UpdateCompanion<Config> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> uid;
  final Value<int> rowid;
  const ConfigsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.uid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigsCompanion.insert({
    required String key,
    required String value,
    required int uid,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       uid = Value(uid);
  static Insertable<Config> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? uid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (uid != null) 'uid': uid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? uid,
    Value<int>? rowid,
  }) {
    return ConfigsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      uid: uid ?? this.uid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('uid: $uid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devNameMeta = const VerificationMeta(
    'devName',
  );
  @override
  late final GeneratedColumn<String> devName = GeneratedColumn<String>(
    'devName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'customName',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _internalAddressMeta = const VerificationMeta(
    'internalAddress',
  );
  @override
  late final GeneratedColumn<String> internalAddress = GeneratedColumn<String>(
    'internalAddress',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPairedMeta = const VerificationMeta(
    'isPaired',
  );
  @override
  late final GeneratedColumn<bool> isPaired = GeneratedColumn<bool>(
    'isPaired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("isPaired" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    guid,
    devName,
    uid,
    customName,
    type,
    address,
    internalAddress,
    isPaired,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Device';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('devName')) {
      context.handle(
        _devNameMeta,
        devName.isAcceptableOrUnknown(data['devName']!, _devNameMeta),
      );
    } else if (isInserting) {
      context.missing(_devNameMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('customName')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['customName']!, _customNameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('internalAddress')) {
      context.handle(
        _internalAddressMeta,
        internalAddress.isAcceptableOrUnknown(
          data['internalAddress']!,
          _internalAddressMeta,
        ),
      );
    }
    if (data.containsKey('isPaired')) {
      context.handle(
        _isPairedMeta,
        isPaired.isAcceptableOrUnknown(data['isPaired']!, _isPairedMeta),
      );
    } else if (isInserting) {
      context.missing(_isPairedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {guid};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      devName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devName'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      )!,
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customName'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      internalAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internalAddress'],
      ),
      isPaired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}isPaired'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String guid;
  final String devName;
  final int uid;
  final String? customName;
  final String type;
  final String? address;
  final String? internalAddress;
  final bool isPaired;
  const Device({
    required this.guid,
    required this.devName,
    required this.uid,
    this.customName,
    required this.type,
    this.address,
    this.internalAddress,
    required this.isPaired,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['guid'] = Variable<String>(guid);
    map['devName'] = Variable<String>(devName);
    map['uid'] = Variable<int>(uid);
    if (!nullToAbsent || customName != null) {
      map['customName'] = Variable<String>(customName);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || internalAddress != null) {
      map['internalAddress'] = Variable<String>(internalAddress);
    }
    map['isPaired'] = Variable<bool>(isPaired);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      guid: Value(guid),
      devName: Value(devName),
      uid: Value(uid),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      type: Value(type),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      internalAddress: internalAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(internalAddress),
      isPaired: Value(isPaired),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      guid: serializer.fromJson<String>(json['guid']),
      devName: serializer.fromJson<String>(json['devName']),
      uid: serializer.fromJson<int>(json['uid']),
      customName: serializer.fromJson<String?>(json['customName']),
      type: serializer.fromJson<String>(json['type']),
      address: serializer.fromJson<String?>(json['address']),
      internalAddress: serializer.fromJson<String?>(json['internalAddress']),
      isPaired: serializer.fromJson<bool>(json['isPaired']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'guid': serializer.toJson<String>(guid),
      'devName': serializer.toJson<String>(devName),
      'uid': serializer.toJson<int>(uid),
      'customName': serializer.toJson<String?>(customName),
      'type': serializer.toJson<String>(type),
      'address': serializer.toJson<String?>(address),
      'internalAddress': serializer.toJson<String?>(internalAddress),
      'isPaired': serializer.toJson<bool>(isPaired),
    };
  }

  Device copyWith({
    String? guid,
    String? devName,
    int? uid,
    Value<String?> customName = const Value.absent(),
    String? type,
    Value<String?> address = const Value.absent(),
    Value<String?> internalAddress = const Value.absent(),
    bool? isPaired,
  }) => Device(
    guid: guid ?? this.guid,
    devName: devName ?? this.devName,
    uid: uid ?? this.uid,
    customName: customName.present ? customName.value : this.customName,
    type: type ?? this.type,
    address: address.present ? address.value : this.address,
    internalAddress: internalAddress.present
        ? internalAddress.value
        : this.internalAddress,
    isPaired: isPaired ?? this.isPaired,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      guid: data.guid.present ? data.guid.value : this.guid,
      devName: data.devName.present ? data.devName.value : this.devName,
      uid: data.uid.present ? data.uid.value : this.uid,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      type: data.type.present ? data.type.value : this.type,
      address: data.address.present ? data.address.value : this.address,
      internalAddress: data.internalAddress.present
          ? data.internalAddress.value
          : this.internalAddress,
      isPaired: data.isPaired.present ? data.isPaired.value : this.isPaired,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('guid: $guid, ')
          ..write('devName: $devName, ')
          ..write('uid: $uid, ')
          ..write('customName: $customName, ')
          ..write('type: $type, ')
          ..write('address: $address, ')
          ..write('internalAddress: $internalAddress, ')
          ..write('isPaired: $isPaired')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    guid,
    devName,
    uid,
    customName,
    type,
    address,
    internalAddress,
    isPaired,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.guid == this.guid &&
          other.devName == this.devName &&
          other.uid == this.uid &&
          other.customName == this.customName &&
          other.type == this.type &&
          other.address == this.address &&
          other.internalAddress == this.internalAddress &&
          other.isPaired == this.isPaired);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> guid;
  final Value<String> devName;
  final Value<int> uid;
  final Value<String?> customName;
  final Value<String> type;
  final Value<String?> address;
  final Value<String?> internalAddress;
  final Value<bool> isPaired;
  final Value<int> rowid;
  const DevicesCompanion({
    this.guid = const Value.absent(),
    this.devName = const Value.absent(),
    this.uid = const Value.absent(),
    this.customName = const Value.absent(),
    this.type = const Value.absent(),
    this.address = const Value.absent(),
    this.internalAddress = const Value.absent(),
    this.isPaired = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String guid,
    required String devName,
    required int uid,
    this.customName = const Value.absent(),
    required String type,
    this.address = const Value.absent(),
    this.internalAddress = const Value.absent(),
    required bool isPaired,
    this.rowid = const Value.absent(),
  }) : guid = Value(guid),
       devName = Value(devName),
       uid = Value(uid),
       type = Value(type),
       isPaired = Value(isPaired);
  static Insertable<Device> custom({
    Expression<String>? guid,
    Expression<String>? devName,
    Expression<int>? uid,
    Expression<String>? customName,
    Expression<String>? type,
    Expression<String>? address,
    Expression<String>? internalAddress,
    Expression<bool>? isPaired,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (devName != null) 'devName': devName,
      if (uid != null) 'uid': uid,
      if (customName != null) 'customName': customName,
      if (type != null) 'type': type,
      if (address != null) 'address': address,
      if (internalAddress != null) 'internalAddress': internalAddress,
      if (isPaired != null) 'isPaired': isPaired,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? guid,
    Value<String>? devName,
    Value<int>? uid,
    Value<String?>? customName,
    Value<String>? type,
    Value<String?>? address,
    Value<String?>? internalAddress,
    Value<bool>? isPaired,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      guid: guid ?? this.guid,
      devName: devName ?? this.devName,
      uid: uid ?? this.uid,
      customName: customName ?? this.customName,
      type: type ?? this.type,
      address: address ?? this.address,
      internalAddress: internalAddress ?? this.internalAddress,
      isPaired: isPaired ?? this.isPaired,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (devName.present) {
      map['devName'] = Variable<String>(devName.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (customName.present) {
      map['customName'] = Variable<String>(customName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (internalAddress.present) {
      map['internalAddress'] = Variable<String>(internalAddress.value);
    }
    if (isPaired.present) {
      map['isPaired'] = Variable<bool>(isPaired.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('guid: $guid, ')
          ..write('devName: $devName, ')
          ..write('uid: $uid, ')
          ..write('customName: $customName, ')
          ..write('type: $type, ')
          ..write('address: $address, ')
          ..write('internalAddress: $internalAddress, ')
          ..write('isPaired: $isPaired, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, account, password, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'User';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    } else if (isInserting) {
      context.missing(_accountMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int? id;
  final String account;
  final String password;
  final String type;
  const User({
    this.id,
    required this.account,
    required this.password,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    map['account'] = Variable<String>(account);
    map['password'] = Variable<String>(password);
    map['type'] = Variable<String>(type);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      account: Value(account),
      password: Value(password),
      type: Value(type),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int?>(json['id']),
      account: serializer.fromJson<String>(json['account']),
      password: serializer.fromJson<String>(json['password']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'account': serializer.toJson<String>(account),
      'password': serializer.toJson<String>(password),
      'type': serializer.toJson<String>(type),
    };
  }

  User copyWith({
    Value<int?> id = const Value.absent(),
    String? account,
    String? password,
    String? type,
  }) => User(
    id: id.present ? id.value : this.id,
    account: account ?? this.account,
    password: password ?? this.password,
    type: type ?? this.type,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      account: data.account.present ? data.account.value : this.account,
      password: data.password.present ? data.password.value : this.password,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('account: $account, ')
          ..write('password: $password, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, account, password, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.account == this.account &&
          other.password == this.password &&
          other.type == this.type);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int?> id;
  final Value<String> account;
  final Value<String> password;
  final Value<String> type;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.account = const Value.absent(),
    this.password = const Value.absent(),
    this.type = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String account,
    required String password,
    required String type,
  }) : account = Value(account),
       password = Value(password),
       type = Value(type);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? account,
    Expression<String>? password,
    Expression<String>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (account != null) 'account': account,
      if (password != null) 'password': password,
      if (type != null) 'type': type,
    });
  }

  UsersCompanion copyWith({
    Value<int?>? id,
    Value<String>? account,
    Value<String>? password,
    Value<String>? type,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      account: account ?? this.account,
      password: password ?? this.password,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('account: $account, ')
          ..write('password: $password, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $OperationSyncsTable extends OperationSyncs
    with TableInfo<$OperationSyncsTable, OperationSync> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperationSyncsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<int> opId = GeneratedColumn<int>(
    'opId',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devIdMeta = const VerificationMeta('devId');
  @override
  late final GeneratedColumn<String> devId = GeneratedColumn<String>(
    'devId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [opId, devId, uid, time];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'OperationSync';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperationSync> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('opId')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['opId']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('devId')) {
      context.handle(
        _devIdMeta,
        devId.isAcceptableOrUnknown(data['devId']!, _devIdMeta),
      );
    } else if (isInserting) {
      context.missing(_devIdMeta);
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId, devId, uid};
  @override
  OperationSync map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperationSync(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opId'],
      )!,
      devId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devId'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      )!,
    );
  }

  @override
  $OperationSyncsTable createAlias(String alias) {
    return $OperationSyncsTable(attachedDatabase, alias);
  }
}

class OperationSync extends DataClass implements Insertable<OperationSync> {
  final int opId;
  final String devId;
  final int uid;
  final String time;
  const OperationSync({
    required this.opId,
    required this.devId,
    required this.uid,
    required this.time,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['opId'] = Variable<int>(opId);
    map['devId'] = Variable<String>(devId);
    map['uid'] = Variable<int>(uid);
    map['time'] = Variable<String>(time);
    return map;
  }

  OperationSyncsCompanion toCompanion(bool nullToAbsent) {
    return OperationSyncsCompanion(
      opId: Value(opId),
      devId: Value(devId),
      uid: Value(uid),
      time: Value(time),
    );
  }

  factory OperationSync.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperationSync(
      opId: serializer.fromJson<int>(json['opId']),
      devId: serializer.fromJson<String>(json['devId']),
      uid: serializer.fromJson<int>(json['uid']),
      time: serializer.fromJson<String>(json['time']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<int>(opId),
      'devId': serializer.toJson<String>(devId),
      'uid': serializer.toJson<int>(uid),
      'time': serializer.toJson<String>(time),
    };
  }

  OperationSync copyWith({int? opId, String? devId, int? uid, String? time}) =>
      OperationSync(
        opId: opId ?? this.opId,
        devId: devId ?? this.devId,
        uid: uid ?? this.uid,
        time: time ?? this.time,
      );
  OperationSync copyWithCompanion(OperationSyncsCompanion data) {
    return OperationSync(
      opId: data.opId.present ? data.opId.value : this.opId,
      devId: data.devId.present ? data.devId.value : this.devId,
      uid: data.uid.present ? data.uid.value : this.uid,
      time: data.time.present ? data.time.value : this.time,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperationSync(')
          ..write('opId: $opId, ')
          ..write('devId: $devId, ')
          ..write('uid: $uid, ')
          ..write('time: $time')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(opId, devId, uid, time);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperationSync &&
          other.opId == this.opId &&
          other.devId == this.devId &&
          other.uid == this.uid &&
          other.time == this.time);
}

class OperationSyncsCompanion extends UpdateCompanion<OperationSync> {
  final Value<int> opId;
  final Value<String> devId;
  final Value<int> uid;
  final Value<String> time;
  final Value<int> rowid;
  const OperationSyncsCompanion({
    this.opId = const Value.absent(),
    this.devId = const Value.absent(),
    this.uid = const Value.absent(),
    this.time = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperationSyncsCompanion.insert({
    required int opId,
    required String devId,
    required int uid,
    required String time,
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       devId = Value(devId),
       uid = Value(uid),
       time = Value(time);
  static Insertable<OperationSync> custom({
    Expression<int>? opId,
    Expression<String>? devId,
    Expression<int>? uid,
    Expression<String>? time,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'opId': opId,
      if (devId != null) 'devId': devId,
      if (uid != null) 'uid': uid,
      if (time != null) 'time': time,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperationSyncsCompanion copyWith({
    Value<int>? opId,
    Value<String>? devId,
    Value<int>? uid,
    Value<String>? time,
    Value<int>? rowid,
  }) {
    return OperationSyncsCompanion(
      opId: opId ?? this.opId,
      devId: devId ?? this.devId,
      uid: uid ?? this.uid,
      time: time ?? this.time,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['opId'] = Variable<int>(opId.value);
    }
    if (devId.present) {
      map['devId'] = Variable<String>(devId.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperationSyncsCompanion(')
          ..write('opId: $opId, ')
          ..write('devId: $devId, ')
          ..write('uid: $uid, ')
          ..write('time: $time, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperationRecordsTable extends OperationRecords
    with TableInfo<$OperationRecordsTable, OperationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperationRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<int> uid = GeneratedColumn<int>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devIdMeta = const VerificationMeta('devId');
  @override
  late final GeneratedColumn<String> devId = GeneratedColumn<String>(
    'devId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Module, String> module =
      GeneratedColumn<String>(
        'module',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Module>($OperationRecordsTable.$convertermodule);
  static const VerificationMeta _moduleEnMeta = const VerificationMeta(
    'moduleEn',
  );
  @override
  late final GeneratedColumn<String> moduleEn = GeneratedColumn<String>(
    'moduleEn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OpMethod, String> method =
      GeneratedColumn<String>(
        'method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OpMethod>($OperationRecordsTable.$convertermethod);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageSyncMeta = const VerificationMeta(
    'storageSync',
  );
  @override
  late final GeneratedColumn<bool> storageSync = GeneratedColumn<bool>(
    'storageSync',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("storageSync" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uid,
    devId,
    module,
    moduleEn,
    method,
    data,
    time,
    storageSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'OperationRecord';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('devId')) {
      context.handle(
        _devIdMeta,
        devId.isAcceptableOrUnknown(data['devId']!, _devIdMeta),
      );
    } else if (isInserting) {
      context.missing(_devIdMeta);
    }
    if (data.containsKey('moduleEn')) {
      context.handle(
        _moduleEnMeta,
        moduleEn.isAcceptableOrUnknown(data['moduleEn']!, _moduleEnMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('storageSync')) {
      context.handle(
        _storageSyncMeta,
        storageSync.isAcceptableOrUnknown(
          data['storageSync']!,
          _storageSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OperationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uid'],
      )!,
      devId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devId'],
      )!,
      module: $OperationRecordsTable.$convertermodule.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}module'],
        )!,
      ),
      moduleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moduleEn'],
      ),
      method: $OperationRecordsTable.$convertermethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}method'],
        )!,
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      )!,
      storageSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}storageSync'],
      ),
    );
  }

  @override
  $OperationRecordsTable createAlias(String alias) {
    return $OperationRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<Module, String> $convertermodule =
      const ModuleTypeConverter();
  static TypeConverter<OpMethod, String> $convertermethod =
      const OpMethodTypeConverter();
}

class OperationRecord extends DataClass implements Insertable<OperationRecord> {
  final int id;
  final int uid;
  final String devId;
  final Module module;
  final String? moduleEn;
  final OpMethod method;
  final String data;
  final String time;
  final bool? storageSync;
  const OperationRecord({
    required this.id,
    required this.uid,
    required this.devId,
    required this.module,
    this.moduleEn,
    required this.method,
    required this.data,
    required this.time,
    this.storageSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uid'] = Variable<int>(uid);
    map['devId'] = Variable<String>(devId);
    {
      map['module'] = Variable<String>(
        $OperationRecordsTable.$convertermodule.toSql(module),
      );
    }
    if (!nullToAbsent || moduleEn != null) {
      map['moduleEn'] = Variable<String>(moduleEn);
    }
    {
      map['method'] = Variable<String>(
        $OperationRecordsTable.$convertermethod.toSql(method),
      );
    }
    map['data'] = Variable<String>(data);
    map['time'] = Variable<String>(time);
    if (!nullToAbsent || storageSync != null) {
      map['storageSync'] = Variable<bool>(storageSync);
    }
    return map;
  }

  OperationRecordsCompanion toCompanion(bool nullToAbsent) {
    return OperationRecordsCompanion(
      id: Value(id),
      uid: Value(uid),
      devId: Value(devId),
      module: Value(module),
      moduleEn: moduleEn == null && nullToAbsent
          ? const Value.absent()
          : Value(moduleEn),
      method: Value(method),
      data: Value(data),
      time: Value(time),
      storageSync: storageSync == null && nullToAbsent
          ? const Value.absent()
          : Value(storageSync),
    );
  }

  factory OperationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperationRecord(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<int>(json['uid']),
      devId: serializer.fromJson<String>(json['devId']),
      module: serializer.fromJson<Module>(json['module']),
      moduleEn: serializer.fromJson<String?>(json['moduleEn']),
      method: serializer.fromJson<OpMethod>(json['method']),
      data: serializer.fromJson<String>(json['data']),
      time: serializer.fromJson<String>(json['time']),
      storageSync: serializer.fromJson<bool?>(json['storageSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<int>(uid),
      'devId': serializer.toJson<String>(devId),
      'module': serializer.toJson<Module>(module),
      'moduleEn': serializer.toJson<String?>(moduleEn),
      'method': serializer.toJson<OpMethod>(method),
      'data': serializer.toJson<String>(data),
      'time': serializer.toJson<String>(time),
      'storageSync': serializer.toJson<bool?>(storageSync),
    };
  }

  OperationRecord copyWith({
    int? id,
    int? uid,
    String? devId,
    Module? module,
    Value<String?> moduleEn = const Value.absent(),
    OpMethod? method,
    String? data,
    String? time,
    Value<bool?> storageSync = const Value.absent(),
  }) => OperationRecord(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    devId: devId ?? this.devId,
    module: module ?? this.module,
    moduleEn: moduleEn.present ? moduleEn.value : this.moduleEn,
    method: method ?? this.method,
    data: data ?? this.data,
    time: time ?? this.time,
    storageSync: storageSync.present ? storageSync.value : this.storageSync,
  );
  OperationRecord copyWithCompanion(OperationRecordsCompanion data) {
    return OperationRecord(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      devId: data.devId.present ? data.devId.value : this.devId,
      module: data.module.present ? data.module.value : this.module,
      moduleEn: data.moduleEn.present ? data.moduleEn.value : this.moduleEn,
      method: data.method.present ? data.method.value : this.method,
      data: data.data.present ? data.data.value : this.data,
      time: data.time.present ? data.time.value : this.time,
      storageSync: data.storageSync.present
          ? data.storageSync.value
          : this.storageSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperationRecord(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('devId: $devId, ')
          ..write('module: $module, ')
          ..write('moduleEn: $moduleEn, ')
          ..write('method: $method, ')
          ..write('data: $data, ')
          ..write('time: $time, ')
          ..write('storageSync: $storageSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    devId,
    module,
    moduleEn,
    method,
    data,
    time,
    storageSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperationRecord &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.devId == this.devId &&
          other.module == this.module &&
          other.moduleEn == this.moduleEn &&
          other.method == this.method &&
          other.data == this.data &&
          other.time == this.time &&
          other.storageSync == this.storageSync);
}

class OperationRecordsCompanion extends UpdateCompanion<OperationRecord> {
  final Value<int> id;
  final Value<int> uid;
  final Value<String> devId;
  final Value<Module> module;
  final Value<String?> moduleEn;
  final Value<OpMethod> method;
  final Value<String> data;
  final Value<String> time;
  final Value<bool?> storageSync;
  const OperationRecordsCompanion({
    this.id = const Value.absent(),
    this.uid = const Value.absent(),
    this.devId = const Value.absent(),
    this.module = const Value.absent(),
    this.moduleEn = const Value.absent(),
    this.method = const Value.absent(),
    this.data = const Value.absent(),
    this.time = const Value.absent(),
    this.storageSync = const Value.absent(),
  });
  OperationRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int uid,
    required String devId,
    required Module module,
    this.moduleEn = const Value.absent(),
    required OpMethod method,
    required String data,
    required String time,
    this.storageSync = const Value.absent(),
  }) : uid = Value(uid),
       devId = Value(devId),
       module = Value(module),
       method = Value(method),
       data = Value(data),
       time = Value(time);
  static Insertable<OperationRecord> custom({
    Expression<int>? id,
    Expression<int>? uid,
    Expression<String>? devId,
    Expression<String>? module,
    Expression<String>? moduleEn,
    Expression<String>? method,
    Expression<String>? data,
    Expression<String>? time,
    Expression<bool>? storageSync,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (devId != null) 'devId': devId,
      if (module != null) 'module': module,
      if (moduleEn != null) 'moduleEn': moduleEn,
      if (method != null) 'method': method,
      if (data != null) 'data': data,
      if (time != null) 'time': time,
      if (storageSync != null) 'storageSync': storageSync,
    });
  }

  OperationRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? uid,
    Value<String>? devId,
    Value<Module>? module,
    Value<String?>? moduleEn,
    Value<OpMethod>? method,
    Value<String>? data,
    Value<String>? time,
    Value<bool?>? storageSync,
  }) {
    return OperationRecordsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      devId: devId ?? this.devId,
      module: module ?? this.module,
      moduleEn: moduleEn ?? this.moduleEn,
      method: method ?? this.method,
      data: data ?? this.data,
      time: time ?? this.time,
      storageSync: storageSync ?? this.storageSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = Variable<int>(uid.value);
    }
    if (devId.present) {
      map['devId'] = Variable<String>(devId.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(
        $OperationRecordsTable.$convertermodule.toSql(module.value),
      );
    }
    if (moduleEn.present) {
      map['moduleEn'] = Variable<String>(moduleEn.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(
        $OperationRecordsTable.$convertermethod.toSql(method.value),
      );
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (storageSync.present) {
      map['storageSync'] = Variable<bool>(storageSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperationRecordsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('devId: $devId, ')
          ..write('module: $module, ')
          ..write('moduleEn: $moduleEn, ')
          ..write('method: $method, ')
          ..write('data: $data, ')
          ..write('time: $time, ')
          ..write('storageSync: $storageSync')
          ..write(')'))
        .toString();
  }
}

class $AppInfosTable extends AppInfos with TableInfo<$AppInfosTable, AppInfo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppInfosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
    'appId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devIdMeta = const VerificationMeta('devId');
  @override
  late final GeneratedColumn<String> devId = GeneratedColumn<String>(
    'devId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconB64Meta = const VerificationMeta(
    'iconB64',
  );
  @override
  late final GeneratedColumn<String> iconB64 = GeneratedColumn<String>(
    'iconB64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, appId, devId, name, iconB64];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'AppInfo';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppInfo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('appId')) {
      context.handle(
        _appIdMeta,
        appId.isAcceptableOrUnknown(data['appId']!, _appIdMeta),
      );
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('devId')) {
      context.handle(
        _devIdMeta,
        devId.isAcceptableOrUnknown(data['devId']!, _devIdMeta),
      );
    } else if (isInserting) {
      context.missing(_devIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('iconB64')) {
      context.handle(
        _iconB64Meta,
        iconB64.isAcceptableOrUnknown(data['iconB64']!, _iconB64Meta),
      );
    } else if (isInserting) {
      context.missing(_iconB64Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppInfo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppInfo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      appId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appId'],
      )!,
      devId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devId'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconB64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iconB64'],
      )!,
    );
  }

  @override
  $AppInfosTable createAlias(String alias) {
    return $AppInfosTable(attachedDatabase, alias);
  }
}

class AppInfo extends DataClass implements Insertable<AppInfo> {
  final int id;
  final String appId;
  final String devId;
  final String name;
  final String iconB64;
  const AppInfo({
    required this.id,
    required this.appId,
    required this.devId,
    required this.name,
    required this.iconB64,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['appId'] = Variable<String>(appId);
    map['devId'] = Variable<String>(devId);
    map['name'] = Variable<String>(name);
    map['iconB64'] = Variable<String>(iconB64);
    return map;
  }

  AppInfosCompanion toCompanion(bool nullToAbsent) {
    return AppInfosCompanion(
      id: Value(id),
      appId: Value(appId),
      devId: Value(devId),
      name: Value(name),
      iconB64: Value(iconB64),
    );
  }

  factory AppInfo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppInfo(
      id: serializer.fromJson<int>(json['id']),
      appId: serializer.fromJson<String>(json['appId']),
      devId: serializer.fromJson<String>(json['devId']),
      name: serializer.fromJson<String>(json['name']),
      iconB64: serializer.fromJson<String>(json['iconB64']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'appId': serializer.toJson<String>(appId),
      'devId': serializer.toJson<String>(devId),
      'name': serializer.toJson<String>(name),
      'iconB64': serializer.toJson<String>(iconB64),
    };
  }

  AppInfo copyWith({
    int? id,
    String? appId,
    String? devId,
    String? name,
    String? iconB64,
  }) => AppInfo(
    id: id ?? this.id,
    appId: appId ?? this.appId,
    devId: devId ?? this.devId,
    name: name ?? this.name,
    iconB64: iconB64 ?? this.iconB64,
  );
  AppInfo copyWithCompanion(AppInfosCompanion data) {
    return AppInfo(
      id: data.id.present ? data.id.value : this.id,
      appId: data.appId.present ? data.appId.value : this.appId,
      devId: data.devId.present ? data.devId.value : this.devId,
      name: data.name.present ? data.name.value : this.name,
      iconB64: data.iconB64.present ? data.iconB64.value : this.iconB64,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppInfo(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('devId: $devId, ')
          ..write('name: $name, ')
          ..write('iconB64: $iconB64')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appId, devId, name, iconB64);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppInfo &&
          other.id == this.id &&
          other.appId == this.appId &&
          other.devId == this.devId &&
          other.name == this.name &&
          other.iconB64 == this.iconB64);
}

class AppInfosCompanion extends UpdateCompanion<AppInfo> {
  final Value<int> id;
  final Value<String> appId;
  final Value<String> devId;
  final Value<String> name;
  final Value<String> iconB64;
  const AppInfosCompanion({
    this.id = const Value.absent(),
    this.appId = const Value.absent(),
    this.devId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconB64 = const Value.absent(),
  });
  AppInfosCompanion.insert({
    this.id = const Value.absent(),
    required String appId,
    required String devId,
    required String name,
    required String iconB64,
  }) : appId = Value(appId),
       devId = Value(devId),
       name = Value(name),
       iconB64 = Value(iconB64);
  static Insertable<AppInfo> custom({
    Expression<int>? id,
    Expression<String>? appId,
    Expression<String>? devId,
    Expression<String>? name,
    Expression<String>? iconB64,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appId != null) 'appId': appId,
      if (devId != null) 'devId': devId,
      if (name != null) 'name': name,
      if (iconB64 != null) 'iconB64': iconB64,
    });
  }

  AppInfosCompanion copyWith({
    Value<int>? id,
    Value<String>? appId,
    Value<String>? devId,
    Value<String>? name,
    Value<String>? iconB64,
  }) {
    return AppInfosCompanion(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      devId: devId ?? this.devId,
      name: name ?? this.name,
      iconB64: iconB64 ?? this.iconB64,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (appId.present) {
      map['appId'] = Variable<String>(appId.value);
    }
    if (devId.present) {
      map['devId'] = Variable<String>(devId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconB64.present) {
      map['iconB64'] = Variable<String>(iconB64.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppInfosCompanion(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('devId: $devId, ')
          ..write('name: $name, ')
          ..write('iconB64: $iconB64')
          ..write(')'))
        .toString();
  }
}

class $RulesTable extends Rules with TableInfo<$RulesTable, Rule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformsMeta = const VerificationMeta(
    'platforms',
  );
  @override
  late final GeneratedColumn<String> platforms = GeneratedColumn<String>(
    'platforms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcesMeta = const VerificationMeta(
    'sources',
  );
  @override
  late final GeneratedColumn<String> sources = GeneratedColumn<String>(
    'sources',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regexWhiteBlackModeMeta =
      const VerificationMeta('regexWhiteBlackMode');
  @override
  late final GeneratedColumn<String> regexWhiteBlackMode =
      GeneratedColumn<String>(
        'regexWhiteBlackMode',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _regexMainMeta = const VerificationMeta(
    'regexMain',
  );
  @override
  late final GeneratedColumn<String> regexMain = GeneratedColumn<String>(
    'regexMain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regexAllowExtractDataMeta =
      const VerificationMeta('regexAllowExtractData');
  @override
  late final GeneratedColumn<bool> regexAllowExtractData =
      GeneratedColumn<bool>(
        'regexAllowExtractData',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("regexAllowExtractData" IN (0, 1))',
        ),
      );
  static const VerificationMeta _regexExtractedContentMeta =
      const VerificationMeta('regexExtractedContent');
  @override
  late final GeneratedColumn<String> regexExtractedContent =
      GeneratedColumn<String>(
        'regexExtractedContent',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _regexAllowAddTagMeta = const VerificationMeta(
    'regexAllowAddTag',
  );
  @override
  late final GeneratedColumn<bool> regexAllowAddTag = GeneratedColumn<bool>(
    'regexAllowAddTag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("regexAllowAddTag" IN (0, 1))',
    ),
  );
  static const VerificationMeta _regexTagsMeta = const VerificationMeta(
    'regexTags',
  );
  @override
  late final GeneratedColumn<String> regexTags = GeneratedColumn<String>(
    'regexTags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regexIsSyncDisabledMeta =
      const VerificationMeta('regexIsSyncDisabled');
  @override
  late final GeneratedColumn<bool> regexIsSyncDisabled = GeneratedColumn<bool>(
    'regexIsSyncDisabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("regexIsSyncDisabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _regexIsFinalRuleMeta = const VerificationMeta(
    'regexIsFinalRule',
  );
  @override
  late final GeneratedColumn<bool> regexIsFinalRule = GeneratedColumn<bool>(
    'regexIsFinalRule',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("regexIsFinalRule" IN (0, 1))',
    ),
  );
  static const VerificationMeta _scriptLanguageMeta = const VerificationMeta(
    'scriptLanguage',
  );
  @override
  late final GeneratedColumn<String> scriptLanguage = GeneratedColumn<String>(
    'scriptLanguage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scriptContentMeta = const VerificationMeta(
    'scriptContent',
  );
  @override
  late final GeneratedColumn<String> scriptContent = GeneratedColumn<String>(
    'scriptContent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    platforms,
    sources,
    trigger,
    type,
    regexWhiteBlackMode,
    regexMain,
    regexAllowExtractData,
    regexExtractedContent,
    regexAllowAddTag,
    regexTags,
    regexIsSyncDisabled,
    regexIsFinalRule,
    scriptLanguage,
    scriptContent,
    version,
    enabled,
    order,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Rule';
  @override
  VerificationContext validateIntegrity(
    Insertable<Rule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('platforms')) {
      context.handle(
        _platformsMeta,
        platforms.isAcceptableOrUnknown(data['platforms']!, _platformsMeta),
      );
    } else if (isInserting) {
      context.missing(_platformsMeta);
    }
    if (data.containsKey('sources')) {
      context.handle(
        _sourcesMeta,
        sources.isAcceptableOrUnknown(data['sources']!, _sourcesMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcesMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('regexWhiteBlackMode')) {
      context.handle(
        _regexWhiteBlackModeMeta,
        regexWhiteBlackMode.isAcceptableOrUnknown(
          data['regexWhiteBlackMode']!,
          _regexWhiteBlackModeMeta,
        ),
      );
    }
    if (data.containsKey('regexMain')) {
      context.handle(
        _regexMainMeta,
        regexMain.isAcceptableOrUnknown(data['regexMain']!, _regexMainMeta),
      );
    } else if (isInserting) {
      context.missing(_regexMainMeta);
    }
    if (data.containsKey('regexAllowExtractData')) {
      context.handle(
        _regexAllowExtractDataMeta,
        regexAllowExtractData.isAcceptableOrUnknown(
          data['regexAllowExtractData']!,
          _regexAllowExtractDataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regexAllowExtractDataMeta);
    }
    if (data.containsKey('regexExtractedContent')) {
      context.handle(
        _regexExtractedContentMeta,
        regexExtractedContent.isAcceptableOrUnknown(
          data['regexExtractedContent']!,
          _regexExtractedContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regexExtractedContentMeta);
    }
    if (data.containsKey('regexAllowAddTag')) {
      context.handle(
        _regexAllowAddTagMeta,
        regexAllowAddTag.isAcceptableOrUnknown(
          data['regexAllowAddTag']!,
          _regexAllowAddTagMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regexAllowAddTagMeta);
    }
    if (data.containsKey('regexTags')) {
      context.handle(
        _regexTagsMeta,
        regexTags.isAcceptableOrUnknown(data['regexTags']!, _regexTagsMeta),
      );
    } else if (isInserting) {
      context.missing(_regexTagsMeta);
    }
    if (data.containsKey('regexIsSyncDisabled')) {
      context.handle(
        _regexIsSyncDisabledMeta,
        regexIsSyncDisabled.isAcceptableOrUnknown(
          data['regexIsSyncDisabled']!,
          _regexIsSyncDisabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regexIsSyncDisabledMeta);
    }
    if (data.containsKey('regexIsFinalRule')) {
      context.handle(
        _regexIsFinalRuleMeta,
        regexIsFinalRule.isAcceptableOrUnknown(
          data['regexIsFinalRule']!,
          _regexIsFinalRuleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regexIsFinalRuleMeta);
    }
    if (data.containsKey('scriptLanguage')) {
      context.handle(
        _scriptLanguageMeta,
        scriptLanguage.isAcceptableOrUnknown(
          data['scriptLanguage']!,
          _scriptLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scriptLanguageMeta);
    }
    if (data.containsKey('scriptContent')) {
      context.handle(
        _scriptContentMeta,
        scriptContent.isAcceptableOrUnknown(
          data['scriptContent']!,
          _scriptContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scriptContentMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Rule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      platforms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platforms'],
      )!,
      sources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      regexWhiteBlackMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regexWhiteBlackMode'],
      ),
      regexMain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regexMain'],
      )!,
      regexAllowExtractData: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}regexAllowExtractData'],
      )!,
      regexExtractedContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regexExtractedContent'],
      )!,
      regexAllowAddTag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}regexAllowAddTag'],
      )!,
      regexTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regexTags'],
      )!,
      regexIsSyncDisabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}regexIsSyncDisabled'],
      )!,
      regexIsFinalRule: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}regexIsFinalRule'],
      )!,
      scriptLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scriptLanguage'],
      )!,
      scriptContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scriptContent'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
    );
  }

  @override
  $RulesTable createAlias(String alias) {
    return $RulesTable(attachedDatabase, alias);
  }
}

class Rule extends DataClass implements Insertable<Rule> {
  final int id;
  final String name;
  final String platforms;
  final String sources;
  final String trigger;
  final String type;
  final String? regexWhiteBlackMode;
  final String regexMain;
  final bool regexAllowExtractData;
  final String regexExtractedContent;
  final bool regexAllowAddTag;
  final String regexTags;
  final bool regexIsSyncDisabled;
  final bool regexIsFinalRule;
  final String scriptLanguage;
  final String scriptContent;
  final int version;
  final bool enabled;
  final int order;
  const Rule({
    required this.id,
    required this.name,
    required this.platforms,
    required this.sources,
    required this.trigger,
    required this.type,
    this.regexWhiteBlackMode,
    required this.regexMain,
    required this.regexAllowExtractData,
    required this.regexExtractedContent,
    required this.regexAllowAddTag,
    required this.regexTags,
    required this.regexIsSyncDisabled,
    required this.regexIsFinalRule,
    required this.scriptLanguage,
    required this.scriptContent,
    required this.version,
    required this.enabled,
    required this.order,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['platforms'] = Variable<String>(platforms);
    map['sources'] = Variable<String>(sources);
    map['trigger'] = Variable<String>(trigger);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || regexWhiteBlackMode != null) {
      map['regexWhiteBlackMode'] = Variable<String>(regexWhiteBlackMode);
    }
    map['regexMain'] = Variable<String>(regexMain);
    map['regexAllowExtractData'] = Variable<bool>(regexAllowExtractData);
    map['regexExtractedContent'] = Variable<String>(regexExtractedContent);
    map['regexAllowAddTag'] = Variable<bool>(regexAllowAddTag);
    map['regexTags'] = Variable<String>(regexTags);
    map['regexIsSyncDisabled'] = Variable<bool>(regexIsSyncDisabled);
    map['regexIsFinalRule'] = Variable<bool>(regexIsFinalRule);
    map['scriptLanguage'] = Variable<String>(scriptLanguage);
    map['scriptContent'] = Variable<String>(scriptContent);
    map['version'] = Variable<int>(version);
    map['enabled'] = Variable<bool>(enabled);
    map['order'] = Variable<int>(order);
    return map;
  }

  RulesCompanion toCompanion(bool nullToAbsent) {
    return RulesCompanion(
      id: Value(id),
      name: Value(name),
      platforms: Value(platforms),
      sources: Value(sources),
      trigger: Value(trigger),
      type: Value(type),
      regexWhiteBlackMode: regexWhiteBlackMode == null && nullToAbsent
          ? const Value.absent()
          : Value(regexWhiteBlackMode),
      regexMain: Value(regexMain),
      regexAllowExtractData: Value(regexAllowExtractData),
      regexExtractedContent: Value(regexExtractedContent),
      regexAllowAddTag: Value(regexAllowAddTag),
      regexTags: Value(regexTags),
      regexIsSyncDisabled: Value(regexIsSyncDisabled),
      regexIsFinalRule: Value(regexIsFinalRule),
      scriptLanguage: Value(scriptLanguage),
      scriptContent: Value(scriptContent),
      version: Value(version),
      enabled: Value(enabled),
      order: Value(order),
    );
  }

  factory Rule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rule(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      platforms: serializer.fromJson<String>(json['platforms']),
      sources: serializer.fromJson<String>(json['sources']),
      trigger: serializer.fromJson<String>(json['trigger']),
      type: serializer.fromJson<String>(json['type']),
      regexWhiteBlackMode: serializer.fromJson<String?>(
        json['regexWhiteBlackMode'],
      ),
      regexMain: serializer.fromJson<String>(json['regexMain']),
      regexAllowExtractData: serializer.fromJson<bool>(
        json['regexAllowExtractData'],
      ),
      regexExtractedContent: serializer.fromJson<String>(
        json['regexExtractedContent'],
      ),
      regexAllowAddTag: serializer.fromJson<bool>(json['regexAllowAddTag']),
      regexTags: serializer.fromJson<String>(json['regexTags']),
      regexIsSyncDisabled: serializer.fromJson<bool>(
        json['regexIsSyncDisabled'],
      ),
      regexIsFinalRule: serializer.fromJson<bool>(json['regexIsFinalRule']),
      scriptLanguage: serializer.fromJson<String>(json['scriptLanguage']),
      scriptContent: serializer.fromJson<String>(json['scriptContent']),
      version: serializer.fromJson<int>(json['version']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'platforms': serializer.toJson<String>(platforms),
      'sources': serializer.toJson<String>(sources),
      'trigger': serializer.toJson<String>(trigger),
      'type': serializer.toJson<String>(type),
      'regexWhiteBlackMode': serializer.toJson<String?>(regexWhiteBlackMode),
      'regexMain': serializer.toJson<String>(regexMain),
      'regexAllowExtractData': serializer.toJson<bool>(regexAllowExtractData),
      'regexExtractedContent': serializer.toJson<String>(regexExtractedContent),
      'regexAllowAddTag': serializer.toJson<bool>(regexAllowAddTag),
      'regexTags': serializer.toJson<String>(regexTags),
      'regexIsSyncDisabled': serializer.toJson<bool>(regexIsSyncDisabled),
      'regexIsFinalRule': serializer.toJson<bool>(regexIsFinalRule),
      'scriptLanguage': serializer.toJson<String>(scriptLanguage),
      'scriptContent': serializer.toJson<String>(scriptContent),
      'version': serializer.toJson<int>(version),
      'enabled': serializer.toJson<bool>(enabled),
      'order': serializer.toJson<int>(order),
    };
  }

  Rule copyWith({
    int? id,
    String? name,
    String? platforms,
    String? sources,
    String? trigger,
    String? type,
    Value<String?> regexWhiteBlackMode = const Value.absent(),
    String? regexMain,
    bool? regexAllowExtractData,
    String? regexExtractedContent,
    bool? regexAllowAddTag,
    String? regexTags,
    bool? regexIsSyncDisabled,
    bool? regexIsFinalRule,
    String? scriptLanguage,
    String? scriptContent,
    int? version,
    bool? enabled,
    int? order,
  }) => Rule(
    id: id ?? this.id,
    name: name ?? this.name,
    platforms: platforms ?? this.platforms,
    sources: sources ?? this.sources,
    trigger: trigger ?? this.trigger,
    type: type ?? this.type,
    regexWhiteBlackMode: regexWhiteBlackMode.present
        ? regexWhiteBlackMode.value
        : this.regexWhiteBlackMode,
    regexMain: regexMain ?? this.regexMain,
    regexAllowExtractData: regexAllowExtractData ?? this.regexAllowExtractData,
    regexExtractedContent: regexExtractedContent ?? this.regexExtractedContent,
    regexAllowAddTag: regexAllowAddTag ?? this.regexAllowAddTag,
    regexTags: regexTags ?? this.regexTags,
    regexIsSyncDisabled: regexIsSyncDisabled ?? this.regexIsSyncDisabled,
    regexIsFinalRule: regexIsFinalRule ?? this.regexIsFinalRule,
    scriptLanguage: scriptLanguage ?? this.scriptLanguage,
    scriptContent: scriptContent ?? this.scriptContent,
    version: version ?? this.version,
    enabled: enabled ?? this.enabled,
    order: order ?? this.order,
  );
  Rule copyWithCompanion(RulesCompanion data) {
    return Rule(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      platforms: data.platforms.present ? data.platforms.value : this.platforms,
      sources: data.sources.present ? data.sources.value : this.sources,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      type: data.type.present ? data.type.value : this.type,
      regexWhiteBlackMode: data.regexWhiteBlackMode.present
          ? data.regexWhiteBlackMode.value
          : this.regexWhiteBlackMode,
      regexMain: data.regexMain.present ? data.regexMain.value : this.regexMain,
      regexAllowExtractData: data.regexAllowExtractData.present
          ? data.regexAllowExtractData.value
          : this.regexAllowExtractData,
      regexExtractedContent: data.regexExtractedContent.present
          ? data.regexExtractedContent.value
          : this.regexExtractedContent,
      regexAllowAddTag: data.regexAllowAddTag.present
          ? data.regexAllowAddTag.value
          : this.regexAllowAddTag,
      regexTags: data.regexTags.present ? data.regexTags.value : this.regexTags,
      regexIsSyncDisabled: data.regexIsSyncDisabled.present
          ? data.regexIsSyncDisabled.value
          : this.regexIsSyncDisabled,
      regexIsFinalRule: data.regexIsFinalRule.present
          ? data.regexIsFinalRule.value
          : this.regexIsFinalRule,
      scriptLanguage: data.scriptLanguage.present
          ? data.scriptLanguage.value
          : this.scriptLanguage,
      scriptContent: data.scriptContent.present
          ? data.scriptContent.value
          : this.scriptContent,
      version: data.version.present ? data.version.value : this.version,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rule(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('platforms: $platforms, ')
          ..write('sources: $sources, ')
          ..write('trigger: $trigger, ')
          ..write('type: $type, ')
          ..write('regexWhiteBlackMode: $regexWhiteBlackMode, ')
          ..write('regexMain: $regexMain, ')
          ..write('regexAllowExtractData: $regexAllowExtractData, ')
          ..write('regexExtractedContent: $regexExtractedContent, ')
          ..write('regexAllowAddTag: $regexAllowAddTag, ')
          ..write('regexTags: $regexTags, ')
          ..write('regexIsSyncDisabled: $regexIsSyncDisabled, ')
          ..write('regexIsFinalRule: $regexIsFinalRule, ')
          ..write('scriptLanguage: $scriptLanguage, ')
          ..write('scriptContent: $scriptContent, ')
          ..write('version: $version, ')
          ..write('enabled: $enabled, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    platforms,
    sources,
    trigger,
    type,
    regexWhiteBlackMode,
    regexMain,
    regexAllowExtractData,
    regexExtractedContent,
    regexAllowAddTag,
    regexTags,
    regexIsSyncDisabled,
    regexIsFinalRule,
    scriptLanguage,
    scriptContent,
    version,
    enabled,
    order,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rule &&
          other.id == this.id &&
          other.name == this.name &&
          other.platforms == this.platforms &&
          other.sources == this.sources &&
          other.trigger == this.trigger &&
          other.type == this.type &&
          other.regexWhiteBlackMode == this.regexWhiteBlackMode &&
          other.regexMain == this.regexMain &&
          other.regexAllowExtractData == this.regexAllowExtractData &&
          other.regexExtractedContent == this.regexExtractedContent &&
          other.regexAllowAddTag == this.regexAllowAddTag &&
          other.regexTags == this.regexTags &&
          other.regexIsSyncDisabled == this.regexIsSyncDisabled &&
          other.regexIsFinalRule == this.regexIsFinalRule &&
          other.scriptLanguage == this.scriptLanguage &&
          other.scriptContent == this.scriptContent &&
          other.version == this.version &&
          other.enabled == this.enabled &&
          other.order == this.order);
}

class RulesCompanion extends UpdateCompanion<Rule> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> platforms;
  final Value<String> sources;
  final Value<String> trigger;
  final Value<String> type;
  final Value<String?> regexWhiteBlackMode;
  final Value<String> regexMain;
  final Value<bool> regexAllowExtractData;
  final Value<String> regexExtractedContent;
  final Value<bool> regexAllowAddTag;
  final Value<String> regexTags;
  final Value<bool> regexIsSyncDisabled;
  final Value<bool> regexIsFinalRule;
  final Value<String> scriptLanguage;
  final Value<String> scriptContent;
  final Value<int> version;
  final Value<bool> enabled;
  final Value<int> order;
  const RulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.platforms = const Value.absent(),
    this.sources = const Value.absent(),
    this.trigger = const Value.absent(),
    this.type = const Value.absent(),
    this.regexWhiteBlackMode = const Value.absent(),
    this.regexMain = const Value.absent(),
    this.regexAllowExtractData = const Value.absent(),
    this.regexExtractedContent = const Value.absent(),
    this.regexAllowAddTag = const Value.absent(),
    this.regexTags = const Value.absent(),
    this.regexIsSyncDisabled = const Value.absent(),
    this.regexIsFinalRule = const Value.absent(),
    this.scriptLanguage = const Value.absent(),
    this.scriptContent = const Value.absent(),
    this.version = const Value.absent(),
    this.enabled = const Value.absent(),
    this.order = const Value.absent(),
  });
  RulesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String platforms,
    required String sources,
    required String trigger,
    required String type,
    this.regexWhiteBlackMode = const Value.absent(),
    required String regexMain,
    required bool regexAllowExtractData,
    required String regexExtractedContent,
    required bool regexAllowAddTag,
    required String regexTags,
    required bool regexIsSyncDisabled,
    required bool regexIsFinalRule,
    required String scriptLanguage,
    required String scriptContent,
    required int version,
    required bool enabled,
    required int order,
  }) : name = Value(name),
       platforms = Value(platforms),
       sources = Value(sources),
       trigger = Value(trigger),
       type = Value(type),
       regexMain = Value(regexMain),
       regexAllowExtractData = Value(regexAllowExtractData),
       regexExtractedContent = Value(regexExtractedContent),
       regexAllowAddTag = Value(regexAllowAddTag),
       regexTags = Value(regexTags),
       regexIsSyncDisabled = Value(regexIsSyncDisabled),
       regexIsFinalRule = Value(regexIsFinalRule),
       scriptLanguage = Value(scriptLanguage),
       scriptContent = Value(scriptContent),
       version = Value(version),
       enabled = Value(enabled),
       order = Value(order);
  static Insertable<Rule> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? platforms,
    Expression<String>? sources,
    Expression<String>? trigger,
    Expression<String>? type,
    Expression<String>? regexWhiteBlackMode,
    Expression<String>? regexMain,
    Expression<bool>? regexAllowExtractData,
    Expression<String>? regexExtractedContent,
    Expression<bool>? regexAllowAddTag,
    Expression<String>? regexTags,
    Expression<bool>? regexIsSyncDisabled,
    Expression<bool>? regexIsFinalRule,
    Expression<String>? scriptLanguage,
    Expression<String>? scriptContent,
    Expression<int>? version,
    Expression<bool>? enabled,
    Expression<int>? order,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (platforms != null) 'platforms': platforms,
      if (sources != null) 'sources': sources,
      if (trigger != null) 'trigger': trigger,
      if (type != null) 'type': type,
      if (regexWhiteBlackMode != null)
        'regexWhiteBlackMode': regexWhiteBlackMode,
      if (regexMain != null) 'regexMain': regexMain,
      if (regexAllowExtractData != null)
        'regexAllowExtractData': regexAllowExtractData,
      if (regexExtractedContent != null)
        'regexExtractedContent': regexExtractedContent,
      if (regexAllowAddTag != null) 'regexAllowAddTag': regexAllowAddTag,
      if (regexTags != null) 'regexTags': regexTags,
      if (regexIsSyncDisabled != null)
        'regexIsSyncDisabled': regexIsSyncDisabled,
      if (regexIsFinalRule != null) 'regexIsFinalRule': regexIsFinalRule,
      if (scriptLanguage != null) 'scriptLanguage': scriptLanguage,
      if (scriptContent != null) 'scriptContent': scriptContent,
      if (version != null) 'version': version,
      if (enabled != null) 'enabled': enabled,
      if (order != null) 'order': order,
    });
  }

  RulesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? platforms,
    Value<String>? sources,
    Value<String>? trigger,
    Value<String>? type,
    Value<String?>? regexWhiteBlackMode,
    Value<String>? regexMain,
    Value<bool>? regexAllowExtractData,
    Value<String>? regexExtractedContent,
    Value<bool>? regexAllowAddTag,
    Value<String>? regexTags,
    Value<bool>? regexIsSyncDisabled,
    Value<bool>? regexIsFinalRule,
    Value<String>? scriptLanguage,
    Value<String>? scriptContent,
    Value<int>? version,
    Value<bool>? enabled,
    Value<int>? order,
  }) {
    return RulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      platforms: platforms ?? this.platforms,
      sources: sources ?? this.sources,
      trigger: trigger ?? this.trigger,
      type: type ?? this.type,
      regexWhiteBlackMode: regexWhiteBlackMode ?? this.regexWhiteBlackMode,
      regexMain: regexMain ?? this.regexMain,
      regexAllowExtractData:
          regexAllowExtractData ?? this.regexAllowExtractData,
      regexExtractedContent:
          regexExtractedContent ?? this.regexExtractedContent,
      regexAllowAddTag: regexAllowAddTag ?? this.regexAllowAddTag,
      regexTags: regexTags ?? this.regexTags,
      regexIsSyncDisabled: regexIsSyncDisabled ?? this.regexIsSyncDisabled,
      regexIsFinalRule: regexIsFinalRule ?? this.regexIsFinalRule,
      scriptLanguage: scriptLanguage ?? this.scriptLanguage,
      scriptContent: scriptContent ?? this.scriptContent,
      version: version ?? this.version,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (platforms.present) {
      map['platforms'] = Variable<String>(platforms.value);
    }
    if (sources.present) {
      map['sources'] = Variable<String>(sources.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (regexWhiteBlackMode.present) {
      map['regexWhiteBlackMode'] = Variable<String>(regexWhiteBlackMode.value);
    }
    if (regexMain.present) {
      map['regexMain'] = Variable<String>(regexMain.value);
    }
    if (regexAllowExtractData.present) {
      map['regexAllowExtractData'] = Variable<bool>(
        regexAllowExtractData.value,
      );
    }
    if (regexExtractedContent.present) {
      map['regexExtractedContent'] = Variable<String>(
        regexExtractedContent.value,
      );
    }
    if (regexAllowAddTag.present) {
      map['regexAllowAddTag'] = Variable<bool>(regexAllowAddTag.value);
    }
    if (regexTags.present) {
      map['regexTags'] = Variable<String>(regexTags.value);
    }
    if (regexIsSyncDisabled.present) {
      map['regexIsSyncDisabled'] = Variable<bool>(regexIsSyncDisabled.value);
    }
    if (regexIsFinalRule.present) {
      map['regexIsFinalRule'] = Variable<bool>(regexIsFinalRule.value);
    }
    if (scriptLanguage.present) {
      map['scriptLanguage'] = Variable<String>(scriptLanguage.value);
    }
    if (scriptContent.present) {
      map['scriptContent'] = Variable<String>(scriptContent.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('platforms: $platforms, ')
          ..write('sources: $sources, ')
          ..write('trigger: $trigger, ')
          ..write('type: $type, ')
          ..write('regexWhiteBlackMode: $regexWhiteBlackMode, ')
          ..write('regexMain: $regexMain, ')
          ..write('regexAllowExtractData: $regexAllowExtractData, ')
          ..write('regexExtractedContent: $regexExtractedContent, ')
          ..write('regexAllowAddTag: $regexAllowAddTag, ')
          ..write('regexTags: $regexTags, ')
          ..write('regexIsSyncDisabled: $regexIsSyncDisabled, ')
          ..write('regexIsFinalRule: $regexIsFinalRule, ')
          ..write('scriptLanguage: $scriptLanguage, ')
          ..write('scriptContent: $scriptContent, ')
          ..write('version: $version, ')
          ..write('enabled: $enabled, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }
}

class $ScriptModulesTable extends ScriptModules
    with TableInfo<$ScriptModulesTable, ScriptModule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptModulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _moduleNameMeta = const VerificationMeta(
    'moduleName',
  );
  @override
  late final GeneratedColumn<String> moduleName = GeneratedColumn<String>(
    'moduleName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'displayName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RuleScriptLanguage, String>
  language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RuleScriptLanguage>($ScriptModulesTable.$converterlanguage);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    moduleName,
    displayName,
    language,
    source,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ScriptModule';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScriptModule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('moduleName')) {
      context.handle(
        _moduleNameMeta,
        moduleName.isAcceptableOrUnknown(data['moduleName']!, _moduleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleNameMeta);
    }
    if (data.containsKey('displayName')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['displayName']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {moduleName};
  @override
  ScriptModule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScriptModule(
      moduleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}moduleName'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}displayName'],
      )!,
      language: $ScriptModulesTable.$converterlanguage.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}language'],
        )!,
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ScriptModulesTable createAlias(String alias) {
    return $ScriptModulesTable(attachedDatabase, alias);
  }

  static TypeConverter<RuleScriptLanguage, String> $converterlanguage =
      const RuleScriptLanguageConverter();
}

class ScriptModule extends DataClass implements Insertable<ScriptModule> {
  final String moduleName;
  final String displayName;
  final RuleScriptLanguage language;
  final String source;
  final int version;
  const ScriptModule({
    required this.moduleName,
    required this.displayName,
    required this.language,
    required this.source,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['moduleName'] = Variable<String>(moduleName);
    map['displayName'] = Variable<String>(displayName);
    {
      map['language'] = Variable<String>(
        $ScriptModulesTable.$converterlanguage.toSql(language),
      );
    }
    map['source'] = Variable<String>(source);
    map['version'] = Variable<int>(version);
    return map;
  }

  ScriptModulesCompanion toCompanion(bool nullToAbsent) {
    return ScriptModulesCompanion(
      moduleName: Value(moduleName),
      displayName: Value(displayName),
      language: Value(language),
      source: Value(source),
      version: Value(version),
    );
  }

  factory ScriptModule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScriptModule(
      moduleName: serializer.fromJson<String>(json['moduleName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      language: serializer.fromJson<RuleScriptLanguage>(json['language']),
      source: serializer.fromJson<String>(json['source']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'moduleName': serializer.toJson<String>(moduleName),
      'displayName': serializer.toJson<String>(displayName),
      'language': serializer.toJson<RuleScriptLanguage>(language),
      'source': serializer.toJson<String>(source),
      'version': serializer.toJson<int>(version),
    };
  }

  ScriptModule copyWith({
    String? moduleName,
    String? displayName,
    RuleScriptLanguage? language,
    String? source,
    int? version,
  }) => ScriptModule(
    moduleName: moduleName ?? this.moduleName,
    displayName: displayName ?? this.displayName,
    language: language ?? this.language,
    source: source ?? this.source,
    version: version ?? this.version,
  );
  ScriptModule copyWithCompanion(ScriptModulesCompanion data) {
    return ScriptModule(
      moduleName: data.moduleName.present
          ? data.moduleName.value
          : this.moduleName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      language: data.language.present ? data.language.value : this.language,
      source: data.source.present ? data.source.value : this.source,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScriptModule(')
          ..write('moduleName: $moduleName, ')
          ..write('displayName: $displayName, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(moduleName, displayName, language, source, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScriptModule &&
          other.moduleName == this.moduleName &&
          other.displayName == this.displayName &&
          other.language == this.language &&
          other.source == this.source &&
          other.version == this.version);
}

class ScriptModulesCompanion extends UpdateCompanion<ScriptModule> {
  final Value<String> moduleName;
  final Value<String> displayName;
  final Value<RuleScriptLanguage> language;
  final Value<String> source;
  final Value<int> version;
  final Value<int> rowid;
  const ScriptModulesCompanion({
    this.moduleName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.language = const Value.absent(),
    this.source = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScriptModulesCompanion.insert({
    required String moduleName,
    required String displayName,
    required RuleScriptLanguage language,
    required String source,
    required int version,
    this.rowid = const Value.absent(),
  }) : moduleName = Value(moduleName),
       displayName = Value(displayName),
       language = Value(language),
       source = Value(source),
       version = Value(version);
  static Insertable<ScriptModule> custom({
    Expression<String>? moduleName,
    Expression<String>? displayName,
    Expression<String>? language,
    Expression<String>? source,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (moduleName != null) 'moduleName': moduleName,
      if (displayName != null) 'displayName': displayName,
      if (language != null) 'language': language,
      if (source != null) 'source': source,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScriptModulesCompanion copyWith({
    Value<String>? moduleName,
    Value<String>? displayName,
    Value<RuleScriptLanguage>? language,
    Value<String>? source,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ScriptModulesCompanion(
      moduleName: moduleName ?? this.moduleName,
      displayName: displayName ?? this.displayName,
      language: language ?? this.language,
      source: source ?? this.source,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (moduleName.present) {
      map['moduleName'] = Variable<String>(moduleName.value);
    }
    if (displayName.present) {
      map['displayName'] = Variable<String>(displayName.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(
        $ScriptModulesTable.$converterlanguage.toSql(language.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptModulesCompanion(')
          ..write('moduleName: $moduleName, ')
          ..write('displayName: $displayName, ')
          ..write('language: $language, ')
          ..write('source: $source, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingStorageAcksTable extends PendingStorageAcks
    with TableInfo<$PendingStorageAcksTable, PendingStorageAck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingStorageAcksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<int> opId = GeneratedColumn<int>(
    'opId',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDevIdMeta = const VerificationMeta(
    'targetDevId',
  );
  @override
  late final GeneratedColumn<String> targetDevId = GeneratedColumn<String>(
    'targetDevId',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [opId, targetDevId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PendingStorageAck';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingStorageAck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('opId')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['opId']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('targetDevId')) {
      context.handle(
        _targetDevIdMeta,
        targetDevId.isAcceptableOrUnknown(
          data['targetDevId']!,
          _targetDevIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetDevIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId, targetDevId};
  @override
  PendingStorageAck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingStorageAck(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opId'],
      )!,
      targetDevId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}targetDevId'],
      )!,
    );
  }

  @override
  $PendingStorageAcksTable createAlias(String alias) {
    return $PendingStorageAcksTable(attachedDatabase, alias);
  }
}

class PendingStorageAck extends DataClass
    implements Insertable<PendingStorageAck> {
  final int opId;
  final String targetDevId;
  const PendingStorageAck({required this.opId, required this.targetDevId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['opId'] = Variable<int>(opId);
    map['targetDevId'] = Variable<String>(targetDevId);
    return map;
  }

  PendingStorageAcksCompanion toCompanion(bool nullToAbsent) {
    return PendingStorageAcksCompanion(
      opId: Value(opId),
      targetDevId: Value(targetDevId),
    );
  }

  factory PendingStorageAck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingStorageAck(
      opId: serializer.fromJson<int>(json['opId']),
      targetDevId: serializer.fromJson<String>(json['targetDevId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<int>(opId),
      'targetDevId': serializer.toJson<String>(targetDevId),
    };
  }

  PendingStorageAck copyWith({int? opId, String? targetDevId}) =>
      PendingStorageAck(
        opId: opId ?? this.opId,
        targetDevId: targetDevId ?? this.targetDevId,
      );
  PendingStorageAck copyWithCompanion(PendingStorageAcksCompanion data) {
    return PendingStorageAck(
      opId: data.opId.present ? data.opId.value : this.opId,
      targetDevId: data.targetDevId.present
          ? data.targetDevId.value
          : this.targetDevId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingStorageAck(')
          ..write('opId: $opId, ')
          ..write('targetDevId: $targetDevId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(opId, targetDevId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingStorageAck &&
          other.opId == this.opId &&
          other.targetDevId == this.targetDevId);
}

class PendingStorageAcksCompanion extends UpdateCompanion<PendingStorageAck> {
  final Value<int> opId;
  final Value<String> targetDevId;
  final Value<int> rowid;
  const PendingStorageAcksCompanion({
    this.opId = const Value.absent(),
    this.targetDevId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingStorageAcksCompanion.insert({
    required int opId,
    required String targetDevId,
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       targetDevId = Value(targetDevId);
  static Insertable<PendingStorageAck> custom({
    Expression<int>? opId,
    Expression<String>? targetDevId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'opId': opId,
      if (targetDevId != null) 'targetDevId': targetDevId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingStorageAcksCompanion copyWith({
    Value<int>? opId,
    Value<String>? targetDevId,
    Value<int>? rowid,
  }) {
    return PendingStorageAcksCompanion(
      opId: opId ?? this.opId,
      targetDevId: targetDevId ?? this.targetDevId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['opId'] = Variable<int>(opId.value);
    }
    if (targetDevId.present) {
      map['targetDevId'] = Variable<String>(targetDevId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingStorageAcksCompanion(')
          ..write('opId: $opId, ')
          ..write('targetDevId: $targetDevId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HistoriesTable histories = $HistoriesTable(this);
  late final $HistoryTagsTable historyTags = $HistoryTagsTable(this);
  late final VHistoryTagHold vHistoryTagHold = VHistoryTagHold(this);
  late final $ConfigsTable configs = $ConfigsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $OperationSyncsTable operationSyncs = $OperationSyncsTable(this);
  late final $OperationRecordsTable operationRecords = $OperationRecordsTable(
    this,
  );
  late final $AppInfosTable appInfos = $AppInfosTable(this);
  late final $RulesTable rules = $RulesTable(this);
  late final $ScriptModulesTable scriptModules = $ScriptModulesTable(this);
  late final $PendingStorageAcksTable pendingStorageAcks =
      $PendingStorageAcksTable(this);
  late final Index indexHistoryDevId = Index(
    'index_History_devId',
    'CREATE INDEX index_History_devId ON History (devId)',
  );
  late final Index indexHistoryDevIdSource = Index(
    'index_History_devId_source',
    'CREATE INDEX index_History_devId_source ON History (devId, source)',
  );
  late final Index indexHistoryTagTagNameHisId = Index(
    'index_HistoryTag_tagName_hisId',
    'CREATE UNIQUE INDEX index_HistoryTag_tagName_hisId ON HistoryTag (tagName, hisId)',
  );
  late final Index indexOperationRecordUidModuleMethod = Index(
    'index_OperationRecord_uid_module_method',
    'CREATE INDEX index_OperationRecord_uid_module_method ON OperationRecord (uid, module, method)',
  );
  late final Index indexOperationRecordModuleEnMethod = Index(
    'index_OperationRecord_moduleEn_method',
    'CREATE INDEX index_OperationRecord_moduleEn_method ON OperationRecord (moduleEn, method)',
  );
  late final Index indexAppInfoAppIdDevId = Index(
    'index_AppInfo_appId_devId',
    'CREATE UNIQUE INDEX index_AppInfo_appId_devId ON AppInfo (appId, devId)',
  );
  late final UserDao userDao = UserDao(this as AppDatabase);
  late final ConfigDao configDao = ConfigDao(this as AppDatabase);
  late final HistoryDao historyDao = HistoryDao(this as AppDatabase);
  late final DeviceDao deviceDao = DeviceDao(this as AppDatabase);
  late final OperationSyncDao operationSyncDao = OperationSyncDao(
    this as AppDatabase,
  );
  late final HistoryTagDao historyTagDao = HistoryTagDao(this as AppDatabase);
  late final OperationRecordDao operationRecordDao = OperationRecordDao(
    this as AppDatabase,
  );
  late final AppInfoDao appInfoDao = AppInfoDao(this as AppDatabase);
  late final RuleDao ruleDao = RuleDao(this as AppDatabase);
  late final ScriptModuleDao scriptModuleDao = ScriptModuleDao(
    this as AppDatabase,
  );
  late final PendingStorageAckDao pendingStorageAckDao = PendingStorageAckDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    histories,
    historyTags,
    vHistoryTagHold,
    configs,
    devices,
    users,
    operationSyncs,
    operationRecords,
    appInfos,
    rules,
    scriptModules,
    pendingStorageAcks,
    indexHistoryDevId,
    indexHistoryDevIdSource,
    indexHistoryTagTagNameHisId,
    indexOperationRecordUidModuleMethod,
    indexOperationRecordModuleEnMethod,
    indexAppInfoAppIdDevId,
  ];
}

typedef $$HistoriesTableCreateCompanionBuilder =
    HistoriesCompanion Function({
      Value<int> id,
      required int uid,
      required String time,
      required String content,
      Value<String?> extracted,
      required String type,
      required String devId,
      required bool top,
      required bool sync,
      required int size,
      Value<String?> updateTime,
      Value<String?> source,
    });
typedef $$HistoriesTableUpdateCompanionBuilder =
    HistoriesCompanion Function({
      Value<int> id,
      Value<int> uid,
      Value<String> time,
      Value<String> content,
      Value<String?> extracted,
      Value<String> type,
      Value<String> devId,
      Value<bool> top,
      Value<bool> sync,
      Value<int> size,
      Value<String?> updateTime,
      Value<String?> source,
    });

class $$HistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $HistoriesTable> {
  $$HistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extracted => $composableBuilder(
    column: $table.extracted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get top => $composableBuilder(
    column: $table.top,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sync => $composableBuilder(
    column: $table.sync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoriesTable> {
  $$HistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extracted => $composableBuilder(
    column: $table.extracted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get top => $composableBuilder(
    column: $table.top,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sync => $composableBuilder(
    column: $table.sync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoriesTable> {
  $$HistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get extracted =>
      $composableBuilder(column: $table.extracted, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get devId =>
      $composableBuilder(column: $table.devId, builder: (column) => column);

  GeneratedColumn<bool> get top =>
      $composableBuilder(column: $table.top, builder: (column) => column);

  GeneratedColumn<bool> get sync =>
      $composableBuilder(column: $table.sync, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$HistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoriesTable,
          History,
          $$HistoriesTableFilterComposer,
          $$HistoriesTableOrderingComposer,
          $$HistoriesTableAnnotationComposer,
          $$HistoriesTableCreateCompanionBuilder,
          $$HistoriesTableUpdateCompanionBuilder,
          (History, BaseReferences<_$AppDatabase, $HistoriesTable, History>),
          History,
          PrefetchHooks Function()
        > {
  $$HistoriesTableTableManager(_$AppDatabase db, $HistoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> uid = const Value.absent(),
                Value<String> time = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> extracted = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> devId = const Value.absent(),
                Value<bool> top = const Value.absent(),
                Value<bool> sync = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String?> updateTime = const Value.absent(),
                Value<String?> source = const Value.absent(),
              }) => HistoriesCompanion(
                id: id,
                uid: uid,
                time: time,
                content: content,
                extracted: extracted,
                type: type,
                devId: devId,
                top: top,
                sync: sync,
                size: size,
                updateTime: updateTime,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int uid,
                required String time,
                required String content,
                Value<String?> extracted = const Value.absent(),
                required String type,
                required String devId,
                required bool top,
                required bool sync,
                required int size,
                Value<String?> updateTime = const Value.absent(),
                Value<String?> source = const Value.absent(),
              }) => HistoriesCompanion.insert(
                id: id,
                uid: uid,
                time: time,
                content: content,
                extracted: extracted,
                type: type,
                devId: devId,
                top: top,
                sync: sync,
                size: size,
                updateTime: updateTime,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoriesTable,
      History,
      $$HistoriesTableFilterComposer,
      $$HistoriesTableOrderingComposer,
      $$HistoriesTableAnnotationComposer,
      $$HistoriesTableCreateCompanionBuilder,
      $$HistoriesTableUpdateCompanionBuilder,
      (History, BaseReferences<_$AppDatabase, $HistoriesTable, History>),
      History,
      PrefetchHooks Function()
    >;
typedef $$HistoryTagsTableCreateCompanionBuilder =
    HistoryTagsCompanion Function({
      Value<int> id,
      required String tagName,
      required int hisId,
    });
typedef $$HistoryTagsTableUpdateCompanionBuilder =
    HistoryTagsCompanion Function({
      Value<int> id,
      Value<String> tagName,
      Value<int> hisId,
    });

class $$HistoryTagsTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryTagsTable> {
  $$HistoryTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagName => $composableBuilder(
    column: $table.tagName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hisId => $composableBuilder(
    column: $table.hisId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryTagsTable> {
  $$HistoryTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagName => $composableBuilder(
    column: $table.tagName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hisId => $composableBuilder(
    column: $table.hisId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryTagsTable> {
  $$HistoryTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tagName =>
      $composableBuilder(column: $table.tagName, builder: (column) => column);

  GeneratedColumn<int> get hisId =>
      $composableBuilder(column: $table.hisId, builder: (column) => column);
}

class $$HistoryTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoryTagsTable,
          HistoryTag,
          $$HistoryTagsTableFilterComposer,
          $$HistoryTagsTableOrderingComposer,
          $$HistoryTagsTableAnnotationComposer,
          $$HistoryTagsTableCreateCompanionBuilder,
          $$HistoryTagsTableUpdateCompanionBuilder,
          (
            HistoryTag,
            BaseReferences<_$AppDatabase, $HistoryTagsTable, HistoryTag>,
          ),
          HistoryTag,
          PrefetchHooks Function()
        > {
  $$HistoryTagsTableTableManager(_$AppDatabase db, $HistoryTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tagName = const Value.absent(),
                Value<int> hisId = const Value.absent(),
              }) =>
                  HistoryTagsCompanion(id: id, tagName: tagName, hisId: hisId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tagName,
                required int hisId,
              }) => HistoryTagsCompanion.insert(
                id: id,
                tagName: tagName,
                hisId: hisId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoryTagsTable,
      HistoryTag,
      $$HistoryTagsTableFilterComposer,
      $$HistoryTagsTableOrderingComposer,
      $$HistoryTagsTableAnnotationComposer,
      $$HistoryTagsTableCreateCompanionBuilder,
      $$HistoryTagsTableUpdateCompanionBuilder,
      (
        HistoryTag,
        BaseReferences<_$AppDatabase, $HistoryTagsTable, HistoryTag>,
      ),
      HistoryTag,
      PrefetchHooks Function()
    >;
typedef $$ConfigsTableCreateCompanionBuilder =
    ConfigsCompanion Function({
      required String key,
      required String value,
      required int uid,
      Value<int> rowid,
    });
typedef $$ConfigsTableUpdateCompanionBuilder =
    ConfigsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> uid,
      Value<int> rowid,
    });

class $$ConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigsTable> {
  $$ConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigsTable> {
  $$ConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigsTable> {
  $$ConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);
}

class $$ConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigsTable,
          Config,
          $$ConfigsTableFilterComposer,
          $$ConfigsTableOrderingComposer,
          $$ConfigsTableAnnotationComposer,
          $$ConfigsTableCreateCompanionBuilder,
          $$ConfigsTableUpdateCompanionBuilder,
          (Config, BaseReferences<_$AppDatabase, $ConfigsTable, Config>),
          Config,
          PrefetchHooks Function()
        > {
  $$ConfigsTableTableManager(_$AppDatabase db, $ConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> uid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigsCompanion(
                key: key,
                value: value,
                uid: uid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int uid,
                Value<int> rowid = const Value.absent(),
              }) => ConfigsCompanion.insert(
                key: key,
                value: value,
                uid: uid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigsTable,
      Config,
      $$ConfigsTableFilterComposer,
      $$ConfigsTableOrderingComposer,
      $$ConfigsTableAnnotationComposer,
      $$ConfigsTableCreateCompanionBuilder,
      $$ConfigsTableUpdateCompanionBuilder,
      (Config, BaseReferences<_$AppDatabase, $ConfigsTable, Config>),
      Config,
      PrefetchHooks Function()
    >;
typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      required String guid,
      required String devName,
      required int uid,
      Value<String?> customName,
      required String type,
      Value<String?> address,
      Value<String?> internalAddress,
      required bool isPaired,
      Value<int> rowid,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<String> guid,
      Value<String> devName,
      Value<int> uid,
      Value<String?> customName,
      Value<String> type,
      Value<String?> address,
      Value<String?> internalAddress,
      Value<bool> isPaired,
      Value<int> rowid,
    });

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devName => $composableBuilder(
    column: $table.devName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalAddress => $composableBuilder(
    column: $table.internalAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaired => $composableBuilder(
    column: $table.isPaired,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devName => $composableBuilder(
    column: $table.devName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalAddress => $composableBuilder(
    column: $table.internalAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaired => $composableBuilder(
    column: $table.isPaired,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get devName =>
      $composableBuilder(column: $table.devName, builder: (column) => column);

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get internalAddress => $composableBuilder(
    column: $table.internalAddress,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaired =>
      $composableBuilder(column: $table.isPaired, builder: (column) => column);
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
          Device,
          PrefetchHooks Function()
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> guid = const Value.absent(),
                Value<String> devName = const Value.absent(),
                Value<int> uid = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> internalAddress = const Value.absent(),
                Value<bool> isPaired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                guid: guid,
                devName: devName,
                uid: uid,
                customName: customName,
                type: type,
                address: address,
                internalAddress: internalAddress,
                isPaired: isPaired,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String guid,
                required String devName,
                required int uid,
                Value<String?> customName = const Value.absent(),
                required String type,
                Value<String?> address = const Value.absent(),
                Value<String?> internalAddress = const Value.absent(),
                required bool isPaired,
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                guid: guid,
                devName: devName,
                uid: uid,
                customName: customName,
                type: type,
                address: address,
                internalAddress: internalAddress,
                isPaired: isPaired,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, BaseReferences<_$AppDatabase, $DevicesTable, Device>),
      Device,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int?> id,
      required String account,
      required String password,
      required String type,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int?> id,
      Value<String> account,
      Value<String> password,
      Value<String> type,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<String> account = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<String> type = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                account: account,
                password: password,
                type: type,
              ),
          createCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                required String account,
                required String password,
                required String type,
              }) => UsersCompanion.insert(
                id: id,
                account: account,
                password: password,
                type: type,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$OperationSyncsTableCreateCompanionBuilder =
    OperationSyncsCompanion Function({
      required int opId,
      required String devId,
      required int uid,
      required String time,
      Value<int> rowid,
    });
typedef $$OperationSyncsTableUpdateCompanionBuilder =
    OperationSyncsCompanion Function({
      Value<int> opId,
      Value<String> devId,
      Value<int> uid,
      Value<String> time,
      Value<int> rowid,
    });

class $$OperationSyncsTableFilterComposer
    extends Composer<_$AppDatabase, $OperationSyncsTable> {
  $$OperationSyncsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OperationSyncsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperationSyncsTable> {
  $$OperationSyncsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperationSyncsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperationSyncsTable> {
  $$OperationSyncsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get devId =>
      $composableBuilder(column: $table.devId, builder: (column) => column);

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);
}

class $$OperationSyncsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperationSyncsTable,
          OperationSync,
          $$OperationSyncsTableFilterComposer,
          $$OperationSyncsTableOrderingComposer,
          $$OperationSyncsTableAnnotationComposer,
          $$OperationSyncsTableCreateCompanionBuilder,
          $$OperationSyncsTableUpdateCompanionBuilder,
          (
            OperationSync,
            BaseReferences<_$AppDatabase, $OperationSyncsTable, OperationSync>,
          ),
          OperationSync,
          PrefetchHooks Function()
        > {
  $$OperationSyncsTableTableManager(
    _$AppDatabase db,
    $OperationSyncsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperationSyncsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperationSyncsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperationSyncsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> opId = const Value.absent(),
                Value<String> devId = const Value.absent(),
                Value<int> uid = const Value.absent(),
                Value<String> time = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationSyncsCompanion(
                opId: opId,
                devId: devId,
                uid: uid,
                time: time,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int opId,
                required String devId,
                required int uid,
                required String time,
                Value<int> rowid = const Value.absent(),
              }) => OperationSyncsCompanion.insert(
                opId: opId,
                devId: devId,
                uid: uid,
                time: time,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OperationSyncsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperationSyncsTable,
      OperationSync,
      $$OperationSyncsTableFilterComposer,
      $$OperationSyncsTableOrderingComposer,
      $$OperationSyncsTableAnnotationComposer,
      $$OperationSyncsTableCreateCompanionBuilder,
      $$OperationSyncsTableUpdateCompanionBuilder,
      (
        OperationSync,
        BaseReferences<_$AppDatabase, $OperationSyncsTable, OperationSync>,
      ),
      OperationSync,
      PrefetchHooks Function()
    >;
typedef $$OperationRecordsTableCreateCompanionBuilder =
    OperationRecordsCompanion Function({
      Value<int> id,
      required int uid,
      required String devId,
      required Module module,
      Value<String?> moduleEn,
      required OpMethod method,
      required String data,
      required String time,
      Value<bool?> storageSync,
    });
typedef $$OperationRecordsTableUpdateCompanionBuilder =
    OperationRecordsCompanion Function({
      Value<int> id,
      Value<int> uid,
      Value<String> devId,
      Value<Module> module,
      Value<String?> moduleEn,
      Value<OpMethod> method,
      Value<String> data,
      Value<String> time,
      Value<bool?> storageSync,
    });

class $$OperationRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $OperationRecordsTable> {
  $$OperationRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Module, Module, String> get module =>
      $composableBuilder(
        column: $table.module,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get moduleEn => $composableBuilder(
    column: $table.moduleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OpMethod, OpMethod, String> get method =>
      $composableBuilder(
        column: $table.method,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get storageSync => $composableBuilder(
    column: $table.storageSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OperationRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperationRecordsTable> {
  $$OperationRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleEn => $composableBuilder(
    column: $table.moduleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get storageSync => $composableBuilder(
    column: $table.storageSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperationRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperationRecordsTable> {
  $$OperationRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get devId =>
      $composableBuilder(column: $table.devId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Module, String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get moduleEn =>
      $composableBuilder(column: $table.moduleEn, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OpMethod, String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<bool> get storageSync => $composableBuilder(
    column: $table.storageSync,
    builder: (column) => column,
  );
}

class $$OperationRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperationRecordsTable,
          OperationRecord,
          $$OperationRecordsTableFilterComposer,
          $$OperationRecordsTableOrderingComposer,
          $$OperationRecordsTableAnnotationComposer,
          $$OperationRecordsTableCreateCompanionBuilder,
          $$OperationRecordsTableUpdateCompanionBuilder,
          (
            OperationRecord,
            BaseReferences<
              _$AppDatabase,
              $OperationRecordsTable,
              OperationRecord
            >,
          ),
          OperationRecord,
          PrefetchHooks Function()
        > {
  $$OperationRecordsTableTableManager(
    _$AppDatabase db,
    $OperationRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperationRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperationRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperationRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> uid = const Value.absent(),
                Value<String> devId = const Value.absent(),
                Value<Module> module = const Value.absent(),
                Value<String?> moduleEn = const Value.absent(),
                Value<OpMethod> method = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<String> time = const Value.absent(),
                Value<bool?> storageSync = const Value.absent(),
              }) => OperationRecordsCompanion(
                id: id,
                uid: uid,
                devId: devId,
                module: module,
                moduleEn: moduleEn,
                method: method,
                data: data,
                time: time,
                storageSync: storageSync,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int uid,
                required String devId,
                required Module module,
                Value<String?> moduleEn = const Value.absent(),
                required OpMethod method,
                required String data,
                required String time,
                Value<bool?> storageSync = const Value.absent(),
              }) => OperationRecordsCompanion.insert(
                id: id,
                uid: uid,
                devId: devId,
                module: module,
                moduleEn: moduleEn,
                method: method,
                data: data,
                time: time,
                storageSync: storageSync,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OperationRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperationRecordsTable,
      OperationRecord,
      $$OperationRecordsTableFilterComposer,
      $$OperationRecordsTableOrderingComposer,
      $$OperationRecordsTableAnnotationComposer,
      $$OperationRecordsTableCreateCompanionBuilder,
      $$OperationRecordsTableUpdateCompanionBuilder,
      (
        OperationRecord,
        BaseReferences<_$AppDatabase, $OperationRecordsTable, OperationRecord>,
      ),
      OperationRecord,
      PrefetchHooks Function()
    >;
typedef $$AppInfosTableCreateCompanionBuilder =
    AppInfosCompanion Function({
      Value<int> id,
      required String appId,
      required String devId,
      required String name,
      required String iconB64,
    });
typedef $$AppInfosTableUpdateCompanionBuilder =
    AppInfosCompanion Function({
      Value<int> id,
      Value<String> appId,
      Value<String> devId,
      Value<String> name,
      Value<String> iconB64,
    });

class $$AppInfosTableFilterComposer
    extends Composer<_$AppDatabase, $AppInfosTable> {
  $$AppInfosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconB64 => $composableBuilder(
    column: $table.iconB64,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppInfosTableOrderingComposer
    extends Composer<_$AppDatabase, $AppInfosTable> {
  $$AppInfosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devId => $composableBuilder(
    column: $table.devId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconB64 => $composableBuilder(
    column: $table.iconB64,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppInfosTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppInfosTable> {
  $$AppInfosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get appId =>
      $composableBuilder(column: $table.appId, builder: (column) => column);

  GeneratedColumn<String> get devId =>
      $composableBuilder(column: $table.devId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconB64 =>
      $composableBuilder(column: $table.iconB64, builder: (column) => column);
}

class $$AppInfosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppInfosTable,
          AppInfo,
          $$AppInfosTableFilterComposer,
          $$AppInfosTableOrderingComposer,
          $$AppInfosTableAnnotationComposer,
          $$AppInfosTableCreateCompanionBuilder,
          $$AppInfosTableUpdateCompanionBuilder,
          (AppInfo, BaseReferences<_$AppDatabase, $AppInfosTable, AppInfo>),
          AppInfo,
          PrefetchHooks Function()
        > {
  $$AppInfosTableTableManager(_$AppDatabase db, $AppInfosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppInfosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppInfosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppInfosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> appId = const Value.absent(),
                Value<String> devId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconB64 = const Value.absent(),
              }) => AppInfosCompanion(
                id: id,
                appId: appId,
                devId: devId,
                name: name,
                iconB64: iconB64,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String appId,
                required String devId,
                required String name,
                required String iconB64,
              }) => AppInfosCompanion.insert(
                id: id,
                appId: appId,
                devId: devId,
                name: name,
                iconB64: iconB64,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppInfosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppInfosTable,
      AppInfo,
      $$AppInfosTableFilterComposer,
      $$AppInfosTableOrderingComposer,
      $$AppInfosTableAnnotationComposer,
      $$AppInfosTableCreateCompanionBuilder,
      $$AppInfosTableUpdateCompanionBuilder,
      (AppInfo, BaseReferences<_$AppDatabase, $AppInfosTable, AppInfo>),
      AppInfo,
      PrefetchHooks Function()
    >;
typedef $$RulesTableCreateCompanionBuilder =
    RulesCompanion Function({
      Value<int> id,
      required String name,
      required String platforms,
      required String sources,
      required String trigger,
      required String type,
      Value<String?> regexWhiteBlackMode,
      required String regexMain,
      required bool regexAllowExtractData,
      required String regexExtractedContent,
      required bool regexAllowAddTag,
      required String regexTags,
      required bool regexIsSyncDisabled,
      required bool regexIsFinalRule,
      required String scriptLanguage,
      required String scriptContent,
      required int version,
      required bool enabled,
      required int order,
    });
typedef $$RulesTableUpdateCompanionBuilder =
    RulesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> platforms,
      Value<String> sources,
      Value<String> trigger,
      Value<String> type,
      Value<String?> regexWhiteBlackMode,
      Value<String> regexMain,
      Value<bool> regexAllowExtractData,
      Value<String> regexExtractedContent,
      Value<bool> regexAllowAddTag,
      Value<String> regexTags,
      Value<bool> regexIsSyncDisabled,
      Value<bool> regexIsFinalRule,
      Value<String> scriptLanguage,
      Value<String> scriptContent,
      Value<int> version,
      Value<bool> enabled,
      Value<int> order,
    });

class $$RulesTableFilterComposer extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platforms => $composableBuilder(
    column: $table.platforms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sources => $composableBuilder(
    column: $table.sources,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regexWhiteBlackMode => $composableBuilder(
    column: $table.regexWhiteBlackMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regexMain => $composableBuilder(
    column: $table.regexMain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get regexAllowExtractData => $composableBuilder(
    column: $table.regexAllowExtractData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regexExtractedContent => $composableBuilder(
    column: $table.regexExtractedContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get regexAllowAddTag => $composableBuilder(
    column: $table.regexAllowAddTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regexTags => $composableBuilder(
    column: $table.regexTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get regexIsSyncDisabled => $composableBuilder(
    column: $table.regexIsSyncDisabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get regexIsFinalRule => $composableBuilder(
    column: $table.regexIsFinalRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scriptLanguage => $composableBuilder(
    column: $table.scriptLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scriptContent => $composableBuilder(
    column: $table.scriptContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platforms => $composableBuilder(
    column: $table.platforms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sources => $composableBuilder(
    column: $table.sources,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regexWhiteBlackMode => $composableBuilder(
    column: $table.regexWhiteBlackMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regexMain => $composableBuilder(
    column: $table.regexMain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get regexAllowExtractData => $composableBuilder(
    column: $table.regexAllowExtractData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regexExtractedContent => $composableBuilder(
    column: $table.regexExtractedContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get regexAllowAddTag => $composableBuilder(
    column: $table.regexAllowAddTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regexTags => $composableBuilder(
    column: $table.regexTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get regexIsSyncDisabled => $composableBuilder(
    column: $table.regexIsSyncDisabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get regexIsFinalRule => $composableBuilder(
    column: $table.regexIsFinalRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scriptLanguage => $composableBuilder(
    column: $table.scriptLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scriptContent => $composableBuilder(
    column: $table.scriptContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get platforms =>
      $composableBuilder(column: $table.platforms, builder: (column) => column);

  GeneratedColumn<String> get sources =>
      $composableBuilder(column: $table.sources, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get regexWhiteBlackMode => $composableBuilder(
    column: $table.regexWhiteBlackMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regexMain =>
      $composableBuilder(column: $table.regexMain, builder: (column) => column);

  GeneratedColumn<bool> get regexAllowExtractData => $composableBuilder(
    column: $table.regexAllowExtractData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regexExtractedContent => $composableBuilder(
    column: $table.regexExtractedContent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get regexAllowAddTag => $composableBuilder(
    column: $table.regexAllowAddTag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regexTags =>
      $composableBuilder(column: $table.regexTags, builder: (column) => column);

  GeneratedColumn<bool> get regexIsSyncDisabled => $composableBuilder(
    column: $table.regexIsSyncDisabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get regexIsFinalRule => $composableBuilder(
    column: $table.regexIsFinalRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scriptLanguage => $composableBuilder(
    column: $table.scriptLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scriptContent => $composableBuilder(
    column: $table.scriptContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);
}

class $$RulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RulesTable,
          Rule,
          $$RulesTableFilterComposer,
          $$RulesTableOrderingComposer,
          $$RulesTableAnnotationComposer,
          $$RulesTableCreateCompanionBuilder,
          $$RulesTableUpdateCompanionBuilder,
          (Rule, BaseReferences<_$AppDatabase, $RulesTable, Rule>),
          Rule,
          PrefetchHooks Function()
        > {
  $$RulesTableTableManager(_$AppDatabase db, $RulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> platforms = const Value.absent(),
                Value<String> sources = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> regexWhiteBlackMode = const Value.absent(),
                Value<String> regexMain = const Value.absent(),
                Value<bool> regexAllowExtractData = const Value.absent(),
                Value<String> regexExtractedContent = const Value.absent(),
                Value<bool> regexAllowAddTag = const Value.absent(),
                Value<String> regexTags = const Value.absent(),
                Value<bool> regexIsSyncDisabled = const Value.absent(),
                Value<bool> regexIsFinalRule = const Value.absent(),
                Value<String> scriptLanguage = const Value.absent(),
                Value<String> scriptContent = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> order = const Value.absent(),
              }) => RulesCompanion(
                id: id,
                name: name,
                platforms: platforms,
                sources: sources,
                trigger: trigger,
                type: type,
                regexWhiteBlackMode: regexWhiteBlackMode,
                regexMain: regexMain,
                regexAllowExtractData: regexAllowExtractData,
                regexExtractedContent: regexExtractedContent,
                regexAllowAddTag: regexAllowAddTag,
                regexTags: regexTags,
                regexIsSyncDisabled: regexIsSyncDisabled,
                regexIsFinalRule: regexIsFinalRule,
                scriptLanguage: scriptLanguage,
                scriptContent: scriptContent,
                version: version,
                enabled: enabled,
                order: order,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String platforms,
                required String sources,
                required String trigger,
                required String type,
                Value<String?> regexWhiteBlackMode = const Value.absent(),
                required String regexMain,
                required bool regexAllowExtractData,
                required String regexExtractedContent,
                required bool regexAllowAddTag,
                required String regexTags,
                required bool regexIsSyncDisabled,
                required bool regexIsFinalRule,
                required String scriptLanguage,
                required String scriptContent,
                required int version,
                required bool enabled,
                required int order,
              }) => RulesCompanion.insert(
                id: id,
                name: name,
                platforms: platforms,
                sources: sources,
                trigger: trigger,
                type: type,
                regexWhiteBlackMode: regexWhiteBlackMode,
                regexMain: regexMain,
                regexAllowExtractData: regexAllowExtractData,
                regexExtractedContent: regexExtractedContent,
                regexAllowAddTag: regexAllowAddTag,
                regexTags: regexTags,
                regexIsSyncDisabled: regexIsSyncDisabled,
                regexIsFinalRule: regexIsFinalRule,
                scriptLanguage: scriptLanguage,
                scriptContent: scriptContent,
                version: version,
                enabled: enabled,
                order: order,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RulesTable,
      Rule,
      $$RulesTableFilterComposer,
      $$RulesTableOrderingComposer,
      $$RulesTableAnnotationComposer,
      $$RulesTableCreateCompanionBuilder,
      $$RulesTableUpdateCompanionBuilder,
      (Rule, BaseReferences<_$AppDatabase, $RulesTable, Rule>),
      Rule,
      PrefetchHooks Function()
    >;
typedef $$ScriptModulesTableCreateCompanionBuilder =
    ScriptModulesCompanion Function({
      required String moduleName,
      required String displayName,
      required RuleScriptLanguage language,
      required String source,
      required int version,
      Value<int> rowid,
    });
typedef $$ScriptModulesTableUpdateCompanionBuilder =
    ScriptModulesCompanion Function({
      Value<String> moduleName,
      Value<String> displayName,
      Value<RuleScriptLanguage> language,
      Value<String> source,
      Value<int> version,
      Value<int> rowid,
    });

class $$ScriptModulesTableFilterComposer
    extends Composer<_$AppDatabase, $ScriptModulesTable> {
  $$ScriptModulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get moduleName => $composableBuilder(
    column: $table.moduleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RuleScriptLanguage, RuleScriptLanguage, String>
  get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScriptModulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScriptModulesTable> {
  $$ScriptModulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get moduleName => $composableBuilder(
    column: $table.moduleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScriptModulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScriptModulesTable> {
  $$ScriptModulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get moduleName => $composableBuilder(
    column: $table.moduleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RuleScriptLanguage, String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ScriptModulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScriptModulesTable,
          ScriptModule,
          $$ScriptModulesTableFilterComposer,
          $$ScriptModulesTableOrderingComposer,
          $$ScriptModulesTableAnnotationComposer,
          $$ScriptModulesTableCreateCompanionBuilder,
          $$ScriptModulesTableUpdateCompanionBuilder,
          (
            ScriptModule,
            BaseReferences<_$AppDatabase, $ScriptModulesTable, ScriptModule>,
          ),
          ScriptModule,
          PrefetchHooks Function()
        > {
  $$ScriptModulesTableTableManager(_$AppDatabase db, $ScriptModulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptModulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptModulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptModulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> moduleName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<RuleScriptLanguage> language = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScriptModulesCompanion(
                moduleName: moduleName,
                displayName: displayName,
                language: language,
                source: source,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String moduleName,
                required String displayName,
                required RuleScriptLanguage language,
                required String source,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => ScriptModulesCompanion.insert(
                moduleName: moduleName,
                displayName: displayName,
                language: language,
                source: source,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScriptModulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScriptModulesTable,
      ScriptModule,
      $$ScriptModulesTableFilterComposer,
      $$ScriptModulesTableOrderingComposer,
      $$ScriptModulesTableAnnotationComposer,
      $$ScriptModulesTableCreateCompanionBuilder,
      $$ScriptModulesTableUpdateCompanionBuilder,
      (
        ScriptModule,
        BaseReferences<_$AppDatabase, $ScriptModulesTable, ScriptModule>,
      ),
      ScriptModule,
      PrefetchHooks Function()
    >;
typedef $$PendingStorageAcksTableCreateCompanionBuilder =
    PendingStorageAcksCompanion Function({
      required int opId,
      required String targetDevId,
      Value<int> rowid,
    });
typedef $$PendingStorageAcksTableUpdateCompanionBuilder =
    PendingStorageAcksCompanion Function({
      Value<int> opId,
      Value<String> targetDevId,
      Value<int> rowid,
    });

class $$PendingStorageAcksTableFilterComposer
    extends Composer<_$AppDatabase, $PendingStorageAcksTable> {
  $$PendingStorageAcksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDevId => $composableBuilder(
    column: $table.targetDevId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingStorageAcksTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingStorageAcksTable> {
  $$PendingStorageAcksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDevId => $composableBuilder(
    column: $table.targetDevId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingStorageAcksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingStorageAcksTable> {
  $$PendingStorageAcksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get targetDevId => $composableBuilder(
    column: $table.targetDevId,
    builder: (column) => column,
  );
}

class $$PendingStorageAcksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingStorageAcksTable,
          PendingStorageAck,
          $$PendingStorageAcksTableFilterComposer,
          $$PendingStorageAcksTableOrderingComposer,
          $$PendingStorageAcksTableAnnotationComposer,
          $$PendingStorageAcksTableCreateCompanionBuilder,
          $$PendingStorageAcksTableUpdateCompanionBuilder,
          (
            PendingStorageAck,
            BaseReferences<
              _$AppDatabase,
              $PendingStorageAcksTable,
              PendingStorageAck
            >,
          ),
          PendingStorageAck,
          PrefetchHooks Function()
        > {
  $$PendingStorageAcksTableTableManager(
    _$AppDatabase db,
    $PendingStorageAcksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingStorageAcksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingStorageAcksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingStorageAcksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> opId = const Value.absent(),
                Value<String> targetDevId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingStorageAcksCompanion(
                opId: opId,
                targetDevId: targetDevId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int opId,
                required String targetDevId,
                Value<int> rowid = const Value.absent(),
              }) => PendingStorageAcksCompanion.insert(
                opId: opId,
                targetDevId: targetDevId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingStorageAcksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingStorageAcksTable,
      PendingStorageAck,
      $$PendingStorageAcksTableFilterComposer,
      $$PendingStorageAcksTableOrderingComposer,
      $$PendingStorageAcksTableAnnotationComposer,
      $$PendingStorageAcksTableCreateCompanionBuilder,
      $$PendingStorageAcksTableUpdateCompanionBuilder,
      (
        PendingStorageAck,
        BaseReferences<
          _$AppDatabase,
          $PendingStorageAcksTable,
          PendingStorageAck
        >,
      ),
      PendingStorageAck,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HistoriesTableTableManager get histories =>
      $$HistoriesTableTableManager(_db, _db.histories);
  $$HistoryTagsTableTableManager get historyTags =>
      $$HistoryTagsTableTableManager(_db, _db.historyTags);
  $$ConfigsTableTableManager get configs =>
      $$ConfigsTableTableManager(_db, _db.configs);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$OperationSyncsTableTableManager get operationSyncs =>
      $$OperationSyncsTableTableManager(_db, _db.operationSyncs);
  $$OperationRecordsTableTableManager get operationRecords =>
      $$OperationRecordsTableTableManager(_db, _db.operationRecords);
  $$AppInfosTableTableManager get appInfos =>
      $$AppInfosTableTableManager(_db, _db.appInfos);
  $$RulesTableTableManager get rules =>
      $$RulesTableTableManager(_db, _db.rules);
  $$ScriptModulesTableTableManager get scriptModules =>
      $$ScriptModulesTableTableManager(_db, _db.scriptModules);
  $$PendingStorageAcksTableTableManager get pendingStorageAcks =>
      $$PendingStorageAcksTableTableManager(_db, _db.pendingStorageAcks);
}
