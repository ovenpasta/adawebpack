#!/usr/bin/env python3

import os
import re
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


def main() -> int:
    llvm_config = os.environ.get("LLVM_CONFIG_BIN")
    output = Path(os.environ.get("BUILD_INFO_OUT", ".objs/basic_build_info.ads"))
    output.parent.mkdir(parents=True, exist_ok=True)

    #  An explicit llvm-config wins; otherwise the clang bundled with the
    #  gnat_llvm Alire toolchain (same LLVM as the compiler); otherwise the
    #  llvm-config on PATH.
    bundled_clang = Path(os.environ.get("GNAT_LLVM_PREFIX", "")) / "bin" / "clang"
    if llvm_config:
        llvm_version = capture([llvm_config, "--version"])
    elif os.environ.get("GNAT_LLVM_PREFIX") and bundled_clang.exists():
        match = re.search(r"clang version (\S+)",
                          capture([str(bundled_clang), "--version"]))
        llvm_version = match.group(1) if match else ""
    else:
        llvm_version = capture(["llvm-config", "--version"])
    llvm_version = llvm_version or "unknown LLVM version"

    output.write_text(
        "package Basic_Build_Info is\n"
        f'   function LLVM_Line return String is ("LLVM {ada_string(llvm_version)} backend targeting wasm32");\n'
        "end Basic_Build_Info;\n",
        encoding="ascii",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
