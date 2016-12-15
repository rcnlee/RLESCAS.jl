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
using RLESUtils, Loggers, MathUtils
using Compat
import Compat.ASCIIString

const STATELOGFILEROOT = Pkg.dir("RLESCAS/test/results/statelog")
const STATELOGNAMES = [
    "RA_1",
    "vert_rate_1",
    "alt_diff_1",
    "psi_1",
    "intr_sr_1",
    "intr_chi_1",
    "intr_vrc0_1",
    "intr_vrc1_1",
    "intr_vrc2_1",
    "cc0_1",
    "cc1_1",
    "cc2_1",
    "vc0_1",
    "vc1_1",
    "vc2_1",
    "ua0_1",
    "ua1_1",
    "ua2_1",
    "da0_1",
    "da1_1",
    "da2_1",
    "target_rate_1",
    "crossing_1",
    "alarm_1",
    "alert_1",
    "intr_out_vrc0_1",
    "intr_out_vrc1_1",
    "intr_out_vrc2_1",
    "intr_out_tds_1",
    "response_none_1",
    "response_stay_1",
    "response_follow_1",
    "response_timer_1",
    "response_h_d_1",
    "response_psi_d_1",
    "v_1",
    "h_1",
    "RA_2",
    "vert_rate_2",
    "alt_diff_2",
    "psi_2",
    "intr_sr_2",
    "intr_chi_2",
    "intr_vrc0_2",
    "intr_vrc1_2",
    "intr_vrc2_2",
    "cc0_2",
    "cc1_2",
    "cc2_2",
    "vc0_2",
    "vc1_2",
    "vc2_2",
    "ua0_2",
    "ua1_2",
    "ua2_2",
    "da0_2",
    "da1_2",
    "da2_2",
    "target_rate_2",
    "crossing_2",
    "alarm_2",
    "alert_2",
    "intr_out_vrc0_2",
    "intr_out_vrc1_2",
    "intr_out_vrc2_2",
    "intr_out_tds_2",
    "response_none_2",
    "response_stay_2",
    "response_follow_2",
    "response_timer_2",
    "response_h_d_2",
    "response_psi_d_2",
    "v_2",
    "h_2",
    "converging",
    "abs_alt_diff",
    "horizontal_range",
    "t",
    "encounter_id"]

const STATELOGTYPES = [
    Bool,
    Float64,
    Float64,
    Float64,
    Float64,
    Float64,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Float64,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Float64,
    Bool,
    Bool,
    Bool,
    Float64,
    Float64,
    Float64,
    Float64,
    Float64,
    Bool,
    Float64,
    Float64,
    Float64,
    Float64,
    Float64,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Float64,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Bool,
    Float64,
    Bool,
    Bool,
    Bool,
    Float64,
    Float64,
    Float64,
    Float64,
    Float64,
    Bool,
    Float64,
    Float64,
    Int64,
    Int64]

function statelog_setup(sim)
    logs = TaggedDFLogger()
    add_folder!(logs, "States", STATELOGTYPES, STATELOGNAMES)
    #addObserver(sim, "initialize", s->statelog_capture(logs, s[1]))
    addObserver(sim, "update", s->statelog_capture(logs, s[1]))
    logs
end
function statelog_finish(sim, logs; fileroot=STATELOGFILEROOT)
    save_log(fileroot*".txt", logs)
    empty!(sim.observer)
end

