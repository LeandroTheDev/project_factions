---@diagnostic disable: undefined-global, undefined-field
require "ISUI/ISUIElement"

FactionsGUILabel = ISUIElement:derive("FactionsGUILabel");


--************************************************************************--
--** ISPanel:initialise
--**
--************************************************************************--

function FactionsGUILabel:initialise()
	ISUIElement.initialise(self);
end

function FactionsGUILabel:getName()
	return self.name;
end


function FactionsGUILabel:setName(name)
	if self.name == name then return end
	self.name = name
	self:setX(self.originalX)
	self:setWidth(getTextManager():MeasureStringX(self.font, name))
	if self.left ~= true then
		self:setX(self.x - self.width)
	end
end
function FactionsGUILabel:setColor(r,g,b)
	self.r = r;
	self.g = g;
	self.b = b;
end

--************************************************************************--
--** ISPanel:render
--**
--************************************************************************--
function FactionsGUILabel:prerender()
    local txt = self.name;
    if self.translation then
        txt = self.translation;
    end
	local height = getTextManager():MeasureFont(self.font);

	-- The above call doesn't handle multi-line text
	local height2 = getTextManager():MeasureStringY(self.font, txt)
	height = math.max(height, height2)
    if not self.center then
	    self:drawText(txt, 0, (self.height/2)-(height/2), self.r, self.g, self.b, self.a, self.font);
    else
        self:drawTextCentre(txt, 0, (self.height/2)-(height/2), self.r, self.g, self.b, self.a, self.font);
    end
    if self.joypadFocused and self.joypadTexture then
		local texY = self.height / 2 - 20 / 2
        self:drawTextureScaled(self.joypadTexture,-20,texY,20,20,1,1,1,1);
    end
    self:updateTooltip()
end

function FactionsGUILabel:onMouseMove(dx, dy)
    self.mouseOver = true;
end

function FactionsGUILabel:onMouseMoveOutside(dx, dy)
    self.mouseOver = false;
end

function FactionsGUILabel:updateTooltip()
    if self.disabled then return; end
    if self:isMouseOver() and self.tooltip then
        local text = self.tooltip
        if not self.tooltipUI then
            self.tooltipUI = ISToolTip:new()
            self.tooltipUI:setOwner(self)
            self.tooltipUI:setVisible(false)
            self.tooltipUI:setAlwaysOnTop(true)
        end
        if not self.tooltipUI:getIsVisible() then
            if string.contains(self.tooltip, "\n") then
                self.tooltipUI.maxLineWidth = 1000 -- don't wrap the lines
            else
                self.tooltipUI.maxLineWidth = 300
            end
            self.tooltipUI:addToUIManager()
            self.tooltipUI:setVisible(true)
        end
        self.tooltipUI.description = text
        self.tooltipUI:setX(self:getAbsoluteX())
        self.tooltipUI:setY(self:getAbsoluteY() + self:getHeight())
    else
        if self.tooltipUI and self.tooltipUI:getIsVisible() then
            self.tooltipUI:setVisible(false)
            self.tooltipUI:removeFromUIManager()
        end
    end
end

function FactionsGUILabel:setTooltip(tooltip)
    self.tooltip = tooltip;
end

function FactionsGUILabel:setJoypadFocused(focused)
    self.joypadFocused = focused;
    self.joypadTexture = getTexture("media/ui/abutton.png");
end

function FactionsGUILabel:setTranslation(translation)
    self.translation = translation;
    self.x = self.originalX;
    if self.font ~= nil then
        self.width  = getTextManager():MeasureStringX(self.font, translation);
        if(self.left ~= true) then
            self.x = self.x - self.width;
        end
    else
        self.width = getTextManager():MeasureStringX(UIFont.NewSmall, translation);
        if(self.left ~= true) then
            self.x = self.x - self.width;
        end
        self.font = UIFont.NewSmall;
    end
end

--************************************************************************--
--** ISPanel:new
--**
--************************************************************************--
function FactionsGUILabel:new (x, y, width, height, name, r, g, b, a, font)
	local o = {}
	--o.data = {}
	o = ISUIElement:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.x = x;
	o.y = y;
	o.font = font;
	o.backgroundColor = {r=0, g=0, b=0, a=0.5};
	o.borderColor = {r=1, g=1, b=1, a=0.7};
	o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
	o.name = name;
	o.r = r;
	o.g = g;
	o.b = b;
	o.a = a;
    o.mouseOver = false;
    o.tooltip = nil;
    o.joypadFocused = false;
    o.center = false;
    o.translation = nil;
    o.originalX = x;
	return o
end
