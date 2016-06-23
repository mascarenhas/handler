local handler = require "handler"
local coroutine = require "taggedcoro"

local ex = {}

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

local ops = {}

function ops:throw(k, co, e)
  local traceback = function (msg)
    return ex.traceback(co, msg)
  end
  return self.cblk(e, traceback, k)
end

function ex.trycatch(tblk, cblk)
  local h = setmetatable({ cblk = cblk }, { __index = ops })
  return handler.with("exception", h, tblk)
end

return ex
