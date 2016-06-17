local handler = require "handler"

local coro = {}

local coro_h = {}

local main = { status = "normal" }

function coro_h.coroutine_yield(k, ...)
end

function coro.create(f)
  local co = { status = "suspended", f = f, k = nil }
  co.h = {
    coroutine_yield = function (k, ...)
      co.status = "suspended"
      co.k = k
      return ...
    end,
    coroutine_running = function (k)
      return k(co)
    end,
    ["return"] = function (...)
      co.status = "dead"
      return ...
    end
  }
  return co
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
    return resumek(co, pcall(handler.with, co.h, co.f, ...))
  end
end

function coro.yield(...)
  return handler.op("coroutine_yield", ...)
end

function coro.running()
  if handler.present("coroutine_running") then
    return handler.op("coroutine_running"), false
  else
    return main, true
  end
end

function coro.isyieldable()
  return handler.present("coroutine_yield")
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
