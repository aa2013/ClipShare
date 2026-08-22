import 'dart:core';
import 'dart:math';
///雪花算法，生成 id 用
class Snowflake {
  static const int _defaultTwepoch = 1288834974657;
  static const int _defaultTimeOffset = 2000;
  static const int _workerIdBits = 5;
  static const int _maxWorkerId = 31;
  static const int _dataCenterIdBits = 5;
  static const int _maxDataCenterId = 31;
  static const int _sequenceBits = 12;
  static const int _workerIdShift = 12;
  static const int _dataCenterIdShift = 17;
  static const int _timestampLeftShift = 22;
  static const int _sequenceMask = 4095;

  late final int _twepoch;
  late final int _workerId;
  late final int _dataCenterId;
  late final bool _useSystemClock;
  late final int _timeOffset;
  late final int _randomSequenceLimit;
  int _sequence = 0;
  int _lastTimestamp = -1;

  Snowflake(int dataCenterId)
      : this.fromWorkerAndDataCenterId(
          IdUtil.getWorkerId(dataCenterId),
          IdUtil.getDataCenterId(dataCenterId),
        );

  Snowflake.fromWorkerAndDataCenterId(int workerId, int dataCenterId)
      : this.fromWorkerDataAndClockId(workerId, dataCenterId, false);

  Snowflake.fromWorkerDataAndClockId(
    int workerId,
    int dataCenterId, [
    bool isUseSystemClock = false,
  ]) : this.fromEpochDate(
          null,
          workerId,
          dataCenterId,
          isUseSystemClock,
          _defaultTimeOffset,
        );

  Snowflake.fromEpochDate(
    DateTime? epochDate,
    int workerId,
    int dataCenterId,
    bool isUseSystemClock,
    int timeOffset, [
    int randomSequenceLimit = 0,
  ]) : this.fromEpochDateAndRandom(
          epochDate,
          workerId,
          dataCenterId,
          isUseSystemClock,
          timeOffset,
          0,
        );

  Snowflake.fromEpochDateAndRandom(
    DateTime? epochDate,
    int workerId,
    int dataCenterId,
    bool isUseSystemClock,
    int timeOffset,
    int randomSequenceLimit,
  )   : _twepoch = epochDate != null
            ? epochDate.millisecondsSinceEpoch
            : _defaultTwepoch,
        _workerId = Assert.checkBetween(workerId, 0, _maxWorkerId),
        _dataCenterId = Assert.checkBetween(dataCenterId, 0, _maxDataCenterId),
        _useSystemClock = isUseSystemClock,
        _timeOffset = timeOffset,
        _randomSequenceLimit =
            Assert.checkBetween(randomSequenceLimit, 0, _sequenceMask);

  int _getWorkerId(int id) {
    return (id >> _workerIdShift) & _maxWorkerId;
  }

  int _getDataCenterId(int id) {
    return (id >> _dataCenterIdShift) & _maxDataCenterId;
  }

  int _getGenerateDateTime(int id) {
    return ((id >> _timestampLeftShift) & 2199023255551) + _twepoch;
  }

  int nextId() {
    int timestamp = _genTime();
    if (timestamp < _lastTimestamp) {
      if (_lastTimestamp - timestamp >= _timeOffset) {
        throw StateError(
          'Clock moved backwards. Refusing to generate id for ${_lastTimestamp - timestamp}ms',
        );
      }

      timestamp = _lastTimestamp;
    }

    if (timestamp == _lastTimestamp) {
      int sequence = (_sequence + 1) & _sequenceMask;
      if (sequence == 0) {
        timestamp = _tilNextMillis(_lastTimestamp);
      }

      _sequence = sequence;
    } else if (_randomSequenceLimit > 1) {
      _sequence = Random().nextInt(_randomSequenceLimit);
    } else {
      _sequence = 0;
    }

    _lastTimestamp = timestamp;
    return ((timestamp - _twepoch) << _timestampLeftShift) |
        (_dataCenterId << _dataCenterIdShift) |
        (_workerId << _workerIdShift) |
        _sequence;
  }

  String nextIdStr() {
    return nextId().toString();
  }

  int _tilNextMillis(int lastTimestamp) {
    int timestamp;
    do {
      timestamp = _genTime();
    } while (timestamp == lastTimestamp);

    if (timestamp < lastTimestamp) {
      throw StateError(
        'Clock moved backwards. Refusing to generate id for ${lastTimestamp - timestamp}ms',
      );
    } else {
      return timestamp;
    }
  }

  int _genTime() {
    return _useSystemClock
        ? DateTime.now().millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
  }
}

class IdUtil {
  static int getWorkerId(int datacenterId) {
    StringBuffer mpid = StringBuffer();
    mpid.write(datacenterId.toString());

    // try {
    //   mpid.write(RuntimeUtil.getPid().toString());
    // } catch (UtilException) {}

    return (mpid.toString().hashCode & 0xffff) % (Snowflake._maxWorkerId + 1);
  }

  static int getDataCenterId(int id) {
    return id >> Snowflake._dataCenterIdShift & Snowflake._maxDataCenterId;
  }
}

class Assert {
  static int checkBetween(int value, int min, int max) {
    if (value >= min && value <= max) {
      return value;
    } else {
      throw ArgumentError('Value $value is not between $min and $max');
    }
  }
}
