-- ColorPickerPlus replaces the standard Color Picker to provide
-- © Jaslm
--	1. text entry for colors (RGB, hex, and HSV values) and alpha (for opacity),
--	2. copy to and paste from color palette
--	3. color swatches for the copied color and for the starting color
--	4. analog color choice through a hue bar and saturation/value gradient square
--	5. class palette and copy/paste independent of palette

--VARIABLES
-------------------------------------------------------------------------------------------------------

local _, ColorPickerPlus = ...
local MOD = ColorPickerPlus
local DB

local lockedHueBar = false
local lockedOpacityBar = false
local lockedGradient = false
local lockedOpacity = 0  -- saves value of opacity while HueBar or Gradient changes color values

local colorHue  -- 0 to 1
local colorSat  -- 0 to 1
local colorVal  -- 0 to 1

local dialogWidthNoOpacity = 380
local dialogWidthWithOpacity = 420
local dialogHeight = 380

local sideMargin = 28
local topMargin = 28
local spacing = 12

local hueBarWidth = 18
local hueBarHeight = 300
local hueTextureSize = 50  -- allow for 1/6 of hueBarHeight

local opacityBarWidth = 18
local opacityBarHeight = 300

local gradientWidth = 160
local gradientHeight = 160

local colorSwatchWidth = 120
local colorSwatchHeight = 120
local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) -- true if on classic server

-- bgtable used in creation of backdrops
local bgtable = {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		tile = false,
		tileSize = 16,
		edgeSize = 1,
		insets = { 0, 0, 0, 0 },
	}

-- initial values in palette
-- these are overridden by user and saved in WoW SavedVariables
local defaults = {
	palette = {					--  36 color allotted
		{ r = 1.0, g = 0.0, b = 0.0, a = 1.0 },	-- red
		{ r = 1.0, g = 0.0, b = 0.5, a = 1.0 },	-- rose
		{ r = 1.0, g = 0.0, b = 1.0, a = 1.0 },	-- magenta
		{ r = 0.5, g = 0.0, b = 1.0, a = 1.0 },	-- violet
		{ r = 0.0, g = 0.0, b = 1.0, a = 1.0 },	-- blue
		{ r = 0.0, g = 0.5, b = 1.0, a = 1.0 },	-- azure
		{ r = 0.0, g = 1.0, b = 1.0, a = 1.0 },	-- cyan
		{ r = 0.0, g = 1.0, b = 0.5, a = 1.0 }, -- aquamarine
		{ r = 0.0, g = 1.0, b = 0.0, a = 1.0 }, -- green
		{ r = 0.5, g = 1.0, b = 0.0, a = 1.0 }, -- chartreuse
		{ r = 1.0, g = 1.0, b = 0.0, a = 1.0 }, -- yellow
		{ r = 1.0, g = 0.5, b = 0.0, a = 1.0 }, -- orange
		{ r = 0.976, g = 0.549, b = 0.714, a = 1.0 },	-- pastels
		{ r = 0.984, g = 0.714, b = 0.820, a = 1.0 },
		{ r = 0.647, g = 0.537, b = 0.757, a = 1.0 },
		{ r = 0.757, g = 0.702, b = 0.843, a = 1.0 },
		{ r = 0.459, g = 0.537, b = 0.749, a = 1.0 },
		{ r = 0.580, g = 0.659, b = 0.816, a = 1.0 },
		{ r = 0.604, g = 0.808, b = 0.874, a = 1.0 },
		{ r = 0.710, g = 0.882, b = 0.682, a = 1.0 },
		{ r = 0.749, g = 0.894, b = 0.462, a = 1.0 },
		{ r = 0.999, g = 0.980, b = 0.506, a = 1.0 },
		{ r = 0.992, g = 0.792, b = 0.635, a = 1.0 },
		{ r = 0.859, g = 0.835, b = 0.725, a = 1.0 },
		{ r = 0.0, g = 0.0, b = 0.0, a = 1.0 },  -- black
		{ r = 0.1, g = 0.1, b = 0.1, a = 1.0 },	 -- shades of gray
		{ r = 0.2, g = 0.2, b = 0.2, a = 1.0 },
		{ r = 0.3, g = 0.3, b = 0.3, a = 1.0 },
		{ r = 0.4, g = 0.4, b = 0.4, a = 1.0 },
		{ r = 0.5, g = 0.5, b = 0.5, a = 1.0 },
		{ r = 0.6, g = 0.6, b = 0.6, a = 1.0 },
		{ r = 0.7, g = 0.7, b = 0.7, a = 1.0 },
		{ r = 0.8, g = 0.8, b = 0.8, a = 1.0 },
		{ r = 0.9, g = 0.9, b = 0.9, a = 1.0 },
		{ r = 1.0, g = 1.0, b = 1.0, a = 1.0 }, -- white
		{ r = 0.7, g = 0.7, b = 0.7, a = 0.7 }, -- transparent gray
	},
	paletteState = 2,
}

local classColorPalette = {
		{ r = 0.77, g = 0.12, b = 0.23, a = 1.0 }, -- Death Knight red
		{ r = 0.64, g = 0.19, b = 0.79, a = 1.0 }, -- Demon Hunter Magenta
		{ r = 1.00, g = 0.49, b = 0.04, a = 1.0 }, -- Druid Orange
		{ r = 0.67, g = 0.83, b = 0.45, a = 1.0 }, -- Hunter Green
		{ r = 0.41, g = 0.80, b = 0.94, a = 1.0 }, -- Mage Blue
		{ r = 0.00, g = 1.00, b = 0.59, a = 1.0 }, -- Monk Green
		{ r = 0.96, g = 0.55, b = 0.73, a = 1.0 }, -- Paladin Pink
		{ r = 1.00, g = 1.00, b = 1.00, a = 1.0 }, -- Priest White
		{ r = 1.00, g = 0.96, b = 0.41, a = 1.0 }, -- Rogue Yellow
		{ r = 0.00, g = 0.44, b = 0.87, a = 1.0 }, -- Shaman Blue
		{ r = 0.58, g = 0.51, b = 0.79, a = 1.0 }, -- Warlock Purple
		{ r = 0.78, g = 0.61, b = 0.43, a = 1.0 }, -- Warrior Tan
	}

--EVENT REGISTRATION
-------------------------------------------------------------------------------------------------------------------------
-- these need to happen inline at lua file load time

local eventFrame = CreateFrame("Frame")
eventFrame:Hide()
eventFrame:SetScript("OnEvent", function(self, event, ...) if (MOD[event]) then MOD[event](self, ...) end end)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

-------------------------------------------------------------------------------------------------------------------------
-- utility functions

