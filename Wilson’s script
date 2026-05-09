local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ── STATE ──────────────────────────────────────────────────
local selectedTargets = {}
local saved           = {}
local dead            = {}

local AUTO, SMART, JUMP, AUTOTP = false, false, false, false
local ULTRA, HITCHANCE          = false, false
local AIPRED                    = false
local CLICKTP                   = false
local killEnabled               = false

local history, patterns = {}, {}

local targetPlayer    = nil
local autoTPLastShoot = 0
local isFrozen        = false
local freezeBody      = nil
local FLING_THRESHOLD = 100

local clickTPConn = nil

local autoGrapplerEnabled = false
local autoGrapplerToolRef = nil
local autoGrapplerRemote  = nil
local autoGrapplerConn    = nil

-- Button debounce helper
local btnCooldowns = {}
local BTN_DELAY    = 0.1
local TOGGLE_EXTRA = 0.08

local function canPress(id, isToggle)
	local now   = tick()
	local delay = BTN_DELAY + (isToggle and TOGGLE_EXTRA or 0)
	if (now - (btnCooldowns[id] or 0)) < delay then return false end
	btnCooldowns[id] = now
	return true
end

-- ── GUI ────────────────────────────────────────────────────
local gui1 = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui1.ResetOnSpawn = false
gui1.Name = "AutograpplerGui"

local frame1 = Instance.new("Frame", gui1)
frame1.Size              = UDim2.new(0,330,0,520)
frame1.Position          = UDim2.new(1,-350,0.5,-260)
frame1.BackgroundColor3  = Color3.fromRGB(10,10,10)
frame1.BackgroundTransparency = 0.3
frame1.Visible           = false
frame1.Active            = true
frame1.Draggable         = true
Instance.new("UICorner", frame1)

local title1 = Instance.new("TextLabel", frame1)
title1.Size                  = UDim2.new(1,0,0,30)
title1.Text                  = "Autograppler by Hxdes"
title1.BackgroundTransparency= 1
title1.TextColor3            = Color3.new(1,1,1)
title1.Font                  = Enum.Font.Bodoni
title1.TextSize              = 18

local openBtn1 = Instance.new("TextButton", gui1)
openBtn1.Size                = UDim2.new(0,60,0,60)
openBtn1.Position            = UDim2.new(0,20,0.5,0)
openBtn1.Text                = "Aim"
openBtn1.TextScaled          = true
openBtn1.BackgroundTransparency = 0.4
openBtn1.Font                = Enum.Font.Bodoni
openBtn1.Draggable           = true
Instance.new("UICorner", openBtn1).CornerRadius = UDim.new(1,0)

openBtn1.MouseButton1Click:Connect(function()
	if not canPress("openBtn1", false) then return end
	frame1.Visible = not frame1.Visible
end)

local function makeBtn1(txt, pos)
	local b = Instance.new("TextButton", frame1)
	b.Size               = UDim2.new(0.45,0,0,32)
	b.Position           = pos
	b.BackgroundColor3   = Color3.fromRGB(25,25,25)
	b.BackgroundTransparency = 0.2
	b.TextColor3         = Color3.new(1,1,1)
	b.Text               = txt
	b.Font               = Enum.Font.Bodoni
	b.TextSize           = 14
	Instance.new("UICorner", b)
	return b
end

local autoBtn1       = makeBtn1("Auto: OFF",        UDim2.new(0.03,0,0,45))
local autoGrappleBtn1= makeBtn1("AutoGrapple: OFF", UDim2.new(0.52,0,0,45))
local smartBtn1      = makeBtn1("Smart: OFF",       UDim2.new(0.03,0,0,90))
local jumpBtn1       = makeBtn1("JumpRed: OFF",     UDim2.new(0.52,0,0,90))
local clickTPBtn1    = makeBtn1("ClickTP: OFF",     UDim2.new(0.03,0,0,135))
local tpBtn1         = makeBtn1("AutoTP: OFF",      UDim2.new(0.52,0,0,135))
local killBtn1       = makeBtn1("Kill: OFF",        UDim2.new(0.03,0,0,180))
local ultraBtn1      = makeBtn1("Ultra: OFF",       UDim2.new(0.52,0,0,180))
local hitBtn1        = makeBtn1("Hit: OFF",         UDim2.new(0.03,0,0,225))
local aiBtn1         = makeBtn1("AI: OFF",          UDim2.new(0.52,0,0,225))
local clearBtn1      = makeBtn1("Clear",            UDim2.new(0.03,0,0,270))

