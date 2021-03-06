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

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Ada.Containers.Vectors; use Ada.Containers;
with Ada.Containers.Hashed_Maps;

with Interfaces.C.Extensions; use Interfaces.C.Extensions;

with GNAT.Sockets; use GNAT.Sockets;

with DNSCatcher.Datasets; use DNSCatcher.Datasets;
with DNSCatcher.Types;    use DNSCatcher.Types;

-- @summary
-- The Transaction Manager keeps state of DNS connections and ensures that each
-- individual client gets the correct DNS request without crossrouting them
--
-- @description
-- The Transaction Manager keeps track of the state of DNS handshakes and
-- requests. This is required due to the connectionless nature of UDP, and to
-- a lesser extent with TCP/IP, DoH/DoT. This is handled on a per network layer
-- level, so UDP v4 and v6 have seperate transaction managers to handle result
-- management.
--
package DNSCatcher.DNS.Transaction_Manager is
   -- Collection of stored packets for processing or delivery
   package Stored_Packets_Vector is new Vectors (Natural,
      Raw_Packet_Record_Ptr);

   -- DNS Transaction Task
   --
   -- Handles transaction management as a many procedures, one (or more)
   -- consumers.
   task type DNS_Transaction_Manager_Task is
      -- Starts the Transaction Manager
      entry Start;

      -- Sets the packet queue vector for a given network interface
      --
      -- @value Queue
      -- The raw packet queue to use
      entry Set_Packet_Queue (Queue : DNS_Raw_Packet_Queue_Ptr);

      -- Inbound client packets come here
      --
      -- @value Packet
      -- The raw packet as generated by the network interface
      --
      -- @value Local
      -- Is this packet generated by the internal DNS client?
      entry From_Client_Resolver_Packet
        (Packet : Raw_Packet_Record_Ptr;
         Local  : Boolean);

         -- Inbound server packets are loaded here
         --
         -- @value Packet
         -- Raw DNS packet generated by the network interface code
         --
      entry From_Upstream_Resolver_Packet (Packet : Raw_Packet_Record_Ptr);

      -- DNS Transaction Manager shutdown
      entry Stop;
   end DNS_Transaction_Manager_Task;

   type DNS_Transaction_Manager_Task_Ptr is
     access DNS_Transaction_Manager_Task;

private

   -- Record of a DNS Transaction
   --
   -- @value Client_Resolver_Address

   -- The downstream client making a request to DNSCatcher's internal DNS
   -- server (or relay)
   --
   -- @value Client_Resolver_Port
   --
   -- The port used for communicating with; due to the way UDP sockets work,
   -- this can be a high level port that's dynamically allocated and not port
   -- 53 as may be expected
   --
   -- @value Server_Resolver_Address
   --
   -- The upstream server that is handling this result. May be the Catcher
   -- instance itself.
   --
   -- @value Server_Resolver_Port
   --
   -- The port used to communicate with the upstream server location
   --
   -- @value DNS_Transaction_Id
   --
   -- The 16-bit integer sent by the client to isolate individual DNS
   -- transactions from a given client.
   --
   -- @value Local_Request
   -- The internal DNS Client made this request
   --
   -- @value From_Client_Resolver_Packet The client's packet allocated on the
   -- heap ready for processing
   --
   -- @value From_Upstream_Resolver_Packet The upstream server's packet ready
   -- for delivery to the client
   --
   type DNS_Transaction is record
      Client_Resolver_Address       : Unbounded_String;
      Client_Resolver_Port          : Port_Type;
      Server_Resolver_Address       : Unbounded_String;
      Server_Resolver_Port          : Port_Type;
      DNS_Transaction_Id            : Unsigned_16;
      Local_Request                 : Boolean;
      From_Client_Resolver_Packet   : Raw_Packet_Record_Ptr;
      From_Upstream_Resolver_Packet : Raw_Packet_Record_Ptr;
   end record;
   type DNS_Transaction_Ptr is access DNS_Transaction;
   type IP_Transaction_Key is new Unbounded_String;

   function IP_Transaction_Key_HashID
     (id : IP_Transaction_Key)
      return Hash_Type;

   package DNS_Transaction_Maps is new Hashed_Maps
     (Key_Type => IP_Transaction_Key, Element_Type => DNS_Transaction_Ptr,
      Hash     => IP_Transaction_Key_HashID, Equivalent_Keys => "=");
   use DNS_Transaction_Maps;
   procedure Free_Hash_Map_Entry (c : DNS_Transaction_Maps.Cursor);
end DNSCatcher.DNS.Transaction_Manager;