-- Convert r, g, b input values into h, s, v return values
-- All values are in the range 0 to 1.0
local function RGB_to_HSV(r, g, b)
	local mincolor, maxcolor = math.min(r, g, b), math.max(r, g, b)
	local ch, cs, cv = 0, 0, maxcolor
	if maxcolor > 0 then -- technically ch is undefined if cs is zero
		local delta = maxcolor - mincolor
		cs = delta / maxcolor
		if delta > 0 then -- don't allow divide by zero
			if r == maxcolor then
				ch = (g - b) / delta -- between yellow and magenta
			elseif g == maxcolor then
				ch = 2 + ((b - r) / delta) -- between cyan and yellow
			else
				ch = 4 + ((r - g) / delta) -- between magenta and cyan
			end
		end
		if ch < 0 then ch = ch + 6 end -- correct for negative values
		ch = ch / 6 -- and finally adjust range 0 to 1.0
	end
	return ch, cs, cv
end

-- Convert h, s, l input values into r, g, b return values
-- All values are in the range 0 to 1.0
local function HSV_to_RGB(ch, cs, cv)
	if not ch or not cs or not cv then return 1, 0, 0 end
	if ch == 1 then ch = 0 end
	local r, g, b = cv, cv, cv
	if cs > 0 then -- if cs is zero then grey is returned
		local h = ch * 6; local sextant = math.floor(h) -- figure out which sextant of the color wheel
		local fract = h - sextant -- fractional offset into the sextant
		local p, q, t = cv * (1 - cs), cv * (1 - (cs * fract)), cv * (1 - (cs * (1 - fract)))
		if sextant == 0 then
			r, g, b = cv, t, p
		elseif sextant == 1 then
			r, g, b = q, cv, p
		elseif sextant == 2 then
			r, g, b = p, cv, t
		elseif sextant == 3 then
			r, g, b = p, q, cv
		elseif sextant == 4 then
			r, g, b = t, p, cv
		else
			r, g, b = cv, p, q
		end
	end
	return r, g, b
end

function MOD:UpdateHSVfromColorPickerRGB()
	colorHue, colorSat, colorVal = RGB_to_HSV(ColorPickerFrame:GetColorRGB())
end
function MOD:SetRGBfromHSV()
	ColorPickerFrame:SetColorRGB(HSV_to_RGB(colorHue, colorSat, colorVal))
end

function MOD:GetAlpha()
	local a
	if ColorPickerFrame.hasOpacity then
		a = 1-OpacitySliderFrame:GetValue()  -- blizzard values are reversed from expected transparency
	else
		a = 1
	end
	return a
end

function MOD:UpdateGradientColorOverlay()  -- assumes color variables all set prior
	local r, g, b = HSV_to_RGB(colorHue, 1, 1)
	ColorPPColorOverlay:SetVertexColor(r, g, b)
end

function MOD:UpdateChosenColor()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = MOD:GetAlpha()
	ColorPPChosenColor:SetBackdropColor(r,g,b,a)
end

function MOD:UpdateOldColor(r, g, b, a)
	ColorPPOldColor:SetBackdropColor(r,g,b,a)
end

function MOD.ADDON_LOADED (ev, name)
	if name == "ColorPickerPlus" then
		DB = ColorPickerPlusDB
		if DB then
			if not DB.palette then
				DB.palette = defaults.palette
			end
			if not DB.paletteState then
				DB.paletteState = defaults.paletteState
			end
		else
			ColorPickerPlusDB = defaults
			DB = ColorPickerPlusDB
		end
	end
end

-- functions to update thumb cursors

function MOD:UpdateGradientThumb()
	local rx = (colorSat * gradientWidth) -- use saturation and brightness to adjust gradient selection point
	local ry = (colorVal * gradientHeight)
	ColorPPColorGradientThumb:ClearAllPoints()

	-- allow for 5 pixel border around gradient, which allows user to 'grab' thumb and move it to edge of gradient
	if rx == 0 then rx = 5
	elseif rx > gradientWidth-5 then rx = rx-5
	end
	if ry == 0 then ry = 5
	elseif ry > gradientHeight-5 then ry = ry-5
	end
	ColorPPColorGradientThumb:SetPoint("CENTER", ColorPPGradient, "BOTTOMLEFT", rx, ry)
end

function MOD:UpdateOpacityBarThumb()
	local a = OpacitySliderFrame:GetValue()
	local ry = a*opacityBarHeight
	ColorPPOpacityBarThumb:ClearAllPoints()
	ColorPPOpacityBarThumb:SetPoint("CENTER", ColorPPOpacityBar, "BOTTOM", 0, ry)
end

function MOD:UpdateHueBarThumb()
	local ry = colorHue*hueBarHeight
	if colorHue < 0.5 then ry = ry + 1 else ry = ry -1 end   -- adjust for thumb position at ends of bar
	ColorPPHueBarThumb:ClearAllPoints()
	ColorPPHueBarThumb:SetPoint("CENTER", ColorPPHueBar, "TOP", 0, -ry)
end

function MOD:UpdateColorGraphics()
--[[
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local h, s, v = colorHue, colorSat, colorVal
	local a = MOD:GetAlpha()
	print("UPDATE COLOR GRAPHICS")
	print("r, g, b = ", floor(100*r), floor(100*g), floor(100*b))
	print("h, s, v = ", floor(h*360), floor(s*100), floor(v*100))
	print("alpha = ", floor(a*100))
--]]

	MOD:UpdateChosenColor()
	MOD:UpdateGradientColorOverlay()
	MOD:UpdateGradientThumb()
	MOD:UpdateHueBarThumb()
end

function MOD:ShowHideAlpha()
	-- show/hide the alpha box and adjust related components
	if ColorPickerFrame.hasOpacity then
		OpacitySliderFrame:Hide()    -- have to do this every time
		ColorPPOpacityBar:Show()
		ColorPPBoxA:Show()
		ColorPPBoxLabelA:Show()
		ColorPickerFrame:SetWidth(dialogWidthWithOpacity)
		MOD:UpdateOpacityBarThumb()
	else
		ColorPPOpacityBar:Hide()
		ColorPPBoxA:Hide()
		ColorPPBoxLabelA:Hide()
		ColorPickerFrame:SetWidth(dialogWidthNoOpacity)
	end
end

function MOD:Hooked_OnShow(...)
	local r, g, b = ColorPickerFrame:GetColorRGB()

	colorHue, colorSat, colorVal = RGB_to_HSV(r,g,b) -- store HSV values in our own variables

	MOD:ShowHideAlpha()

	MOD:UpdateOldColor(r,g,b,MOD:GetAlpha())
	MOD:UpdateColorGraphics()
	MOD:UpdateColorTexts()
	MOD:UpdateAlphaText()
end


