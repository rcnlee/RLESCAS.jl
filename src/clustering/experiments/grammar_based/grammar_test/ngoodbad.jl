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

include(Pkg.dir("RLESCAS/src/clustering/clustering.jl"))
include(Pkg.dir("RLESCAS/src/clustering/experiments/grammar_based/grammar.jl"))

const GENOME_SIZE = 500
const POP_SIZE = 1000
const MAXWRAPS = 2

function goodbad_test(pop_size::Int64=POP_SIZE, genome_size::Int64=GENOME_SIZE, maxwraps::Int64=MAXWRAPS)
  grammar = create_grammar()
  pop = ExamplePopulation(pop_size, genome_size)
  ngood = nbad = ntotal = 0

  for ind in pop.individuals
    try
      ind.code = transform(grammar, ind, maxwraps=maxwraps)
      @show ind.code
      ngood += 1
      ntotal += 1
    catch e
      println("exception = $e")
      ind.code = nothing
      nbad += 1
      ntotal += 1
    end
  end

  @show ngood
  @show nbad
  @show ntotal
  return filter(ind -> ind.code != nothing, pop)
end

goodbad_test();