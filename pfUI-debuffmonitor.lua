pfUI:RegisterModule("debuffmonitor", function ()

  local config
  local font_size
  local font = C.global.font_combat
  local border = tonumber(C.appearance.border.actionbars) > 0 and tonumber(C.appearance.border.actionbars) or 1
  local scanner = libtipscan:GetScanner("debuffmonitor")

  local debuff_list = {
    ["Sunder Armor"] = {
      ["name"] = "Sunder Armor",
      ["short"] = "sa", 
      ["texture"] = "Interface\\Icons\\Ability_Warrior_Sunder"},
    ["Expose Armor"] = {
      ["name"] = "Expose Armor",
      ["short"] = "ea",
      ["texture"] = "Interface\\Icons\\Ability_Warrior_Riposte"},
    ["Armor Shatter"] = {
      ["name"] = "Armor Shatter",
      ["short"] = "as",
      ["texture"] = "Interface\\Icons\\INV_Axe_12"},
    ["Faerie Fire"] = {
      ["name"] = "Faerie Fire",
      ["short"] = "ff",
      ["texture"] = "Interface\\Icons\\Spell_Nature_FaerieFire"},
    ["Curse of Recklessness"] = {
      ["name"] = "Curse of Recklessness",
      ["short"] = "cor",
      ["texture"] = "Interface\\Icons\\Spell_Shadow_UnholyStrength"},
    ["Crystal Yield"] = {
      ["name"] = "Crystal Yield",
      ["short"] = "cy",
      ["texture"] = "Interface\\Icons\\INV_Misc_Gem_Amethyst_01"},
    ["Nightfall"] = {
      ["name"] = "Nightfall",
      ["short"] = "nf",
      ["texture"] = "Interface\\Icons\\Spell_Holy_ElunesGrace"},
    ["Elemental Vulnerability"] = {
      ["name"] = "Elemental Vulnerability",
      ["short"] = "ev",
      ["tooltip_name"] = "Elemental Vulnerability",
      ["texture"] = "Interface\\Icons\\Spell_Holy_Dizzy"},
    ["Curse of the Elements"] = {
      ["name"] = "Curse of the Elements",
      ["short"] = "coe",
      ["texture"] = "Interface\\Icons\\Spell_Shadow_ChillTouch"},
    ["Scorch"] = {
      ["name"] = "Scorch",
      ["short"] = "sc",
      ["texture"] = "Interface\\Icons\\Spell_Fire_SoulBurn"},
    ["Ignite"] = {
      ["name"] = "Ignite",
      ["short"] = "ig",
      ["texture"] = "Interface\\Icons\\Spell_Fire_Incinerate"},
    ["Arcanite Dragonling"] = {
      ["name"] = "Arcanite Dragonling",
      ["short"] = "ad",
      ["texture"] = "Interface\\Icons\\Spell_Fire_Fireball"},
    ["Winter's Chill"] = {
      ["name"] = "Winter's Chill",
      ["short"] = "wc",
      ["texture"] = "Interface\\Icons\\Spell_Frost_ChillingBlast"},
    ["Curse of Shadows"] = {
      ["name"] = "Curse of Shadows",
      ["short"] = "cos",
      ["texture"] = "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde"},
    ["Shadow Weaving"] = {
      ["name"] = "Shadow Weaving",
      ["short"] = "sw",
      ["tooltip_name"] = "Shadow Vulnerability",
      ["texture"] = "Interface\\Icons\\Spell_Shadow_BlackPlague"},
    ["Shadow Bolt"] = {
      ["name"] = "Shadow Bolt",
      ["short"] = "sb",
      ["texture"] = "Interface\\Icons\\Spell_Shadow_ShadowBolt"},
    ["Vampiric Embrace"] = {
      ["name"] = "Vampiric Embrace",
      ["short"] = "ve",
      ["texture"] = "Interface\\Icons\\Spell_Shadow_UnsummonBuilding"},
  }

  pfUI.debuffmonitor = CreateFrame("Frame", "pfDebuffMonitor", UIParent)
  pfUI.debuffmonitor:RegisterEvent("VARIABLES_LOADED")

  local function SendReport(report)
    local chat = config.report_chat
    if chat == "RAID" and not UnitInRaid("player") then chat = "PARTY" end
    if chat == "PARTY" and not UnitExists("party1") then chat = "SAY" end
    if chat == "SELF" then
      message(report)
    else
      SendChatMessage(report, chat)
    end
  end

  local function ReportResistances()
    if pfUI.debuffmonitor.target.unit ~= nil and config.report == "1" then
      local unit = pfUI.debuffmonitor.target.unit
      local report_string = UnitName(unit) .. " has: " .. (UnitResistance(unit, 0) or "??") .. " armor"
      if config.resistances == "1" then
        report_string = report_string .. ", " .. (UnitResistance(unit, 2) or "??") .. " fire, " .. (UnitResistance(unit, 3) or "??") .. " nature, " ..  (UnitResistance(unit, 4) or "??") .. " frost, " .. (UnitResistance(unit, 5) or "??") .. " shadow resistances"
      end
      if IsControlKeyDown() then
        SendReport(report_string)
      end
    end
  end

  -- third row elements (debuffs)
  local function FindDebuff(texture, name)
    local needle = debuff_list[name].tooltip_name
    local found = false
    local stacks = 0
    if pfUI.debuffmonitor.target.unit ~= nil then
      for i = 1, 16 do
        local d_texture, d_stacks, d_type = UnitDebuff(pfUI.debuffmonitor.target.unit, i)
        if d_texture == texture then
          if needle == nil or needle == "" then
            found = true
            stacks = d_stacks
          else
            scanner:SetUnitDebuff(pfUI.debuffmonitor.target.unit, i)
            local d_name = scanner:Line(1)
            if strupper(d_name) == strupper(needle) then
              found = true
              stacks = d_stacks
            end
          end
        end
      end
    end
    return found, stacks
  end

  local function ReportDebuff()
    local report_string
    if pfUI.debuffmonitor.target.unit ~= nil  and config.report == "1" then
      if not this.active then
        report_string = UnitName(pfUI.debuffmonitor.target.unit) .. ": " .. this.name .. " is NOT ACTIVE"
      else
        report_string = UnitName(pfUI.debuffmonitor.target.unit) .. ": " .. this.name .. " is ACTIVE"
        if this.stacks:GetText() ~= nil and this.stacks:GetText() ~= "" then
          report_string = report_string .. " (x" .. this.stacks:GetText() .. ")"
        end
      end
      if IsControlKeyDown() and UnitIsDead(pfUI.debuffmonitor.target.unit) ~= 1 then
        SendReport(report_string)
      end
    end
  end

  local function CreateDebuff(d_name, d_short)
    local debuff_frame = CreateFrame("Frame", nil, pfUI.debuffmonitor.target.debuffs)
    debuff_frame.short = d_short
    debuff_frame.name = d_name
    debuff_frame.active = false
    debuff_frame:SetFrameStrata("MEDIUM")
    debuff_frame:EnableMouse(true)
    CreateBackdrop(debuff_frame, 0.5)
    debuff_frame.backdrop:SetBackdropBorderColor(1, .3, .3, .75)

    debuff_frame.texture = debuff_frame:CreateTexture(nil, "OVERLAY")
    debuff_frame.texture:SetTexCoord(.07,.93,.07,.93)
    debuff_frame.texture:SetAllPoints(debuff_frame)
    debuff_frame.texture:SetTexture(debuff_list[d_name].texture)
    debuff_frame.texture:SetAlpha(0.3)

    debuff_frame.stacks = debuff_frame:CreateFontString("Status", "OVERLAY", "GameFontNormal")
    debuff_frame.stacks:SetTextColor(0,1,1,1)
    debuff_frame.stacks:SetJustifyH("CENTER")
    debuff_frame.stacks:SetJustifyV("CENTER")
    debuff_frame.stacks:SetAllPoints(debuff_frame)

    debuff_frame:SetScript("OnMouseDown", ReportDebuff)

    debuff_frame:SetScript("OnUpdate", function()
      if ( this.tick or .2) > GetTime() then return else this.tick = GetTime() + .2 end
      if pfUI.debuffmonitor.target:IsShown() then
        local found, stacks = FindDebuff(debuff_list[this.name].texture, this.name)
        if not found then
          this.active = false
          this.stacks:SetText("")
          this.texture:SetAlpha(0.3)
          this.backdrop:Show()
          return
        else
          this.active = true
          this.backdrop:Hide()
          this.texture:SetAlpha(1)
          if stacks > 1 then
            this.stacks:SetText(stacks)
          else
            this.stacks:SetText("")
          end
        end
        return
      end
      return
    end)
    return debuff_frame
  end

  -- display stuff
  local function UpdateDisplay()
    local scan_unit
    if UnitIsPlayer("target") then
      if not UnitIsPlayer("targettarget") and UnitCanAttack("player", "targettarget") then
        scan_unit = "targettarget"
      end
    else
      if UnitCanAttack("player", "target") then
        scan_unit = "target"
      end
    end

    if config.alive == "1" and (scan_unit ~= nil and UnitIsDead(scan_unit) == 1) then
      scan_unit = nil
    end

    if scan_unit == nil then
      pfUI.debuffmonitor.target.unit = nil
      pfUI.debuffmonitor.target.name:SetText("")
      pfUI.debuffmonitor.target.armor:SetText("|cffffff00ARMOR: ")
      pfUI.debuffmonitor.target.fire:SetText("|cffFF0000FIRE: ")
      pfUI.debuffmonitor.target.nature:SetText("|cff00FF00NATURE: ")
      pfUI.debuffmonitor.target.frost:SetText("|cff4AE8F5FROST: ")
      pfUI.debuffmonitor.target.shadow:SetText("|cff800080SHADOW: ")
      if config.show == "target" then
        pfUI.debuffmonitor.target:Hide()
      end
    else
      pfUI.debuffmonitor.target.unit = scan_unit
      pfUI.debuffmonitor.target.name:SetText(strupper(UnitName(scan_unit)))
      pfUI.debuffmonitor.target.armor:SetText("|cffffff00ARMOR: " .. UnitResistance(scan_unit, 0) or "??")
      pfUI.debuffmonitor.target.fire:SetText("|cffFF0000FIRE: " .. UnitResistance(scan_unit, 2) or "??")
      pfUI.debuffmonitor.target.nature:SetText("|cff00FF00NATURE: " .. UnitResistance(scan_unit, 3) or "??")
      pfUI.debuffmonitor.target.frost:SetText("|cff4AE8F5FROST: " .. UnitResistance(scan_unit, 4) or "??")
      pfUI.debuffmonitor.target.shadow:SetText("|cff800080SHADOW: " .. UnitResistance(scan_unit, 5) or "??")
      pfUI.debuffmonitor.target:Show()
    end

    if config.hide_solo == "1" then
      if not UnitExists("party1") and not UnitInRaid("player") then
        pfUI.debuffmonitor.target:Hide()
      end
    end

    if config.show == "never" then
      pfUI.debuffmonitor.target:Hide()
    elseif config.show == "always" then
      pfUI.debuffmonitor.target:Show()
    end
  end

  -- dynamic stuff
  local function NumDebuffsToShow()
    local counter = 0
    for name, _ in debuff_list do
      if config.debuff[debuff_list[name].short] == "1" then
        counter = counter + 1
      end
    end
    return counter
  end

  local function DebuffSize()
    local spacing = border  * 2
    local actual_width = pfUI.debuffmonitor.target:GetWidth() - spacing * (NumDebuffsToShow() + 1)
    local size = actual_width / NumDebuffsToShow()
    return size <= 28 and size or 28
  end

  local function UpdateConfigDebuffs()
    local parent = config.resistances == "1" and "row_3" or "row_2"
    local size = DebuffSize()
    local index = 0
    local spacing = border * 2
    local offset
    for d_short in pfUI.debuffmonitor.target.debuffs.frames do
      if config.debuff[d_short] ~= "1" then
        pfUI.debuffmonitor.target.debuffs.frames[d_short]:Hide()
      else
        index = index + 1
        offset = (index - 1) * (size + spacing) + spacing
        pfUI.debuffmonitor.target.debuffs.frames[d_short]:ClearAllPoints()
        pfUI.debuffmonitor.target.debuffs.frames[d_short]:SetWidth(size)
        pfUI.debuffmonitor.target.debuffs.frames[d_short]:SetHeight(size)
        pfUI.debuffmonitor.target.debuffs.frames[d_short]:SetPoint("TOPLEFT", pfUI.debuffmonitor.target[parent], "TOPLEFT", offset, 0)
        pfUI.debuffmonitor.target.debuffs.frames[d_short]:Show()
      end
    end
  end

  function pfUI.debuffmonitor:Load()
    config = C.debuffmon
    font_size = config.font_size == "-1" and tonumber(C.global.font_size) or tonumber(config.font_size)

    pfUI.debuffmonitor.target = CreateFrame("Frame", "pfDebuffMonitorTarget", UIParent)
    pfUI.debuffmonitor.target:SetWidth(config.width == "-1" and C.chat.right.width or config.width)
    pfUI.debuffmonitor.target:SetHeight(56)
    pfUI.debuffmonitor.target:EnableMouse(true)
    CreateBackdrop(pfUI.debuffmonitor.target)
  
    pfUI.debuffmonitor.target.first_row = "#name#armor"
    pfUI.debuffmonitor.target.second_row = "#fire#nature#frost#shadow"

    -- create rows
    for i=1,4 do
      pfUI.debuffmonitor.target["row_" .. i] = CreateFrame("Frame", nil, pfUI.debuffmonitor.target)
      pfUI.debuffmonitor.target["row_" .. i]:SetWidth(pfUI.debuffmonitor.target:GetWidth())
      pfUI.debuffmonitor.target["row_" .. i]:SetHeight(pfUI.debuffmonitor.target:GetHeight()/4)
      pfUI.debuffmonitor.target["row_" .. i]:ClearAllPoints()
      pfUI.debuffmonitor.target["row_" .. i]:SetPoint("TOPLEFT", pfUI.debuffmonitor.target, "TOPLEFT", 0, -(pfUI.debuffmonitor.target["row_" .. i]:GetHeight() * (i-1)))
    end

  -- first row elements (name, armor)
    for index, value in pairs({strsplit("#", pfUI.debuffmonitor.target.first_row)}) do
      pfUI.debuffmonitor.target[value] = pfUI.debuffmonitor.target:CreateFontString("Status", "LOW", "GameFontNormal")
      pfUI.debuffmonitor.target[value]:ClearAllPoints()
      if index == 1 then
        pfUI.debuffmonitor.target[value]:SetPoint("TOPLEFT", pfUI.debuffmonitor.target.row_1, "TOPLEFT", 0, 0)
        pfUI.debuffmonitor.target[value]:SetPoint("BOTTOMRIGHT", pfUI.debuffmonitor.target.row_1, "BOTTOMRIGHT", 0, 0)
      else
        pfUI.debuffmonitor.target[value]:SetPoint("TOPLEFT", pfUI.debuffmonitor.target.row_1, "TOPLEFT", (pfUI.debuffmonitor.target:GetWidth()/4) * 3, 0)
        pfUI.debuffmonitor.target[value]:SetPoint("BOTTOMRIGHT", pfUI.debuffmonitor.target.row_1, "BOTTOMRIGHT", (pfUI.debuffmonitor.target:GetWidth()/4) * 3, 0)
      end
      pfUI.debuffmonitor.target[value]:SetFontObject(GameFontWhite)
      pfUI.debuffmonitor.target[value]:SetFont(font, font_size)
      pfUI.debuffmonitor.target[value]:SetJustifyH("LEFT")
      pfUI.debuffmonitor.target[value]:SetText(strupper(value))
    end

  -- second row elements (resistances)
    for index, value in pairs({strsplit("#", pfUI.debuffmonitor.target.second_row)}) do
      pfUI.debuffmonitor.target[value] = pfUI.debuffmonitor.target:CreateFontString("Status", "LOW", "GameFontNormal")
      pfUI.debuffmonitor.target[value]:SetWidth(pfUI.debuffmonitor.target:GetWidth()/4)
      pfUI.debuffmonitor.target[value]:ClearAllPoints()
      pfUI.debuffmonitor.target[value]:SetPoint("TOPLEFT", pfUI.debuffmonitor.target.row_2, "TOPLEFT", (pfUI.debuffmonitor.target:GetWidth()/4) * (index - 1), 0)
      pfUI.debuffmonitor.target[value]:SetPoint("BOTTOMRIGHT", pfUI.debuffmonitor.target.row_2, "BOTTOMRIGHT", (pfUI.debuffmonitor.target:GetWidth()/4) * (index - 1), 0)
      pfUI.debuffmonitor.target[value]:SetFontObject(GameFontWhite)
      pfUI.debuffmonitor.target[value]:SetFont(font, font_size)
      pfUI.debuffmonitor.target[value]:SetJustifyH("LEFT")
      pfUI.debuffmonitor.target[value]:SetText(strupper(value))
    end
    pfUI.debuffmonitor.target:SetScript("OnMouseDown", ReportResistances)

    pfUI.debuffmonitor.target.debuffs = CreateFrame("Frame", nil, pfUI.debuffmonitor.target)
    pfUI.debuffmonitor.target.debuffs.frames = {}
    for l_name, _ in debuff_list do
      pfUI.debuffmonitor.target.debuffs.frames[debuff_list[l_name].short] = CreateDebuff(debuff_list[l_name].name, debuff_list[l_name].short)
    end
    
    pfUI.debuffmonitor:UnregisterEvent("VARIABLES_LOADED")
    pfUI.debuffmonitor:SetScript("OnEvent", UpdateDisplay)
    pfUI.debuffmonitor:RegisterEvent("PLAYER_TARGET_CHANGED")
    pfUI.debuffmonitor:SetScript("OnUpdate", function()
      -- throttle updates to once per seconds
      if ( this.tick or 1) > GetTime() then return else this.tick = GetTime() + 1 end
      UpdateDisplay()
    end)
  
    pfUI.debuffmonitor:UpdateConfig()  
  end

  function pfUI.debuffmonitor:UpdateConfig()
    -- pfUI.debuffmonitor.target:ClearAllPoints()
    if config.name ~= "1" then
      pfUI.debuffmonitor.target.name:Hide()
    else
      pfUI.debuffmonitor.target.name:Show()
    end

    if config.armor ~= "1" then
      pfUI.debuffmonitor.target.armor:Hide()
    else
      pfUI.debuffmonitor.target.armor:Show()
    end

    if config.resistances ~= "1" then
      pfUI.debuffmonitor.target.fire:Hide()
      pfUI.debuffmonitor.target.nature:Hide()
      pfUI.debuffmonitor.target.frost:Hide()
      pfUI.debuffmonitor.target.shadow:Hide()
      --
      -- pfUI.debuffmonitor.target.row_4:Hide()
      pfUI.debuffmonitor.target:SetHeight(42)
    else
      pfUI.debuffmonitor.target.fire:Show()
      pfUI.debuffmonitor.target.nature:Show()
      pfUI.debuffmonitor.target.frost:Show()
      pfUI.debuffmonitor.target.shadow:Show()
      --
      -- pfUI.debuffmonitor.target.row_4:Show()
      pfUI.debuffmonitor.target:SetHeight(56)
    end

    if config.background ~= "1" then
      pfUI.debuffmonitor.target.backdrop:Hide()
    else
      pfUI.debuffmonitor.target.backdrop:Show()
    end

    pfUI.debuffmonitor.target:SetPoint("BOTTOMLEFT", pfUI.chat.right or UIParent, "TOPLEFT", 0, 5)
    UpdateMovable(pfUI.debuffmonitor.target)

    UpdateConfigDebuffs()
    UpdateDisplay()
  end

  pfUI.debuffmonitor:SetScript("OnEvent", pfUI.debuffmonitor.Load)

  pfUI.debuffmonitor._debuff_list = debuff_list

end)
