#!/bin/bash
set -euo pipefail

CMAKE_CUDA_ARCHITECTURES="80;86;89;90;120"
WORK_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Detect CUDA version (e.g. "12.4" -> "cu124")
CUDA_VERSION=$(nvcc --version | grep -oP 'release \K[0-9]+\.[0-9]+')
CUDA_TAG="cu$(echo "${CUDA_VERSION}" | tr -d '.')"
echo "=== Detected CUDA ${CUDA_VERSION} (${CUDA_TAG}) ==="

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

echo "=== Renaming wheels to include CUDA version ==="
for whl in "${PROJECT_DIR}"/dist/*.whl; do
    new_name=$(basename "${whl}" | sed "s/\(-[0-9][0-9.]*\)-/\1+${CUDA_TAG}-/")
    if [ "$(basename "${whl}")" != "${new_name}" ]; then
        mv "${whl}" "${PROJECT_DIR}/dist/${new_name}"
    fi
done

echo "=== Done ==="
ls -la "${PROJECT_DIR}/dist/"

cd "${PROJECT_DIR}"
echo "=== Uploading wheels ==="
pixi run twine upload --repository-url https://pypi.internal.paralleldomain.com/ --username "" --password "" \
    dist/kiss_slam-*+${CUDA_TAG}-*.whl \
    dist/map_closures-*+${CUDA_TAG}-*.whl