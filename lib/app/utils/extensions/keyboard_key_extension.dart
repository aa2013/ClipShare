import 'package:clipshare/app/utils/constants.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:uni_platform/src/extensions/keyboard_key.dart';

extension PhysicalKeyboardKeyExt on PhysicalKeyboardKey {
  bool get isModify {
    for (var keys in HotKeyModifier.values) {
      if (keys.physicalKeys.contains(this)) {
        return true;
      }
    }
    return false;
  }

  bool get isCtrl {
    return HotKeyModifier.control.physicalKeys.contains(this);
  }

  bool get isAlt {
    return HotKeyModifier.alt.physicalKeys.contains(this);
  }

  bool get isCapsLock {
    return HotKeyModifier.capsLock.physicalKeys.contains(this);
  }

  bool get isFn {
    return HotKeyModifier.fn.physicalKeys.contains(this);
  }

  bool get isMeta {
    return HotKeyModifier.meta.physicalKeys.contains(this);
  }

  bool get isShift {
    return HotKeyModifier.shift.physicalKeys.contains(this);
  }

  bool isSameModify(PhysicalKeyboardKey key) {
    if (!key.isModify || !isModify) return false;
    if (key.isAlt && isAlt) return true;
    if (key.isCapsLock && isCapsLock) return true;
    if (key.isCtrl && isCtrl) return true;
    if (key.isFn && isFn) return true;
    if (key.isMeta && isMeta) return true;
    if (key.isShift && isShift) return true;
    return false;
  }

  HotKeyModifier get toModify {
    for (var modify in HotKeyModifier.values) {
      if (modify.physicalKeys.contains(this)) {
        return modify;
      }
    }
    throw Exception("$debugName is not modify");
  }

  static String toModifyString(HotKeyModifier modifier) {
    if (modifier == HotKeyModifier.alt) return "Alt";
    if (modifier == HotKeyModifier.capsLock) return "CapsLock";
    if (modifier == HotKeyModifier.control) return "Ctrl";
    if (modifier == HotKeyModifier.fn) return "Fn";
    if (modifier == HotKeyModifier.meta) return "Meta";
    if (modifier == HotKeyModifier.shift) return "Shift";
    throw Exception("not support");
  }

