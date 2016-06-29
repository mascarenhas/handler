local handler = require "handler"

local parser = {}

local ops = {}

function ops:input(k)
  return k(self.inp, self.pos)
end

function ops:advance(k, pos)
  self.pos = self.pos + pos
  return k()
end

function ops:fail(k, expected)
  if expected then
    if self.pos > self.lastpos then
      self.lastpos = self.pos
      self.expset = { [expected] = true }
    elseif self.pos == self.lastpos then
      self.expset[expected] = true
    end
  end
  return false, self.lastpos, self.expset
end

function ops:try(k, ...)
  local n = select("#", ...)
  for i = 1, n do
    local p = (select(i, ...))
    local h = setmetatable({ inp = self.inp,
      pos = self.pos, lastpos = self.lastpos,
      expset = self.expset }, { __index = ops })
    local res = table.pack(handler.with("parser", h, p))
    self.lastpos = h.lastpos
    self.expset = h.expset
    if res[1] then
      self.pos = h.pos
      return k(true, table.unpack(res, 4, res.n))
    end
  end
  return k(false)
end

function ops:finish(...)
  return true, self.lastpos, self.expset, ...
end

function parser.input()
  return handler.op("parser", "input")
end

function parser.advance(i)
  return handler.op("parser", "advance", i)
end

function parser.try(...)
  return handler.op("parser", "try", ...)
end

function parser.fail(expected)
  return handler.op("parser", "fail", expected)
end

function parser.str(s)
  local input, pos = parser.input()
  if #s > (#input - pos + 1) then
    return parser.fail()
  else
    local is = input:sub(pos, pos + #s - 1)
    if is == s then
      parser.advance(#s)
      return s, pos
    else
      return parser.fail()
    end
  end
end

function parser.class(cls)
  local input, pos = parser.input()
  if pos > #input then
    return parser.fail()
  else
    local c = input:sub(pos, pos)
    if cls(c) then
      parser.advance(1)
      return c, pos
    else
      return parser.fail()
    end
  end
end

function parser.choice(...)
  local ps = table.pack(...)
  local res = table.pack(parser.try(table.unpack(ps, 1, ps.n-1)))
  if res[1] then
    return table.unpack(res, 2, res.n)
  else
    return ps[ps.n]()
  end
end

function parser.named(p, name)
  local input, pos = parser.input()
  local res = parser.try(p)
  if res then
    local _, npos = parser.input()
    return input:sub(pos, npos-1), pos
  else
    return parser.fail(name)
  end
end

function parser.star(p)
  local res = {}
  repeat
    local ok, rp = parser.try(p)
    if ok then res[#res+1] = rp end
  until not ok
  if #res > 0 then
    return res
  end
end

function parser.plus(p)
  local res = { (p()) }
  repeat
    local ok, rp = parser.try(p)
    if ok then res[#res+1] = rp end
  until not ok
  if #res > 0 then
    return res
  end
end

function parser.bang(p)
  local res = parser.try(p)
  if res then
    return parser.fail()
  end
end

function parser.dot()
  return parser.class(function (c) return true end)
end

function parser.chainl(term, op)
  local exp = term()
  repeat
    local ok, fop = parser.try(op)
    if ok then
      exp = fop(exp, term())
    end
  until not ok
  return exp
end

function parser.chainr(term, op)
  local exp = term()
  local ok, fop = parser.try(op)
  if ok then
    exp = fop(exp, parser.chainr(term, op))
  end
  return exp
end

function parser.run(input, p)
  local h = setmetatable({ inp = input, pos = 1, lastpos = 0 }, { __index = ops })
  return handler.with("parser", h, p)
end

return parser
