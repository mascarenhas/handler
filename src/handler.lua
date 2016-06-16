
local yield, wrap, isyieldable = coroutine.yield, coroutine.wrap, coroutine.isyieldable

local ok, taggedcoro = pcall(require, "taggedcoro")

if ok then
  yield = function (...)
    return taggedcoro.yield("handler", ...)
  end
  wrap = function (f)
    return taggedcoro.wrap(f, "handler")
  end
  isyieldable = function ()
    return taggedcoro.isyieldable("handler")
  end
end

local handler = {}

local handlers = setmetatable({}, { __mode = "k" })

local not_found = {}

local function handlek(co, label, ...)
  local hf = handlers[co][label]
  if not hf then
    if not isyieldable() then
      return handlek(co, co(not_found))
    end
    return handlek(co, co(yield(label, ...)))
  elseif label == "return" then
    return hf(...)
  else
    return hf(function (...) return handlek(co, co(...)) end, ...)
  end
end

function handler.with(handler, f, ...)
  local co = wrap(function (...) return "return", f(...) end)
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
  return opk(label, yield(label, ...))
end

return handler
