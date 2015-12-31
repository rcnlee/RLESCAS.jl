# *****************************************************************************
# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# *****************************************************************************
# Copyright ã 2015, United States Government, as represented by the
# Administrator of the National Aeronautics and Space Administration. All
# rights reserved.  The Reinforcement Learning Encounter Simulator (RLES)
# platform is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable
# law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
# _____________________________________________________________________________
# Reinforcement Learning Encounter Simulator (RLES) includes the following
# third party software. The SISLES.jl package is licensed under the MIT Expat
# License: Copyright (c) 2014: Youngjun Kim.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED
# "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *****************************************************************************

#Derivation tree for GrammaticalEvolution
#Warning: not all rules are supported
module DerivationTrees

export DerivTreeParams, DerivationTree, DerivTreeNode, getvalue
export initialize!, step!, isterminal, actionspace

using GrammaticalEvolution
using DataStructures

using Debug

typealias DecisionRule Union{OrRule, RangeRule} #rules that require a decision

type DerivTreeParams
  grammar::Grammar
end

type DerivTreeNode
  cmd::ASCIIString
  rule::Rule
  action::Int64
  depth::Int64
  children::Vector{DerivTreeNode}
end
function DerivTreeNode(cmd::ASCIIString, rule::Rule, depth::Int64=0, action::Int64=-1)
  return DerivTreeNode(cmd, rule, action, depth, DerivTreeNode[])
end

type DerivationTree
  params::DerivTreeParams
  root::DerivTreeNode
  opennodes::Stack
end

function DerivationTree(p::DerivTreeParams)
  root = DerivTreeNode("", p.grammar.rules[:start])
  tree = DerivationTree(p, root, Stack(DerivTreeNode))
  return tree
end

function initialize!(tree::DerivationTree)
  push!(tree.opennodes, tree.root)
  process_non_decisions!(tree)
end

function step!(tree::DerivationTree, a::Int64)
  opennodes = tree.opennodes
  if isempty(opennodes)
    return #we're done
  end
  node = pop!(opennodes)
  process!(tree, node, node.rule, a)
  process_non_decisions!(tree)
end

isterminal(tree::DerivationTree) = isempty(tree.opennodes)

function process_non_decisions!(tree::DerivationTree)
  opennodes = tree.opennodes
  while !isempty(opennodes) && !isa(top(opennodes).rule, DecisionRule)
    node = pop!(opennodes)
    process!(tree, node, node.rule)
  end
end

###########################
### process! nonterminals
function process!(tree::DerivationTree, node::DerivTreeNode, rule::OrRule, a::Int64)
  node.action = a
  node.cmd = rule.name
  idx = ((a - 1) % length(rule.values)) + 1
  child_node = DerivTreeNode("", rule.values[idx], node.depth + 1)
  push!(node.children, child_node)
  push!(tree.opennodes, child_node)
end

function process!(tree::DerivationTree, node::DerivTreeNode, rule::ReferencedRule)
  #don't create a child node for reference rules, shortcut through
  node.cmd = rule.name
  node.rule = tree.params.grammar.rules[rule.symbol]
  push!(tree.opennodes, node)
end

#= not tested...
function process!(tree::DerivationTree, node::DerivTreeNode, rule::AndRule)
  for subrule in rule.values
    child_node = DerivTreeNode(rule.name, subrule, node.depth + 1)
    push!(node.children, child_node)
    push!(tree.opennodes, child_node)
  end
end
=#

function process!(tree::DerivationTree, node::DerivTreeNode, rule::ExprRule)
  node.cmd = rule.name
  for arg in rule.args
    if isa(arg, Rule)
      child_node = DerivTreeNode("", arg, node.depth + 1)
      push!(node.children, child_node)
      push!(tree.opennodes, child_node)
    end
  end
end

###########################
### Terminals
function process!(tree::DerivationTree, node::DerivTreeNode, rule::RangeRule, a::Int64)
  node.cmd = rule.name
  node.action = a
end

function process!(tree::DerivationTree, node::DerivTreeNode, rule::Terminal)
  node.cmd = rule.name
end

function process!(tree::DerivationTree, node::DerivTreeNode, x)
  node.cmd = string(x)
end

###########################
### getvalue

getvalue(tree::DerivationTree) = getvalue(tree.root) #entry
getvalue(node::DerivTreeNode) = getvalue(node, node.rule)
getvalue(node::DerivTreeNode, rule::Terminal) = rule.value

function getvalue(node::DerivTreeNode, rule::RangeRule)
  return ((node.action - 1) % length(rule.range)) + rule.range.start
end

function getvalue(node::DerivTreeNode, rule::OrRule)
  child_node = node.children[1]
  return getvalue(child_node, child_node.rule)
end

function getvalue(node::DerivTreeNode, rule::ExprRule)
  xs = Any[]
  child_i = 1
  for arg in rule.args
    if isa(arg, Rule)
      child_node = node.children[child_i]
      push!(xs, getvalue(child_node, child_node.rule))
      child_i += 1
    else
      push!(xs, arg)
    end
  end
  return Expr(xs...)
end

###########################
###
function actionspace(tree::DerivationTree)
  if isempty(tree.opennodes)
    return 0:0
  end
  node = top(tree.opennodes)
  return actionspace(node, node.rule)
end

actionspace(node::DerivTreeNode, rule::OrRule) = 1:length(rule.values)
actionspace(node::DerivTreeNode, rule::RangeRule) = 1:length(rule.range)

end #module
