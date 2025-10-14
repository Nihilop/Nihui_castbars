-- Nihui CastBars - Configuration utilities
local addonName, ns = ...

-- Configuration helper functions
ns.Config = {}

function ns.Config:GetCastBarSettings()
    return ns.castBarSettings()
end

function ns.Config:UpdateCastBars()
    if ns.modules.castbars and ns.modules.castbars.ApplySettings then
        ns.modules.castbars:ApplySettings()
    end
end

function ns.Config:ResetToDefaults()
    local defaults = {
        enabled = true,
        debug = false,

        player = {
            enabled = true,
            width = 200,
            height = 20,
            point = "BOTTOM",
            relativeTo = "UIParent",
            relativePoint = "BOTTOM",
            xOffset = 0,
            yOffset = 150,
            showIcon = true,
            showText = true,
            showTimer = true,
            mask = "Interface\\AddOns\\Nihui_cb\\textures\\UIUnitFramePlayerHealthMask2x.tga",
            movable = true
        },

        target = {
            enabled = true,
            width = 180,
            height = 18,
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            xOffset = 0,
            yOffset = -50,
            showIcon = true,
            showText = true,
            showTimer = true,
            mask = "Interface\\AddOns\\Nihui_cb\\textures\\UIUnitFramePlayerHealthMask2x.tga",
            movable = true
        },

        focus = {
            enabled = true,
            width = 160,
            height = 16,
            point = "CENTER",
            relativeTo = "UIParent",
            relativePoint = "CENTER",
            xOffset = 250,
            yOffset = -50,
            showIcon = true,
            showText = true,
            showTimer = true,
            mask = "Interface\\AddOns\\Nihui_cb\\textures\\UIUnitFramePlayerHealthMask2x.tga",
            movable = true
        }
    }

    local settings = ns.castBarSettings()
    for key, value in pairs(defaults) do
        if type(value) == "table" and type(settings[key]) == "table" then
            for subkey, subvalue in pairs(value) do
                if type(subvalue) == "table" and type(settings[key][subkey]) == "table" then
                    for subsubkey, subsubvalue in pairs(subvalue) do
                        settings[key][subkey][subsubkey] = subsubvalue
                    end
                else
                    settings[key][subkey] = subvalue
                end
            end
        else
            settings[key] = value
        end
    end

    self:UpdateCastBars()

    print("|cff00ff00Nihui CastBars:|r Settings reset to defaults!")
end