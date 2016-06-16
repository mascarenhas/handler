local corout
local handler = require "handler"

local iterator = {}

function iterator.produce(...)
  return handler.op("iterator_produce", ...)
end

function iterator.make(f)
  local savedk
  local h = {}
  function h.iterator_produce(k, ...)
    savedk = k
    return ...
  end
  h["return"] = function (...)
    return ...
  end
  return function (...)
    if not savedk then
      return handler.with(iterator.handler, f, ...)
    else
      return savedk(...)
    end
  end
end

return iterator
