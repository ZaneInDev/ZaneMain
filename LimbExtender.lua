local RawSettings = {
    Toggle = "L",
    TargetLimb = "HumanoidRootPart",
    LimbSize = 5,
    MobileButton = true,
    LimbTransparency = 0,
    LimbCanCollide = false,
    TeamCheck = true,
    ForcefieldCheck = true,
    ResetLimbOnDeath = false,
    UseHighlight = true,
    DepthMode = "AlwaysOnTop",
    HighlightFillColor = Color3.fromRGB(0, 140, 140),
    HighlightFillTransparency = 0.7,
    HighlightOutlineColor = Color3.fromRGB(255, 255, 255),
    HighlightOutlineTransparency = 1,
    ListenForInput = true,
    LimbMaterial = Enum.Material.Forcefield,
    DuplicateLimb = true,
    UseTeamColor = true,
    DeathAnimation = true,
    DuplicatedLimbPrefix = "Extended"
}

getgenv().LimbExtenderData = getgenv().LimbExtenderData or {}
local LimbExtenderData = getgenv().LimbExtenderData
local LimbExtender = nil

if LimbExtenderData.Running ~= nil then
    LimbExtenderData.TerminateOldProcess("FullKill")
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

LimbExtenderData.Running = LimbExtenderData.Running or false
LimbExtenderData.CAU = LimbExtenderData.CAU or loadstring(game:HttpGet('https://raw.githubusercontent.com/AAPVdev/scripts/refs/heads/main/ContextActionUtility.lua'))()

LimbExtenderData.PlayerTable = LimbExtenderData.PlayerTable or {}
LimbExtenderData.Limbs = LimbExtenderData.Limbs or {}
LimbExtenderData.DuplicatedLimbs = LimbExtenderData.DuplicatedLimbs or {}
LimbExtenderData.ActiveTweens = LimbExtenderData.ActiveTweens or {}

local PlayerTable = LimbExtenderData.PlayerTable
local Limbs = LimbExtenderData.Limbs
local DuplicatedLimbs = LimbExtenderData.DuplicatedLimbs
local ActiveTweens = LimbExtenderData.ActiveTweens
local ContextActionUtility = LimbExtenderData.CAU

local function GetPlayers(Func, IncludeLocalPlayer)
    for _, Player in ipairs(Players:GetPlayers()) do
        if IncludeLocalPlayer or Player ~= LocalPlayer then
            Func(Player)
        end
    end
end

local function RemoveDuplicatedLimb(Limb)
    local Character = Limb:FindFirstAncestorOfClass("Model")
    if Character and DuplicatedLimbs[Character] and DuplicatedLimbs[Character].Original == Limb then
        local DupLimb = DuplicatedLimbs[Character]
        if DupLimb and DupLimb.Instance then
            DupLimb.Instance:Destroy()
            DuplicatedLimbs[Character] = nil
        end
        return
    end
    
    for Char, DupData in pairs(DuplicatedLimbs) do
        if DupData.Instance == Limb then
            Limb:Destroy()
            DuplicatedLimbs[Char] = nil
            return
        end
    end
end

local function RestoreLimbProperties(Limb)
    local LimbProperties = Limbs[Limb]

    if not LimbProperties then
        return
    end

    if LimbProperties.SizeChanged then
        LimbProperties.SizeChanged:Disconnect()
    end
    
    if LimbProperties.CollisionChanged then
        LimbProperties.CollisionChanged:Disconnect()
    end
    
    if LimbProperties.Highlight then
        LimbProperties.Highlight:Destroy()
    end

    RemoveDuplicatedLimb(Limb)
    Limbs[Limb] = nil

    Limb.Size = LimbProperties.Size
    Limb.CanCollide = LimbProperties.CanCollide
    Limb.Transparency = LimbProperties.Transparency
    Limb.Massless = LimbProperties.Massless
    Limb.Material = LimbProperties.Material
    
    if LimbProperties.Color then
        Limb.Color = LimbProperties.Color
    end
    
    if ActiveTweens[Limb] then
        ActiveTweens[Limb]:Cancel()
        ActiveTweens[Limb] = nil
    end
end

local function SaveLimbProperties(Limb)
    if Limbs[Limb] then
        RestoreLimbProperties(Limb)
    end

    Limbs[Limb] = {
        Size = Limb.Size,
        Transparency = Limb.Transparency,
        CanCollide = Limb.CanCollide,
        Massless = Limb.Massless,
        Material = Limb.Material,
        Color = Limb.Color
    }
