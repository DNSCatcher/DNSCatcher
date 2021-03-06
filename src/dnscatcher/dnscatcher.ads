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

-- @summary
-- DNSCatcher is a complete implementation of the DNS cross-check protocol and
-- DNS Server designed to allow for exhaustive testing of recursive resolver
-- behavior and datasets..
--
-- @description
-- DNSCatcher is the codename of the reference implementation of the DNS
-- Cross-check protocol. It was implemented as a new DNS server instead
-- of recycling existing code to allow ease of processing of discrete data
-- that often isn't exposed within client or server implementaitons short
-- of extensively patching them.
--
-- Catcher is coded with Ada with some components in C to ensure high
-- performance, reliability, and quality. It is intended for parts of the
-- codebase to be rewritten to the SPARK subset for formal validation to
-- help ensure that DNSCatcher is written correctly.
--
-- For use with other programming languages, APIs will be defined for
-- interacting with C which all modern programming languages can bind to.
--
-- This package represents the primary DNSCatcher implementation as a library.
-- For the actual daemon, see the DNSCatcherD package
--
package DNSCatcher is

end DNSCatcher;
