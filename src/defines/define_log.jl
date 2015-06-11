import RLESMDPs: ESAction
using SISLES.Encounter
using SISLES.WorldModel
using SISLES.Sensor
using SISLES.CollisionAvoidanceSystem
using SISLES.PilotResponse

import Obj2Dict
using Base.Test

const ENABLE_ROUNDING = true
const ROUND_NDECIMALS = 9

#TODO: consider using OrderedDicts to preserve time order.  For now use sortByTime()
typealias SimLog Dict{String, Any}
typealias SimLogDict Dict{String, Any}

function addObservers!(simLog::SimLog, mdp::RLESMDP)

  addObserver(mdp,     "action_seq", x -> log_action!(simLog, x))
  addObserver(mdp.sim, "CAS_info",   x -> log_cas_info!(simLog, x))
  addObserver(mdp.sim, "Initial",    x -> log_initial!(simLog, x))
  addObserver(mdp.sim, "Command",    x -> log_command!(simLog, x))
  addObserver(mdp.sim, "Sensor",     x -> log_sensor!(simLog, x))
  addObserver(mdp.sim, "CAS",        x -> log_ra!(simLog, x))
  addObserver(mdp.sim, "Response",   x -> log_response!(simLog, x))
  addObserver(mdp.sim, "Dynamics",   x -> log_adm!(simLog, x))
  addObserver(mdp.sim, "WorldModel", x -> log_wm!(simLog, x))
  addObserver(mdp.sim, "run_info",   x -> log_runinfo!(simLog, x))

  return simLog #not required, but returned for convenience
end

function check_key!(d::SimLogDict,k::String; subkey::Union(String,Nothing) = nothing)

  if !haskey(d,k)
    d[k] = SimLogDict()
    if subkey != nothing
      d[k][subkey] = SimLogDict()
    end
  end
end

function log_cas_info!(simLog::SimLog, args)

  #[CAS version]
  cas = args[1]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "CAS_info")
    simLog["var_names"]["CAS_info"] = extract_cas_info_names(cas)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "CAS_info")
    simLog["var_units"]["CAS_info"] = extract_cas_info_units(cas)
  end

  check_key!(simLog, "CAS_info", subkey = "aircraft")

  simLog["CAS_info"] = extract_cas_info(cas)

end

extract_cas_info_names(cas::ACASX) = String["version"]
extract_cas_info_units(cas::ACASX) = String["n/a"]

extract_cas_info(cas::ACASX) = Any[cas.version]

function log_initial!(simLog::SimLog, args)

  #[aircraft_number, time_index, initial]
  aircraft_number = args[1]
  t_index = args[2] #time index starts at 1 so we're OK
  aem = args[3]

  @test t_index == 0

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "initial")
    simLog["var_names"]["initial"] = extract_initial_names(aem)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "initial")
    simLog["var_units"]["initial"] = extract_initial_units(aem)
  end

  check_key!(simLog, "initial", subkey = "aircraft")

  simLog["initial"]["aircraft"]["$(aircraft_number)"] = extract_initial(aircraft_number, aem)

end

extract_initial_names(aem::CorrAEMDBN) = String["v", "x", "y", "z", "psi", "theta", "phi", "v_d"]
extract_initial_units(aem::CorrAEMDBN) = String["ft/s", "ft", "ft", "ft", "deg", "deg", "deg", "ft/s^2"]

function extract_initial(i, aem::CorrAEMDBN)
  # initial
  # airspeed, ft/s, double
  # north position, ft, double
  # east position, ft, double
  # altitude, ft, double
  # heading angle, degrees, double
  # flight path angle, degrees, double
  # roll angle, degrees, double
  # airspeed acceleration, ft/s^2, double

  t, x, y, h, v, psi = aem.aem.dynamic_states[i, 1, :]
  t_n, x_n, y_n, h_n, v_n, psi_n, = aem.aem.dynamic_states[i, 2, :]

  t, v_d, h_d, psi_d = aem.aem.states[i, 1, :]

  theta = atand((h_n - h) / norm(x_n - x, y_n - y)) |> to_plusminus_180
  phi = 0.0

  return round_floats(Any[v, x, y, h, psi, theta, phi, v_d], ROUND_NDECIMALS,
                      enable = ENABLE_ROUNDING)
