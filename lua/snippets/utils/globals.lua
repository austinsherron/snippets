Ls       = require 'luasnip'
LsExtras = require 'luasnip.extras'
LsFmt    = require 'luasnip.extras.fmt'

-- to create snippets manually
Snippet     = Ls.snippet
SnippetNode = Ls.snippet

-- to create nodes manually
C = Ls.choice_node
D = Ls.dynamic_node
F = Ls.function_node
I = Ls.insert_node
T = Ls.text_node

-- extras
Rep = LsExtras.rep
Key = require('luasnip.nodes.key_indexer').new_key

-- formatting
Fmt  = LsFmt.fmt
Fmta = LsFmt.fmta

-- snippet loader
Loader = require 'snippets.utils.loader'

-- building blocks
GenericNodes = require 'snippets.parts.generic.nodes'

-- util classes
Bool   = require 'toolbox.core.bool'
String = require 'toolbox.core.string'
Table  = require 'toolbox.core.table'
Set    = require 'toolbox.extensions.set'

Logger = require 'snippets.utils.logger'

-- util functions
---@diagnostic disable-next-line: lowercase-global
ternary = Bool.ternary

