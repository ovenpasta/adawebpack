with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Ordered_Maps;
with Test_Utils;

procedure Containers_Main is

   package Int_Vecs is
     new Ada.Containers.Vectors (Natural, Integer);
   package Int_Lists is
     new Ada.Containers.Doubly_Linked_Lists (Integer);
   package Int_Maps is
     new Ada.Containers.Ordered_Maps (Integer, Integer);

   V : Int_Vecs.Vector;
   L : Int_Lists.List;
   M : Int_Maps.Map;

begin
   --  Vector: append, length, element access, delete
   V.Append (10);
   V.Append (20);
   V.Append (30);
   Test_Utils.Check ("vec length",       Integer (V.Length) = 3);
   Test_Utils.Check ("vec element 0",    V.Element (0) = 10);
   Test_Utils.Check ("vec element 2",    V.Element (2) = 30);
   V.Delete_Last;
   Test_Utils.Check ("vec after delete", Integer (V.Length) = 2);

   --  List: prepend/append, cursor access
   L.Append (1);
   L.Prepend (0);
   L.Append (2);
   Test_Utils.Check ("list length", Integer (L.Length) = 3);
   Test_Utils.Check ("list first",  Int_Lists.Element (L.First) = 0);
   Test_Utils.Check ("list last",   Int_Lists.Element (L.Last)  = 2);

   --  Ordered_Map: insert, contains, element, delete
   M.Insert (1, 100);
   M.Insert (2, 200);
   M.Insert (3, 300);
   Test_Utils.Check ("map length",       Integer (M.Length) = 3);
   Test_Utils.Check ("map contains 2",   M.Contains (2));
   Test_Utils.Check ("map no key 99",    not M.Contains (99));
   Test_Utils.Check ("map element 2",    M.Element (2) = 200);
   M.Delete (2);
   Test_Utils.Check ("map after delete", not M.Contains (2));

end Containers_Main;
