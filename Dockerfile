# Stage 1: Python builder for venv
FROM python:3.9-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Set up virtual environment
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install Python packages
RUN pip install --no-cache-dir \
    gTTS \
    pyttsx3 \
    librosa \
    scipy \
    numpy

# Stage 2: Final n8n container
FROM n8nio/n8n:latest

USER root

# Install dependencies: git, make, cmake, curl, build tools, ffmpeg
RUN apk add --no-cache \
    git \
    build-base \
    cmake \
    curl \
    ffmpeg \
    python3 \
    py3-pip

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Copy Python venv from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set up temp directory
RUN mkdir -p /tmp/workspace && \
    chown -R node:node /tmp/workspace

# ✅ Install whisper.cpp (ONLY)
RUN git clone https://github.com/ggerganov/whisper.cpp.git /opt/whisper.cpp && \
    cd /opt/whisper.cpp && \
    make && \
    mv build/bin/main . && \
    mkdir -p /opt/whisper.cpp/models && \
    curl -L -o /opt/whisper.cpp/models/ggml-base.en.bin https://ggml.ggerganov.com/ggml-model-whisper-base.en.bin && \
    chown -R node:node /opt/whisper.cpp

USER node
WORKDIR /tmp/workspace
