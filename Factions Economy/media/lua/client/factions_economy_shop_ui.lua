---@diagnostic disable: undefined-global

local ServerShopUI = ISPanel:derive("ServerShopUI")
ServerShopUI.BuyType = {}
ServerShopUI.DrawType = {}
ServerShopUI.LoadType = {}
ServerShopUI.PreviewType = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
local FONT_SCALE = FONT_HGT_SMALL / 14


local function OnServerCommand(module, command, arguments)
    if module == "ServerPoints" and command == "getPoints" then
        ServerShopUI.instance.points = arguments[1]
        Events.OnServerCommand.Remove(OnServerCommand)
    end
end

function ServerShopUI:setVisible(visible)
    if self.javaObject == nil then
        self:instantiate()
    end
    self.javaObject:setVisible(visible)
    if self.preview then
        self.preview:setVisible(visible)
    end
    if visible then
        Events.OnServerCommand.Add(OnServerCommand)
        sendClientCommand("ServerPoints", "getPoints", nil)
    end
end

function ServerShopUI.LoadType.ITEM(row, entry)
    row.quantity = entry.quantity or 1
    local item = getScriptManager():getItem(entry.target)
    row.text = item:getDisplayName()
    row.texture = item:getNormalTexture()
end

function ServerShopUI.LoadType.VEHICLE(row, entry)
    row.text = getScriptManager():getVehicle(entry.target):getName()
    row.texture = getTexture("Item_CarKey")
end

function ServerShopUI.LoadType.XP(row, entry)
    row.quantity = entry.quantity or 1
    row.text = entry.target .. " XP"
    row.texture = getTexture("media/ui/Moodle_internal_plus_green.png")
end

function ServerShopUI.LoadType.DIV(row, entry)
    row.target = row.target or {}
    if type(entry.target) == "string" then
        row.target = {}
        for text in entry.target:gmatch("([^\n]+)") do table.insert(row.target, text) end
    end
    row.font = row.height > #row.target * (FONT_HGT_LARGE + 1 * FONT_SCALE) and UIFont.Large or row.height > #row.target * (FONT_HGT_MEDIUM + 1 * FONT_SCALE) and UIFont.Medium or UIFont.Small
    row.fontHeight = getTextManager():getFontHeight(row.font)
end

function ServerShopUI.LoadListings(module, command, arguments)
    if module == "ServerPoints" and command == "loadShop" then
        Events.OnServerCommand.Remove(ServerShopUI.LoadListings)
        for k, v in pairs(arguments) do
            local scrollingList = ISScrollingListBox:new(1, 0, ServerShopUI.instance.tabPanel.width - 2, ServerShopUI.instance.tabPanel.height - ServerShopUI.instance.tabPanel.tabHeight)
            scrollingList.itemPadY = 10 * FONT_SCALE
            scrollingList.itemheight = FONT_HGT_LARGE + scrollingList.itemPadY * 2 + 1 * FONT_SCALE + FONT_HGT_SMALL
            scrollingList.textureHeight = scrollingList.itemheight - scrollingList.itemPadY * 2
            scrollingList.mouseoverselected = -1
            scrollingList:initialise()
            scrollingList.doDrawItem = ServerShopUI.doDrawItem
            ServerShopUI.instance.tabPanel:addView(k, scrollingList)
            for _, entry in ipairs(v) do
                local row = scrollingList:addItem(entry.type, nil)
                row.type = entry.type
                row.target = entry.target
                row.price = entry.price or 0
                if ServerShopUI.LoadType[entry.type] then
                    ServerShopUI.LoadType[entry.type](row, entry)
                else
                    row.text = entry.type .. ":" .. tostring(entry.target)
                end
            end
        end
    end
end

local function OnTick()
    Events.OnTick.Remove(OnTick)
    Events.OnServerCommand.Add(ServerShopUI.LoadListings)
    sendClientCommand("ServerPoints", "loadShop", nil)
end

