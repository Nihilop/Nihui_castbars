-- Nihui CastBars - Core initialization
local addonName, ns = ...

-- Addon instance
ns.addon = {}
ns.modules = {}

-- Default configuration
local defaults = {
    castbars = {
        enabled = true,
        debug = false,

        -- Player settings - positioned at bottom center of screen
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

        -- Target settings - positioned at center of screen
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

        -- Focus settings - positioned at center-right of screen
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
    },
}

-- Initialize SavedVariables
function ns.addon:InitializeDB()
    if not NihuiCastBarsDB then
        NihuiCastBarsDB = CopyTable(defaults)
    else
        -- Merge any missing defaults
        for category, settings in pairs(defaults) do
            if not NihuiCastBarsDB[category] then
                NihuiCastBarsDB[category] = CopyTable(settings)
            else
                for key, value in pairs(settings) do
                    if NihuiCastBarsDB[category][key] == nil then
                        NihuiCastBarsDB[category][key] = value
                    elseif type(value) == "table" and type(NihuiCastBarsDB[category][key]) == "table" then
                        for subkey, subvalue in pairs(value) do
                            if NihuiCastBarsDB[category][key][subkey] == nil then
                                NihuiCastBarsDB[category][key][subkey] = subvalue
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Settings accessor
function ns.castBarSettings()
    return NihuiCastBarsDB.castbars
end

-- Module registration
function ns.addon:RegisterModule(name, module)
    ns.modules[name] = module
    if module.OnEnable then
        C_Timer.After(1, function()
            module:OnEnable()
        end)
    end
end

-- Event frame for addon events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        ns.addon:InitializeDB()

        -- Expose API globally for inter-addon communication
        _G["NihuiCbAPI"] = ns

        print("|cff00ff00Nihui CastBars|r loaded successfully!")
    elseif event == "PLAYER_LOGIN" then
        -- Initialize modules after login
        for name, module in pairs(ns.modules) do
            if module.OnEnable then
                module:OnEnable()
            end
        end
    end
end)

-- Slash command
SLASH_NIHUICB1 = "/ncb"
SLASH_NIHUICB2 = "/nihuicb"
SlashCmdList["NIHUICB"] = function(msg)
    if msg == "config" or msg == "" then
        if ns.GUI and ns.GUI.Toggle then
            ns.GUI:Toggle()
        else
            print("|cff00ff00Nihui CastBars:|r GUI not loaded yet")
        end
    elseif msg == "debug" then
        local settings = ns.castBarSettings()
        settings.debug = not settings.debug
        if settings.debug then
            print("|cff00ff00Nihui CastBars:|r Debug mode enabled")
            if ns.modules.castbars and ns.modules.castbars.StartDebugMode then
                ns.modules.castbars:StartDebugMode()
            end
        else
            print("|cff00ff00Nihui CastBars:|r Debug mode disabled")
            if ns.modules.castbars and ns.modules.castbars.StopDebugMode then
                ns.modules.castbars:StopDebugMode()
            end
        end
    elseif msg == "reset" then
        NihuiCastBarsDB = CopyTable(defaults)
        ReloadUI()
    else
        print("|cff00ff00Nihui CastBars Commands:|r")
        print("/ncb config - Open configuration")
        print("/ncb debug - Toggle debug mode (looping cast)")
        print("/ncb reset - Reset to defaults (requires reload)")
    end
end