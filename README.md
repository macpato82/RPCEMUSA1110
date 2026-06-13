# RPCEmu — SA-1110 fork

A fork of **[RPCEmu](http://www.marutan.net/rpcemu/) 0.9.5**, an emulator of
Acorn's Risc PC and A7000 machines, adding a new StrongARM machine model and a
number of fixes.

RPCEmu is licensed under the GPL — see [COPYING](COPYING).

> **ROM included.** This repository ships `roms/RISCPC.ROM` — **RISC OS 5.31**,
> a RISC OS Open build that is redistributable under the Apache License 2.0.
> See [roms/RISC-OS-5-LICENCE.txt](roms/RISC-OS-5-LICENCE.txt). You can also get
> the latest official images from <https://www.riscosopen.org/>.

---

## What's different in this fork

### New machine model
- **Risc PC – StrongARM (SA-1110 compat) (experimental)** — a new selectable
  machine (`CPUModel_SA1110`, config key `RPCSA1110`).
  - A genuine SA-1110 reports the Intel implementer ID (`0x69…`), which the
    Risc PC RISC OS ROM does not recognise — it fails CPU setup and hangs at the
    startup banner. To boot reliably, this model reports the **exact SA-110
    CP15 ID (`0x4401a102`)** that the ROM accepts, so RISC OS treats it as a
    StrongARM and boots through to the desktop. It is therefore
    StrongARM-compatible on the stock Risc PC ROM.

### Fixes
- **1920×1080 (and other large-mode) crash.** The video update wrapped the
  video thread's framebuffer (`thr.bitmap`) in a `QImage` and passed it to the
  GUI thread via a queued signal *without copying*. When the machine thread then
  ran `resizedisplay()` → `realloc()` (e.g. on a screen-mode change), it could
  free/move the buffer the GUI thread was still reading — a use-after-free that
  reliably crashed when switching to large modes. Fixed by deep-copying the
  image before it crosses the thread boundary (`src/qt5/rpc-qt5.cpp`).
- **Configurable Phoebe (RPC2) memory.** The Phoebe model was hard-locked to
  256 MB RAM / 4 MB VRAM. It now honours the user-selected RAM and VRAM sizes
  like the other Risc PC models (`src/qt5/settings.cpp`, `src/rpcemu.c`).
- **IOMD2 register 0xCC.** The read path returned `iomd.dmaext` but the write
  path discarded the value; the write now stores it, matching the read
  (`src/iomd.c`).
- **Safety hardening.** `vsprintf` → `vsnprintf` and `sprintf` → `snprintf` in
  the core logging and register-dump paths (`src/rpcemu.c`, `src/arm.c`,
  `src/ArmDynarec.c`).
- **Modern-compiler build fix.** `src/hostfs.c` used `typedef int bool;`, which
  is an error on GCC defaulting to C23 (where `bool` is a keyword). Replaced
  with `#include <stdbool.h>`.

---

## Requirements

- A C/C++ toolchain (GCC/Clang) and `make`
- **Qt 5** (Widgets, GUI, Multimedia) and `qmake`
- A **RISC OS ROM image** in a `roms/` directory next to the executable. One is
  included here (`roms/RISCPC.ROM`, RISC OS 5.31); newer official builds are at
  <https://www.riscosopen.org/>.
- Optionally, a HostFS directory and disc images for storage.

## Building (Linux)

```sh
cd src/qt5

# Recompiler (dynarec) build — recommended:
qmake CONFIG+=dynarec rpcemu.pro
make -j"$(nproc)"

# …or the portable interpreter build:
qmake rpcemu.pro
make -j"$(nproc)"
```

The resulting `rpcemu-recompiler` / `rpcemu-interpreter` binary is placed in the
repository root. Run it from a directory containing your `roms/` folder.

## Running the SA-1110 model

Launch the emulator, open the configuration dialog, and pick
**“Risc PC – StrongARM (SA-1110 compat) (experimental)”** from the hardware
list, or set `model=RPCSA1110` in `rpc.cfg`.

---

## Not included (and why)

The following are deliberately excluded (see [.gitignore](.gitignore)):

- **HostFS content** — a full RISC OS environment includes copyrighted OS and
  application files.
- Proprietary ROMs (RISC OS 4 / Select / Six). Only the redistributable
  RISC OS 5 ROM is included.
- Disc images, `cmos.ram`, local `rpc.cfg`, and build artifacts.

## Credits

- RPCEmu by the RPCEmu developers — <http://www.marutan.net/rpcemu/>
- Edited by RISCOS Technologies
