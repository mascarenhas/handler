
local taggedcoro = require("taggedcoro")

local handler = {}

local function handlek(co, wco, ...)
  local label = taggedcoro.lasttag(co)
  local hf = taggedcoro.tagset(co)[label]
  assert(hf)
  if label == "return" then
    return hf(...)
  else
    return hf(function (...)
      return handlek(co, wco, wco(...))
    end, ...)
  end
end

function handler.with(handler, f, ...)
  if not handler["return"] then
    handler["return"] = function (...) return ... end
  end
  local wco, co = taggedcoro.wrap(f, handler)
  return handlek(co, wco, wco(...))
end

function handler.present(label)
  return taggedcoro.isyieldable(label)
end

function handler.op(label, ...)
  if handler.present(label) then
    return taggedcoro.yield(label, ...)
  else
    return error("there is no hander for operation " .. label)
  end
end

return handler
