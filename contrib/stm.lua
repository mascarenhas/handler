local handler = require "handler"
local thread = require "thread"

local stm = {}

local db = {}

function stm.var(name, val)
  if stm.in_transaction() then
    return error("cannot create stm variable " .. name .. " inside a transaction")
  end
  db[name] = { value = val, timestamp = 0, cv = thread.cv() }
end

function stm.transaction(blk)
  if stm.in_transaction() then
    return blk()
  end
  local tvars = {}
  local h = {}
  function h.get(k, name)
    if not tvars[name] then
      tvars[name] = { value = db[name].value, timestamp = db[name].timestamp, dirty = false }
    end
    return k(tvars[name].value)
  end
  function h.set(k, name, val)
    if not tvars[name] then
      tvars[name] = { value = val, timestamp = db[name].timestamp, dirty = true }
    else
      tvars[name].value = val
      tvars[name].dirty = true
    end
    return k()
  end
  function h.retry(k)
    for name, var in pairs(tvars) do
      if db[name].timestamp > var.timestamp then
        return stm.transaction(blk)
      end
    end
    local cvs = {}
    for name, _ in pairs(tvars) do
      cvs[#cvs+1] = db[name].cv
    end
    thread.yield("cvs", cvs)
    return stm.transaction(blk)
  end
  function h.rollback(k)
    return
  end
  h["return"] = function (...)
    for name, var in pairs(tvars) do
      if db[name].timestamp > var.timestamp then
        return stm.transaction(blk)
      end
    end
    for name, var in pairs(tvars) do
      if var.dirty then
        db[name].value = var.value
        db[name].timestamp = db[name].timestamp + 1
      end
    end
    for name, var in pairs(tvars) do
      if var.dirty then
        thread.signal(db[name].cv)
      end
    end
    return ...
  end
  return handler.with("stm", h, blk)
end

function stm.get(name)
  return handler.op("stm", "get", name)
end

function stm.set(name, val)
  return handler.op("stm", "set", name, val)
end

function stm.retry()
  return handler.op("stm", "retry")
end

function stm.rollback()
  return handler.op("stm", "rollback")
end

function stm.in_transaction()
  return handler.present("stm")
end

return stm
