local handler = require "handler"

local lua_print = print

local print = {
  print = function (self, k, s)
    lua_print(s)
    k()
  end
}

local reverse = {
  print = function (self, k, s)
    k()
    handler.op("io", "print", s)
  end
}

local function ABC()
  handler.op("io", "print", "A")
  handler.op("io", "print", "B")
  handler.op("io", "print", "C")
end

handler.with("io", print, function ()
  handler.with("io", reverse, ABC)
end)

local collect = {
  finish = function (self, x)
    return x, ""
  end,
  print = function (self, k, s)
    local x, acc = k()
    return x, s .. acc
  end
}

lua_print(handler.with("io", collect, ABC))

lua_print(handler.with("io", collect, function ()
  handler.with("io", reverse, ABC)
end))

local collectp = {
  finish = function (self, x)
    return function (acc)
      return x, acc
    end
  end,
  print = function (self, k, s)
    return function (acc)
      return k()(acc .. s)
    end
  end
}

lua_print(handler.with("io", collectp, ABC)(""))

local state = {
  finish = function (self, x)
    return function (s)
      return s, x
    end
  end,
  get = function (self, k)
    return function (s)
      return k(s)(s)
    end
  end,
  set = function (self, k, s)
    return function ()
      return k()(s)
    end
  end
}

local getset = function ()
  local x = handler.op("st", "get")
  handler.op("st", "set", x * 2)
  return 0
end

lua_print(handler.with("st", state, getset)(2))

local transaction = {
  finish = function (self, x)
    return function (s)
      handler.op("st", "set", s)
      return x
    end
  end,
  rollback = function (self, k, x)
    return function ()
      return x
    end
  end,
  get = function (self, k)
    return function (s)
      return k(s)(s)
    end
  end,
  set = function (self, k, s)
    return function ()
      return k()(s)
    end
  end
}

local trans = function ()
  local x = handler.op("st", "get")
  handler.op("st", "set", x * 2)
  if x < 5 then
    handler.op("st", "rollback", 0)
  end
  return 1
end

lua_print(handler.with("st", state, function ()
  local s = handler.op("st", "get")
  return handler.with("st", transaction, trans)(s)
end)(2))
lua_print(handler.with("st", state, function ()
  local s = handler.op("st", "get")
  return handler.with("st", transaction, trans)(s)
end)(6))
