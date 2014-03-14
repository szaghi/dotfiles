--Author: Maksim Ryzhikov
--Name: goog-translator
--Driver: lua
--Version: 0.1.0

--load the http module
local io    = require("io")
local http  = require("socket.http")
local url   = require("socket.url")
local ltn12 = require("ltn12")

--load vim variables
local langpair = vim.eval("s:goog_conf.langpair")
local query    = table.concat(vim.eval("a:query"))

--define local variables
local lng = {
  hl = string.match(langpair,"(%w+)",1),
  tl = string.match(langpair,"|(%w+)",1)
}
lng.sl = lng.hl
local _outp = {}


--send request
http.request{
  url = "http://www.translate.google.com/translate_a/t?client=t&text="..url.escape(query).."&hl="..lng.hl.."&sl="..lng.sl.."&tl="..lng.tl.."&multires=1&otf=1&ssel=0&tsel=0&sc=1",
  headers = {
    ["User-Agent"] = "Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1"
  },
  sink = ltn12.sink.table(_outp)
}

--output result
_outp = string.match(table.concat(_outp), "\"(.-)\"", 1)
vim.command('let s:outp="'.._outp..'"')
