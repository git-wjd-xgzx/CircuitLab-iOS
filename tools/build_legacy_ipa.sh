#!/usr/bin/env bash
#
# Cross-compile CircuitLab for armv7 / iOS 4.3 with an old iOS SDK.
#
# Usage:
#   tools/build_legacy_ipa.sh /path/to/iPhoneOS10.3.sdk [output-dir]
#
# The script needs macOS + Xcode command line tools (clang, ld, otool,
# vtool, zip). It produces:
#   build/CircuitLab-unsigned.ipa
#   build/CircuitLab-jailbreak.ipa   (ad-hoc signed with ldid, if present)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="${1:-$ROOT/iPhoneOS10.3.sdk}"
OUT="${2:-$ROOT/build}"
APP="$OUT/CircuitLab.app"
BIN="$APP/CircuitLab"

if [ ! -d "$SDK/System/Library/Frameworks/UIKit.framework" ]; then
  echo "error: iOS SDK not found at: $SDK" >&2
  echo "       pass the path to iPhoneOS10.3.sdk as the first argument." >&2
  exit 2
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "error: xcrun not found; run this script on macOS with Xcode installed." >&2
  exit 2
fi

CC="${CC:-$(xcrun --find clang)}"
MIN_OS="4.3"

# The iOS 10.3 SDK ships only text stubs, no crt. Without a crt1.3.1.o
# modern ld silently bumps the minimum OS to 7.0. This small fat object
# (armv6/armv7/armv7s/armv7k) restores true 4.3 linking.
if [ -f "$ROOT/tools/crt1.3.1.o" ] && [ ! -f "$SDK/usr/lib/crt1.3.1.o" ]; then
  cp "$ROOT/tools/crt1.3.1.o" "$SDK/usr/lib/crt1.3.1.o"
fi

echo "==> SDK:  $SDK"
echo "==> CC:   $CC"
echo "==> OUT:  $OUT"

rm -rf "$OUT"
mkdir -p "$APP"

# A modern clang can emit armv7 Mach-O while targeting the old deployment
# target. -fno-objc-arc keeps the Objective-C runtime requirements at iOS 4.3.
"$CC" \
  -target "armv7-apple-ios${MIN_OS}" \
  -miphoneos-version-min="${MIN_OS}" \
  -isysroot "$SDK" \
  -I "$ROOT/Sources" \
  -O2 -DNDEBUG -fno-objc-arc -fno-common \
  -Wno-deprecated-declarations \
  "$ROOT/Sources/main.m" \
  "$ROOT/Sources/AppDelegate.m" \
  "$ROOT/Sources/LabViewController.m" \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -Wl,-dead_strip \
  -o "$BIN"

chmod 755 "$BIN"

cp "$ROOT/Sources/Info.plist" "$APP/Info.plist"
cp "$ROOT/Sources/index.html" "$APP/index.html"
cp "$ROOT/Resources/Icon.png" "$APP/Icon.png"
cp "$ROOT/Resources/Icon@2x.png" "$APP/Icon@2x.png"
cp "$ROOT/Resources/Default.png" "$APP/Default.png"
cp "$ROOT/Resources/Default@2x.png" "$APP/Default@2x.png"
printf 'APPL????' > "$APP/PkgInfo"

if command -v plutil >/dev/null 2>&1; then
  plutil -lint "$APP/Info.plist"
fi

echo "==> Binary:"
file "$BIN"
if command -v vtool >/dev/null 2>&1; then
  vtool -show-build "$BIN" || true
fi
if command -v otool >/dev/null 2>&1; then
  otool -arch armv7 -l "$BIN" | grep -A4 -E "LC_VERSION_MIN_IPHONEOS|LC_BUILD_VERSION" || true
fi

package_ipa() {
  local name="$1"
  rm -rf "$OUT/Payload"
  mkdir -p "$OUT/Payload"
  cp -R "$APP" "$OUT/Payload/CircuitLab.app"
  ( cd "$OUT" && zip -qry "$name" Payload )
  echo "==> $OUT/$name"
}

package_ipa "CircuitLab-unsigned.ipa"

if command -v ldid >/dev/null 2>&1; then
  echo "==> Ad-hoc signing with ldid"
  ldid -S "$BIN"
  package_ipa "CircuitLab-jailbreak.ipa"
else
  echo "==> ldid not installed; only the unsigned IPA was created."
fi

echo
echo "Done. Install on a jailbroken iOS 4.3+ device with AppSync/afc2,"
echo "or re-sign the .app with your own Apple developer certificate."
