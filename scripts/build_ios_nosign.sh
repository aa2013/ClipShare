#!/bin/bash
set -e
# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VERSION=$(grep "version:" "$PROJECT_ROOT"/pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)
BUILD_NUMBER=$(grep "version:" "$PROJECT_ROOT"/pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f2)

cd ../ && flutter build ios --release
path=build/ios/iphoneos
payload=$path/Payload
mkdir $payload && cp -r $path/Runner.app $payload
cd $path || exit 1
zip -r "clipshare-$VERSION-$BUILD_NUMBER.ipa" Payload
open .