end

local function GetTeamColor(Player)
    if RawSettings.UseTeamColor and Player and Player.Team then
        return Player.Team.TeamColor.Color
    end
    return nil
end

local function DuplicateLimb(OriginalLimb)
    if not RawSettings.DuplicateLimb or not OriginalLimb then
        return nil
    end
    
    local Character = OriginalLimb:FindFirstAncestorOfClass("Model")
    if not Character then
        return nil
    end
    
    RemoveDuplicatedLimb(OriginalLimb)
    
    local NewLimb = OriginalLimb:Clone()
    NewLimb.Name = RawSettings.DuplicatedLimbPrefix .. OriginalLimb.Name
    NewLimb.Parent = Character
    
    for _, Constraint in ipairs(Character:GetDescendants()) do
        if Constraint:IsA("Weld") or Constraint:IsA("WeldConstraint") or Constraint:IsA("Motor6D") then
            if Constraint.Part0 == OriginalLimb then
                local NewConstraint = Constraint:Clone()
                NewConstraint.Parent = Constraint.Parent
                NewConstraint.Part0 = NewLimb
                NewConstraint.Part1 = Constraint.Part1
            elseif Constraint.Part1 == OriginalLimb then
                local NewConstraint = Constraint:Clone()
                NewConstraint.Parent = Constraint.Parent
                NewConstraint.Part1 = NewLimb
                NewConstraint.Part0 = Constraint.Part0
            end
        end
    end
    
    DuplicatedLimbs[Character] = {
        Instance = NewLimb,
        Original = OriginalLimb
    }
    
    return NewLimb
end

local function ModifyLimbProperties(Limb, Player)
    SaveLimbProperties(Limb)

    local NewSize = Vector3.new(
        RawSettings.LimbSize,
        RawSettings.LimbSize,
        RawSettings.LimbSize
    )

    Limb.Size = NewSize
    Limb.Material = RawSettings.LimbMaterial

    Limbs[Limb].SizeChanged = Limb:GetPropertyChangedSignal("Size"):Connect(function()
        Limb.Size = NewSize
    end)

    Limbs[Limb].CollisionChanged = Limb:GetPropertyChangedSignal("CanCollide"):Connect(function()
        Limb.CanCollide = RawSettings.LimbCanCollide
    end)

    Limb.Transparency = RawSettings.LimbTransparency
    Limb.CanCollide = RawSettings.LimbCanCollide

    local TeamColor = GetTeamColor(Player)
    if TeamColor then
        Limb.Color = TeamColor
    end

    if RawSettings.TargetLimb ~= "HumanoidRootPart" then
        Limb.Massless = true
    end

    if RawSettings.UseHighlight then
        Limbs[Limb].Highlight = Limb:FindFirstChildWhichIsA("Highlight") or Instance.new("Highlight", Limb)

        local HighlightInstance = Limbs[Limb].Highlight
        HighlightInstance.Name = "LimbHighlight"
        HighlightInstance.DepthMode = Enum.HighlightDepthMode[RawSettings.DepthMode]
        HighlightInstance.FillColor = TeamColor or RawSettings.HighlightFillColor
        HighlightInstance.FillTransparency = RawSettings.HighlightFillTransparency
        HighlightInstance.OutlineColor = RawSettings.HighlightOutlineColor
        HighlightInstance.OutlineTransparency = RawSettings.HighlightOutlineTransparency
        HighlightInstance.Enabled = true
    end
    
    if RawSettings.DuplicateLimb then
        DuplicateLimb(Limb)
    end
end

local function PlayDeathAnimation(Limb)
    if not RawSettings.DeathAnimation or not Limb then
        return
    end
    
    if ActiveTweens[Limb] then
        ActiveTweens[Limb]:Cancel()
        ActiveTweens[Limb] = nil
    end
    
    local TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local Goal = {Size = Vector3.new(0, 0, 0)}
    local Tween = TweenService:Create(Limb, TweenInfo, Goal)
    
    Tween.Completed:Connect(function()
        ActiveTweens[Limb] = nil
    end)
    
    ActiveTweens[Limb] = Tween
    Tween:Play()
end

local function RemovePlayerData(Player)
    local PlayerData = PlayerTable[Player.Name]
    if PlayerData then
        for _, Connection in pairs(PlayerData) do
            if typeof(Connection) == "RBXScriptConnection" then
                Connection:Disconnect()
            end
        end
        
        if Player.Character then
            local TargetLimb = Player.Character:FindFirstChild(RawSettings.TargetLimb)
            if TargetLimb and Limbs[TargetLimb] then
                RestoreLimbProperties(TargetLimb)
            end
        end

        PlayerTable[Player.Name] = nil
    end
