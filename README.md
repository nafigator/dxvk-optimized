# DXVK (x86-64-v4 optimized)

Custom builds of [DXVK](https://github.com/doitsujin/dxvk) with `-march=x86-64-v4 -O3` and related flags for AMD Zen 4 CPUs.

Built from upstream DXVK source with minimal patches (compiler flags, AVX-check removal, Clang 22 compatibility).

## Requirements

- **Architecture:** amd64
- **CPU:** with **AVX-512** support (x86-64-v4)
  - AMD Zen 4 (Ryzen 7000/8000/9000)
- Wine 8.0+ or Proton 8.0+

DLLs will crash with `Illegal instruction` on CPUs without AVX-512.

## Installation

1. Download the archive from the [Releases](../../releases) page.

2. Extract it:

   ```bash
   tar --zstd -xf dxvk-*.tar.zst
   cd dxvk-*/
   ```

3. Copy DLLs into your Wine prefix:

   ```bash
   export WINEPREFIX=/path/to/your/prefix
   cp x64/*.dll "$WINEPREFIX/drive_c/windows/system32/"
   cp x86/*.dll "$WINEPREFIX/drive_c/windows/syswow64/"
   ```

4. Set DLL overrides in `winecfg` to **"native, then builtin"** for:

    - `d3d8`
    - `d3d9`
    - `d3d10core`
    - `d3d11`
    - `dxgi`

## Clear shader caches after installation

**Mandatory.** Old shader caches are incompatible with the new library version and will cause crashes or rendering artifacts.

```bash
rm -rf ~/.cache/dxvk/* \
       ~/.cache/mesa_shader_cache*
```

## Verification

Launch the game with HUD enabled:

```bash
DXVK_HUD=1 WINEPREFIX=/path/to/your/prefix wine /path/to/game.exe
```

A HUD overlay with FPS and GPU info confirms DXVK is active.

## Build Architecture

- Compiler: `Clang` from [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) 20260922 (UCRT)
- Linker: `LLD`
- Build flags: `-march=x86-64-v4, -mtune=znver4, -O3, -fomit-frame-pointer, -falign-functions=32, -falign-loops=32`
- Patches applied:
    - Removed upstream AVX build check (safe with Clang's correct stack alignment)
    - `std::tuple()` → `std::tuple<>()` for Clang 22 compatibility

## Expected Performance

| Component | Gain | Comment |
|---|---|---|
| CPU part of driver (D3D9/10/11 translation) | 1–5% | Noticeable in CPU-bound scenarios |
| GPU-bound games | ~0% | Bottleneck is GPU/memory, not driver code |

**Honest warning:** do not expect a "magic" speedup. The main benefit is more efficient CPU usage in games that are limited by D3D call overhead. For Radeon 780M the main limiter is memory bandwidth, not translation layer code.

## How It Is Built

GitHub Actions workflow:

1. Starts the `archlinux/archlinux:multilib-devel` container.
2. Installs `clang`, `llvm`, `lld`, `meson`, `ninja`, `glslang`.
3. Downloads and installs `llvm-mingw` toolchain to `/opt/llvm-mingw`.
4. Clones DXVK source at the tagged release.
5. Copies Clang cross-files from `.github/helpers/`.
6. Applies compatibility patches.
7. Builds 64-bit and 32-bit DLLs via `meson` + `ninja`.
8. Packages DLLs into `dxvk-<version>.tar.zst`.
9. Uploads archive as artifact and attaches it to the release.

Source workflow: [`.github/workflows/build.yml`](.github/workflows/build.yml).

## Important

- Packages are built **only for AMD Zen 4** (or other CPUs with AVX-512).
- **Do not install** these DLLs if you are unsure about AVX-512 support.
- DXVK manipulation in online multiplayer games may be considered cheating. **Use at your own risk.**
- Not affiliated with the upstream project. Report build-specific issues in this repository's [Issues](../../issues) tracker.

## License

Build scripts and workflows in this repository are licensed under the MIT License.

DXVK itself is distributed under the [zlib license](https://github.com/doitsujin/dxvk/blob/master/LICENSE). The compiled DLLs in Releases are redistributions of DXVK under its original license.