local scroll1 = Instance.new("ScrollingFrame", frame1)
scroll1.Size                = UDim2.new(1,-10,0,180)
scroll1.Position            = UDim2.new(0,5,0,315)
scroll1.ScrollBarThickness  = 6
scroll1.BackgroundTransparency = 1

local layout1 = Instance.new("UIListLayout", scroll1)
layout1.Padding = UDim.new(0,3)

-- ── HELPERS ───────────────────────────────────────────────
local function getRoot1(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("LowerTorso")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("Head")
end

local function isFullySpawned1(p)
	local char = p and p.Character; if not char then return false end
	local hum  = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if not getRoot1(char) then return false end
	if char:FindFirstChildOfClass("ForceField") then return false end
	return true
end

local function isTargetValid1(p)
	if not p or not isFullySpawned1(p) then return false end
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function isAlive1(p)
	if not p or not p.Character then return false end
	if dead[p] then return false end
	return isFullySpawned1(p)
end

-- ── TOGGLE TOUCH (replaces noclip loop) ───────────────────
-- Called once on Kill ON/OFF — no per-frame loop needed
local function toggleTouch(isEnabled)
	local char = LocalPlayer.Character; if not char then return end
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = not isEnabled
			v.CanTouch   = not isEnabled
		end
	end
end

-- ── TARGET PICKER ─────────────────────────────────────────
local function closest1()
	local myRoot = getRoot1(LocalPlayer.Character)
	if not myRoot then return nil end
	local best, dist = nil, math.huge
	local toRemove = {}
	for userId in pairs(selectedTargets) do
		local p = Players:GetPlayerByUserId(userId)
		if not p or p == LocalPlayer then
			toRemove[#toRemove+1] = userId
		elseif not isAlive1(p) then
			-- skip this frame, may be respawning
		else
			local root = getRoot1(p.Character)
			if root then
				local d = (root.Position - myRoot.Position).Magnitude
				if d < dist then dist = d; best = p end
			end
		end
	end
	for _, uid in ipairs(toRemove) do selectedTargets[uid] = nil end
	return best
end

local function chooseStuds1(ws, vs, moving)
	local extra = math.clamp(vs/2, 0, 100)
	if not moving or vs < 1 then return math.random(3,8),   0.150 end
	if ws == 16  then return math.random(8,15)+extra,        0.150 end
	if ws == 50  then return math.random(60,120)+extra,      0.200 end
	if ws == 100 then return math.random(140,190)+extra,     0.335 end
	return math.random(40,80)+extra, 0.200
end

local function spinTeleportToTarget1(p)
	local myRoot = getRoot1(LocalPlayer.Character)
	local tRoot  = getRoot1(p.Character)
	if not myRoot or not tRoot then return end
	myRoot.CFrame = tRoot.CFrame * CFrame.new(math.random(-50,50), 0, math.random(-50,50))
end

-- ── PREDICTION ────────────────────────────────────────────
local function updateLearning1(p, pos)
	history[p] = history[p] or {}
	table.insert(history[p], pos)
	if #history[p] > 6 then table.remove(history[p], 1) end
	if #history[p] >= 2 then
		patterns[p] = history[p][#history[p]] - history[p][#history[p]-1]
	end
end

local function predict1(p)
	local root = getRoot1(p.Character)
	local me   = getRoot1(LocalPlayer.Character)
	if not root or not me then return nil end
	local pos  = root.Position
	local vel  = root.AssemblyLinearVelocity
	updateLearning1(p, pos)
	local dist   = (pos - me.Position).Magnitude
	local t      = math.clamp(dist/120, 0.05, 0.8)
	local future = pos + vel * t
	if SMART  then future = future + vel * 0.2 end
	if ULTRA and patterns[p] then future = future + patterns[p] * 2 end
	if AIPRED then
		local rand   = Vector3.new(math.sin(tick()*3), 0, math.cos(tick()*3))
		local adapt  = vel.Magnitude / 50
		future = future + (vel * 0.3 * adapt) + (rand * 3)
		if patterns[p] then future = future + patterns[p] * 1.5 end
	end
	if not JUMP then future = Vector3.new(future.X, pos.Y, future.Z) end
	return future
end

-- ── GRAPPLE HELPERS ───────────────────────────────────────
local function getGrappleRemote1()
	local char = LocalPlayer.Character; if not char then return nil, nil end
	local tool = char:FindFirstChildOfClass("Tool"); if not tool then return nil, nil end
	return tool:FindFirstChildOfClass("RemoteEvent"), tool
end

local function findGrappleTool1()
	if LocalPlayer.Character then
		local t = LocalPlayer.Character:FindFirstChild("Grapple"); if t then return t end
	end
	return LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Grapple")
end

local function tryDisableMain1(tool)
	if not tool then return end
	local ms = tool:FindFirstChild("Main")
	if ms and ms:IsA("Script") then pcall(function() ms.Disabled = true end) end
end

local function tryRestoreMain1(tool)
	if not tool then return end
	local ms = tool:FindFirstChild("Main")
	if ms and ms:IsA("Script") then pcall(function() ms.Disabled = false end) end
end

local function findMouseClickBindable1()
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj.Name == "mouseClick" and obj:IsA("BindableEvent") then return obj end
	end
end

-- ── AUTO GRAPPLER ─────────────────────────────────────────
local function fireAutoGrappler1()
	local t = closest1(); if not t then return end
	if not (t.Character and t.Character.PrimaryPart) then return end
	local pos = predict1(t); if not pos then return end
	if autoGrapplerRemote then
		pcall(function() autoGrapplerRemote:FireServer(pos) end); return
	end
	if autoGrapplerToolRef then
		local re = autoGrapplerToolRef:FindFirstChildOfClass("RemoteEvent")
		if re then pcall(function() re:FireServer(pos) end) end
	end
end

local function enableAutoGrappler1()
	autoGrapplerToolRef = findGrappleTool1(); if not autoGrapplerToolRef then return false end
	if autoGrapplerToolRef.Parent == LocalPlayer.Backpack and LocalPlayer.Character then
		pcall(function() autoGrapplerToolRef.Parent = LocalPlayer.Character end); task.wait(0.05)
	end
	local fr = nil
	for _, c in ipairs(autoGrapplerToolRef:GetDescendants()) do
		if c:IsA("RemoteEvent") then fr = c; break end
	end
	autoGrapplerRemote = fr
	tryDisableMain1(autoGrapplerToolRef)
	local bindable = findMouseClickBindable1(); if not bindable then return false end
	if autoGrapplerConn then pcall(function() autoGrapplerConn:Disconnect() end) end
	autoGrapplerConn = bindable.Event:Connect(function()
		if not autoGrapplerEnabled then return end
		fireAutoGrappler1()
	end)
	return true
end

local function disableAutoGrappler1()
	if autoGrapplerConn then pcall(function() autoGrapplerConn:Disconnect() end); autoGrapplerConn = nil end
	if autoGrapplerToolRef then tryRestoreMain1(autoGrapplerToolRef) end
	autoGrapplerRemote = nil; autoGrapplerToolRef = nil
end

-- ── CLICK TP ──────────────────────────────────────────────
local function isClickOverGui1(pos)
	if not pos then return false end
	local guis = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)
	for _, g in ipairs(guis) do if g:IsDescendantOf(gui1) then return true end end
	return false
end

local function enableClickTP1()
	if clickTPConn then clickTPConn:Disconnect(); clickTPConn = nil end
	clickTPConn = UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not CLICKTP then return end
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			if isClickOverGui1(input.Position) then return end
			local tgtPlayer = closest1()
			if tgtPlayer and tgtPlayer.Character and getRoot1(tgtPlayer.Character) then
				spinTeleportToTarget1(tgtPlayer)
			end
		end
	end)
end

local function disableClickTP1()
	if clickTPConn then clickTPConn:Disconnect(); clickTPConn = nil end
end

-- ── FREEZE HELPERS ────────────────────────────────────────
local function applyFreeze1()
	if isFrozen then return end
	local root = getRoot1(LocalPlayer.Character); if not root then return end
	isFrozen = true
	if freezeBody then freezeBody:Destroy() end
	freezeBody = Instance.new("BodyVelocity")
	freezeBody.Velocity  = Vector3.new(0,0,0)
	freezeBody.MaxForce  = Vector3.new(1e9,1e9,1e9)
	freezeBody.P         = 1e9
	freezeBody.Parent    = root
end

local function releaseFreeze1()
	if not isFrozen then return end
	if freezeBody then freezeBody:Destroy(); freezeBody = nil end
	isFrozen = false
end

-- ── KILL LOOP ─────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
	if not killEnabled then return end
	local pit = Workspace:FindFirstChild("Pit")
	local dp  = pit and pit:FindFirstChild("Damage")
	if dp then
		local closestRoot, closestDist = nil, math.huge
		local myRoot = getRoot1(LocalPlayer.Character)
		for userId in pairs(selectedTargets) do
			local p = Players:GetPlayerByUserId(userId)
			if p and p ~= LocalPlayer and isTargetValid1(p) then
				local root = getRoot1(p.Character)
				if root and myRoot then
					local d = (root.Position - myRoot.Position).Magnitude
					if d < closestDist then closestDist = d; closestRoot = root end
				end
			end
		end
		if closestRoot then
			dp.CFrame = closestRoot.CFrame; dp.Size = Vector3.new(9999,9999,9999)
		else
			dp.CFrame = CFrame.new(0,-15.75,0); dp.Size = Vector3.new(3.5,33,33)
		end
	end
	local char = LocalPlayer.Character
	if char then local r = char:FindFirstChild("ragdollValue"); if r then r:Destroy() end end
end)