function MOD:CleanUpColorPickerFrame()

	-- First, disable some standard Blizzard components
	ColorPickerWheel:Hide()
	ColorPickerFrame:GetColorWheelThumbTexture():Hide()
	ColorPickerFrame:GetColorValueTexture():Hide()
	ColorPickerFrame:GetColorValueThumbTexture():Hide()
	ColorSwatch:Hide()
	OpacitySliderFrame:Hide()

	-- Hide the "Color Picker" dialog title
	local children = { ColorPickerFrame:GetRegions() }
	for _, v in ipairs(children) do
		if v:IsObjectType("FontString") then
			if v:GetText() == COLOR_PICKER then v:Hide() end
		end
	end

	-- Add the "Color Picker Plus" dialog title
	if isClassic then
		local t = ColorPickerFrame:CreateFontString(ColorPPHeaderText)
		t:SetFontObject("GameFontNormal")
		t:SetText("Color Picker Plus")
		t:SetPoint("TOP", ColorPickerFrameHeader, "TOP", 0, -14)
	else
		ColorPickerFrame.Header:Hide()
		local h = CreateFrame('Frame', "ColorPPHeaderTitle", ColorPickerFrame, "DialogHeaderTemplate")
		local t = h:CreateFontString(nil, "ARTWORK")
		t:SetFontObject("GameFontNormal")
		t:SetText("Color Picker Plus")
		t:SetPoint("TOP", h, "TOP", 0, -14)
	end

	-- make the color picker movable.
	local mover = CreateFrame('Frame', nil, ColorPickerFrame)
	mover:SetPoint('TOPLEFT', ColorPickerFrame, 'TOP', -60, 0)
	mover:SetPoint('BOTTOMRIGHT', ColorPickerFrame, 'TOP', 60, -15)
	mover:EnableMouse(true)
	mover:SetScript('OnMouseDown', function() ColorPickerFrame:StartMoving() end)
	mover:SetScript('OnMouseUp', function() ColorPickerFrame:StopMovingOrSizing() end)
	mover:SetScript('OnHide', function() ColorPickerFrame:StopMovingOrSizing() end)
	ColorPickerFrame:SetUserPlaced(true)
	ColorPickerFrame:SetClampedToScreen(true)  -- keep color picker frame on-screen
	ColorPickerFrame:SetClampRectInsets(120,-120,0,90) -- but allow for dragging partially off to sides and down
	ColorPickerFrame:EnableKeyboard(false)

	-- make the Color Picker dialog a bit taller to accommodate new widget layout
	-- width must be handled in the onShow script
	ColorPickerFrame:SetHeight(dialogHeight)

end

function MOD:CreateCheckerboardBG (fr, dense, w, h)
	local t = fr:CreateTexture("ColorPPCheckerboard")
	t:SetSize(w, h)
	if dense then
		t:SetTexture("Interface\\AddOns\\ColorPickerPlus\\media\\checkerboard16")
	else
		t:SetTexture("Interface\\AddOns\\ColorPickerPlus\\media\\checkerboard8")
	end
	t:SetPoint("TOPLEFT", fr, "TOPLEFT", 0, 0)
	t:SetDrawLayer("Background", -3)
	return t
end

local function OldColorOnMouseUp (frame, button)
	if frame:IsMouseOver() and button == "LeftButton" then
		-- Set the chosen color to the old color
		local r, g, b, a = frame:GetBackdropColor()

		-- update color and opacity variables
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame.func()
		MOD:UpdateHSVfromColorPickerRGB()
		OpacitySliderFrame:SetValue(1-a)

		MOD:UpdateColorGraphics()
		MOD:UpdateColorTexts()
		MOD:UpdateAlphaText()
	end
end

local function ChosenColorOnMouseUp (frame, button)
	if frame:IsMouseOver() and button == "LeftButton" and IsControlKeyDown() then

		local r, g, b, a = frame:GetBackdropColor()

		-- print chosen color in [0-1] RGB to the chat window
		print("ColorPickerPlus color in [0-1] RGB: r = ", string.format("%.3f", r), " g = ", string.format("%.3f", g), " b = ", string.format("%.3f", b))

	end
end

function MOD:CreateColorSwatches()
	local fh = CreateFrame("Frame", "ColorPPSwatches", ColorPickerFrame)
	fh:SetSize(colorSwatchWidth, colorSwatchHeight)
	MOD:CreateCheckerboardBG (fh, true, colorSwatchWidth, colorSwatchHeight)
	fh:SetPoint("BOTTOM", ColorPPPaletteFrame, "BOTTOM", 0, 0)
	fh:SetPoint("LEFT", ColorPPBoxR, "LEFT", -14, 0)

	-- create frame for the old color that was passed in, to display color as its backdrop color
	local fr = CreateFrame("Frame", "ColorPPOldColor", fh, BackdropTemplateMixin and "BackdropTemplate")
	fr:SetBackdrop(bgtable)
	fr:SetFrameLevel(OpacitySliderFrame:GetFrameLevel())
	fr:SetSize(colorSwatchWidth,colorSwatchHeight*0.35)
	fr:ClearAllPoints()
	fr:SetPoint("TOPLEFT", fh, "TOPLEFT")
	fr:SetBackdropColor(0,0,0,1)
	fr:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	fr:SetScript("OnMouseUp", OldColorOnMouseUp)
	fr:Show()

	-- create frame for the chosen color for backdrop
	fr = CreateFrame("Frame", "ColorPPChosenColor", ColorPickerFrame, BackdropTemplateMixin and "BackdropTemplate")
	fr:SetBackdrop(bgtable)
	fr:SetSize(colorSwatchWidth,colorSwatchHeight*0.65)
	fr:ClearAllPoints()
	fr:SetPoint("TOPLEFT", ColorPPOldColor, "BOTTOMLEFT", 0, 0)
	fr:SetBackdropColor(0,0,0,1)
	fr:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	fr:SetScript("OnMouseUp", ChosenColorOnMouseUp)
	fr:Show()
end

function MOD:CreateCopyPasteArea()

	-- create frame for buttons and copiedColorSwatch
	fr = CreateFrame("Frame", "ColorPPCopyPasteArea", ColorPPPaletteFrame, BackdropTemplateMixin and "BackdropTemplate")
	fr:SetBackdrop(bgtable)
	fr:SetSize(gradientWidth-10, gradientHeight-10)
	fr:ClearAllPoints()
	fr:SetPoint ("CENTER", ColorPPPaletteFrame, "CENTER", 0, 0)
	fr:SetBackdropColor(0.4,0.4,0.4,0)
	fr:SetBackdropBorderColor(0.4, 0.4, 0.4, 0)
	fr:Show()

	-- Create copiedColorSwatch
	local f = CreateFrame("Frame", "ColorPPCopiedColor", fr, BackdropTemplateMixin and "BackdropTemplate")
	local x = colorSwatchHeight*0.65
	f:SetBackdrop(bgtable)
	f:SetBackdropColor(0,0,0,0)
	f:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
	f:SetSize(x, x)
	MOD:CreateCheckerboardBG(f, true, x, x)
	f:ClearAllPoints()
	f:SetPoint("LEFT", fr, "LEFT", 0, 0)
	f:SetPoint("BOTTOM", fr, "BOTTOM", 0, 0)

	-- create label for buffer swatch