end

extract_initial_names(aem::StarDBN) = String["v", "x", "y", "z", "psi", "theta", "phi", "v_d"]
extract_initial_units(aem::StarDBN) = String["ft/s", "ft", "ft", "ft", "deg", "deg", "deg", "ft/s^2"]

function extract_initial(i, aem::StarDBN)
  # initial
  # airspeed, ft/s, double
  # north position, ft, double
  # east position, ft, double
  # altitude, ft, double
  # heading angle, degrees, double
  # flight path angle, degrees, double
  # roll angle, degrees, double
  # airspeed acceleration, ft/s^2, double

  is = aem.initial_states[i]
  t, x, y, h, v, psi = is.t, is.x, is.y, is.h, is.v, is.psi

  L, v_d, h_d, psi_d = aem.initial_commands[i]

  theta = atand(h_d / v)
  phi = 0.0

  return round_floats(Any[v, x, y, h, psi, theta, phi, v_d], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_command!(simLog::SimLog, args)

  #[aircraft_number, time_index, command]
  aircraft_number = args[1]
  t_index = args[2] #time index starts at 1 so we're OK
  command = args[3]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "command")
    simLog["var_names"]["command"] = extract_command_names(command)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "command")
    simLog["var_units"]["command"] = extract_command_units(command)
  end

  check_key!(simLog, "command", subkey = "aircraft")
  d_a = simLog["command"]["aircraft"]

  check_key!(d_a, "$(aircraft_number)", subkey = "time")
  d_t = d_a["$(aircraft_number)"]["time"]

  v = extract_command(command)
  d_t["$(t_index)"] = v

  #check to make sure we're in sync
  #@test t_index == length(d_t) + 1 #not called on initialize
end

extract_command_names(command::CorrAEMCommand) = String["h_d", "v_d", "psi_d"]
extract_command_units(command::CorrAEMCommand) = String["ft/s", "ft/s^2", "deg/s"]

function extract_command(command::CorrAEMCommand)

  return round_floats(Any[command.h_d, command.v_d, command.psi_d], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_adm!(simLog::SimLog, args)

  #[aircraft_number, time_index, dynamics model]
  aircraft_number = args[1]
  t_index = args[2] #time index
  adm = args[3]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "adm")
    simLog["var_names"]["adm"] = extract_adm_names(adm)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "adm")
    simLog["var_units"]["adm"] = extract_adm_units(adm)
  end

  check_key!(simLog, "adm", subkey = "aircraft")
  d_a = simLog["adm"]["aircraft"]

  check_key!(d_a, "$(aircraft_number)", subkey = "time")
  d_t = d_a["$(aircraft_number)"]["time"]

  v = extract_adm(adm)
  d_t["$(t_index)"] = v

  #check to make sure we're in sync
  #@test t_index == length(d_t) #make sure we're in sync

end

extract_adm_names(adm::SimpleADM) = String["t", "x", "y", "h", "v", "psi"]
extract_adm_units(adm::SimpleADM) = String["s", "ft", "ft", "ft", "ft/s", "deg"]

