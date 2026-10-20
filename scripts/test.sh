#!/usr/bin/env bash
# Runs the official Crafting Interpreters tests against your jlox or clox,
# the same way the cracked.guide workflow does on GitHub Actions.
#
#   scripts/test.sh chap04_scanning     one chapter's suite (chap04..chap13 run jlox, chap14+ run clox)
#   scripts/test.sh jlox                every jlox test
#   scripts/test.sh clox                every clox test
#
# The first run clones munificent/craftinginterpreters into .craftinginterpreters/
# (gitignored) and fetches its test runner's Dart packages. Later runs pull it.
# Set CRACKED_OFFLINE=1 to skip the pull.
#
# Needs: git, Dart 2 (2.19.6; the runner does not work on Dart 3), a JDK for
# jlox and a C compiler plus make for clox. The dev container has all of it.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CI="$ROOT/.craftinginterpreters"
BIN="$ROOT/build"

die() { echo "test.sh: $*" >&2; exit 2; }

suite="${1:-}"
if [ -z "$suite" ] || [ "$suite" = "-h" ] || [ "$suite" = "--help" ]; then
  sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 2
fi

case "$suite" in
  jlox) interp=jlox ;;
  clox) interp=clox ;;
  chap[0-9][0-9]_*)
    n="${suite:4:2}"; n="${n#0}"
    if [ "$n" -le 13 ]; then interp=jlox; else interp=clox; fi ;;
  *) die "unknown suite '$suite'. Try chap04_scanning, chap17_compiling, jlox or clox." ;;
esac

# ---- Dart 2 ----------------------------------------------------------------------
if ! command -v dart >/dev/null 2>&1; then
  cat >&2 <<'EOF'
test.sh: Dart is not installed. The book's test runner needs Dart 2 (2.19.6), not Dart 3.
  Linux x64:   curl -fLO https://storage.googleapis.com/dart-archive/channels/stable/release/2.19.6/sdk/dartsdk-linux-x64-release.zip
               unzip dartsdk-linux-x64-release.zip -d ~/.local && export PATH="$HOME/.local/dart-sdk/bin:$PATH"
  macOS:       same URL with dartsdk-macos-arm64-release.zip (Apple silicon) or dartsdk-macos-x64-release.zip
  Windows:     use WSL and the Linux steps, or the dev container
  Or open this repo in the dev container / a Codespace, which has it.
EOF
  exit 2
fi
dart_version="$(dart --version 2>&1 | sed -n 's/.*Dart SDK version: \([0-9][0-9.]*\).*/\1/p')"
case "$dart_version" in
  2.*) ;;
  *) die "found Dart ${dart_version:-?}, but the test runner needs Dart 2 (2.19.6). Put a Dart 2 SDK first on PATH (see the comment at the top of this script)." ;;
esac

# ---- the official repo and its runner --------------------------------------------
if [ ! -d "$CI/.git" ]; then
  echo "Cloning munificent/craftinginterpreters into .craftinginterpreters/ ..."
  git clone --depth 1 https://github.com/munificent/craftinginterpreters.git "$CI" || die "clone failed"
elif [ -z "${CRACKED_OFFLINE:-}" ]; then
  git -C "$CI" pull --ff-only --quiet || echo "test.sh: could not update .craftinginterpreters/, using what is there" >&2
fi
if [ ! -f "$CI/tool/.dart_tool/package_config.json" ] || [ "$CI/tool/pubspec.yaml" -nt "$CI/tool/.dart_tool/package_config.json" ]; then
  (cd "$CI/tool" && dart pub get) || die "dart pub get failed in .craftinginterpreters/tool"
fi

# ---- .cracked.json (same keys as the workflow) -----------------------------------
cfg() {
  [ -f "$ROOT/.cracked.json" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$1" '.[$k] // empty | tostring' "$ROOT/.cracked.json" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; v=json.load(open(sys.argv[1])).get(sys.argv[2]); print("" if v is None else v)' "$ROOT/.cracked.json" "$1" 2>/dev/null
  fi
}
abs() { case "$1" in /*) echo "$1" ;; *) echo "$ROOT/$1" ;; esac; }
BUILD="$(cfg build)"; path="$(cfg "$interp")"

# ---- build -----------------------------------------------------------------------
mkdir -p "$BIN"
if [ -n "$BUILD" ]; then
  echo "build: $BUILD"
  (cd "$ROOT" && bash -c "$BUILD") || die "your build command failed"
fi

pkg_of() { sed -n 's/^[[:space:]]*package[[:space:]]\{1,\}\([A-Za-z0-9_.]\{1,\}\)[[:space:]]*;.*/\1/p' "$1" | head -n 1; }

if [ -z "$path" ] && [ "$interp" = jlox ]; then
  main="$(find "$ROOT/jlox" -name Lox.java -not -path '*/test/*' 2>/dev/null | head -n 1)"
  [ -n "$main" ] || die "no Lox.java under jlox/. Point \"jlox\" in .cracked.json at your launcher."
  pkg="$(pkg_of "$main")"; cls="${pkg:+$pkg.}Lox"
  # Expr.java and Stmt.java come from GenerateAst (chapter 5); make them if they are not there.
  gen="$(find "$ROOT/jlox" -name GenerateAst.java | head -n 1)"
  if [ -n "$gen" ] && [ ! -f "$(dirname "$main")/Expr.java" ]; then
    gpkg="$(pkg_of "$gen")"
    rm -rf "$BIN/generate-ast"
    { javac -nowarn -d "$BIN/generate-ast" "$gen" && java -cp "$BIN/generate-ast" "${gpkg:+$gpkg.}GenerateAst" "$(dirname "$main")"; } || die "GenerateAst failed"
  fi
  rm -rf "$BIN/jlox-classes"
  find "$ROOT/jlox" -name '*.java' -not -path '*/test/*' -print0 | xargs -0 javac -nowarn -d "$BIN/jlox-classes" || die "javac failed"
  printf '#!/bin/sh\nexec java -Dfile.encoding=UTF-8 -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8 -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -cp "%s" %s "$@"\n' "$BIN/jlox-classes" "$cls" > "$BIN/jlox"
  chmod +x "$BIN/jlox"
  path="$BIN/jlox"
fi
if [ -z "$path" ] && [ "$interp" = clox ]; then
  [ -f "$ROOT/clox/Makefile" ] || die "no clox/Makefile. Point \"clox\" in .cracked.json at your binary."
  make -C "$ROOT/clox" || die "make failed"
  path="$ROOT/clox/build/clox"
fi
path="$(abs "$path")"
[ -x "$path" ] || die "$path is not an executable file"

# ---- run -------------------------------------------------------------------------
# The JVM announces these on stderr, which the tests read as errors.
unset JAVA_TOOL_OPTIONS _JAVA_OPTIONS JDK_JAVA_OPTIONS
# The tests print non-ASCII strings: run under a UTF-8 locale.
if [ "$(uname)" = Darwin ]; then export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8; else export LC_ALL=C.UTF-8 LANG=C.UTF-8; fi

# test.dart waits forever on a test that never ends; give each one 10 seconds.
run="$path"
t="$(command -v timeout || command -v gtimeout || true)"
if [ -n "$t" ]; then
  run="$BIN/run-$interp"
  printf '#!/bin/sh\nexec "%s" 10 "%s" "$@"\n' "$t" "$path" > "$run"
  chmod +x "$run"
fi

echo "Running $suite against $path"
cd "$CI" && exec dart tool/bin/test.dart "$suite" --interpreter "$run"
