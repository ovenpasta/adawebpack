# Supported packages of the standard Ada library

Packages available in **both** `rts-wasm` and `rts-wasm-emcc` unless
marked otherwise.

 * Ada
   * Assertions
   * Calendar *(rts-wasm-emcc only - requires Emscripten `clock_gettime`)*
   * Characters
     * Wide_Wide_Latin_1
   * Containers
     * Doubly_Linked_Lists
     * Hashed_Maps
     * Hashed_Sets
     * Ordered_Maps
     * Ordered_Sets
     * Vectors
   * Exceptions
   * Finalization
   * IO_Exceptions
   * Numerics
     * Elementary_Functions
     * Generic_Elementary_Functions
     * Long_Elementary_Functions
     * Long_Long_Elementary_Functions
   * Streams
   * Tags
   * Unchecked_Conversion
   * Unchecked_Deallocation
 * GNAT
   * Array_Split
   * IO
   * Regpat
   * String_Split
 * Interfaces
 * System
   * Address_To_Access_Conversions
   * Machine_Code
   * Storage_Elements
   * Storage_Pools
     * Subpools

## Notes

**`Ada.Calendar`** is available in `rts-wasm-emcc` only. It requires
Emscripten's POSIX time emulation (`clock_gettime`, `localtime_r`).
Not available in `rts-wasm` (standalone WASM without Emscripten).

**`Ada.Containers`** packages are available in both runtimes.
Tampering checks are disabled by default (compiled with `-gnatp`).

**`delay` statements** (`delay D` and `delay until T`) work in
`rts-wasm-emcc`. They call `nanosleep` via `System.OS_Primitives.Timed_Delay`.
Without `-sASYNCIFY` at the `emcc` link step, `nanosleep` busy-waits
(blocking the browser main thread for the duration). With `-sASYNCIFY` it
yields to the event loop. Not available in `rts-wasm`.

**`Ada.Strings.Fixed`** is not currently available in either WASM runtime.
