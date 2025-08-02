# ESPHome Swift - Swift Embedded Development Environment
# Based on Ubuntu 22.04 LTS for stability
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    wget \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libbsd-dev \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install build tools for ESP32
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    ccache \
    libffi-dev \
    libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Swift dependencies
RUN apt-get update && apt-get install -y \
    binutils \
    libc6-dev \
    libgcc-12-dev \
    libstdc++-12-dev \
    zlib1g-dev \
    libncurses5 \
    && rm -rf /var/lib/apt/lists/*

# Set up Python environment for ESP tools
RUN python3 -m pip install --upgrade pip setuptools wheel

# Install ESP-IDF dependencies
RUN python3 -m pip install \
    esptool \
    pyserial \
    pyparsing

# Create working directory
WORKDIR /workspace

# Download and install Swift development snapshot with Embedded support
# Using a recent snapshot that should have Swift Embedded
ENV SWIFT_VERSION=swift-DEVELOPMENT-SNAPSHOT-2025-07-18-a
ENV SWIFT_PLATFORM=ubuntu2204
ENV SWIFT_ARCH=aarch64

# Download Swift toolchain
RUN SWIFT_WEBROOT="https://download.swift.org/development/ubuntu2204-aarch64" \
    && SWIFT_DOWNLOAD_URL="$SWIFT_WEBROOT/$SWIFT_VERSION/$SWIFT_VERSION-ubuntu22.04-aarch64.tar.gz" \
    && curl -fSsL "$SWIFT_DOWNLOAD_URL" -o swift.tar.gz \
    && tar -xzf swift.tar.gz -C / --strip-components=1 \
    && rm swift.tar.gz \
    && chmod -R o+r /usr/lib/swift

# Verify Swift installation
RUN swift --version

# Install UV for Python package management (as mentioned in swift-embedded-examples)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

# Set up environment for ESP32 development
ENV IDF_PATH=/opt/esp-idf
ENV IDF_TOOLS_PATH=/opt/esp

# Clone ESP-IDF for ESP32 support (using stable version)
RUN git clone --recursive --depth 1 --branch v5.2.1 https://github.com/espressif/esp-idf.git $IDF_PATH

# Install ESP-IDF
RUN cd $IDF_PATH && \
    ./install.sh esp32c3,esp32c6,esp32h2 && \
    . $IDF_PATH/export.sh

# Create a script to source ESP-IDF environment
RUN echo '#!/bin/bash\n\
source $IDF_PATH/export.sh\n\
exec "$@"' > /usr/local/bin/idf-env.sh && \
    chmod +x /usr/local/bin/idf-env.sh

# Set working directory for the project
WORKDIR /workspace/esphome-swift

# Default command - bash shell with ESP-IDF environment
CMD ["/usr/local/bin/idf-env.sh", "bash"]