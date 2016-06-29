local handler = require "handler"

local nlr = {}

function nlr.ret(...)
  return handler.op("nlr", "ret", ...)
end

local h = {}

function h.ret(k, ...)
  return ...
end

function nlr.run(blk)
  return handler.with("nlr", h, blk)
end

return nlr
