---@diagnostic disable: undefined-global

local AddTradeUI = ISPanel:derive("AddTradeUI")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_SCALE = FONT_HGT_SMALL / 14

-- -- Função para verificar se duas tabelas são iguais -thanks chatGPT
-- local function tabelaIdentica(tabela1, tabela2)
--   -- Verificar se as tabelas têm o mesmo número de pares chave-valor
--   if #tabela1 ~= #tabela2 then
--     return false
--   end

--   -- Verificar cada par chave-valor em ambas as tabelas
--   for chave, valor in pairs(tabela1) do
--     if tabela2[chave] ~= valor then
--       return false
--     end
--   end

--   return true
-- end

function AddTradeUI:initialise()
  ISPanel.initialise(self)
  self:create()
end

function AddTradeUI:setVisible(visible)
  self.javaObject:setVisible(visible)
end

function AddTradeUI:render()
  local z = 15 * FONT_SCALE

  z = z + FONT_HGT_SMALL + 2 * FONT_SCALE * FONT_SCALE
  self:drawText(getText("IGUI_Trade_Items"), self:getWidth() * 0.025, z, 1, 1, 1, 1, UIFont.Medium)
end

local function OnServerCommand(module, command, arguments)
  Events.OnServerCommand.Remove(OnServerCommand)
end

function AddTradeUI:create()
  --Variable Declarations
  local btnWid = 125 * FONT_SCALE
  local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
  local padBottom = 10 * FONT_SCALE

  local z = 15 * FONT_SCALE + FONT_HGT_SMALL + 2 * FONT_SCALE
  local inset = 2
  local height = inset + FONT_HGT_SMALL + inset

  z = z + height + 10 * FONT_SCALE + FONT_HGT_SMALL + 2 * FONT_SCALE
  height = inset + 6 * FONT_HGT_SMALL + inset

  height = self:getHeight() - z - padBottom - btnHgt - 10 * FONT_SCALE
  --Items List
  self.itemList = ISScrollingListBox:new(padBottom, z, self:getWidth() - padBottom * 2, height)
  self.itemList:initialise()
  self.itemList:instantiate()
  self.itemList.font = UIFont.Medium;
  self.itemList.itemPadY = 5 * FONT_SCALE
  self.itemList.itemheight = FONT_HGT_MEDIUM + 5 * FONT_SCALE * 2
  self.itemList.texturePadY = (self.itemList.itemheight - FONT_HGT_MEDIUM) / 2
  self.itemList.doDrawItem = self.doDrawItem
  self.itemList.onMouseWheel = function(self, del)
    if not self:isVScrollBarVisible() then return true end
    local yScroll = self.smoothScrollTargetY or self:getYScroll()
    local topRow = self:rowAt(0, -yScroll)
    if self.items[topRow] then
      if not self.smoothScrollTargetY then self.smoothScrollY = self:getYScroll() end
      local y = self:topOfItem(topRow)
      if del < 0 then
        if yScroll == -y and topRow > 1 then
          local prev = self:prevVisibleIndex(topRow)
          y = self:topOfItem(prev)
        end
        self.smoothScrollTargetY = -y
      else
        self.smoothScrollTargetY = -(y + self.items[topRow].height)
      end
    else
      self:setYScroll(self:getYScroll() - (del * 18))
    end
    return true
  end
  self.itemList.setYScroll = function(self, y)
    ISUIElement.setYScroll(self, y)
    y = self.smoothScrollY or y
    local topRow = self:rowAt(0, -y + self.itemheight - (self.itemheight - FONT_HGT_SMALL - 4) / 2)
    local bottomRow = self:rowAt(0, self:getHeight() - y - self.itemheight + (self.itemheight - FONT_HGT_SMALL - 4) / 2)
    if bottomRow == -1 then bottomRow = #self.items end
    for i, v in ipairs(self.items) do
      if (i < topRow) or (i > bottomRow) then
        v.priceEntry:setVisible(false)
        y = y + self.itemheight
      else
        v.priceEntry:setY(y + (self.itemheight - FONT_HGT_SMALL - 4) / 2)
        v.priceEntry:setVisible(true)
        y = y + self.itemheight
      end
    end
  end
  self.itemList.drawBorder = true
  self:addChild(self.itemList)
  self.itemList.itemPrices = {}
  local items = self.container:getItems()
  local alreadyAdded = {}
  for i = 0, items:size() - 1 do
    local item = items:get(i)
    --Verifica se o item ja existe
    local continue = true;
    for j = 0, items:size() - 1 do
      if item:getType() == alreadyAdded[j] then
        continue = false
        break;
      end
    end
    if continue then
      table.insert(alreadyAdded, item:getType())
      self.itemList.itemPrices[item:getType()] = "0"
      local row = self.itemList:addItem(item:getDisplayName(), item)
      row.priceEntry = ISTextEntryBox:new("0", self.itemList:getWidth() - 75 - self.itemList.vscroll.width, 0, 70,
        inset + FONT_HGT_SMALL + inset)
      row.priceEntry:initialise()
      row.priceEntry:instantiate()
      row.priceEntry:setMaxTextLength(3)
      row.priceEntry:setOnlyNumbers(true)
      self.itemList:addChild(row.priceEntry)
    end
  end
  self.itemList:setYScroll(0)
  Events.OnServerCommand.Add(OnServerCommand)

  --Send Button
  z = z + height + 10 * FONT_SCALE
  self.save = ISButton:new(padBottom, z, btnWid, btnHgt, getText("IGUI_Trade_Send"), self,
    AddTradeUI.onOptionMouseDown)
  self.save.internal = "SAVE"
  self.save:initialise()
  self.save:instantiate()
  self.save.borderColor = self.buttonBorderColor
  self:addChild(self.save)

  --Cancel Button
  self.cancel = ISButton:new(self:getWidth() - btnWid - padBottom, z, btnWid, btnHgt, getText("UI_btn_close"), self,
    AddTradeUI.onOptionMouseDown)
  self.cancel.internal = "CANCEL"
  self.cancel:initialise()
  self.cancel:instantiate()
  self.cancel.borderColor = self.buttonBorderColor
  self:addChild(self.cancel)
