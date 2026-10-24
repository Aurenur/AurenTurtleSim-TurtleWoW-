-- Polish & High Precision Layout Engine for AurenTurtleSim (WoW 1.12.1)
local FRAME_WIDTH, FRAME_HEIGHT = 470, 640
local BUTTON_SIZE = 40
local BUTTON_GAP = 18

-- Grid horizontal centering:
-- Total 4-col grid width = (4 * 40px) + (3 * 18px) = 214px
-- Center offset = (470 - 214) / 2 = 128px
local GRID_X_OFFSET = 128
local GRID_Y_OFFSET = -95

local simFrame = CreateFrame("Frame", "AurenTurtleSimFrame", UIParent)
simFrame:SetWidth(FRAME_WIDTH)
simFrame:SetHeight(FRAME_HEIGHT)
simFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
simFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
simFrame:EnableMouse(true)
simFrame:SetMovable(true)
simFrame:RegisterForDrag("LeftButton")
simFrame:SetScript("OnDragStart", function() simFrame:StartMoving() end)
simFrame:SetScript("OnDragStop", function() simFrame:StopMovingOrSizing() end)
simFrame:Hide()

local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
eventHandler:SetScript("OnEvent", function()
    local _, pClass = UnitClass("player")
    if pClass then
        AurenTurtleSim.selectedClass = pClass
        AurenTurtleSim:ScanTurtleWoWTalents()
        AurenTurtleSim:Reset()
    end
end)

local titleText = simFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", simFrame, "TOP", 0, -16)
titleText:SetText("AurenTurtleSim")

local pointsText = simFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pointsText:SetPoint("TOP", simFrame, "TOP", 0, -42)

AurenTurtleSimUI = { buttons = {}, tabButtons = {} }

local function OnTabClick()
    local tabIdx = this:GetID()
    AurenTurtleSim.activeTab = tabIdx
    AurenTurtleSimUI:RenderTree(tabIdx)
end

-- Top Spec Tree Tabs (Width 125px each, centered across 470px)
for t = 1, 3 do
    local tabBtn = CreateFrame("Button", "AurenTurtleSimTab"..t, simFrame, "UIPanelButtonTemplate")
    tabBtn:SetWidth(125)
    tabBtn:SetHeight(22)
    tabBtn:SetPoint("TOPLEFT", simFrame, "TOPLEFT", 35 + ((t-1) * 135), -66)
    tabBtn:SetID(t)
    tabBtn:SetScript("OnClick", OnTabClick)
    AurenTurtleSimUI.tabButtons[t] = tabBtn
end

-- ==========================================
-- BOTTOM CONTROLS: ROW 1 - PROFILES
-- ==========================================
local selectedProfileName = nil

local profileDropDown = CreateFrame("Frame", "AurenTurtleSimDropDown", simFrame, "UIDropDownMenuTemplate")
profileDropDown:SetPoint("BOTTOMLEFT", simFrame, "BOTTOMLEFT", 12, 52)
UIDropDownMenu_SetWidth(110, profileDropDown)

local function ProfileDropDown_OnClick()
    selectedProfileName = this.value
    UIDropDownMenu_SetSelectedValue(profileDropDown, selectedProfileName)
    UIDropDownMenu_SetText(selectedProfileName, profileDropDown)
end

local function ProfileDropDown_Initialize()
    local info
    local classSpecs = AurenTurtleSimDB_SavedSpecs and AurenTurtleSimDB_SavedSpecs[AurenTurtleSim.selectedClass]
    if classSpecs then
        for name in pairs(classSpecs) do
            info = {}
            info.text = name
            info.value = name
            info.func = ProfileDropDown_OnClick
            UIDropDownMenu_AddButton(info)
        end
    end
end

UIDropDownMenu_Initialize(profileDropDown, ProfileDropDown_Initialize)

-- Custom Dark Inset Input Box (Zero Texture Overlap)
local profileEdit = CreateFrame("EditBox", "AurenTurtleSimEditBox", simFrame)
profileEdit:SetWidth(115)
profileEdit:SetHeight(20)
profileEdit:SetPoint("LEFT", profileDropDown, "RIGHT", -12, 2)
profileEdit:SetFontObject("GameFontHighlightSmall")
profileEdit:SetAutoFocus(false)
profileEdit:SetText("Build Name...")
profileEdit:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
profileEdit:SetBackdropColor(0, 0, 0, 0.75)
profileEdit:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

profileEdit:SetScript("OnEditFocusGained", function()
    if this:GetText() == "Build Name..." then
        this:SetText("")
    end
end)

profileEdit:SetScript("OnEditFocusLost", function()
    if this:GetText() == "" then
        this:SetText("Build Name...")
    end
end)

