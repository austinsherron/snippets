local logger = require 'snippets.utils.logger'
local Table  = require 'toolbox.core.table'


--- Utilities for loading lua snippets.
---
---@class Loader
local Loader = {}

local function key_loader(lang, key, idx)
  logger:info('Loading snippet=%s for language=%s', { key, lang })
  return idx
end


local function value_loader(val)
  local snippet = val()
  logger:debug('Snippet loaded successfully')
  return snippet
end


--- Constructs and returns an array-like table of snippets from a singleton that contains
--- snippet construction functions.
---
---@param snippet_class { [any]: fun(): s: Snippet }: a singleton class that contains
--- snippet construction functions
---@param lang string|nil: optional; for logging purposes only; the name of the language
--- for which snippets are being loaded
---@return Snippet[]: an array-like table of snippets from a singleton that contains
--- snippet construction functions
function Loader.from_lua(snippet_class, lang)
  lang = lang or '?'

  logger:debug(Table.tostring(snippet_class))

  local snippets = Table.map_items(snippet_class, {
    keys = function(k, _, i) return key_loader(lang, k, i)  end,
    vals = function(v, _, _) return value_loader(v) end,
  })
  return snippets
end

return Loader

