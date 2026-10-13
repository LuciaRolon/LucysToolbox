function newBooleanSetting(addonName, addonDB, category, systemName, variableName, title, description)
    local initialValue = C_CVar.GetCVar(systemName) == "1"
    local variable, name, description, defaultValue = variableName, title, description, initialValue
    local newSetting = Settings.RegisterAddOnSetting(category, addonName.."_"..variable, variable, addonDB, type(defaultValue), name, defaultValue)
    Settings.CreateCheckbox(category, newSetting, description)

    newSetting:SetValueChangedCallback(function(setting, value)
        local newValue = "0"
        if value then
            newValue = "1"
        end
        C_CVar.SetCVar(systemName, newValue)
    end)
end

function newSliderSetting(addonName, addonDB, category, systemName, variableName, title, description, min, max, step)
    local initialValue = tonumber(C_CVar.GetCVar(systemName))
    local minValue, maxValue, step = min, max, step
    local variable, name, description, defaultValue = variableName, title, description, initialValue
    local newSetting = Settings.RegisterAddOnSetting(category, addonName.."_"..variable, variable, addonDB, type(defaultValue), name, defaultValue)

    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    Settings.CreateSlider(category, newSetting, options, description)

    newSetting:SetValueChangedCallback(function(setting, value)
        C_CVar.SetCVar(systemName, value)
    end)
end

function newBooleanAddonSetting(addonName, addonDB, category, initialValue, variableName, title, description)
    local variable, name, description, defaultValue = variableName, title, description, initialValue
    local newSetting = Settings.RegisterAddOnSetting(category, addonName.."_"..variable, variable, addonDB, type(defaultValue), name, defaultValue)
    Settings.CreateCheckbox(category, newSetting, description)
end


function InitializeSettings()
    local addonName = "LucysToolbox"
    LucysDB = LucysDB or {}

    -- Initialize Settings
    local category, layout = Settings.RegisterVerticalLayoutCategory("Lucy's Toolbox")
    Settings.RegisterAddOnCategory(category)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Quality of Life"))
    -- Blizzard Settings
    newBooleanSetting(addonName, LucysDB, category, "minimapTrackingShowAll", "minTrack", "Expanded Minimap Tracking", "Adds new options to Minimap Tracking like Target, Focus Target and more.")
    newBooleanSetting(addonName, LucysDB, category, "threatShowNumeric", "threatShow", "Show Threat Percentage", "Adds the Threat Percentage value above unit frames")
    -- Addon Settings
    newBooleanAddonSetting(addonName, LucysDB, category, false, "showItemID", "Show Item ID in Tooltip", "Adds the ID of the item to the tooltip.")
    newBooleanAddonSetting(addonName, LucysDB, category, false, "simpleItemTooltip", "Simplify Item Tooltips", "Simplifies certain lines in Item Tooltips by changing long text to the corresponding modifiers.")
    newBooleanAddonSetting(addonName, LucysDB, category, false, "showSpellCoefficient", "Show Spell Coefficients", "Shows the Spell Power Coefficient in the tooltip for certain spells and effects. Note: The damage bonus shown is only calculated from coefficient vs. spell power. Other effects like Talents or unique items are not included.")

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Visuals"))
    newBooleanSetting(addonName, LucysDB, category, "giquality", "indLight", "Indirect Lighting", "Allows indirect lighting. Disabling this will increase performance but the game will look much darker.")
    newSliderSetting(addonName, LucysDB, category, "groundEffectDensity", "groundDensity", "Ground Effect Density", "Adds more density to certain ground effects like grass.", 16, 256, 1)
    newSliderSetting(addonName, LucysDB, category, "groundEffectDist", "groundDist", "Ground Effect Distance", "Set the maximum distance from the player at which to render ground effects such as ferns, flowers, grass, and rocks.", 32, 600, 1)
    newSliderSetting(addonName, LucysDB, category, "shadowNumCascades", "shadowCascade", "Shadow Cascades", "Change the number of Shadow Cascades, affecting quality of lighting distribution. Makes the game look darker.", 1, 4, 1)
    newSliderSetting(addonName, LucysDB, category, "weatherDensity", "weathDens", "Weather Density", "Changes the density of Weather effects.", 0, 3, 1)
    newBooleanSetting(addonName, LucysDB, category, "ffxDeath", "deathEffect", "Dead Ghostly Effect", "If disabled, removes the Ghost/White visual effect on your camera while you're dead.")


    -- Register slash commands
    SLASH_LUCYSTOOLBOX1 = "/toolbox"
    SLASH_LUCYSTOOLBOX2 = "/lt"

    SlashCmdList["LUCYSTOOLBOX"] = function(msg)
        Settings.OpenToCategory(category:GetID())
    end
end


