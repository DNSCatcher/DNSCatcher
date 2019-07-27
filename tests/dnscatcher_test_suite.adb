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

pragma Ada_2012;

with Test_Packet_Parser;
with Test_Network_ASync_IO;

package body DNSCatcher_Test_Suite is
   use AUnit.Test_Suites;

   -- Statically allocate test suite;
   Result : aliased Test_Suite;

   -- And the test cases
   Test_Packet_Parser_Ptr    : aliased Test_Packet_Parser.Packet_Parser_Test;
   Test_Network_Async_IO_Ptr : aliased Test_Network_ASync_IO
     .Network_ASync_IO_Test;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
   begin
      Add_Test (Result'Access, Test_Packet_Parser_Ptr'Access);
      Add_Test (Result'Access, Test_Network_Async_IO_Ptr'Access);
      return (Result'Access);
   end Suite;

end DNSCatcher_Test_Suite;
