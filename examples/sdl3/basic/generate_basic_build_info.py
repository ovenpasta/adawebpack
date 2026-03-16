#!/usr/bin/env python3

import os
import subprocess
from pathlib import Path


def capture(command: list[str]) -> str:
    try:
        return subprocess.check_output(
            command,
            stderr=subprocess.STDOUT,
            text=True,
        ).strip()
    except Exception:
        return ""


def ada_string(value: str) -> str:
    return value.replace('"', '""')


def c_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def main() -> int:
    llvm_gcc = os.environ["LLVM_GCC_BIN"]
    output = Path(os.environ["BUILD_INFO_OUT"])
    c_output = Path(os.environ["BUILD_INFO_C_OUT"])

    gnatls = capture(["gnatls", "--version"]).splitlines()
    if gnatls:
        gnat_version = gnatls[0].strip()
    else:
        llvm_gcc_version = capture([llvm_gcc, "--version"]).splitlines()
        gnat_version = (
            llvm_gcc_version[0].strip() if llvm_gcc_version else "unknown GNAT version"
        )

    llvm_version = capture(["llvm-config", "--version"]) or "unknown LLVM version"

    output.write_text(
        "package Basic_Build_Info is\n"
        f'   function GNAT_Line return String is ("{ada_string(gnat_version)} via GNAT-LLVM");\n'
        f'   function LLVM_Line return String is ("LLVM {ada_string(llvm_version)} backend targeting wasm32");\n'
        "end Basic_Build_Info;\n",
        encoding="ascii",
    )

    c_output.write_text(
        '#include <SDL3/SDL.h>\n'
        '#include <SDL3/SDL_stdinc.h>\n\n'
        f'static const char *basic_overlay_gnat_line = "{c_string(gnat_version)} via GNAT-LLVM";\n'
        f'static const char *basic_overlay_llvm_line = "LLVM {c_string(llvm_version)} backend targeting wasm32";\n'
        'static const char *basic_overlay_title_line = "SDL debug text overlay";\n'
        'static char basic_overlay_sdl_line[32];\n\n'
        'const char *basic_overlay_gnat_text(void) {\n'
        '  return basic_overlay_gnat_line;\n'
        '}\n\n'
        'const char *basic_overlay_llvm_text(void) {\n'
        '  return basic_overlay_llvm_line;\n'
        '}\n\n'
        'const char *basic_overlay_title_text(void) {\n'
        '  return basic_overlay_title_line;\n'
        '}\n\n'
        'const char *basic_overlay_sdl_text(void) {\n'
        '  const int version = SDL_GetVersion();\n'
        '  const int major = version / 1000000;\n'
        '  const int minor = (version / 1000) % 1000;\n'
        '  const int patch = version % 1000;\n'
        '  SDL_snprintf(basic_overlay_sdl_line, sizeof(basic_overlay_sdl_line), "SDL %d.%d.%d", major, minor, patch);\n'
        '  return basic_overlay_sdl_line;\n'
        '}\n',
        encoding="ascii",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
