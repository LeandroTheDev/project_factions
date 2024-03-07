---@diagnostic disable: undefined-global, duplicate-set-field

-- Check if feature is enabled
if SandboxVars.FactionsPlus.EnableWaterLightCycle then
	-- Variable to handle the print to the server
	-- the existence is simple not spam the day check water
	-- only when the check is changed
	local printerHandler = "on";

	Events.EveryHours.Add(function()
		local currentTime = GetCurrentTime(SandboxVars.FactionsPlus.Timezone);
		local function enable()
			-- Turn on water, light
			getSandboxOptions():set("ElecShutModifier", 2147483647);
			getSandboxOptions():set("WaterShutModifier", 2147483647);
			sendServerCommand(player, "ServerSafehouse", "updateSandbox", { electricityOn = true });
			if printerHandler ~= "off" then
				print('[Factions] Day Check Water, Lights on: ' .. currentTime.tm_wday);
				printerHandler = "off";
			end
		end
		local function disable()
			-- Turn off water, light
			getSandboxOptions():set("ElecShutModifier", -1);
			getSandboxOptions():set("WaterShutModifier", -1);
			sendServerCommand(player, "ServerSafehouse", "updateSandbox", { electricityOff = true });
			if printerHandler ~= "on" then
				print('[Factions] Day Check Water, Lights off: ' .. currentTime.tm_wday);
				printerHandler = "on";
			end
		end
		local stringDays = FactionsPlus.WaterLightCycle;
		-- Swipe the days into a variable
		for day in string.gmatch(stringDays, "%d+") do
			-- Get the day number
			local dayNumber = tonumber(day)
			-- Check if the dayNumber is equals the today number
			if dayNumber == currentTime.tm_wday then enable() -- Enable if is
			else disable() end  -- Disable if not
		end
	end);
end
