---@diagnostic disable: undefined-field
DFRL:SetDefaults("targetframe", {
    enabled = {true},
    hidden = {false},

    darkMode = {0, 1, "slider", {0, 1}, "appearance", "Adjust dark mode intensity"},

    textShow = {true, 1, "checkbox", "text settings", "Show health and mana text"},
    noPercent = {true, 3, "checkbox", "text settings", "Show only current values without percentages"},
    textColoring = {false, 4, "checkbox", "text settings", "Color text based on health/mana percentage"},
    healthSize = {15, 5, "slider", {8, 20}, "text settings", "Health text font size"},
    manaSize = {9, 6, "slider", {8, 20}, "text settings", "Mana text font size"},
    frameFont = {"Myriad-Pro", 2, "dropdown", {
        "FRIZQT__.TTF",
        "Expressway",
        "Homespun",
        "Hooge",
        "Myriad-Pro",
        "Prototype",
        "PT-Sans-Narrow-Bold",
        "PT-Sans-Narrow-Regular",
        "RobotoMono",
        "BigNoodleTitling",
        "Continuum",
        "DieDieDie"
    }, "text settings", "Change the font used for the targetframe"},

    colorReaction = {true, 5, "checkbox", "bar color", "Color health bar based on target reaction"},
    colorClass = {false, 6, "checkbox", "bar color", "Color health bar based on target class"},

    frameScale = {1, 8, "slider", {0.7, 1.3}, "tweaks", "Adjust frame size"},

})