local function SimplifySpellPowerTooltip(tooltip)
    local tooltipName = tooltip:GetName()

    if not tooltipName then
        return
    end

    for i = 1, tooltip:NumLines() do
        local line = _G[tooltipName .. "TextLeft" .. i]

        if line then
            local text = line:GetText()

            if text then
                -- Spell Power
                local spellPower = text:match(
                    "^Equip: Increases damage and healing done by magical spells and effects by up to (%d+)%.?$"
                )
                if spellPower then
                    line:SetText("Equip: +" .. spellPower .. " Spell Power.")
                end

                -- Spell Power against Type.
                local targetType, spellPowerType = text:match(
                    "^Equip: Increases damage done to (.+) by magical spells and effects by up to (%d+)%.?$"
                )
                if targetType and spellPowerType then
                    line:SetText("Equip: +" .. spellPowerType .. " Spell Power against " .. targetType .. ".")
                end

                -- Healing Power
                local healingPower, spellDamage = text:match(
                    "^Equip: Increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects."
                )
                if healingPower and spellDamage then
                    line:SetText("Equip: +" .. healingPower .. " Spell Healing.\nEquip: +" .. spellDamage .. " Spell Damage.")
                end

                -- Elemental Power
                local spellType, spellPower = text:match(
                    "^Equip: Increases damage done by (.+) spells and effects by up to (%d+)%.?$"
                )
                if spellType and spellPower then
                    line:SetText("Equip: +" .. spellPower .. " " .. spellType .. " Spell Power.")
                end

                -- Hit Chance
                local hitChance = text:match(
                    "^Equip: Improves your chance to hit by ([%d%.]+)%%%.?$"
                )
                if hitChance then
                    line:SetText("Equip: +" .. hitChance .. "% Hit Chance.")
                end

                -- Dodge and Parry Chance
                local stat, value = text:match(
                    "^Equip: Increases your chance to (%a+) an attack by ([%d%.]+)%%%.?$"
                )
                if stat and value then
                    if stat == "Dodge" or stat == "Parry" then
                        line:SetText("Equip: +" .. value .. "% " .. stat .. " Chance.")
                    end
                end

                -- Crit Chance
                local critChance = text:match(
                    "^Equip: Improves your chance to get a critical strike by ([%d%.]+)%%%.?$"
                )
                if critChance then
                    line:SetText("Equip: +" .. critChance .. "% Critical Strike Chance.")
                end

                -- Block Chance
                local blockChance = text:match(
                    "^Equip: Increases your chance to Block attacks with a shield by ([%d%.]+)%%%.?$"
                )
                if blockChance then
                    line:SetText("Equip: +" .. blockChance .. "% Block Chance.")
                end
            end
        end
    end
end

--#region SpellCoefficients

local schoolIDs = {
    [2] = 2,   -- Holy
    [4] = 3,   -- Fire
    [8] = 4,   -- Nature
    [16] = 5,  -- Frost
    [32] = 6,  -- Shadow
    [64] = 7,  -- Arcane
}

local function GetSpellPowerFromMask(schoolMask)
    local schoolID = schoolIDs[schoolMask]

    if not schoolID then
        return nil
    end

    return GetSpellBonusDamage(schoolID)
end

local function GetEffectBonus(spellID, effectIndex)
    local spellData = LucysSpellCoefficients[spellID]

    if not spellData then
        return nil
    end

    local effect = spellData.effects[effectIndex]

    if not effect then
        return nil
    end

    local coefficient = effect.coefficient
    local kind = effect.kind

    if kind == "healing" or kind == "periodic_healing" then
        return GetSpellBonusHealing() * coefficient
    end

    if kind == "damage" or kind == "periodic_damage" then
        local spellPower = GetSpellPowerFromMask(
            spellData.schoolMask
        )

        if spellPower then
            return spellPower * coefficient
        end
    end

    return nil
end

local function AddSpellCoefficient(tooltip, data)
    local spellData = LucysSpellCoefficients[data.id]

    if not spellData then
        return
    end

    for index, effect in pairs(spellData.effects) do
        if effect.kind ~= "unknown" then
            local bonus = GetEffectBonus(data.id, index)
            local kind = "Instant Damage"
            if effect.kind == "healing" then
                kind = "Instant Healing"
            elseif effect.kind == "periodic_damage" then
                kind = "Periodic Damage"
            elseif effect.kind == "periodic_healing" then
                kind = "Periodic Healing"
            end
    
            local label = string.format(
                "%s: %.1f%% SP",
                kind,
                effect.coefficient * 100
            )
    
            if bonus then
                label = label .. string.format(
                    " (+%.1f)",
                    bonus
                )
            end
    
            tooltip:AddLine(label, 0, 1, 0)            
        end
    end
end

--#endregion

function InitializeTooltipProcessors()
    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Item,
        function(tooltip, data)
            if LucysDB.showItemID then
                local itemID = data.id

                if not itemID then
                    return
                end

                tooltip:AddLine("Item ID: " .. itemID, 1, 1, 1)
            end
            if LucysDB.simpleItemTooltip then
                SimplifySpellPowerTooltip(tooltip)
            end
        end
    )

    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Spell,
        function(tooltip, data)
            if LucysDB.showSpellCoefficient then
                AddSpellCoefficient(tooltip, data)
            end
        end
    )
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "LucysToolbox" then
        InitializeSettings()
        InitializeTooltipProcessors()
        print("|cff00ff00Lucy's Toolbox|r loaded! Type /lt for settings.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)