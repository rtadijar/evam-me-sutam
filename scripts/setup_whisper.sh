#!/bin/bash

# Exit on error
set -e

# Define whisper.cpp directory and version
# We are cloning it into a vendor directory to keep the project root clean.
WHISPER_CPP_DIR="vendor/whisper.cpp"
MODEL="large-v2"
WHISPER_CPP_TAG="v1.7.6" # Pinning to a specific stable version

# 1. Clone whisper.cpp if it doesn't exist
if [ ! -d "$WHISPER_CPP_DIR" ]; then
  echo "Cloning whisper.cpp..."
  # We need to create the vendor directory first.
  mkdir -p vendor
  git clone https://github.com/ggml-org/whisper.cpp.git "$WHISPER_CPP_DIR"
else
  echo "whisper.cpp directory already exists. Fetching latest tags..."
  (cd "$WHISPER_CPP_DIR" && git fetch --all --tags)
fi

cd "$WHISPER_CPP_DIR"

# 2. Checkout the specified tag for reproducibility
echo "Checking out tag ${WHISPER_CPP_TAG}..."
git checkout "tags/${WHISPER_CPP_TAG}" -f

# 3. Download the model if it doesn't exist
# The model files are placed in the models directory inside whisper.cpp
MODEL_FILE="models/ggml-${MODEL}.bin"
if [ ! -f "$MODEL_FILE" ]; then
  echo "Downloading Whisper model ${MODEL}..."
  ./models/download-ggml-model.sh "${MODEL}"
else
  echo "Whisper model ${MODEL} already exists."
fi

# 4. Build whisper.cpp with GPU support
# Remove previous build directory to ensure a clean build from the correct environment
if [ -d "build" ]; then
    echo "Removing previous build directory..."
    rm -rf build
fi
echo "Building whisper.cpp with CUDA support..."
cmake -B build -DGGML_CUDA=1
cmake --build build -j --config Release

echo "Setup complete. You can find the executable at $(cd ../..; pwd)/${WHISPER_CPP_DIR}/build/bin/whisper-cli"
