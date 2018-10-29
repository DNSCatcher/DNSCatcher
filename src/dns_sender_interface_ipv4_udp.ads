with GNAT.Sockets;            use GNAT.Sockets;
with DNSCatcher_Config;       use DNSCatcher_Config;
with Raw_DNS_Packets;         use Raw_DNS_Packets;
with DNS_Network_Receiver_Interface;
with DNS_Transaction_Manager; use DNS_Transaction_Manager;

package DNS_Sender_Interface_IPv4_UDP is
   -- Tasks Definition
   task type Send_Packet_Task is
      entry Initialize (Config : Configuration_Ptr; Socket : Socket_Type;
         Transaction_Manager   : DNS_Transaction_Manager_Task_Ptr;
         Packet_Queue          : Raw_DNS_Packets.Raw_DNS_Packet_Queue_Ptr);
      entry Start;
      entry Stop;
   end Send_Packet_Task;
   type Send_Packet_Task_Ptr is access Send_Packet_Task;

   type IPv4_UDP_Sender_Interface is new DNS_Network_Receiver_Interface.Receiver_Interface with
   record
      Config              : Configuration_Ptr;
      Sender_Socket       : Socket_Type;
      Transaction_Manager : DNS_Transaction_Manager_Task_Ptr;
      Sender_Task         : Send_Packet_Task_Ptr;
      Packet_Queue        : Raw_DNS_Packet_Queue_Ptr;
   end record;
   type IPv4_UDP_Receiver_Interface_Ptr is access IPv4_UDP_Sender_Interface;

   procedure Initialize (This : in out IPv4_UDP_Sender_Interface; Config : Configuration_Ptr;
      Transaction_Manager     :        DNS_Transaction_Manager_Task_Ptr; Socket : Socket_Type);
   -- Initializes a network interface and does any necessary prep work. It MUST be called before
   -- calling any other method

   procedure Start (This : in out IPv4_UDP_Sender_Interface);
   -- Starts the interface

   procedure Shutdown (This : in out IPv4_UDP_Sender_Interface);
   -- Cleanly shuts down the interface

   function Get_Packet_Queue_Ptr
     (This : in out IPv4_UDP_Sender_Interface) return Raw_DNS_Packet_Queue_Ptr;
   -- Returns a pointer to the packet queue

end DNS_Sender_Interface_IPv4_UDP;