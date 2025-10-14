-- Nihui CastBars - GUI with AceConfig
local addonName, ns = ...

-- Check if AceConfig is available
local AceConfig = LibStub("AceConfig-3.0", true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
local AceDBOptions = LibStub("AceDBOptions-3.0", true)

if not AceConfig or not AceConfigDialog then
    print("|cff00ff00Nihui CastBars:|r AceConfig not available, using simple GUI")
    return
end

local GUI = {}
ns.GUI = GUI

-- Create the configuration table
local function CreateConfigTable()
    return {
        type = "group",
        name = "|cff00ff00Nihui|r CastBars",
        args = {
            enabled = {
                order = 1,
                type = "toggle",
                name = "Enable CastBars",
                desc = "Enable or disable all castbar customizations",
                width = "full",
                get = function()
                    return ns.castBarSettings().enabled
                end,
                set = function(_, val)
                    ns.castBarSettings().enabled = val
                    if ns.modules.castbars then
                        if val then
                            ns.modules.castbars:OnEnable()
                        else
                            ns.modules.castbars:OnDisable()
                        end
                    end
                end,
            },

            debug = {
                order = 2,
                type = "toggle",
                name = "Debug Mode (Looping Casts)",
                desc = "Enable debug mode with continuous spell casting for testing positioning",
                width = "full",
                get = function()
                    return ns.castBarSettings().debug
                end,
                set = function(_, val)
                    ns.castBarSettings().debug = val
                    if ns.modules.castbars then
                        if val then
                            ns.modules.castbars:StartDebugMode()
                        else
                            ns.modules.castbars:StopDebugMode()
                        end
                    end
                end,
                disabled = function()
                    return not ns.castBarSettings().enabled
                end,
            },

            moveTip = {
                order = 2.5,
                type = "description",
                name = "|cffFFD700Tip:|r Hold Alt + Drag castbars to move them around the screen",
                fontSize = "medium",
            },

            resetButton = {
                order = 3,
                type = "execute",
                name = "Reset to Defaults",
                desc = "Reset all settings to default values",
                func = function()
                    if ns.Config then
                        ns.Config:ResetToDefaults()
                    end
                end,
                width = 1.5,
                confirm = true,
                confirmText = "Are you sure you want to reset all settings to defaults?",
            },

            -- Player CastBar Group
            playerGroup = {
                order = 10,
                type = "group",
                name = "Player CastBar",
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Player CastBar",
                        desc = "Enable custom player castbar",
                        get = function()
                            return ns.castBarSettings().player.enabled
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.enabled = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = "full",
                    },

                    width = {
                        order = 2,
                        type = "range",
                        name = "Width",
                        desc = "Width of the player castbar",
                        min = 80,
                        max = 400,
                        step = 5,
                        get = function()
                            return ns.castBarSettings().player.width
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.width = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().player.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    height = {
                        order = 3,
                        type = "range",
                        name = "Height",
                        desc = "Height of the player castbar",
                        min = 12,
                        max = 40,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().player.height
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.height = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().player.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    xOffset = {
                        order = 4,
                        type = "range",
                        name = "X Position",
                        desc = "Horizontal position on screen",
                        min = -1000,
                        max = 1000,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().player.xOffset
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.xOffset = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().player.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    yOffset = {
                        order = 5,
                        type = "range",
                        name = "Y Position",
                        desc = "Vertical position on screen",
                        min = -500,
                        max = 500,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().player.yOffset
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.yOffset = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().player.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showIcon = {
                        order = 6,
                        type = "toggle",
                        name = "Show Icon",
                        desc = "Show spell icon next to castbar",
                        get = function()
                            return ns.castBarSettings().player.showIcon
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.showIcon = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().player.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showText = {
                        order = 7,
                        type = "toggle",
                        name = "Show Text",
                        desc = "Show spell name below castbar",
                        get = function()
                            return ns.castBarSettings().player.showText
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.showText = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().player.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showTimer = {
                        order = 8,
                        type = "toggle",
                        name = "Show Timer",
                        desc = "Show remaining time on castbar",
                        get = function()
                            return ns.castBarSettings().player.showTimer
                        end,
                        set = function(_, val)
                            ns.castBarSettings().player.showTimer = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().player.enabled or not ns.castBarSettings().enabled
                        end,
                    },
                },
            },

            -- Target CastBar Group
            targetGroup = {
                order = 20,
                type = "group",
                name = "Target CastBar",
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Target CastBar",
                        desc = "Enable custom target castbar",
                        get = function()
                            return ns.castBarSettings().target.enabled
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.enabled = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = "full",
                    },

                    width = {
                        order = 2,
                        type = "range",
                        name = "Width",
                        desc = "Width of the target castbar",
                        min = 80,
                        max = 400,
                        step = 5,
                        get = function()
                            return ns.castBarSettings().target.width
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.width = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().target.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    height = {
                        order = 3,
                        type = "range",
                        name = "Height",
                        desc = "Height of the target castbar",
                        min = 12,
                        max = 40,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().target.height
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.height = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().target.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    xOffset = {
                        order = 4,
                        type = "range",
                        name = "X Position",
                        desc = "Horizontal position on screen",
                        min = -1000,
                        max = 1000,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().target.xOffset
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.xOffset = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().target.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    yOffset = {
                        order = 5,
                        type = "range",
                        name = "Y Position",
                        desc = "Vertical position on screen",
                        min = -500,
                        max = 500,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().target.yOffset
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.yOffset = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().target.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showIcon = {
                        order = 6,
                        type = "toggle",
                        name = "Show Icon",
                        desc = "Show spell icon next to castbar",
                        get = function()
                            return ns.castBarSettings().target.showIcon
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.showIcon = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().target.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showText = {
                        order = 7,
                        type = "toggle",
                        name = "Show Text",
                        desc = "Show spell name below castbar",
                        get = function()
                            return ns.castBarSettings().target.showText
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.showText = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().target.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showTimer = {
                        order = 8,
                        type = "toggle",
                        name = "Show Timer",
                        desc = "Show remaining time on castbar",
                        get = function()
                            return ns.castBarSettings().target.showTimer
                        end,
                        set = function(_, val)
                            ns.castBarSettings().target.showTimer = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().target.enabled or not ns.castBarSettings().enabled
                        end,
                    },
                },
            },

            -- Focus CastBar Group
            focusGroup = {
                order = 30,
                type = "group",
                name = "Focus CastBar",
                inline = true,
                args = {
                    enabled = {
                        order = 1,
                        type = "toggle",
                        name = "Enable Focus CastBar",
                        desc = "Enable custom focus castbar",
                        get = function()
                            return ns.castBarSettings().focus.enabled
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.enabled = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = "full",
                    },

                    width = {
                        order = 2,
                        type = "range",
                        name = "Width",
                        desc = "Width of the focus castbar",
                        min = 80,
                        max = 400,
                        step = 5,
                        get = function()
                            return ns.castBarSettings().focus.width
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.width = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().focus.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    height = {
                        order = 3,
                        type = "range",
                        name = "Height",
                        desc = "Height of the focus castbar",
                        min = 12,
                        max = 40,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().focus.height
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.height = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().focus.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    xOffset = {
                        order = 4,
                        type = "range",
                        name = "X Position",
                        desc = "Horizontal position on screen",
                        min = -1000,
                        max = 1000,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().focus.xOffset
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.xOffset = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().focus.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    yOffset = {
                        order = 5,
                        type = "range",
                        name = "Y Position",
                        desc = "Vertical position on screen",
                        min = -500,
                        max = 500,
                        step = 1,
                        get = function()
                            return ns.castBarSettings().focus.yOffset
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.yOffset = val
                            ns.Config:UpdateCastBars()
                        end,
                        width = 1.5,
                        disabled = function()
                            return not ns.castBarSettings().focus.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showIcon = {
                        order = 6,
                        type = "toggle",
                        name = "Show Icon",
                        desc = "Show spell icon next to castbar",
                        get = function()
                            return ns.castBarSettings().focus.showIcon
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.showIcon = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().focus.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showText = {
                        order = 7,
                        type = "toggle",
                        name = "Show Text",
                        desc = "Show spell name below castbar",
                        get = function()
                            return ns.castBarSettings().focus.showText
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.showText = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().focus.enabled or not ns.castBarSettings().enabled
                        end,
                    },

                    showTimer = {
                        order = 8,
                        type = "toggle",
                        name = "Show Timer",
                        desc = "Show remaining time on castbar",
                        get = function()
                            return ns.castBarSettings().focus.showTimer
                        end,
                        set = function(_, val)
                            ns.castBarSettings().focus.showTimer = val
                            ns.Config:UpdateCastBars()
                        end,
                        disabled = function()
                            return not ns.castBarSettings().focus.enabled or not ns.castBarSettings().enabled
                        end,
                    },
                },
            },
        },
    }
end

-- Initialize the GUI
function GUI:Initialize()
    -- Register the config table
    AceConfig:RegisterOptionsTable("NihuiCastBars", CreateConfigTable)

    -- Create the dialog
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("NihuiCastBars", "|cff00ff00Nihui|r CastBars")

    print("|cff00ff00Nihui CastBars:|r GUI initialized. Use '/ncb config' or check Interface > AddOns")
end

-- Toggle the configuration window
function GUI:Toggle()
    if self.optionsFrame then
        -- Use new Settings API for modern WoW versions
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(self.optionsFrame.name)
        elseif SettingsPanel then
            -- Fallback for SettingsPanel
            if SettingsPanel:IsShown() then
                SettingsPanel:Hide()
            else
                SettingsPanel:Open()
            end
        elseif InterfaceOptionsFrame_OpenToCategory then
            -- Legacy support for older versions
            InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
            InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        else
            -- Final fallback - use AceConfigDialog directly
            AceConfigDialog:Open("NihuiCastBars")
        end
    else
        print("|cff00ff00Nihui CastBars:|r Configuration not available")
    end
end

-- Initialize when addon loads
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        C_Timer.After(0.5, function()
            GUI:Initialize()
        end)
        frame:UnregisterEvent("ADDON_LOADED")
    end
end)