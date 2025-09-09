if not getSandboxOptions():getOptionByName("FactionsPlus.EnableFastSleep"):getValue() then return end

function CheckSleep()
	local player = getPlayer()
	if player:isAsleep() then
		local newFatigue = player:getStats():getFatigue() -
			(getSandboxOptions():getOptionByName("FactionsPlus.SleepFatigueReducer"):getValue() / 100);
		local newEndurance = player:getStats():getEndurance() +
			(getSandboxOptions():getOptionByName("FactionsPlus.SleepEnduranceReceive"):getValue() / 100);
		player:getStats():setFatigue(math.max(0, newFatigue))
		player:getStats():setEndurance(math.min(1, newEndurance))
		if player:getStats():getFatigue() <= 0 then
			player:forceAwake();
		end
	end
end

Events.OnChatWindowInit.Add(function()
	Events.EveryOneMinute.Add(CheckSleep)
end)
