#!/usr/bin/env bash
# ArduPilot Rover 4.7.1 Stable / Hex CubeBlack helper.
set -Eeuo pipefail
cd "$(dirname "$(readlink -f "$0")")"
BOARD="${ARDU_BOARD:-CubeBlack}"
JOBS="${JOBS:-1}"
if [[ -f ../firmware-toolchain-env.sh ]]; then
  source ../firmware-toolchain-env.sh
fi
# User-local ARM GNU toolchain is used only when a system compiler is absent.
if ! command -v arm-none-eabi-gcc >/dev/null 2>&1; then
  TOOLCHAIN_ROOT="${ARM_GCC_ROOT:-$HOME/.local/opt/arm-gcc-10.3/usr}"
  if [[ -x "$TOOLCHAIN_ROOT/bin/arm-none-eabi-gcc" ]]; then
    export PATH="$TOOLCHAIN_ROOT/bin:$PATH"
    export CPATH="$TOOLCHAIN_ROOT/include/newlib${CPATH:+:$CPATH}"
    export LIBRARY_PATH="$TOOLCHAIN_ROOT/lib/arm-none-eabi/newlib/thumb/v7e-m+fp/hard:$TOOLCHAIN_ROOT/lib/arm-none-eabi/newlib:$TOOLCHAIN_ROOT/lib/arm-none-eabi/newlib/thumb/v7e-m/nofp${LIBRARY_PATH:+:$LIBRARY_PATH}"
  fi
fi

PORT="${ARDU_PORT:-/dev/ttyACM0}"
IMAGE="build/$BOARD/bin/ardurover.apj"
case "${1:-help}" in
 doctor)
  echo "Project: $PWD"
  echo "Git commit: $(git rev-parse HEAD)"
  echo "ArduPilot version:"
  git tag --points-at HEAD | grep "^Rover-" | head -10
  echo "Board: $BOARD"
  for executable in python3 git make arm-none-eabi-gcc; do command -v "$executable"; done
  echo "Missing Git submodules:"
  git submodule status --recursive | grep '^-' || true
  echo "USB CubeBlack:"
  ls -l /dev/serial/by-id/ 2>/dev/null || true
  echo "Image:"
  ls -lh "$IMAGE" 2>/dev/null || true
  ;;
 deps)
  git submodule update --init --recursive --jobs "$JOBS"
  ;;
 configure)
  ./waf configure --board "$BOARD"
  ;;
 build)
  if [[ -f ../firmware_safe_build.sh ]]; then
    source ../firmware_safe_build.sh
    prepare_safe_firmware_build
  fi
  if [[ -f ../firmware_relocation_guard.py ]]; then
    python3 ../firmware_relocation_guard.py --root "$PWD" --kind ardupilot
  fi
  if [[ ! -f .lock-waf_linux_build ]]; then
    ./waf configure --board "$BOARD"
  fi
  nice -n 10 ionice -c2 -n7 ./waf rover -j "$JOBS"
  ;;
 upload)
  if [[ "${ARDU_CONFIRM_UPLOAD:-}" != "YES" ]]; then
    echo "Upload cancelled: set ARDU_CONFIRM_UPLOAD=YES ./ardupilot.sh upload"
    exit 3
  fi
  [[ -f "$IMAGE" ]] || { echo "Image missing: $IMAGE"; exit 4; }
  python3 - "$IMAGE" <<'PY'
import json,base64,zlib,sys
p=sys.argv[1]
fw=json.load(open(p))
raw=zlib.decompress(base64.b64decode(fw['image']))
assert fw.get('board_id')==9, 'CubeBlack Board ID mismatch'
assert fw.get('image_size')==len(raw) and len(raw)<=2080768, 'Firmware exceeds CubeBlack flash region'
print('Image checked: Board ID 9, bytes:',len(raw))
PY
  echo "IMPORTANT: Disconnect all motor/actuator power; make sure FC disarmed."
  python3 Tools/scripts/uploader.py --port "$PORT" --baud-flightstack 115200 --baud-bootloader 115200 "$IMAGE"
  ;;
 *)
  echo "Usage: ./ardupilot.sh doctor|deps|configure|build|upload"
  echo "Build: ./ardupilot.sh configure && ./ardupilot.sh build"
  echo "Upload (explicit): ARDU_CONFIRM_UPLOAD=YES ./ardupilot.sh upload"
  ;;
esac
