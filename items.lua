module(..., package.seeall)

require "json"
require "copytable"

inventory = {}
groupable = {}
pipes = json.decode(GetVariable("inventory_pipes") or "{}")
vials = json.decode(GetVariable("inventory_vials") or "{}")
arti_vials = json.decode(GetVariable("inventory_arti_vials") or "{}")
linked = json.decode(GetVariable("inventory_linked") or "{}")
rift = json.decode(GetVariable("inventory_rift") or "{}")

xlate_herb =
{
	["an arnica bud"] = "arnica",
	["a calamus root"] = "calamus",
	["a sprig of chervil"] = "chervil",
	["a plug of coltsfoot"] = "coltsfoot",
	["a piece of black earwort"] = "earwort",
	["a stalk of faeleaf"] = "faeleaf",
	["a stem of galingale"] = "galingale",
	["a horehound blossom"] = "horehound",
	["a kafe bean"] = "kafe",
	["kombu seaweed"] = "kombu",
	["a sprig of marjoram"] = "marjoram",
	["a piece of merbloom seaweed"] = "merbloom",
	["a bog myrtle leaf"] = "myrtle",
	["a bunch of pennyroyal"] = "pennyroyal",
	["a reishi mushroom"] = "reishi",
	["a wormwood stem"] = "wormwood",
	["a yarrow sprig"] = "yarrow",
}

xlate_potions = 
{
	["a potion of healing"] = "healing",
	["a potion of mana"] = "mana",
	["a potion of bromides"] = "bromides",
	["a potion of allheale"] = "allheale",
	["an antidote potion"] = "antidote",
	["a choleric purgative"] = "choleric",
	["a potion of fire"] = "fire",
	["a potion of frost"] = "frost",
	["a potion of galvanism"] = "galvanism",
	["a love potion"] = "love",
	["a melancholic purgative"] = "melancholic",
	["a melancholic purgativ"] = "melancholic", --Potionlist cutoff (linked)
	["a phlegmatic purgative"] = "phlegmatic",
	["a sanguine purgative"] = "sanguine",
	["elixir vitae"] = "vitae",
	["a mending salve"] = "mending",
	["a regeneration salve"] = "regeneration",
	["liniment salve"] = "liniment",
	["the poison aleutian"] = "aleutian",
	["the poison anatine"] = "anatine",
	["the poison anerod"] = "anerod",
	["the poison botulinum"] = "botulinum",
	["the poison calcise"] = "calcise",
	["the poison chansu"] = "chansu",
	["the poison charybdon"] = "charybdon",
	["the poison contortrin"] = "contortrin",
	["the poison crotamine"] = "crotamine",
	["the poison dendroxin"] = "dendroxin",
	["the poison dulak"] = "dulak",
	["the poison escozul"] = "escozul",
	["the poison hadrudin"] = "hadrudin",
	["the poison haemotox"] = "haemotox",
	["the poison ibululu"] = "ibululu",
	["the poison inyoka"] = "inyoka",
	["the poison mactans"] = "mactans",
	["the poison mantakaya"] = "mantakaya",
	["the poison mellitin"] = "mellitin",
	["the poison morphite"] = "morphite",
	["the poison niricol"] = "niricol",
	["the poison pyrotoxin"] = "pyrotoxin",
	["the poison saxitin"] = "saxitin",
	["the poison senso"] = "senso",
	["the poison tetrodin"] = "tetrodin",
	["dragonsblood oil"] = "dragonsblood",
	["jasmine oil"] = "jasmine",
	["sandalwood oil"] = "sandalwood",
	["vanilla oil"] = "vanilla",
	["absynthe"] = "absinthe",
	["cloudberry tea"] = "cloudberry",
	["black tea"] = "blacktea",
	["green tea"] = "greentea",
	["white tea"] = "whitetea",
	["oolong tea"] = "oolongtea",
	["pale beer"] = "palebeer",
	["amber beer"] = "amberbeer",
	["dark beer"] = "darkbeer",
	["oil of preservation"] = "preservation",
	["oil of sharpness"] = "sharpness",
	["musk oil"] = "musk",
	["oil of invisibility"] = "invisibility"	
}


function gmcp_received_char_items_list(name, line, wc)
	local dt = json.decode(wc[1])
	if (dt.location == "inv") then
		inventory = {}
		groupable = {}
		for _,i in pairs(dt.items) do
			inventory[i.id] = copytable.shallow(i)
			if i.attrib then
				if string.find(i.attrib, "g") then
					groupable[i.id] = i.name
				end
			end
		end
	end
end

function gmcp_received_char_items_add(name, line, wc)
	local dt = json.decode(wc[1])
	if (dt.location == "inv") then
		inventory[dt.item.id] = copytable.shallow(dt.item)
		if dt.item.attrib then 
			if string.find(dt.item.attrib, "g") then
				groupable[dt.item.id] = dt.item.name
			end
		end
	end
end

