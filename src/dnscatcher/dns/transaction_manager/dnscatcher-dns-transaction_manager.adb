-- Copyright 2019 Michael Casadevall <michael@casadevall.pro>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to
-- deal in the Software without restriction, including without limitation the
-- rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;

with Ada.Exceptions;      use Ada.Exceptions;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Strings.Hash;

with DNSCatcher.Utils;                use DNSCatcher.Utils;
with DNSCatcher.Utils.Logger;         use DNSCatcher.Utils.Logger;
with DNSCatcher.DNS.Processor.Packet; use DNSCatcher.DNS.Processor.Packet;

package body DNSCatcher.DNS.Transaction_Manager is
   -- Handle the map for tracking transactions to/from source
   task body DNS_Transaction_Manager_Task is
      Outbound_Packet_Queue : DNS_Raw_Packet_Queue_Ptr;
      Hashmap_Key           : IP_Transaction_Key;
      Hashmap_Cursor        : DNS_Transaction_Maps.Cursor;
      Outbound_Packet       : Raw_Packet_Record;
      Transaction_Hashmap   : DNS_Transaction_Maps.Map;
      Transaction           : DNS_Transaction_Ptr;
      Running               : Boolean := False;
      Logger_Packet         : Logger_Message_Packet_Ptr;
      Parsed_Packet         : Parsed_DNS_Packet_Ptr;
   begin
      loop
         Logger_Packet := null;
         while Running = False
         loop
            Transaction := null;
            select
               accept Set_Packet_Queue (Queue : in DNS_Raw_Packet_Queue_Ptr) do
                  Outbound_Packet_Queue := Queue;
               end Set_Packet_Queue;
            or
               accept Start do
                  if Outbound_Packet_Queue /= null
                  then
                     Logger_Packet := new Logger_Message_Packet;
                     Logger_Packet.Push_Component ("Transaction Manager");

                     Running := True;
                     Logger_Packet.Log_Message
                       (INFO, "Transaction Manager Started!");
                     Logger_Queue.Add_Packet (Logger_Packet);
                  end if;
               end Start;
            or
               accept Stop do
                  null;
               end Stop;
            or
               terminate;
            end select;
         end loop;

         while Running
         loop
            Logger_Packet := new Logger_Message_Packet;
            Logger_Packet.Push_Component ("Transaction Manager");

            select
               accept From_Client_Resolver_Packet
                 (Packet : Raw_Packet_Record_Ptr;
                  Local  : Boolean) do
                  declare
                     Log_String         : Unbounded_String;
                     Transaction_String : String (1 .. 8);
                  begin
                     Log_String :=
                       To_Unbounded_String ("Downstream DNS Transaction ID: ");
                     Put
                       (Transaction_String,
                        Integer (Packet.Raw_Data.Header.Identifier),
                        Base => 16);
                     Log_String :=
                       Log_String & To_Unbounded_String (Transaction_String);
                     Logger_Packet.Log_Message (DEBUG, To_String (Log_String));
                  end;

                  Hashmap_Key :=
                    IP_Transaction_Key
                      (Packet.To_Address & Packet.To_Port'Image &
                       Packet.Raw_Data.Header.Identifier'Image);

                  -- Create the key if necessary
                  Hashmap_Cursor := Transaction_Hashmap.Find (Hashmap_Key);

                  if Hashmap_Cursor = DNS_Transaction_Maps.No_Element
                  then
                     Transaction := new DNS_Transaction;
                     Transaction.Client_Resolver_Address :=
                       Packet.From_Address;
                     Transaction.Client_Resolver_Port    := Packet.From_Port;
                     Transaction.Server_Resolver_Address := Packet.To_Address;
                     Transaction.Server_Resolver_Port    := Packet.To_Port;
                     Transaction.DNS_Transaction_Id      :=
                       Packet.Raw_Data.Header.Identifier;
                     Transaction.Local_Request := Local;
                     Transaction_Hashmap.Insert (Hashmap_Key, Transaction);
                  end if;

                  -- Save the packet
                  Transaction := Transaction_Hashmap (Hashmap_Key);
                  Transaction.From_Client_Resolver_Packet := Packet;

                  -- Try to parse the packet
                  Parsed_Packet := Packet_Parser (Logger_Packet, Packet);
                  Free_Parsed_DNS_Packet (Parsed_Packet);

                  -- Rewrite the DNS Packet and send it on it's way
                  Outbound_Packet_Queue.Put (Packet.all);
               exception
                  when Exp_Error : others =>
                     begin
                        Logger_Packet.Log_Message
                          (ERROR,
                           "Transaction error: " &
                           Exception_Information (Exp_Error));
                     end;
               end From_Client_Resolver_Packet;
            or
               accept From_Upstream_Resolver_Packet
                 (Packet : Raw_Packet_Record_Ptr) do
                  declare
                     Log_String         : Unbounded_String;
                     Transaction_String : String (1 .. 8);
                  begin
                     Log_String :=
                       To_Unbounded_String ("Upstream DNS Transaction ID: ");
                     Put
                       (Transaction_String,
                        Integer (Packet.Raw_Data.Header.Identifier),
                        Base => 16);
                     Log_String :=
                       Log_String & To_Unbounded_String (Transaction_String);
                     Logger_Packet.Log_Message (DEBUG, To_String (Log_String));
                  end;

                  Hashmap_Key :=
                    IP_Transaction_Key
                      (Packet.From_Address & Packet.From_Port'Image &
                       Packet.Raw_Data.Header.Identifier'Image);

                  -- Create the key if necessary
                  Hashmap_Cursor := Transaction_Hashmap.Find (Hashmap_Key);

                  if Hashmap_Cursor = DNS_Transaction_Maps.No_Element
                  then
                     Transaction := new DNS_Transaction;
                     Transaction.Client_Resolver_Address := Packet.To_Address;
                     Transaction.Client_Resolver_Port    := Packet.To_Port;
                     Transaction.Server_Resolver_Address :=
                       Packet.From_Address;
                     Transaction.Server_Resolver_Port := Packet.From_Port;
                     Transaction.DNS_Transaction_Id   :=
                       Packet.Raw_Data.Header.Identifier;
                     Transaction_Hashmap.Insert (Hashmap_Key, Transaction);
                  end if;

                  -- Save the packet
                  Transaction := Transaction_Hashmap (Hashmap_Key);
                  Transaction.From_Upstream_Resolver_Packet := Packet;

                  -- Try to parse the packet
                  Parsed_Packet := Packet_Parser (Logger_Packet, Packet);
                  Logger_Packet.Log_Message
                    (INFO,
                     To_String (Transaction.Server_Resolver_Address) & " -> " &
                     To_String (Transaction.Client_Resolver_Address));
                  for I of Parsed_Packet.Answer
                  loop
                     Logger_Packet.Log_Message (INFO, "    " & I.Print_Packet);
                  end loop;
                  Free_Parsed_DNS_Packet (Parsed_Packet);

                  -- If we're a local response, we don't resend it
                  if Transaction.Local_Request /= True
                  then
                     -- Flip the packet around so it goes to the right place
                     Outbound_Packet            := Packet.all;
                     Outbound_Packet.To_Address :=
                       Transaction.Client_Resolver_Address;
                     Outbound_Packet.To_Port :=
                       Transaction.Client_Resolver_Port;
                     Outbound_Packet_Queue.Put (Outbound_Packet);
                  end if;

               exception
                  when Exp_Error : others =>
                     begin
                        Logger_Packet.Log_Message
                          (ERROR,
                           "Transaction error: " &
                           Exception_Information (Exp_Error));
                     end;
               end From_Upstream_Resolver_Packet;
            or
               accept Stop do
                  begin
                     Transaction_Hashmap.Iterate (Free_Hash_Map_Entry'Access);
                  end;

                  Running := False;
               end Stop;
            or
               delay 0.1;
            end select;
            if Logger_Packet /= null
            then
               Logger_Queue.Add_Packet (Logger_Packet);
            end if;
         end loop;
      end loop;
   end DNS_Transaction_Manager_Task;

   -- Clean up the pool and get rid of everything we don't need
   procedure Free_Hash_Map_Entry (c : DNS_Transaction_Maps.Cursor) is
      procedure Free_Transaction is new Ada.Unchecked_Deallocation
        (Object => DNS_Transaction, Name => DNS_Transaction_Ptr);
      procedure Free_Packet is new Ada.Unchecked_Deallocation
        (Object => Raw_Packet_Record, Name => Raw_Packet_Record_Ptr);
      P : DNS_Transaction_Ptr;
   begin
      P := Element (c);

      if P.From_Client_Resolver_Packet /= null
      then
         if P.From_Client_Resolver_Packet.Raw_Data.Data /= null
         then
            Free_Stream_Element_Array_Ptr
              (P.From_Client_Resolver_Packet.Raw_Data.Data);
         end if;
         Free_Packet (P.From_Client_Resolver_Packet);
      end if;

      if P.From_Upstream_Resolver_Packet /= null
      then
         if P.From_Upstream_Resolver_Packet.Raw_Data.Data /= null
         then
            Free_Stream_Element_Array_Ptr
              (P.From_Upstream_Resolver_Packet.Raw_Data.Data);
         end if;
         Free_Packet (P.From_Upstream_Resolver_Packet);
      end if;

      Free_Transaction (P);
   end Free_Hash_Map_Entry;

   function IP_Transaction_Key_HashID
     (id : IP_Transaction_Key)
     return Hash_Type
   is
   begin
      return Ada.Strings.Hash (To_String (id));
   end IP_Transaction_Key_HashID;
end DNSCatcher.DNS.Transaction_Manager;
