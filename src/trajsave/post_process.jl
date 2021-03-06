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

module PostProcess

export PostProcessing, StandardPostProc, postprocess

import Compat.ASCIIString

using ..TrajSaveReplay
using ..AddSupplementary
using ..SaveHelpers
using ..Log_To_CSV
using ..Log_To_Scripted
using ..Log_To_Waypoints
using ..Summarize
using ..Label270_To_Text
import ...RLESCAS

abstract PostProcessing

type StandardPostProc <: PostProcessing
  formats::Vector{ASCIIString}
  filters::Vector{ASCIIString}
end
StandardPostProc() = StandardPostProc(ASCIIString[], ASCIIString[])

function postprocess(filename::AbstractString, opts::StandardPostProc)
  formats = opts.formats
  filters = opts.filters

  sort!(formats)
  #sorting prevents pdf from appearing after tex.  This works around tex being deleted as
  #an intermediate file during the pdf process

  #fill and add supplementary to all files
  fill_replay(filename, overwrite=true)
  add_supplementary(filename)
  #filters
  for f in filters
    if f == "nmacs_only" && !is_nmac(filename)
      return #if it fails any of the filters, we're done
    end
  end

  for f in formats
    if f == "pdf"
      RLESCAS.include_visualize()
      RLESCAS.trajPlot(filename, format=:PDF)
    elseif f == "tex"
      RLESCAS.include_visualize()
      RLESCAS.trajPlot(filename, format=:TEX)
    elseif f == "scripted"
      log_to_scripted(filename)
    elseif f == "waypoints"
      log_to_waypoints(filename)
    elseif f == "csv"
      log_to_csv(filename)
    elseif f == "label270_text"
      label270_to_text(filename)
    elseif f == "summary"
      summarize(filename)
    else
      warn("config: unrecognized output")
    end
  end
end

end #module
