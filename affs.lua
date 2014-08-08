module(..., package.seeall)

require "copytable"

queue = {}
current = {}


function get(aff)
	--Returns tabular information on an affliction or false if you don't have it.
	if current[aff] then
		return current[aff]
	end
	
	return false
end

function add(aff, level, param)
	--This is meant for manually adding afflictions in through context clues.
	current[aff] = {level = level or 1, param = param}
end

function get_level(aff)
	--Returns the current level of an affliction. If you don't have it, it returns 0.
	if current[aff] then
		return current[aff].level
	end
	
	return 0
end


function is_prone()
	--returns whether or not you are prone.
	return (core.vitals.prone > 0)
end


local xlate_aff = 
{
	--Auditory
	["deafness"] = {aff = "auditory", level = 1},
	["earache"] = {aff = "auditory", level = 2},
	["tinnitis"] = {aff = "auditory", level = 3},
	["hyperacusis"] = {aff = "auditory", level = 4},
	["echoes"] = {aff = "auditory", level = 5},
	
	--Aura
	["leaky_aura"] = {aff = "aura", level = 1},
	["justice_curse"] = {aff = "aura", level = 2},
	["jinx_curse"] = {aff = "aura", level = 3},
	["aeon_curse"] = {aff = "aura", level = 4},
	["peace_curse"] = {aff = "aura", level = 5},
	
	--Bleeding
	["mild_bleeding"] = {aff = "bleeding", level = 1},
	["light_bleeding"] = {aff = "bleeding", level = 2},
	["moderate_bleeding"] = {aff = "bleeding", level = 3},
	["severe_bleeding"] = {aff = "bleeding", level = 4},
	["critical_bleeding"] = {aff = "bleeding", level = 5},
	
	--Health Curse
	["minor_health_curse"] = {aff = "health_curse", level = 1},
	["moderate_health_curse"] = {aff = "health_curse", level = 2},
	["major_health_curse"] = {aff = "health_curse", level = 3},
	
	--Mana Curse
	["minor_mana_curse"] = {aff = "mana_curse", level = 1},
	["moderate_mana_curse"] = {aff = "mana_curse", level = 2},
	["major_mana_curse"] = {aff = "mana_curse", level = 3},
	
	--Ego Curse
	["minor_ego_curse"] = {aff = "ego_curse", level = 1},
	["moderate_ego_curse"] = {aff = "ego_curse", level = 2},
	["major_ego_curse"] = {aff = "ego_curse", level = 3},
	
	--Delusions
	["confusion"] = {aff = "delusions", level = 1},
	["dementia"] = {aff = "delusions", level = 2},
	["delirium"] = {aff = "delusions", level = 3},
	["hallucinations"] = {aff = "delusions", level = 4},
	["amnesia"] = {aff = "delusions", level = 5},
	
	--Entanglement
	["entanglement"] = {aff = "entangled", level = 1},
	
	--Magical Damage Malus
	["minor_magical_damage_malus"] = {aff = "magical_damage_malus", level = 1},
	["moderate_magical_damage_malus"] = {aff = "magical_damage_malus", level = 2},
	["major_magical_damage_malus"] = {aff = "magical_damage_malus", level = 3},
	
	--Musculature
	["recklessness"] = {aff = "musculature", level = 1},
	["leg_cramps"] = {aff = "musculature", level = 2},
	["twitches"] = {aff = "musculature", level = 3},
	["spasms"] = {aff = "musculature", level = 4},
	["wasted_muscles"] = {aff = "musculature", level = 5},
	
	--Nerves
	["vapors"] = {aff = "nerves", level = 1},
	["dizziness"] = {aff = "nerves", level = 2},
	["clumsiness"] = {aff = "nerves", level = 3},
	["epilepsy"] = {aff = "nerves", level = 4},
	["slickness"] = {aff = "nerves", level = 5},
	
	--Ocular
	["blindness"] = {aff = "ocular", level = 1},
	["photosensitivity"] = {aff = "ocular", level = 2},
	["double_vision"] = {aff = "ocular", level = 3},
	["blurred_vision"] = {aff = "ocular", level = 4},
	["cataracts"] = {aff = "ocular", level = 5},
	
	--Skin
	["scabies"] = {aff = "skin", level = 1},
	["lesions"] = {aff = "skin", level = 2},
	["pox"] = {aff = "skin", level = 3},
	["sun_allergy"] = {aff = "skin", level = 4},
	["rigormortis"] = {aff = "skin", level = 5},
	
	--Addiction
	["gluttony"] = {aff = "addiction", level = 1},
	["dipsomania"] = {aff = "addiction", level = 2},
	["intemperance"] = {aff = "addiction", level = 3},
	["debauchery"] = {aff = "addiction", level = 4},
	["addiction"] = {aff = "addiction", level = 5},
}


function received_affliction(name, line, wc)
	local aff = string.gsub(wc[1], "%s+", "_")
	if xlate_aff[aff] then
		current[xlate_aff[aff].aff] = current[xlate_aff[aff].aff] or {}
		current[xlate_aff[aff].aff].level = xlate_aff[aff].level
		ui.system("Tracked affliction: "..xlate_aff[aff].aff.." level "..xlate_aff[aff].level..".")
	end
end

function lowered_affliction(name, line, wc)
	local aff = string.gsub(wc[1], "%s+", "_")
	local new_aff = string.gsub(wc[2], "%s+", "_")
	if xlate_aff[new_aff] then
		current[aff] = current[aff] or {}
		current[aff].level = xlate_aff[new_aff].level
	end
	table.insert(curing.last_cured, aff)
end

function clear_affliction(name, line, wc)
	local aff = string.gsub(wc[1], "%s+", "_")
	current[aff] = nil
	if (aff == "entanglement") then
		events.failsafe_clear("writhing")
	end
	table.insert(curing.last_cured, aff)
end


--Ignore these for now.
local affliction_categories =
{
}

function no_affliction_category(name, line, wc)
	local aff = string.gsub(wc[1], "%s+", "_")
	if aff_categories[aff] then
		for _,i in ipairs(aff_categories[aff]) do
			current[i] = nil
		end
	else
		current[aff] = nil
	end
end





function routine()
	for a,p in ipairs(queue) do
		current[a] = copytable.shallow(p)
	end
end