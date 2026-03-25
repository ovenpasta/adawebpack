--  WASM RTS: abort helper for No_Exception_Propagation builds.
--  Provides a single point for calling __gnat_last_chance_handler
--  so WASM-specific package body variants do not repeat the import.

package System.WASM_Abort with Pure is

   procedure Abort_Program
     (Message : System.Address;
      Line    : Integer)
   with
     Import,
     Convention    => C,
     External_Name => "__gnat_last_chance_handler",
     No_Return;

end System.WASM_Abort;