--	local t = fr:CreateFontString(fr)
--	t:SetFontObject("GameFontNormal")
--	t:SetText("Buffer")
--	t:SetTextColor(0.5,0.5,0.5,1)
--	t:SetPoint("BOTTOM", ColorPPCopiedColor, "TOP", 0, 5)
--	t:Show()


	-- add copy button
	local b = CreateFrame("Button", "ColorPPCopy", fr, "UIPanelButtonTemplate")
	b:SetText("<-- Copy")
	b:SetWidth("80")
	b:SetHeight("22")
	b:SetScale(0.80)
	b:SetPoint("TOP", "ColorPPCopiedColor", "TOP", 0, -20)
	b:SetPoint("RIGHT", "ColorPPCopyPasteArea", "RIGHT", 0, 0)

	-- copy color into buffer on button click
	b:SetScript("OnClick", function(self)

		-- copy current dialog colors into buffer
		local r, g, b = ColorPickerFrame:GetColorRGB()
		local a = MOD:GetAlpha()

		ColorPPCopiedColor:SetBackdropColor(r,g,b,a)
		ColorPPPaste:Enable()
	end
	)


	-- add paste button to the ColorPickerFrame
	b = CreateFrame("Button", "ColorPPPaste", fr, "UIPanelButtonTemplate")
	b:SetText("Paste -->")
	b:SetWidth("80")
	b:SetHeight("22")
	b:SetScale(0.8)
	b:SetPoint("TOPRIGHT", "ColorPPCopy", "BOTTOMRIGHT", 0, -10)
	b:Disable()  -- enable when something has been copied

	-- paste color on button click, updating frame components
	b:SetScript("OnClick", function(self)
		local r, g, b, a = ColorPPCopiedColor:GetBackdropColor()

		-- update color and opacity variables
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame.func()
		MOD:UpdateHSVfromColorPickerRGB()
		OpacitySliderFrame:SetValue(1-a)

		MOD:UpdateColorGraphics()
		MOD:UpdateColorTexts()
		MOD:UpdateAlphaText()

	end)

end

local function PaletteSwatchOnMouseUp (frame, button)
	local r,g,b,a
	if (frame:IsMouseOver()) then
		if (button == "LeftButton") then
			if IsModifierKeyDown() then
				if IsShiftKeyDown() then   -- Set the swatch color to the chosen color
					r, g, b, a = ColorPPChosenColor:GetBackdropColor()
					frame:SetBackdropColor(r, g, b, a)
					local c = DB.palette[frame._cppKey]
					c.r = r; c.g = g; c.b = b; c.a = a
				end
			else	-- Set the chosen color to the swatch color
				r, g, b, a = frame:GetBackdropColor()

				ColorPickerFrame:SetColorRGB(r, g, b)
				ColorPickerFrame.func()
				MOD:UpdateHSVfromColorPickerRGB()
				OpacitySliderFrame:SetValue(1-a)

				MOD:UpdateColorGraphics()
				MOD:UpdateColorTexts()
				MOD:UpdateAlphaText()
			end
		end
	end
end

function MOD:CreatePalette()

	local rows = 6
	local cols = 6  -- set to work for square matrix currently
	local spacer = 2
	local margin = 0
	local swatchSize = 20

	-- create frame for palette
	fr = CreateFrame("Frame", "ColorPPPalette", ColorPPPaletteFrame, BackdropTemplateMixin and "BackdropTemplate")
	fr:SetBackdrop(bgtable)
	fr:SetSize((cols*swatchSize)+((cols-1)*spacer)+(2*margin), (rows*swatchSize)+((rows-1)*spacer)+(2*margin))
	fr:ClearAllPoints()
	fr:SetPoint ("CENTER", ColorPPPaletteFrame, "CENTER", 0, 0)
	fr:SetPoint ("BOTTOM", ColorPPPaletteFrame, "BOTTOM", 0, 0)
	fr:SetBackdropColor(0.4,0.4,0.4,0)
	fr:SetBackdropBorderColor(0.4, 0.4, 0.4, 0)
	fr:Show()

	-- Create Palette Swatches
	local i, j, k = 0, 0, 0
	for j = 1, rows do
		for i = 1, cols do
			k = k+1
			local c = DB.palette[k]
			local f = CreateFrame("Frame", "ColorPPswatch_"..tostring(k), fr, BackdropTemplateMixin and "BackdropTemplate")
			f._cppKey = k
			f:SetBackdrop(bgtable)
			f:SetBackdropColor(c.r,c.g,c.b,c.a)
			f:SetBackdropBorderColor(0, 0, 0, c.a)
			f:SetSize(swatchSize, swatchSize)
			MOD:CreateCheckerboardBG(f, false, swatchSize, swatchSize)
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", fr, "TOPLEFT", margin+(spacer*(i-1)) + ((i-1)*swatchSize), -(margin + (spacer*(j-1)) + ((j-1)*swatchSize)))
			f:SetScript("OnMouseUp", PaletteSwatchOnMouseUp)

		end
	end
end

local function ClassPaletteSwatchOnMouseUp (frame, button)
	local r,g,b,a
	if (frame:IsMouseOver()) then
		-- Set the chosen color to the swatch color
		r, g, b, a = frame:GetBackdropColor()

		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame.func()
		MOD:UpdateHSVfromColorPickerRGB()
		OpacitySliderFrame:SetValue(1-a)

		MOD:UpdateColorGraphics()
		MOD:UpdateColorTexts()
		MOD:UpdateAlphaText()

	end
end

function MOD:CreateClassPalette()

	local rows = 3
	local cols = 4
	local spacer = 2
	local margin = 0
	local swatchSize = 20

	-- create frame for palette
	fr = CreateFrame("Frame", "ColorPPClassPalette", ColorPPPaletteFrame, BackdropTemplateMixin and "BackdropTemplate")
	fr:SetBackdrop(bgtable)
	fr:SetSize((cols*swatchSize)+((cols-1)*spacer)+(2*margin), (rows*swatchSize)+((rows-1)*spacer)+(2*margin))
	fr:ClearAllPoints()
	fr:SetPoint ("CENTER", ColorPPPaletteFrame, "CENTER", 0, -5)
	fr:SetBackdropColor(0.4,0.4,0.4,0)
	fr:SetBackdropBorderColor(0.4, 0.4, 0.4, 0)
	fr:Show()

	-- create label for frame
	local t = fr:CreateFontString(fr)
	t:SetFontObject("GameFontNormal")
	t:SetText("Class Colors")
	t:SetTextColor(1,1,1,1)
	t:SetPoint("BOTTOM", fr, "TOP", 0, 5)
	t:Show()

	-- Create Palette Swatches
	local i, j, k = 0, 0, 0
	for j = 1, rows do
		for i = 1, cols do
			k = k+1
			local c = classColorPalette[k]
			local f = CreateFrame("Frame", "ColorPPswatch_"..tostring(k), fr, BackdropTemplateMixin and "BackdropTemplate")
			f._cppKey = k
			f:SetBackdrop(bgtable)
			f:SetBackdropColor(c.r,c.g,c.b,c.a)
			f:SetBackdropBorderColor(0, 0, 0, c.a)
			f:SetSize(swatchSize, swatchSize)
			MOD:CreateCheckerboardBG(f, false, swatchSize, swatchSize)
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", fr, "TOPLEFT", margin+(spacer*(i-1)) + ((i-1)*swatchSize), -(margin + (spacer*(j-1)) + ((j-1)*swatchSize)))
			f:SetScript("OnMouseUp", ClassPaletteSwatchOnMouseUp)

		end
	end
