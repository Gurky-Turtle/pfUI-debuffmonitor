-- load pfUI environment
setfenv(1, pfUI:GetEnvironment())

function pfUI.debuffmonitor:LoadGui()
  if not pfUI.gui then return end

  local function CreateSlashCmdLine(parent, index, cmd, description)
    parent.cmds = parent.cmds or {}
    if parent.cmds[index] then return end
    parent.cmds[index] = {}
    parent.cmds[index].cmd = parent:CreateFontString("Status", "LOW", "GameFontWhite")
    parent.cmds[index].cmd:SetFont(pfUI.font_default, C.global.font_size)
    parent.cmds[index].cmd:SetText("|cff33ffcc" .. cmd .. "|r")
    parent.cmds[index].cmd:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", - (parent:GetWidth() * 0.8), - (tonumber(C.global.font_size) * 2) * index)

    if description and description ~= "" then
      parent.cmds[index].desc = parent:CreateFontString("Status", "LOW", "GameFontWhite")
      parent.cmds[index].desc:SetFont(pfUI.font_default, C.global.font_size)
      parent.cmds[index].desc:SetText(" - " .. description)
      parent.cmds[index].desc:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", (parent:GetWidth() * 0.2), - (tonumber(C.global.font_size) * 2) * index)
    end

    parent:GetParent().objectCount = parent:GetParent().objectCount + 1
  end

  local old_gui = true
  
  if pfUI.gui.CreateGUIEntry then
    old_gui = false
  end

  pfUI.gui.dropdowns.debuffmonitor_show = {
    "always:" .. T["Always"], 
    "never:" .. T["Never"], 
    "target:" .. T["Target"], 
  }

  pfUI.gui.dropdowns.debuffmonitor_chat = {
    "SELF:" .. T["Self"], 
    "SAY:" .. T["Say"], 
    "YELL:" .. T["Yell"], 
    "PARTY:" .. T["Party"], 
    "RAID:" .. T["Raid"], 
  }

  if old_gui then
    local CreateConfig = pfUI.gui.CreateConfig
    local update = pfUI.gui.update

    if pfUI.gui.tabs.thirdparty then
      pfUI.gui.tabs.thirdparty.tabs.debuffmon = pfUI.gui.tabs.thirdparty.tabs:CreateTabChild(GetAddOnMetadata("pfUI-debuffmonitor", "X-LocalName"), true)
      pfUI.gui.tabs.thirdparty.tabs.debuffmon:SetScript("OnShow", function() 
        if not this.setup then
          CreateConfig(update[c], this, T["General"], nil, nil, "header")
          CreateConfig(nil, this, T["Frame Width"], C.debuffmon, "width")
          CreateConfig(nil, this, T["Font Size"], C.debuffmon, "font_size")
          CreateConfig(update["debuffmonitor"], this, T["Show Monitor"], C.debuffmon, "show", "dropdown", pfUI.gui.dropdowns.debuffmonitor_show) 
          CreateConfig(update["debuffmonitor"], this, T["Hide when Solo"], C.debuffmon, "hide_solo", "checkbox") 
          CreateConfig(update["debuffmonitor"], this, T["Show Background"], C.debuffmon, "background", "checkbox") 
          CreateConfig(update["debuffmonitor"], this, T["Monitor Only Alive Targets"], C.debuffmon, "alive", "checkbox")
          CreateConfig(update["debuffmonitor"], this, T["Allow Stats/Debuffs Reporting (Ctrl+Click)"], C.debuffmon, "report", "checkbox")
          CreateConfig(update["debuffmonitor"], this, T["Report to the Following Chat"], C.debuffmon, "report_chat", "dropdown", pfUI.gui.dropdowns.debuffmonitor_chat)

          CreateConfig(update[c], this, T["Display Stats"], nil, nil, "header")
          CreateConfig(update["debuffmonitor"], this, T["Target Name"], C.debuffmon, "name", "checkbox") 
          CreateConfig(update["debuffmonitor"], this, T["Target Resistances"], C.debuffmon, "resistances", "checkbox")
          CreateConfig(update["debuffmonitor"], this, T["Target Armor"], C.debuffmon, "armor", "checkbox")

          CreateConfig(update[c], this, T["Display Debuffs"], nil, nil, "header")
          if pfUI.debuffmonitor._debuff_list then
            for k in pfUI.debuffmonitor._debuff_list do
              pfUI:UpdateConfig("debuffmon", "debuff", pfUI.debuffmonitor._debuff_list[k].short, "1")
              CreateConfig(update["debuffmonitor"], this, T[pfUI.debuffmonitor._debuff_list[k].name], C.debuffmon.debuff, pfUI.debuffmonitor._debuff_list[k].short, "checkbox")
            end
          end

          CreateConfig(nil, this, T["Version"] .. ": " .. GetAddOnMetadata("pfUI-debuffmonitor", "Version"), nil, nil, "header")
          CreateConfig(update["debuffmonitor"], this, T["Website"], nil, nil, "button", function()
            pfUI.chat.urlcopy.CopyText("https://gitlab.com/dein0s_wow_vanilla/pfUI-debuffmonitor")
          end)

          this.setup = true
        end
      end)
    end
  else
    local Reload = pfUI.gui.Reload
    local CreateConfig = pfUI.gui.CreateConfig
    local CreateGUIEntry = pfUI.gui.CreateGUIEntry
    local U = pfUI.gui.UpdaterFunctions
    CreateGUIEntry(T["Thirdparty"], GetAddOnMetadata("pfUI-debuffmonitor", "X-LocalName"), function()
      CreateConfig(nil, T["General"], nil, nil, "header")
      CreateConfig(nil, T["Frame Width"], C.debuffmon, "width")
      CreateConfig(nil, T["Font Size"], C.debuffmon, "font_size")
      CreateConfig(U["debuffmonitor"], T["Show Monitor"], C.debuffmon, "show", "dropdown", pfUI.gui.dropdowns.debuffmonitor_show) 
      CreateConfig(U["debuffmonitor"], T["Hide when Solo"], C.debuffmon, "hide_solo", "checkbox") 
      CreateConfig(U["debuffmonitor"], T["Show Background"], C.debuffmon, "background", "checkbox") 
      CreateConfig(U["debuffmonitor"], T["Monitor Only Alive Targets"], C.debuffmon, "alive", "checkbox")
      CreateConfig(U["debuffmonitor"], T["Allow Stats/Debuffs Reporting (Ctrl+Click)"], C.debuffmon, "report", "checkbox")
      CreateConfig(U["debuffmonitor"], T["Report to the Following Chat"], C.debuffmon, "report_chat", "dropdown", pfUI.gui.dropdowns.debuffmonitor_chat)

      CreateConfig(nil, T["Display Stats"], nil, nil, "header")
      CreateConfig(U["debuffmonitor"], T["Target Name"], C.debuffmon, "name", "checkbox") 
      CreateConfig(U["debuffmonitor"], T["Target Resistances"], C.debuffmon, "resistances", "checkbox") 
      CreateConfig(U["debuffmonitor"], T["Target Armor"], C.debuffmon, "armor", "checkbox")


      CreateConfig(nil, T["Display Debuffs"], nil, nil, "header")
      if pfUI.debuffmonitor._debuff_list then
        for k in pfUI.debuffmonitor._debuff_list do
          pfUI:UpdateConfig("debuffmon", "debuff", pfUI.debuffmonitor._debuff_list[k].short, "1")
          CreateConfig(U["debuffmonitor"], T[pfUI.debuffmonitor._debuff_list[k].name], C.debuffmon.debuff, pfUI.debuffmonitor._debuff_list[k].short, "checkbox")
        end
      end

      CreateConfig(nil, T["Version"] .. ": " .. GetAddOnMetadata("pfUI-debuffmonitor", "Version"), nil, nil, "header")
      CreateConfig(U["debuffmonitor"], T["Website"], nil, nil, "button", function()
        pfUI.chat.urlcopy.CopyText("https://gitlab.com/dein0s_wow_vanilla/pfUI-debuffmonitor")
      end)

    end)
  end
end

pfUI.debuffmonitor:LoadGui()
