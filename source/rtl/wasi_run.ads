------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                             W A S I _ R U N                              --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

--  Entry point of WASI command programs (rts-wasm-wasi-eh only).

--  wasi-libc's crt1 (_start -> __main_void) calls __main_argc_argv, defined
--  in argv.o (wasi_argv.c), which calls Main below. Main runs the
--  binder-generated main and hands an exception escaping it to the last
--  chance handler: with single-phase WebAssembly exception handling the
--  raise machinery cannot detect that no handler exists, so the exception
--  would otherwise leave _start as a bare wasm exception, without the usual
--  "raised ..." message.

with System;

package Wasi_Run is

   function Main
     (Argc : Integer;
      Argv : System.Address;
      Envp : System.Address) return Integer;
   pragma Export (C, Main, "__gnat_wasi_main");

end Wasi_Run;