DFRL:RegisterModule("targetframe", 1, function()
    d:DebugPrint("BOOTING")

    local Setup = {
        texpath = "Interface\\AddOns\\DragonflightReloaded\\media\\tex\\unitframes\\",
        texpath2 = "Interface\\AddOns\\DragonflightReloaded\\media\\tex\\ui\\",
        fontpath = "Interface\\AddOns\\DragonflightReloaded\\media\\fnt\\",

        hideFrame = nil,
        healthPercentText = nil,

        combatOverlay = nil,
        combatOverlayTex = nil,

        texts = {
            healthPercent = nil,
            healthValue = nil,
            healthPercentShow = true,
            manaPercent = nil,
            manaValue = nil,
            manaPercentShow = true,
            config = {
                font = "Fonts\\FRIZQT__.TTF",
                healthFontSize = 12,
                manaFontSize = 9,
                nameFontSize = 9,
                levelFontSize = 9,
                outline = "OUTLINE",
                nameColor = {1, .82, 0},
                levelColor = {1, .82, 0},
                healthColor = {1, 1, 1},
                manaColor = {1, 1, 1},
            }
        },

        barColorState = {
            colorReaction = false,
            colorClass = false,
            -- lowHpColor = false
        }
    }

    function Setup:KillBlizz()
        TargetFrameHealthBar:SetScript("OnEnter", nil)
        TargetFrameHealthBar:SetScript("OnLeave", nil)
        TargetFrameNameBackground:SetTexture(nil)
    end

    function Setup:HealthBar()
        TargetFrameHealthBar:SetPoint("TOPRIGHT", -100, -29)
        TargetFrameHealthBar:SetWidth(129)
        TargetFrameHealthBar:SetHeight(30)
    end

    function Setup:HealthBarText()
        local cfg = self.texts.config

        self.texts.healthTextFrame = CreateFrame("Frame", nil, TargetFrame)
        self.texts.healthTextFrame:SetAllPoints(TargetFrameHealthBar)
        self.texts.healthTextFrame:SetFrameStrata(TargetFrame:GetFrameStrata())
        self.texts.healthTextFrame:SetFrameLevel(TargetFrame:GetFrameLevel() + 2)

        self.texts.healthPercent = self.texts.healthTextFrame:CreateFontString(nil)
        self.texts.healthPercent:SetFont(cfg.font, cfg.healthFontSize, cfg.outline)
        self.texts.healthPercent:SetPoint("LEFT", TargetFrameHealthBar, "LEFT", 5, 0)

        self.texts.healthValue = self.texts.healthTextFrame:CreateFontString(nil)
        self.texts.healthValue:SetFont(cfg.font, cfg.healthFontSize, cfg.outline)
        self.texts.healthValue:SetPoint("RIGHT", TargetFrameHealthBar, "RIGHT", -5, 0)
    end

    function Setup:ManaBar()
        TargetFrameManaBar:SetPoint("TOPRIGHT", -100, -53)
        TargetFrameManaBar:SetWidth(129)
    end

    function Setup:ManaBarText()
        local cfg = self.texts.config

        self.texts.manaTextFrame = CreateFrame("Frame", nil, TargetFrame)
        self.texts.manaTextFrame:SetAllPoints(TargetFrameManaBar)
        self.texts.manaTextFrame:SetFrameStrata(TargetFrame:GetFrameStrata())
        self.texts.manaTextFrame:SetFrameLevel(TargetFrame:GetFrameLevel() + 2)

        self.texts.manaPercent = self.texts.manaTextFrame:CreateFontString(nil)
        self.texts.manaPercent:SetFont(cfg.font, cfg.manaFontSize, cfg.outline)
        self.texts.manaPercent:SetPoint("LEFT", TargetFrameManaBar, "LEFT", 5, 0)

        self.texts.manaValue = self.texts.manaTextFrame:CreateFontString(nil)
        self.texts.manaValue:SetFont(cfg.font, cfg.manaFontSize, cfg.outline)
        self.texts.manaValue:SetPoint("RIGHT", TargetFrameManaBar, "RIGHT", -12, 0)
    end

    function Setup:FrameTextures()
        TargetFrameBackground:SetWidth(256)
        TargetFrameBackground:SetHeight(128)
        TargetFrameBackground:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", 0, 0)
        TargetFrameBackground:SetTexture(self.texpath .. "UI-TargetingFrameDF1-Background.blp")
    end

    function Setup:Portrait()
        TargetFrame.portrait:SetHeight(61)
        TargetFrame.portrait:SetWidth(61)
    end

    function Setup:NameText()
        local cfg = self.texts.config
        TargetFrame.name:ClearAllPoints()
        TargetFrame.name:SetPoint("CENTER", TargetFrame, "CENTER", -40, 25)
        TargetFrame.name:SetJustifyH("RIGHT")
        TargetFrame.name:SetFont(cfg.font, cfg.nameFontSize, "")
        TargetFrame.name:SetTextColor(unpack(cfg.nameColor))
    end

    function Setup:LevelText()
        local cfg = self.texts.config
        TargetLevelText:ClearAllPoints()
        TargetLevelText:SetPoint("CENTER", TargetFrame, "CENTER", -102, 25)
        TargetLevelText:SetFont(cfg.font, cfg.levelFontSize, "")
        TargetLevelText:SetTextColor(unpack(cfg.levelColor))
    end

    function Setup:UpdateTexts()
        if not UnitExists("target") then return end

        local health = UnitHealth("target")
        local maxHealth = UnitHealthMax("target")
        local healthPercent = maxHealth > 0 and health / maxHealth or 0
        local healthPercentInt = math.floor(healthPercent * 100)

        local mana = UnitMana("target")
        local maxMana = UnitManaMax("target")
        local manaPercent = maxMana > 0 and mana / maxMana or 0
        local manaPercentInt = math.floor(manaPercent * 100)

        local noPercentEnabled = DFRL:GetConfig("targetframe", "noPercent")
        local coloringEnabled = DFRL:GetConfig("targetframe", "textColoring")

        local isDead = UnitIsDead("target")

        if noPercentEnabled then
            self.texts.healthPercent:SetText("")
            if isDead then
                self.texts.healthValue:SetText("")
            else
                self.texts.healthValue:SetText(health)
            end
            self.texts.healthValue:ClearAllPoints()
            self.texts.healthValue:SetPoint("CENTER", TargetFrameHealthBar, "CENTER", 0, 0)

            self.texts.manaPercent:SetText("")
            if maxMana > 0 then
                self.texts.manaValue:SetText(mana)
                self.texts.manaValue:ClearAllPoints()
                self.texts.manaValue:SetPoint("CENTER", TargetFrameManaBar, "CENTER", -0, 0)
            else
                self.texts.manaValue:SetText("")
            end
        else
            if isDead then
                self.texts.healthPercent:SetText("")
                self.texts.healthValue:SetText("")
            else
                self.texts.healthPercent:SetText(healthPercentInt .. "%")
                self.texts.healthValue:SetText(health)
            end
            self.texts.healthValue:ClearAllPoints()
            self.texts.healthValue:SetPoint("RIGHT", TargetFrameHealthBar, "RIGHT", -0, 0)

            if maxMana > 0 then
                self.texts.manaPercent:SetText(manaPercentInt .. "%")
                self.texts.manaValue:SetText(mana)
                self.texts.manaValue:ClearAllPoints()
                self.texts.manaValue:SetPoint("RIGHT", TargetFrameManaBar, "RIGHT", -0, 0)
            else
                self.texts.manaPercent:SetText("")
                self.texts.manaValue:SetText("")
            end
        end

        if coloringEnabled then
            local r = 1
            local g = healthPercent
            local b = healthPercent
            self.texts.healthPercent:SetTextColor(r, g, b)
            self.texts.healthValue:SetTextColor(r, g, b)

            if maxMana > 0 then
                r = 1
                g = manaPercent
                b = manaPercent
                self.texts.manaPercent:SetTextColor(r, g, b)
                self.texts.manaValue:SetTextColor(r, g, b)
            end
        else
            self.texts.healthPercent:SetTextColor(1, 1, 1)
            self.texts.healthValue:SetTextColor(1, 1, 1)
            self.texts.manaPercent:SetTextColor(1, 1, 1)
            self.texts.manaValue:SetTextColor(1, 1, 1)
        end
    end

    function Setup:HookClassification()
        function _G.TargetFrame_CheckClassification()
            -- bars - i put this here because i dont want to create a new func just for this
            TargetFrameHealthBar:SetStatusBarTexture(Setup.texpath.. "healthDF2.tga")
            TargetFrameManaBar:SetStatusBarTexture(Setup.texpath.. "UI-HUD-UnitFrame-Target-PortraitOn-Bar-Mana-Status.blp")

            -- frames
            local classification = UnitClassification("target")
            if (classification == "worldboss") then
                TargetFrameTexture:SetTexture(self.texpath .. "UI-TargetingFrame-Boss.blp")
            elseif (classification == "rareelite") then
                TargetFrameTexture:SetTexture(self.texpath .. "UI-TargetingFrame-RareElite.blp")
            elseif (classification == "elite") then
                TargetFrameTexture:SetTexture(self.texpath .. "UI-TargetingFrame-Elite.blp")
            elseif (classification == "rare") then
                TargetFrameTexture:SetTexture(self.texpath .. "UI-TargetingFrame-Rare.blp")
            else
                TargetFrameTexture:SetTexture(self.texpath .. "UI-TargetingFrameDF1.blp")
            end
        end
    end

    function Setup:CheckTargetTapped()
        if not UnitExists("target") then return end

        if UnitIsPlayer("target") then
            TargetFrameHealthBar:SetStatusBarColor(0, 1, 0)
            return
        end

        if UnitIsTapped("target") and not UnitIsTappedByPlayer("target") then
            TargetFrameHealthBar:SetStatusBarColor(0.5, 0.5, 0.5)
        else
            TargetFrameHealthBar:SetStatusBarColor(0, 1, 0)
        end
    end

    function Setup:UpdateBarColor()
        if not UnitExists("target") then return end

        if not UnitIsPlayer("target") and UnitIsTapped("target") and not UnitIsTappedByPlayer("target") then
            TargetFrameHealthBar:SetStatusBarColor(0.5, 0.5, 0.5)
            return
        end

        if self.barColorState.colorClass and UnitIsPlayer("target") then
            local _, class = UnitClass("target")
            if class and RAID_CLASS_COLORS[class] then
                local color = RAID_CLASS_COLORS[class]
                TargetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
                return
            end
        end

        if self.barColorState.colorReaction then
            local reaction = UnitReaction("player", "target")
            if reaction then
                if reaction <= 2 then
                    TargetFrameHealthBar:SetStatusBarColor(1, 0, 0)  -- hostile - Red
                elseif reaction == 3 or reaction == 4 then
                    TargetFrameHealthBar:SetStatusBarColor(1, 1, 0)  -- neutral - Yellow
                else
                    TargetFrameHealthBar:SetStatusBarColor(0, 1, 0)  -- friendly - Green
                end
                return
            end
        end

        TargetFrameHealthBar:SetStatusBarColor(0, 1, 0)
    end

    function Setup:Run()
        self:KillBlizz()
        self:FrameTextures()
        self:HealthBar()
        self:HealthBarText()
        self:ManaBar()
        self:ManaBarText()
        self:Portrait()
        self:NameText()
        self:LevelText()
        self:UpdateTexts()
        self:HookClassification()
    end

    -- init setup
    Setup:Run()

    -- callbacks
    local callbacks = {}

    callbacks.darkMode = function(value)
        local intensity = DFRL:GetConfig("targetframe", "darkMode")
        local darkColor = {1 - intensity, 1 - intensity, 1 - intensity}
        local lightColor = {1, 1, 1}
        local color = value and darkColor or lightColor

        TargetFrameTexture:SetVertexColor(color[1], color[2], color[3])
        TargetFrameBackground:SetVertexColor(color[1], color[2], color[3])
    end

    callbacks.textShow = function(value)
        if value then
            Setup.texts.healthPercent:Show()
            Setup.texts.healthValue:Show()
            Setup.texts.manaPercent:Show()
            Setup.texts.manaValue:Show()
        else
            Setup.texts.healthPercent:Hide()
            Setup.texts.healthValue:Hide()
            Setup.texts.manaPercent:Hide()
            Setup.texts.manaValue:Hide()
        end
    end

    callbacks.noPercent = function()
        Setup:UpdateTexts()
    end

    callbacks.textColoring = function()
        Setup:UpdateTexts()
    end

    callbacks.healthSize = function(value)
        Setup.texts.config.healthFontSize = value
        Setup.texts.healthPercent:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
        Setup.texts.healthValue:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
    end

    callbacks.manaSize = function(value)
        Setup.texts.config.manaFontSize = value
        Setup.texts.manaPercent:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
        Setup.texts.manaValue:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
    end

    callbacks.frameFont = function(value)
        local fontPath
        if value == "Expressway" then
            fontPath = Setup.fontpath .. "Expressway.ttf"
        elseif value == "Homespun" then
            fontPath = Setup.fontpath .. "Homespun.ttf"
        elseif value == "Hooge" then
            fontPath = Setup.fontpath .. "Hooge.ttf"
        elseif value == "Myriad-Pro" then
            fontPath = Setup.fontpath .. "Myriad-Pro.ttf"
        elseif value == "Prototype" then
            fontPath = Setup.fontpath .. "Prototype.ttf"
        elseif value == "PT-Sans-Narrow-Bold" then
            fontPath = Setup.fontpath .. "PT-Sans-Narrow-Bold.ttf"
        elseif value == "PT-Sans-Narrow-Regular" then
            fontPath = Setup.fontpath .. "PT-Sans-Narrow-Regular.ttf"
        elseif value == "RobotoMono" then
            fontPath = Setup.fontpath .. "RobotoMono.ttf"
        elseif value == "BigNoodleTitling" then
            fontPath = Setup.fontpath .. "BigNoodleTitling.ttf"
        elseif value == "Continuum" then
            fontPath = Setup.fontpath .. "Continuum.ttf"
        elseif value == "DieDieDie" then
            fontPath = Setup.fontpath .. "DieDieDie.ttf"
        else
            fontPath = "Fonts\\FRIZQT__.TTF"
        end

        Setup.texts.config.font = fontPath
        Setup.texts.healthPercent:SetFont(fontPath, Setup.texts.config.healthFontSize, "OUTLINE")
        Setup.texts.healthValue:SetFont(fontPath, Setup.texts.config.healthFontSize, "OUTLINE")
        Setup.texts.manaPercent:SetFont(fontPath, Setup.texts.config.manaFontSize, "OUTLINE")
        Setup.texts.manaValue:SetFont(fontPath, Setup.texts.config.manaFontSize, "OUTLINE")
        Setup:NameText()
        Setup:LevelText()
    end

    callbacks.colorReaction = function(value)
        Setup.barColorState.colorReaction = value
        Setup:UpdateBarColor()
    end

    callbacks.colorClass = function(value)
        Setup.barColorState.colorClass = value
        Setup:UpdateBarColor()
    end

    callbacks.frameScale = function(value)
        TargetFrame:SetScale(value)
    end

    -- hook health bar value change (no need anymore
    -- but ill still keep it here for future use)
    -- HookScript(_G["TargetFrameHealthBar"], "OnValueChanged", function()
    --     -- targetState:updateColor()
    -- end)

    -- event handler
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MANA")
    f:RegisterEvent("UNIT_ENERGY")
    f:RegisterEvent("UNIT_RAGE")
    f:RegisterEvent("UNIT_FOCUS")
    f:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            local currentValue = GetCVar("statusBarText")
            if currentValue ~= "0" then
                SetCVar("statusBarText", "0")
                ReloadUI()
            end
        elseif event == "PLAYER_TARGET_CHANGED" then
            Setup:CheckTargetTapped()
            Setup:UpdateTexts()
            Setup:UpdateBarColor()
        elseif (event == "UNIT_HEALTH" and arg1 == "target") or
            (event == "UNIT_MANA" and arg1 == "target") or
            (event == "UNIT_ENERGY" and arg1 == "target") or
            (event == "UNIT_RAGE" and arg1 == "target") or
            (event == "UNIT_FOCUS" and arg1 == "target") then
            Setup:CheckTargetTapped()
            Setup:UpdateTexts()
            Setup:UpdateBarColor()
        end
    end)

    -- execute callbacks
    DFRL:RegisterCallback("targetframe", callbacks)
end)