function statelog_capture(logs, s)
    A = Any[]
    
    #guard
    if length(s.dm) != 2
        error("Only num_aircraft == 2 is supported!")
    end
    for i = 1:2
        push!(A, Bool(DL.is_ra_active(s.cas[i]))) #ra_active
        push!(A, Float64(s.cas[i].input.ownInput.dz)) #dz
        z1 = s.cas[i].input.ownInput.z
        z2 = s.cas[i].input.intruders[1].z
        push!(A, Float64(z2-z1)) #z
        push!(A, Float64(s.cas[i].input.ownInput.psi)) #psi
        push!(A, Float64(s.cas[i].input.intruders[1].sr)) #sr
        push!(A, Float64(s.cas[i].input.intruders[1].chi)) #chi
        vrc = s.cas[i].input.intruders[1].vrc #vrc
        push!(A, Bool(vrc == 0))
        push!(A, Bool(vrc == 1))
        push!(A, Bool(vrc == 2))
        cc = bin(Int(s.cas[i].output.cc), 3) #cc
        push!(A, Bool(cc[1] == '1'))
        push!(A, Bool(cc[2] == '1'))
        push!(A, Bool(cc[3] == '1'))
        vc = bin(Int(s.cas[i].output.vc), 3) #vc
        push!(A, Bool(vc[1] == '1'))
        push!(A, Bool(vc[2] == '1'))
        push!(A, Bool(vc[3] == '1'))
        ua = bin(Int(s.cas[i].output.ua), 3) #ua
        push!(A, Bool(ua[1] == '1'))
        push!(A, Bool(ua[2] == '1'))
        push!(A, Bool(ua[3] == '1'))
        da = bin(Int(s.cas[i].output.da), 3) #da
        push!(A, Bool(da[1] == '1'))
        push!(A, Bool(da[2] == '1'))
        push!(A, Bool(da[3] == '1'))
        push!(A, Float64(s.cas[i].output.target_rate)) #target_rate
        push!(A, Bool(s.cas[i].output.crossing)) #crossing
        push!(A, Bool(s.cas[i].output.alarm)) #alarm
        push!(A, Bool(s.cas[i].output.alert)) #alert
        vrc = s.cas[i].output.intruders[1].vrc
        push!(A, Bool(vrc == 0)) #vrc
        push!(A, Bool(vrc == 1)) #vrc
        push!(A, Bool(vrc == 2)) #vrc
        push!(A, Float64(s.cas[i].output.intruders[1].tds)) #tds
        push!(A, Bool(s.pr[i].state == "none")) #response state
        push!(A, Bool(s.pr[i].state == "stay")) #response state
        push!(A, Bool(s.pr[i].state == "follow")) #response state
        push!(A, Float64(s.pr[i].timer)) #timer
        push!(A, Float64(s.pr[i].output.h_d)) #output h_d
        push!(A, Float64(s.pr[i].output.psi_d)) #output psi_d
        push!(A, Float64(s.dm[i].state.v)) #v
        push!(A, Float64(s.dm[i].state.h)) #same as z
    end
    psi_1 = s.cas[1].input.ownInput.psi
    psi_2 = s.cas[2].input.ownInput.psi
    intr_chi_1 = s.cas[1].input.intruders[1].chi
    intr_chi_2 = s.cas[2].input.intruders[1].chi
    push!(A, Bool(is_converging(psi_1, intr_chi_1, psi_2, intr_chi_2))) #converging
    h_1 = s.dm[1].state.h 
    h_2 = s.dm[2].state.h 
    abs_alt_diff = abs(h_2-h_1)
    push!(A, Float64(abs_alt_diff)) #abs alt diff
    intr_sr_1 = s.cas[1].input.intruders[1].sr
    push!(A, Float64(sqrt(intr_sr_1^2 - abs_alt_diff^2))) #horizontal range
    push!(A, s.t_index) #t
    push!(A, s.params.encounter_number) #encounter id

    push!(logs, "States", A)
end

#duped from GrammarExpts, time_series_features1.jl
function is_converging(psi1::Float64, chi1::Float64, psi2::Float64, chi2::Float64)
    #println("psi1=$psi1, chi1=$chi1, psi2=$psi2, chi2=$chi2")
    if abs(chi1) > pi/2 && abs(chi2) > pi/2 #flying away from each other
        return false
    end
    z1 = to_plusminus_pi(psi2 - psi1)
    z2 = to_plusminus_pi(psi1 - psi2)
    isconverge = z1 * chi1 <= 0 && z2 * chi2 <= 0
    isconverge
end
