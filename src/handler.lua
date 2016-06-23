
local coroutine = require "taggedcoro"

local handler = {}

local NOT_FOUND = {}

local handlers = setmetatable({}, { __mode = "k" })

local function handlek(tag, co, ...)
  local h = handlers[co]
  if coroutine.status(co) == "dead" then
    return h:finish(...)
  end
  local label = ...
  local hf = h[label]
  if not hf then
    if coroutine.isyieldable(tag) then
      -- try to find op in next handler of this type
      return handlek(tag, co, co(coroutine.yield(tag, label, ...)))
    else
      return handlek(tag, co, co(NOT_FOUND))
    end
  else
    return hf(h, function (...)
      return handlek(tag, co, co(...))
    end, select(2, ...))
  end
end

function handler.with(tag, h, f, ...)
  local co = coroutine.wrap(tag, f)
  if not h.finish then
    h.finish = function (self, ...) return ... end
  end
  handlers[co] = h
  return handlek(tag, co, co(...))
end

function handler.present(tag)
  return coroutine.isyieldable(tag)
end

local function opk(tag, label, ...)
  local fst = ...
  if fst == NOT_FOUND then
    error("handler not found for tag " .. tag .. "  and label " .. label)
  else
    return ...
  end
end

function handler.op(tag, label, ...)
  return opk(tag, label, coroutine.yield(tag, label, ...))
end

return handler