end



local function GradientOnMouseDown(self, button)
	if self:IsMouseOver() and IsMouseButtonDown(LeftButton) then
		if not (lockedHueBar or lockedOpacityBar) then
			lockedGradient = true
			if ColorPickerFrame.hasOpacity then lockedOpacity = 1-OpacitySliderFrame:GetValue() else lockedOpacity = 1 end
		end
	end
end

local function GradientOnUpdate(self)

	if IsMouseButtonDown(LeftButton) then

		if (lockedHueBar or lockedOpacityBar) then return end

		if lockedGradient then  -- begin to track motion, until button release

			local brightness, saturation

			-- Get the bounds of the frame and account for any Scale settings
			-- note that position is within 5 pixel border on each side
			local scale = ColorPickerFrame:GetScale()	-- We inherit scale from our "parent" the ColorPickerFrame
			local top = (self:GetTop() * scale) + 5
			local bottom = (self:GetBottom() * scale) - 5
			local left = (self:GetLeft() * scale) + 5
			local right = (self:GetRight()) * scale -5
			local height = top - bottom
			local width = right - left

			-- Get the cursor position and account for any UI Scale settings
			local uiscale = UIParent:GetEffectiveScale()
			local x, y = GetCursorPosition()
			x = x/uiscale
			y = y/uiscale

			local mousePosX = right - x
			local mousePosY = top - y

			if (y < bottom) then  colorVal = 0
			elseif (y > top) then colorVal = 1
			else
				colorVal = 1-(mousePosY / height)
				if colorVal < 0 then colorVal = 0 end
			end

			if (x < left) then colorSat = 0
			elseif (x > right) then colorSat = 1
			else
				colorSat = 1-(mousePosX / width)
				if colorSat < 0 then colorSat = 0 end
			end

			local r, g, b = HSV_to_RGB(colorHue, colorSat, colorVal)

			ColorPickerFrame:SetColorRGB(r, g, b)
			ColorPickerFrame.func()
			ColorPPChosenColor:SetBackdropColor(r,g,b,lockedOpacity)
			MOD:UpdateColorTexts()
			MOD:UpdateGradientThumb()

		end
	else
		lockedGradient = false
		lockedHueBar = false
		lockedOpacityBar = false
	end
end

function MOD:CreateColorGradient()  -- allows selection of saturation/value

	local f = CreateFrame("Frame", "ColorPPGradient", ColorPickerFrame)
	f:SetSize(gradientWidth, gradientHeight)
	f:SetPoint("TOPLEFT", ColorPPHueBar, "TOPRIGHT", spacing, 5)
	f:EnableMouse(true)
	f:SetScript("OnMouseDown", GradientOnMouseDown)
	f:SetScript("OnUpdate", GradientOnUpdate)

	-- add Color Gradient
	local t = f:CreateTexture("ColorPPGradientTexture")
	t:SetSize(gradientWidth-10, gradientHeight-10)
	t:SetTexture("Interface\\AddOns\\ColorPickerPlus\\media\\color_gradient")
	t:SetPoint("CENTER", ColorPPGradient, "CENTER", 0, 0)
	t:Show()

	-- add Color Overlay
	t = f:CreateTexture("ColorPPColorOverlay")
	t:SetSize(gradientWidth-10, gradientHeight-10)
	t:SetDrawLayer("OVERLAY", 0)
	t:SetTexture("Interface\\AddOns\\ColorPickerPlus\\media\\color_overlay")
	t:SetPoint("CENTER", ColorPPGradient, "CENTER", 0, 0)
	t:Show()

	-- add gradient thumb texture
	t = f:CreateTexture("ColorPPColorGradientThumb")
	t:SetSize(10, 10)
	t:SetDrawLayer("OVERLAY", 1)
	--t:SetTexture("Interface\\AddOns\\ColorPickerPlus\\media\\cursor2")
	t:SetTexture("Interface\\Buttons\\UI-ColorPicker-Buttons")
	t:SetTexCoord(0, 0.15625, 0, 0.625)
	t:SetPoint("CENTER", ColorPPGradientTexture, "CENTER", 0, 0)
	t:Show()

end


local function HueBarOnMouseDown(self, button)
	if self:IsMouseOver() and IsMouseButtonDown(LeftButton) then
		if not (lockedGradient or lockedOpacityBar) then
			lockedHueBar = true
			if ColorPickerFrame.hasOpacity then lockedOpacity = 1-OpacitySliderFrame:GetValue() else lockedOpacity = 1 end
			MOD:UpdateHueBarThumb()
		end
	end
end

local function HueBarOnUpdate(self)  -- it's actually the holder that receives this call

	if IsMouseButtonDown(LeftButton) then

		if (lockedGradient or lockedOpacityBar) then return end

		if lockedHueBar then  -- tracking mouse in or out of bar

			local fr = ColorPPHueBar

			-- Get the bounds of the frame and account for any Scale settings
			local scale = ColorPickerFrame:GetScale()
			local top = fr:GetTop() * scale
			local bottom = fr:GetBottom() * scale
			local left = fr:GetLeft() * scale
			local right = fr:GetRight() * scale
			local height = top - bottom

			-- Get the cursor position and account for any UI Scale settings
			local uiscale = UIParent:GetEffectiveScale()
			local x, y = GetCursorPosition()
			x = x / uiscale
			y = y / uiscale

			if (y < bottom) then  colorHue = 1
				elseif (y > top) then colorHue = 0
				else colorHue = (top-y) / height
			end

			local r, g, b = HSV_to_RGB(colorHue,colorSat,colorVal)
 			ColorPickerFrame:SetColorRGB(r, g, b)
			ColorPickerFrame.func()
			MOD:UpdateColorTexts()
			ColorPPChosenColor:SetBackdropColor(r, g, b, lockedOpacity)
			ColorPPColorOverlay:SetVertexColor(HSV_to_RGB(colorHue,1,1))
			MOD:UpdateHueBarThumb()

		end

	else
		lockedGradient = false
		lockedHueBar = false
		lockedOpacityBar = false
		return

	end

