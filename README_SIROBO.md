# ArduPilot Rover 4.7.1 Stable — Cube Black (Pixhawk 2.1)

Fork checkout can be located anywhere (including sirobo HDD or MiniPC1).

- Official upstream: https://github.com/ArduPilot/ardupilot
- Release tag: `Rover-4.7.1`, commit `dbe792162d06cab66c3475fd5556bf7a120f119e`
- RTOS: **ChibiOS** (not PX4/NuttX), Git submodule `modules/ChibiOS`
- Board target: **CubeBlack**, firmware board ID **9** (FMUv3)
- Build system: `./waf` (not PlatformIO)
- Build artifacts: `build/CubeBlack/bin/ardurover.apj` and `ardurover.bin`

## Build (like pio run)

```bash
cd /path/to/ardupilot-firmware
./ardupilot.sh doctor
./ardupilot.sh deps
./ardupilot.sh configure
./ardupilot.sh build
```

Or directly (official Waf commands):
```bash
./waf configure --board CubeBlack
./waf rover -j 8
```

## Upload (like pio run -t upload)

```bash
# This actually rewrites CubeBlack flash. Run only if intended.
ARDU_CONFIRM_UPLOAD=YES ./ardupilot.sh upload
```

Or official Waf uploader:
```bash
python3 Tools/scripts/uploader.py --port /dev/ttyACM0 --baud-flightstack 115200 --baud-bootloader 115200 build/CubeBlack/bin/ardurover.apj
```

Never force a mismatched board ID. Make sure the vehicle is disarmed and disconnect motor/actuator power before flashing; back up parameters. Flashing is **not** performed by the project setup process. The attached Cube Black already ran **ArduPilot Rover 4.7.1 Official** after its earlier flash.

## File roles
`modules/ChibiOS/`: RTOS and HAL; `modules/mavlink/`: MAVLink communication; `libraries/`: navigation/control drivers; `Rover/`: Rover logic; `Tools/scripts/uploader.py`: serial upload; `build/`: compilation artifacts.

This drive is NTFS3, so a full source build may be slower than on an ext4 SSD; nevertheless the project's build output is placed on the requested HDD path.
