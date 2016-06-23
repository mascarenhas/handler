local corout
local handler = require "handler"

local iterator = {}

function iterator.produce(...)
  return handler.op("iterator", "produce", ...)
end

local ops = {}

function ops:produce(k, ...)
  self.savedk = k
  return ...
end

function ops:next(...)
  if self.savedk then
    return self.savedk(...)
  else
    return handler.with("iterator", self, self.f, ...)
  end
end

function iterator.make(f)
  local h = setmetatable({ f = f }, { __index = ops })
  return function (...)
    return h:next(...)
  end
end

return iterator
