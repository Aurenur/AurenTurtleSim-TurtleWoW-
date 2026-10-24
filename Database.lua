-- Dynamic Turtle WoW Talent Storage
AurenTurtleSim = AurenTurtleSim or {}
AurenTurtleSimDB_Data = AurenTurtleSimDB_Data or {}
AurenTurtleSimDB_SavedSpecs = AurenTurtleSimDB_SavedSpecs or {}

function AurenTurtleSim:ScanTurtleWoWTalents()
    local _, playerClass = UnitClass("player")
    if not playerClass then playerClass = "PALADIN" end

    self.selectedClass = playerClass
    AurenTurtleSimDB_Data[playerClass] = {}

    local numTabs = GetNumTalentTabs()
    if not numTabs or numTabs <= 0 then numTabs = 3 end

    for tab = 1, numTabs do
        local tabName, tabIcon = GetTalentTabInfo(tab)
        AurenTurtleSimDB_Data[playerClass][tab] = {
            name = tabName or ("Tree " .. tab),
            icon = tabIcon or "Interface\\Icons\\INV_Misc_QuestionMark",
            talents = {}
        }

        local numTalents = GetNumTalents(tab) or 0
        for id = 1, numTalents do
            local name, iconTexture, tier, column, currentRank, maxRank = GetTalentInfo(tab, id)
            
            if name then
                local reqIndex = nil
                if GetTalentPrereqs then
                    local prereqTier, prereqColumn = GetTalentPrereqs(tab, id)
                    if prereqTier and prereqColumn then
                        for pId = 1, numTalents do
                            local _, _, pTier, pCol = GetTalentInfo(tab, pId)
                            if pTier == prereqTier and pCol == prereqColumn then
                                reqIndex = pId
                                break
                            end
                        end
                    end
                end

                AurenTurtleSimDB_Data[playerClass][tab].talents[id] = {
                    name = name,
                    row = tier or 1,
                    col = column or 1,
                    maxRank = maxRank or 5,
                    icon = iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark",
                    req = reqIndex,
                    desc = "Turtle WoW Live Talent"
                }
            end
        end
    end
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AurenTurtleSim]|r Scanned Turtle WoW |cffffd100" .. playerClass .. "|r talent tree!")
    end
end