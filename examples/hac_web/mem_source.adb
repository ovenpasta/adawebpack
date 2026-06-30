with Ada.Streams;

package body Mem_Source is

   --  A minimal read-only in-memory stream serving an Ada source text.
   --  Declared at library level so an allocator can hand it to the
   --  library-level Source_Stream_Access type.

   type Mem_Stream is new Ada.Streams.Root_Stream_Type with record
      Data : not null access constant String;
      Pos  : Natural := 0;  --  number of characters already consumed
   end record;

   overriding procedure Read
     (S    : in out Mem_Stream;
      Item :    out Ada.Streams.Stream_Element_Array;
      Last :    out Ada.Streams.Stream_Element_Offset);

   overriding procedure Write
     (S    : in out Mem_Stream;
      Item : in     Ada.Streams.Stream_Element_Array) is null;

   procedure Read
     (S    : in out Mem_Stream;
      Item :    out Ada.Streams.Stream_Element_Array;
      Last :    out Ada.Streams.Stream_Element_Offset)
   is
      use type Ada.Streams.Stream_Element_Offset;
      Remaining : constant Natural := S.Data'Length - S.Pos;
      Count     : constant Natural := Natural'Min (Remaining, Natural (Item'Length));
   begin
      if Count = 0 then
         --  Source exhausted (or a zero-length request): no elements read.
         --  Signal end of file the standard way, Last < Item'First, without
         --  touching Item or advancing Pos.
         Last := Item'First - 1;
         return;
      end if;

      for K in 0 .. Count - 1 loop
         Item (Item'First + Ada.Streams.Stream_Element_Offset (K)) :=
           Ada.Streams.Stream_Element
             (Character'Pos (S.Data (S.Data'First + S.Pos + K)));
      end loop;
      Last := Item'First + Ada.Streams.Stream_Element_Offset (Count) - 1;
      S.Pos := S.Pos + Count;
   end Read;

   function New_String_Stream
     (Text : String) return HAC_Sys.Co_Defs.Source_Stream_Access is
   begin
      return new Mem_Stream'(Ada.Streams.Root_Stream_Type with
                               Data => new String'(Text), Pos => 0);
   end New_String_Stream;

end Mem_Source;