  static Map<int, String> nameMap = {
    0x00000010: 'Hyper',
    0x00000011: 'Super Key',
    0x00000012: 'Fn',
    0x00000013: 'Fn Lock',
    0x00000014: 'Suspend',
    0x00000015: 'Resume',
    0x00000016: 'Turbo',
    0x00000017: 'Privacy Screen Toggle',
    0x00000018: 'Microphone Mute Toggle',
    0x00010082: 'Sleep',
    0x00010083: 'Wake Up',
    0x000100b5: 'Display Toggle Int Ext',
    0x0005ff01: 'Game Button 1',
    0x0005ff02: 'Game Button 2',
    0x0005ff03: 'Game Button 3',
    0x0005ff04: 'Game Button 4',
    0x0005ff05: 'Game Button 5',
    0x0005ff06: 'Game Button 6',
    0x0005ff07: 'Game Button 7',
    0x0005ff08: 'Game Button 8',
    0x0005ff09: 'Game Button 9',
    0x0005ff0a: 'Game Button 10',
    0x0005ff0b: 'Game Button 11',
    0x0005ff0c: 'Game Button 12',
    0x0005ff0d: 'Game Button 13',
    0x0005ff0e: 'Game Button 14',
    0x0005ff0f: 'Game Button 15',
    0x0005ff10: 'Game Button 16',
    0x0005ff11: 'Game Button A',
    0x0005ff12: 'Game Button B',
    0x0005ff13: 'Game Button C',
    0x0005ff14: 'Game Button Left 1',
    0x0005ff15: 'Game Button Left 2',
    0x0005ff16: 'Game Button Mode',
    0x0005ff17: 'Game Button Right 1',
    0x0005ff18: 'Game Button Right 2',
    0x0005ff19: 'Game Button Select',
    0x0005ff1a: 'Game Button Start',
    0x0005ff1b: 'Game Button Thumb Left',
    0x0005ff1c: 'Game Button Thumb Right',
    0x0005ff1d: 'Game Button X',
    0x0005ff1e: 'Game Button Y',
    0x0005ff1f: 'Game Button Z',
    0x00070000: 'Usb Reserved',
    0x00070001: 'Usb Error Roll Over',
    0x00070002: 'Usb Post Fail',
    0x00070003: 'Usb Error Undefined',
    0x00070004: 'Key A',
    0x00070005: 'Key B',
    0x00070006: 'Key C',
    0x00070007: 'Key D',
    0x00070008: 'Key E',
    0x00070009: 'Key F',
    0x0007000a: 'Key G',
    0x0007000b: 'Key H',
    0x0007000c: 'Key I',
    0x0007000d: 'Key J',
    0x0007000e: 'Key K',
    0x0007000f: 'Key L',
    0x00070010: 'Key M',
    0x00070011: 'Key N',
    0x00070012: 'Key O',
    0x00070013: 'Key P',
    0x00070014: 'Key Q',
    0x00070015: 'Key R',
    0x00070016: 'Key S',
    0x00070017: 'Key T',
    0x00070018: 'Key U',
    0x00070019: 'Key V',
    0x0007001a: 'Key W',
    0x0007001b: 'Key X',
    0x0007001c: 'Key Y',
    0x0007001d: 'Key Z',
    0x0007001e: 'Digit 1',
    0x0007001f: 'Digit 2',
    0x00070020: 'Digit 3',
    0x00070021: 'Digit 4',
    0x00070022: 'Digit 5',
    0x00070023: 'Digit 6',
    0x00070024: 'Digit 7',
    0x00070025: 'Digit 8',
    0x00070026: 'Digit 9',
    0x00070027: 'Digit 0',
    0x00070028: 'Enter',
    0x00070029: 'Escape',
    0x0007002a: 'Backspace',
    0x0007002b: 'Tab',
    0x0007002c: 'Space',
    0x0007002d: 'Minus',
    0x0007002e: 'Equal',
    0x0007002f: 'Bracket Left',
    0x00070030: 'Bracket Right',
    0x00070031: 'Backslash',
    0x00070033: 'Semicolon',
    0x00070034: 'Quote',
    0x00070035: 'Backquote',
    0x00070036: 'Comma',
    0x00070037: 'Period',
    0x00070038: 'Slash',
    0x00070039: 'Caps Lock',
    0x0007003a: 'F1',
    0x0007003b: 'F2',
    0x0007003c: 'F3',
    0x0007003d: 'F4',
    0x0007003e: 'F5',
    0x0007003f: 'F6',
    0x00070040: 'F7',
    0x00070041: 'F8',
    0x00070042: 'F9',
    0x00070043: 'F10',
    0x00070044: 'F11',
    0x00070045: 'F12',
    0x00070046: 'Print Screen',
    0x00070047: 'Scroll Lock',
    0x00070048: 'Pause',
    0x00070049: 'Insert',
    0x0007004a: 'Home',
    0x0007004b: 'Page Up',
    0x0007004c: 'Delete',
    0x0007004d: 'End',
    0x0007004e: 'Page Down',
    0x0007004f: 'Arrow Right',
    0x00070050: 'Arrow Left',
    0x00070051: 'Arrow Down',
    0x00070052: 'Arrow Up',
    0x00070053: 'Num Lock',
    0x00070054: 'Numpad Divide',
    0x00070055: 'Numpad Multiply',
    0x00070056: 'Numpad Subtract',
    0x00070057: 'Numpad Add',
    0x00070058: 'Numpad Enter',
    0x00070059: 'Numpad 1',
    0x0007005a: 'Numpad 2',
    0x0007005b: 'Numpad 3',
    0x0007005c: 'Numpad 4',
    0x0007005d: 'Numpad 5',
    0x0007005e: 'Numpad 6',
    0x0007005f: 'Numpad 7',
    0x00070060: 'Numpad 8',
    0x00070061: 'Numpad 9',
    0x00070062: 'Numpad 0',
    0x00070063: 'Numpad Decimal',
    0x00070064: 'Intl Backslash',
    0x00070065: 'Context Menu',
    0x00070066: 'Power',
    0x00070067: 'Numpad Equal',
    0x00070068: 'F13',
    0x00070069: 'F14',
    0x0007006a: 'F15',
    0x0007006b: 'F16',
    0x0007006c: 'F17',
    0x0007006d: 'F18',
    0x0007006e: 'F19',
    0x0007006f: 'F20',
    0x00070070: 'F21',
    0x00070071: 'F22',
    0x00070072: 'F23',
    0x00070073: 'F24',
    0x00070074: 'Open',
    0x00070075: 'Help',
    0x00070077: 'Select',
    0x00070079: 'Again',
    0x0007007a: 'Undo',
    0x0007007b: 'Cut',
    0x0007007c: 'Copy',
    0x0007007d: 'Paste',
    0x0007007e: 'Find',
    0x0007007f: 'Audio Volume Mute',
    0x00070080: 'Audio Volume Up',
    0x00070081: 'Audio Volume Down',
    0x00070085: 'Numpad Comma',
    0x00070087: 'Intl Ro',
    0x00070088: 'Kana Mode',
    0x00070089: 'Intl Yen',
    0x0007008a: 'Convert',
    0x0007008b: 'Non Convert',
    0x00070090: 'Lang 1',
    0x00070091: 'Lang 2',
    0x00070092: 'Lang 3',
    0x00070093: 'Lang 4',
    0x00070094: 'Lang 5',
    0x0007009b: 'Abort',
    0x000700a3: 'Props',
    0x000700b6: 'Numpad Paren Left',
    0x000700b7: 'Numpad Paren Right',
    0x000700bb: 'Numpad Backspace',
    0x000700d0: 'Numpad Memory Store',
    0x000700d1: 'Numpad Memory Recall',
    0x000700d2: 'Numpad Memory Clear',
    0x000700d3: 'Numpad Memory Add',
    0x000700d4: 'Numpad Memory Subtract',
    0x000700d7: 'Numpad Sign Change',
    0x000700d8: 'Numpad Clear',
    0x000700d9: 'Numpad Clear Entry',
    0x000700e0: 'Control Left',
    0x000700e1: 'Shift Left',
    0x000700e2: 'Alt Left',
    0x000700e3: 'Meta Left',
    0x000700e4: 'Control Right',
    0x000700e5: 'Shift Right',
    0x000700e6: 'Alt Right',
    0x000700e7: 'Meta Right',
    0x000c0060: 'Info',
    0x000c0061: 'Closed Caption Toggle',
    0x000c006f: 'Brightness Up',
    0x000c0070: 'Brightness Down',
    0x000c0072: 'Brightness Toggle',
    0x000c0073: 'Brightness Minimum',
    0x000c0074: 'Brightness Maximum',
    0x000c0075: 'Brightness Auto',
    0x000c0079: 'Kbd Illum Up',
    0x000c007a: 'Kbd Illum Down',
    0x000c0083: 'Media Last',
    0x000c008c: 'Launch Phone',
    0x000c008d: 'Program Guide',
    0x000c0094: 'Exit',
    0x000c009c: 'Channel Up',
    0x000c009d: 'Channel Down',
    0x000c00b0: 'Media Play',
    0x000c00b1: 'Media Pause',
    0x000c00b2: 'Media Record',
    0x000c00b3: 'Media Fast Forward',
    0x000c00b4: 'Media Rewind',
    0x000c00b5: 'Media Track Next',
    0x000c00b6: 'Media Track Previous',
    0x000c00b7: 'Media Stop',
    0x000c00b8: 'Eject',
    0x000c00cd: 'Media Play Pause',
    0x000c00cf: 'Speech Input Toggle',
    0x000c00e5: 'Bass Boost',
    0x000c0183: 'Media Select',
    0x000c0184: 'Launch Word Processor',
    0x000c0186: 'Launch Spreadsheet',
    0x000c018a: 'Launch Mail',
    0x000c018d: 'Launch Contacts',
    0x000c018e: 'Launch Calendar',
    0x000c0192: 'Launch App2',
    0x000c0194: 'Launch App1',
    0x000c0196: 'Launch Internet Browser',
    0x000c019c: 'Log Off',
    0x000c019e: 'Lock Screen',
    0x000c019f: 'Launch Control Panel',
    0x000c01a2: 'Select Task',
    0x000c01a7: 'Launch Documents',
    0x000c01ab: 'Spell Check',
    0x000c01ae: 'Launch Keyboard Layout',
    0x000c01b1: 'Launch Screen Saver',
    0x000c01b7: 'Launch Audio Browser',
    0x000c01cb: 'Launch Assistant',
    0x000c0201: 'New Key',
    0x000c0203: 'Close',
    0x000c0207: 'Save',
    0x000c0208: 'Print',
    0x000c0221: 'Browser Search',
    0x000c0223: 'Browser Home',
    0x000c0224: 'Browser Back',
    0x000c0225: 'Browser Forward',
    0x000c0226: 'Browser Stop',
    0x000c0227: 'Browser Refresh',
    0x000c022a: 'Browser Favorites',
    0x000c022d: 'Zoom In',
    0x000c022e: 'Zoom Out',
    0x000c0232: 'Zoom Toggle',
    0x000c0279: 'Redo',
    0x000c0289: 'Mail Reply',
    0x000c028b: 'Mail Forward',
    0x000c028c: 'Mail Send',
    0x000c029d: 'Keyboard Layout Select',
    0x000c029f: 'Show All Windows',
  };

