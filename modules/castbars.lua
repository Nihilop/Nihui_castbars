-- Nihui CastBars - CastBar Module (adapted from rnxmUI)
local addonName, ns = ...

local CastBars = {}
ns.modules.castbars = CastBars

-- Debug mode variables
local debugTimer = nil
local debugSpells = {
    {name = "Fireball", texture = "Interface\\Icons\\Spell_Fire_FlameBolt", duration = 2.5, type = "cast"},
    {name = "Heal", texture = "Interface\\Icons\\Spell_Holy_Heal", duration = 3.0, type = "cast"},
    {name = "Arcane Missiles", texture = "Interface\\Icons\\Spell_Nature_StarFall", duration = 5.0, type = "channel"},
    {name = "Greater Heal", texture = "Interface\\Icons\\Spell_Holy_GreaterHeal", duration = 3.5, type = "cast"},
    {name = "Drain Life", texture = "Interface\\Icons\\Spell_Shadow_LifeDrain02", duration = 4.0, type = "channel"}
}

-- MASKING SYSTEM (adapted from rnxmUI)
function CastBars.CreateMask(parent, width, height, maskTexture)
    if not parent then return end

    local maskFrame = CreateFrame("Frame", nil, parent)
    maskFrame:SetSize(width, height)
    maskFrame:SetAllPoints(parent)

    local mask = maskFrame:CreateMaskTexture()
    mask:SetTexture(maskTexture or "Interface\\AddOns\\Nihui_cb\\textures\\UIUnitFramePlayerHealthMask2x.tga")
    mask:SetAllPoints(maskFrame)

    return mask
end

function CastBars.ApplyMaskToStatusBar(statusBar, mask)
    if not statusBar or not mask then return end

    local statusBarTexture = statusBar:GetStatusBarTexture()
    if statusBarTexture then
        statusBarTexture:AddMaskTexture(mask)
    end

    if statusBar.bg then
        statusBar.bg:AddMaskTexture(mask)
    end

    statusBar.appliedMask = mask
end

function CastBars.SetCastBarMask(castBar, maskTexture)
    if not castBar then return end

    local width = castBar:GetWidth()
    local height = castBar:GetHeight()

    local mask = CastBars.CreateMask(castBar, width, height, maskTexture)
    if mask then
        CastBars.ApplyMaskToStatusBar(castBar, mask)
        castBar.mask = mask
    end

    -- Apply mask to interrupt holder
    if castBar.interruptHolder then
        local holderMask = CastBars.CreateMask(castBar.interruptHolder, width, height, maskTexture)
        if holderMask then
            CastBars.ApplyMaskToStatusBar(castBar.interruptHolder, holderMask)
            castBar.interruptHolder.mask = holderMask
        end
    end
end