function extract_adm(adm::SimpleADM)

  s = adm.state

  return round_floats(Any[s.t, s.x, s.y, s.h, s.v, s.psi], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

extract_adm_names(adm::LLADM) = String["t", "v", "N", "E", "h", "psi", "theta", "phi", "a"]
extract_adm_units(adm::LLADM) = String["s", "ft/s", "ft", "ft", "ft", "rad", "rad", "rad", "ft/s^2"]

function extract_adm(adm::LLADM)

  s = adm.state

  return round_floats(Any[s.t, s.v, s.N, s.E, s.h, s.psi, s.theta, s.phi, s.a], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_wm!(simLog::SimLog, args)

  #[time_index, world model]
  t_index = args[1] #time index
  wm = args[2]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "wm")
    simLog["var_names"]["wm"] = extract_wm_names(wm)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "wm")
    simLog["var_units"]["wm"] = extract_wm_units(wm)
  end

  check_key!(simLog, "wm", subkey = "aircraft")
  d_a = simLog["wm"]["aircraft"]

  for i = 1:wm.number_of_aircraft

    check_key!(d_a, "$i", subkey = "time")
    d_t = d_a["$i"]["time"]

    v = extract_wm(wm,i) #[t, x,y,z,vx,vy,vz]
    d_t["$(t_index)"] = v

    #check to make sure we're in sync
    #@test t_index == length(d_t) #make sure we're in sync
  end

end

extract_wm_names(wm::AirSpace) = String["t", "x", "y", "z", "vx", "vy", "vz"]
extract_wm_units(wm::AirSpace) = String["s", "ft", "ft", "ft", "ft/s", "ft/s", "ft/s"]

function extract_wm(wm::AirSpace, aircraft_number::Int)

  s = wm.states[aircraft_number]

  return round_floats(Any[s.t, s.x, s.y, s.h, s.vx, s.vy, s.vh], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_sensor!(simLog::SimLog, args)

  #[aircraft_number, time_index, cas]
  aircraft_number = args[1]
  t_index = args[2] #time index starts at 1 so we're OK
  sr = args[3]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "sensor")
    simLog["var_names"]["sensor"] = extract_sensor_names(sr)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "sensor")
    simLog["var_units"]["sensor"] = extract_sensor_units(sr)
  end

  v = extract_sensor(sr)
  check_key!(simLog, "sensor", subkey = "aircraft")
  d_a = simLog["sensor"]["aircraft"]

  check_key!(d_a, "$(aircraft_number)", subkey = "time")
  d_t = d_a["$(aircraft_number)"]["time"]

  d_t["$(t_index)"] = v

  #check to make sure we're in sync
  #@test t_index == length(d_t)

end

extract_sensor_names(sr::Nothing) = String[]
extract_sensor_units(sr::Nothing) = String[]

extract_sensor(sr::Nothing) = Any[] #input=[empty]

function extract_sensor_names(sr::SimpleTCASSensor)

  v = String["r", "r_d", "a", "a_d", "num_intruders"]

  for i = 1:length(sr.output.h)
    push!(v,"h_$i", "h_d_$i")
  end

  return v
end

function extract_sensor_units(sr::SimpleTCASSensor)

  v = String["ft", "ft/s", "ft", "ft/s", "integer"]

  for i = 1:length(sr.output.h)
    push!(v, "ft", "ft/s")
  end

  return v
end

