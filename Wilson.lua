local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SavedTargets = {}
local SelectedTargets = {}

-- ============================================
-- LIVE CONFIGURATION
-- ============================================
_G.FIRE_RATE = 0.16
local TP_DIST = 10
local INTERCEPT_TIME = 0.2
local GRAPPLE_SPEED = 150
local MAX_DISTANCE = 130
local VELOCITY_CAP = 100

-- State Variables
local AutoTP = false
local HitChance = false
local ReturnMode = false
local KillAuraEnabled = false
local SmartPred = false
local JumpPred = false
local UltraPred = false
local IAPred = false

local LastShot = 0
local LearnData = {}
local PitConnection = nil
local OriginalPitSize, OriginalPitCFrame = nil, nil

-- ============================================
-- CORE UTILITIES & TARGETING
-- ============================================
local function GetHRP(plr)
	local c = plr.Character
	return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChildWhichIsA("BasePart"))
end

local function IsValid(p)
    if not p or not p.Parent or not SelectedTargets[p] then return false end
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = GetHRP(p)
    if not hum or not hrp then return false end
    if hum.Health <= 0 then return false end
    return true
end

local function GetTool()
	for _, v in pairs(LocalPlayer.Character:GetChildren()) do
		if v:IsA("Tool") and v:FindFirstChild("RemoteEvent") then return v end
	end
	return nil
end

local function GetBestTarget()
    local best, dist = nil, math.huge
    local myHRP = GetHRP(LocalPlayer)
    if not myHRP then return nil end
    for p, _ in pairs(SelectedTargets) do
        if IsValid(p) then
            local hrp = GetHRP(p)
            local d = (hrp.Position - myHRP.Position).Magnitude
            if d < dist then dist = d; best = p end
        end
    end
    return best
end

-- ============================================
-- PREDICTION ENGINE
-- ============================================
local function Predict(plr)
	local hrp = GetHRP(plr)
	local my = GetHRP(LocalPlayer)
	if not hrp or not my then return nil end
	local pos, vel = hrp.Position, hrp.AssemblyLinearVelocity
	local dist = (pos - my.Position).Magnitude
    
    -- Learn Pattern
	LearnData[plr] = LearnData[plr] or {}
	table.insert(LearnData[plr], pos)
	if #LearnData[plr] > 8 then table.remove(LearnData[plr], 1) end

	local timeHit = math.clamp(dist / GRAPPLE_SPEED, 0.05, 0.65)
	local future = pos + vel * timeHit

	if SmartPred and vel.Magnitude > 30 then future += vel * 0.25 end
	if JumpPred and math.abs(vel.Y) > 5 then future += Vector3.new(0, vel.Y * 0.4, 0) end
    if UltraPred then future += hrp.CFrame.RightVector * (math.sin(tick()*4)*4) + vel * 0.15 end
	if IAPred then 
		local pattern = (#LearnData[plr] > 1) and (LearnData[plr][#LearnData[plr]] - LearnData[plr][#LearnData[plr]-1]) or Vector3.zero
		future += pattern * 2 + vel * (0.2 * (vel.Magnitude/50))
	end
	return future
end

-- ============================================
-- KILL AURA LOGIC (RESTORED)
-- ============================================
local function StoreOriginalPit()
	local pit = game.Workspace:FindFirstChild("Pit")
	if pit and pit:FindFirstChild("Damage") then
		OriginalPitSize = pit.Damage.Size
		OriginalPitCFrame = pit.Damage.CFrame
	end
end
task.spawn(function() while not game.Workspace:FindFirstChild("Pit") do task.wait(0.5) end StoreOriginalPit() end)

local function SetPitImmunity(immune)
	local char = LocalPlayer.Character
	if not char then return end
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
            if immune then
                if not v:GetAttribute("OrigTouch") then v:SetAttribute("OrigTouch", v.CanTouch) end
                v.CanTouch = false
            else
                local orig = v:GetAttribute("OrigTouch")
                if orig ~= nil then v.CanTouch = orig end
            end
        end
	end
end

local function ToggleKillAura()
	KillAuraEnabled = not KillAuraEnabled
	local pit = game.Workspace:FindFirstChild("Pit")
	if KillAuraEnabled then
		SetPitImmunity(true)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("ragdollValue") then LocalPlayer.Character.ragdollValue:Destroy() end
		if pit and pit:FindFirstChild("Damage") then
			pit.Damage.Size = Vector3.new(600, 600, 600)
			PitConnection = RunService.Heartbeat:Connect(function()
				local hrp = GetHRP(LocalPlayer)
				if hrp then pit.Damage.CFrame = hrp.CFrame end
			end)
		end
	else
		SetPitImmunity(false)
		if PitConnection then PitConnection:Disconnect(); PitConnection = nil end
		if pit and pit:FindFirstChild("Damage") and OriginalPitSize then
			pit.Damage.Size = OriginalPitSize; pit.Damage.CFrame = OriginalPitCFrame
		end
	end
end

-- ============================================
-- ORIGINAL STYLE GUI
-- ============================================
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.Name = "NexusAutotpElite"
gui.ResetOnSpawn = false

local open = Instance.new("TextButton", gui)
open.Size = UDim2.new(0,130,0,38)
open.Position = UDim2.new(0,15,0.5,-20)
open.Text = "Abrir TP"
open.Font = Enum.Font.Garamond
open.TextScaled = true
open.TextColor3 = Color3.new(1,1,1)
open.BackgroundColor3 = Color3.fromRGB(15,25,55)
Instance.new("UICorner", open).CornerRadius = UDim.new(0,9)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,340,0,550)
frame.Position = UDim2.new(0.5,-170,0.5,-275)
frame.BackgroundColor3 = Color3.fromRGB(235,240,255)
frame.Visible = false
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(20,35,80)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,34)
title.BackgroundTransparency = 1
title.Text = "Autotp Profesional Elite"
title.Font = Enum.Font.Garamond
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(15,25,70)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(0.94,0,0,150)
scroll.Position = UDim2.new(0.03,0,0,65)
scroll.BackgroundColor3 = Color3.new(1,1,1)
scroll.BackgroundTransparency = 0.5
Instance.new("UICorner", scroll)

