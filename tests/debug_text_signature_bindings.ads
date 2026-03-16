with Interfaces.C;
with Interfaces.C.Extensions;
with Interfaces.C.Strings;
with System;

package Debug_Text_Signature_Bindings is

   function Debug_Text_Signature_Call
     (Renderer : System.Address;
      X        : Interfaces.C.C_float;
      Y        : Interfaces.C.C_float;
      Text     : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Extensions.bool
     with Import => True,
          Convention => C,
          External_Name => "debug_text_signature_call";

end Debug_Text_Signature_Bindings;
