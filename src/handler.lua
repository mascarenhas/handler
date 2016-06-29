
local coroutine = require "taggedcoro"

local handler = {}

local NOT_FOUND = {}

local function ohandlek(tag, h, co, ...)
  if coroutine.status(co) == "dead" then
    if h.finish then
      return h:finish(...)
    else
      return ...
    end
  end
  local label = ...
  local hf = h[label]
  if not hf then
    return ohandlek(tag, h, co, co(NOT_FOUND))
  else
    return hf(h, function (...)
      return ohandlek(tag, h, co, co(...))
    end, select(2, ...))
  end
end

local function handlek(tag, h, co, ...)
  if coroutine.status(co) == "dead" then
    if h.finish then
      return h.finish(...)
    else
      return ...
    end
  end
  local label = ...
  local hf = h[label]
  if not hf then
    if coroutine.isyieldable(tag) then
      -- try to find op in next handler of this type
      return handlek(tag, h, co, co(coroutine.yield(tag, label, ...)))
    else
      return handlek(tag, h, co, co(NOT_FOUND))
    end
  else
    return hf(function (...)
      return handlek(tag, h, co, co(...))
    end, select(2, ...))
  end
end

function handler.with(tag, h, f, ...)
  local co = coroutine.wrap(tag, f)
  if getmetatable(h) then
    return ohandlek(tag, h, co, co(...))
  else
    if not h.finish then
      h.finish = function (...) return ... end
    end
    return handlek(tag, h, co, co(...))
  end
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
