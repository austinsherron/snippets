local Validate   = require 'toolbox.utils.validate'
local InsertMode = require('snippets.utils.builder.modes').insert

local ternary = require('toolbox.core.bool').ternary

local ls       = require 'luasnip'
local lsExtras = require 'luasnip.extras'


---@alias FnNodeCallback fun(args: any[], parent: Snippet|Node, userArgs: table): string|string[]

local function errMsg(where, what, ...)
  local values = Table.map_items(
    Table.pack(...),
    { vals = String.tostring }
  )

  what = string.format(what, Table.unpack(values))
  return string.format('NodesBuilder.%s: %s', where, what)
end


local function newErr(where, what, ...)
  error(errMsg(where, what, ...))
end

local MODE_METHODS = {
  [InsertMode.CHILD] = ls.i,
  [InsertMode.LAST]  = lsExtras.rep,
  [InsertMode.NEW]   = ls.i,
  [InsertMode.PREV]  = lsExtras.rep,
}

--- A recursive utility class used to build snippet nodes.
---
---@class NodesBuilder
---@field private root boolean|nil
---@field private parent SnippetBuilder|NodesBuilder|nil
---@field private toNode (fun(ns: table[]): n: table)
---@field private idx integer
---@field private nodes table[]
local NodesBuilder = {}
NodesBuilder.__index = NodesBuilder

--- Constructor
---
---@param snippetBuilder SnippetBuilder|nil: the snippet builder for which the node
--- builder is being used, if any; a nil value indicates a standalone node builder
--- instance
---@return NodesBuilder: a new instance
function NodesBuilder.new(snippetBuilder)
  local this = {
    root    = true,
    parent  = snippetBuilder,
    toNode  = nil,
    idx     = 0,
  }
  return setmetatable(this, NodesBuilder)
end


--- Constructor. The constructed instance builds nodes for a parent node, i.e.: choice,
--- snippet, etc.
---
---@param parent NodesBuilder: a reference to the parent builder
---@param toNode (fun(c: NodesBuilder): n: table): a callable that, given a reference to
--- the child builder, constructs and returns a container node
---@return NodesBuilder: a new builder used to construct nodes for a parent node
function NodesBuilder.child(parent, toNode)
  local this = {
    root    = false,
    parent  = parent,
    toNode  = toNode,
    idx     = parent.idx,
  }
  return setmetatable(this, NodesBuilder)
end


---@private
function NodesBuilder:isRoot()
  return self.root or self.parent == nil
end


---@private
function NodesBuilder:isChild()
  return not self:isRoot()
end


---@private
function NodesBuilder:isStandalone()
  return self.parent == nil
end


---@private
---@return NodesBuilder
function NodesBuilder:withNode(...)
  local nodes = Table.pack(...)
  self.nodes = Table.concat({ self.nodes or {}, nodes })

  return self
end


--- Adds a text node to the builder.
---
---@param text string: the text for the new node
---@return NodesBuilder: this instance
function NodesBuilder:withText(text)
  return self:withNode(ls.t(text))
end


local function toModeAndPrev(modeOrIdx)
  local prev = ternary(type(modeOrIdx) == 'number', modeOrIdx)
  local mode = ternary(
    prev == nil,
    function() return InsertMode.orDefault(modeOrIdx) end,
    InsertMode.PREV
  )

  return mode, prev
end


local function isValidChildInsert(modeOrIdx, isRep)
    return not isRep and (modeOrIdx == nil or modeOrIdx == InsertMode.CHILD)
end


---@private
function NodesBuilder:validateInsert(modeOrIdx, isRep)
  if self:isChild() and isValidChildInsert(modeOrIdx, isRep) then
    return InsertMode.CHILD, nil
  elseif self:isChild() then
    newErr('withInsert', 'cannot specify insert idx for child nodes')
  end

  local mode, prev = toModeAndPrev(modeOrIdx)
  local curr = self.idx

  if self.idx == 0 and mode ~= InsertMode.NEW then
    newErr('withInsert', 'invalid insert mode=%s w/ no previous insert nodes', mode)
  elseif mode == InsertMode.PREV and curr == nil then
    newErr('withInsert', 'prev idx is required for mode=%s', mode)
  elseif mode == InsertMode.PREV and prev >= curr then
    newErr('withInsert', 'prev idx=%s must be < curr=%s for mode=%s ', prev, curr, mode)
  end

  return mode, prev
