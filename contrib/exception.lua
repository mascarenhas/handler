local handler = require "handler"

local ex = {}

function ex.trycatch(tblk, cblk)
  local h = {}
  h["return"] = function (...)
    return ...
  end
  function h.exception_throw(k, e)
    return cblk(e, k)
  end
  return handler.with(h, tblk)
end

function ex.throw(e)
  return handler.op("exception_throw", e)
end

return ex
