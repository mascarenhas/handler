
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
  return handlek(co, co(...))
end

function handlek(co, ok, label, ...)
  if not ok then return error(label) end
  for k, _ in pairs(handlers[co]) do
    opset[k] = opset[k] - 1
  end
  local hf = handlers[co][label]
  if not hf then
    if label == "return" then
      return ...
    else
      return handlekk(co, coroutine.yield(label, ...))
    end
  elseif label == "return" then
    return hf(...)
  else
    local function unwind(e)
      for k, _ in pairs(handlers[co]) do
        opset[k] = opset[k] - 1
      end
      return e
    end
    return hf(function (...)
      for k, _ in pairs(handlers[co]) do
        opset[k] = opset[k] + 1
      end
      return handlek(co, xpcall(co, unwind, ...))
    end, ...)
  end
end

function handler.with(handler, f, ...)
  local co = coroutine.wrap(function (...) return "return", f(...) end)
  handlers[co] = handler
  for k, _ in pairs(handler) do
    opset[k] = (opset[k] or 0) + 1
  end
  local function unwind(e)
    for k, _ in pairs(handler) do
      opset[k] = opset[k] - 1
    end
    return e
  end
  return handlek(co, xpcall(co, unwind, ...))
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
