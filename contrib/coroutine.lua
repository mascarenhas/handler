local handler = require "handler"

local coro = {}

local main = { status = "normal" }

local ops = {}

function ops:yield(k, ...)
  self.status = "suspended"
  self.k = k
  return ...
end

function ops:running(k)
  return k(self)
end

function ops:finish(...)
  self.status = "dead"
  return ...
end

function coro.create(f)
  return setmetatable({ status = "suspended", f = f, k = nil },
                      { __index = ops })
end

local function resumek(co, ok, err, ...)
  if ok then
    return true, err, ...
  else
    co.status = "dead"
    return false, err
  end
end

function coro.resume(co, ...)
  if co.status ~= "suspended" then
    return false, "cannot resume " .. co.status .. " coroutine"
  end
  coro.running().status = "normal"
  co.status = "running"
  if co.k then
    return resumek(co, pcall(co.k, ...))
  else
    return resumek(co, pcall(handler.with, "coroutine", co, co.f, ...))
  end
end

function coro.yield(...)
  return handler.op("coroutine", "yield", ...)
end

function coro.running()
  if handler.present("coroutine") then
    return handler.op("coroutine", "running"), false
  else
    return main, true
  end
end

function coro.isyieldable()
  return handler.present("coroutine")
end

function coro.status(co)
  return co.status
end

local function wrapk(ok, err, ...)
  if ok then
    return err, ...
  else
    return error(err)
  end
end

function coro.wrap(f)
  local co = coro.create(f)
  return function (...)
           return wrapk(coro.resume(co, ...))
         end
end

return coro
