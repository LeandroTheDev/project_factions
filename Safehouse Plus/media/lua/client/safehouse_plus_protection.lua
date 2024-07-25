---@diagnostic disable: undefined-global, cast-local-type
-- Check if this feature is enabled
if not SandboxVars.SafehousePlus.EnableSafehouseProtection then return end

-- Handle the server side
local function OnServerCommand(module, command, arguments)
	if module == "ServerSafehouseProtection" and command == "safehouseProtected" then
		-- Success message
		getPlayer():Say(getText("IGUI_Safehouse_Protected"));
	end
	if module == "ServerSafehouseProtection" and command == "notOwner" then
		-- Error message
		getPlayer():Say(getText("IGUI_Safehouse_Protected_Not_Owner"));
	end
	if module == "ServerSafehouseProtection" and command == "notBelongs" then
		-- Error message
		getPlayer():Say(getText("IGUI_Safehouse_Protected_Invalid"));
	end
end
Events.OnServerCommand.Add(OnServerCommand)
