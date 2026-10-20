# Dev container for Crafting Interpreters: gcc/make for clox, Dart 2.19.6 for
# the book's test runner. Java 21 (Temurin) comes from the feature in
# devcontainer.json.
FROM mcr.microsoft.com/devcontainers/base:1-ubuntu-24.04

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential gdb valgrind unzip jq ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*

# The test runner (tool/bin/test.dart) predates Dart 3, so pin Dart 2.
ARG DART_VERSION=2.19.6
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) arch=x64 ;; arm64) arch=arm64 ;; *) echo "unsupported architecture" >&2; exit 1 ;; \
    esac; \
    curl -fsSLo /tmp/dart.zip "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-${arch}-release.zip"; \
    unzip -q /tmp/dart.zip -d /opt; \
    rm /tmp/dart.zip; \
    chmod -R a+rX /opt/dart-sdk; \
    /opt/dart-sdk/bin/dart --disable-analytics >/dev/null 2>&1 || true

ENV PATH="/opt/dart-sdk/bin:${PATH}" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
