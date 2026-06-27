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

   --  Size of the C "struct file_attributes" (adaint.h) for the wasm32 ABI:
   --  int + 7 unsigned char (+ padding) + OS_Time(int64) + __int64 = 32 bytes.
   --  Needed by System.File_Attributes for Ada.Directories.
   SIZEOF_struct_file_attributes : constant := 32;

   --  Emscripten musl "struct dirent" size for wasm32 (d_name at offset 19,
   --  d_name[256] => 275, padded to 280). Read-buffer size for __gnat_readdir.
   SIZEOF_struct_dirent_alloc : constant := 280;

   --  errno value for "No such file or directory" (musl).
   ENOENT : constant := 2;

end System.OS_Constants;