-- ── AUTO TP LOOP ──────────────────────────────────────────
RunService.RenderStepped:Connect(function()
	if not AUTOTP then
		if isFrozen then releaseFreeze1() end
		return
	end

	if targetPlayer then
		if not targetPlayer.Character then
			targetPlayer = nil; autoTPLastShoot = tick(); return
		end
		if targetPlayer.Character:FindFirstChildOfClass("ForceField") then return end
		if not isAlive1(targetPlayer) then
			targetPlayer = nil; autoTPLastShoot = tick(); return
		end
	end

	if not targetPlayer then
		targetPlayer = closest1(); autoTPLastShoot = tick()
	end
	if not targetPlayer then return end

	local newT = closest1()
	if newT and newT ~= targetPlayer then
		local myR = getRoot1(LocalPlayer.Character)
		local cR  = getRoot1(targetPlayer.Character)
		local nR  = getRoot1(newT.Character)
		if myR and cR and nR then
			if (nR.Position-myR.Position).Magnitude < (cR.Position-myR.Position).Magnitude - 5 then
				targetPlayer = newT
			end
		end
	end

	local myRoot = getRoot1(LocalPlayer.Character)
	local tRoot  = getRoot1(targetPlayer.Character)
	local tHum   = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not (myRoot and tRoot and tHum) then
		targetPlayer = closest1(); autoTPLastShoot = tick(); return
	end

	local mySpeed = myRoot.AssemblyLinearVelocity.Magnitude
	if mySpeed > FLING_THRESHOLD and not isFrozen then applyFreeze1()
	elseif mySpeed < 20 and isFrozen then releaseFreeze1() end

	local vs = tRoot.AssemblyLinearVelocity.Magnitude
	local offset, delay = chooseStuds1(tHum.WalkSpeed, vs, vs > 1)
	myRoot.CFrame = CFrame.new(tRoot.Position + tRoot.CFrame.LookVector * offset, tRoot.Position)

	if tick() - autoTPLastShoot >= delay then
		local remote, tool = getGrappleRemote1()
		if tool then
			local rope = tool:FindFirstChild("Rope")
			if rope and rope.Visible then
				if not isAlive1(targetPlayer) then targetPlayer = closest1(); autoTPLastShoot = tick() end
			else
				local pos = predict1(targetPlayer)
				if pos and remote then pcall(function() remote:FireServer(pos) end) end
				autoTPLastShoot = tick()
			end
		end
	end
end)

