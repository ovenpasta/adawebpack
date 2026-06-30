--  Elaboration-only main for the interactive browser shell.
--
--  The real work happens in HAC_Runner.Compile_And_Run, which is exported to
--  JavaScript as "hac_compile_and_run" and invoked from the page each time the
--  user clicks Run. This main exists only so the binder elaborates the Ada
--  runtime (and HAC's library-level state) before any exported call.

with HAC_Runner;
pragma Unreferenced (HAC_Runner);

procedure HAC_Web is
begin
   null;
end HAC_Web;