local controls = Instance.new("Frame", frame)
controls.Size = UDim2.new(1, -20, 0, 300)
controls.Position = UDim2.new(0, 10, 0, 230)
controls.BackgroundTransparency = 1

local grid = Instance.new("UIGridLayout", controls)
grid.CellSize = UDim2.new(0, 155, 0, 32)
grid.CellPadding = UDim2.new(0, 10, 0, 8)

local function MakeBtn(text)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = Enum.Font.Garamond
	b.TextScaled = true
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(20,35,80)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
	b.Parent = controls
	return b
end

local TPOnceBtn = MakeBtn("TP Once")
local AutoTPBtn = MakeBtn("AutoTP OFF")
local ReturnBtn = MakeBtn("Return OFF")
local HitBtn = MakeBtn("HitChance OFF")
local KillAuraBtn = MakeBtn("Kill Aura OFF")
local SmartBtn = MakeBtn("SmartPred OFF")
local JumpBtn = MakeBtn("JumpPred OFF")
local UltraBtn = MakeBtn("UltraPred OFF")
local IABtn = MakeBtn("IA Pred OFF")

-- FIRE RATE SECTION
local RateLabel = Instance.new("TextLabel", controls)
RateLabel.Text = "Velocidad:"
RateLabel.Font = Enum.Font.Garamond
RateLabel.TextColor3 = Color3.fromRGB(15,25,70)
RateLabel.BackgroundTransparency = 1
RateLabel.TextScaled = true

local RateInput = Instance.new("TextBox", controls)
RateInput.Text = tostring(_G.FIRE_RATE)
RateInput.Font = Enum.Font.Garamond
RateInput.BackgroundColor3 = Color3.fromRGB(200, 210, 240)
RateInput.TextColor3 = Color3.fromRGB(15,25,70)
RateInput.TextScaled = true
Instance.new("UICorner", RateInput)

RateInput.FocusLost:Connect(function()
	local n = tonumber(RateInput.Text)
	if n then _G.FIRE_RATE = n else RateInput.Text = tostring(_G.FIRE_RATE) end
end)

open.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible open.Text = frame.Visible and "Cerrar TP" or "Abrir TP" end)

