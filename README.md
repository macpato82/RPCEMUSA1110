# RPCEmu — SA-1110 fork

A fork of **[RPCEmu](http://www.marutan.net/rpcemu/) 0.9.5**, the emulator of
Acorn's Risc PC and A7000 machines. This fork adds a StrongARM (SA-1110)
machine model, a dual‑machine startup selector, Access+/ShareFS networking over
NAT, a Qt 6 port, **cross‑platform builds for Linux, Windows and macOS**, and a
range of fixes.

RPCEmu is licensed under the GPL — see [COPYING](COPYING).

> **ROM included.** This repository ships `roms/RISCPC.ROM` — **RISC OS 5.31**, a
> RISC OS Open build redistributable under the Apache License 2.0. See
> [roms/RISC-OS-5-LICENCE.txt](roms/RISC-OS-5-LICENCE.txt). Newer official images
> are at <https://www.riscosopen.org/>.

---

## Downloads

Pre‑built binaries for **Linux, Windows and macOS** are produced by GitHub
Actions for every push, and are attached to tagged
[Releases](../../releases). They are also downloadable as artifacts from any
build run under the [Actions](../../actions) tab.

| Platform | Build | Notes |
| --- | --- | --- |
| **Linux** x86‑64 | CMake, Qt 6, dynarec (recompiler) | Fastest |
| **Windows** x86‑64 | MSYS2/MinGW, Qt 5, interpreter | Qt DLLs bundled |
| **macOS** arm64 | Qt 5, interpreter | `.app` bundle |

> Windows and macOS use the **interpreter** (the ARM→x86 dynarec targets the
> Linux/SysV ABI, so it is not used on Win64 or Apple Silicon). They are slower
> than the Linux recompiler but otherwise fully functional.

---

## What's different in this fork

### Machine models & startup selector
- **Risc PC – StrongARM (SA‑1110 compat)** — a new machine (`RPCSA1110`). A real
  SA‑1110 reports the Intel implementer id, which the Risc PC ROM rejects (hangs
  at the banner); this model reports the exact **SA‑110 CP15 id (`0x4401a102`)**
  the ROM accepts, so RISC OS boots through to the desktop.
- **Dual‑machine startup selector** — on launch you can pick between two fully
  independent machines, each with its own ROM, HostFS, CMOS, config and hard
  disc. A command‑line flag (`--riscos4` / `--riscos5`) selects one directly and
  skips the dialog (handy for per‑machine desktop launchers).
- **A7000+ FPA fix** — `resetfpa()` is now called on reset, initialising the FPA
  system id in FPSR so RISC OS detects the floating‑point accelerator on the
  ARM7500FE.

### Video
- **16 MB VRAM option** (in addition to 2/8 MB) — the maximum that fits the Risc
  PC's `0x02000000` VRAM window.
- **8 MB VRAM on RISC OS 4.39 (Adjust)** — added a ROM patch entry so the 4.39
  Adjust ROM raises its 2 MB VRAM cap to 8 MB, unlocking higher screen modes.
- **Large‑mode crash fixed** — the video framebuffer is now deep‑copied before
  crossing the emulator→GUI thread boundary, fixing a use‑after‑free that
  crashed on 1920×1080 and other large modes.

### Networking — Access+/ShareFS
- **ShareFS over NAT** — a broadcast relay (ported from `rpcemu-extended`, GPL)
  forwards Access+/ShareFS discovery broadcasts between the guest and the host
  LAN, so the emulated machine sees shares on real Acorn machines **without any
  bridge/TAP/sudo setup**. Cross‑platform (Winsock on Windows, POSIX elsewhere).
- **Privilege‑free Ethernet bridging** (Linux) — set `RPCEMU_TAP=<name>` to
  attach to a pre‑existing persistent TAP that is already in your bridge, so no
  elevated privileges are needed at runtime.

### Storage
- **Real disc geometry** — `IDENTIFY DEVICE` now reports the actual `.hdf` image
  size (and advertises LBA), instead of a fixed ~31 GB, so `*Format`/HForm
  create a correctly‑sized disc.

### Qt & platform
- **Qt 6 port** — the audio backend (`QAudioSink`) and GUI build against Qt 6
  (default) or Qt 5.
- **Keyboard fixes** — works under Qt 6 / Wayland (the menu‑open guard is now a
  live check; the xcb platform is preferred when an X display is present).

### Hardening & misc
- NULL‑checks on ROM/VRAM/RAM allocation, `snprintf` throughout, bounded HostFS
  path construction, a NULL‑deref guard in the sound DMA path, and IDE write‑error
  logging. Configurable Phoebe (RPC2) memory; IOMD2 register `0xCC` write fix.

---

## Building

The emulator core is C; the front‑end is Qt (5 or 6). Binaries are placed in the
repository root and must be run from a directory containing a `roms/` folder.

### Linux — CMake (recommended)

```sh
cmake -S . -B build -DRPCEMU_DYNAREC=ON      # recompiler (add =OFF for interpreter)
cmake --build build -j"$(nproc)"
```

Defaults to **Qt 6**; add `-DRPCEMU_QT_VERSION=5` for Qt 5.
Dependencies (Debian/Ubuntu): `build-essential cmake qt6-base-dev qt6-multimedia-dev`.

### Linux / macOS — qmake

```sh
cd src/qt5
qmake CONFIG+=dynarec rpcemu.pro   # or just `qmake rpcemu.pro` for the interpreter
make -j"$(nproc)"
```

macOS (Apple Silicon) is interpreter‑only; install Qt 5 with `brew install qt@5`
and put `$(brew --prefix qt@5)/bin` on `PATH`.

### Windows — MSYS2 / MinGW

```sh
# In an MSYS2 MINGW64 shell, with mingw-w64-x86_64-{gcc,make,qt5-base,qt5-multimedia,qt5-tools}
cd src/qt5
qmake rpcemu.pro
mingw32-make -j2
windeployqt-qt5 --release RPCEmu-Interpreter.exe   # bundle the Qt DLLs
```

See [.github/workflows/build.yml](.github/workflows/build.yml) for the exact,
reproducible build steps used for the released binaries.

---

## Running

- **Machine selector** — launch with no arguments to choose RISC OS 5 / RISC OS 4
  (or pass `--riscos5` / `--riscos4`). Each machine uses its own `rpc.cfg`,
  ROM directory, HostFS, CMOS and hard disc.
- **Networking** — choose **NAT** in the configuration for plug‑and‑play
  networking *and* ShareFS over your LAN. (Ethernet bridging / IP tunnelling are
  Linux‑only; macOS supports NAT only.)
- **Hard discs** — create a blank `.hdf`, attach it, and format it from within
  RISC OS (HForm); it will report its true size.

---

## Known limitations

- Windows and macOS are **interpreter** builds (no dynarec) — see above.
- The **macOS keyboard** is not yet mapped: the key table uses X11 keycodes,
  which differ from the native scan codes Qt reports on macOS. A macOS keymap is
  a planned follow‑up. (Linux and Windows keyboards work.)

---

## Not included (and why)

Deliberately excluded (see [.gitignore](.gitignore)): HostFS content and
proprietary ROMs (RISC OS 4 / Select / Six — only the redistributable RISC OS 5
ROM is shipped), disc images, `cmos.ram`, local `rpc.cfg`, and build artifacts.

## Credits

- RPCEmu by the RPCEmu developers — <http://www.marutan.net/rpcemu/>
- Access+/ShareFS broadcast relay from
  [`rpcemu-extended`](https://github.com/andrewtimmins/rpcemu-extended) (GPL).
- Edited by RISCOS Technologies.
