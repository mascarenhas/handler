
local iterator = require "iterator"
local nlr = require "nlr"
local ex = require "exception"

local function aux(msg)
  return nlr.run(function ()
    ex.trycatch(function ()
      local msg = ex.throw(msg)
      iterator.produce(msg)
      nlr.ret(msg)
      return "unreacheable"
    end,
    function (err, retry)
      retry(err)
      return "unreacheable"
    end)
  end)
end

local function iter(msg)
  return iterator.make(function ()
    while true do
      msg = msg .. aux(msg)
      if #msg > 50 then return nil end
    end
  end)
end

for msg in iter("F ") do
  print(msg)
end
