#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=${1:?give a build directory}
cd "$root"
python3 Sparky/fetch_openssl.py "$work/sources"
bash Sparky/build_openssl.sh ios "$work/sources/openssl" "$work/openssl"
xcrun --sdk iphoneos clang -arch arm64 -isysroot "$(xcrun --sdk iphoneos --show-sdk-path)" \
  -miphoneos-version-min=16.0 -Wall -Wextra -Werror \
  -I "$work/openssl/install/include" Sparky/Tests/CryptoTest.c \
  "$work/openssl/install/lib/libcrypto.a" -o "$work/crypto-link-check"
xcrun lipo "$work/crypto-link-check" -verify_arch arm64
python3 Sparky/check_catalogs.py
bash Sparky/test_protocol.sh "$work/protocol"
xcodebuild -project 'KDE Connect.xcodeproj' -scheme 'KDE Connect' \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath "$work/build" -clonedSourcePackagesDirPath "$work/packages" \
  -onlyUsePackageVersionsFromResolvedFile -jobs 4 \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' DEVELOPMENT_TEAM='' \
  CODE_SIGN_ENTITLEMENTS=Sparky/Sideload.entitlements \
  KDE_OPENSSL_PREFIX="$work/openssl/install" \
  PRODUCT_BUNDLE_IDENTIFIER=org.sparkyos.kdeconnect IPHONEOS_DEPLOYMENT_TARGET=16.0 \
  build
