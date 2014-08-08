module(..., package.seeall)

require "json"

first_gmcp = true
prompt_queue = {}
blackout_queue = {}
failsafes = {}


function gmcp_received_char_vitals(name, line, wc)
	local dt = json.decode(wc[1])
	
	--If this is the first gmcp message received...
	if first_gmcp then 
		first_gmcp = false
		setmetatable(core.vitals, nil)
		Execute("get_items_list")
		Execute("get_rift_list")
		--Execute("reset_roominfo")
	end
	
	--Set previous vitals
	core.vitals.prev_hp = core.vitals.hp or 0
	core.vitals.prev_mp = core.vitals.mp or 0 
	core.vitals.prev_ep = core.vitals.ep or 0
	
	--Hopefully we can push for some vitals renaming on gmcp.
	local xlate_stat =
	{
		ego = "ep",
		maxego = "maxep",
		ep = "end",
		maxep = "maxend",
	}
	
	for v,a in pairs(dt) do
		v, a = xlate_stat[v] or v, tonumber(a) or a
		if not balances.translate_gmcp(v, a) then
			core.vitals[v] = a
		end
	end
	
	--Calculate vital percents.
	core.vitals.hp_pct = (core.vitals.hp/core.vitals.maxhp)
	core.vitals.mp_pct = (core.vitals.mp/core.vitals.maxmp)
	core.vitals.ep_pct = (core.vitals.ep/core.vitals.maxep)
end


--Prompt Event
function prompt_add(name, func)
	prompt_queue[name] = func
end

local function execute_prompt_queue()
	for n,f in pairs(prompt_queue) do
		if (type(f) == "function") then
			f()
		end
		prompt_queue[n] = nil
	end
end

function received_prompt(name, line, wc, styles)
	if first_gmcp then
		ui.gag_prompt()
		SendNoEcho()
	end
	
	execute_prompt_queue()
	curing.routine()
	ui.draw_prompt(wc[1])
	curing.last_cured = {}
end


--Blackout event
function blackout_add(name, func)
	blackout_queue[name] = func
end

local function execute_blackout_queue()
	for n,f in pairs(blackout_queue) do
		if (type(f) == "function") then
			f()
		end
		blackout_queue[n] = nil
	end
end

function received_blackout_prompt()
	execute_blackout_queue()
	curing.routine()
	ui.draw_blackout_prompt()
	curing.last_cured = {}
end


--System Failsafes. These call functions on timeout.
function failsafe_add(name, func, seconds, nodup)
	if not (nodup and failsafes[name]) then
		failsafes[name] = func
		local mins = math.floor(seconds/60)
		local secs = seconds % 60
		ImportXML(
			[[
			<timers>
			  <timer
			   enabled="y" 
		       name="failsafe_]]..name..[["
		       minute="]]..mins..[["
		       second="]]..secs..[["
			   one_shot="y"
			   send_to="12"
			   group="Balances">
			  <send>
				if events.failsafes["]]..name..[["] then
					events.failsafes["]]..name..[["]()
					events.failsafes["]]..name..[["] = nil
				end
			  </send>
			  </timer>
			</timers>
		]])
	end
end

function failsafe_clear(name)
	failsafes[name] = nil
	DeleteTimer("failsafe_"..name)
end