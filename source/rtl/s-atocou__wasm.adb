------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--               S Y S T E M . A T O M I C _ C O U N T E R S                --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--  WASM implementation without thread support. This runtime is built       --
--  without WASM threads (no SharedArrayBuffer), so there is no concurrent  --
--  access and ordinary loads/stores are sufficient. If thread support is   --
--  added in the future, this body must be replaced with one using WASM     --
--  atomic instructions (i32.atomic.rmw.add etc.) or LLVM atomics.         --
--                                                                          --
--  Note: Atomic_Unsigned deliberately disables "+" and "-" operators to    --
--  prevent BT := BT + 1 patterns. We use 'Succ/'Pred instead.             --
--                                                                          --
------------------------------------------------------------------------------

package body System.Atomic_Counters is

   ---------------
   -- Decrement --
   ---------------

   function Decrement (Item : in out Atomic_Counter) return Boolean is
   begin
      Item.Value := Atomic_Unsigned'Pred (Item.Value);
      return Item.Value = 0;
   end Decrement;

   function Decrement
     (Item : aliased in out Atomic_Unsigned) return Boolean
   is
   begin
      Item := Atomic_Unsigned'Pred (Item);
      return Item = 0;
   end Decrement;

   procedure Decrement (Item : aliased in out Atomic_Unsigned) is
   begin
      Item := Atomic_Unsigned'Pred (Item);
   end Decrement;

   ---------------
   -- Increment --
   ---------------

   procedure Increment (Item : in out Atomic_Counter) is
   begin
      Item.Value := Atomic_Unsigned'Succ (Item.Value);
   end Increment;

   procedure Increment (Item : aliased in out Atomic_Unsigned) is
   begin
      Item := Atomic_Unsigned'Succ (Item);
   end Increment;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Item : out Atomic_Counter) is
   begin
      Item.Value := 1;
   end Initialize;

   ------------
   -- Is_One --
   ------------

   function Is_One (Item : Atomic_Counter) return Boolean is
   begin
      return Item.Value = 1;
   end Is_One;

end System.Atomic_Counters;