end

function MOD:CreateHueBar()

	local fh = CreateFrame("Frame", "ColorPPHueBarHolder", ColorPickerFrame)
	fh:SetSize(hueBarWidth+6, hueBarHeight+8)
	fh:SetPoint("TOPLEFT", ColorPickerFrame, "TOPLEFT", sideMargin, -topMargin)
	local f = CreateFrame("Frame", "ColorPPHueBar", fh)
	f:SetSize(hueBarWidth, hueBarHeight)
	f:SetPoint("CENTER", fh, "CENTER")
	fh:EnableMouse(true)
	fh:SetScript("OnUpdate", HueBarOnUpdate)
	fh:SetScript("OnMouseDown", HueBarOnMouseDown)

	local color = {
		{ r = 1.0, g = 0.0, b = 0.0 },	-- Red
		{ r = 1.0, g = 1.0, b = 0.0 },	-- Yellow
		{ r = 0.0, g = 1.0, b = 0.0 },	-- Green
		{ r = 0.0, g = 1.0, b = 1.0 },	-- Cyan
		{ r = 0.0, g = 0.0, b = 1.0 },	-- Blue
		{ r = 1.0, g = 0.0, b = 1.0 },	-- Purple
		{ r = 1.0, g = 0.0, b = 0.0 },	-- Red again
	}

	for i = 1, 6 do
		local t = f:CreateTexture("ColorPPHue"..tostring(i), ColorPPHueBar)
		if i == 1 then t:SetPoint("TOP", ColorPPHueBar, "TOP", 0, 0)
			else t:SetPoint("TOP", "ColorPPHue"..tostring(i-1), "BOTTOM", 0, 0) end
		t:SetSize(hueBarWidth, hueTextureSize)
		t:SetVertexColor(1.0, 1.0, 1.0, 1.0)
		t:SetColorTexture(1.0, 1.0, 1.0, 1.0)
		t:SetGradient("VERTICAL",  color[i+1].r, color[i+1].g, color[i+1].b, color[i].r, color[i].g, color[i].b )
	end

	-- Thumb indicates value position on the slider
	local thumb = f:CreateTexture("ColorPPHueBarThumb", fh)
	thumb:SetTexture("Interface\\AddOns\\ColorPickerPlus\\Media\\SliderVBar.tga", false)
	thumb:SetDrawLayer("OVERLAY")
	thumb:SetSize(hueBarWidth+6, 8)

end


local function OpacityBarOnMouseDown(self, button)
	if (self:IsMouseOver() and IsMouseButtonDown(LeftButton)) then
		if not (lockedHueBar or lockedGradient) then
			lockedOpacityBar = true
			MOD:UpdateOpacityBarThumb()
		end
	end
end

local function OpacityBarOnUpdate(self)

	if IsMouseButtonDown(LeftButton) then
		if (lockedGradient or lockedHueBar) then return end
		if lockedOpacityBar then  -- tracking mouse in or out of bar

			-- Get the bounds of the frame and account for any Scale settings
			local scale = ColorPickerFrame:GetScale()	-- We inherit scale from our "parent" the ColorPickerFrame
			local top = self:GetTop() * scale
			local bottom = self:GetBottom() * scale
			local left = self:GetLeft() * scale
			local right = self:GetRight() * scale
			local height = top - bottom

			-- Get the cursor position and account for any UI Scale settings
			local uiscale = UIParent:GetEffectiveScale()
			local x, y = GetCursorPosition()
			x = x / uiscale
			y = y / uiscale

			local a
		    if (y < bottom) then  a = 0
				elseif (y > top) then a = 1
				else
					a = 1-((top-y) / height)
			end

		OpacitySliderFrame:SetValue(a)  -- blizzard reverse alpha
		MOD:UpdateAlphaText()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		ColorPPChosenColor:SetBackdropColor(r, g, b, 1-a)
		end
	else
		lockedGradient = false
		lockedHueBar = false
		lockedOpacityBar = false
		return
	 end
end

function MOD:CreateOpacityBar()

	local f = CreateFrame("Frame", "ColorPPOpacityBar", ColorPickerFrame)
	f:SetSize(opacityBarWidth, opacityBarHeight)
	f:SetPoint("TOP", ColorPickerFrame, "TOP", 0, -topMargin)
	f:EnableMouse(true)
	f:SetScript("OnUpdate", OpacityBarOnUpdate)
	f:SetScript("OnMouseDown", OpacityBarOnMouseDown)


	local t = f:CreateTexture("ColorPPOpacityBarBG", f)
	t:SetPoint("TOP", ColorPPOpacityBar, "TOP", 0, 0)
	t:SetSize(opacityBarWidth, opacityBarHeight)
	t:SetVertexColor(1.0, 1.0, 1.0, 1.0)
	t:SetColorTexture(1.0, 1.0, 1.0, 1.0)
	t:SetGradient("VERTICAL",  1, 1, 1, 0, 0, 0 )

 	-- Thumb indicates value position on the slider
	local thumb = f:CreateTexture("ColorPPOpacityBarThumb", f)
	thumb:SetTexture("Interface\\AddOns\\ColorPickerPlus\\Media\\SliderVBar.tga", false)
	--thumb:SetTexture("Interface\\AddOns\\ColorPickerPlus\\Media\\ThinVSlider2.tga", false)
	thumb:SetSize(opacityBarWidth+6, 8)
	thumb:SetDrawLayer("OVERLAY", 4)
	thumb:SetPoint("CENTER", f, "CENTER", 0, 0)

	f:ClearAllPoints()
	f:SetPoint("TOP", ColorPPHueBar, "TOP", 0, 0)
	f:SetPoint("RIGHT", "ColorPickerFrame", "RIGHT", -sideMargin, 0)
end

