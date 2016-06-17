package = "Handler"
 version = "0.1-1"
 source = {
    url = "git://github.com/mascarenhas/handler.git"
}
description = {
    summary = "Effect Handlers",
    detailed = [[
       A richer abstraction for handling requests from
       coroutines. An effect handler is a map from
       tags to handler functions, and is associated
       with a coroutine. A yield specifies a tag,
       and dispatches to the handler function
       in the nearest enclosing coroutine that has
       the tag. This handler function can then resume
       the coroutine after answering the request.
    ]],
    homepage = "https://github.com/mascarenhas/handler",
    license = "MIT/X11"
}
dependencies = {
    "lua ~> 5.3"
}
build = {
   type = "builtin",
   modules = {
     handler = "src/handler.lua",
     ["handler.iterator"] = "contrib/iterator.lua",
     ["handler.stm"] = "contrib/stm.lua",
     ["handler.exception"] = "contrib/exception.lua",
     ["handler.nlr"] = "contrib/nlr.lua",
     ["handler.coroutine"] = "contrib/coroutine.lua"
   },
   copy_directories = {}
}
