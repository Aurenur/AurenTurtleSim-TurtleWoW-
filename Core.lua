-- Core Engine for AurenTurtleSim
AurenTurtleSim = AurenTurtleSim or {}
AurenTurtleSim.selectedClass = "PALADIN"
AurenTurtleSim.activeTab = 1
AurenTurtleSim.pointsRemaining = 51

AurenTurtleSim.state = {
    [1] = {},
    [2] = {},
    [3] = {}
}

function AurenTurtleSim:Reset()
    self.pointsRemaining = 51
    self.state = { [1] = {}, [2] = {}, [3] = {} }
    
    if AurenTurtleSimDB_Data and AurenTurtleSimDB_Data[self.selectedClass] then
        for tab = 1, 3 do
            local tabData = AurenTurtleSimDB_Data[self.selectedClass][tab]
            if tabData and tabData.talents then
                for id in pairs(tabData.talents) do
                    self.state[tab][id] = 0
                end
            end
        end
    end
end

function AurenTurtleSim:GetPointsInTab(tab)
    if not tab or not self.state or not self.state[tab] then return 0 end
    local total = 0
    for _, rank in pairs(self.state[tab]) do
        total = total + (rank or 0)
    end
    return total
end

function AurenTurtleSim:GetRank(tab, id)
    if not tab or not id then return 0 end
    if not self.state then return 0 end
    if not self.state[tab] then return 0 end
    return self.state[tab][id] or 0
end

function AurenTurtleSim:CanAddPoint(tab, id)
    if self.pointsRemaining <= 0 then return false end
    if not AurenTurtleSimDB_Data or not AurenTurtleSimDB_Data[self.selectedClass] then return false end

    local tabData = AurenTurtleSimDB_Data[self.selectedClass][tab]
    if not tabData or not tabData.talents or not tabData.talents[id] then return false end

    local talent = tabData.talents[id]
    local currentRank = self:GetRank(tab, id)
    if currentRank >= (talent.maxRank or 1) then return false end

    local requiredPointsForTier = ((talent.row or 1) - 1) * 5
    if self:GetPointsInTab(tab) < requiredPointsForTier then return false end

    if talent.req and tabData.talents[talent.req] then
        local reqRank = self:GetRank(tab, talent.req)
        local reqMax = tabData.talents[talent.req].maxRank or 1
        if reqRank < reqMax then return false end
    end

    return true
end

function AurenTurtleSim:CanRemovePoint(tab, id)
    local currentRank = self:GetRank(tab, id)
    if currentRank <= 0 then return false end

    if not AurenTurtleSimDB_Data or not AurenTurtleSimDB_Data[self.selectedClass] then return false end
    local tabData = AurenTurtleSimDB_Data[self.selectedClass][tab]
    if not tabData or not tabData.talents or not tabData.talents[id] then return false end
    local talent = tabData.talents[id]

    for tid, tdata in pairs(tabData.talents) do
        if tdata and tdata.req == id and self:GetRank(tab, tid) > 0 then
            if currentRank <= (tdata.maxRank or 1) then
                return false
            end
        end
    end

    local currentTabPoints = self:GetPointsInTab(tab)
    for tid, tdata in pairs(tabData.talents) do
        local spentInChild = self:GetRank(tab, tid)
        if spentInChild > 0 and tdata and tdata.row and talent.row and tdata.row > talent.row then
            local reqForChildTier = (tdata.row - 1) * 5
            if (currentTabPoints - 1) < reqForChildTier then
                return false
            end
        end
    end

    return true
end

function AurenTurtleSim:AddPoint(tab, id)
    if self:CanAddPoint(tab, id) then
        if not self.state[tab] then self.state[tab] = {} end
        self.state[tab][id] = self:GetRank(tab, id) + 1
        self.pointsRemaining = self.pointsRemaining - 1
        return true
    end
    return false
end

function AurenTurtleSim:RemovePoint(tab, id)
    if self:CanRemovePoint(tab, id) then
        if not self.state[tab] then self.state[tab] = {} end
        self.state[tab][id] = self:GetRank(tab, id) - 1
        self.pointsRemaining = self.pointsRemaining + 1
        return true
    end
    return false
end

function AurenTurtleSim:SaveSpec(name)
    if not name or name == "" or name == "Build Name..." then return false end
    AurenTurtleSimDB_SavedSpecs = AurenTurtleSimDB_SavedSpecs or {}
    AurenTurtleSimDB_SavedSpecs[self.selectedClass] = AurenTurtleSimDB_SavedSpecs[self.selectedClass] or {}
    
    local copyState = { [1] = {}, [2] = {}, [3] = {} }
    for t = 1, 3 do
        for id, rank in pairs(self.state[t] or {}) do
            copyState[t][id] = rank
        end
    end

    AurenTurtleSimDB_SavedSpecs[self.selectedClass][name] = {
        state = copyState,
        pointsRemaining = self.pointsRemaining
    }
    
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AurenTurtleSim]|r Saved profile '|cffffd100" .. name .. "|r'!")
    end
    return true
end

function AurenTurtleSim:LoadSpec(name)
    if not AurenTurtleSimDB_SavedSpecs or not AurenTurtleSimDB_SavedSpecs[self.selectedClass] then return false end
    local spec = AurenTurtleSimDB_SavedSpecs[self.selectedClass][name]
    if not spec then return false end

    self:Reset()
    for t = 1, 3 do
        if spec.state and spec.state[t] then
            for id, rank in pairs(spec.state[t]) do
                for r = 1, rank do
                    self:AddPoint(t, id)
                end
            end
        end
    end

    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AurenTurtleSim]|r Loaded profile '|cffffd100" .. name .. "|r'!")
    end
    return true
end

function AurenTurtleSim:DeleteSpec(name)
    if AurenTurtleSimDB_SavedSpecs and AurenTurtleSimDB_SavedSpecs[self.selectedClass] and AurenTurtleSimDB_SavedSpecs[self.selectedClass][name] then
        AurenTurtleSimDB_SavedSpecs[self.selectedClass][name] = nil
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AurenTurtleSim]|r Deleted profile '|cffffd100" .. name .. "|r'.")
        end
        return true
    end
    return false
end