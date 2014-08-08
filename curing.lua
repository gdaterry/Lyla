module(..., package.seeall)

last_cured = {}

local cure_map =
{
	["auditory"] = "eat earwort",
	["addiction"] = "eat galingale",
	["aura"] = "eat reishi",
	["delusions"] = "eat pennyroyal",
	["ocular"] = "eat faeleaf",
	["skin"] = "eat arnica",
	["musculature"] = "eat yarrow",
	["nerves"] = "eat kombu",
	
	["bleeding"] = "sip sanguine",
	
	["health_curse"] = "sip phlegmatic",
	["mana_curse"] = "sip phlegmatic",
	["ego_curse"] = "sip phlegmatic",
	
	["magical_damage_malus"] = "sip melancholic",
}

local herb_queue =
{
	{"aura", 5}, --Peace
	{"aura", 4}, --Aeon
	{"aura", 3}, --Jinx
	
	{"musculature", 5},
	{"musculature", 4},
	{"musculature", 3},
	{"musculature", 2},
	{"musculature", 1}, --Recklessness
	
	{"auditory", 5},
	{"auditory", 4},
	
	{"auditory", 3},
	
	{"aura", 2}, -- Justice
	{"aura", 1}, -- Leaky aura
	
	{"auditory", 2},
	
	{"addiction", 5},
	{"addiction", 4},
	{"addiction", 3},
	{"addiction", 2},
	{"addiction", 1},
	
	{"nerves", 5},
	{"nerves", 4},
	{"nerves", 3},
	{"nerves", 2},
	{"nerves", 1},
	
	{"skin", 5},
	{"skin", 4},
	{"skin", 3},
	{"skin", 2},
	{"skin", 1},
	
	{"delusions", 5},
	{"delusions", 4},
	{"delusions", 3},
	{"delusions", 2},
	{"delusions", 1},
	
	{"ocular", 5},
	{"ocular", 4},
	{"ocular", 3},
	{"ocular", 2},
	
	{"auditory", 1},
	
	{"ocular", 1},
}

local purgative_queue =
{
	{"bleeding", 5},
	{"bleeding", 4},
	{"bleeding", 3},
	{"bleeding", 2},
	{"bleeding", 1},
	
	{"magical_damage_malus", 5},
	{"magical_damage_malus", 4},
	{"magical_damage_malus", 3},
	{"magical_damage_malus", 2},
	{"magical_damage_malus", 1},
	
	{"health_curse", 5},
	{"health_curse", 4},
	{"health_curse", 3},
	{"health_curse", 2},
	{"health_curse", 1},
	
	{"mana_curse", 5},
	{"mana_curse", 4},
	{"mana_curse", 3},
	{"mana_curse", 2},
	{"mana_curse", 1},
	
	{"ego_curse", 5},
	{"ego_curse", 4},
	{"ego_curse", 3},
	{"ego_curse", 2},
	{"ego_curse", 1},
}

local function evaluate_queue(queue)
	for _,a in ipairs(queue) do
		--a[1] is the name of the affliction to be cured. a[2] is the level being referred to. a[3] is a condition to be filled. Must be a function. Can be blank.
		if (affs.get(a[1]) and (affs.get_level(a[1]) == (a[2] or 1)) and 
		   ((a[3] and a[3]()) or (a[3] == nil))) 
		then
			if acts.can(cure_map[a[1]], a[1]) then
				acts.exec(cure_map[a[1]])
				ui.system("Attempting to cure your "..a[1].." affliction with '"..cure_map[a[1]].."'.")
				break
			end
		end
	end
end

function routine()
	evaluate_queue(herb_queue)
	if not (affs.get_level("aura") >= 4) then
		evaluate_queue(purgative_queue)
		if affs.get("entangled") and acts.can("writhe") then
			acts.exec("writhe")
			ui.system("Attempting to writhe your entanglement.")
		end
	end
end