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

module TreeExplainVis

export drawplot, plot_pop_distr, plot_fitness, plot_fitness5, plot_pop_diversity, plot_itertime

using Gadfly, Reel
using DataFrames

function drawplot(outfile::AbstractString, p::Plot;
                  width=4inch, height=3inch)
  if endswith(outfile, ".pdf")
    draw(PDF(outfile, width, height), p)
  elseif endswith(outfile, ".png")
    draw(PNG(outfile, width, height), p)
  elseif endswith(outfile, ".svg")
    draw(SVG(outfile, width, height), p)
  elseif endswith(outfile, ".tex")
    draw(PGF(outfile, width, height), p)
  elseif endswith(outfile, ".ps")
    draw(PS(outfile, width, height), p)
  else
    error("drawplot: extension not recognized $(splitext(outfile)[2])")
  end
end

function writefilm(file::AbstractString, film; remove_destination::Bool=true)
  ext = splitext(file)[2]
  tmpfile = splitext(basename(tempname()))[1] * ext #temp name, current directory, same ext as file
  write(tmpfile, film)
  mv(tmpfile, file, remove_destination=remove_destination) #workaround for Reel not working for long filenames
end

function plot_pop_distr(log::DataFrame, outfile::ASCIIString="pop_distr.gif"; fps::Float64=5.0)
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    id = D[:decision_id][1]
    n_iters = maximum(D[:iter])

    #counts
    film1 = roll(fps=fps, duration=n_iters / fps) do t, dt
      i = Int64(round(t * fps + 1))
      D1 = D[D[:iter] .== i, [:bin_center, :count]]
      plot(D1, x="bin_center", y="count", Geom.bar,
           Guide.xlabel("Fitness"), Guide.ylabel("Count"), Guide.title("Population Fitness, Generation=$i"))
    end
    writefilm("$(fileroot)_$(id)_counts$ext", film1)

    #unique fitness
    film2 = roll(fps=fps, duration=n_iters / fps) do t, dt
      i = Int64(round(t * fps + 1))
      D1 = D[D[:iter] .== i, [:bin_center, :unique_fitness]]
      plot(D1, x="bin_center", y="unique_fitness", Geom.bar,
           Guide.xlabel("Fitness"), Guide.ylabel("Number of Unique Fitness"), Guide.title("Population Unique Fitness, Generation=$i"))
    end
    writefilm("$(fileroot)_$(id)_uniqfitness$ext", film2)

    #unique code
    film3 = roll(fps=fps, duration=n_iters / fps) do t, dt
      i = Int64(round(t * fps + 1))
      D1 = D[D[:iter] .== i, [:bin_center, :unique_code]]
      plot(D1, x="bin_center", y="unique_code", Geom.bar,
           Guide.xlabel("Fitness"), Guide.ylabel("Number of Unique Code"), Guide.title("Population Unique Code, Generation=$i"))
    end
    writefilm("$(fileroot)_$(id)_uniqcode$ext", film3)
  end
end

function plot_fitness(log::DataFrame, outfile::ASCIIString="fitness.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    p = plot(D, x="iter", y="fitness", Geom.point, Geom.line)
    push!(plotvec, p)
    id = D[:decision_id][1]
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

function plot_fitness5(log::DataFrame, outfile::ASCIIString="fitness5.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    p = plot(D, x="iter", y="fitness", color="position", Geom.point, Geom.line)
    push!(plotvec, p)
    id = D[:decision_id][1]
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

function plot_pop_diversity(log::DataFrame, outfile::ASCIIString="pop_diversity.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    D1 = DataFrame(x=D[:iter], y=D[:unique_fitness], label="num_unique_fitness")
    D2 = DataFrame(x=D[:iter], y=D[:unique_code], label="num_unique_code")
    p = plot(vcat(D1, D2), x="x", y="y", color="label", Geom.point, Geom.line)
    push!(plotvec, p)
    id = D[:decision_id][1]
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

function plot_itertime(log::DataFrame, outfile::ASCIIString="itertime.pdf")
  plotvec = Plot[]
  fileroot, ext = splitext(outfile)
  for D in groupby(log, :decision_id)
    p = plot(D, x="iter", y="iteration_time_s", Geom.point, Geom.line)
    push!(plotvec, p)
    id = D[:decision_id][1]
    drawplot("$(fileroot)_$id$ext", p)
  end
  return plotvec
end

end #module
