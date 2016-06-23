local corout
local handler = require "handler"

local iterator = {}

function iterator.produce(...)
  return handler.op("iterator", "produce", ...)
end

function iterator.make(f)
  local savedk
  local h = {}
  function h.produce(k, ...)
    savedk = k
    return ...
  end
  return function (...)
    if not savedk then
      return handler.with("iterator", h, f, ...)
    else
      return savedk(...)
    end
  end
end

return iterator
