------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                   S Y S T E M . O S _ C O N S T A N T S                  --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--  WASM32 / Emscripten variant.                                            --
--  Values match the Emscripten musl ABI for wasm32.                        --
--                                                                          --
--  time_t    : int64  (8 bytes) -- Emscripten musl uses 64-bit time_t      --
--  tv_usec   : int    (4 bytes) -- suseconds_t = int in wasm32 musl         --
--  tv_nsec   : long   (4 bytes) -- long = 32-bit in wasm32                  --
--                                                                          --
------------------------------------------------------------------------------

package System.OS_Constants with Pure is

   SIZEOF_tv_sec  : constant := 8;
   SIZEOF_tv_usec : constant := 4;
   SIZEOF_tv_nsec : constant := 4;

   MAX_tv_sec : constant := 2 ** (SIZEOF_tv_sec * 8 - 1) - 1;

   CLOCK_REALTIME  : constant := 0;
   CLOCK_MONOTONIC : constant := 1;

end System.OS_Constants;