-- ============================================
-- THE CORE ENGINE
-- ============================================
RunService.Heartbeat:Connect(function()
	if not AutoTP then return end
	if tick() - LastShot < _G.FIRE_RATE then return end

	local target = GetBestTarget()
	if target then
		local myHRP = GetHRP(LocalPlayer)
		local enHRP = GetHRP(target)
		if not myHRP or not enHRP then return end

		local dist = (enHRP.Position - myHRP.Position).Magnitude
		if HitChance then
			if dist > MAX_DISTANCE or enHRP.AssemblyLinearVelocity.Magnitude > VELOCITY_CAP then return end
		end

		local oldCF = myHRP.CFrame
		local vel = enHRP.AssemblyLinearVelocity
        
		-- INTERCEPT POSITIONING
		local futurePos = enHRP.Position + (vel * INTERCEPT_TIME)
		local lookDir = (vel.Magnitude > 3) and vel.Unit or enHRP.CFrame.LookVector
		local tpPos = futurePos + (lookDir * TP_DIST)
		
		myHRP.CFrame = CFrame.new(tpPos, enHRP.Position)
		RunService.RenderStepped:Wait() 

		local aimPoint = Predict(target)
		local tool = GetTool()
		if tool and aimPoint then tool.RemoteEvent:FireServer(aimPoint) end

		LastShot = tick()
		if ReturnMode then task.wait(0.04) myHRP.CFrame = oldCF end
	end
end)

TPOnceBtn.MouseButton1Click:Connect(function()
	local target = GetBestTarget()
	if target then
		local myHRP, enHRP = GetHRP(LocalPlayer), GetHRP(target)
		local oldCF = myHRP.CFrame
		myHRP.CFrame = enHRP.CFrame * CFrame.new(0, 0, 10)
		task.wait(0.04)
		local aim = Predict(target)
		local tool = GetTool()
		if tool and aim then tool.RemoteEvent:FireServer(aim) end
		if ReturnMode then task.wait(0.1) myHRP.CFrame = oldCF end
	end
end)

-- BUTTON CONNECTIONS
AutoTPBtn.MouseButton1Click:Connect(function() AutoTP = not AutoTP AutoTPBtn.Text = AutoTP and "AutoTP ON" or "AutoTP OFF" AutoTPBtn.BackgroundColor3 = AutoTP and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)
HitBtn.MouseButton1Click:Connect(function() HitChance = not HitChance HitBtn.Text = HitChance and "HitChance ON" or "HitChance OFF" HitBtn.BackgroundColor3 = HitChance and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)
ReturnBtn.MouseButton1Click:Connect(function() ReturnMode = not ReturnMode ReturnBtn.Text = ReturnMode and "Return ON" or "Return OFF" ReturnBtn.BackgroundColor3 = ReturnMode and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)
KillAuraBtn.MouseButton1Click:Connect(function() ToggleKillAura() KillAuraBtn.Text = KillAuraEnabled and "Kill Aura ON" or "Kill Aura OFF" KillAuraBtn.BackgroundColor3 = KillAuraEnabled and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)
SmartBtn.MouseButton1Click:Connect(function() SmartPred = not SmartPred SmartBtn.Text = SmartPred and "Smart ON" or "Smart OFF" SmartBtn.BackgroundColor3 = SmartPred and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)
JumpBtn.MouseButton1Click:Connect(function() JumpPred = not JumpPred JumpBtn.Text = JumpPred and "Jump ON" or "Jump OFF" JumpBtn.BackgroundColor3 = JumpPred and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)
UltraBtn.MouseButton1Click:Connect(function() UltraPred = not UltraPred UltraBtn.Text = UltraPred and "Ultra ON" or "Ultra OFF" UltraBtn.BackgroundColor3 = UltraPred and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)
IABtn.MouseButton1Click:Connect(function() IAPred = not IAPred IABtn.Text = IAPred and "IA ON" or "IA OFF" IABtn.BackgroundColor3 = IAPred and Color3.fromRGB(0,120,0) or Color3.fromRGB(20,35,80) end)

LocalPlayer.CharacterAdded:Connect(function() if KillAuraEnabled then task.wait(0.5) SetPitImmunity(true) end end)

function Refresh()
	for _,v in pairs(scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
	local ly = Instance.new("UIListLayout", scroll) ly.Padding = UDim.new(0,4)
	for _,p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local b = Instance.new("TextButton", scroll)
			b.Size = UDim2.new(1,-10,0,28)
			b.Text = p.DisplayName.." ("..p.Name..")"
			b.Font = Enum.Font.Garamond; b.TextScaled = true
			b.BackgroundColor3 = SelectedTargets[p] and Color3.fromRGB(120,180,255) or Color3.new(1,1,1)
			Instance.new("UICorner", b)
			b.MouseButton1Click:Connect(function() SelectedTargets[p] = not SelectedTargets[p] Refresh() end)
		end
	end
end
task.spawn(function() while task.wait(3) do Refresh() end end)
Refresh()