-- ── AUTO SHOOT LOOP ───────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(0.12)
		if AUTO then
			local t = closest1()
			if t then
				local pos = predict1(t)
				if pos then
					local remote = getGrappleRemote1()
					if remote then pcall(function() remote:FireServer(pos) end) end
				end
			end
		end
	end
end)

-- ── PLAYER TRACKING ───────────────────────────────────────
local function trackPlayer1(p)
	p.CharacterAdded:Connect(function(char)
		dead[p] = false
		if saved[p.Name] then selectedTargets[p.UserId] = true end
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				dead[p] = true
				if targetPlayer == p then targetPlayer = nil end
			end)
		end
	end)
end

for _, p in pairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then trackPlayer1(p) end
end
Players.PlayerAdded:Connect(function(p)
	if p ~= LocalPlayer then trackPlayer1(p) end
	refresh1()
end)
Players.PlayerRemoving:Connect(function(p)
	selectedTargets[p.UserId] = nil; refresh1()
end)

-- ── PLAYER LIST ───────────────────────────────────────────
function refresh1()
	for _, v in pairs(scroll1:GetChildren()) do
		if v:IsA("TextButton") then v:Destroy() end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local b = Instance.new("TextButton", scroll1)
			b.Size            = UDim2.new(1,0,0,22)
			b.Text            = p.DisplayName
			b.BackgroundColor3= selectedTargets[p.UserId] and Color3.fromRGB(0,170,255) or Color3.fromRGB(40,40,40)
			b.TextColor3      = Color3.new(1,1,1)
			b.Font            = Enum.Font.Bodoni
			b.TextSize        = 14
			Instance.new("UICorner", b)
			if saved[p.Name] then selectedTargets[p.UserId] = true end
			b.MouseButton1Click:Connect(function()
				if not canPress("list_"..p.UserId, false) then return end
				if selectedTargets[p.UserId] then
					selectedTargets[p.UserId] = nil; saved[p.Name] = nil
				else
					selectedTargets[p.UserId] = true; saved[p.Name] = true
				end
				refresh1()
			end)
		end
	end
