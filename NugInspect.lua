NugInspect = CreateFrame("Frame","NugInspect")

NugInspect:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

NugInspect:RegisterEvent("ADDON_LOADED")

BINDING_HEADER_NUGINSPECT = "NugInspect"

function NugInspect:Inspect()
    if InspectFrame and InspectFrame:IsVisible() then
        HideUIPanel(InspectFrame)
    else
        if UnitExists("target") then
            if UnitIsPlayer("target") and not UnitIsEnemy("player", "target") then
                InspectUnit("target")
            else
                if not InspectFrame then
                    LoadAddOn("Blizzard_InspectUI")
                end
                InspectFrame.unit = "target"
                INSPECTED_UNIT = "target"
                ShowUIPanel(InspectFrame);
                InspectFrame_UpdateTabs();
            end
        else
            InspectUnit("player")
        end
    end
end

function NugInspect.ADDON_LOADED(self,event,arg1)
    if arg1 ~= "Blizzard_InspectUI" then return end
    self:UnregisterEvent("ADDON_LOADED")

    InspectGuildText:SetPoint("TOP", "InspectTitleText", "BOTTOM", 0, 10)

    local SetPaperDollBackground1 = SetPaperDollBackground
    SetPaperDollBackground = function(model, unit)
        if not UnitRace(unit) then unit = "player" end
        return SetPaperDollBackground1(model, unit)
    end

    -- InspectFrame:SetScript("OnEvent", function (self, event, unit, ...)
    -- -- InspectFrame:HookScript("OnEvent", function (self, event, unit, ...)
    --     if ( event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" ) then
    --         if ( (event == "PLAYER_TARGET_CHANGED" and (self.unit == "target" or self.unit == "player")) or
    --              (event == "GROUP_ROSTER_UPDATE" and self.unit ~= "target") ) then
    --         -- if (event == "PLAYER_TARGET_CHANGED" and self.unit == "player") then
    --             HideUIPanel(InspectFrame)
    --         -- end
    --         -- if not InspectFrame:IsVisible() then
    --             if UnitExists("target") then
    --                 NugInspect:Inspect()
    --             end
    --         end
    --     else
    --         InspectFrame_OnEvent(self, event, unit, ...)
    --     end
    -- end)

    hooksecurefunc("InspectFrame_UpdateTabs", function()
        local unit = InspectFrame.unit
        local guild, rank, rankid = GetGuildInfo(unit)
        if guild then
            InspectGuildText:SetFormattedText("%s (%d) of <%s>", rank, rankid, guild)
            InspectGuildText:Show()
        else
            InspectGuildText:Hide()
        end

		local viewBtn = InspectPaperDollFrame.ViewButton
		viewBtn:SetWidth(70)
		viewBtn:SetText("View")
		viewBtn:ClearAllPoints()
		viewBtn:SetPoint("BOTTOMLEFT", InspectPaperDollFrame, "BOTTOMLEFT", 10, 10)

        local st = NugInspectServerText
        if not st then
            NugInspectServerText = InspectPaperDollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            st = NugInspectServerText
            st:SetWordWrap(false)
            st:SetJustifyH("RIGHT")
            st:SetWidth(110)
            st:SetPoint("BOTTOMRIGHT", -15, 15)
        end
        local name, realm = UnitName(unit)
        st:SetText(realm or "")


        if not UnitIsPlayer(unit) then
            InspectSwitchTabs(1)
            PanelTemplates_DisableTab(InspectFrame, 2);
            PanelTemplates_DisableTab(InspectFrame, 3);
			viewBtn:Hide()
        end
    end)

    NugInspect.PaperDollButtons = {}

    InspectFrame:HookScript("OnShow", function()
        NugInspect:RegisterEvent("MODIFIER_STATE_CHANGED")
        NugInspect:MODIFIER_STATE_CHANGED()
    end)
    InspectFrame:HookScript("OnHide", function()
        NugInspect:UnregisterEvent("MODIFIER_STATE_CHANGED")
    end)

    hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(button)
            if not button.ItemLevelText then
                local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                text:SetFont(GameFontHighlight:GetFont(),12,"OUTLINE");
                text:SetWidth(60)
                text:SetPoint("BOTTOM", button, "BOTTOM", 0,0)
                button.ItemLevelText = text
            end

            NugInspect.PaperDollButtons[button] = true
    end)

end

-- Construct your saarch pattern based on the existing global string:
local S_ITEM_LEVEL   = "^" .. gsub(ITEM_LEVEL, "%%d", "(%%d+)")
local S_ITEM_LEVEL_ALT   = "^" .. gsub(ITEM_LEVEL_ALT, "%%d", "(%%d+)")

-- Create the tooltip:
local scantip = CreateFrame("GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate")
scantip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetItemLevelFromTooltip(itemLink)
    -- Pass the item link to the tooltip:
    scantip:SetHyperlink(itemLink)

    -- Scan the tooltip:
    for i = 2, scantip:NumLines() do -- Line 1 is always the name so you can skip it.
        local text = _G["MyScanningTooltipTextLeft"..i]:GetText()
        if text and text ~= "" then
            -- local currentUpgradeLevel, maxUpgradeLevel = strmatch(text, S_UPGRADE_LEVEL)
			local itemLevel = strmatch(text, S_ITEM_LEVEL)
            if itemLevel then
                return itemLevel
            end
        end
    end
end




function NugInspect.MODIFIER_STATE_CHANGED(self, event)
    local unit = InspectFrame.unit;

    for button in pairs(self.PaperDollButtons) do
        if IsAltKeyDown() then
            local slotID = button:GetID()
            if slotID and unit then
                local itemLink = GetInventoryItemLink(unit, slotID)
                if itemLink then
                    -- local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
					local iLevel = GetItemLevelFromTooltip(itemLink)
                    button.ItemLevelText:SetText(iLevel)
                    button.ItemLevelText:Show()
                else
                    button.ItemLevelText:Hide()
                end
            end
        else
            button.ItemLevelText:Hide()
        end
    end
end