function extract_sensor(sr::SimpleTCASSensor)

  #input=[r,r_d, a, a_d],[num_intruders],[h,h_d for each intruder]
  out = sr.output
  num_intruders = length(out.h)

  hhd = Float64[]

  for (h, h_d) in zip(out.h, out.h_d)
    push!(hhd, h, h_d)
  end

  return round_floats(vcat(Any[out.r, out.r_d, out.a, out.a_d],
                           num_intruders,
                           hhd), ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function extract_sensor_names(sr::ACASXSensor)

  v = String["dz", "z", "psi", "h", "modes", "num_intruders"]

  for i=1:length(sr.outputVals.intruders)
    v = vcat(v, String["valid_$i", "id_$i", "modes_$i", "sr_$i", "chi_$i", "z_$i", "cvc_$i", "vrc_$i", "vsb_$i"])
  end

  return v
end

function extract_sensor_units(sr::ACASXSensor)

  v = String["ft/s", "ft", "rad", "ft", "n/a", "integer"]

  for i = 1:length(sr.outputVals.intruders)
    push!(v, "boolean", "integer", "n/a", "ft", "rad", "ft", "n/a", "n/a", "n/a")
  end

  return v
end

function extract_sensor(sr::ACASXSensor)

  #input=[dz,z,psi,h,modes],[num_intruders],[valid,id,modes, sr,chi,z,cvc,vrc,vsb for each intruder]
  out = sr.outputVals
  own = out.ownInput
  num_intruders = length(out.intruders)

  intr_vec = Any[]
  for intr in out.intruders
    push!(intr_vec, intr.valid, intr.id, intr.modes,
                              intr.sr, intr.chi, intr.z, intr.cvc, intr.vrc, intr.vsb)
  end

  return round_floats(vcat(Any[own.dz, own.z, own.psi, own.h, own.modes],
                           num_intruders,
                           intr_vec), ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_ra!(simLog::SimLog, args)

  #[aircraft_number, time_index, cas]
  aircraft_number = args[1]
  t_index = args[2] #time index starts at 1 so we're OK
  cas = args[3]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "ra")
    simLog["var_names"]["ra"] = extract_ra_names(cas)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "ra")
    simLog["var_units"]["ra"] = extract_ra_units(cas)
  end

  #state=[alarm,target_rate,dh_min,dh_max]
  v = extract_ra(cas)
  check_key!(simLog, "ra", subkey = "aircraft")
  d_a = simLog["ra"]["aircraft"]

  check_key!(d_a, "$(aircraft_number)", subkey = "time")
  d_t = d_a["$(aircraft_number)"]["time"]

  d_t["$(t_index)"] = v

  #check to make sure we're in sync
  #@test t_index == length(d_t)

  log_ra_detailed!(simLog, args)

end

extract_ra_names(cas::Nothing) = String["ra_active", "target_rate"]
extract_ra_units(cas::Nothing) = String["boolean", "ft/s"]

extract_ra(cas::Nothing) = Any[false, false]

extract_ra_names(cas::Union(SimpleTCAS,CoordSimpleTCAS)) = String["ra_active", "target_rate"]
extract_ra_units(cas::Union(SimpleTCAS,CoordSimpleTCAS)) = String["boolean", "ft/s"]

function extract_ra(cas::SimpleTCAS)
  return Any[cas.b_TCAS_activated, cas.b_TCAS_activated ? cas.RA.h_d : 0.0]
end

extract_ra_names(cas::ACASX) = String["ra_active", "alarm", "target_rate", "dh_min", "dh_max",
                                      "crossing", "cc", "vc", "ua", "da"]
extract_ra_units(cas::ACASX) = String["boolean", "boolean", "ft/s", "ft/s", "ft/s",
                                      "boolean", "n/a", "n/a", "n/a", "n/a"]

function extract_ra(cas::ACASX)

  ra_active = (cas.outputVals.dh_min > -9999.0 || cas.outputVals.dh_max < 9999.0)::Bool
  return round_floats(Any[ra_active,
                          cas.outputVals.alarm,
                          cas.outputVals.target_rate,
                          cas.outputVals.dh_min,
                          cas.outputVals.dh_max,
                          cas.outputVals.crossing,
                          cas.outputVals.cc,
                          cas.outputVals.vc,
                          cas.outputVals.ua,
                          cas.outputVals.da], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_ra_detailed!(simLog::SimLog, args)

  #[aircraft_number, time_index, cas]
  aircraft_number = args[1]
  t_index = args[2] #time index starts at 1 so we're OK
  cas = args[3]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "ra_detailed")
    simLog["var_names"]["ra_detailed"] = extract_ra_detailed_names(cas)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "ra_detailed")
    simLog["var_units"]["ra_detailed"] = extract_ra_detailed_units(cas)
  end

  #state=[alarm,target_rate,dh_min,dh_max]
  v = extract_ra_detailed(cas)
  check_key!(simLog, "ra_detailed", subkey = "aircraft")
  d_a = simLog["ra_detailed"]["aircraft"]

  check_key!(d_a, "$(aircraft_number)", subkey = "time")
  d_t = d_a["$(aircraft_number)"]["time"]

  d_t["$(t_index)"] = v

  #check to make sure we're in sync
  #@test t_index == length(d_t)

end

