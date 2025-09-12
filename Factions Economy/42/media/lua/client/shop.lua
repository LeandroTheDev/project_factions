local isSingleplayer = (not isClient() and not isServer());

ISShop = ISPanel:derive("ISShop")
ISShop.BuyType = {}
ISShop.DrawType = {}
ISShop.LoadType = {}
ISShop.PreviewType = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14

--#region Server Functions

local function ReceiveCurrency(module, command, arguments)
    if module == "FactionsEconomyCurrency" and command == "receiveCurrency" then
        ISShop.instance.currency = arguments[1]
        Events.OnServerCommand.Remove(ReceiveCurrency);

        DebugPrintFactionsEconomy("Currency updated: " .. ISShop.instance.currency);
    end
end

local function ReceiveShopItems(module, command, arguments)
    if module == "FactionsEconomyShop" and command == "receiveShopItems" then
        Events.OnServerCommand.Remove(ReceiveShopItems)

        DebugPrintFactionsEconomy("Shop items received!");

        for k, v in pairs(arguments) do
            DebugPrintFactionsEconomy("Iterating: " .. k);
            local scrollingList = ISScrollingListBox:new(1, 0, ISShop.instance.tabPanel.width - 2,
                ISShop.instance.tabPanel.height - ISShop.instance.tabPanel.tabHeight)
            scrollingList.itemPadY = 10 * FONT_SCALE
            scrollingList.itemheight = FONT_HGT_LARGE + scrollingList.itemPadY * 2 + 1 * FONT_SCALE + FONT_HGT_SMALL
            scrollingList.textureHeight = scrollingList.itemheight - scrollingList.itemPadY * 2
            scrollingList.mouseoverselected = -1
            scrollingList:initialise()
            scrollingList.doDrawItem = ISShop.doDrawItem
            ISShop.instance.tabPanel:addView(k, scrollingList)
            for index, entry in ipairs(v) do
                local row = scrollingList:addItem(entry.type, nil)
                row.type = entry.type
                row.target = entry.target
                row.price = entry.price or 0
                row.rowId = k;
                row.rowIndex = index;

                DebugPrintFactionsEconomy("New item for: " .. k .. ", name: " .. row.target);

                if ISShop.LoadType[entry.type] then
                    ISShop.LoadType[entry.type](row, entry)
                else
                    row.text = entry.type .. ":" .. tostring(entry.target)
                end
            end
        end
    end
end

local function RequestShopItems()
    Events.OnGameStart.Remove(RequestShopItems);
    if isSingleplayer then
        ReceiveShopItems("FactionsEconomyShop", "receiveShopItems", ShopItems);
    else
        Events.OnServerCommand.Add(ReceiveShopItems);
        sendClientCommand("FactionsEconomyShop", "getShopItems", nil);
    end
end

Events.OnGameStart.Add(RequestShopItems);

--#endregion

--#region Widgets load

function ISShop.LoadType.ITEM(row, entry)
    row.quantity = entry.quantity or 1
    local item = getScriptManager():getItem(entry.target)
    if item then
        row.text = item:getDisplayName()
        row.texture = item:getNormalTexture()
    else
        row.text = "Unkown"
        row.text = "Base.Axe"
    end
end

function ISShop.LoadType.VEHICLE(row, entry)
    row.text = getScriptManager():getVehicle(entry.target):getName()
    row.texture = getTexture("Item_CarKey")
end

function ISShop.LoadType.XP(row, entry)
    row.quantity = entry.quantity or 1
    row.text = entry.target .. " XP"
    row.texture = getTexture("media/ui/Moodle_internal_plus_green.png")
end

function ISShop.LoadType.DIV(row, entry)
    row.target = row.target or {}
    if type(entry.target) == "string" then
        row.target = {}
        for text in entry.target:gmatch("([^\n]+)") do table.insert(row.target, text) end
    end
    row.font = row.height > #row.target * (FONT_HGT_LARGE + 1 * FONT_SCALE) and UIFont.Large or
        row.height > #row.target * (FONT_HGT_MEDIUM + 1 * FONT_SCALE) and UIFont.Medium or UIFont.Small
    row.fontHeight = getTextManager():getFontHeight(row.font)
end

--#endregion

--#region Widgets buy section

