local oldMainScreen_render = MainScreen.render;

function MainScreen:render()
    oldMainScreen_render(self);

    -- Main menu is not ingame
    if not self.quitToDesktop then return end

    local labelSeparator = 16;
    local newY = self.quitToDesktop:getBottom() + labelSeparator;
    self.shopOption:setY(newY);

    self.bottomPanel:setHeight(self.shopOption:getBottom());
end

local onMenuItemMouseDownMainMenu = function(item, x, y)
    local joypadData = JoypadState.getMainMenuJoypad();
    DebugPrintFactionsEconomy("Shop button pressed");

    MainScreen.instance.shop:setVisible(true, joypadData);
end

-- Get the default function from pause menu
local oldMainScreen_instantiate = MainScreen.instantiate;
-- Overwrite the pause menu
function MainScreen:instantiate()
    -- Default behavior
    oldMainScreen_instantiate(self);

    -- Shop instanciate
    if self.inGame then
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14;
        local core = getCore();
        local width = 800 * FONT_SCALE;
        local height = 600 * FONT_SCALE;

        self.shop = ISShop:new((core:getScreenWidth() - width) / 2, (core:getScreenHeight() - height) / 2,
            width, height);
        self.shop:initialise();
        self.shop:setVisible(false);
        self.shop:setAnchorRight(true);
        self.shop:setAnchorBottom(true);
        self:addChild(self.shop);

        DebugPrintFactionsEconomy("Shop interface created, additional infos: self.width: " ..
            self.width .. ", self.height: " .. self.height);
    end

    -- Shop option in main menu
    if self.inGame then
        local labelHgt = getTextManager():getFontHeight(UIFont.Large) + 8 * 2;
        local labelX = 0;
        local labelY = self.quitToDesktop.y + labelHgt;

        self.shopOption = ISLabel:new(labelX, labelY, labelHgt, getText("IGUI_Shop"), 1, 1, 1, 1,
            UIFont.Large, true);
        self.shopOption.internal = "SHOP";
        self.shopOption:initialise();
        self.bottomPanel:addChild(self.shopOption);
        self.shopOption.onMouseDown = onMenuItemMouseDownMainMenu;

        DebugPrintFactionsEconomy("Shop option label created, additional infos: labelY: " ..
            labelY .. ", quitToDesktop.y: " .. self.quitToDesktop.y .. ", labelHgt: " .. labelHgt);
    end
end
