local handler = require "handler"

local lua_print = print

local print = {
  print = function (k, s)
    print(s)
    k()
  end
}

local reverse = {
  print = function (k, s)
    k()
    handler.op("print", s)
  end
}

local function ABC()
  handler.op("print", "A")
  handler.op("print", "B")
  handler.op("print", "C")
end

handler.with(print, function ()
  handler.with(reverse, ABC)
end)

local collect = {
  ["return"] = function (x)
    return x, ""
  end,
  print = function (k, s)
    local x, acc = k()
    return x, s .. acc
  end
}

lua_print(handler.with(collect, ABC))

lua_print(handler.with(collect, function ()
  handler.with(reverse, ABC)
end))

local collectp = {
  ["return"] = function (x)
    return function (acc)
      return x, acc
    end
  end,
  print = function (k, s)
    return function (acc)
      return k()(acc .. s)
    end
  end
}

lua_print(handler.with(collectp, ABC)(""))

local state = {
  ["return"] = function (x)
    return function (s)
      return s, x
    end
  end,
  get = function (k)
    return function (s)
      return k(s)(s)
    end
  end,
  set = function (k, s)
    return function ()
      return k()(s)
    end
  end
}

local getset = function ()
  local x = handler.op("get")
  handler.op("set", x * 2)
  return 0
end

lua_print(handler.with(state, getset)(2))

local transaction = {
  ["return"] = function (x)
    return function (s)
      handler.op("set", s)
      return x
    end
  end,
  rollback = function (k, x)
    return function ()
      return x
    end
  end,
  get = function (k)
    return function (s)
      return k(s)(s)
    end
  end,
  set = function (k, s)
    return function ()
      return k()(s)
    end
  end
}

local trans = function ()
  local x = handler.op("get")
  handler.op("set", x * 2)
  if x < 5 then
    handler.op("rollback", 0)
  end
  return 1
end

lua_print(handler.with(state, function ()
  local s = handler.op("get")
  return handler.with(transaction, trans)(s)
end)(2))
lua_print(handler.with(state, function ()
  local s = handler.op("get")
  return handler.with(transaction, trans)(s)
end)(6))