function ServerShopUI:createChildren()
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
    Events.OnTick.Add(OnTick)

    self.previewButton = ISButton:new(self.width - 200 * FONT_SCALE - padBottom * 2, 0, 100 * FONT_SCALE, FONT_HGT_LARGE + 1 * FONT_SCALE + FONT_HGT_SMALL, "PREVIEW", self, ServerShopUI.onPreview)
    self.previewButton:initialise()
    self.previewButton:instantiate()
    self.previewButton.borderColor = self.buttonBorderColor
    self.previewButton:setVisible(false)
    self.previewButton.font = UIFont.Medium
    self:addChild(self.previewButton)

    self.buyButton = ISButton:new(self.width - 100 * FONT_SCALE - padBottom, 0, 100 * FONT_SCALE, FONT_HGT_LARGE + 1 * FONT_SCALE + FONT_HGT_SMALL, getText("IGUI_Buy"), self, ServerShopUI.onBuy)
    self.buyButton:initialise()
    self.buyButton:instantiate()
    self.buyButton.borderColor = self.buttonBorderColor
    self.buyButton:setVisible(false)
    self.buyButton.font = UIFont.Medium
    self:addChild(self.buyButton)

    self.cancelButton = ISButton:new(self.width - padBottom - btnWid, self.height - padBottom - btnHgt, btnWid, btnHgt, getText("UI_btn_close"), self, ServerShopUI.close)
    self.cancelButton:initialise()
    self.cancelButton:instantiate()
    self:addChild(self.cancelButton)

    if getDebug() then
        self.reloadButton = ISButton:new(self.cancelButton.x - padBottom - btnWid, self.cancelButton.y, btnWid, btnHgt, getText("IGUI_Reload"), self, ServerShopUI.onReload)
        self.reloadButton:initialise()
        self.reloadButton:instantiate()
        self:addChild(self.reloadButton)
    end
end

function ServerShopUI:close()
    self:setVisible(false)
end

function ServerShopUI:onReload()
    for i, v in ipairs(self.tabPanel.viewList) do
        self.tabPanel:removeView(v.view)
    end
    Events.OnServerCommand.Add(ServerShopUI.LoadListings)
    sendClientCommand("ServerPoints", "loadShop", nil)
end

function ServerShopUI.BuyType.ITEM(row)
    sendClientCommand("ServerPoints", "buyShop", { row.price, row.target })
    getPlayer():getInventory():AddItems(row.target, row.quantity)
end

function ServerShopUI.BuyType.VEHICLE(row)
    sendClientCommand("ServerPoints", "buyShop", { row.price, row.target })
    sendClientCommand("ServerPoints", "vehicleShop", { row.target })
end

function ServerShopUI.BuyType.XP(row)
    sendClientCommand("ServerPoints", "buyShop", { row.price, row.target })
    getPlayer():getXp():AddXP(Perks[row.target], row.quantity, true, false, false)
end

function ServerShopUI:onBuy()
    local row = self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected]
    self.points = self.points - row.price
    if ServerShopUI.BuyType[row.type] then
        ServerShopUI.BuyType[row.type](row)
    end
    Events.OnServerCommand.Add(OnServerCommand)
    sendClientCommand("ServerPoints", "getShop", nil)
end

function ServerShopUI.PreviewType.VEHICLE(self)
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
    self.preview.javaObject:fromLua2("setVehicleScript", "vehicle", self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected].target)

    self.preview.closeButton = ISButton:new(self.preview.width - 15 * FONT_SCALE, 5 * FONT_SCALE, 10 * FONT_SCALE, 10 * FONT_SCALE, nil, self.preview, function(self)
        self:setVisible(false)
        self:removeFromUIManager()
        ServerShopUI.instance.preview = nil
    end)
    self.preview.closeButton:setDisplayBackground(false)
    self.preview.closeButton:setImage(getTexture("media/ui/Dialog_Titlebar_CloseIcon.png"))
    self.preview.closeButton:forceImageSize(self.preview.closeButton.width, self.preview.closeButton.height)
    self.preview.closeButton:initialise()
    self.preview:addChild(self.preview.closeButton)
end

function ServerShopUI:onPreview()
    if self.preview then
        self.preview:setVisible(false)
        self.preview:removeFromUIManager()
        ServerShopUI.instance.preview = nil
    end
    if ServerShopUI.PreviewType[self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected].type] then
        ServerShopUI.PreviewType[self.tabPanel.activeView.view.items[self.tabPanel.activeView.view.mouseoverselected].type](self)
    end
end

function ServerShopUI:tabPanelRender()
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

function ServerShopUI:addView(name, view)
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

