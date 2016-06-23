local handler = require "handler"

local nlr = {}

local h = {}

function h.ret(k, ...)
  return ...
end

function nlr.run(blk)
  return handler.with("nlr", h, blk)
end

function nlr.ret(...)
  return handler.op("nlr", "ret", ...)
end

return nlr