function ISShop.BuyType.ITEM(row)
    -- Raw copy of the server function for single player
    if isSingleplayer then
        local player = getPlayer();
        local rowId = row.rowId;
        local index = row.rowIndex;

        local category = ShopItems[rowId]
        if not category then
            DebugPrintFactionsEconomy("Row not found: " .. tostring(rowId) .. ", for player: " .. player:getUsername());
            return
        end

        --type
        --target
        --quantity
        --price
        local item = category[index]
        if not item then
            DebugPrintFactionsEconomy("Item not found on index: " ..
                tostring(index) .. ", for player: " .. player:getUsername());
            return
        end

        if item.type == "ITEM" then
            -- No currency registered for the player
            if not FactionsEconomyCurrencyData[player:getUsername()] then
                DebugPrintFactionsEconomy("No currency registered for player: " .. player:getUsername());
                return
            end

            -- Check if player have currency available to buy the item
            if FactionsEconomyCurrencyData[player:getUsername()] >= item.price then
                FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] -
                    item.price;

                DebugPrintFactionsEconomy(player:getUsername() ..
                    ", bought: " .. item.target .. " for " .. item.price);

                player:getInventory():AddItems(item.target, item.quantity);
            else -- Nope
                DebugPrintFactionsEconomy("Not enough currency for player: " ..
                    player:getUsername() ..
                    ", " .. FactionsEconomyCurrencyData[player:getUsername()] .. "/" .. item.price);
                return
            end
        end
    else
        sendClientCommand("FactionsEconomyShop", "buyShop", row)
    end
end

function ISShop.BuyType.VEHICLE(row)
    sendClientCommand("FactionsEconomyShop", "buyShop", { row.price, row.target })
    sendClientCommand("FactionsEconomyShop", "vehicleShop", { row.target })
end

function ISShop.BuyType.XP(row)
    sendClientCommand("FactionsEconomyShop", "buyShop", { row.price, row.target })
    getPlayer():getXp():AddXP(Perks[row.target], row.quantity, true, false, false)
end

--#endregion

function ISShop:setVisible(visible)
    if self.javaObject == nil then
        self:instantiate()
    end
    self.javaObject:setVisible(visible)
    if self.preview then
        self.preview:setVisible(visible)
    end
    if visible then
        if isSingleplayer then
            ISShop.instance.currency = FactionsEconomyCurrencyData[getPlayer():getUsername()] or 0;
        else
            Events.OnServerCommand.Add(ReceiveCurrency);
            sendClientCommand("FactionsEconomyCurrency", "getCurrency", nil);
        end
    end
end

function ISShop:createChildren()
    local z = 15 * FONT_SCALE * 2 + FONT_HGT_LARGE + 1
    local btnWid = 125 * FONT_SCALE
    local btnHgt = FONT_HGT_SMALL + 5 * 2 * FONT_SCALE
    local padBottom = 10 * FONT_SCALE

    self.tabPanel = ISTabPanel:new(0, z, self.width, self.height - z - padBottom - btnHgt - padBottom)
    self.tabPanel:initialise()
    self.tabPanel.tabFont = UIFont.Medium
    self.tabPanel.tabHeight = FONT_HGT_MEDIUM + 6
    self.tabPanel.render = self.tabPanelRender
    self.tabPanel.addView = self.addView
    self:addChild(self.tabPanel)

    self.previewButton = ISButton:new(self.width - 200 * FONT_SCALE - padBottom * 2, 0, 100 * FONT_SCALE,
        FONT_HGT_LARGE + 1 * FONT_SCALE + FONT_HGT_SMALL, "PREVIEW", self, ISShop.onPreview)
    self.previewButton:initialise()
    self.previewButton:instantiate()
    self.previewButton.borderColor = self.buttonBorderColor
    self.previewButton:setVisible(false)
    self.previewButton.font = UIFont.Medium
    self:addChild(self.previewButton)

    self.buyButton = ISButton:new(self.width - 100 * FONT_SCALE - padBottom, 0, 100 * FONT_SCALE,
        FONT_HGT_LARGE + 1 * FONT_SCALE + FONT_HGT_SMALL, getText("IGUI_Buy"), self, ISShop.onBuy)
    self.buyButton:initialise()
    self.buyButton:instantiate()
    self.buyButton.borderColor = self.buttonBorderColor
    self.buyButton:setVisible(false)
    self.buyButton.font = UIFont.Medium
    self:addChild(self.buyButton)

    self.cancelButton = ISButton:new(self.width - padBottom - btnWid, self.height - padBottom - btnHgt, btnWid, btnHgt,
        getText("UI_btn_close"), self, ISShop.close)
    self.cancelButton:initialise()
    self.cancelButton:instantiate()
    self:addChild(self.cancelButton)

    self.reloadButton = ISButton:new(self.cancelButton.x - padBottom - btnWid, self.cancelButton.y, btnWid, btnHgt,
        getText("IGUI_Reload"), self, ISShop.onReload)
    self.reloadButton:initialise()
    self.reloadButton:instantiate()
    self:addChild(self.reloadButton)
