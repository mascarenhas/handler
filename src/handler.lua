local coroutine = require "coroutine"

local handler = {}

local handlers = setmetatable({}, { __mode = "k" })

local function handlek(co, ...)
  local res = { co(...) }
  local label = res[1]
  local hf = handlers[co][label]
  if not hf then
    if not coroutine.isyieldable() then
      return error("there is no handler for the operation " .. label)
    end
    return handlek(co, coroutine.yield(table.unpack(res)))
  elseif label == "return" then
    return hf(table.unpack(res, 2))
  else
    return hf(function (...) return handlek(co, ...) end, table.unpack(res, 2))
  end
end

function handler.with(handler, f, ...)
  local co = coroutine.wrap(function (...) return "return", f(...) end)
  handlers[co] = handler
  return handlek(co, ...)
end

function handler.op(label, ...)
  if not coroutine.isyieldable() then
    return error("there is no handler for the operation " .. label)
  end
  return coroutine.yield(label, ...)
end

return handler
