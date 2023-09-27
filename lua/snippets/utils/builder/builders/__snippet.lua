local String   = require 'toolbox.core.string'
local Validate = require 'toolbox.utils.validate'

local NodesBuilder = require 'snippets.utils.builder.builders.__nodes'
local FormatMode   = require('snippets.utils.builder.modes').format

local ls    = require 'luasnip'
local lsFmt = require 'luasnip.extras.fmt'


--- Utility for building snippets.
---
---@class SnippetBuilder
---@field private args { trig: string, desc: string }
---@field private nodes NodesBuilder
local SnippetBuilder = {}
SnippetBuilder.__index = SnippetBuilder

--- Constructor
---
---@return SnippetBuilder: a new instance
function SnippetBuilder.new()
  return setmetatable({ args = {}}, SnippetBuilder)
end


--- Adds a snippet trigger string to the instance.
---
---@param trig string: the string that triggers the snippet
---@return SnippetBuilder: this instance
function SnippetBuilder:withTrig(trig)
  self.args.trig = trig
  return self
end


--- Adds a snippet description to the instance.
---
---@param desc string: a description of the snippet
---@return SnippetBuilder: this instance
function SnippetBuilder:withDesc(desc)
  self.args.desc = desc
  return self
end


--- Adds a format string to the instance and indicates to the builder that this snippet
--- should be constructed w/ a luasnip format method.
---
---@param fmt_str string: the snippet format string
---@param mode FormatMode|nil: indicates which luasnip format method should be used when
--- building w/ format strings; optional, defaults to FormatMode.A, at the time of writing
---@return SnippetBuilder: this instance
function SnippetBuilder:withFmt(fmt_str, mode)
  return self:withFmtStr(fmt_str)
             :withFmtMode(mode)
end


---@see SnippetBuilder.withFmt
function SnippetBuilder:withFmtStr(fmt_str)
  self.fmt_str = fmt_str
  return self
end


---@see SnippetBuilder.withFmt
function SnippetBuilder:withFmtMode(mode)
  mode = FormatMode.orDefault(mode)

  self.fmt_method = 'fmt' .. mode
  return self
end


function SnippetBuilder:nodeBuilder()
  self.nodes = self.nodes or NodesBuilder.new(self)
  return self.nodes
end


-- function SnippetBuilder:withText(text)
--   self.node = self.node or NodesBuilder.new()
--   self.node:withText(text)
--
--   return self
-- end
--
--
-- function SnippetBuilder:withInsert(mode_or_idx)
--   self.node = self.node or NodesBuilder.new()
--   self.node:withInsert(mode_or_idx)
--
--   return self
-- end
--
--
-- function SnippetBuilder:withChoice()
--   self.node = self.node or NodesBuilder.new()
-- end


---@private
function SnippetBuilder:buildForNodes()
  return ls.snippet(self.args, self.nodes:getNodes())
end


---@private
function SnippetBuilder:buildForFmt()
  Validate.required(
    { 'fmt_method', 'fmt_str' },
    self,
    'build a snippet w/ a format method'
  )

  local fmt_method = lsFmt[self.fmt_method]

  return ls.snippet(
    self.args,
    fmt_method(self.fmt_str, self.nodes)
  )
end


---@private
function SnippetBuilder:validateBuild()
  Validate.required({ 'args', 'nodes' }, self, 'build a snippet')
  Validate.required({ 'trig' }, self.args, 'build a snippet')
end


--- Builds a snippet w/ this instance.
---
---@return table: the snippet
function SnippetBuilder:build()
  self:validateBuild()

  if String.nil_or_empty(self.fmt_method) then
    return self:buildForNodes()
  end

  return self:buildForFmt()
end

return SnippetBuilder

