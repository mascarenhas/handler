local handler = require "handler"

local nlr = {}

local h = {}

function h.nlr_return(k, ...)
  return ...
end

function nlr.run(blk)
  return handler.with(h, blk)
end

function nlr.ret(...)
  return handler.op("nlr_return", ...)
end

return nlr
