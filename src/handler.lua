local coroutine = require "coroutine"

local handler = {}

local handlers = setmetatable({}, { __mode = "k" })

local not_found = {}

local function handlek(co, label, ...)
  local hf = handlers[co][label]
  if not hf then
    if not coroutine.isyieldable() then
      return handlek(co, co(not_found))
    end
    return handlek(co, co(coroutine.yield(label, ...)))
  elseif label == "return" then
    return hf(...)
  else
    return hf(function (...) return handlek(co, co(...)) end, ...)
  end
end

function handler.with(handler, f, ...)
  local co = coroutine.wrap(function (...) return "return", f(...) end)
  handlers[co] = handler
  return handlek(co, co(...))
end

local function opk(label, fst, ...)
  if fst == not_found then
    return error("there is no hander for operation " .. label)
  else
    return fst, ...
  end
end

function handler.op(label, ...)
  return opk(label, coroutine.yield(label, ...))
end

return handler
