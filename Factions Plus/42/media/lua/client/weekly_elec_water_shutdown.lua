local function OnServerCommand(module, command, arguments)
	-- The server needs to send us the message to update sandbox
	-- because the client also need to update their sandbox options
	-- indie stone....
	if module == "ServerSafehouse" and command == "updateSandbox" then
		if arguments.electricityOn then
			getSandboxOptions():set("ElecShutModifier", 2147483647);
			getSandboxOptions():set("WaterShutModifier", 2147483647);
		elseif arguments.electricityOff then
			getSandboxOptions():set("ElecShutModifier", -1);
			getSandboxOptions():set("WaterShutModifier", -1);
		end
	end
end

Events.OnServerCommand.Add(OnServerCommand)
