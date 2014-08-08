module(..., package.seeall)

gag_this_prompt = false

function prefix()
	--The prefix used before messages.
	ColourTell("gold", "", "(", "palegoldenrod", "", "Lyla", "gold", "", "): ")
end

function system(msg)
	--Most common system messages.
	prefix()
	ColourNote("silver", "", msg)
end

function err(msg)
	--When Lyla needs to tell you something went wrong.
	prefix()
	ColourNote("indianred", "", msg)
end

function debug_message(msg)
	ColourNote("indianred", "", "[Debug]: "..msg)
end


function gag_prompt()
	--Call this function to gag the prompt.
	gag_this_prompt = true
end


function percent_colour(pct, desaturated)
	--Returns a colour value from green, to yellow to red, based on a given percentage.
	local dsat =
	{
		["green"] = "yellowgreen",
		["red"] = "indianred",
		["yellow"] = "khaki",
	}
	
	local colour = "green"
	
	if (pct < 0.5) then
		colour = "red"
	elseif (pct < 0.75) then
		colour = "yellow"
	end
	
	if desaturated then
		colour = dsat[colour]
	end
	
	return colour
end


local function timestamp_prefix()
	--Draws a clickable timestamp for you. Click any two timestamps and it gives you the difference.
	local time_ms = GetInfo(232) 
	ColourTell("silver", "", "[")
	Hyperlink("time_stamp_difference "..time_ms, string.format("%0.2f", time_ms), "Click to get difference.", "lightslategray", "", 0)
	ColourTell("silver", "", "|")
end

local function draw_prompt_stat(stat)
	--Draws the specific stat, adjacent to its percentage.
	local stat_letter =
	{
		["hp"] = "h",
		["mp"] = "m",
		["ep"] = "e",
	}
	local c, dc = percent_colour(core.vitals[stat.."_pct"]), percent_colour(core.vitals[stat.."_pct"], true)
	ColourTell(c, "", (math.ceil(core.vitals[stat.."_pct"] * 100)).."%"..stat_letter[stat], "gray", "", "(", "gray", "", core.vitals[stat], "silver", "", ")")
end
	
local function draw_stat_differences()
	--Notes any changes in your vitals.
	local note = false
	for _,s in ipairs{"hp", "mp", "ep"} do
		local c = "yellowgreen"
		local diff = core.vitals[s] - core.vitals["prev_"..s]
		if (diff > 0) then
			note = true
			ColourTell(c, "", "(+"..diff..s..")")
		elseif (diff < 0) then
			note = true
			c = "indianred"
			ColourTell(c, "", "("..diff..s..")")
		end
	end
	Note()
end

local function draw_prompt_notes()
	--Places notes on the prompt for your benefit.
	if core.is_paused() then
		ColourTell("red", "", "(paused)")
	end
	if (affs.get_level("aura") >= 4) then
		ColourTell("purple", "", "(slow)")
	end
end

function draw_prompt(flags)
	if not gag_this_prompt then
		--The flag colour will appear yellow or silver, depending on whether or not you can move freely.
		local flag_colour = "yellow"
		if (not balances.full() or affs.is_prone()) then
			flag_colour = "silver"
		end
		--Draw the timestamp.
		timestamp_prefix()
		--Health
		draw_prompt_stat("hp")
		ColourTell("silver", "", "|")
		--Mana
		draw_prompt_stat("mp")
		ColourTell("silver", "", "|")
		--Ego
		draw_prompt_stat("ep")
		ColourTell("silver", "", "|")
		--Power
		ColourTell(percent_colour(core.vitals.pow/10), "", core.vitals.pow.."p")
		ColourTell("silver", "", "] ")
		ColourTell(flag_colour, "", flags.."- ")
		--Trailing notes.
		draw_prompt_notes()
		draw_stat_differences()
		if (#curing.last_cured > 0) then
			ColourNote("white", "", "Cured: "..table.concat(curing.last_cured, ", "))
		end
	end
	gag_this_prompt = false
end


function draw_blackout_prompt()
	if not gag_this_prompt then
		timestamp_prefix()
		ColourTell("steelblue", "", "Blackout")
		ColourTell("silver", "", "]- ")
		draw_prompt_notes()
		Note()
	end
	gag_this_prompt = false
end