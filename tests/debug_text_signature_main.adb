with Debug_Text_Signature_Bindings;
with Interfaces.C.Extensions;
with Interfaces.C.Strings;
with System;
with Test_Utils;

procedure Debug_Text_Signature_Main is
   use type Interfaces.C.Extensions.bool;

   Text : Interfaces.C.Strings.chars_ptr :=
     Interfaces.C.Strings.New_String ("debug text signature");
   Ok : Interfaces.C.Extensions.bool;
begin
   Ok :=
     Debug_Text_Signature_Bindings.Debug_Text_Signature_Call
       (Renderer => System'To_Address (16#1234#),
        X        => 36.0,
        Y        => 84.0,
        Text     => Text);

   Interfaces.C.Strings.Free (Text);

   Test_Utils.Check ("debug_text_signature",
                     Ok /= Interfaces.C.Extensions.bool'Val (0));
end Debug_Text_Signature_Main;
