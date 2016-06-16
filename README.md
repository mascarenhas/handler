# Effect Handlers for Lua

Informally, an *effect handler* is a way for a coroutine to
answer to *operations*. An operation is identified with a label,
and can have arguments. Every operation is dispatched to
the nearest enclosing coroutine that has a handler for
that operation.

A handler receives a *continuation*, and the arguments
for its operation. The continuation can be used to
resume the coroutine that sent the operation; any
arguments passed to it are returned from the call
to `handler.op`. Or the handler can ignore the
coroutine, stash it somewhere to be used later, etc.

If a coroutine finishes its return
values are dispatched to a `return` handler, if
present.

Install it by running `luarocks make` on the provided
rockspec file. The `contrib` folder has some libraries
that implement some abstractions on top of effect handlers,
and the `samples` folder has a sample script that shows
how different handlers compose seamlessly. Some of them depend on
the [thread](https://github.com/mascarenhas/thread)
library and on a branch of
 [Cosmo](https://github.com/mascarenhas/cosmo/tree/taggedcoro).
These two libraries depend on [taggedcoro](https://github.com/mascarenhas/taggedcoro).