-- CREATE CASTBAR FUNCTION (adapted from rnxmUI)
function CastBars.CreateCastBar(parent, unit, options)
    if not unit then return end

    options = options or {}
    local settings = ns.castBarSettings()
    local unitSettings = settings[unit] or {}

    local width = options.width or unitSettings.width or 125
    local height = options.height or unitSettings.height or 18

    -- For player: free positioning, for others: relative to their parent frame
    local point, relativeTo, relativePoint, xOffset, yOffset, movable, frameParent

    if unit == "player" then
        -- Player castbar is free-positioned
        point = unitSettings.point or "BOTTOM"
        relativeTo = _G[unitSettings.relativeTo] or UIParent
        relativePoint = unitSettings.relativePoint or "BOTTOM"
        xOffset = unitSettings.xOffset or 0
        yOffset = unitSettings.yOffset or 150
        movable = unitSettings.movable ~= false
        frameParent = UIParent
    else
        -- Target/Focus castbars are relative to their unit frames
        point = "BOTTOM"
        relativeTo = parent or (unit == "target" and TargetFrame) or (unit == "focus" and FocusFrame)
        relativePoint = "BOTTOM"
        xOffset = unitSettings.xOffset or 0
        yOffset = unitSettings.yOffset or -20
        movable = false -- Don't make target/focus movable, they follow their frames
        frameParent = relativeTo
    end

    local showIcon = options.showIcon ~= false and unitSettings.showIcon ~= false
    local showText = options.showText ~= false and unitSettings.showText ~= false
    local showTimer = options.showTimer ~= false and unitSettings.showTimer ~= false

    -- Create main cast bar frame
    local castBar = CreateFrame("StatusBar", "NihuiCastBar" .. unit:gsub("^%l", string.upper), frameParent)
    castBar:SetSize(width, height)
    castBar:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    castBar:Hide()

    -- Make movable if enabled
    if movable then
        castBar:SetMovable(true)
        castBar:EnableMouse(true)
        castBar:RegisterForDrag("LeftButton")
        castBar:SetScript("OnDragStart", function(self)
            if IsAltKeyDown() then
                self:StartMoving()
            end
        end)
        castBar:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save new position
            local point, relativeTo, relativePoint, x, y = self:GetPoint()
            local settings = ns.castBarSettings()
            if settings[unit] then
                settings[unit].point = point
                settings[unit].relativeTo = relativeTo and relativeTo:GetName() or "UIParent"
                settings[unit].relativePoint = relativePoint
                settings[unit].xOffset = x
                settings[unit].yOffset = y
            end
        end)

        -- Add visual indicator when movable
        castBar:SetScript("OnEnter", function(self)
            if IsAltKeyDown() then
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:SetText("Alt + Drag to move", 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        castBar:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- Apply mask to both castbar and interrupt holder
    local maskTexture = unitSettings.mask or "Interface\\AddOns\\Nihui_cb\\textures\\UIUnitFramePlayerHealthMask2x.tga"
    CastBars.SetCastBarMask(castBar, maskTexture)

    -- Store references
    castBar.unit = unit
    castBar.options = options
    -- Store original position for taint-safe interrupt positioning
    castBar.originalPoint = {point, relativeTo, relativePoint, xOffset, yOffset}

    -- Create background
    local bg = castBar:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\MirroredFrameSingleBG.tga")
    bg:SetAllPoints(castBar)
    bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    castBar.bg = bg

    -- Create border with backdrop
    local border = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", castBar, "TOPLEFT", -12, 12)
    border:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 12, -12)
    border:SetBackdrop({
        edgeFile = "Interface\\AddOns\\Nihui_cb\\textures\\MirroredFrameSingle2.tga",
        edgeSize = 16,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    castBar.border = border

    -- Progress overlay
    local progressOverlay = border:CreateTexture(nil, "OVERLAY", nil, 5)
    progressOverlay:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\powerHL1.tga")
    progressOverlay:SetSize(width * 1.1, height * 2)
    progressOverlay:SetPoint("CENTER", castBar, "CENTER")
    progressOverlay:SetBlendMode("ADD")
    progressOverlay:SetAlpha(0)
    progressOverlay:Hide()
    castBar.progressOverlay = progressOverlay

    -- Create spark
    local spark = border:CreateTexture(nil, "OVERLAY", nil, 6)
    spark:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\orangespark.tga")
    spark:SetSize(20, height * 1.58)
    spark:SetBlendMode("ADD")
    spark:Hide()
    castBar.spark = spark

    -- Create completion flash
    local completionFlash = border:CreateTexture(nil, "OVERLAY", nil, 3)
    completionFlash:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\powerhl1.tga")
    completionFlash:SetSize(width * 1.1, height * 2)
    completionFlash:SetPoint("CENTER", castBar, "CENTER")
    completionFlash:SetBlendMode("ADD")
    completionFlash:Hide()
    castBar.completionFlash = completionFlash

    -- Create interrupt holder (like rnxmUI)
    local interruptHolder = CreateFrame("StatusBar", nil, frameParent)
    interruptHolder:SetSize(width, height)
    interruptHolder:SetPoint("CENTER", castBar, "CENTER")
    interruptHolder:SetMinMaxValues(0, 1)
    interruptHolder:SetValue(0)
    interruptHolder:Hide()
    castBar.interruptHolder = interruptHolder

    -- Interrupt holder background
    local holderBg = interruptHolder:CreateTexture(nil, "BACKGROUND")
    holderBg:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\MirroredFrameSingleBG.tga")
    holderBg:SetAllPoints(interruptHolder)
    holderBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    interruptHolder.bg = holderBg

    -- Interrupt holder border
    local holderBorder = CreateFrame("Frame", nil, interruptHolder, "BackdropTemplate")
    holderBorder:SetPoint("TOPLEFT", interruptHolder, "TOPLEFT", -12, 12)
    holderBorder:SetPoint("BOTTOMRIGHT", interruptHolder, "BOTTOMRIGHT", 12, -12)
    holderBorder:SetBackdrop({
        edgeFile = "Interface\\AddOns\\Nihui_cb\\textures\\MirroredFrameSingle2.tga",
        edgeSize = 16,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    holderBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    interruptHolder.border = holderBorder

    -- Red statusbar texture for interrupt
    interruptHolder:SetStatusBarTexture("Interface\\AddOns\\Nihui_cb\\textures\\MirroredFrameSingleBG.tga")

    -- Interrupt text
    if showText then
        local holderText = interruptHolder:CreateFontString(nil, "OVERLAY")
        holderText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        holderText:SetPoint("CENTER", interruptHolder, "CENTER", 0, 0)
        holderText:SetTextColor(1, 1, 1, 1)
        holderText:SetShadowOffset(1, -1)
        holderText:SetShadowColor(0, 0, 0, 0.8)
        interruptHolder.text = holderText
    end

    -- Interrupt icon
    if showIcon then
        local holderIcon = interruptHolder:CreateTexture(nil, "OVERLAY", nil, 2)
        holderIcon:SetSize(height + 4, height + 4)
        if unit == "player" then
            holderIcon:SetPoint("LEFT", holderBorder, "RIGHT", -4, 0)
        else
            holderIcon:SetPoint("RIGHT", holderBorder, "LEFT", 4, 0)
        end
        holderIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        interruptHolder.icon = holderIcon
    end

    -- Interrupt holder spark
    local holderSpark = interruptHolder:CreateTexture(nil, "OVERLAY", nil, 6)
    holderSpark:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\orangespark.tga")
    holderSpark:SetSize(20, height * 1.58)
    holderSpark:SetBlendMode("ADD")
    holderSpark:Hide()
    interruptHolder.spark = holderSpark

    -- Create interrupt glow like rnxmUI
    local holderInterruptGlow = holderBorder:CreateTexture(nil, "OVERLAY", nil, 6)
    holderInterruptGlow:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\powerhl1")
    holderInterruptGlow:SetSize(width * 1.1, height * 2)
    holderInterruptGlow:SetPoint("CENTER", holderBorder, "CENTER")
    holderInterruptGlow:SetVertexColor(1, 0, 0, 1)
    holderInterruptGlow:SetBlendMode("ADD")
    holderInterruptGlow:Hide()
    interruptHolder.interruptGlow = holderInterruptGlow

    -- Create icon
    if showIcon then
        local icon = border:CreateTexture(nil, "OVERLAY", nil, 2)
        icon:SetSize(height + 4, height + 4)
        if unit == "player" then
            icon:SetPoint("LEFT", border, "RIGHT", -4, 0)
        else
            icon:SetPoint("RIGHT", border, "LEFT", 4, 0)
        end
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        castBar.icon = icon

        -- Create icon background
        local iconBackground = border:CreateTexture(nil, "OVERLAY", nil, 3)
        iconBackground:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\castshield0.tga")
        iconBackground:SetSize(height + 2, height + 2)
        iconBackground:SetPoint("CENTER", icon, "CENTER", -7.5, -7.5)
        iconBackground:Hide()
        castBar.iconBackground = iconBackground

        -- Create icon border
        local iconBorder = border:CreateTexture(nil, "OVERLAY", nil, 2)
        iconBorder:SetAtlas("newplayertutorial-drag-slotblue")
        iconBorder:SetSize(height * 2.5, height * 2.5)
        iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
        iconBorder:SetDesaturated(true)
        iconBorder:SetBlendMode("ADD")
        castBar.iconBorder = iconBorder

        -- Create lock icon for non-interruptible spells
        local lockIcon = border:CreateTexture(nil, "OVERLAY", nil, 4)
        lockIcon:SetAtlas("common-icon-forbidenredalert")  -- Lock/forbidden icon
        lockIcon:SetSize(height * 0.6, height * 0.6)
        lockIcon:SetPoint("LEFT", castBar, "LEFT", 8, 0)  -- Position on left side of castbar
        lockIcon:SetVertexColor(1, 1, 1, 0.9)
        lockIcon:Hide()  -- Hidden by default
        castBar.lockIcon = lockIcon
    else
        -- Create lock icon even if regular icon is disabled
        local lockIcon = border:CreateTexture(nil, "OVERLAY", nil, 4)
        lockIcon:SetAtlas("common-icon-forbidenredalert")  -- Lock/forbidden icon
        lockIcon:SetSize(height * 0.6, height * 0.6)
        lockIcon:SetPoint("LEFT", castBar, "LEFT", 8, 0)  -- Position on left side of castbar
        lockIcon:SetVertexColor(1, 1, 1, 0.9)
        lockIcon:Hide()  -- Hidden by default
        castBar.lockIcon = lockIcon
    end

    -- Create text
    if showText then
        local text = castBar:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        text:SetPoint("TOP", castBar, "BOTTOM", 0, -2.5)
        text:SetTextColor(1, 1, 1, 1)
        text:SetShadowColor(0.4, 0.4, 0.4, 1)
        text:SetShadowOffset(2, -2)
        castBar.text = text
    end

    -- Create timer
    if showTimer then
        local timer = castBar:CreateFontString(nil, "OVERLAY")
        timer:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        timer:SetPoint("RIGHT", castBar, "RIGHT", -5, 0)
        timer:SetTextColor(1, 1, 1, 1)
        timer:SetShadowColor(0.4, 0.4, 0.4, 1)
        timer:SetShadowOffset(2, -2)
        castBar.timer = timer
    end

    -- CREATE INTERRUPT HOLDER
    local interruptHolder = CreateFrame("StatusBar", nil, frameParent)
    interruptHolder:SetSize(width, height)
    interruptHolder:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    interruptHolder:SetMinMaxValues(0, 1)
    interruptHolder:SetValue(0)
    interruptHolder:Hide()
    castBar.interruptHolder = interruptHolder

    -- Setup interrupt holder components
    local holderBg = interruptHolder:CreateTexture(nil, "BACKGROUND")
    holderBg:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\MirroredFrameSingleBG.tga")
    holderBg:SetAllPoints(interruptHolder)
    holderBg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    interruptHolder.bg = holderBg

    local holderBorder = CreateFrame("Frame", nil, interruptHolder, "BackdropTemplate")
    holderBorder:SetPoint("TOPLEFT", interruptHolder, "TOPLEFT", -12, 12)
    holderBorder:SetPoint("BOTTOMRIGHT", interruptHolder, "BOTTOMRIGHT", 12, -12)
    holderBorder:SetBackdrop({
        edgeFile = "Interface\\AddOns\\Nihui_cb\\textures\\MirroredFrameSingle2.tga",
        edgeSize = 16,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    holderBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    interruptHolder.border = holderBorder

    interruptHolder:SetStatusBarTexture("Interface\\AddOns\\Nihui_cb\\textures\\WSRed.tga")

    -- Interrupt holder text
    if showText then
        local holderText = interruptHolder:CreateFontString(nil, "OVERLAY")
        holderText:SetFont("Fonts\\FRIZQT__.TTF", 12, "SHADOW")
        holderText:SetPoint("TOP", interruptHolder, "BOTTOM", 3, -2.5)
        holderText:SetTextColor(1, 0.5, 0.5, 1)
        holderText:SetShadowColor(0.4, 0.1, 0.1)
        holderText:SetShadowOffset(2, -2)
        interruptHolder.text = holderText
    end

    -- Interrupt holder icon
    if showIcon then
        local holderIcon = interruptHolder:CreateTexture(nil, "ARTWORK", nil, 1)
        holderIcon:SetSize(height + 4, height + 4)
        holderIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        if unit == "player" then
            holderIcon:SetPoint("LEFT", holderBorder, "RIGHT", -4, 0)
        else
            holderIcon:SetPoint("RIGHT", holderBorder, "LEFT", 4, 0)
        end
        interruptHolder.icon = holderIcon

        -- Create interrupt icon background
        local interruptIconBackground = interruptHolder:CreateTexture(nil, "ARTWORK", nil, 2)
        interruptIconBackground:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\castshieldbreak0.tga")
        interruptIconBackground:SetSize(height + 2, height + 2)
        interruptIconBackground:SetPoint("CENTER", holderIcon, "CENTER", -7.5, -7.5)
        interruptIconBackground:SetVertexColor(1, 0, 0, 1)
        interruptIconBackground:Hide()
        interruptHolder.iconBackground = interruptIconBackground

        -- Icon border for interrupt
        local iconBorder = interruptHolder:CreateTexture(nil, "ARTWORK", nil, 1)
        iconBorder:SetAtlas("newplayertutorial-drag-slotblue")
        iconBorder:SetSize(height * 2.5, height * 2.5)
        iconBorder:SetPoint("CENTER", holderIcon, "CENTER", 0, 0)
        iconBorder:SetDesaturated(true)
        iconBorder:SetBlendMode("ADD")
        iconBorder:SetVertexColor(1, 0, 0, 1)
        interruptHolder.iconBorder = iconBorder

        -- Create lock icon for interrupt holder
        local holderLockIcon = holderBorder:CreateTexture(nil, "OVERLAY", nil, 4)
        holderLockIcon:SetAtlas("common-icon-forbidenredalert")
        holderLockIcon:SetSize(height * 0.6, height * 0.6)
        holderLockIcon:SetPoint("LEFT", interruptHolder, "LEFT", 8, 0)
        holderLockIcon:SetVertexColor(1, 0.5, 0.5, 0.9)  -- Reddish tint for interrupt
        holderLockIcon:Hide()
        interruptHolder.lockIcon = holderLockIcon
    else
        -- Create lock icon for interrupt holder even without regular icon
        local holderLockIcon = interruptHolder:CreateTexture(nil, "OVERLAY", nil, 4)
        holderLockIcon:SetAtlas("common-icon-forbidenredalert")
        holderLockIcon:SetSize(height * 0.6, height * 0.6)
        holderLockIcon:SetPoint("LEFT", interruptHolder, "LEFT", 8, 0)
        holderLockIcon:SetVertexColor(1, 0.5, 0.5, 0.9)  -- Reddish tint for interrupt
        holderLockIcon:Hide()
        interruptHolder.lockIcon = holderLockIcon
    end

    -- Create spark for interrupt holder
    local holderSpark = holderBorder:CreateTexture(nil, "OVERLAY")
    holderSpark:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\orangespark.tga")
    holderSpark:SetSize(20, height * 1.6)
    holderSpark:SetVertexColor(1, 1, 1, 1)
    holderSpark:SetBlendMode("ADD")
    holderSpark:Hide()
    interruptHolder.spark = holderSpark

    -- Create interrupt glow
    local holderInterruptGlow = holderBorder:CreateTexture(nil, "OVERLAY", nil, 6)
    holderInterruptGlow:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\powerhl1.tga")
    holderInterruptGlow:SetSize(width * 1.1, height * 2)
    holderInterruptGlow:SetPoint("CENTER", holderBorder, "CENTER")
    holderInterruptGlow:SetVertexColor(1, 0, 0, 1)
    holderInterruptGlow:SetBlendMode("ADD")
    holderInterruptGlow:Hide()
    interruptHolder.interruptGlow = holderInterruptGlow

    -- CORE STATE VARIABLES
    castBar.isChanneling = false
    castBar.castStartTime = 0
    castBar.castEndTime = 0
    castBar.spellName = ""
    castBar.spellIcon = ""
    castBar.isInterruptible = true
    castBar.castID = nil
    castBar.isCasting = false
    castBar.reverseChanneling = false

    -- Add all the castbar methods from rnxmUI
    CastBars.AddCastBarMethods(castBar)
    CastBars.SetupCastBarEvents(castBar)

    return castBar
end

-- ADD CASTBAR METHODS (adapted from rnxmUI)
function CastBars.AddCastBarMethods(castBar)

    function castBar:UpdateAppearance(castType, isInterruptible)
        if castType == "cast" then
            if isInterruptible then
                self:SetStatusBarTexture("Interface\\AddOns\\Nihui_cb\\textures\\WSYellow.tga")
                self:SetStatusBarColor(1, 1, 1, 1)
                self.spark:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\castspark.tga")
                self.spark:SetDesaturated(false)
            else
                -- Non-interruptible cast: gray appearance
                self:SetStatusBarTexture("Interface\\AddOns\\Nihui_cb\\textures\\armorcastbar0.tga")
                self:SetStatusBarColor(0.6, 0.6, 0.6, 1)  -- Gray color
                self.spark:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\uspark.tga")
                self.spark:SetDesaturated(true)  -- Desaturated spark
            end
        elseif castType == "channel" then
            if isInterruptible then
                self:SetStatusBarTexture("Interface\\AddOns\\Nihui_cb\\textures\\WSGreen.tga")
                self:SetStatusBarColor(1, 1, 1, 1)
                self.spark:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\channelspark.tga")
                self.spark:SetDesaturated(false)
            else
                -- Non-interruptible channel: gray appearance
                self:SetStatusBarTexture("Interface\\AddOns\\Nihui_cb\\textures\\armorcastbar0.tga")
                self:SetStatusBarColor(0.6, 0.6, 0.6, 1)  -- Gray color
                self.spark:SetTexture("Interface\\AddOns\\Nihui_cb\\textures\\uspark.tga")
                self.spark:SetDesaturated(true)  -- Desaturated spark
            end
        elseif castType == "interrupt" then
            self:SetStatusBarTexture("Interface\\AddOns\\Nihui_cb\\textures\\HPDHD.tga")
            self:SetStatusBarColor(1, 0.2, 0.2, 1)
        end

        -- Progress overlay color tinting
        if self.progressOverlay then
            if castType == "cast" then
                if isInterruptible then
                    self.progressOverlay:SetVertexColor(1, 0.8, 0.2, 1)
                    self.progressOverlay:SetTexCoord(0, 1, 0, 1)
                else
                    self.progressOverlay:SetVertexColor(1, 0, 0, 1)
                    self.progressOverlay:SetTexCoord(0, 1, 0, 1)
                end
            elseif castType == "channel" then
                self.progressOverlay:SetTexCoord(1, 0, 0, 1)
                if isInterruptible then
                    self.progressOverlay:SetVertexColor(0.1, 1, 0.3, 1)
                else
                    self.progressOverlay:SetVertexColor(1, 0, 0, 1)
                end
            elseif castType == "interrupt" then
                self.progressOverlay:SetVertexColor(1, 0.2, 0.2, 1)
                self.progressOverlay:SetTexCoord(0, 1, 0, 1)
            end
        end

        -- Icon border color tinting
        if self.icon and self.iconBorder then
            if castType == "cast" then
                if isInterruptible then
                    self.iconBorder:SetVertexColor(1, 0.8, 0.2, 1)
                else
                    self.iconBorder:SetVertexColor(0.8, 0.8, 0.8, 1)
                end
            elseif castType == "channel" then
                if isInterruptible then
                    self.iconBorder:SetVertexColor(0.1, 1, 0.3, 1)
                else
                    self.iconBorder:SetVertexColor(0.8, 0.8, 0.8, 1)
                end
            elseif castType == "interrupt" then
                self.iconBorder:SetVertexColor(1, 0.2, 0.2, 1)
            end
        end

        -- Icon background logic - only show if icon is valid
        if self.iconBackground then
            local hasValidIcon = self.spellIcon and self.spellIcon ~= "" and self.spellIcon ~= 0
            if hasValidIcon and (castType == "cast" or castType == "channel") and not isInterruptible then
                self.iconBackground:Show()
            else
                self.iconBackground:Hide()
            end
        end

        -- Lock icon logic - show for non-interruptible spells
        if self.lockIcon then
            if (castType == "cast" or castType == "channel") and not isInterruptible then
                self.lockIcon:Show()
                -- Color the lock icon based on cast type
                if castType == "cast" then
                    self.lockIcon:SetVertexColor(0.8, 0.8, 0.8, 0.9)  -- Light gray for casts
                else
                    self.lockIcon:SetVertexColor(0.8, 0.8, 0.8, 0.9)  -- Light gray for channels
                end
            else
                self.lockIcon:Hide()
            end
        end
    end

    function castBar:StartCast(name, icon, startTime, endTime, isInterruptible, castID)
        -- Clear all states and ensure visibility
        self.isChanneling = false
        self.isCasting = true
        self.spellName = name
        self.spellIcon = icon
        self.isInterruptible = isInterruptible
        self.castID = castID

        -- Force visibility and clear any pending hide timers
        self:SetAlpha(1)
        self:Show()

        self:UpdateAppearance("cast", isInterruptible)

        if self.text then
            self.text:SetText(name)
        end

        -- Check if icon is valid before showing it
        local hasValidIcon = icon and icon ~= "" and icon ~= 0
        if self.icon then
            if hasValidIcon then
                self.icon:SetTexture(icon)
                self.icon:Show()
                if self.iconBorder then self.iconBorder:Show() end
            else
                self.icon:Hide()
                if self.iconBorder then self.iconBorder:Hide() end
                if self.iconBackground then self.iconBackground:Hide() end
            end
        end

        if self.spark then
            self.spark:Show()
        end

        if startTime and endTime and startTime > 0 and endTime > 0 then
            self.castStartTime = startTime
            self.castEndTime = endTime
        else
            self.castStartTime = GetTime() * 1000
            self.castEndTime = self.castStartTime + 2500  -- 2.5 second default
        end
    end

    function castBar:StartDebugCast(spellData)
        self.debugMode = true
        local currentTime = GetTime() * 1000

        if spellData.type == "cast" then
            self:StartCast(spellData.name, spellData.texture, currentTime, currentTime + (spellData.duration * 1000), true, nil)
        elseif spellData.type == "channel" then
            self:SetupChannel(spellData.name, spellData.texture, currentTime, currentTime + (spellData.duration * 1000), true)
        end
    end

    function castBar:SetupChannel(name, texture, startTimeMS, endTimeMS, isInterruptible)
        -- Clear all states and ensure visibility
        self.isChanneling = true
        self.isCasting = true
        self.spellName = name
        self.spellIcon = texture or ""
        self.isInterruptible = isInterruptible

        -- Force visibility and clear any pending hide timers
        self:SetAlpha(1)
        self:Show()

        self:UpdateAppearance("channel", isInterruptible)

        if self.text then
            self.text:SetText(name)
        end

        -- Check if icon is valid before showing it
        local hasValidIcon = texture and texture ~= "" and texture ~= 0
        if self.icon then
            if hasValidIcon then
                self.icon:SetTexture(texture)
                self.icon:Show()
                if self.iconBorder then self.iconBorder:Show() end
            else
                self.icon:Hide()
                if self.iconBorder then self.iconBorder:Hide() end
                if self.iconBackground then self.iconBackground:Hide() end
            end
        end

        if self.spark then
            self.spark:Show()
        end

        if startTimeMS and endTimeMS then
            self.castStartTime = startTimeMS
            self.castEndTime = endTimeMS
        else
            self.castStartTime = GetTime() * 1000
            self.castEndTime = self.castStartTime + 5000  -- 5 second default
        end
    end

    function castBar:UpdateSpark()
        if not self.spark or not self.spark:IsShown() then return end

        local progress = self:GetValue()
        local castBarWidth = self:GetWidth()
        local sparkPos = castBarWidth * progress

        self.spark:ClearAllPoints()
        self.spark:SetPoint("CENTER", self, "LEFT", sparkPos, 0)
    end

    -- Update spark position on interrupt holder
    function castBar:UpdateHolderSpark(holder, progress)
        if not holder or not holder.spark then return end

        local width = holder:GetWidth()
        local sparkPos = width * progress

        holder.spark:ClearAllPoints()
        holder.spark:SetPoint("CENTER", holder, "LEFT", sparkPos, 0)
        holder.spark:Show()
    end

    -- Helper function to cancel all animations and reset state
    function castBar:CancelAllAnimations()
        if self.completionFlashAnim then
            self.completionFlashAnim:Stop()
            self.completionFlash:Hide()
        end
        if self.fadeOutAnim then
            self.fadeOutAnim:Stop()
        end
        if self.hideTimer then
            self.hideTimer:Cancel()
            self.hideTimer = nil
        end
        if self.interruptAnim then
            self.interruptAnim:Stop()
        end
        -- Cancel any pending interrupt hide timer
        if self.interruptHideTimer then
            self.interruptHideTimer:Cancel()
            self.interruptHideTimer = nil
        end
        -- Hide and reset interrupt holder
        if self.interruptHolder then
            if self.interruptHolder.hideTimer then
                self.interruptHolder.hideTimer:Cancel()
                self.interruptHolder.hideTimer = nil
            end
            if self.interruptHolder.fadeOutAnim then
                self.interruptHolder.fadeOutAnim:Stop()
            end
            if self.interruptHolder.shakeStartTime then
                self.interruptHolder.shakeStartTime = nil
                if self.interruptHolder.shakeOriginalPoint then
                    self.interruptHolder:ClearAllPoints()
                    self.interruptHolder:SetPoint(unpack(self.interruptHolder.shakeOriginalPoint))
                    self.interruptHolder.shakeOriginalPoint = nil
                end
            end
            self.interruptHolder:Hide()
            self.interruptHolder:SetAlpha(1)
        end
        self.isFlashing = false
        self:SetAlpha(1)
    end

    function castBar:StopCast()
        if self.spark then
            self.spark:Hide()
        end

        -- Hide lock icon when stopping cast
        if self.lockIcon then
            self.lockIcon:Hide()
        end

        self.castStartTime = 0
        self.castEndTime = 0
        self.castID = nil
        self.isCasting = false
        self.isChanneling = false
        self.reverseChanneling = false
        self.debugMode = false

        self:Hide()
    end

    -- Interrupt animation exactly like rnxmUI
    function castBar:ShowInterruptAnimation()
        if not self.interruptHolder then return end
        if self.interruptHolder:IsShown() then return end

        local currentProgress = self:GetValue()
        local spellName = self.spellName
        local spellIcon = self.spellIcon

        -- Setup interrupt holder with current progress
        self.interruptHolder:SetValue(currentProgress)
        self.interruptHolder:SetStatusBarColor(1.0, 0.4, 1.0, 1.0) -- Magenta like rnxmUI

        -- Update holder spark position
        self:UpdateHolderSpark(self.interruptHolder, currentProgress)

        -- Set interrupt text
        if self.interruptHolder.text then
            self.interruptHolder.text:SetText("Interrupted")
        end

        -- Set interrupt icon - check if valid before showing
        local hasValidIcon = spellIcon and spellIcon ~= "" and spellIcon ~= 0
        if self.interruptHolder.icon then
            if hasValidIcon then
                self.interruptHolder.icon:SetTexture(spellIcon)
                self.interruptHolder.icon:Show()
                if self.interruptHolder.iconBorder then self.interruptHolder.iconBorder:Show() end
            else
                self.interruptHolder.icon:Hide()
                if self.interruptHolder.iconBorder then self.interruptHolder.iconBorder:Hide() end
                if self.interruptHolder.iconBackground then self.interruptHolder.iconBackground:Hide() end
            end
        end

        -- Hide main castbar
        self:Hide()
        if self.spark then
            self.spark:Hide()
        end

        -- Show interrupt holder
        self.interruptHolder:Show()

        -- Play shake animation and glow like rnxmUI
        self:PlayHolderShake()
        self:PlayHolderInterruptGlow()
    end

    -- Shake animation for interrupt holder
    function castBar:PlayHolderShake()
        if not self.interruptHolder then return end

        -- Stop any existing shake first (taint-safe)
        if self.interruptHolder.shakeStartTime then
            self.interruptHolder.shakeStartTime = nil
            if self.interruptHolder.shakeOriginalPoint then
                self.interruptHolder:ClearAllPoints()
                self.interruptHolder:SetPoint(unpack(self.interruptHolder.shakeOriginalPoint))
                self.interruptHolder.shakeOriginalPoint = nil
            end
        end

        local duration = 0.5
        local deltaX = 4
        local deltaY = 2
        local startTime = GetTime()

        local parent = self.interruptHolder:GetParent()
        if not parent then return end

        -- Use stored original position to avoid taint (robust solution)
        local originalPoint = self.originalPoint
        if originalPoint then
            -- Taint-safe: use position from creation
            self.interruptHolder.shakeOriginalPoint = originalPoint
        else
            -- Fallback: GetPoint() for compatibility (if no stored position)
            local point, relativeTo, relativePoint, x, y = self:GetPoint()
            self.interruptHolder.shakeOriginalPoint = {point or "CENTER", relativeTo or parent, relativePoint or "CENTER", x or 0, y or 0}
        end
        self.interruptHolder.shakeStartTime = startTime

        local function shakeUpdate()
            if not self.interruptHolder or not self.interruptHolder.shakeStartTime then
                return
            end

            local elapsed = GetTime() - self.interruptHolder.shakeStartTime
            local progress = elapsed / duration

            if progress >= 1 then  -- Shake duration complete
                -- Reset position
                if self.interruptHolder.shakeOriginalPoint then
                    self.interruptHolder:ClearAllPoints()
                    self.interruptHolder:SetPoint(unpack(self.interruptHolder.shakeOriginalPoint))
                    self.interruptHolder.shakeOriginalPoint = nil
                    self.interruptHolder.shakeStartTime = nil
                end

                -- Hide after delay
                self.interruptHolder.hideTimer = C_Timer.NewTimer(0.5, function()
                    if self.interruptHolder then
                        if not self.interruptHolder.interruptFadeOutAnim then
                            self.interruptHolder.interruptFadeOutAnim = self.interruptHolder:CreateAnimationGroup()
                            local fadeOut = self.interruptHolder.interruptFadeOutAnim:CreateAnimation("Alpha")
                            fadeOut:SetDuration(0.4)
                            fadeOut:SetFromAlpha(1)
                            fadeOut:SetToAlpha(0)
                            fadeOut:SetSmoothing("OUT")

                            self.interruptHolder.interruptFadeOutAnim:SetScript("OnFinished", function()
                                if self.interruptHolder then
                                    self.interruptHolder:Hide()
                                    self.interruptHolder:SetAlpha(1)

                                    -- Clear casting state like rnxmUI
                                    if self then
                                        self.castStartTime = 0
                                        self.castEndTime = 0
                                        self.castID = nil
                                        self.isCasting = false
                                        self.isChanneling = false
                                        self.reverseChanneling = false
                                    end
                                end
                            end)
                        end

                        self.interruptHolder.interruptFadeOutAnim:Play()
                    end
                end)
                return
            end

            -- Calculate 2D shake offset like rnxmUI

            local easedProgress = progress * (2 - progress)
            local angle = (easedProgress + 0.25) * 2 * math.pi
            local offsetX = math.cos(angle) * deltaX * math.cos(angle * 2) * (1 - easedProgress)
            local offsetY = math.abs(math.cos(angle)) * deltaY * math.sin(angle * 2) * (1 - easedProgress)

            self.interruptHolder:ClearAllPoints()
            local origPoint = self.interruptHolder.shakeOriginalPoint
            self.interruptHolder:SetPoint(origPoint[1], origPoint[2], origPoint[3], origPoint[4] + offsetX, origPoint[5] + offsetY)

            C_Timer.After(0.016, shakeUpdate)  -- ~60 FPS
        end

        shakeUpdate()
    end

    function castBar:PlayHolderInterruptGlow()
        if not self.interruptHolder or not self.interruptHolder.interruptGlow then return end

        if not self.interruptHolder.interruptGlowAnim then
            self.interruptHolder.interruptGlowAnim = self.interruptHolder.interruptGlow:CreateAnimationGroup()

            local fadeIn = self.interruptHolder.interruptGlowAnim:CreateAnimation("Alpha")
            fadeIn:SetOrder(1)
            fadeIn:SetDuration(0.2)
            fadeIn:SetFromAlpha(0)
            fadeIn:SetToAlpha(1)

            local fadeOut = self.interruptHolder.interruptGlowAnim:CreateAnimation("Alpha")
            fadeOut:SetOrder(2)
            fadeOut:SetDuration(1.4)
            fadeOut:SetFromAlpha(1)
            fadeOut:SetToAlpha(0)
            fadeOut:SetSmoothing("OUT")

            self.interruptHolder.interruptGlowAnim:SetScript("OnFinished", function()
                self.interruptHolder.interruptGlow:Hide()
            end)
        end

        self.interruptHolder.interruptGlow:Show()
        self.interruptHolder.interruptGlow:SetAlpha(0)
        self.interruptHolder.interruptGlowAnim:Play()
    end

    function castBar:Interrupt()
        self:ShowInterruptAnimation()
    end


    function castBar:ShowCompletionFlash()
        local isChanneling = self.isChanneling
        local isInterruptible = self.isInterruptible

        -- Force visual completion state for casts only
        if not isChanneling then
            self:SetValue(1.0)  -- Casts always show 100%
            if self.spark then
                self.spark:Hide()  -- Always hide spark for completed casts
            end
        end

        -- IMMEDIATELY clear casting state to stop OnUpdate
        self.castStartTime = 0
        self.castEndTime = 0
        self.castID = nil
        self.isCasting = false
        self.isChanneling = false
        self.reverseChanneling = false

        -- Set completion flash color
        if isChanneling then
            if isInterruptible then
                self.completionFlash:SetVertexColor(0, 0.5, 0.5, 1)  -- Cyan for interruptible channels
            else
                self.completionFlash:SetVertexColor(1, 0, 0, 1)  -- Red for uninterruptible channels
            end
            self.completionFlash:SetTexCoord(1, 0, 0, 1)  -- Reversed for channels
        elseif not isInterruptible then
            self.completionFlash:SetVertexColor(1, 0, 0, 1)  -- Red for uninterruptible casts
            self.completionFlash:SetTexCoord(0, 1, 0, 1)
        else
            self.completionFlash:SetVertexColor(1, 1, 0, 1)  -- Yellow for interruptible casts
            self.completionFlash:SetTexCoord(0, 1, 0, 1)
        end

        -- Store reference to prevent multiple flashes
        self.isFlashing = true

        -- Create completion flash animation
        if not self.completionFlashAnim then
            self.completionFlashAnim = self.completionFlash:CreateAnimationGroup()

            local flashIn = self.completionFlashAnim:CreateAnimation("Alpha")
            flashIn:SetOrder(1)
            flashIn:SetDuration(0.2)
            flashIn:SetFromAlpha(0)
            flashIn:SetToAlpha(1)

            local flashOut = self.completionFlashAnim:CreateAnimation("Alpha")
            flashOut:SetOrder(2)
            flashOut:SetDuration(0.2)
            flashOut:SetFromAlpha(1)
            flashOut:SetToAlpha(0)
            flashOut:SetSmoothing("OUT")

            self.completionFlashAnim:SetScript("OnFinished", function()
                self.completionFlash:Hide()
                self:StartFadeOut() -- Always fade out after flash
            end)
        end

        self.completionFlash:Show()
        self.completionFlash:SetAlpha(0)
        self.completionFlash:SetScale(1, 1)
        self.completionFlashAnim:Play()

        -- Handle debug mode restart
        if self.debugMode then
            C_Timer.After(1.0, function()
                if ns.castBarSettings().debug then
                    local randomSpell = debugSpells[math.random(1, #debugSpells)]
                    self:StartDebugCast(randomSpell)
                end
            end)
        end
    end

    function castBar:StartFadeOut(immediate)
        -- Cancel any existing fade operations
        if self.fadeOutAnim then
            self.fadeOutAnim:Stop()
        end
        if self.hideTimer then
            self.hideTimer:Cancel()
            self.hideTimer = nil
        end

        -- Create fade-out animation group if it doesn't already exist
        if not self.fadeOutAnim then
            self.fadeOutAnim = self:CreateAnimationGroup()
            local fadeOut = self.fadeOutAnim:CreateAnimation("Alpha")
            fadeOut:SetDuration(0.35)  -- Duration of the fade-out animation
            fadeOut:SetFromAlpha(1)    -- Starting alpha (fully visible)
            fadeOut:SetToAlpha(0)      -- Ending alpha (fully transparent)
            fadeOut:SetSmoothing("OUT")  -- Smooth transition

            -- Handle animation completion
            self.fadeOutAnim:SetScript("OnFinished", function()
                if not self.isCasting then -- Double-check no new cast started
                    self:Hide()
                    self:SetAlpha(1)
                    self.isFlashing = false
                    -- Clean state
                    self.castStartTime = 0
                    self.castEndTime = 0
                    self.castID = nil
                    self.isCasting = false
                    self.isChanneling = false
                    self.reverseChanneling = false
                    self.debugMode = false
                end
            end)
        end

        -- Play fade-out immediately
        self.fadeOutAnim:Play()
    end
end

-- SETUP EVENTS
function CastBars.SetupCastBarEvents(castBar)
    -- EVENT HANDLER (from rnxmUI)
    local function OnEvent(self, event, unitID, ...)
        -- Priority: If real cast/channel starts, cancel everything else and show it
        if event == "UNIT_SPELLCAST_START" and unitID == self.unit then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unitID)
            if name then
                -- Cancel any running animations/timers immediately
                self:CancelAllAnimations()
                self:StartCast(name, texture, startTimeMS, endTimeMS, not notInterruptible, castID)
            end
            return
        end

        if event == "UNIT_SPELLCAST_CHANNEL_START" and unitID == self.unit then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible = UnitChannelInfo(unitID)
            if name then
                -- Cancel any running animations/timers immediately
                self:CancelAllAnimations()
                self.isInterruptible = not notInterruptible
                self:SetupChannel(name, texture, startTimeMS, endTimeMS, not notInterruptible)
            end
            return
        end

        if unitID ~= self.unit then return end

        if event == "UNIT_SPELLCAST_STOP" then
            -- Check if we have valid casting info to determine if this was a real cast
            local currentCast = UnitCastingInfo(unitID)
            local wasRealCast = self:IsShown() and (self.isCasting or currentCast)

            if wasRealCast and not self.isChanneling and not self.reverseChanneling then
                self:SetValue(1.0)  -- Force visual before flash
                if self.spark then
                    self.spark:Hide()
                end
                self:ShowCompletionFlash()
            else
                -- Only hide if we're not starting a new cast immediately
                local newCast = UnitCastingInfo(unitID)
                if not newCast then
                    self:StopCast()
                end
            end

        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            if self:IsShown() and self.isCasting and self.isChanneling and not self.reverseChanneling then
                local currentProgress = self:GetValue()
                if currentProgress <= 0.075 then  -- Channel essentially completed
                    self:SetValue(0.0)  -- Force to empty
                    if self.spark then
                        self.spark:Hide()
                    end
                end
                -- Now call completion flash with corrected visual state
                self:ShowCompletionFlash()
            else
                self:StopCast()
            end

        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- IMPORTANT: Check that the unitID matches this castbar's unit
            -- This prevents interrupt animations from showing on all nameplates
            if unitID == self.unit and self.isCasting and self:IsShown() then
                self:Interrupt()
            end

        elseif event == "UNIT_SPELLCAST_FAILED" then
            -- Only fail if no new cast is currently active
            local currentCast = UnitCastingInfo(unitID)
            if not currentCast then
                self:StopCast()
            end

        elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            self.isInterruptible = false
            local castingInfo = UnitCastingInfo(unitID)
            local channelInfo = UnitChannelInfo(unitID)
            if castingInfo then
                self:UpdateAppearance("cast", false)
            elseif channelInfo then
                self:UpdateAppearance("channel", false)
            end
        end
    end

    local function OnUpdate(self, elapsed)
        local castStartTime = self.castStartTime
        local castEndTime = self.castEndTime
        if not castStartTime or not castEndTime or
           castStartTime == 0 or castEndTime == 0 then
            return
        end

        local currentTime = GetTime() * 1000
        local totalTime = castEndTime - castStartTime

        if totalTime <= 0 then
            self:StopCast()
            return
        end

        local progress
        if self.isChanneling then
            progress = (castEndTime - currentTime) / totalTime
        else
            progress = (currentTime - castStartTime) / totalTime
        end

        progress = math.max(0, math.min(1, progress))
        self:SetValue(progress)
        self:UpdateSpark()

        if self.progressOverlay then
            self.progressOverlay:SetAlpha(progress * 1)
            if progress > 0 then
                self.progressOverlay:Show()
            else
                self.progressOverlay:Hide()
            end
        end

        if self.timer then
            local remaining = (castEndTime - currentTime) / 1000
            if remaining > 0 then
                self.timer:SetFormattedText("%.1f", remaining)
            else
                self.timer:SetText("")
            end
        end

        -- Check for completion
        if (not self.isChanneling and progress >= 1) or
           (self.isChanneling and progress <= 0) then
            self:ShowCompletionFlash()
            return
        end
    end

    castBar:SetScript("OnUpdate", OnUpdate)

    -- Register events
    castBar:RegisterEvent("UNIT_SPELLCAST_START")
    castBar:RegisterEvent("UNIT_SPELLCAST_STOP")
    castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    castBar:RegisterEvent("UNIT_SPELLCAST_FAILED")
    castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    castBar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

    castBar:SetScript("OnEvent", OnEvent)

    -- Check for existing casts on creation
    local castingInfo = UnitCastingInfo(castBar.unit)
    local channelInfo = UnitChannelInfo(castBar.unit)

    if castingInfo then
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible = castingInfo
        if name then
            castBar:StartCast(name, texture, startTimeMS, endTimeMS, not notInterruptible, castID)
        end
    elseif channelInfo then
        local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible = channelInfo
        if name then
            castBar.isInterruptible = not notInterruptible
            castBar:SetupChannel(name, texture, startTimeMS, endTimeMS, not notInterruptible)
        end
    end
end

-- DEBUG MODE
function CastBars:StartDebugMode()
    if debugTimer then
        debugTimer:Cancel()
    end

    local function startRandomCast()
        if not ns.castBarSettings().debug then return end

        local settings = ns.castBarSettings()
        local availableCastBars = {}

        -- Collect all enabled castbars
        if settings.player.enabled and self.playerCastBar then
            table.insert(availableCastBars, {castBar = self.playerCastBar, unit = "player"})
        end
        if settings.target.enabled and self.targetCastBar then
            table.insert(availableCastBars, {castBar = self.targetCastBar, unit = "target"})
        end
        if settings.focus.enabled and self.focusCastBar then
            table.insert(availableCastBars, {castBar = self.focusCastBar, unit = "focus"})
        end

        if #availableCastBars == 0 then
            print("|cff00ff00Nihui CastBars:|r No castbars available for debug mode")
            return
        end

        -- Start casts on all available castbars with slight delays
        for i, cbInfo in ipairs(availableCastBars) do
            local randomSpell = debugSpells[math.random(1, #debugSpells)]
            local delay = (i - 1) * 0.5 -- Stagger the casts by 0.5 seconds

            C_Timer.After(delay, function()
                if ns.castBarSettings().debug and cbInfo.castBar then
                    cbInfo.castBar:StartDebugCast(randomSpell)
                end
            end)
        end

        -- Schedule next batch of casts
        local longestDuration = 0
        for _, spell in ipairs(debugSpells) do
            longestDuration = math.max(longestDuration, spell.duration)
        end

        debugTimer = C_Timer.NewTimer(longestDuration + 2, startRandomCast)
    end

    startRandomCast()
    print("|cff00ff00Nihui CastBars:|r Debug mode started - looping casts on all enabled castbars")
end

function CastBars:StopDebugMode()
    if debugTimer then
        debugTimer:Cancel()
        debugTimer = nil
    end

    -- Stop any current debug casts on all castbars
    if self.playerCastBar and self.playerCastBar.debugMode then
        self.playerCastBar:StopCast()
    end
    if self.targetCastBar and self.targetCastBar.debugMode then
        self.targetCastBar:StopCast()
    end
    if self.focusCastBar and self.focusCastBar.debugMode then
        self.focusCastBar:StopCast()
    end

    print("|cff00ff00Nihui CastBars:|r Debug mode stopped")
end

-- DISABLE DEFAULT CASTBARS (from rnxmUI)
function CastBars.DisableDefaultCastBars()
    if PlayerCastingBarFrame then
        PlayerCastingBarFrame:Hide()
        PlayerCastingBarFrame:SetScript("OnShow", function(self) self:Hide() end)
    end

    if TargetFrameSpellBar then
        TargetFrameSpellBar:Hide()
        TargetFrameSpellBar:SetScript("OnShow", function(self) self:Hide() end)
    end

    if FocusFrameSpellBar then
        FocusFrameSpellBar:Hide()
        FocusFrameSpellBar:SetScript("OnShow", function(self) self:Hide() end)
    end
end

function CastBars.EnableDefaultCastBars()
    if PlayerCastingBarFrame then
        PlayerCastingBarFrame:Show()
        PlayerCastingBarFrame:SetScript("OnShow", nil)
    end

    if TargetFrameSpellBar then
        TargetFrameSpellBar:Show()
        TargetFrameSpellBar:SetScript("OnShow", nil)
    end

    if FocusFrameSpellBar then
        FocusFrameSpellBar:Show()
        FocusFrameSpellBar:SetScript("OnShow", nil)
    end
end

-- MODULE FUNCTIONS
function CastBars:OnEnable()
    local settings = ns.castBarSettings()
    if not settings.enabled then return end

    -- Disable default Blizzard castbars
    CastBars.DisableDefaultCastBars()

    self:CreateCastBars()

    if settings.debug then
        self:StartDebugMode()
    end
end

function CastBars:OnDisable()
    self:StopDebugMode()
    self:DestroyCastBars()

    -- Re-enable default Blizzard castbars
    CastBars.EnableDefaultCastBars()
end

function CastBars:CreateCastBars()
    local settings = ns.castBarSettings()

    -- Create player castbar (free positioning)
    if settings.player.enabled and not self.playerCastBar then
        self.playerCastBar = CastBars.CreateCastBar(nil, "player", settings.player)
    end

    -- Create target castbar (relative to TargetFrame)
    if settings.target.enabled and not self.targetCastBar then
        self.targetCastBar = CastBars.CreateCastBar(TargetFrame, "target", settings.target)
    end

    -- Create focus castbar (relative to FocusFrame)
    if settings.focus.enabled and not self.focusCastBar then
        self.focusCastBar = CastBars.CreateCastBar(FocusFrame, "focus", settings.focus)
    end
end

function CastBars:DestroyCastBars()
    if self.playerCastBar then
        self.playerCastBar:StopCast()
        self.playerCastBar:Hide()
        self.playerCastBar = nil
    end

    if self.targetCastBar then
        self.targetCastBar:StopCast()
        self.targetCastBar:Hide()
        self.targetCastBar = nil
    end

    if self.focusCastBar then
        self.focusCastBar:StopCast()
        self.focusCastBar:Hide()
        self.focusCastBar = nil
    end
end

function CastBars:UpdateCastBarPosition(castBar, unit)
    if not castBar then return end

    local settings = ns.castBarSettings()
    local unitSettings = settings[unit] or {}

    if unit == "player" then
        -- Player castbar - update free position
        local point = unitSettings.point or "BOTTOM"
        local relativeTo = _G[unitSettings.relativeTo] or UIParent
        local relativePoint = unitSettings.relativePoint or "BOTTOM"
        local xOffset = unitSettings.xOffset or 0
        local yOffset = unitSettings.yOffset or 150

        castBar:ClearAllPoints()
        castBar:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)

        -- Update interrupt holder position too
        if castBar.interruptHolder then
            castBar.interruptHolder:ClearAllPoints()
            castBar.interruptHolder:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
        end
    else
        -- Target/Focus - update relative position
        local xOffset = unitSettings.xOffset or 0
        local yOffset = unitSettings.yOffset or -20
        local parent = (unit == "target" and TargetFrame) or (unit == "focus" and FocusFrame)

        castBar:ClearAllPoints()
        castBar:SetPoint("BOTTOM", parent, "BOTTOM", xOffset, yOffset)

        if castBar.interruptHolder then
            castBar.interruptHolder:ClearAllPoints()
            castBar.interruptHolder:SetPoint("BOTTOM", parent, "BOTTOM", xOffset, yOffset)
        end
    end

    -- Update size
    local width = unitSettings.width or 125
    local height = unitSettings.height or 18
    castBar:SetSize(width, height)
    if castBar.interruptHolder then
        castBar.interruptHolder:SetSize(width, height)
    end
end

function CastBars:UpdateCastBarVisibility(castBar, unit)
    if not castBar then return end

    local settings = ns.castBarSettings()
    local unitSettings = settings[unit] or {}

    -- Update icon visibility
    if castBar.icon then
        if unitSettings.showIcon then
            castBar.icon:Show()
        else
            castBar.icon:Hide()
        end
    end

    -- Update text visibility
    if castBar.text then
        if unitSettings.showText then
            castBar.text:Show()
        else
            castBar.text:Hide()
        end
    end

    -- Update timer visibility
    if castBar.timer then
        if unitSettings.showTimer then
            castBar.timer:Show()
        else
            castBar.timer:Hide()
        end
    end

    -- Update interrupt holder elements too
    if castBar.interruptHolder then
        if castBar.interruptHolder.icon then
            if unitSettings.showIcon then
                castBar.interruptHolder.icon:Show()
            else
                castBar.interruptHolder.icon:Hide()
            end
        end

        if castBar.interruptHolder.text then
            if unitSettings.showText then
                castBar.interruptHolder.text:Show()
            else
                castBar.interruptHolder.text:Hide()
            end
        end
    end
end

function CastBars:ApplySettings()
    local settings = ns.castBarSettings()

    -- Update existing castbars instead of recreating them
    if self.playerCastBar then
        self:UpdateCastBarPosition(self.playerCastBar, "player")
        self:UpdateCastBarVisibility(self.playerCastBar, "player")
    end
    if self.targetCastBar then
        self:UpdateCastBarPosition(self.targetCastBar, "target")
        self:UpdateCastBarVisibility(self.targetCastBar, "target")
    end
    if self.focusCastBar then
        self:UpdateCastBarPosition(self.focusCastBar, "focus")
        self:UpdateCastBarVisibility(self.focusCastBar, "focus")
    end

    -- Only recreate if we need to enable/disable castbars
    if settings.player.enabled and not self.playerCastBar then
        self.playerCastBar = CastBars.CreateCastBar(nil, "player", settings.player)
        self:UpdateCastBarVisibility(self.playerCastBar, "player")
    elseif not settings.player.enabled and self.playerCastBar then
        self.playerCastBar:StopCast()
        self.playerCastBar:Hide()
        self.playerCastBar = nil
    end

    if settings.target.enabled and not self.targetCastBar then
        self.targetCastBar = CastBars.CreateCastBar(TargetFrame, "target", settings.target)
        self:UpdateCastBarVisibility(self.targetCastBar, "target")
    elseif not settings.target.enabled and self.targetCastBar then
        self.targetCastBar:StopCast()
        self.targetCastBar:Hide()
        self.targetCastBar = nil
    end

    if settings.focus.enabled and not self.focusCastBar then
        self.focusCastBar = CastBars.CreateCastBar(FocusFrame, "focus", settings.focus)
        self:UpdateCastBarVisibility(self.focusCastBar, "focus")
    elseif not settings.focus.enabled and self.focusCastBar then
        self.focusCastBar:StopCast()
        self.focusCastBar:Hide()
        self.focusCastBar = nil
    end

    if settings.debug and not debugTimer then
        self:StartDebugMode()
    elseif not settings.debug and debugTimer then
        self:StopDebugMode()
    end
end

-- Register the module
ns.addon:RegisterModule("castbars", CastBars)