end

function AddTradeUI:doDrawItem(y, item, alt)
  self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor
    .b)
  self:drawTextureScaledAspect2(item.item:getTexture(), 5, y + self.texturePadY, FONT_HGT_MEDIUM, FONT_HGT_MEDIUM, 1, 1,
    1, 1)
  self:drawText(item.text .. " (" .. self.parent.container:getCountType(item.item:getType()) .. ")", 10 + FONT_HGT_MEDIUM,
    y + self.itemPadY, 0.7, 0.7, 0.7, 1.0, self.font)

  y = y + item.height
  return y
end

function AddTradeUI:onOptionMouseDown(button, x, y)
  if button.internal == "CANCEL" then
    self:close()
  elseif button.internal == "SAVE" then
    self.shop:transmitModData();
    local sendItems = {};
    --Varredura dos itens
    for i, v in ipairs(self.itemList.items) do
      if v.priceEntry:getText() ~= "0" then
        --Declaração do item
        local selectedItem = {
          type = "ITEM",
          target = v.item:getFullType(),
          quantity = 1,
          price = v.priceEntry:getText(),
          category = v.item:getCategory(),
          condition = v.item:getCondition(),
          maxcondition = v.item:getConditionMax(),
          repaired = v.item:getHaveBeenRepaired(),
          isbroken = v.item:isBroken()
        }
        --Remove do Container
        local container = v.item:getContainer();
        container:removeItemOnServer(v.item);
        local result = container:removeItemWithID(v.item:getID());
        --Verifica se foi possivel excluir o item
        if result then
          --Adiciona item na tabela de itens a serem enviados
          table.insert(sendItems, selectedItem);
        end
      end
    end
    --Envia um por um para o servidor // Pode afetar a performance? sim com certeza é melhor futuramente fazer um sistema diferente no server-side
    for i, v in ipairs(sendItems) do
      sendClientCommand("ServerPoints", "addTrade", { v, nil })
    end
    self:close()
  end
end

function AddTradeUI:close()
  self:setVisible(false)
  self:removeFromUIManager()
  AddTradeUI.instance = nil
end

function AddTradeUI:new(x, y, width, height, shop, shopData)
  local o = {}
  o = ISPanel:new(x, y, width, height)
  setmetatable(o, self)
  self.__index = self
  o.variableColor = { r = 0.9, g = 0.55, b = 0.1, a = 1 }
  o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
  o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
  o.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
  o.moveWithMouse = true
  o.shop = shop
  o.container = shop:getContainer()
  o.shopData = shopData
  AddTradeUI.instance = o
  return o
end

return AddTradeUI
