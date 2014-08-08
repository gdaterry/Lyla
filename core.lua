module(..., package.seeall)

require "ui"
require "copytable"
require "tprint"
require "events"
require "acts"
require "affs"
require "items"
require "balances"
require "curing"
require "defs"

version = 1.01
vitals = {}
setmetatable(vitals, {__index = function() return 0 end})
local core_plugin = "ee3d5d821778595edca2c612"
paused = false


local xml_files =
{
	"acts",
	"affs",
	"balances",
	"core",
	"defs",
	"items",
}

local system_groups =
{
	"Actions",
	"Afflictions",
	"Balances",
	"Core",
	"Defences",
	"Events",
	"GMCP",
	"Items",
}

--Say hello, Lyla.
events.prompt_add("greeting_message",
function()
	ui.system("Greetings! I, Lyla, have been successfully booted up. My current version is "..string.format("%.2f", version)..".")
end)


--Trigger and plugin loading functions.
if not IsPluginInstalled(core_plugin) then
	ui.system("The core plugin was not found to be loaded. Attempting to load it now...")
	local result = LoadPlugin("core_plugin.xml")
	if (result == 0) then
		ui.system("The core plugin has been successfully installed.")
	elseif (result == 30030) then
		ui.err("The core plugin could not be found in the local folder. Ensure that 'core_plugin.xml' has been properly downloaded.")
	else
		ui.err("There seems to be a problem with the plugin. It may be corrupt or my maker made a grave mistake before giving me to you! Please try redownloading it first.")
	end
end


function load(custom)
	local t, imp, count = copytable.shallow(xml_files), {}, 0
	
	--As an optional parameter, you can specific the names of your own XML files for input.
	if custom then
		if (type(custom) == "table") then
			for _,i in ipairs(custom) do
				table.insert(t, i)
			end
		else
			table.insert(t, custom)
		end
	end
	
	for _,i in ipairs(t) do
		io.input(i..".xml")
		table.insert(imp, io.read("*all"))
		io.close()
	end
	
	--First unload all the previous system triggers and aliases.
	local count = 0
	for _,i in ipairs(system_groups) do
		count = count + DeleteGroup(i)
	end
	ui.system(count.." installed items (triggers, aliases and timers) have been removed.")
	
	--Now load the new ones.
	local count = 0
	count = ImportXML(table.concat(imp, "\n"))
	ui.system(count.." items (triggers, aliases and timers) have been successfully loaded.")
	ReloadPlugin(core_plugin)
	
	
	ui.system("Reloading script file. This may take a moment...")
	Note()
	DoCommand("ReloadScriptFile")
	if IsConnected() then SendNoEcho() end
end


--System pausing and unpausing.
function toggle_pause(name, line, wc)
	if (wc[1] == "pause") then
		SetVariable("paused", 1)
		ui.system("Most of my functions have now been paused.")
	else
		SetVariable("paused", 0)
		ui.system("The majority of my functions have now been unpaused.")
	end
	if IsConnected() then SendNoEcho() end
end

function is_paused()
	if not GetVariable("paused") then
		SetVariable("paused", "0")
	elseif (GetVariable("paused") == "1") then
		return true
	end
	
	return false
end


--Timestamp handler function.
function time_stamp_difference(name, line, wc)
	wc[1] = tonumber(wc[1])
	if not time_stamp then
		time_stamp = wc[1]
		events.failsafe_add("timestamp_timeout",
		function()
			time_stamp = nil
		end, 25)
	else
		ui.prefix()
		ColourNote("silver", "", "The time difference was ", "gold", "", math.abs(string.format("%.2f", (wc[1] - time_stamp))).." seconds", "silver", "", ". You are most welcome!")
		time_stamp = nil
		events.failsafe_clear("timestamp_timeout")
		if IsConnected() then SendNoEcho() end
	end
end


--Convenience Math Solver
function calculate_math(name, line, wc)
	local env = setmetatable({}, {__index = function(_,m) return (math[m] or bit[m] or string[m] or utils[m]) end})
	ui.prefix()
	ColourNote("silver", "", "Your request, ", "yellow", "", wc[1], "silver", "", ", calculates to ", "yellow", "", setfenv(assert(loadstring("return "..wc[1])), env)(), "silver", "", ". Don't you love a woman with brains?")
	if IsConnected() then SendNoEcho() end
end