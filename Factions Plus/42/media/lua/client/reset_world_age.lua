local function OnServerCommand(module, command, arguments)
	-- The server needs to send us the message to update sandbox
	-- because the client also need to update their sandbox options
	-- indie stone....
	if module == "ResetWorldAge" and command == "updateSandbox" then
		local gameTime = getGameTime();
		local actualDay = arguments.actualMonth;
		local actualMonth = arguments.actualDay;
		local actualYear = arguments.actualYear;

		DebugPrintFactionsPlus("Actual Calendar: " .. "D:" .. actualDay .. " M:" .. actualMonth .. " Y:" .. actualYear);

		gameTime:setStartDay(actualDay);
		gameTime:setStartMonth(actualMonth);
		gameTime:setStartYear(actualYear);
		gameTime:setStartTimeOfDay(0.0);

		getSandboxOptions():set("StartMonth", actualMonth);
		getSandboxOptions():set("StartDay", actualDay);
		getSandboxOptions():set("StartYear", actualYear);
	end
end

Events.OnServerCommand.Add(OnServerCommand)