function MOD:CreateTextBoxes()
	-- set up edit box frames and interior label and text areas
	local boxes = { "R", "G", "B", "X", "H", "S", "V", "A"}
	for i = 1, table.getn(boxes) do

		local rgb = boxes[i]
		--local box = CreateFrame("EditBox", "ColorPPBox"..rgb, ColorPickerFrame, "InputBoxTemplate")
		local box = CreateFrame("EditBox", "ColorPPBox"..rgb, ColorPickerFrame, BackdropTemplateMixin and "BackdropTemplate")
		box:SetBackdrop(bgtable)
		box:SetBackdropColor(0.1,0.1,0.1,0.7)
		box:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.7)
		box:SetFontObject("GameFontNormal")
		box:SetTextColor(1,1,1,1)
		box:SetID(i)
		box:SetFrameStrata("DIALOG")
		box:SetAutoFocus(false)
		box:SetTextInsets(0,5,0,0)
		box:SetJustifyH("RIGHT")
		box:SetHeight(16)

		if i == 4 then
			-- Hex entry box
			box:SetMaxLetters(6)
			box:SetWidth(60)
			box:SetNumeric(false)
		else
			box:SetMaxLetters(3)
			box:SetWidth(38)
			box:SetNumeric(true)
		end

		-- label
		local label = box:CreateFontString("ColorPPBoxLabel"..rgb, "ARTWORK", "GameFontNormalSmall")
		label:SetTextColor(1, 1, 1, 1)
		label:SetPoint("LEFT", "ColorPPBox"..rgb, "LEFT", -14, 0)
		if i == 4 then label:SetText("#") else label:SetText(rgb) end

		-- set up scripts to handle event appropriately
		if i == 8 then
			box:SetScript("OnTextChanged", function(self, userInput) MOD:AlphaTextChanged(self, userInput) end)
		elseif i < 4 then
			box:SetScript("OnTextChanged", function(self, userInput) MOD:RGBTextChanged(self, userInput) end)
		elseif i == 4 then
			box:SetScript("OnTextChanged", function(self, userInput) MOD:HexTextChanged(self, userInput) end)
		else
			box:SetScript("OnTextChanged", function(self, userInput) MOD:HSVTextChanged(self, userInput) end)
		end

		box:SetScript("OnEditFocusGained", function(self) self:SetCursorPosition(0) self:HighlightText() end)
		box:SetScript("OnEditFocusLost", function(self)	self:HighlightText(0,0) end)
		box:SetScript("OnTextSet", function(self) self:ClearFocus() end)	-- otherwise cursor left blinking
		box:Show()
	end

	-- finish up with vertical placement
	ColorPPBoxR:SetPoint("TOPLEFT", "ColorPPGradient", "TOPRIGHT", spacing*2, -5)
	ColorPPBoxG:SetPoint("TOPLEFT", "ColorPPBoxR", "BOTTOMLEFT", 0, -2)
	ColorPPBoxB:SetPoint("TOPLEFT", "ColorPPBoxG", "BOTTOMLEFT", 0, -2)
	ColorPPBoxX:SetPoint("TOPLEFT", "ColorPPBoxB", "BOTTOMLEFT", 0, -10)

	ColorPPBoxV:SetPoint("BOTTOMLEFT", "ColorPPGradient", "BOTTOMRIGHT", spacing*2, 5)
	ColorPPBoxS:SetPoint("BOTTOMLEFT", "ColorPPBoxV", "TOPLEFT", 0, 2)
	ColorPPBoxH:SetPoint("BOTTOMLEFT", "ColorPPBoxS", "TOPLEFT", 0, 2)

	ColorPPBoxA:ClearAllPoints()
	ColorPPBoxA:SetPoint("RIGHT", ColorPPOpacityBar, "LEFT", -spacing, 0)
	ColorPPBoxA:SetPoint("TOP", ColorPPBoxR, "TOP")

		-- define the order of tab cursor movement
	ColorPPBoxR:SetScript("OnTabPressed", function(self) ColorPPBoxG:SetFocus() end)
	ColorPPBoxG:SetScript("OnTabPressed", function(self) ColorPPBoxB:SetFocus()  end)
	ColorPPBoxB:SetScript("OnTabPressed", function(self) ColorPPBoxR:SetFocus()  end)

		-- define the order of tab cursor movement
	ColorPPBoxH:SetScript("OnTabPressed", function(self) ColorPPBoxS:SetFocus() end)
	ColorPPBoxS:SetScript("OnTabPressed", function(self) ColorPPBoxV:SetFocus()  end)
	ColorPPBoxV:SetScript("OnTabPressed", function(self) ColorPPBoxH:SetFocus()  end)
end


