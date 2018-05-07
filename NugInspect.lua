NugInspect = CreateFrame("Frame","NugInspect")
local NugInspect = NugInspect
local GetInventoryItemLink = GetInventoryItemLink

NugInspect:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)

NugInspect:RegisterEvent("ADDON_LOADED")

_G.BINDING_HEADER_NUGINSPECT = "NugInspect"

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

        local ail = InspectModelFrame.NugInspectAILText
        if not ail then
            InspectModelFrame.NugInspectAILText = InspectModelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ail = InspectModelFrame.NugInspectAILText
            ail:SetWordWrap(false)
            ail:SetJustifyH("LEFT")
            ail:SetWidth(50)
            ail:SetPoint("BOTTOMRIGHT", -3, 5)
            ail:Hide()
        end


        if not UnitIsPlayer(unit) or not UnitIsFriend(unit, "player") then
            InspectSwitchTabs(1)
            PanelTemplates_DisableTab(InspectFrame, 2);
            PanelTemplates_DisableTab(InspectFrame, 3);
			viewBtn:Hide()
        end
    end)

    NugInspect.PaperDollButtons = {}
    NugInspect.SlotToButton = {}

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
            NugInspect.SlotToButton[button:GetID()] = button
    end)

end

-- Construct your saarch pattern based on the existing global string:
local S_ITEM_LEVEL   = "^" .. gsub(ITEM_LEVEL, "%%d", "(%%d+)")
local S_ITEM_LEVEL_ALT   = "^" .. gsub(ITEM_LEVEL_ALT, "%%d", "(%%d+)")

-- Create the tooltip:
local scantip = CreateFrame("GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate")
scantip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetItemLevelFromTooltip(unit, slotID)
    -- Pass the item link to the tooltip:
    scantip:SetInventoryItem(unit, slotID)

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


local IsTwoHanded = function(itemLink)
    local _, _, _, itemEquipLoc = GetItemInfoInstant(itemLink)
    return itemEquipLoc == "INVTYPE_2HWEAPON"
end

local INVSLOT_MAINHAND = INVSLOT_MAINHAND
local INVSLOT_OFFHAND = INVSLOT_OFFHAND
function NugInspect.MODIFIER_STATE_CHANGED(self, event)
    local unit = InspectFrame.unit;

    local isFriend = UnitIsFriend(unit, "player")
    local isPlayer = UnitIsPlayer(unit)

    local TotalItemLevel = 0
    local TotalItemCount = 0

    for i=1, 17 do
        local button = NugInspect.SlotToButton[i]

        if IsAltKeyDown() and isFriend and isPlayer and (i~=4) then
            local slotID = button:GetID()
            if slotID and unit then
                local itemLink = GetInventoryItemLink(unit, slotID)
                local iLevel
                if itemLink then
                    iLevel = GetItemLevelFromTooltip(unit, slotID)--itemLink)
                    
                    if slotID > 16 then
                        local isArtifact = GetInventoryItemQuality(unit, slotID) == 6
                        if isArtifact then
                            local mhLink = GetInventoryItemLink(unit, INVSLOT_MAINHAND)
                            local ohLink = GetInventoryItemLink(unit, INVSLOT_OFFHAND)
                            local mhLevel = mhLink and GetItemLevelFromTooltip(unit, INVSLOT_MAINHAND) or 0
                            local ohLevel = ohLink and GetItemLevelFromTooltip(unit, INVSLOT_OFFHAND) or 0
                            iLevel = math.max(mhLevel, ohLevel)
                        end
                    end                   

                    button.ItemLevelText:SetText(iLevel)
                    button.ItemLevelText:Show()
                else
                    iLevel = 0
                    button.ItemLevelText:Hide()
                end

                if slotID == 17 and not itemLink then
                    itemLink = GetInventoryItemLink(unit, INVSLOT_MAINHAND)
                    if itemLink and IsTwoHanded(itemLink) then
                        iLevel = GetItemLevelFromTooltip(unit, INVSLOT_MAINHAND)
                    end
                end

                if slotID ~= 4 and slotID ~=19 then
                    TotalItemLevel = TotalItemLevel + iLevel
                    TotalItemCount = TotalItemCount + 1
                end
            end
        else
            button.ItemLevelText:Hide()
        end
    end

    local ailt = InspectModelFrame.NugInspectAILText
    if ailt then
        if TotalItemCount > 0 then
            local AverageItemLevel = math.floor(TotalItemLevel/TotalItemCount + 0.5)

            ailt:Show()
            ailt:SetFormattedText("AIL: %d", AverageItemLevel)
        else
            ailt:Hide()
        end
    end
end
