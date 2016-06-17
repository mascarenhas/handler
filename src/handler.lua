
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

local opset = setmetatable({}, { __mode = "k" })

local handlek

local function handlekk(co, ...)
  for k, _ in pairs(handlers[co]) do
    opset[k] = opset[k] + 1
  end
  return handlek(co, co(...))
end

function handlek(co, label, ...)
  for k, _ in pairs(handlers[co]) do
    opset[k] = opset[k] - 1
  end
  local hf = handlers[co][label]
  if not hf then
    if label == "return" then
      return ...
    else
      return handlekk(co, yield(label, ...))
    end
  elseif label == "return" then
    return hf(...)
  else
    return hf(function (...)
      for k, _ in pairs(handlers[co]) do
        opset[k] = opset[k] + 1
      end
      return handlek(co, co(...))
    end, ...)
  end
end

function handler.with(handler, f, ...)
  local co = wrap(function (...) return "return", f(...) end)
  handlers[co] = handler
  for k, _ in pairs(handler) do
    opset[k] = (opset[k] or 0) + 1
  end
  return handlek(co, co(...))
end

function handler.present(label)
  return (opset[label] or 0) > 0
end

function handler.op(label, ...)
  if (opset[label] or 0) > 0 then
    return yield(label, ...)
  else
    return error("there is no hander for operation " .. label)
  end
end

return handler