function extract_ra_detailed_names(cas::ACASX)

  vcat(["ra_active"], ["ownInput.dz", "ownInput.z", "ownInput.psi", "ownInput.h", "ownInput.modes"],
         [["intruderInput[$i].valid", "intruderInput[$i].id", "intruderInput[$i].modes",
         "intruderInput[$i].sr", "intruderInput[$i].chi", "intruderInput[$i].z", "intruderInput[$i].cvc",
           "intruderInput[$i].vrc", "intruderInput[$i].vsb", "intruderInput[$i].equipage",
           "intruderInput[$i].quant", "intruderInput[$i].sensitivity_index",
           "intruderInput[$i].protection_mode"] for i = 1:cas.max_intruders]...,
         ["ownOutput.cc", "ownOutput.vc", "ownOutput.ua", "ownOutput.da", "ownOutput.target_rate",
          "ownOutput.turn_off_aurals", "ownOutput.crossing", "ownOutput.alarm", "ownOutput.alert",
          "ownOutput.dh_min", "ownOutput.dh_max", "ownOutput.sensitivity_index", "ownOutput.ddh"],
         [["intruderOutput[$i].id", "intruderOutput[$i].cvc", "intruderOutput[$i].vrc",
          "intruderOutput[$i].vsb", "intruderOutput[$i].tds", "intruderOutput[$i].code"]
          for i = 1:cas.max_intruders]...)
end

function extract_ra_detailed_units(cas::ACASX)

  vcat(["boolean"], ["ft/s", "ft", "rad", "ft/s", "integer"],
         [["boolean", "integer", "integer", "ft", "rad", "ft", "n/a", "n/a", "n/a", "enum",
           "ft", "integer", "integer"] for i = 1:cas.max_intruders]...,
         ["n/a", "n/a", "n/a", "n/a", "ft/s", "boolean", "boolean", "boolean", "boolean",
          "ft/s", "ft/s", "integer", "ft/s^2"],
         [["integer", "n/a", "n/a", "n/a", "n/a", "n/a"]
          for i = 1:cas.max_intruders]...)
end

function extract_ra_detailed(cas::ACASX) #log everything

  ra_active = (cas.outputVals.dh_min > -9999.0 || cas.outputVals.dh_max < 9999.0)::Bool

  ownInput = Any[cas.inputVals.ownInput.dz,
             cas.inputVals.ownInput.z,
             cas.inputVals.ownInput.psi,
             cas.inputVals.ownInput.h,
             cas.inputVals.ownInput.modes]

  intruderInputs = vcat([Any[cas.inputVals.intruders[i].valid,
                             cas.inputVals.intruders[i].id,
                             cas.inputVals.intruders[i].modes,
                             cas.inputVals.intruders[i].sr,
                             cas.inputVals.intruders[i].chi,
                             cas.inputVals.intruders[i].z,
                             cas.inputVals.intruders[i].cvc,
                             cas.inputVals.intruders[i].vrc,
                             cas.inputVals.intruders[i].vsb,
                             cas.inputVals.intruders[i].equipage,
                             cas.inputVals.intruders[i].quant,
                             cas.inputVals.intruders[i].sensitivity_index,
                             cas.inputVals.intruders[i].protection_mode]
                          for i=1:length(cas.inputVals.intruders)]...)

  ownOutput = Any[cas.outputVals.cc,
                   cas.outputVals.vc,
                   cas.outputVals.ua,
                   cas.outputVals.da,
                   cas.outputVals.target_rate,
                   cas.outputVals.turn_off_aurals,
                   cas.outputVals.crossing,
                   cas.outputVals.alarm,
                   cas.outputVals.alert,
                   cas.outputVals.dh_min,
                   cas.outputVals.dh_max,
                   cas.outputVals.sensitivity_index,
                   cas.outputVals.ddh]

  intruderOutputs = vcat([Any[cas.outputVals.intruders[i].id,
                              cas.outputVals.intruders[i].cvc,
                              cas.outputVals.intruders[i].vrc,
                              cas.outputVals.intruders[i].vsb,
                              cas.outputVals.intruders[i].tds,
                              cas.outputVals.intruders[i].code]
                          for i=1:length(cas.outputVals.intruders)]...)

  return round_floats(vcat(ra_active,
                           ownInput,
                           intruderInputs,
                           ownOutput,
                           intruderOutputs), ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

function log_response!(simLog::SimLog, args)

  #[aircraft_number, time_index, cas]
  aircraft_number = args[1]
  t_index = args[2] #time index starts at 1 so we're OK
  pr = args[3]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "response")
    simLog["var_names"]["response"] = extract_response_names(pr)
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "response")
    simLog["var_units"]["response"] = extract_response_units(pr)
  end

  v = extract_response(pr)
  check_key!(simLog, "response", subkey = "aircraft")
  d_a = simLog["response"]["aircraft"]

  check_key!(d_a, "$(aircraft_number)", subkey = "time")
  d_t = d_a["$(aircraft_number)"]["time"]

  d_t["$(t_index)"] = v

  #check to make sure we're in sync
  #@test t_index == length(d_t)