end


---@private
function NodesBuilder:nextIdx(mode, prev)
  if mode == InsertMode.CHILD then
    return nil
  elseif mode == InsertMode.LAST then
    return self.idx
  elseif mode == InsertMode.NEW then
    self.idx = self.idx + 1
    return self.idx
  elseif mode == InsertMode.PREV then
    return prev
  else
    error('InsertMode.nextIdx: unrecognized insert mode=' .. mode)
  end
end


--- Adds an insert node to the builder.
---
---@param modeOrIdx InsertMode|integer|nil: indicates how the index for the insert node
--- should be determined; an integer indicates that a previous index should be used for
--- the new node; if the builder is building a root node, nil indicates that a new insert
--- node should be added; if the builder is building a child node, nil is the only valid
--- choice (besides an explicit reference to InsertMode.CHILD)
---@return NodesBuilder: this instance
function NodesBuilder:withInsert(modeOrIdx)
  local mode, prev = self:validateInsert(modeOrIdx, false)
  local idx = self:nextIdx(mode, prev)

  local method = MODE_METHODS[mode]
  return self:withNode(method(idx))
end


--- Syntactic sugar for NodesBuilder:withInsert(InsertMode.LAST) or
--- NodesBuilder:withInsert(InsertMode.PREV, integer).
---
---@param idx integer|nil: the index of the node to repeat, or nil for InsertMode.LAST
---@return NodesBuilder: this instance
function NodesBuilder:withRep(idx)
  if idx == nil then
    return self:withInsert(InsertMode.LAST)
  end

  return self:withInsert(idx)
end


--- Constructs and returns a new "choice" node builder.
---
---@return NodesBuilder: a child choice node builder instance
function NodesBuilder:withChoice()
  if self:isChild() then
    newErr('withChoice', "cannot define recursive choice nodes")
  end

  self:nextIdx(InsertMode.NEW)

  local toNode = function(c) return ls.c(c.idx, c.nodes) end
  return NodesBuilder.child(self, toNode)
end


--- Constructs and returns a new function node.
---
---@param fn FnNodeCallback: the function that the node calls
---@param refNodes integer[]: references to the indices of nodes who contents will be
--- passed to fn as arguments
---@param userArgs table|nil: an arbitrary table of user-defined arguments to pass through
--- to the callback
---@return NodesBuilder: this instance
function NodesBuilder:withFunction(fn, refNodes, userArgs)
  if self:isChild() then
    newErr('withFunction', "cannot define recursive function nodes", self.toNode)
  end

  return self:withNode(ls.f(fn, refNodes, userArgs))
end


--- Builds the node if it's a child node, appends it to the parent builder's node array,
--- and returns the parent builder.
----
--- Note: this function exists separately from NodesBuilder.build so that callers have to
--- be explicit about what they're doing: the recursive nature of this utility has the
--- potential to contribute to confusion.
---
---@return NodesBuilder: this builder's parent builder w/ this builder's
--- snippet node appended to its parent's nodes array
function NodesBuilder:buildChild()
  if self:isRoot() then
    newErr('buildChild', 'cannot call buildChild on a root node builder')
  end

  Validate.required({ 'toNode', 'nodes' }, self, 'build a snippet')
  return self.parent:withNode(self.toNode(self))
end


---@return Node[]: a table-like array of snippet nodes
function NodesBuilder:getNodes()
  return self.nodes
end


--- Returns the builder's parent.
---
---@param strict boolean|nil: if true, raises an error if the builder: 1) is the child of
--- a non-snippet builder, 2) is standalone, or 3) has no nodes of its own; if false, all
--- validations are skipped; optional, defaults to true
---@return SnippetBuilder|NodesBuilder|nil: the node's parent
function NodesBuilder:getParent(strict)
  strict = strict or true

  if not strict then
    return self.parent
  end

  if self:isChild() then
    newErr('parent', 'cannot retrieve the parent of a non-root node')
  elseif self:isStandalone() then
    newErr('parent', 'cannot retrieve the parent of a standalone node')
  elseif Table.nil_or_empty(self.nodes) then
    newErr('parent', 'cannot retrieve the parent of a builder w/ no nodes')
  end

  return self.parent
end

return NodesBuilder

