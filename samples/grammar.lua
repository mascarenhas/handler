local parser = require "handler.parser"

local function alpha()
  return parser.class(function (c)
    return c:match("[_%a]")
  end)
end

local function digit()
  return parser.class(function (c)
    return c:match("[%d]")
  end)
end

local function alphanum()
  return parser.class(function (c)
    return c:match("[_%w]")
  end)
end

local function whitespace()
  return parser.class(function (c)
    return c:match("[%s]")
  end)
end

local function noteol()
  return parser.class(function (c)
    return c ~= "\n"
  end)
end

local function notalphanum()
  return parser.bang(alphanum)
end

local function comment()
  parser.str("--")
  parser.star(noteol)
end

local function space()
  parser.star(function ()
    parser.choice(whitespace, comment)
  end)
end

local function eof()
  space()
  parser.bang(parser.dot)
end

local function kw(s)
  space()
  return parser.named(function ()
    parser.str(s)
    notalphanum()
  end, s)
end

local function op(s)
  space()
  return parser.named(function ()
    parser.str(s)
  end, s)
end

local function binop(sop)
  return function ()
    local _, pos = op(sop)
    return function (left, right) return { sop, left, right, pos } end
  end
end

local function name()
  space()
  return parser.named(function ()
    alpha()
    parser.star(alphanum)
  end, "name")
end

local function num()
  space()
  return parser.named(function ()
    parser.plus(digit)
  end, "num")
end

local g = {}

function g.bloco()
  return parser.star(g.stat)
end

function g.stat()
  return parser.choice(g.swhile, g.assign)
end

function g.swhile()
  local _, pos = kw("while")
  local cond = g.exp()
  kw("do")
  local body = g.bloco()
  kw("end")
  return { "while", cond, body, pos }
end

function g.assign()
  local lval = name()
  local _, pos = op("=")
  local rval = g.exp()
  return { "=", lval, rval, pos }
end

function g.exp()
  return parser.choice(function ()
    local left = g.aexp()
    local _, pos = op("<")
    local right = g.aexp()
    return { "<", left, right, pos }
  end, g.aexp)
end

function g.aexp()
  return parser.chainl(g.mexp, g.aop)
end

function g.aop()
  return parser.choice(binop("+"), binop("-"))
end

function g.mexp()
  return parser.chainl(g.pexp, g.mop)
end

function g.mop()
  return parser.choice(binop("*"), binop("/"))
end

function g.pexp()
  return parser.choice(function ()
    op("(")
    local exp = g.exp()
    op(")")
    return exp
  end, function ()
    local n, pos = name()
    return { "name", n, pos }
  end, function ()
    local n, pos = num()
    return { "num" , n, pos }
  end)
end

function g.prog()
  local stats = g.bloco()
  eof()
  return stats
end

local function pos_to_lincol(input, pos)
   local lin = 1
   local last = 1
   input = input:sub(1, pos)
   local br = string.find(input, "\n")
   while br do
       lin = lin + 1
       last = last + br
       input = input:sub(br+1, #input)
       br = string.find(input, "\n")
   end
   return lin, pos - last + 1
end

local function parse(input, p)
  local ok, pos, expset, stats = parser.run(input, p)
  if ok then
    return stats
  else
    local lin, col = pos_to_lincol(input, pos)
    local expected = {}
    for k, _ in pairs(expset) do
      expected[#expected+1] = k
    end
    error(string.format("syntax error at line %d column %d, expected %s", lin, col, table.concat(expected, ", ")))
  end
end

local function dumptree(input, t, offset)
  offset = offset or 0
  local tt = {}
  for i, v in ipairs(t) do
    if type(v) == "table" then
      tt[i] = "\n" .. string.rep(" ", offset+2) .. dumptree(input, v, offset+2)
    elseif type(v) == "string" then
      tt[i] = string.format("%q", v)
    elseif type(v) == "number" then
      tt[i] = string.format("(lin %d, col %d)", pos_to_lincol(input, v))
    end
  end
  return "{ " .. table.concat(tt, ", ") .. " }"
end

local p1 = [[
xyz = 1
abc = 20
while x < 0 do
  xyz = xyz * (abc - 1)
  abc = abc - 1
end
]]

local t1 = parse(p1, g.prog)

print(dumptree(p1, t1))
