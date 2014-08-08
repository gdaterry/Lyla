module(..., package.seeall)

sent_actions = {}
local cn, fn, cmplt = {}, {}, {}

--The following function keeps track of actions sent by the system that are queued for confirmation of completion.
function sent(action, parameters)
	local name, id = string.gsub(Trim(action), "%s+", "%_"), 1
	sent_actions[name] = sent_actions[name] or {}
	if (#sent_actions[name] > 0) then
		--Assigns the latest id to be higher than those queued.
		id = sent_actions[name][#sent_actions[name]].id + 1
	end
	table.insert(sent_actions[name], {time = os.clock(), parameters = parameters, id = id})
	--Creates a temporary timer, which upon firing will clear the current action record from the table.
	ImportXML(
	[[
	<timers>
	  <timer
	   enabled="y" 
	   name="sent_action_]]..name..[[_]]..id..[["
	   second="1.5"
	   one_shot="y"
	   send_to="12"
	   group="Sent Actions">
	  <send>
		acts.clear("]]..name..[[")
	  </send>
	  </timer>
	</timers>
	]])
end


--Removes a record of an action being sent.
function clear(action)
	local action = string.gsub(Trim(action), "%s+", "_")
	if sent_actions[action] then
		local id, t = sent_actions[action][1].id, sent_actions[action][1].time
		table.remove(sent_actions[action], 1)
		DeleteTimer("sent_action_"..action.."_"..id)
		if (#sent_actions[action] < 1) then
			sent_actions[action] = nil
		end
		--Returns the time at which this action record was sent.
		return t
	end
	
	return false
end


--Used to confirm that a sent action has been properly received and answered by the game.
function completed(action)
	local action = string.gsub(Trim(action), "%s+", "_")
	--Clears a record of the action being sent if available. Retrieves the time at which this happened.
	local sent_time = clear(action)
	--Deletes records of actions that should have completed before this one.
	if sent_time then
		for action,record in pairs(sent_actions) do
			if (record[1].time < sent_time) then
				for _,i in ipairs(record) do
					if (i.time < sent_time) then
						clear(action)
						ui.debug_message("Action had been denied: "..action)
					else
						break
					end
				end
			end
		end
	end
end


--Estimates which command was eaten and removes its record.
function command_denial()
	local time_table = {}
	--Creates a table of action times and places them in chronological order.
	for name,i in pairs(sent_actions) do
		table.insert(time_table, {name = name, time = i[1].time})
	end
	table.sort(time_table, function(a,b) return (a.time < b.time) end)
	
	if (#time_table > 0) then
		clear(time_table[1].name)
		ui.debug_message("Command was denied: "..time_table[1].name)
	end
end


--
function handle_input(name, line, wc)
	--sent(wc[1])
end


--
function handle_completed(name, line, wc)
	local name = string.match(name, "^acts%_completed%_([a-z%_]+)$")
	if cmplt[name] then
		cmplt[name](wc)
	end
end



--Completed action handlers
function outrifted_herb(name, line, wc)
	if sent_actions["outr_"..wc[1]] then
		completed("outr_"..wc[1])
	end
end

function ate_herb(name, line, wc)
	local herb = items.xlate_herb[wc[1]]
	if sent_actions["eat_"..herb] then
		completed("eat_"..herb)
		balances.lose("herb")
	end
end


local fluid_handlers =
{
	["choleric"] = function() balances.lose("purgative") end,
	["melancholic"] = function() balances.lose("purgative") end,
	["phlegmatic"] = function() balances.lose("purgative") end,
	["sanguine"] = function() balances.lose("purgative") end,
	["healing"] = function() balances.lose("healing") end,
}

function drank_fluid(name, line, wc)
	local emptied = (wc[1] == "down the last drop")
	local fluid = items.xlate_potions[wc[2]] or wc[2]
	if sent_actions["sip_"..fluid] then
		completed("sip_"..fluid)
		if fluid_handlers[fluid] then
			fluid_handlers[fluid]()
		end
		items.decrement_vial(fluid, wc[3], emptied)
	end
end

function started_writhe(name, line, wc)
	if sent_actions["writhe"] then	
		completed("writhe")
		events.failsafe_add("writhing",
		function()  
		end, 7)
	end
end

function started_writhe_fail()
	if sent_actions["writhe"] then	
		completed("writhe")
		affs.current["entangled"] = nil
	end
end


--Action functions.
function exec(ac)
	local name = string.gsub(Trim(ac), "%s+", "_")
	if fn[name] then
		fn[name]()
	end
end

function can(ac, wc)
	local name = string.gsub(Trim(ac), "%s+", "_")
	if cn[name] then
		return cn[name](wc)
	end
end


function cn.act()
	if core.is_paused() then
		return false
	end
	
	return true
end


--Herb functions.
local function eat_herb(h)
	local orc, ec = 0, 0
	
	if sent_actions["outr_"..h] then
		orc = #sent_actions["outr_"..h]
	end
	
	if sent_actions["eat_"..h] then
		ec = #sent_actions["eat_"..h]
	end
	
	if not (items.herb_in_inventory(h) and not (orc > ec))  then
		Send("outr "..h)
		sent("outr "..h)
		if (affs.get_level("aura") >= 4) then --I'll make real aeon curing later.
			return
		end
	end
	Send("eat "..h)
	sent("eat "..h)
end

local function can_eat_herb(h)
	local herbs = {"arnica", "calamus", "chervil", "earwort", "faeleaf", "galingale", "kombu", "pennyroyal", "reishi", "wormwood", "yarrow"}
	for _,i in ipairs(herbs) do
		if sent_actions["eat_"..i] then
			return false
		end
	end
	
	if not balances.get("herb") or
	   ((items.rift[h] or 0) < 1 and not items.herb_in_inventory(h))
	then
		return false
	end
	
	return cn.act()
end

function cn.eat_arnica()
	return can_eat_herb("arnica")
end

function fn.eat_arnica()
	eat_herb("arnica")
end


function cn.eat_calamus()
	return can_eat_herb("calamus")
end

function fn.eat_calamus()
	eat_herb("calamus")
end


function cn.eat_chervil()
	return can_eat_herb("chervil")
end

function fn.eat_chervil()
	eat_herb("chervil")
end


function cn.eat_earwort(aff)
	if (aff == "auditory" and (affs.get_level("auditory") == 1) and defs.get("truehearing")) then
		return false
	end
	
	return can_eat_herb("earwort")
end

function fn.eat_earwort()
	eat_herb("earwort")
end


function cn.eat_faeleaf(aff)
	if (aff == "ocular" and (affs.get_level("ocular") == 1) and (defs.get("sixthsense") or events.failsafes["def_sixthsense_coming"])) then
		return false
	end
	
	return can_eat_herb("faeleaf")
end

function fn.eat_faeleaf()
	eat_herb("faeleaf")
end


function cn.eat_galingale()
	return can_eat_herb("galingale")
end

function fn.eat_galingale()
	eat_herb("galingale")
end


function cn.eat_kombu()
	return can_eat_herb("kombu")
end

function fn.eat_kombu()
	eat_herb("kombu")
end


function cn.eat_pennyroyal()
	return can_eat_herb("pennyroyal")
end

function fn.eat_pennyroyal()
	eat_herb("pennyroyal")
end


function cn.eat_reishi()
	return can_eat_herb("reishi")
end

function fn.eat_reishi()
	eat_herb("reishi")
end


function fn.eat_sparkleberry()
	eat_herb("sparkleberry")
end


function cn.eat_wormwood()
	return can_eat_herb("wormwood")
end

function fn.eat_wormwood()
	eat_herb("wormwood")
end


function cn.eat_yarrow()
	return can_eat_herb("yarrow")
end

function fn.eat_yarrow()
	eat_herb("yarrow")
end


--Sipping functions
local function sip_fluid(fluid)
	Send("sip "..fluid)
	sent("sip "..fluid)
end

local function can_sip_purgative(p)
	local purgs = {"choleric", "melancholic", "phlegmatic", "frost", "fire", "sanguine"}
	for _,i in ipairs(purgs) do
		if sent_actions["sip_"..i] then
			return false
		end
	end
	
	if not balances.get("purgative") or
	   (items.total_fluid(p) < 1)
	then
		return false
	end
	
	return cn.act()
end


function cn.sip_choleric()
	return can_sip_purgative("choleric")
end

function fn.sip_choleric()
	sip_fluid("choleric")
end


function cn.sip_melancholic()
	return can_sip_purgative("melancholic")
end

function fn.sip_melancholic()
	sip_fluid("melancholic")
end


function cn.sip_phlegmatic()
	return can_sip_purgative("phlegmatic")
end

function fn.sip_phlegmatic()
	sip_fluid("phlegmatic")
end


function cn.sip_frost()
	return can_sip_purgative("frost")
end

function fn.sip_frost()
	sip_fluid("frost")
end


function cn.sip_fire()
	return can_sip_purgative("fire")
end

function fn.sip_fire()
	sip_fluid("fire")
end


function fn.sip_healing()
	sip_fluid("healing")
end


function cn.sip_sanguine()
	return can_sip_purgative("sanguine")
end

function fn.sip_sanguine()
	sip_fluid("sanguine")
end


--Writhing functions.
function cn.writhe()
	if sent_actions["writhe"] or
	   events.failsafes["writhing"]
	then
		return false
	end
	
	return cn.act()
end

function fn.writhe()
	Send("writhe")
	sent("writhe")
end