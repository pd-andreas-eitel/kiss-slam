#!/bin/bash
set -euo pipefail

CMAKE_CUDA_ARCHITECTURES="80;86;89;90;120"
WORK_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cleanup() {
    rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

echo "=== Building map-closures wheel from source ==="
git clone --depth 1 https://github.com/PRBonn/MapClosures.git "${WORK_DIR}/MapClosures"
pixi run -m "${PROJECT_DIR}" pip wheel "${WORK_DIR}/MapClosures/python" --wheel-dir "${WORK_DIR}/wheels" --no-deps

echo "=== Building kiss-slam wheel ==="
rm -f "${PROJECT_DIR}"/dist/map_closures*.whl
pixi run -m "${PROJECT_DIR}" pip wheel "${PROJECT_DIR}" \
    --wheel-dir "${PROJECT_DIR}/dist/" \
    --find-links "${WORK_DIR}/wheels" \
    --no-deps \
    --config-settings="cmake.define.CMAKE_CUDA_ARCHITECTURES=${CMAKE_CUDA_ARCHITECTURES}"

echo "=== Copying map-closures wheel to dist/ ==="
cp "${WORK_DIR}/wheels"/map_closures*.whl "${PROJECT_DIR}/dist/"

echo "=== Done ==="
ls -la "${PROJECT_DIR}/dist/"

cd "${PROJECT_DIR}"
echo "=== Uploading wheels ==="
pixi run twine upload --repository-url https://pypi.internal.paralleldomain.com/ --username "" --password "" \
    "dist/kiss_slam-0.0.2-cp311-cp311-linux_x86_64.whl" \
    "dist/map_closures-2.0.2-cp311-cp311-linux_x86_64.whl"