end

function ISShop:close()
    self:setVisible(false)
end

function ISShop:onReload()
    for i, v in ipairs(self.tabPanel.viewList) do
        self.tabPanel:removeView(v.view)
    end

    if isSingleplayer then
        ISShop.instance.currency = FactionsEconomyCurrencyData[getPlayer():getUsername()] or 0;
        ReceiveShopItems("FactionsEconomyShop", "receiveShopItems", ShopItems);
    else
        Events.OnServerCommand.Add(ReceiveShopItems);
        sendClientCommand("FactionsEconomyShop", "getShopItems", nil);

        Events.OnServerCommand.Add(ReceiveCurrency);
        sendClientCommand("FactionsEconomyCurrency", "getCurrency", nil);
    end
end

function ISShop:onBuy()
    local row = self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected]
    if ISShop.BuyType[row.type] then
        ISShop.BuyType[row.type](row);

        if isSingleplayer then
            ISShop.instance.currency = FactionsEconomyCurrencyData[getPlayer():getUsername()] or 0;
        else
            Events.OnServerCommand.Add(ReceiveCurrency);
            sendClientCommand("FactionsEconomyCurrency", "getCurrency", nil);
        end
    end
end

function ISShop.PreviewType.VEHICLE(self)
    self.preview = ISUI3DScene:new(self.x + self.width, self.y, 400 * FONT_SCALE, self.height)
    self.preview:initialise()
    self.parent:addChild(self.preview)
    self.preview.onMouseMove = function(self, dx, dy)
        if self.mouseDown then
            local vector = self:getRotation()
            local x = vector:x() + dy
            x = x > 90 and 90 or x < -90 and -90 or x
            self:setRotation(x, vector:y() + dx)
        end
    end
    self.preview.setRotation = function(self, x, y)
        self.javaObject:fromLua3("setViewRotation", x, y, 0)
    end
    self.preview.getRotation = function(self)
        return self.javaObject:fromLua0("getViewRotation")
    end
    self.preview.javaObject:fromLua1("setDrawGrid", false)
    self.preview.javaObject:fromLua1("createVehicle", "vehicle")
    self.preview.javaObject:fromLua3("setViewRotation", 45 / 2, 45, 0)
    self.preview.javaObject:fromLua1("setView", "UserDefined")
    self.preview.javaObject:fromLua2("dragView", 0, 30)
    self.preview.javaObject:fromLua1("setZoom", 6)
    self.preview.javaObject:fromLua2("setVehicleScript", "vehicle",
        self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected].target)

    self.preview.closeButton = ISButton:new(self.preview.width - 15 * FONT_SCALE, 5 * FONT_SCALE, 10 * FONT_SCALE,
        10 * FONT_SCALE, nil, self.preview, function(self)
            self:setVisible(false)
            self:removeFromUIManager()
            ISShop.instance.preview = nil
        end)
    self.preview.closeButton:setDisplayBackground(false)
    self.preview.closeButton:setImage(getTexture("media/ui/Dialog_Titlebar_CloseIcon.png"))
    self.preview.closeButton:forceImageSize(self.preview.closeButton.width, self.preview.closeButton.height)
    self.preview.closeButton:initialise()
    self.preview:addChild(self.preview.closeButton)
end