end

extract_response_names(pr::StochasticLinearPR) = String["state", "displayRA", "response", "v_d", "h_d", "psi_d", "logProb"]
extract_response_units(pr::StochasticLinearPR) = String["enum", "enum", "enum", "ft/s^2", "ft/s", "deg/s", "float"]

function extract_response(pr::StochasticLinearPR)

  return round_floats(Any[pr.state,
                          pr.displayRA,
                          pr.response,
                          pr.output.t,
                          pr.output.v_d,
                          pr.output.h_d,
                          pr.output.psi_d,
                          pr.output.logProb], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

extract_response_names(pr::LLDetPR) = String["state", "timer", "t", "v_d", "h_d", "psi_d", "logProb"]
extract_response_units(pr::LLDetPR) = String["enum", "s", "s", "ft/s^2", "ft", "rad/s", "float"]

function extract_response(pr::LLDetPR)

  return round_floats(Any[pr.state,
                          pr.timer,
                          pr.output.t,
                          pr.output.v_d,
                          pr.output.h_d,
                          pr.output.psi_d,
                          pr.output.logProb], ROUND_NDECIMALS, enable = ENABLE_ROUNDING)
end

extract_runinfo_names() = String["reward", "md_time", "hmd", "vmd", "nmac"]
extract_runinfo_units() = String["float", "s", "ft", "ft", "boolean"]

function log_runinfo!(simLog::SimLog, args)
  # called only once when isEndState is true

  reward = args[1]
  md_time = args[2]
  hmd = args[3]
  vmd = args[4]
  nmac = args[5]

  check_key!(simLog, "var_names")

  if !haskey(simLog["var_names"], "run_info")
    simLog["var_names"]["run_info"] = extract_runinfo_names()
  end

  check_key!(simLog, "var_units")

  if !haskey(simLog["var_units"], "run_info")
    simLog["var_units"]["run_info"] = extract_runinfo_units()
  end

  check_key!(simLog, "run_info")

  simLog["run_info"] = Any[reward, md_time, hmd, vmd, nmac]

end

function log_action!(simLog::SimLog, args)

  #t_index = args[1] #there but not used
  action = args[2]::ESAction

  if !haskey(simLog, "action_seq")
    simLog["action_seq"] = SaveDict[]
  end

  push!(simLog["action_seq"], Obj2Dict.to_dict(action))

end

function round_floats(v::Vector{Any}, ndigits::Int64; enable::Bool = true)

  out = v

  if enable
    out = map(v) do x
      return isa(x, FloatingPoint) ? round(x, ndigits) : x
    end
  end

  return out
end

#mods x to the range [-b, b]
function to_plusminus_b(x::FloatingPoint, b::FloatingPoint)

  z = mod(x, 2 * b)

  return (z > b) ? (z - 2 * b) : z
end

to_plusminus_180(x::FloatingPoint) = to_plusminus_b(x, 180.0)