  String? get label => nameMap[usbHidUsage];

  String? get simpleLabel {
    if (label == null) return null;
    var keyName = label!.replaceAll(RegExp("(Key |Numpad |Digit )"), "");
    for (var map in Constants.keyNameMap) {
      if (map["key"] == keyName) {
        keyName = map["name"].toString();
      }
    }
    return keyName;
  }
}

extension HotKeyModifierExt on HotKeyModifier {
  String get label {
    switch (this) {
      case HotKeyModifier.alt:
        return "Alt";
      case HotKeyModifier.capsLock:
        return "CapsLock";
      case HotKeyModifier.control:
        return "Ctrl";
      case HotKeyModifier.fn:
        return "Fn";
      case HotKeyModifier.meta:
        return "Meta";
      case HotKeyModifier.shift:
        return "Shift";
      default:
        throw Exception("Unknown HotKeyModifier $name");
    }
  }
}
extension KeyboardKeyExt on KeyboardKey{

  String get simpleLabel {
    PhysicalKeyboardKey? physicalKey;
    if (this is LogicalKeyboardKey) {
      physicalKey = (this as LogicalKeyboardKey).physicalKey;
    } else if (this is PhysicalKeyboardKey) {
      physicalKey = this as PhysicalKeyboardKey;
    }
    return physicalKey?.simpleLabel ?? keyLabel;
  }
}
extension HotKeyExt on HotKey {
  String get desc {
    var descList = List<String>.empty(growable: true);
    for (var item in modifiers ?? <HotKeyModifier>[]) {
      descList.add(item.label);
    }
    descList.add(key.simpleLabel);
    return descList.join(" + ");
  }
}
