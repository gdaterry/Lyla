module(..., package.seeall) 

current = {}
local fna = {}
local fnc = {}

function get(def)
	return current[def] or false
end

function add(def, params)
	current[def] = params or true
end

function clear(def)
	current[def] = nil
end

function handle(name, line, wc)
	local a,d = string.match(name, "^defs%_(%w+)%_([a-z%d%_]+)$")
	local def = string.gsub(d, "%d+", "")
	
	if (a == "add") then
		if fna[d] then
			fna[d](name, line, wc)
		else
			add(def)
		end
	else
		if fnc[d] then
			fnc[d](name, line, wc)
		else
			clear(def)
		end
	end
end

--Handler functions.

function fna.sixthsense()
	events.failsafe_add("def_sixthsense_coming",
	function()
		add("sixthsense")
	end, 7)
end

function fna.sixthsense2()
	events.failsafe_clear("def_sixthsense_coming")
	add("sixthsense")
end