module(..., package.seeall)

require "events"

local lost_balances = {}
local value_table = {healing = true, herb = true, purgative = true, salve = true}

local xlate_gmcp =
{
	beastbal = "beast",
	equilibrium = "e",
	left_arm = "l",
	right_arm = "r",
	balance = "x",
	head = "h",
	left_leg = "ll",
	right_leg = "rl",
	psiid = "id",
	psisub = "sub",
	psisuper = "super"
}

local balance_time =
{
	healing = 7,
	herb = 5,
	purgative = 3,
	salve = 2,
}


--Translates the gmcp variables.
function translate_gmcp(b, value)
	if xlate_gmcp[b] then
		local pv = get(xlate_gmcp[b])
		value_table[xlate_gmcp[b]] = value
		if (pv and not get(xlate_gmcp[b]) and not lost_balances[xlate_gmcp[b]]) then
			lost_balances[xlate_gmcp[b]] = os.clock()
		elseif get(xlate_gmcp[b]) then
			lost_balances[xlate_gmcp[b]] = nil
		end
		return true
	end
	
	return false
end


--Determine if you are on balance or not. It returns true, false or -1 for special values.
function get(b)
	local v = value_table[b]
	if (type(v) == "number") then
		if (v == 1) then
			return true
		elseif (v == 0) then
			return false
		end
	end
	
	return v
end


--Functions for manually tracking if a balance was lost or gained.
function lose(b)
	if value_table[b] then
		value_table[b] = false
		events.failsafe_add("regain_"..b,
		function()
			gain(b)
		end, balance_time[b])
		lost_balances[b] = os.clock()
	end
end

function gain(b)
	value_table[b] = true
	lost_balances[b] = nil
	events.failsafe_clear("regain_"..b)
end


--Returns if you can perform most balance actions.
function full()
	if get("e") and 
	   get("l") and 
	   get("r") and 
	   get("x") and 
	   get("ll") and 
	   get("rl") and 
	   get("id") and 
	   get("sub") and 
	   get("super")
	then
		return true
	end
	
	return false
end


--Regains the balance from a trigger and shows a message.
local line_to_variable =
{
	["equilibrium"] = "e",
	["left arm"] = "l",
	["right arm"] = "r",
	["balance"] = "x",
	["left leg"] = "ll",
	["right leg"] = "rl",
	["head"] = "h",
}

function regained(name, line, wc, styles)
	local rgb = string.match(name, "^balances%_regained%_(%w+)$")
	--Redraw the line as seen.
	for _,i in ipairs(styles) do
		ColourTell(RGBColourToName(i.textcolour), RGBColourToName(i.backcolour), i.text)
	end
	--Do pretty time display
	local lb = line_to_variable[wc[1]] or line_to_variable[rgb] or rgb
	if lost_balances[lb] then
		ColourTell("gray", "", " ("..string.format("%.2f", os.clock() - lost_balances[lb]).."s)")
	end
	--Regain balances.
	if not (rgb == "limb" or rgb == "balance" or rgb == "equilibrium") then
		gain(rgb)
	end
	Note()
end