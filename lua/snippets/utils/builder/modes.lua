local Set = require 'toolbox.extensions.set'


--- Determines the index of an insert node when added to a snippet builder.
---
---@enum InsertMode
local InsertMode = {
  CHILD = 'child', -- primarily internal; indicates that an insert node is a child of another node
  LAST  = 'last',  -- use the index of the last insert node
  NEW   = 'new',   -- adds a new insert node: increment the last index
  PREV  = 'prev',  -- use some previous insert node's index; must be <= current index
}

InsertMode.ALL = Set.new(Table.values(InsertMode))
InsertMode.DEFAULT = InsertMode.NEW

function InsertMode.orDefault(mode)
  return ternary(
    InsertMode.ALL:contains(mode),
    mode,
    InsertMode.DEFAULT
  )
end

--- Determines which luasnip format method will be used by a snippet builder w/ a format
--- string.
---
---@enum FormatMode
local FormatMode = {
  S = '',
  A = 'a',
}

FormatMode.ALL = Set.new(Table.values(FormatMode))
FormatMode.DEFAULT = FormatMode.A

function FormatMode.orDefault(mode)
  return ternary(mode == nil, FormatMode.DEFAULT, mode)
end

return {
  format = FormatMode,
  insert = InsertMode,
}