end

refresh1()

-- ── BUTTON CONNECTIONS ────────────────────────────────────
autoBtn1.MouseButton1Click:Connect(function()
	if not canPress("auto1", true) then return end
	AUTO = not AUTO; autoBtn1.Text = "Auto: "..(AUTO and "ON" or "OFF")
end)

autoGrappleBtn1.MouseButton1Click:Connect(function()
	if not canPress("ag1", true) then return end
	autoGrapplerEnabled = not autoGrapplerEnabled
	autoGrappleBtn1.Text = "AutoGrapple: "..(autoGrapplerEnabled and "ON" or "OFF")
	if autoGrapplerEnabled then
		if not enableAutoGrappler1() then autoGrapplerEnabled = false; autoGrappleBtn1.Text = "AutoGrapple: OFF" end
	else disableAutoGrappler1() end
end)

smartBtn1.MouseButton1Click:Connect(function()
	if not canPress("smart1", true) then return end
	SMART = not SMART; smartBtn1.Text = "Smart: "..(SMART and "ON" or "OFF")
end)

jumpBtn1.MouseButton1Click:Connect(function()
	if not canPress("jump1", true) then return end
	JUMP = not JUMP; jumpBtn1.Text = "JumpRed: "..(JUMP and "ON" or "OFF")
end)

clickTPBtn1.MouseButton1Click:Connect(function()
	if not canPress("clicktp1", true) then return end
	CLICKTP = not CLICKTP; clickTPBtn1.Text = "ClickTP: "..(CLICKTP and "ON" or "OFF")
	if CLICKTP then enableClickTP1() else disableClickTP1() end
end)

tpBtn1.MouseButton1Click:Connect(function()
	if not canPress("tp1", true) then return end
	AUTOTP = not AUTOTP; tpBtn1.Text = "AutoTP: "..(AUTOTP and "ON" or "OFF")
	if not AUTOTP then releaseFreeze1(); targetPlayer = nil end
end)

-- Kill button — uses toggleTouch instead of a per-frame noclip loop
killBtn1.MouseButton1Click:Connect(function()
	if not canPress("kill1", true) then return end
	killEnabled = not killEnabled
	killBtn1.Text = "Kill: "..(killEnabled and "ON" or "OFF")
	toggleTouch(killEnabled)
	if not killEnabled then
		-- restore the pit damage part to its default position/size when turning off
		local pit = Workspace:FindFirstChild("Pit"); local dp = pit and pit:FindFirstChild("Damage")
		if dp then dp.CFrame = CFrame.new(0,-15.75,0); dp.Size = Vector3.new(3.5,33,33) end
	end
end)

ultraBtn1.MouseButton1Click:Connect(function()
	if not canPress("ultra1", true) then return end
	ULTRA = not ULTRA; ultraBtn1.Text = "Ultra: "..(ULTRA and "ON" or "OFF")
end)

hitBtn1.MouseButton1Click:Connect(function()
	if not canPress("hit1", true) then return end
	HITCHANCE = not HITCHANCE; hitBtn1.Text = "Hit: "..(HITCHANCE and "ON" or "OFF")
end)

aiBtn1.MouseButton1Click:Connect(function()
	if not canPress("ai1", true) then return end
	AIPRED = not AIPRED; aiBtn1.Text = "AI: "..(AIPRED and "ON" or "OFF")
end)

clearBtn1.MouseButton1Click:Connect(function()
	if not canPress("clear1", false) then return end
	for uid in pairs(selectedTargets) do selectedTargets[uid] = nil end
	for n in pairs(saved) do saved[n] = nil end
	targetPlayer = nil; refresh1()
end)

-- ── RESTORE ON RESPAWN ────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
	task.spawn(function()
		repeat task.wait(0.1) until isFullySpawned1(LocalPlayer)
		releaseFreeze1()
		-- Re-apply collision toggle if Kill was active when we respawned
		if killEnabled then toggleTouch(true) end
		if autoGrapplerEnabled then task.wait(0.3); enableAutoGrappler1() end
		if CLICKTP then enableClickTP1() end
	end)
end)