function ServerShopUI.DrawType.DIV(self, y, item, alt)
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    y = y + (item.height - #item.target * item.fontHeight) / 2
    for i, v in ipairs(item.target) do
        self:drawTextCentre(v, self.width / 2, y, 0.7, 0.7, 0.7, 1.0, item.font)
        y = y + item.fontHeight + 1 * FONT_SCALE
    end
end

function ServerShopUI.DrawType.DEFAULT(self, y, item, alt)
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    local x = self.itemPadY
    local z = y + self.itemPadY
    if item.texture then
        self:drawTextureScaledAspect2(item.texture, x, z, self.textureHeight, self.textureHeight, 1, 1, 1, 1)
    end
    x = x + self.itemPadY + self.textureHeight
    if item.quantity then
        self:drawText("Quantity: ", x, z + FONT_HGT_LARGE + 1 * FONT_SCALE, 0.7, 0.7, 0.7, 1.0, UIFont.Small)
        self:drawText(tostring(item.quantity), x + getTextManager():MeasureStringX(UIFont.Small, "Quantity: "), z + FONT_HGT_LARGE + 1 * FONT_SCALE, 0.7, 0.7, 0.7, 1.0, UIFont.Small)
    else
        z = y + (item.height - FONT_HGT_LARGE) / 2
    end
    self:drawText(item.text, x, z, 0.7, 0.7, 0.7, 1.0, self.font)
    x = self.width - 75
    z = y + (item.height - FONT_HGT_LARGE) / 2
    self:drawText(tostring(item.price), x, z, 0.7, 0.7, 0.7, 1.0, self.font)
end

function ServerShopUI:doDrawItem(y, item, alt)
    if ServerShopUI.DrawType[item.type] then
        ServerShopUI.DrawType[item.type](self, y, item, alt)
    else
        ServerShopUI.DrawType.DEFAULT(self, y, item, alt)
    end

    return y + item.height
end

function ServerShopUI:render()
    local z = 15 * FONT_SCALE
    self:drawText(self.title, 10 * FONT_SCALE, z, 1, 1, 1, 1, UIFont.Large)

    z = z + FONT_HGT_LARGE + z
    local x = self.width - 10 * FONT_SCALE - FONT_HGT_LARGE
    self:drawTextureScaledAspect2(getSteamAvatarFromUsername(getPlayer():getUsername()), x, (z - FONT_HGT_LARGE) / 2, FONT_HGT_LARGE, FONT_HGT_LARGE, 1, 1, 1, 1)
    x = x - (5 * FONT_SCALE) - getTextManager():MeasureStringX(UIFont.Medium, self.available)
    self:drawText(self.available, x, (z - FONT_HGT_MEDIUM) / 2, 1, 1, 1, 1, UIFont.Medium)
    x = x - (3 * FONT_SCALE) - getTextManager():MeasureStringX(UIFont.Medium, tostring(self.points))
    self:drawText(tostring(self.points), x, (z - FONT_HGT_MEDIUM) / 2, 1, 1, 1, 1, UIFont.Medium)

    self:drawRect(0, z, self.width, 1, 1, 0.4, 0.4, 0.4)

    self:drawText(self.serverMsg, 10 * FONT_SCALE, self.tabPanel:getBottom() + 1 + 10 * FONT_SCALE, 1, 1, 1, 1, UIFont.Medium)

    local view = self.tabPanel.activeView
    if view then view = view.view else return end
    if view.mouseoverselected == -1 then
        self.buyButton:setVisible(false)
        self.previewButton:setVisible(false)
    else
        local row = view.items[view.mouseoverselected]
        z = (view.mouseoverselected - 1) * view.itemheight + view:getYScroll() + view.itemPadY + view.y + view.parent.y

        if ServerShopUI.BuyType[row.type] then
            self.buyButton:setY(z)
            self.buyButton:setVisible(true)
            if self.points < row.price then
                self.buyButton:setEnable(false)
            else
                self.buyButton:setEnable(true)
            end
        else
            self.buyButton:setVisible(false)
        end

        if ServerShopUI.PreviewType[row.type] then
            self.previewButton:setY(z)
            self.previewButton:setVisible(true)
        else
            self.previewButton:setVisible(false)
        end
    end
end

function ServerShopUI:new(x, y, width, height)
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
    o.points = 0
    ServerShopUI.instance = o
    return o
end

return ServerShopUI