end

local function Terminate(SpecialProcess)
    for Key, Connection in pairs(getgenv().LimbExtenderData) do
        if typeof(Connection) == "RBXScriptConnection" then
            Connection:Disconnect()
            LimbExtenderData[Key] = nil
        end
    end

    GetPlayers(RemovePlayerData, false)

    for Limb, _ in pairs(LimbExtenderData.Limbs) do
        RestoreLimbProperties(Limb)
    end
    
    LimbExtenderData.DuplicatedLimbs = {}
    LimbExtenderData.ActiveTweens = {}

    if SpecialProcess == "FullKill" then
        ContextActionUtility:UnbindAction("LimbExtenderToggle")
    else
        if not RawSettings.ListenForInput then
            ContextActionUtility:UnbindAction("LimbExtenderToggle")
        elseif RawSettings.MobileButton then
            ContextActionUtility:SetTitle("LimbExtenderToggle", "On")
        end
    end
end

local function Initiate()
    Terminate()

    if not LimbExtenderData.Running then
        return
    end

    local function SetupPlayer(Player)
        local function CharacterAdded(Character)
            if Character then
                local PlayerData = PlayerTable[Player.Name]
                if PlayerData then
                    PlayerData["TeamChanged"] = Player:GetPropertyChangedSignal("Team"):Once(function()
                        RemovePlayerData(Player)
                        SetupPlayer(Player)
                    end)

                    local Humanoid = Character:WaitForChild("Humanoid", 0.2)
                    local TargetLimb = Character:WaitForChild(RawSettings.TargetLimb, 0.2)
                    if TargetLimb and Humanoid and Humanoid.Health > 0 then
                        if (RawSettings.TeamCheck and (LocalPlayer.Team == nil or Player.Team ~= LocalPlayer.Team)) or not RawSettings.TeamCheck then
                            ModifyLimbProperties(TargetLimb, Player)
                        end

                        PlayerData["CharacterRemoving"] = Player.CharacterRemoving:Once(function()
                            RestoreLimbProperties(TargetLimb)
                        end)

                        PlayerData["OnDeath"] = Humanoid.Died:Connect(function()
                            if RawSettings.DeathAnimation and Limbs[TargetLimb] then
                                PlayDeathAnimation(TargetLimb)
                            end
                            
                            if RawSettings.ResetLimbOnDeath then
                                RestoreLimbProperties(TargetLimb)
                            end
                        end)
                    end
                end
            end
        end

        PlayerTable[Player.Name] = {}
        PlayerTable[Player.Name]["CharacterAdded"] = Player.CharacterAdded:Connect(CharacterAdded)

        CharacterAdded(Player.Character)
    end

    GetPlayers(SetupPlayer, false)

    LimbExtenderData.TeamChanged = LocalPlayer:GetPropertyChangedSignal("Team"):Once(Initiate)
    LimbExtenderData.PlayerAdded = Players.PlayerAdded:Connect(SetupPlayer)
    LimbExtenderData.PlayerRemoving = Players.PlayerRemoving:Connect(RemovePlayerData)

    if RawSettings.MobileButton and RawSettings.ListenForInput then
        ContextActionUtility:SetTitle("LimbExtenderToggle", "Off")
    end
end

function RawSettings.ToggleState(State)
    local NewState = (State == nil) and (not LimbExtenderData.Running) or State

    LimbExtenderData.Running = NewState

    if NewState then
        Initiate()
    else
        Terminate()
    end
end

LimbExtender = setmetatable({}, {
    __index = RawSettings,
    __newindex = function(_, Key, Value)
        if RawSettings[Key] ~= Value then
            RawSettings[Key] = Value
            Initiate()
        end
    end
})

if RawSettings.ListenForInput then
    ContextActionUtility:BindAction(
        "LimbExtenderToggle",
        function(_, InputState)
            if InputState == Enum.UserInputState.Begin then
                RawSettings.ToggleState()
            end
        end,
        RawSettings.MobileButton,
        Enum.KeyCode[RawSettings.Toggle]
    )
end

LimbExtenderData.TerminateOldProcess = Terminate

if LimbExtenderData.Running then
    Initiate()
elseif RawSettings.MobileButton and RawSettings.ListenForInput then
    ContextActionUtility:SetTitle("LimbExtenderToggle", "On")
end

return LimbExtender
