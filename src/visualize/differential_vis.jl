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

module DifferentialVis

export diffPlot

using ..Visualize
using ..DefineSave
using ..SaveHelpers
using ..AddSupplementary

using ..Visualize: TikzUtils, VisCaptions, use_geometry_package!, use_aircraftshapes_package!

using TikzPictures
import PGFPlots
import PGFPlots: Plots, Axis, GroupPlot

using RLESUtils, PGFPlotUtils

function pgfplot_difflog(d1::TrajLog, d2::TrajLog)
    tps = TikzPicture[]
    caps = AbstractString[]

    g = GroupPlot(2, 2, groupStyle = "horizontal sep = 2.2cm, vertical sep = 2.2cm")

    #xy1
    push!(g, pgfplot_hor(d1))

    #xy2
    push!(g, pgfplot_hor(d2))

    #altitude vs time 1
    push!(g, pgfplot_alt(d1))

    #altitude vs time 2
    push!(g, pgfplot_alt(d2))

    tp = PGFPlots.plot(g)
    use_geometry_package!(tp, landscape = true)
    use_aircraftshapes_package!(tp)
    cap = string("sim1 (left): ", vis_runtype_caps(d1), vis_sim_caps(d1), vis_runinfo_caps(d1), 
        "\\\\sim2 (right): ", vis_runtype_caps(d2), vis_sim_caps(d2), vis_runinfo_caps(d2))

    push!(tps, tp)
    push!(caps, cap)

    g = GroupPlot(2, 2, groupStyle = "horizontal sep = 2.2cm, vertical sep = 2.2cm")

    #heading rate vs time 1
    push!(g, pgfplot_heading(d1))

    #heading rate vs time 2
    push!(g, pgfplot_heading(d2))

    #vertical rate vs time 1
    push!(g, pgfplot_vrate(d1))

    #vertical rate vs time 2
    push!(g, pgfplot_vrate(d2))

    tp = PGFPlots.plot(g)
    use_geometry_package!(tp, landscape = true)
    use_aircraftshapes_package!(tp)
    #cap = #same as above for now... 

    push!(tps, tp)
    push!(caps, cap)

    (tps, caps)
end

function diffPlot{T<:AbstractString}(files::Vector{T};
    format::Symbol=:TEXPDF)

    fs,fs1,fs2 = diffFilePairs(files)
    for (f, f1, f2) in zip(fs, fs1, fs2)
        diffPlot(f1, f2; outfileroot=f, format=format)
    end

end

function diffPlot(sim1::AbstractString, sim2::AbstractString; 
    format::Symbol=:TEXPDF,
    outfileroot::AbstractString=getLogFileRoot(sim1))

    add_supplementary(sim1)
    add_supplementary(sim2)

    d1 = trajLoad(sim1)
    d2 = trajLoad(sim2)

    td = TikzDocument()
    (tps, caps) = pgfplot_difflog(d1, d2)

    for (tp,cap) in zip(tps, caps)
        push!(td, tp; caption=cap)
    end

    plot_tikz(outfileroot, td, format)
    td
end

function diffFilePairs{T<:AbstractString}(files::Vector{T};
    ext::AbstractString=".zip", 
    sim1::AbstractString="_sim1",
    sim2::AbstractString="_sim2")

    fs = filter(f->endswith(f, ext), files)
    fs = [replace(f, ext, "") for f in fs]
    fs = [replace(f, sim1, "") for f in fs]
    fs = [replace(f, sim2, "") for f in fs]
    fs = unique(fs)

    fs1 = [f*sim1*ext for f in fs]
    fs2 = [f*sim2*ext for f in fs]

    (fs, fs1, fs2)
end


end #module
