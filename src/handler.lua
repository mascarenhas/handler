
local coroutine = coroutine

local ok, taggedcoro = pcall(require, "taggedcoro")
if ok then
  coroutine = taggedcoro.fortag("handler")
end

local handler = {}

local handlers = setmetatable({}, { __mode = "k" })

local opset = setmetatable({}, { __mode = "k" })

local handlek

local function handlekk(co, ...)
  for k, _ in pairs(handlers[co]) do
    opset[k] = opset[k] + 1
  end
  return handlek(co, coroutine.resume(co, ...))
end

function handlek(co, ok, ...)
  local h = handlers[co]
  for k, _ in pairs(h) do
    opset[k] = opset[k] - 1
  end
  if not ok then
    return error((...))
  end
  if coroutine.status(co) == "dead" then
    return h["return"](...)
  end
  local label = ...
  local hf = h[label]
  if not hf then
    return handlekk(co, coroutine.yield(...))
  else
    return hf(function (...)
      for k, _ in pairs(h) do
        opset[k] = opset[k] + 1
      end
      return handlek(co, coroutine.resume(co, ...))
    end, select(2, ...))
  end
end

function handler.with(h, f, ...)
  local co = coroutine.create(f)
  if not h["return"] then
    h["return"] = function (...) return ... end
  end
  handlers[co] = h
  for k, _ in pairs(h) do
    opset[k] = (opset[k] or 0) + 1
  end
  return handlek(co, coroutine.resume(co, ...))
end

function handler.present(label)
  return (opset[label] or 0) > 0
end

function handler.op(label, ...)
  if (opset[label] or 0) > 0 then
    return coroutine.yield(label, ...)
  else
    return error("there is no hander for operation " .. label)
  end
end

return handler