local saveBtn = CreateFrame("Button", "AurenTurtleSimSaveBtn", simFrame, "UIPanelButtonTemplate")
saveBtn:SetWidth(50)
saveBtn:SetHeight(22)
saveBtn:SetPoint("LEFT", profileEdit, "RIGHT", 6, 0)
saveBtn:SetText("Save")
saveBtn:SetScript("OnClick", function()
    local name = profileEdit:GetText()
    if name and name ~= "" and name ~= "Build Name..." then
        AurenTurtleSim:SaveSpec(name)
        selectedProfileName = name
        UIDropDownMenu_Initialize(profileDropDown, ProfileDropDown_Initialize)
        UIDropDownMenu_SetSelectedValue(profileDropDown, name)
        UIDropDownMenu_SetText(name, profileDropDown)
        profileEdit:SetText("Build Name...")
        profileEdit:ClearFocus()
        AurenTurtleSimUI:RenderTree(AurenTurtleSim.activeTab)
    end
end)

local loadBtn = CreateFrame("Button", "AurenTurtleSimLoadBtn", simFrame, "UIPanelButtonTemplate")
loadBtn:SetWidth(50)
loadBtn:SetHeight(22)
loadBtn:SetPoint("LEFT", saveBtn, "RIGHT", 4, 0)
loadBtn:SetText("Load")
loadBtn:SetScript("OnClick", function()
    local targetName = selectedProfileName or profileEdit:GetText()
    if targetName and targetName ~= "" and targetName ~= "Build Name..." then
        AurenTurtleSim:LoadSpec(targetName)
        AurenTurtleSimUI:RenderTree(AurenTurtleSim.activeTab)
    end
end)

local delBtn = CreateFrame("Button", "AurenTurtleSimDelBtn", simFrame, "UIPanelButtonTemplate")
delBtn:SetWidth(50)
delBtn:SetHeight(22)
delBtn:SetPoint("LEFT", loadBtn, "RIGHT", 4, 0)
delBtn:SetText("Delete")
delBtn:SetScript("OnClick", function()
    local targetName = selectedProfileName or profileEdit:GetText()
    if targetName and targetName ~= "" and targetName ~= "Build Name..." then
        AurenTurtleSim:DeleteSpec(targetName)
        selectedProfileName = nil
        UIDropDownMenu_SetText("Select Profile", profileDropDown)
        UIDropDownMenu_Initialize(profileDropDown, ProfileDropDown_Initialize)
        profileEdit:SetText("Build Name...")
        AurenTurtleSimUI:RenderTree(AurenTurtleSim.activeTab)
    end
end)

-- ==========================================
-- BOTTOM CONTROLS: ROW 2 - UTILITY
-- ==========================================
local scanBtn = CreateFrame("Button", "AurenTurtleSimScanBtn", simFrame, "UIPanelButtonTemplate")
scanBtn:SetWidth(100)
scanBtn:SetHeight(22)
scanBtn:SetPoint("BOTTOMLEFT", simFrame, "BOTTOMLEFT", 25, 20)
scanBtn:SetText("Rescan Tree")
scanBtn:SetScript("OnClick", function()
    AurenTurtleSim:ScanTurtleWoWTalents()
    AurenTurtleSimUI:RenderTree(AurenTurtleSim.activeTab)
end)

local resetBtn = CreateFrame("Button", "AurenTurtleSimResetBtn", simFrame, "UIPanelButtonTemplate")
resetBtn:SetWidth(90)
resetBtn:SetHeight(22)
resetBtn:SetPoint("BOTTOMRIGHT", simFrame, "BOTTOMRIGHT", -25, 20)
resetBtn:SetText("Reset Points")
resetBtn:SetScript("OnClick", function()
    AurenTurtleSim:Reset()
    AurenTurtleSimUI:RenderTree(AurenTurtleSim.activeTab)
end)

local closeBtn = CreateFrame("Button", "AurenTurtleSimCloseBtn", simFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", simFrame, "TOPRIGHT", -5, -5)

SLASH_AURENTURTLESIM1 = "/ats"
SLASH_AURENTURTLESIM2 = "/aurensim"
SlashCmdList["AURENTURTLESIM"] = function()
    if simFrame:IsShown() then
        simFrame:Hide()
    else
        if not AurenTurtleSimDB_Data or not AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass] or not AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass][1] then
            AurenTurtleSim:ScanTurtleWoWTalents()
            AurenTurtleSim:Reset()
        end
        UIDropDownMenu_Initialize(profileDropDown, ProfileDropDown_Initialize)
        UIDropDownMenu_SetText(selectedProfileName or "Select Profile", profileDropDown)
        AurenTurtleSimUI:RenderTree(AurenTurtleSim.activeTab)
        simFrame:Show()
    end
