#!/bin/bash
set -euo pipefail

CMAKE_CUDA_ARCHITECTURES="80;86;89;90;120"

echo "Building wheel for CUDA architectures: ${CMAKE_CUDA_ARCHITECTURES}"

pip wheel . \
    --wheel-dir dist/ \
    --config-settings="cmake.define.CMAKE_CUDA_ARCHITECTURES=${CMAKE_CUDA_ARCHITECTURES}"

twine upload --repository-url https://pypi.internal.paralleldomain.com/ dist/kiss_slam-0.0.2-cp312-cp312-linux_x86_64.whl
