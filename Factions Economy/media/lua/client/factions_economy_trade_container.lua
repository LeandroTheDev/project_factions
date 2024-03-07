---@diagnostic disable: undefined-global
local TradeUI = require "factions_economy_trade_add_ui"
local UI_SCALE = getTextManager():getFontHeight(UIFont.Small)/14

local function onEditTrade(trade, tradeData)
  local tradeMenu = TradeUI:new((getCore():getScreenWidth() - 400 * UI_SCALE)/2, (getCore():getScreenHeight() - 600 * UI_SCALE)/2, 400 * UI_SCALE, 600 * UI_SCALE, trade, tradeData)
  tradeMenu:initialise()
  tradeMenu:addToUIManager()
end

local function onCreateShop(object, player)
  local square = object:getSquare()
  square:transmitRemoveItemFromSquare(object)
  local properties = object:getProperties()
  local newObject = IsoThumpable.new(object:getCell(), square, object:getSprite():getName(), properties:Is("collideN"), nil)
  newObject:setCanBeLockByPadlock(true)
  newObject:setBlockAllTheSquare(properties:Is("collideN") and properties:Is("collideW"))
  newObject:setIsThumpable(properties:Is("collideN") or properties:Is("collideW"))
  newObject:setThumpDmg(0)
  newObject:setContainer(object:getContainer())
  for i = 1, object:getContainerCount() - 1 do
    newObject:addSecondaryContainer(object:getContainerByIndex(i))
  end
  local tradeData = {}
  tradeData.owner = player:getUsername()
  tradeData.name = player:getUsername() .. "'s Shop"
  newObject:getModData()["tradeData"] = tradeData
  square:AddSpecialObject(newObject)
  newObject:transmitCompleteItemToServer()
  player:getInventory():Remove("TradeOutpost")
end

local function OnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
  local playerObj = getSpecificPlayer(player)
  local hasLedger = playerObj:getInventory():containsType("TradeOutpost")
  for i, v in ipairs(worldObjects) do
    if v:getContainerCount() > 0 then
      local tradeData = v:getModData()["tradeData"]
      if tradeData then
        -- Edit store button
        context:addOption(getText("IGUI_Add_Trade_Items"), v, onEditTrade, tradeData)
        break
      elseif hasLedger then
        -- Convert to shop button
        context:addOption(getText("IGUI_Container_Convert"), v, onCreateShop, playerObj)
        break
      end
    end
  end
end

Events.OnPreFillWorldObjectContextMenu.Add(OnPreFillWorldObjectContextMenu)