function ISShop:onPreview()
    if self.preview then
        self.preview:setVisible(false)
        self.preview:removeFromUIManager()
        ISShop.instance.preview = nil
    end
    if ISShop.PreviewType[self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected].type] then
        ISShop.PreviewType
            [self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected].type](self)
    end
end

function ISShop:tabPanelRender()
    local inset = 1 -- assumes a 1-pixel window border on the left to avoid

    local x = inset + self.scrollX
    local widthOfAllTabs = self:getWidthOfAllTabs()
    local overflowLeft = self.scrollX < 0
    local overflowRight = x + widthOfAllTabs > self.width
    if widthOfAllTabs > self.width then
        self:setStencilRect(0, 0, self.width, self.tabHeight)
    end
    for i, viewObject in ipairs(self.viewList) do
        local tabWidth = self.equalTabWidth and self.maxLength or viewObject.tabWidth
        -- if this tab is the active one, we make the tab btn lighter
        if viewObject == self.activeView then
            self:drawRect(x, 0, tabWidth, self.tabHeight, 1, 0.4, 0.4, 0.4)
        else
            self:drawRect(x + tabWidth, 0, 1, self.tabHeight, 1, 0.4, 0.4, 0.4)
            if self:getMouseY() >= 0 and self:getMouseY() < self.tabHeight and self:isMouseOver() and self:getTabIndexAtX(self:getMouseX()) == i then
                viewObject.fade:setFadeIn(true)
            else
                viewObject.fade:setFadeIn(false)
            end
            viewObject.fade:update()
            self:drawRect(x, 0, tabWidth, self.tabHeight, 0.2 * viewObject.fade:fraction(), 1, 1, 1)
        end
        self:drawTextCentre(viewObject.name, x + (tabWidth / 2), 3, 1, 1, 1, 1, self.tabFont)
        x = x + tabWidth
    end
    self:drawRect(0, self.tabHeight - 1, self.width, 1, 1, 0.4, 0.4, 0.4)
    local butPadX = 3
    if overflowLeft then
        local tex = getTexture("media/ui/ArrowLeft.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(inset, 0, butWid, self.tabHeight - 1, 1, 0, 0, 0)
        self:drawRectBorder(inset, -1, butWid, self.tabHeight + 1, 1, 0.4, 0.4, 0.4)
        self:drawTexture(tex, inset + butPadX, (self.tabHeight - tex:getHeightOrig()) / 2, 1, 1, 1, 1)
    end
    if overflowRight then
        local tex = getTexture("media/ui/ArrowRight.png")
        local butWid = tex:getWidthOrig() + butPadX * 2
        self:drawRect(self.width - inset - butWid, 0, butWid, self.tabHeight - 1, 1, 0, 0, 0)
        self:drawRectBorder(self.width - inset - butWid, -1, butWid, self.tabHeight + 1, 1, 0.4, 0.4, 0.4)
        self:drawTexture(tex, self.width - butWid + butPadX, (self.tabHeight - tex:getHeightOrig()) / 2, 1, 1, 1, 1)
    end
    if widthOfAllTabs > self.width then
        self:clearStencilRect()
    end
    self:drawRect(0, self.height, self.width, 1, 1, 0.4, 0.4, 0.4)
end

function ISShop:addView(name, view)
    local viewObject = {}
    viewObject.name = getText("IGUI_Shop_" .. name)
    viewObject.view = view
    viewObject.tabWidth = getTextManager():MeasureStringX(self.tabFont, name) + self.tabPadX
    viewObject.fade = UITransition.new()
    table.insert(self.viewList, viewObject)
    view:setY(self.tabHeight)
    self:addChild(view)
    view.parent = self
    if #self.viewList == 1 then
        view:setVisible(true)
        self.activeView = viewObject
        self.maxLength = viewObject.tabWidth
    else
        view:setVisible(false)
        if viewObject.tabWidth > self.maxLength then
            self.maxLength = viewObject.tabWidth
        end
    end
end

function ISShop.DrawType.DIV(self, y, item, alt)
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g,
        self.borderColor.b)
    y = y + (item.height - #item.target * item.fontHeight) / 2
    for i, v in ipairs(item.target) do
        self:drawTextCentre(v, self.width / 2, y, 0.7, 0.7, 0.7, 1.0, item.font)
        y = y + item.fontHeight + 1 * FONT_SCALE
    end
end

function ISShop.DrawType.DEFAULT(self, y, item, alt)
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g,
        self.borderColor.b)
    local x = self.itemPadY
    local z = y + self.itemPadY
    if item.texture then
        self:drawTextureScaledAspect2(item.texture, x, z, self.textureHeight, self.textureHeight, 1, 1, 1, 1)
    end
    x = x + self.itemPadY + self.textureHeight
    if item.quantity then
        self:drawText("Quantity: ", x, z + FONT_HGT_LARGE + 1 * FONT_SCALE, 0.7, 0.7, 0.7, 1.0, UIFont.Small)
        self:drawText(tostring(item.quantity), x + getTextManager():MeasureStringX(UIFont.Small, "Quantity: "),
            z + FONT_HGT_LARGE + 1 * FONT_SCALE, 0.7, 0.7, 0.7, 1.0, UIFont.Small)
    else
        z = y + (item.height - FONT_HGT_LARGE) / 2
    end
    self:drawText(item.text, x, z, 0.7, 0.7, 0.7, 1.0, self.font)
    x = self.width - 75
    z = y + (item.height - FONT_HGT_LARGE) / 2
    self:drawText(tostring(item.price), x, z, 0.7, 0.7, 0.7, 1.0, self.font)
