local handler = require "handler"
local coroutine = require "taggedcoro"

local ex = {}

function ex.trycatch(tblk, cblk)
  local h = {}
  function h.throw(k, co, e)
    local traceback = function (msg)
      return ex.traceback(co, msg)
    end
    return cblk(e, traceback, k)
  end
  return handler.with("exception", h, tblk)
end

function ex.throw(e)
  return handler.op("exception", "throw", coroutine.running(), e)
end

function ex.traceback(co, msg)
  local tb = { msg, "stack traceback:" }
  while co do
    tb[#tb+1] = debug.traceback(co):gsub("^stack traceback:\n", "")
    if coroutine.caller then
      co = coroutine.caller(co)
    else
      co = nil
    end
  end
  return table.concat(tb, "\n")
end

return ex