function gmcp_received_char_items_remove(name, line, wc)
	local dt = json.decode(wc[1])
	dt.item.id = tostring(dt.item.id)
	if inventory[dt.item.id] then
		groupable[dt.item.id] = nil
		inventory[dt.item.id] = nil
	end
end

function gmcp_received_ire_rift_list(name, line, wc)
	local dt = json.decode(wc[1])
	rift = {}
	for i in ipairs(dt) do
		local t = string.match(dt[i].desc, "(%w+)%: ")
		local q = tonumber(dt[i].amount)
		if (t == "liquid") then
			if linked[dt[i].name] then
				linked[dt[i].name].sips = q
			end
		else
			rift[dt[i].name] = q
		end
	end
end

function gmcp_received_ire_rift_change(name, line, wc)
	local dt = json.decode(wc[1])
	
	local p = Trim(string.gsub(dt.desc, "%w*%:", ""))
	local p, q = xlate_potions[p] or p, tonumber(dt.amount)

	if linked[p] then
		if vials[p] then
			for n,i in ipairs(vials[p]) do
				if (i.id == linked[p].id) then
					if (q > 0) then
						linked[p].sips = q
						vials[p][n].sips = linked[p].sips
					else
						table.remove(vials[p], n)
						local x = copytable.shallow(linked[p])
						linked[p] = nil
						local still_linked = false
						for _,l in pairs(linked) do
							if (l.id == x.id) then
								still_linked = true
								break
							end
						end
						if not still_linked then
							vials["empty"] = vials["empty"] or {}
							table.insert(vials["empty"], {id = x.id, x.name, sips = 0, x.months})
						end
					end
					break
				end
			end
		end
		return
	end
	rift[dt.name] = q
end

function herb_in_inventory(herb)
	if (herb == "sparkleberry") then
		herb = "sparkleberr"
	end
	
	for _,i in pairs(groupable) do
		if string.find(i, herb) then
			return true
		end
	end
	
	return false
end


--Potions and vials
function send_potionlist()
	Send("potionlist")
	acts.sent("potionlist")
end

function potionlist_start()
	if acts.sent_actions["potionlist"] then
		acts.completed("potionlist")
		EnableTrigger("items_assign_vial", true)
		vials = {}
		linked = {}
		events.prompt_add("potionlist_end",
		function()
			EnableTrigger("items_assign_vial", false)
		end)
	end
end

function assign_vial(name, line, wc)
	local id, conts, sips, months = wc[1], wc[2], tonumber(wc[3]), wc[4] 
	
	conts = xlate_potions[conts] or conts
	vials[conts] = vials[conts] or {}
	
	if (months == "*") then
		arti_vials[id] = true
		months = 9999
	else
		months = tonumber(months)
	end
	
	local nm
	if inventory[id] then
		nm = inventory[id].name
	--elseif bandolier[id] then
		--nm = bandolier[id].name
	end

	table.insert(vials[conts], {id = id, name = nm, sips = sips, months = months})
	
	if string.find(line , "%([a-z]+") then
		linked[conts] = {id = id, name = nm, sips = sips, months = months}
	end
end

function total_fluid(kind)
	if not vials[kind] then
		return 0
	end
	
	local amt = 0
	for _,i in ipairs (vials[kind]) do
		amt = amt + i.sips
	end
	
	return amt
end

function vial_count(kind)
	if not vials[kind] then
		return 0
	end
	
	local count = 0
	for _,n in pairs(vials[kind]) do
		count = count + 1
	end

	return count
end

function vial_max(id)
	if arti_vials[id] then
		return 110
	end
	
	return 60
end

function decrement_vial(fluid, name, emptied)
	if not vials[fluid] or (vials[fluid] and #vials[fluid] < 1) then
		ui.err("Check POTIONLIST!")
		return
	end
	
	if linked[fluid] then
		if not linked[fluid].id then
			ui.err("Check POTIONLIST!")
		end
		--ui.debug_message("Linked: "..fluid)
		return
	end
	
	local pos = 1
	if name then
		if (vials[fluid][1].name ~= name) then
			for i,t in ipairs(vials[fluid]) do
				if (t.name == name) then
					pos = i
					break
				end
			end
			if (pos == 1) then
				ui.err("Check POTIONLIST!")
			end
		end
	end
	
	vials["empty"] = vials["empty"] or {}
	
	if vials[fluid][pos] then
		if not emptied then
			vials[fluid][pos].sips = vials[fluid][pos].sips - 1
			if (vials[fluid][pos].sips < 1) then
				emptied = true
			end
		end
		
		--ui.debug_message("emptied: "..tostring(emptied).." pos: "..pos.." "..fluid)
		if emptied then
			table.insert(vials["empty"], 
			{id = vials[fluid][pos].id, name = vials[fluid][pos].name, sips = 0, months = vials[fluid][pos].months})
			table.remove(vials[fluid], pos)
		end
	end
end