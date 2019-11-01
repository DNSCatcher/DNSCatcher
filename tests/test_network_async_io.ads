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

with AUnit;            use AUnit;
with AUnit.Test_Cases; use AUnit.Test_Cases;

with DNSCatcher_Test_Case; use DNSCatcher_Test_Case;

-- @summary
-- Handles testing the async io basic functionality, and libuv intergrate
--
-- @description
-- Handling of network sockets is primarily coded in C to wrap around libuv
-- and OpenSSL with Ada handlers to handle callbacks and other similar
-- functionality. The expectation is libuv packets will be punted into
-- a protected object which worker tasks can pick up from.
--
-- This code tests the libuv initialization bits, network configuration, and
-- handling of queued data to/from libuv
--
package Test_Network_ASync_IO is

   -- Global config object for Network ASync Tests
   type Network_ASync_IO_Test is new DNSCatcher_Test_Type with record
      null;
   end record;

   -- Registers each test function to be run
   --
   -- @value T
   -- Global config for test case
   procedure Register_Tests (T : in out Network_ASync_IO_Test);

   -- Provide name identifying the test case
   --
   -- @value T
   -- Global config for test case
   function Name
     (T : Network_ASync_IO_Test)
      return Message_String;

   -- Test setup and teardown of async loop
   --
   -- @value T
   -- Global config for test case
   procedure Test_Setup_And_Teardown (T : in out Test_Cases.Test_Case'Class);

end Test_Network_ASync_IO;