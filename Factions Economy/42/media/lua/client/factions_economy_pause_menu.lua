---@diagnostic disable: undefined-global
local ServerShopUI = require "factions_economy_shop_ui"
local ServerTradeUI = require "factions_economy_trade_ui"

local defaultMainScreenRender = MainScreen.render
local function newRender(self)
    defaultMainScreenRender(self)

    if self.inGame and isClient() then
        self.bottomPanel:setHeight(self.shopOptions:getBottom())
        self.bottomPanel:setHeight(self.tradeOptions:getBottom())
    end
end

-- Get the default function from pause menu
local defaultMainScreen = MainScreen.instantiate
-- Overwrite the pause menu
function MainScreen:instantiate()
    -- Default behavior
    defaultMainScreen(self)

    if self.inGame and isClient() then
        -- Add the text for open Shop
        if self.quitToDesktop then
            -- Default options
            local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
            local core = getCore()
            local width = 800 * FONT_SCALE
            local height = 600 * FONT_SCALE
            -- Initializing the UI
            self.serverShop = ServerShopUI:new((core:getScreenWidth() - width) / 2, (core:getScreenHeight() - height) / 2, width, height)
            self.serverShop:initialise()
            self.serverShop:setVisible(false)
            self.serverShop:setAnchorRight(true)
            self.serverShop:setAnchorBottom(true)
            self:addChild(self.serverShop)

            -- Creating the Labels
            local labelHgt = getTextManager():getFontHeight(UIFont.Large) + 8 * 2
            self.shopOptions = ISLabel:new(self.quitToDesktop.x, self.quitToDesktop.y + labelHgt + 16, labelHgt, getText("IGUI_Shop"), 1, 1, 1, 1, UIFont.Large, true)
            self.shopOptions.internal = "SHOP"
            self.shopOptions:initialise()
            self.bottomPanel:addChild(self.shopOptions)
            self.render = newRender
            self.shopOptions.onMouseDown = function()
                getSoundManager():playUISound("UIActivateMainMenuItem")
                MainScreen.instance.serverShop:setVisible(true)
            end
            self.shopOptions:setWidth(self.quitToDesktop.width)
            self.shopOptions.fade = UITransition.new()
            self.shopOptions.fade:setFadeIn(false)
            self.shopOptions.prerender = self.prerenderBottomPanelLabel
        end

        -- Add the text for open the Trading
        if self.quitToDesktop then
            local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
            local core = getCore()
            local width = 800 * FONT_SCALE
            local height = 600 * FONT_SCALE
            self.serverTrade = ServerTradeUI:new((core:getScreenWidth() - width) / 2, (core:getScreenHeight() - height) / 2, width, height)
            self.serverTrade:initialise()
            self.serverTrade:setVisible(false)
            self.serverTrade:setAnchorRight(true)
            self.serverTrade:setAnchorBottom(true)
            self:addChild(self.serverTrade)

            local labelHgt = getTextManager():getFontHeight(UIFont.Large) + 8 * 2
            self.tradeOptions = ISLabel:new(self.quitToDesktop.x, self.shopOptions.y + labelHgt + 16, labelHgt, getText("IGUI_Trade"), 1, 1, 1, 1, UIFont.Large, true)
            self.tradeOptions.internal = "TRADES"
            self.tradeOptions:initialise()
            self.bottomPanel:addChild(self.tradeOptions)
            self.render = newRender
            self.tradeOptions.onMouseDown = function()
                getSoundManager():playUISound("UIActivateMainMenuItem")
                MainScreen.instance.serverTrade:setVisible(true)
            end
            self.tradeOptions:setWidth(self.quitToDesktop.width)
            self.tradeOptions.fade = UITransition.new()
            self.tradeOptions.fade:setFadeIn(false)
            self.tradeOptions.prerender = self.prerenderBottomPanelLabel
        end
    end
end
