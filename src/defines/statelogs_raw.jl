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

import ..DefineLog; DL = DefineLog
using SISLES
using RLESUtils, Loggers
using Compat
import Compat.ASCIIString

const STATELOGFILEROOT = Pkg.dir("RLESCAS/test/results/statelog")

function statelog_setup(sim)
    logs = TaggedDFLogger()
    nams = statelognames(sim)
    add_folder!(logs, "States", fill(Any, length(nams)), nams)
    addObserver(sim, "initialize", s->statelog_capture(logs, s[1]))
    addObserver(sim, "update", s->statelog_capture(logs, s[1]))
    logs
end
function statelog_finish(sim, logs; fileroot=STATELOGFILEROOT)
    save_log(fileroot, logs)
    empty!(sim.observer)
end

function statelog_capture(logs, s)
    A = Any[]
    for i in eachindex(s.em.output_commands) #encounter
        x = DL.extract_command(s.em.output_commands[i])
        append!(A, x)
    end
    for i in eachindex(s.pr) #reponse
        x = DL.extract_response(s.pr[i])
        append!(A, x)
    end
    for i in eachindex(s.dm) #dynamics
        x = DL.extract_adm(s.dm[i])
        append!(A, x)
    end
    for i in eachindex(s.wm.states)
        x = DL.extract_wm(s.wm, i)
        append!(A, x)
    end
    for i in eachindex(s.sr) #sensor
        x = DL.extract_sensor(s.sr[i])
        append!(A, x)
    end
    for i in eachindex(s.cas) #cas
        x = DL.extract_ra_detailed(s.cas[i])
        append!(A, x)
    end
    push!(A, s.t_index) 
    push!(A, s.step_logProb)
    push!(logs, "States", A)
end

function statelognames(s)
    A = ASCIIString[]
    for i in eachindex(s.em.output_commands) #encounter
        nams = DL.extract_command_names(s.em.output_commands[i]) #this is very brittle...
        nams = map(x->"em_"*x*"_ac$i", nams)
        append!(A, nams)
    end
    for i in eachindex(s.pr) #reponse
        nams = DL.extract_response_names(s.pr[i])
        nams = map(x->"pr_"*x*"_ac$i", nams)
        append!(A, nams)
    end
    for i in eachindex(s.dm) #dynamics
        nams = DL.extract_adm_names(s.dm[i])
        nams = map(x->"dm_"*x*"_ac$i", nams)
        append!(A, nams)
    end
    for i in eachindex(s.wm.states)
        nams = DL.extract_wm_names(s.wm)
        nams = map(x->"wm_"*x*"_ac$i", nams)
        append!(A, nams)
    end
    for i in eachindex(s.sr) #sensor
        nams = DL.extract_sensor_names(s.sr[i])
        nams = map(x->"sr_"*x*"_ac$i", nams)
        append!(A, nams)
    end
    for i in eachindex(s.cas) #cas
        nams = DL.extract_ra_detailed_names(s.cas[i])
        nams = map(x->"cas_"*x*"_ac$i", nams)
        append!(A, nams)
    end
    push!(A, "t_index") 
    push!(A, "logProb")
    A
end
