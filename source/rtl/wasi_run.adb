------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                             W A S I _ R U N                              --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Exceptions.Last_Chance_Handler;

package body Wasi_Run is

   ----------
   -- Main --
   ----------

   function Main
     (Argc : Integer;
      Argv : System.Address;
      Envp : System.Address) return Integer
   is
      function Binder_Main
        (Argc : Integer;
         Argv : System.Address;
         Envp : System.Address) return Integer;
      pragma Import (C, Binder_Main, "main");

   begin
      return Binder_Main (Argc, Argv, Envp);

   exception
      --  As in Ada.Exceptions.Exception_Traces.Unhandled_Exception_Terminate,
      --  hand over a copy: the last chance handler runs library-level
      --  finalization before printing, which could overwrite E. If that
      --  finalization itself raises, the new exception still escapes (this
      --  handler is not reentrant).

      when E : others =>
         declare
            Occ : Ada.Exceptions.Exception_Occurrence;
         begin
            Ada.Exceptions.Save_Occurrence (Occ, E);
            Ada.Exceptions.Last_Chance_Handler (Occ);
         end;
   end Main;

end Wasi_Run;
