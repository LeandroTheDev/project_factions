---@diagnostic disable: undefined-global, duplicate-set-field
if not isClient() and not isServer() then return end;
local ServerShopUI = require "factions_economy_shop_ui"
local ServerTradeUI = require "factions_economy_trade_ui"

-- Get the default function from pause menu
local defaultMainScreen = MainScreen.instantiate
-- Overwrite the pause menu
function MainScreen:instantiate()
    -- Default behavior
    defaultMainScreen(self);

    if self.inGame then
        local labelHgt = getTextManager():getFontHeight(UIFont.Large) + 8 * 2;
        local labelY = self.bottomPanel:getHeight();
        local labelX = 0;
        -- Add the text for open Shop
        if self.quitToDesktop then
            -- Default options
            local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14;
            local core = getCore();
            local width = 800 * FONT_SCALE;
            local height = 600 * FONT_SCALE;
            -- Initializing the UI
            self.serverShop = ServerShopUI:new((core:getScreenWidth() - width) / 2, (core:getScreenHeight() - height) / 2,
                width, height);
            self.serverShop:initialise();
            self.serverShop:setVisible(false);
            self.serverShop:setAnchorRight(true);
            self.serverShop:setAnchorBottom(true);
            self:addChild(self.serverShop);

            labelY = labelY + 16;
            self.shopLabel = ISLabel:new(labelX, labelY, labelHgt, getText("IGUI_Shop"), 1, 1, 1, 1, UIFont.Large,
                true);
            self.shopLabel.internal = "SHOP";
            self.shopLabel:initialise();
            self.bottomPanel:addChild(self.shopLabel);
            self.shopLabel.onMouseDown = function(item, x, y)
                getSoundManager():playUISound("UIActivateMainMenuItem");
                MainScreen.instance.serverShop:setVisible(true);
            end;
            labelY = labelY + labelHgt;
        end

        -- Add the text for open the Trading
        if self.quitToDesktop then
            local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14;
            local core = getCore();
            local width = 800 * FONT_SCALE;
            local height = 600 * FONT_SCALE;
            self.serverTrade = ServerTradeUI:new((core:getScreenWidth() - width) / 2,
                (core:getScreenHeight() - height) / 2, width, height);
            self.serverTrade:initialise();
            self.serverTrade:setVisible(false);
            self.serverTrade:setAnchorRight(true);
            self.serverTrade:setAnchorBottom(true);
            self:addChild(self.serverTrade);

            -- Creating the Labels
            labelY = labelY + 16;
            self.tradeLabel = ISLabel:new(labelX, labelY, labelHgt, getText("IGUI_Trade"), 1, 1, 1, 1, UIFont.Large,
                true);
            self.tradeLabel.internal = "TRADE";
            self.tradeLabel:initialise();
            self.bottomPanel:addChild(self.tradeLabel);
            self.tradeLabel.onMouseDown = function(item, x, y)
                getSoundManager():playUISound("UIActivateMainMenuItem");
                MainScreen.instance.serverTrade:setVisible(true);
            end
            labelY = labelY + labelHgt;
        end

        self.bottomPanel:setHeight(labelY);
    end
end