local function ColorPPTooltipShow(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddDoubleLine("Color Picker Plus")
	GameTooltip:AddDoubleLine("Press @ button to cycle between palettes")
	GameTooltip:AddLine(" ")
	if ColorPPCopyPasteArea:IsVisible() then
		GameTooltip:AddLine("Copy into or paste from buffer")
	else
		GameTooltip:AddLine("Left click on palette to use palette color")
		if ColorPPPalette:IsVisible() then
			GameTooltip:AddLine("Shift left click on palette to save color to palette")
		end
	end
	--GameToolTip:AddLine("Left click on old color to reset current color")
	GameTooltip:Show()
end

local function ColorPPTooltipHide(self)
	GameTooltip:Hide()
end

function MOD:CreateHelpFrame()
	local fr = CreateFrame("Frame", "ColorPPHelp", ColorPickerFrame)
	fr:SetFrameLevel(OpacitySliderFrame:GetFrameLevel())
	fr:SetSize(hueBarWidth,hueBarWidth)
	fr:ClearAllPoints()
	fr:SetPoint("TOPLEFT", ColorPPHueBar, "BOTTOMLEFT", 0, -spacing)
	fs = fr:CreateFontString("ColorPPQM")
	fs:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
	fs:SetText("?")
	fs:ClearAllPoints()
	fs:SetPoint("CENTER", "ColorPPHelp", "CENTER")
	fr:SetScript("OnEnter", ColorPPTooltipShow)
	fr:SetScript("OnLeave", ColorPPTooltipHide)
	fs:Show()
	fr:Show()
end

function MOD:CreatePaletteFrame()  -- sits below the color gradient box, holds various palettes
	local fr = CreateFrame("Frame", "ColorPPPaletteFrame", ColorPickerFrame)
	fr:SetSize(gradientWidth-10, gradientHeight -10)
	fr:SetPoint("CENTER", ColorPPGradient, "CENTER", 0, 0)
	fr:SetPoint("BOTTOM", ColorPPHueBar, "BOTTOM", 0, 0)
end

local function ColorPPSwitchPalettes(self)
	-- 0 - full palette, 1 - class color palette, 2 - copy/paste area
	if DB.paletteState == 0 then
		ColorPPPalette:Hide()
		ColorPPClassPalette:Show()
		DB.paletteState = 1
	elseif DB.paletteState == 1 then
		ColorPPClassPalette:Hide()
		ColorPPCopyPasteArea:Show()
		-- show copy/paste stuff here
		DB.paletteState = 2
	else  -- DB.paletteState == 2
		ColorPPCopyPasteArea:Hide()
		ColorPPPalette:Show()
		DB.paletteState = 0
	end
end

function MOD:CreatePaletteSwitcher()
	-- add copy button to the ColorPickerFrame
	local b = CreateFrame("Button", "ColorPPSwitcher", ColorPickerFrame, "UIPanelButtonTemplate", BackdropTemplateMixin and "BackdropTemplate")
	b:SetText("@")
	local f = b:GetFontString()
	f:SetTextColor(1,1,1,1)
	b:SetWidth("24")
	b:SetHeight("24")
	b:SetScale(0.80)
	b:SetPoint("BOTTOMLEFT", "ColorPPHelp", "BOTTOMRIGHT", 5, 0)

	b:SetScript("OnClick", ColorPPSwitchPalettes)
end


function MOD:Initialize_UI()
	MOD:CleanUpColorPickerFrame()
	MOD:CreateHueBar()
	MOD:CreateColorGradient()
	MOD:CreatePaletteFrame()
	MOD:CreatePalette()
	MOD:CreateClassPalette()
	MOD:CreateCopyPasteArea()
	if DB.paletteState == 0 then
	   ColorPPClassPalette:Hide()
	   ColorPPCopyPasteArea:Hide()
	elseif DB.paletteState == 1 then
	   ColorPPPalette:Hide()
	   ColorPPCopyPasteArea:Hide()
	else  -- DB.paletteState == 2
		ColorPPPalette:Hide()
		ColorPPClassPalette:Hide()
	end
	-- print ("on initialization, ps= ", DB.paletteState)
	MOD:CreateOpacityBar()
	MOD:CreateTextBoxes()
	MOD:CreateColorSwatches()
	MOD:CreateHelpFrame()
	MOD:CreatePaletteSwitcher()

end

function MOD.PLAYER_LOGIN()
	ColorPickerFrame:HookScript("OnShow", function(...) MOD:Hooked_OnShow(...) end)
	MOD:Initialize_UI()
	ColorPickerFrame:UnregisterEvent("PLAYER_LOGIN")  --so initialization only happens once
end

function MOD:RGBTextChanged(tbox, userInput)

	if not userInput then return end

	local r, g, b = ColorPickerFrame:GetColorRGB()
	local sr, sg, sb = r, g, b -- save values for recovery after bad entry

	local id = tbox:GetID()
	if id == 1 then
		r = tbox:GetNumber()
		if not r then r = 0 end
		if r > 255 then tbox:SetText(string.format("%d", floor(sr*255))) return end
		r = r/255
	elseif id == 2 then
		g = tbox:GetNumber()
		if not g then g = 0 end
		if g > 255 then tbox:SetText(string.format("%d", floor(sg*255))) return end
		g = g/255
	elseif id == 3 then
		b = tbox:GetNumber()
		if not b then b = 0 end
		if b > 255 then tbox:SetText(string.format("%d", floor(sb*255))) return end
		b = b/255
	else return end


	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorPickerFrame.func()
	MOD:UpdateHSVfromColorPickerRGB()
	MOD:UpdateColorGraphics()
	MOD:UpdateHSVTexts()
	MOD:UpdateHexText()

end

function MOD:HexTextChanged(tbox, userInput)

	if not userInput then return end

	local r, g, b = ColorPickerFrame:GetColorRGB()
	local sr, sg, sb = r, g, b -- save values for recovery after bad entry

	if tbox:GetNumLetters() == 6 then
			local rgb = tbox:GetText()
			r, g, b = tonumber('0x'..strsub(rgb, 0, 2)), tonumber('0x'..strsub(rgb, 3, 4)), tonumber('0x'..strsub(rgb, 5, 6))
			if not r then r = 0 else r = r/255 end
			if not g then g = 0 else g = g/255 end
			if not b then b = 0 else b = b/255 end
	else return	end

	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorPickerFrame.func()
	MOD:UpdateHSVfromColorPickerRGB()
	MOD:UpdateColorGraphics()
	MOD:UpdateHSVTexts()
	MOD:UpdateRGBTexts()

end

function MOD:HSVTextChanged(tbox, userInput)

	if not userInput then return end

	local h, s, v = colorHue, colorSat, colorVal

	local id = tbox:GetID()
	if id == 5 then
		h = tbox:GetNumber()
		if not h then h = 0 end
		if h > 360 then tbox:SetText(string.format("%d", floor(colorHue*360))) return end
		h = h/360
	elseif id == 6 then
		s = tbox:GetNumber()
		if not s then s = 0 end
		if s > 100 then tbox:SetText(string.format("%d", floor(colorSat*100))) return end
		s = s/100
	elseif id == 7 then
		v = tbox:GetNumber()
		if not v then v = 0 end
		if v > 100 then tbox:SetText(string.format("%d", floor(colorVal*100))) return end
		v = v/100
	else return	end

	colorHue, colorSat, colorVal = h, s, v
	local r, g, b = HSV_to_RGB(h,s,v)
	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorPickerFrame.func()
	MOD:UpdateColorGraphics()
	MOD:UpdateRGBTexts()
	MOD:UpdateHexText()

end

function MOD:UpdateColorTexts()
	MOD:UpdateRGBTexts()
	MOD:UpdateHexText()
	MOD:UpdateHSVTexts()
end

function MOD:UpdateHSVTexts(h, s, v)
	if not h then h, s, v = colorHue, colorSat, colorVal end

	h = math.floor (h*360 + 0.5)
	s = math.floor (s*100 + 0.5)
	v = math.floor (v*100 + 0.5)

    ColorPPBoxH:SetText(string.format("%d", h))
    ColorPPBoxS:SetText(string.format("%d", s))
    ColorPPBoxV:SetText(string.format("%d", v))
end

function MOD:UpdateRGBTexts(r, g, b)
	if not r then r, g, b = ColorPickerFrame:GetColorRGB() end

	r = math.floor (r*255 + 0.5)
	g = math.floor (g*255 + 0.5)
	b = math.floor (b*255 + 0.5)

    ColorPPBoxR:SetText(string.format("%d", r))
    ColorPPBoxG:SetText(string.format("%d", g))
    ColorPPBoxB:SetText(string.format("%d", b))
end

function MOD:UpdateHexText(r, g, b)
	if not r then r, g, b = ColorPickerFrame:GetColorRGB() end

	r = math.floor (r*255 + 0.5)
	g = math.floor (g*255 + 0.5)
	b = math.floor (b*255 + 0.5)

	ColorPPBoxX:SetText(string.format("%.2x", r)..string.format("%.2x",g)..string.format("%.2x", b))
end

function MOD:AlphaTextChanged(tbox, userInput)
	if not userInput then return end -- we take care of updating elsewhere
	local a = tbox:GetNumber()
	if a > 100 then
		a = 100
		ColorPPBoxA:SetText(string.format("%d", a))
	end
	a = a / 100
	OpacitySliderFrame:SetValue(1-a)
	ColorPickerFrame.func()
	MOD:UpdateOpacityBarThumb()
	MOD:UpdateChosenColor()
end

function MOD:UpdateAlphaText()
	local a = OpacitySliderFrame:GetValue()   -- still keeping value OpacitySliderFrame, to coordinate with WoW settings
	a = (1- a) * 100                          -- alpha value is reversed
	a = math.floor(a +.05)
	ColorPPBoxA:SetText(string.format("%d", a))
	MOD:UpdateOpacityBarThumb()
end
