import 'dart:math';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

extension StringExt on String {
  String get upperFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get lowerFirst {
    if (isEmpty) return this;
    return '${this[0].toLowerCase()}${substring(1)}';
  }

  String get normalizePath {
    return replaceAll(RegExp(r'(/+|\\+)'), Constants.dirSeparate);
  }

  String get unixPath {
    return replaceAll(RegExp(r'(/+|\\+)'), Constants.unixDirSeparate);
  }

  bool get hasUrl {
    return matchRegExp(r"[a-zA-z]+://[^\s]*");
  }

  bool get isDomain {
    return matchRegExp(r'^[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\.?$');
  }

  bool get isInternalIPv4 {
    try {
      var ip = split(":")[0];
      final parts = ip.split('.').map(int.parse).toList();
      if (parts.length != 4) return false;

      // 检查A类私有地址
      if (parts[0] == 10) return true;

      // 检查B类私有地址
      if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;

      // 检查C类私有地址
      if (parts[0] == 192 && parts[1] == 168) return true;

      // 检查回环地址
      if (parts[0] == 127) return true;

      // 检查链路本地地址
      if (parts[0] == 169 && parts[1] == 254) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  String substringMinLen(int start, int end) {
    return substring(start, min(end, length));
  }

  bool matchRegExp(String regExp, [bool caseSensitive = false]) {
    var reg = RegExp(
      regExp,
      caseSensitive: caseSensitive,
    );
    return reg.hasMatch(this);
  }

  bool get isPort {
    try {
      var port = int.parse(this);
      return port > 0 && port <= 65535;
    } catch (e) {
      return false;
    }
  }

  int toInt() {
    return int.parse(this);
  }

  bool toBool() {
    return bool.parse(this);
  }

  double toDouble() {
    return double.parse(this);
  }

  void askOpenUrl() {
    if (!hasUrl) return;
    showModalBottomSheet(
      context: Get.context!,
      clipBehavior: Clip.antiAlias,
      elevation: 100,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: IntrinsicHeight(
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationKey.openLink.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          openUrl();
                          Navigator.pop(context);
                        },
                        child: Text(TranslationKey.open.tr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Linkify(
                    text: this,
                    options: const LinkifyOptions(humanize: false),
                    linkStyle: const TextStyle(
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void openUrl() async {
    var uri = Uri.parse(this);
    await launchUrl(uri);
  }

  String replaceLast(String target, String replacement) {
    int lastIndex = lastIndexOf(target);
    if (lastIndex == -1) return this; // 如果找不到目标字符串，直接返回原字符串
    return replaceRange(
      lastIndex,
      lastIndex + target.length,
      replacement,
    );
  }

  bool equalsIgnoreCase(String input) {
    return toLowerCase() == input.toLowerCase();
  }

  bool containsIgnoreCase(String input) {
    return toLowerCase().contains(input.toLowerCase());
  }

  bool get isValidVariablePart {
    final int char = codeUnits.first;
    return (char >= 65 && char <= 90) || (char >= 97 && char <= 122) || char == 95;
  }

  String safeDecodeUri() {
    if (!contains("%")) return this;
    try {
      return Uri.decodeComponent(this);
    } catch (e) {
      return this; // 解码失败时返回原字符串
    }
  }

  /// 删除头尾所有匹配的子字符串（递归）
  String trimStr(String substring) {
    return this.trimStart(substring).trimEnd(substring);
  }

  /// 删除头部所有匹配的子字符串（递归）
  String trimStart(String substring) {
    if (isEmpty || substring.isEmpty) return this;

    var result = this;
    while (result.startsWith(substring)) {
      result = result.substring(substring.length);
    }
    return result;
  }

  /// 删除尾部所有匹配的子字符串（递归）
  String trimEnd(String substring) {
    if (isEmpty || substring.isEmpty) return this;

    var result = this;
    while (result.endsWith(substring)) {
      result = result.substring(0, result.length - substring.length);
    }
    return result;
  }

  String toMd5() {
    return CryptoUtil.toMD5(this);
  }
}

extension StringNilExt on String? {
  bool get isNotNullAndEmpty => this != null && this!.isNotEmpty;

  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension CodeAutocompleteCharactersExtension on Characters {
  bool containsSymbols(List<String> symbols) {
    for (int i = length - 1; i >= 0; i--) {
      if (symbols.contains(elementAt(i))) {
        return true;
      }
    }
    return false;
  }
}