end

function AurenTurtleSimButton_OnClick()
    local tab = AurenTurtleSim.activeTab
    local id = this:GetID()
    if arg1 == "LeftButton" then
        AurenTurtleSim:AddPoint(tab, id)
    elseif arg1 == "RightButton" then
        AurenTurtleSim:RemovePoint(tab, id)
    end
    AurenTurtleSimUI:RenderTree(tab)
end

function AurenTurtleSimButton_OnEnter()
    local tab = AurenTurtleSim.activeTab
    local id = this:GetID()
    
    local name = "Talent"
    local maxRank = 1
    
    if AurenTurtleSimDB_Data and AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass] then
        local tabData = AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass][tab]
        if tabData and tabData.talents and tabData.talents[id] then
            name = tabData.talents[id].name or "Talent"
            maxRank = tabData.talents[id].maxRank or 1
        end
    end

    local rank = AurenTurtleSim:GetRank(tab, id)

    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(name, 1, 1, 1)
    GameTooltip:AddLine("Rank " .. rank .. "/" .. maxRank, 1, 0.82, 0)
    GameTooltip:AddLine("Turtle WoW Live Custom Talent", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function AurenTurtleSimButton_OnLeave()
    GameTooltip:Hide()
end

function AurenTurtleSimUI:RenderTree(tab)
    if not AurenTurtleSimDB_Data or not AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass] then
        AurenTurtleSim:ScanTurtleWoWTalents()
    end
    
    local classData = AurenTurtleSimDB_Data and AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass]
    if not classData or not classData[tab] then return end

    for t = 1, 3 do
        local tData = classData[t]
        local ptsInTab = AurenTurtleSim:GetPointsInTab(t)
        local tName = (tData and tData.name) or ("Tree " .. t)
        if AurenTurtleSimUI.tabButtons[t] then
            AurenTurtleSimUI.tabButtons[t]:SetText(tName .. " (" .. ptsInTab .. ")")
        end
    end

    pointsText:SetText("Points Remaining: |cffffd100" .. AurenTurtleSim.pointsRemaining .. " / 51|r")

    for _, btn in pairs(self.buttons) do
        if btn then btn:Hide() end
    end

    local tabData = classData[tab]
    if not tabData or not tabData.talents then return end

    for id, talent in pairs(tabData.talents) do
        if talent then
            local btn = self.buttons[id]
            if not btn then
                btn = CreateFrame("Button", "AurenTurtleSimBtn"..id, simFrame, "ActionButtonTemplate")
                btn:SetWidth(BUTTON_SIZE)
                btn:SetHeight(BUTTON_SIZE)
                btn:SetScript("OnClick", AurenTurtleSimButton_OnClick)
                btn:SetScript("OnEnter", AurenTurtleSimButton_OnEnter)
                btn:SetScript("OnLeave", AurenTurtleSimButton_OnLeave)
                self.buttons[id] = btn
            end

            btn:SetID(id)

            local x = GRID_X_OFFSET + (((talent.col or 1) - 1) * (BUTTON_SIZE + BUTTON_GAP))
            local y = GRID_Y_OFFSET - (((talent.row or 1) - 1) * (BUTTON_SIZE + BUTTON_GAP))
            btn:SetPoint("TOPLEFT", simFrame, "TOPLEFT", x, y)

            local icon = getglobal(btn:GetName().."Icon")
            if icon then
                icon:SetTexture(talent.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            end

            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:Show()
        end
    end

    self:UpdateRanks(tab)
end

function AurenTurtleSimUI:UpdateRanks(tab)
    if not AurenTurtleSimDB_Data or not AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass] then return end
    local classData = AurenTurtleSimDB_Data[AurenTurtleSim.selectedClass]
    local tabData = classData[tab]
    if not tabData or not tabData.talents then return end

    for id, btn in pairs(self.buttons) do
        local talent = tabData.talents[id]
        if btn and talent then
            local rank = AurenTurtleSim:GetRank(tab, id)
            local countText = getglobal(btn:GetName().."Count")
            if countText then
                countText:SetText(rank .. "/" .. (talent.maxRank or 1))
            end

            local canAdd = AurenTurtleSim:CanAddPoint(tab, id)
            local icon = getglobal(btn:GetName().."Icon")
            if icon then
                if rank > 0 or canAdd then
                    icon:SetVertexColor(1, 1, 1)
                else
                    icon:SetVertexColor(0.35, 0.35, 0.35)
                end
            end
        else
            if btn then btn:Hide() end
        end
    end
end