end

function ISShop:doDrawItem(y, item, alt)
    if ISShop.DrawType[item.type] then
        ISShop.DrawType[item.type](self, y, item, alt)
    else
        ISShop.DrawType.DEFAULT(self, y, item, alt)
    end

    return y + item.height
end

function ISShop:render()
    local z = 15 * FONT_SCALE
    self:drawText(self.title, 10 * FONT_SCALE, z, 1, 1, 1, 1, UIFont.Large)

    z = z + FONT_HGT_LARGE + z
    local x = self.width - 10 * FONT_SCALE - FONT_HGT_LARGE
    self:drawTextureScaledAspect2(getSteamAvatarFromUsername(getPlayer():getUsername()), x, (z - FONT_HGT_LARGE) / 2,
        FONT_HGT_LARGE, FONT_HGT_LARGE, 1, 1, 1, 1)
    x = x - (5 * FONT_SCALE) - getTextManager():MeasureStringX(UIFont.Medium, self.available)
    self:drawText(self.available, x, (z - FONT_HGT_MEDIUM) / 2, 1, 1, 1, 1, UIFont.Medium)
    x = x - (3 * FONT_SCALE) - getTextManager():MeasureStringX(UIFont.Medium, tostring(self.currency))
    self:drawText(tostring(self.currency), x, (z - FONT_HGT_MEDIUM) / 2, 1, 1, 1, 1, UIFont.Medium)

    self:drawRect(0, z, self.width, 1, 1, 0.4, 0.4, 0.4)

    self:drawText(self.serverMsg, 10 * FONT_SCALE, self.tabPanel:getBottom() + 1 + 10 * FONT_SCALE, 1, 1, 1, 1,
        UIFont.Medium)

    local view = self.tabPanel.activeView
    if view then view = view.view else return end
    if view.mouseoverselected == -1 then
        self.buyButton:setVisible(false)
        self.previewButton:setVisible(false)
    else
        local row = view.items[view.mouseoverselected]
        z = (view.mouseoverselected - 1) * view.itemheight + view:getYScroll() + view.itemPadY + view.y + view.parent.y

        if ISShop.BuyType[row.type] then
            self.buyButton:setY(z)
            self.buyButton:setVisible(true)
            if self.currency < row.price then
                self.buyButton:setEnable(false)
            else
                self.buyButton:setEnable(true)
            end
        else
            self.buyButton:setVisible(false)
        end

        if ISShop.PreviewType[row.type] then
            self.previewButton:setY(z)
            self.previewButton:setVisible(true)
        else
            self.previewButton:setVisible(false)
        end
    end
end

function ISShop:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.variableColor = { r = 0.9, g = 0.55, b = 0.1, a = 1 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    o.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    o.title = getText("IGUI_Shop")
    o.available = getText("IGUI_Shop_Available")
    o.serverMsg = getText("IGUI_Shop_Message")
    o.currency = 0
    ISShop.instance = o
    return o
end
