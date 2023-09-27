local LogLevel = require 'toolbox.log.level'
local Logger   = require 'toolbox.log.logger'

local Path = require 'utils.api.vim.path'


return Logger.new(Path.log() .. '/luasnip-user.log', LogLevel.DEBUG)

