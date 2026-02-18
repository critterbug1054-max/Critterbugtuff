-- ═══════════════════════════════════════════════════════════════
-- 🎮 ULTIMATE ROBLOX TOOLKIT - ALL-IN-ONE RAYFIELD SCRIPT
--  + Move / Mode Renamer Tab
--  + Malevolent Shrine Domain Expansion Tab (ENHANCED & CAMERA FIX)
--  + MAHORAGA SKIN FOR BESTO FRIENDO (FIXED - VISIBLE & MOVING!)
--  + MAHORAGA SKIN FOR ANY PLAYER IN SERVER
--  + Color Tools, Hitbox, Attributes
--  + AUDIO ON SPAWN
--  + STICKY TELEPORT (GLUES TO TARGET)
-- ═══════════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🎮 Ultimate Roblox Toolkit",
    LoadingTitle = "Ultimate Toolkit Loading",
    LoadingSubtitle = "All-in-One Roblox Script Suite",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "UltimateToolkit_Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- ═══════════════════════════════════════════════════════════════
-- SERVICES & GLOBALS
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local Player = Players.LocalPlayer
local playerGui = Player.PlayerGui
local Camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════
-- 🎭 MAHORAGA SKIN SYSTEM (FIXED - VISIBLE & ALLOWS MOVEMENT!)
-- ═══════════════════════════════════════════════════════════════

local MahoragaSkinEnabled = false
local MAHORAGA_MODEL_ID = 15748584575
local MAHORAGA_SPAWN_AUDIO_ID = "rbxassetid://74841585220876" -- Spawn audio
local MahoragaModel = nil
local ActiveMahoragaSkins = {}
local MahoragaMonitorConnection = nil
local ProcessedNPCs = {}
local MahoragaHeightOffset = 3
local MahoragaTeleportAttackEnabled = true
local MahoragaStickyConnection = nil -- NEW: For sticky follow
local MahoragaStickyTarget = nil -- NEW: Current sticky target
local PlayerMahoragaSkins = {} -- NEW: Track player Mahoraga skins
local SelectedPlayerForMahoraga = nil -- NEW: Selected player to transform

local function LoadMahoragaModel()
    if MahoragaModel then return MahoragaModel end
    print("📥 Loading Mahoraga model...")
    local success, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. MAHORAGA_MODEL_ID)[1]
    end)
    if success and result then
        MahoragaModel = result
        MahoragaModel.Parent = nil
        print("✅ Mahoraga model loaded!")
        return MahoragaModel
    else
        warn("⚠️ Failed to load Mahoraga model:", result)
        return nil
    end
end

local function ApplyMahoragaSkin(character)
    if not character or not MahoragaSkinEnabled then return end
    if ActiveMahoragaSkins[character] or ProcessedNPCs[character] then return end

    print("🎭 APPLYING MAHORAGA TO:", character.Name, "at", character:GetFullName())
    ProcessedNPCs[character] = true

    local baseModel = LoadMahoragaModel()
    if not baseModel then return end

    local hrp = character:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return end

    task.wait(0.2)
    local mahoragaClone = baseModel:Clone()
    
    if mahoragaClone:IsA("Model") then
        pcall(function() mahoragaClone:ScaleTo(3) end)
    end

    mahoragaClone.Parent = character

    -- Position Mahoraga model FIRST at the HRP position with Y-offset to keep it above ground
    if mahoragaClone.PrimaryPart then
        mahoragaClone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, MahoragaHeightOffset, 0))
    else
        local firstPart = mahoragaClone:FindFirstChildWhichIsA("BasePart")
        if firstPart then 
            -- Move the whole model to center on HRP with height offset
            mahoragaClone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, MahoragaHeightOffset, 0))
        end
    end

    -- MAKE MAHORAGA PARTS VISIBLE AND NON-COLLIDABLE
    for _, part in pairs(mahoragaClone:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Keep parts VISIBLE
            part.Transparency = 0
            part.CanCollide = false
            part.Massless = true
            
            -- HIDE SWORD IN CHEST - Look for sword/blade parts
            local partName = part.Name:lower()
            if partName:find("sword") or partName:find("blade") or partName:find("katana") or partName:find("weapon") then
                part.Transparency = 1 -- Hide the sword
                print("🗡️ Hidden sword part:", part.Name)
            end
            
            -- Weld to HRP with proper offset - capture the part's position AFTER model is centered
            local weld = Instance.new("Weld")
            weld.Part0 = hrp
            weld.Part1 = part
            -- C0 has the Y offset to keep model above ground
            weld.C0 = CFrame.new(0, MahoragaHeightOffset, 0)
            weld.C1 = part.CFrame:ToObjectSpace(hrp.CFrame * CFrame.new(0, MahoragaHeightOffset, 0))
            weld.Parent = part
        elseif part:IsA("Decal") or part:IsA("Texture") then
            -- Keep textures visible
            part.Transparency = 0
        end
    end

    -- Hide original body parts (make invisible but keep collision for movement)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
            local face = part:FindFirstChildOfClass("Decal")
            if face then face.Transparency = 1 end
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = 1 end
        end
    end

    -- 🔊 PLAY SPAWN AUDIO
    local spawnSound = Instance.new("Sound")
    spawnSound.Name = "MahoragaSpawnSound"
    spawnSound.SoundId = MAHORAGA_SPAWN_AUDIO_ID
    spawnSound.Volume = 1
    spawnSound.Parent = hrp
    spawnSound:Play()
    Debris:AddItem(spawnSound, 10)
    print("🔊 Playing Mahoraga spawn audio!")

    -- WALK ANIMATION SYSTEM
    local animationConnection
    local bobTime = 0
    
    -- Simple bob animation when walking
    animationConnection = RunService.Heartbeat:Connect(function(dt)
        if not character.Parent or not MahoragaSkinEnabled then
            if animationConnection then animationConnection:Disconnect() end
            return
        end
        
        -- Check if NPC is moving
        local velocity = hrp.Velocity
        local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        
        if horizontalSpeed > 1 then
            bobTime = bobTime + dt * 8 -- Speed of bob
            
            -- Apply walking bob to all Mahoraga parts
            for _, part in pairs(mahoragaClone:GetDescendants()) do
                if part:IsA("BasePart") then
                    local weld = part:FindFirstChildOfClass("Weld")
                    if weld then
                        local bobOffset = math.sin(bobTime) * 0.3
                        -- Add slight bob motion while maintaining Y-offset
                        weld.C0 = CFrame.new(0, MahoragaHeightOffset + bobOffset, 0) * CFrame.Angles(
                            math.sin(bobTime * 0.5) * 0.05, -- Slight pitch
                            0,
                            math.sin(bobTime) * 0.03 -- Slight roll
                        )
                    end
                end
            end
        else
            bobTime = 0
            
            -- Reset to idle position (with Y-offset maintained)
            for _, part in pairs(mahoragaClone:GetDescendants()) do
                if part:IsA("BasePart") then
                    local weld = part:FindFirstChildOfClass("Weld")
                    if weld then
                        weld.C0 = CFrame.new(0, MahoragaHeightOffset, 0)
                    end
                end
            end
        end
    end)

    ActiveMahoragaSkins[character] = {
        model = mahoragaClone,
        animConnection = animationConnection
    }
    
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if ActiveMahoragaSkins[character] then
                if ActiveMahoragaSkins[character].animConnection then
                    ActiveMahoragaSkins[character].animConnection:Disconnect()
                end
                if ActiveMahoragaSkins[character].model then
                    ActiveMahoragaSkins[character].model:Destroy()
                end
            end
            ActiveMahoragaSkins[character] = nil
            ProcessedNPCs[character] = nil
        end
    end)
    
    print("✅ MAHORAGA SKIN APPLIED TO:", character.Name, "- WITH WALK ANIMATION!")
end

-- NEW: Apply Mahoraga skin to a specific player
local function ApplyPlayerMahoragaSkin(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        print("⚠️ Target player has no character")
        return false
    end
    
    local character = targetPlayer.Character
    
    -- Check if already has Mahoraga skin
    if PlayerMahoragaSkins[targetPlayer.UserId] then
        print("⚠️ Player already has Mahoraga skin")
        return false
    end
    
    print("🎭 APPLYING PLAYER MAHORAGA TO:", targetPlayer.Name)
    
    local baseModel = LoadMahoragaModel()
    if not baseModel then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local mahoragaClone = baseModel:Clone()
    
    if mahoragaClone:IsA("Model") then
        pcall(function() mahoragaClone:ScaleTo(3) end)
    end
    
    mahoragaClone.Parent = character
    
    -- Position Mahoraga model
    if mahoragaClone.PrimaryPart then
        mahoragaClone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, MahoragaHeightOffset, 0))
    else
        local firstPart = mahoragaClone:FindFirstChildWhichIsA("BasePart")
        if firstPart then 
            mahoragaClone:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, MahoragaHeightOffset, 0))
        end
    end
    
    -- Make Mahoraga parts visible and weld them
    for _, part in pairs(mahoragaClone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
            part.CanCollide = false
            part.Massless = true
            
            local partName = part.Name:lower()
            if partName:find("sword") or partName:find("blade") or partName:find("katana") or partName:find("weapon") then
                part.Transparency = 1
                print("🗡️ Hidden sword part:", part.Name)
            end
            
            local weld = Instance.new("Weld")
            weld.Part0 = hrp
            weld.Part1 = part
            weld.C0 = CFrame.new(0, MahoragaHeightOffset, 0)
            weld.C1 = part.CFrame:ToObjectSpace(hrp.CFrame * CFrame.new(0, MahoragaHeightOffset, 0))
            weld.Parent = part
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 0
        end
    end
    
    -- Hide original body parts
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
            local face = part:FindFirstChildOfClass("Decal")
            if face then face.Transparency = 1 end
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = 1 end
        end
    end
    
    -- Play spawn audio
    local spawnSound = Instance.new("Sound")
    spawnSound.Name = "MahoragaSpawnSound"
    spawnSound.SoundId = MAHORAGA_SPAWN_AUDIO_ID
    spawnSound.Volume = 1
    spawnSound.Parent = hrp
    spawnSound:Play()
    Debris:AddItem(spawnSound, 10)
    
    -- Walk animation
    local animationConnection
    local bobTime = 0
    
    animationConnection = RunService.Heartbeat:Connect(function(dt)
        if not character.Parent then
            if animationConnection then animationConnection:Disconnect() end
            return
        end
        
        local velocity = hrp.Velocity
        local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        
        if horizontalSpeed > 1 then
            bobTime = bobTime + dt * 8
            
            for _, part in pairs(mahoragaClone:GetDescendants()) do
                if part:IsA("BasePart") then
                    local weld = part:FindFirstChildOfClass("Weld")
                    if weld then
                        local bobOffset = math.sin(bobTime) * 0.3
                        weld.C0 = CFrame.new(0, MahoragaHeightOffset + bobOffset, 0) * CFrame.Angles(
                            math.sin(bobTime * 0.5) * 0.05,
                            0,
                            math.sin(bobTime) * 0.03
                        )
                    end
                end
            end
        else
            bobTime = 0
            
            for _, part in pairs(mahoragaClone:GetDescendants()) do
                if part:IsA("BasePart") then
                    local weld = part:FindFirstChildOfClass("Weld")
                    if weld then
                        weld.C0 = CFrame.new(0, MahoragaHeightOffset, 0)
                    end
                end
            end
        end
    end)
    
    -- Store player Mahoraga data
    PlayerMahoragaSkins[targetPlayer.UserId] = {
        player = targetPlayer,
        model = mahoragaClone,
        animConnection = animationConnection,
        character = character
    }
    
    -- Cleanup on character removal
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if PlayerMahoragaSkins[targetPlayer.UserId] then
                if PlayerMahoragaSkins[targetPlayer.UserId].animConnection then
                    PlayerMahoragaSkins[targetPlayer.UserId].animConnection:Disconnect()
                end
                if PlayerMahoragaSkins[targetPlayer.UserId].model then
                    PlayerMahoragaSkins[targetPlayer.UserId].model:Destroy()
                end
                PlayerMahoragaSkins[targetPlayer.UserId] = nil
            end
        end
    end)
    
    print("✅ PLAYER MAHORAGA SKIN APPLIED TO:", targetPlayer.Name)
    return true
end

-- NEW: Remove Mahoraga skin from a player
local function RemovePlayerMahoragaSkin(targetPlayer)
    if not targetPlayer then return false end
    
    local skinData = PlayerMahoragaSkins[targetPlayer.UserId]
    if not skinData then
        print("⚠️ Player doesn't have Mahoraga skin")
        return false
    end
    
    -- Disconnect animation
    if skinData.animConnection then
        skinData.animConnection:Disconnect()
    end
    
    -- Remove Mahoraga model
    if skinData.model and skinData.model.Parent then
        skinData.model:Destroy()
    end
    
    -- Restore original body parts
    local character = skinData.character
    if character and character.Parent then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                local face = part:FindFirstChildOfClass("Decal")
                if face then face.Transparency = 0 end
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then handle.Transparency = 0 end
            end
        end
    end
    
    PlayerMahoragaSkins[targetPlayer.UserId] = nil
    print("✅ REMOVED PLAYER MAHORAGA SKIN FROM:", targetPlayer.Name)
    return true
end

-- ULTRA AGGRESSIVE DETECTION - WILL FIND ANY NPC (CATCHES EVERYTHING)
local function IsBestoFriendoNPC(character)
    if not character or not character:IsA("Model") then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end

    -- Skip real players
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character == character then return false end
    end

    local name = character.Name
    print("🔍 SCANNING MODEL:", name, "at", character:GetFullName()) -- DEBUG

    -- YOUR SPECIFIC FRIEND (most important)
    if name:find("Califer") or name:find("Friend") then
        print("🎯 MAHORAGA HIT: Califer/Friend match =>", name)
        return true
    end

    -- ANY summon patterns
    if name:find("Friend") or name:find("Clone") or name:find("'s ") then
        print("🎯 MAHORAGA HIT: Generic summon =>", name)
        return true
    end

    -- ANY NPC near you (backup) - THIS CATCHES FACTORY STAFF
    local myChar = Player.Character
    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
        local dist = (character:GetModelCFrame().Position - myChar.HumanoidRootPart.Position).Magnitude
        if dist < 100 then -- Anything within 100 studs
            print("🎯 MAHORAGA HIT: Close NPC backup =>", name, dist.." studs")
            return true
        end
    end

    return false
end
-- 🗡️ MAHORAGA TELEPORT ATTACK SYSTEM (STICKY VERSION - GLUES TO TARGET)
local function FindClosestEnemy()
    local myChar = Player.Character
    if not myChar then return nil end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    
    local closestEnemy = nil
    local closestDistance = math.huge
    
    -- Check other players
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local enemyHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = plr.Character:FindFirstChild("Humanoid")
            
            if enemyHRP and enemyHumanoid and enemyHumanoid.Health > 0 then
                local distance = (myHRP.Position - enemyHRP.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestEnemy = plr.Character
                end
            end
        end
    end
    
    -- Check NPCs in workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= myChar then
            local humanoid = obj:FindFirstChild("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            
            if humanoid and hrp and humanoid.Health > 0 then
                -- Make sure it's not a player character
                local isPlayer = false
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr.Character == obj then
                        isPlayer = true
                        break
                    end
                end
                
                if not isPlayer then
                    local distance = (myHRP.Position - hrp.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestEnemy = obj
                    end
                end
            end
        end
    end
    
    return closestEnemy, closestDistance
end

local function MahoragaTeleportAttack()
    if not MahoragaTeleportAttackEnabled then 
        print("⚠️ Mahoraga teleport attack is disabled")
        return 
    end
    
    -- Find your Mahoraga (Besto Friendo with skin)
    local mahoragaCharacter = nil
    for character, skinData in pairs(ActiveMahoragaSkins) do
        if character and character.Parent and skinData.model then
            mahoragaCharacter = character
            break
        end
    end
    
    if not mahoragaCharacter then
        print("⚠️ No Mahoraga found! Enable Mahoraga skin first.")
        return
    end
    
    local mahoragaHRP = mahoragaCharacter:FindFirstChild("HumanoidRootPart")
    if not mahoragaHRP then return end
    
    -- Find closest enemy
    local closestEnemy, distance = FindClosestEnemy()
    
    if not closestEnemy then
        print("⚠️ No enemies found nearby")
        return
    end
    
    local enemyHRP = closestEnemy:FindFirstChild("HumanoidRootPart")
    local enemyHumanoid = closestEnemy:FindFirstChild("Humanoid")
    
    if not enemyHRP or not enemyHumanoid then return end
    
    print("🗡️ MAHORAGA STICKY TELEPORT ATTACK ON:", closestEnemy.Name, "Distance:", distance)
    
    -- VISUAL: Flash effect at original position
    local flashOrigin = Instance.new("Part")
    flashOrigin.Shape = Enum.PartType.Ball
    flashOrigin.Size = Vector3.new(10, 10, 10)
    flashOrigin.Position = mahoragaHRP.Position
    flashOrigin.Anchored = true
    flashOrigin.CanCollide = false
    flashOrigin.Material = Enum.Material.Neon
    flashOrigin.Color = Color3.fromRGB(255, 255, 255)
    flashOrigin.Transparency = 0.3
    flashOrigin.Parent = workspace
    
    TweenService:Create(flashOrigin, TweenInfo.new(0.5), {
        Size = Vector3.new(20, 20, 20),
        Transparency = 1
    }):Play()
    Debris:AddItem(flashOrigin, 0.5)
    
    -- 🧲 STICKY SYSTEM - DISCONNECT OLD STICKY IF EXISTS
    if MahoragaStickyConnection then
        MahoragaStickyConnection:Disconnect()
        MahoragaStickyConnection = nil
        print("🔓 Unstuck from previous target")
    end
    
    -- Set new sticky target
    MahoragaStickyTarget = closestEnemy
    
    -- 🚀 INITIAL TELEPORT TO ENEMY
    local teleportPosition = enemyHRP.CFrame * CFrame.new(0, 0, -5) -- 5 studs in front
    mahoragaHRP.CFrame = teleportPosition
    mahoragaHRP.Velocity = Vector3.zero
    mahoragaHRP.RotVelocity = Vector3.zero
    mahoragaHRP.AssemblyLinearVelocity = Vector3.zero
    mahoragaHRP.AssemblyAngularVelocity = Vector3.zero
    
    -- 🧲 STICKY CONNECTION - GLUE TO TARGET
    MahoragaStickyConnection = RunService.Heartbeat:Connect(function()
        if not MahoragaStickyTarget or not MahoragaStickyTarget.Parent then
            -- Target died or removed
            if MahoragaStickyConnection then
                MahoragaStickyConnection:Disconnect()
                MahoragaStickyConnection = nil
            end
            MahoragaStickyTarget = nil
            print("🔓 Target lost - unstuck")
            return
        end
        
        if not mahoragaCharacter or not mahoragaCharacter.Parent then
            -- Mahoraga died
            if MahoragaStickyConnection then
                MahoragaStickyConnection:Disconnect()
                MahoragaStickyConnection = nil
            end
            MahoragaStickyTarget = nil
            print("🔓 Mahoraga lost - unstuck")
            return
        end
        
        local targetHRP = MahoragaStickyTarget:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = MahoragaStickyTarget:FindFirstChild("Humanoid")
        
        if not targetHRP or not targetHumanoid or targetHumanoid.Health <= 0 then
            -- Target died
            if MahoragaStickyConnection then
                MahoragaStickyConnection:Disconnect()
                MahoragaStickyConnection = nil
            end
            MahoragaStickyTarget = nil
            print("🔓 Target died - unstuck")
            return
        end
        
        -- GLUE MAHORAGA TO TARGET (5 studs in front)
        local stickyPosition = targetHRP.CFrame * CFrame.new(0, 0, -5)
        mahoragaHRP.CFrame = stickyPosition
        mahoragaHRP.Velocity = targetHRP.Velocity -- Match target velocity
        mahoragaHRP.RotVelocity = Vector3.zero
        mahoragaHRP.AssemblyLinearVelocity = targetHRP.AssemblyLinearVelocity
        mahoragaHRP.AssemblyAngularVelocity = Vector3.zero
        
        -- Force humanoid to face target
        if mahoragaCharacter:FindFirstChild("Humanoid") then
            local lookVector = (targetHRP.Position - mahoragaHRP.Position).Unit
            mahoragaHRP.CFrame = CFrame.new(mahoragaHRP.Position, targetHRP.Position)
        end
    end)
    
    print("🧲 MAHORAGA NOW STUCK TO TARGET!")
    
    -- VISUAL: Flash effect at destination
    local flashDest = Instance.new("Part")
    flashDest.Shape = Enum.PartType.Ball
    flashDest.Size = Vector3.new(1, 1, 1)
    flashDest.Position = teleportPosition.Position
    flashDest.Anchored = true
    flashDest.CanCollide = false
    flashDest.Material = Enum.Material.Neon
    flashDest.Color = Color3.fromRGB(255, 0, 0)
    flashDest.Transparency = 0
    flashDest.Parent = workspace
    
    TweenService:Create(flashDest, TweenInfo.new(0.5), {
        Size = Vector3.new(15, 15, 15),
        Transparency = 1
    }):Play()
    Debris:AddItem(flashDest, 0.5)
    
    -- SOUND EFFECT
    local teleportSound = Instance.new("Sound")
    teleportSound.SoundId = "rbxassetid://1177785010" -- Teleport sound
    teleportSound.Volume = 1
    teleportSound.Parent = mahoragaHRP
    teleportSound:Play()
    Debris:AddItem(teleportSound, 2)
    
    -- TRY TO USE CAVANDER/ATTACKS
    task.wait(0.2)
    
    -- Try to trigger Besto Friendo's attacks through RemoteEvents
    local success, err = pcall(function()
        -- Look for attack remotes in ReplicatedStorage
        local Net = ReplicatedStorage:FindFirstChild("Modules")
        if Net then
            Net = Net:FindFirstChild("Net")
            if Net then
                -- Try to find attack remotes
                for _, remote in pairs(Net:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and 
                       (remote.Name:find("Attack") or remote.Name:find("Skill") or remote.Name:find("Move")) then
                        
                        -- Fire the attack remote
                        pcall(function()
                            remote:FireServer(enemyHRP, enemyHumanoid)
                        end)
                    end
                end
            end
        end
        
        -- Fallback: Direct damage
        task.wait(0.5)
        enemyHumanoid:TakeDamage(50)
        
        -- Visual slash effect
        for i = 1, 5 do
            task.wait(0.1)
            local slashEffect = Instance.new("Part")
            slashEffect.Size = Vector3.new(1, 0.1, 8)
            slashEffect.CFrame = enemyHRP.CFrame * CFrame.Angles(math.random(-180, 180), math.random(-180, 180), 0)
            slashEffect.Anchored = true
            slashEffect.CanCollide = false
            slashEffect.Material = Enum.Material.Neon
            slashEffect.Color = Color3.fromRGB(255, 0, 0)
            slashEffect.Parent = workspace
            
            TweenService:Create(slashEffect, TweenInfo.new(0.3), {
                Transparency = 1,
                Size = Vector3.new(2, 0.2, 12)
            }):Play()
            Debris:AddItem(slashEffect, 0.3)
        end
    end)
    
    if not success then
        warn("Attack execution error:", err)
    end
    
    print("✅ Mahoraga stuck to", closestEnemy.Name, "like glue!")
end

-- NEW: Function to unstick Mahoraga
local function UnstickMahoraga()
    if MahoragaStickyConnection then
        MahoragaStickyConnection:Disconnect()
        MahoragaStickyConnection = nil
        MahoragaStickyTarget = nil
        print("🔓 Mahoraga unstuck manually!")
        return true
    else
        print("⚠️ Mahoraga is not stuck to anyone")
        return false
    end
end

local function StartMahoragaMonitor()
    if MahoragaMonitorConnection then MahoragaMonitorConnection:Disconnect() end
    if not MahoragaSkinEnabled then return end

    print("🚀 MAHORAGA MONITOR ACTIVATED - AGGRESSIVE SCANNING")

    LoadMahoragaModel()

    -- IMMEDIATE FULL WORKSPACE SCAN
    print("🔍 FULL WORKSPACE SCAN STARTING...")
    for _, obj in pairs(workspace:GetDescendants()) do
        if IsBestoFriendoNPC(obj) then
            task.spawn(ApplyMahoragaSkin, obj)
        end
    end
    print("🔍 INITIAL SCAN COMPLETE")

    -- NEW OBJECTS
    local conn1 = workspace.ChildAdded:Connect(function(child)
        if not MahoragaSkinEnabled then return end
        task.wait(0.5)
        if IsBestoFriendoNPC(child) then
            task.spawn(ApplyMahoragaSkin, child)
        end
    end)

    -- CONTINUOUS SCAN
    MahoragaMonitorConnection = RunService.Heartbeat:Connect(function()
        if not MahoragaSkinEnabled then return end
        if tick() % 1 < 0.05 then -- Every second
            for _, obj in pairs(workspace:GetDescendants()) do
                if IsBestoFriendoNPC(obj) and not ProcessedNPCs[obj] then
                    task.spawn(ApplyMahoragaSkin, obj)
                end
            end
        end
    end)

    print("✅ MAHORAGA MONITOR FULLY ACTIVE")
end

local function StopMahoragaMonitor()
    if MahoragaMonitorConnection then
        MahoragaMonitorConnection:Disconnect()
        MahoragaMonitorConnection = nil
    end
    
    -- Unstick when disabling
    if MahoragaStickyConnection then
        MahoragaStickyConnection:Disconnect()
        MahoragaStickyConnection = nil
        MahoragaStickyTarget = nil
    end
    
    for character, skinData in pairs(ActiveMahoragaSkins) do
        if skinData and skinData.animConnection then
            skinData.animConnection:Disconnect()
        end
        if skinData and skinData.model then
            skinData.model:Destroy()
        end
        ActiveMahoragaSkins[character] = nil
        ProcessedNPCs[character] = nil
    end
    table.clear(ProcessedNPCs)
    print("❌ MAHORAGA MONITOR STOPPED")
end

-- ═══════════════════════════════════════════════════════════════
-- 🎥 GLOBAL CAMERA FIX - RUNS ON EVERY RESPAWN
-- ═══════════════════════════════════════════════════════════════

local function ForceResetCamera()
    Camera.CameraType = Enum.CameraType.Custom
    Camera.FieldOfView = 70
    
    local char = Player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            Camera.CameraSubject = humanoid
        end
    end
    
    print("📷 FORCE CAMERA RESET!")
end

-- ALWAYS fix camera on respawn, regardless of domain state
Player.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.1)
    ForceResetCamera()
    
    -- Keep forcing for 3 seconds to be sure
    for i = 1, 30 do
        task.wait(0.1)
        ForceResetCamera()
    end
    
    print("✅ Camera locked to normal on respawn!")
end)

-- Fix camera right now if character exists
if Player.Character then
    ForceResetCamera()
end

-- ═══════════════════════════════════════════════════════════════
-- 🗡️ MAHORAGA TELEPORT ATTACK KEYBIND (P KEY)
-- ═══════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        MahoragaTeleportAttack()
    elseif input.KeyCode == Enum.KeyCode.U then
        -- NEW: U key to unstick
        UnstickMahoraga()
    end
end)

print("✅ Mahoraga Teleport Attack bound to P key!")
print("✅ Mahoraga Unstick bound to U key!")

-- ═══════════════════════════════════════════════════════════════
-- 🎨 COLOR CONVERTER MODULE
-- ═══════════════════════════════════════════════════════════════

local ColorConverter = {}

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function round(num)
    return math.floor(num + 0.5)
end

function ColorConverter.rgbToHex(r, g, b)
    r = clamp(round(r), 0, 255)
    g = clamp(round(g), 0, 255)
    b = clamp(round(b), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

function ColorConverter.rgbToColor3(r, g, b)
    return Color3.fromRGB(r, g, b)
end

function ColorConverter.color3ToRgb(color3)
    return round(color3.R * 255), round(color3.G * 255), round(color3.B * 255)
end

function ColorConverter.rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min
    
    local h, s, v = 0, 0, max
    
    if delta > 0 then
        s = delta / max
        
        if max == r then
            h = 60 * (((g - b) / delta) % 6)
        elseif max == g then
            h = 60 * (((b - r) / delta) + 2)
        else
            h = 60 * (((r - g) / delta) + 4)
        end
        
        if h < 0 then h = h + 360 end
    end
    
    return round(h), round(s * 100), round(v * 100)
end

function ColorConverter.hsvToRgb(h, s, v)
    h = h % 360
    s = clamp(s, 0, 100) / 100
    v = clamp(v, 0, 100) / 100
    
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    
    local r, g, b = 0, 0, 0
    
    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    
    r = round((r + m) * 255)
    g = round((g + m) * 255)
    b = round((b + m) * 255)
    
    return r, g, b
end

function ColorConverter.rotateHue(r, g, b, degrees)
    local h, s, v = ColorConverter.rgbToHsv(r, g, b)
    h = (h + degrees) % 360
    return ColorConverter.hsvToRgb(h, s, v)
end

function ColorConverter.getComplementary(r, g, b)
    return ColorConverter.rotateHue(r, g, b, 180)
end

function ColorConverter.adjustBrightness(r, g, b, amount)
    local h, s, v = ColorConverter.rgbToHsv(r, g, b)
    v = clamp(v + amount, 0, 100)
    return ColorConverter.hsvToRgb(h, s, v)
end

function ColorConverter.adjustSaturation(r, g, b, amount)
    local h, s, v = ColorConverter.rgbToHsv(r, g, b)
    s = clamp(s + amount, 0, 100)
    return ColorConverter.hsvToRgb(h, s, v)
end

function ColorConverter.invert(r, g, b)
    return 255 - r, 255 - g, 255 - b
end

function ColorConverter.multiplyBrightness(r, g, b, multiplier)
    multiplier = clamp(multiplier, 0, 2)
    r = clamp(round(r * multiplier), 0, 255)
    g = clamp(round(g * multiplier), 0, 255)
    b = clamp(round(b * multiplier), 0, 255)
    return r, g, b
end

-- ═══════════════════════════════════════════════════════════════
-- 🔥 TAB 1: BLOX FRUITS - MALEVOLENT SHRINE
-- ═══════════════════════════════════════════════════════════════

local BloxFruitsTab = Window:CreateTab("⚔️ Blox Fruits", 4483362458)
local BFSection = BloxFruitsTab:CreateSection("Malevolent Shrine - Cooldown Control")

-- Audio setup
local AUDIO_ID = "rbxassetid://1234567890"
local ShrineSound = Instance.new("Sound")
ShrineSound.Name = "MalevolentShrineSound"
ShrineSound.SoundId = AUDIO_ID
ShrineSound.Volume = 1
ShrineSound.Looped = false
ShrineSound.Parent = SoundService

local ShrineSoundPlaying = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        if not ShrineSoundPlaying then
            ShrineSoundPlaying = true
            ShrineSound:Play()
            ShrineSound.Ended:Connect(function()
                ShrineSoundPlaying = false
            end)
        else
            ShrineSound:Stop()
            ShrineSoundPlaying = false
        end
    end
end)

-- Cooldown variables
local NoTapCooldown = false
local OriginalCooldowns = {}
local CooldownSpeed = 0
local CooldownLoop = nil
local TapCooldownEnabled = false
local TapTargetSeconds = 0

local TapNames = {"tap", "click", "m1", "basic", "attack"}

local function IsTapName(name)
    name = string.lower(name)
    for _, kw in ipairs(TapNames) do
        if string.find(name, kw) then
            return true
        end
    end
    return false
end

local function ModifyCooldowns()
    local character = Player.Character
    if not character then return end

    local allAttributes = character:GetAttributes()
    for attrName, attrValue in pairs(allAttributes) do
        if type(attrName) == "string" and type(attrValue) == "number" then
            local lowerName = string.lower(attrName)
            local isCooldown = lowerName:find("cooldown") or lowerName:find("cool") or lowerName:find("cd")
            local isTap = lowerName:find("tap") or IsTapName(lowerName)

            if isCooldown or isTap then
                if not OriginalCooldowns[attrName] then
                    OriginalCooldowns[attrName] = attrValue
                end

                local newVal = attrValue

                if isCooldown and NoTapCooldown then
                    newVal = (OriginalCooldowns[attrName] * CooldownSpeed) / 100
                end

                if isTap and TapCooldownEnabled then
                    newVal = TapTargetSeconds
                end

                character:SetAttribute(attrName, newVal)
            end
        end
    end

    for _, obj in pairs(character:GetDescendants()) do
        if obj:IsA("NumberValue") or obj:IsA("IntValue") then
            local lowerName = string.lower(obj.Name)
            local isCooldown = lowerName:find("cooldown") or lowerName:find("cool") or lowerName:find("cd")
            local isTap = lowerName:find("tap") or IsTapName(lowerName)

            if isCooldown or isTap then
                local key = obj:GetFullName()
                if not OriginalCooldowns[key] then
                    OriginalCooldowns[key] = obj.Value
                end

                local newVal = obj.Value

                if isCooldown and NoTapCooldown then
                    newVal = (OriginalCooldowns[key] * CooldownSpeed) / 100
                end

                if isTap and TapCooldownEnabled then
                    newVal = TapTargetSeconds
                end

                obj.Value = newVal
            end
        end
    end
end

BloxFruitsTab:CreateToggle({
    Name = "No Fruit Tap Cooldown (All)",
    CurrentValue = false,
    Flag = "NoTapCooldown",
    Callback = function(Value)
        NoTapCooldown = Value
        if NoTapCooldown or TapCooldownEnabled then
            if not CooldownLoop then
                CooldownLoop = RunService.Heartbeat:Connect(function()
                    if NoTapCooldown or TapCooldownEnabled then
                        pcall(ModifyCooldowns)
                    end
                end)
            end
            ModifyCooldowns()
        else
            if CooldownLoop then
                CooldownLoop:Disconnect()
                CooldownLoop = nil
            end
            local character = Player.Character
            if character then
                for attrName, originalValue in pairs(OriginalCooldowns) do
                    if character:GetAttribute(attrName) then
                        character:SetAttribute(attrName, originalValue)
                    end
                end
            end
        end
    end
})

BloxFruitsTab:CreateSlider({
    Name = "Cooldown Speed %",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 0,
    Flag = "CooldownSpeed",
    Callback = function(Value)
        CooldownSpeed = Value
    end
})

BloxFruitsTab:CreateSection("Tap Cooldown Control")

BloxFruitsTab:CreateToggle({
    Name = "Override Tap Cooldowns Only",
    CurrentValue = false,
    Flag = "TapCooldownOnly",
    Callback = function(Value)
        TapCooldownEnabled = Value
        if TapCooldownEnabled or NoTapCooldown then
            if not CooldownLoop then
                CooldownLoop = RunService.Heartbeat:Connect(function()
                    if NoTapCooldown or TapCooldownEnabled then
                        pcall(ModifyCooldowns)
                    end
                end)
            end
            ModifyCooldowns()
        end
    end
})

BloxFruitsTab:CreateSlider({
    Name = "Tap Cooldown (seconds)",
    Range = {0, 5},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0,
    Flag = "TapCooldownSeconds",
    Callback = function(Value)
        TapTargetSeconds = Value
    end
})

BloxFruitsTab:CreateButton({
    Name = "Reset All Cooldowns Now",
    Callback = function()
        pcall(function()
            local character = Player.Character
            if character then
                for attrName, attrValue in pairs(character:GetAttributes()) do
                    if type(attrValue) == "number" then
                        local lowerName = string.lower(attrName)
                        if lowerName:find("cooldown") or lowerName:find("cool") or lowerName:find("cd") or lowerName:find("tap") then
                            character:SetAttribute(attrName, 0)
                        end
                    end
                end
            end
        end)
    end
})

BloxFruitsTab:CreateParagraph({
    Title = "Audio Control",
    Content = "Press M to play/stop Malevolent Shrine audio. Upload your audio ID in the script!"
})

print("✅ PART 2 LOADED - COLOR TOOLS & BLOX FRUITS!")
-- ═══════════════════════════════════════════════════════════════
-- ⛩️ TAB 2: MALEVOLENT SHRINE DOMAIN EXPANSION (FULL VERSION)
-- ═══════════════════════════════════════════════════════════════

local ShrineTab = Window:CreateTab("⛩️ Red Shrine", 4483362458)

-- Settings
local DomainActive = false
local DomainSize = 1500
local SlashRange = 500
local DomainDuration = 15
local SlashesPerSecond = 8
local SlashDamage = 15
local SlashDuration = 6
local PlayCinematic = true
local ShowRedFog = true
local EnableRedTinting = true
local UseKillAura = true
local AutoDisableOnDeath = true
local SpawnOnShrine = false
local TargetedPlayer = nil
local KillAuraRange = 2000

-- Storage
local DomainParts = {}
local PersistentSlashes = {}
local CurrentShrine = nil
local ResetConnection = nil
local DeathConnection = nil
local TintedParts = {}
local OriginalColors = {}
local KillAuraActive = false
local KillAuraConnection = nil
local CameraFixLoop = nil

-- Original lighting values
local OriginalFogColor = Lighting.FogColor
local OriginalFogEnd = Lighting.FogEnd
local OriginalFogStart = Lighting.FogStart
local OriginalAmbient = Lighting.Ambient
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient
local OriginalBrightness = Lighting.Brightness
local OriginalClockTime = Lighting.ClockTime

-- OST (TWO SOUNDS - INTRO THEN MAIN)
local IntroSound = Instance.new("Sound")
IntroSound.Name = "DomainIntroSound"
IntroSound.SoundId = "rbxassetid://85929440442310"
IntroSound.Volume = 1
IntroSound.Looped = false
IntroSound.Parent = SoundService

local SukunaOST = Instance.new("Sound")
SukunaOST.Name = "SukunaOST"
SukunaOST.SoundId = "rbxassetid://106240568414882"
SukunaOST.Volume = 0.8
SukunaOST.Looped = false
SukunaOST.Parent = SoundService

-- ENHANCED SLASH COLOR SYSTEM - NEON WHITE OR NEON RED WITH BLACK CENTER
local function GetEnhancedSlashColors()
    local useRed = math.random(1, 2) == 1
    
    local centerColor = Color3.fromRGB(0, 0, 0) -- Black center
    local edgeColor
    
    if useRed then
        -- NEON Very Bright Red
        edgeColor = Color3.fromRGB(255, 0, 0)
    else
        -- NEON Very Bright White
        edgeColor = Color3.fromRGB(255, 255, 255)
    end
    
    return centerColor, edgeColor
end

-- 🗡️ ENHANCED KILL AURA FUNCTION (HIDDEN GUI VERSION)
local function ActivateEnhancedKillAura()
    if KillAuraActive then return end
    
    if not UseKillAura then 
        print("⚠️ Kill Aura disabled by user")
        return 
    end
    
    print("🗡️ Activating Enhanced Kill Aura...")
    KillAuraActive = true
    
    local success, Net = pcall(function()
        return ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
    end)
    
    if success and Net then
        local RegisterHit = Net:FindFirstChild("RE/RegisterHit")
        local RegisterAttack = Net:FindFirstChild("RE/RegisterAttack")
        
        if RegisterHit and RegisterAttack then
            KillAuraConnection = task.spawn(function()
                while KillAuraActive and DomainActive do
                    task.wait(0.01)
                    
                    local myChar = Player.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myHRP then continue end
                    
                    local targetsInRange = {}
                    
                    if TargetedPlayer and TargetedPlayer.Character then
                        local targetHRP = TargetedPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local targetHumanoid = TargetedPlayer.Character:FindFirstChild("Humanoid")
                        
                        if targetHRP and targetHumanoid and targetHumanoid.Health > 0 then
                            local dist = (targetHRP.Position - myHRP.Position).Magnitude
                            if dist <= KillAuraRange then
                                table.insert(targetsInRange, TargetedPlayer.Character)
                            end
                        end
                    else
                        local enemiesFolder = workspace:FindFirstChild("Enemies")
                        if enemiesFolder then
                            for _, npc in pairs(enemiesFolder:GetChildren()) do
                                local humanoid = npc:FindFirstChild("Humanoid")
                                local hrp = npc:FindFirstChild("HumanoidRootPart")
                                
                                if humanoid and hrp and humanoid.Health > 0 then
                                    local dist = (hrp.Position - myHRP.Position).Magnitude
                                    if dist <= KillAuraRange then
                                        table.insert(targetsInRange, npc)
                                    end
                                end
                            end
                        end
                        
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= Player and player.Character then
                                local humanoid = player.Character:FindFirstChild("Humanoid")
                                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                                
                                if humanoid and hrp and humanoid.Health > 0 then
                                    local dist = (hrp.Position - myHRP.Position).Magnitude
                                    if dist <= KillAuraRange then
                                        table.insert(targetsInRange, player.Character)
                                    end
                                end
                            end
                        end
                    end
                    
                    if #targetsInRange > 0 then
                        local allTargets = {}
                        
                        for _, targetChar in pairs(targetsInRange) do
                            local head = targetChar:FindFirstChild("Head")
                            if head then
                                table.insert(allTargets, {targetChar, head})
                            end
                        end
                        
                        if #allTargets > 0 then
                            pcall(function()
                                local attackArgs = {0}
                                RegisterAttack:FireServer(unpack(attackArgs))
                                
                                local hitArgs = {
                                    allTargets[1][2],
                                    allTargets
                                }
                                RegisterHit:FireServer(unpack(hitArgs))
                            end)
                        end
                    end
                end
            end)
            print("✅ Enhanced Kill Aura activated!")
        else
            warn("⚠️ RegisterHit/RegisterAttack not found")
            KillAuraActive = false
        end
    else
        warn("⚠️ Net module not found, using fallback")
        KillAuraConnection = task.spawn(function()
            while KillAuraActive and DomainActive do
                task.wait(0.1)
                
                local myChar = Player.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHRP then continue end
                
                if TargetedPlayer and TargetedPlayer.Character then
                    local targetHumanoid = TargetedPlayer.Character:FindFirstChild("Humanoid")
                    local targetHRP = TargetedPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetHumanoid and targetHRP and targetHumanoid.Health > 0 then
                        local dist = (targetHRP.Position - myHRP.Position).Magnitude
                        if dist <= KillAuraRange then
                            pcall(function()
                                targetHumanoid:TakeDamage(SlashDamage)
                            end)
                        end
                    end
                end
            end
        end)
    end
end

-- 🗡️ ENHANCED VISIBLE SLASH SYSTEM
local function CreateVisibleSlash(startPos, endPos)
    local distance = (endPos - startPos).Magnitude
    
    local holder = Instance.new("Part")
    holder.Name = "EnhancedSlash"
    holder.Size = Vector3.new(0.1, 0.1, distance)
    holder.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
    holder.Anchored = true
    holder.CanCollide = false
    holder.Transparency = 1
    holder.Parent = workspace

    local att0 = Instance.new("Attachment", holder)
    att0.Position = Vector3.new(0, 0, -distance / 2)
    
    local att1 = Instance.new("Attachment", holder)
    att1.Position = Vector3.new(0, 0, distance / 2)

    local beam = Instance.new("Beam", holder)
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = 4
    beam.Width1 = 4
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.TextureMode = Enum.TextureMode.Stretch
    beam.Texture = "rbxassetid://241650934"
    beam.TextureLength = 1.5
    beam.TextureSpeed = 2
    beam.Brightness = 5

    local centerColor, edgeColor = GetEnhancedSlashColors()
    
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, edgeColor),
        ColorSequenceKeypoint.new(0.5, centerColor),
        ColorSequenceKeypoint.new(1, edgeColor),
    })
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.2)
    })

    local glow = Instance.new("PointLight", holder)
    glow.Color = edgeColor
    glow.Brightness = 6
    glow.Range = 30

    table.insert(PersistentSlashes, holder)

    local hitPlayers = {}
    task.spawn(function()
        local checkDuration = 0.5
        local startTime = tick()
        
        while tick() - startTime < checkDuration and holder.Parent do
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character and not hitPlayers[plr] then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local humanoid = plr.Character:FindFirstChild("Humanoid")
                    
                    if hrp and humanoid and humanoid.Health > 0 then
                        local slashCenter = (startPos + endPos) / 2
                        local distToSlash = (hrp.Position - slashCenter).Magnitude
                        
                        if distToSlash <= distance / 2 + 10 then
                            hitPlayers[plr] = true
                            
                            if UseKillAura and not KillAuraActive then
                                TargetedPlayer = plr
                                ActivateEnhancedKillAura()
                            end
                            
                            local hitEffect = Instance.new("Part")
                            hitEffect.Shape = Enum.PartType.Ball
                            hitEffect.Size = Vector3.new(5, 5, 5)
                            hitEffect.Position = hrp.Position
                            hitEffect.Anchored = true
                            hitEffect.CanCollide = false
                            hitEffect.Material = Enum.Material.Neon
                            hitEffect.Color = edgeColor
                            hitEffect.Transparency = 0.3
                            hitEffect.Parent = workspace
                            
                            TweenService:Create(hitEffect, TweenInfo.new(0.3), {
                                Size = Vector3.new(10, 10, 10),
                                Transparency = 1
                            }):Play()
                            
                            Debris:AddItem(hitEffect, 0.5)
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)

    task.delay(SlashDuration, function()
        if holder and holder.Parent then
            local tween = TweenService:Create(beam, 
                TweenInfo.new(1), 
                {Transparency = NumberSequence.new(1)}
            )
            tween:Play()
            task.wait(1)
            holder:Destroy()
        end
    end)
end

-- 🌍 FIXED RED TINTING SYSTEM
local function ApplyRedTint(part)
    if not EnableRedTinting then return end
    if part:IsA("BasePart") and not part:IsDescendantOf(CurrentShrine) then
        if not OriginalColors[part] then
            OriginalColors[part] = part.Color
        end
        
        local originalColor = OriginalColors[part]
        local tintedColor = Color3.new(
            math.min(1, originalColor.R + 0.3),
            originalColor.G * 0.3,
            originalColor.B * 0.3
        )
        part.Color = tintedColor
        table.insert(TintedParts, part)
    end
end

local function TintNearbyObjects(center, radius)
    if not EnableRedTinting then return end
    
    local region = Region3.new(
        center - Vector3.new(radius, radius, radius),
        center + Vector3.new(radius, radius, radius)
    )
    region = region:ExpandToGrid(4)
    
    for _, part in pairs(workspace:GetPartBoundsInBox(CFrame.new(center), Vector3.new(radius * 2, radius * 2, radius * 2))) do
        ApplyRedTint(part)
    end
end

local function RestoreOriginalColors()
    print("🎨 Restoring original colors...")
    local restoredCount = 0
    
    for _, part in ipairs(TintedParts) do
        if part and part.Parent and OriginalColors[part] then
            pcall(function()
                part.Color = OriginalColors[part]
                restoredCount = restoredCount + 1
            end)
        end
    end
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(CurrentShrine or workspace) then
            if OriginalColors[part] then
                pcall(function()
                    part.Color = OriginalColors[part]
                    restoredCount = restoredCount + 1
                end)
            end
        end
    end
    
    table.clear(TintedParts)
    table.clear(OriginalColors)
    
    print("✅ Restored " .. restoredCount .. " part colors")
end

-- 🏛️ GROUND-LEVEL SHRINE
local function CreateGroundShrine(centerPos)
    print("📥 Creating ground-level RED shrine...")
    
    if CurrentShrine then
        CurrentShrine:Destroy()
        CurrentShrine = nil
    end
    
    local shrineModel = Instance.new("Model")
    shrineModel.Name = "RedMalevolentShrine_Ground"
    shrineModel.Parent = workspace
    CurrentShrine = shrineModel
    
    local ray = Ray.new(centerPos, Vector3.new(0, -1000, 0))
    local hit, position = workspace:FindPartOnRay(ray, Player.Character)
    local groundY = position.Y
    
    local platform = Instance.new("Part")
    platform.Name = "ShrinePlatform"
    platform.Size = Vector3.new(200, 2, 200)
    platform.Position = Vector3.new(centerPos.X, groundY + 1, centerPos.Z)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.Marble
    platform.Color = Color3.fromRGB(100, 10, 10)
    platform.Parent = shrineModel
    
    local success, model = pcall(function()
        return game:GetObjects("rbxassetid://16639433873")[1]
    end)
    
    local shrineHeight = 35
    local shrineTopY = groundY + 40
    
    if success and model then
        model.Parent = shrineModel
        model:ScaleTo(4)
        model:MoveTo(Vector3.new(centerPos.X, groundY - 35, centerPos.Z))
        
        local partData = {}
        for _, part in pairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                local offset = part.Position - Vector3.new(centerPos.X, groundY - 35, centerPos.Z)
                partData[part] = {
                    offset = offset,
                    targetY = groundY + 18 + offset.Y
                }
                
                local glow = Instance.new("PointLight", part)
                glow.Color = Color3.fromRGB(255, 0, 0)
                glow.Brightness = 3
                glow.Range = 40
            end
        end
        
        shrineHeight = 35
        shrineTopY = groundY + 58
        
        task.spawn(function()
            task.wait(0.1)
            for part, data in pairs(partData) do
                if part and part.Parent then
                    local targetPos = Vector3.new(part.Position.X, data.targetY, part.Position.Z)
                    TweenService:Create(part, 
                        TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                        {Position = targetPos}
                    ):Play()
                end
            end
        end)
    else
        local shrineBody = Instance.new("Part", shrineModel)
        shrineBody.Name = "ShrineBody"
        shrineBody.Size = Vector3.new(48, 40, 40)
        shrineBody.Position = Vector3.new(centerPos.X, groundY - 35, centerPos.Z)
        shrineBody.Anchored = true
        shrineBody.CanCollide = false
        shrineBody.Material = Enum.Material.Marble
        shrineBody.Color = Color3.fromRGB(80, 10, 10)
        shrineBody.Transparency = 0.1
        
        local roof = Instance.new("Part", shrineModel)
        roof.Name = "ShrineRoof"
        roof.Size = Vector3.new(62, 4, 62)
        roof.Position = Vector3.new(centerPos.X, groundY - 15, centerPos.Z)
        roof.Anchored = true
        roof.CanCollide = false
        roof.Material = Enum.Material.Neon
        roof.Color = Color3.fromRGB(255, 20, 20)
        roof.Transparency = 0.2
        
        shrineHeight = 38
        shrineTopY = groundY + 55
        
        task.spawn(function()
            task.wait(0.1)
            TweenService:Create(shrineBody, 
                TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                {Position = Vector3.new(centerPos.X, groundY + 15, centerPos.Z)}
            ):Play()
            
            TweenService:Create(roof, 
                TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                {Position = Vector3.new(centerPos.X, groundY + 35, centerPos.Z)}
            ):Play()
        end)
    end
    
    local aura = Instance.new("Part", shrineModel)
    aura.Name = "RedAura"
    aura.Shape = Enum.PartType.Ball
    aura.Size = Vector3.new(24, 24, 24)
    aura.Position = Vector3.new(centerPos.X, groundY - 20, centerPos.Z)
    aura.Anchored = true
    aura.CanCollide = false
    aura.Material = Enum.Material.Neon
    aura.Color = Color3.fromRGB(255, 0, 0)
    aura.Transparency = 0.3
    
    task.spawn(function()
        task.wait(0.1)
        TweenService:Create(aura, 
            TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {Position = Vector3.new(centerPos.X, shrineTopY, centerPos.Z)}
        ):Play()
        
        task.wait(2.5)
        
        local gui = Instance.new("ScreenGui", Player.PlayerGui)
        gui.Name = "MalevolentShrineText"
        
        local shrineText = Instance.new("TextLabel", gui)
        shrineText.Size = UDim2.new(0.8, 0, 0.2, 0)
        shrineText.Position = UDim2.new(0.1, 0, 0.4, 0)
        shrineText.BackgroundTransparency = 1
        shrineText.Font = Enum.Font.GothamBold
        shrineText.TextSize = 70
        shrineText.TextColor3 = Color3.fromRGB(255, 0, 0)
        shrineText.TextStrokeTransparency = 0.3
        shrineText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        shrineText.Text = "Malevolent Shrine"
        shrineText.TextTransparency = 1
        shrineText.ZIndex = 101
        
        TweenService:Create(shrineText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        
        task.wait(3)
        
        TweenService:Create(shrineText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        task.wait(0.5)
        gui:Destroy()
        
        while aura.Parent and DomainActive do
            TweenService:Create(aura, TweenInfo.new(1), {
                Size = Vector3.new(30, 30, 30), 
                Transparency = 0.1
            }):Play()
            task.wait(1)
            TweenService:Create(aura, TweenInfo.new(1), {
                Size = Vector3.new(24, 24, 24), 
                Transparency = 0.3
            }):Play()
            task.wait(1)
        end
    end)
    
    table.insert(DomainParts, shrineModel)
    
    print("✅ Shrine rising from ground!")
    
    return Vector3.new(centerPos.X, shrineTopY, centerPos.Z)
end

-- 🌫️ RED DARK FOG
local FogPulseConnection = nil

local function CreateRedFog()
    if not ShowRedFog then return end
    
    Lighting.FogColor = Color3.fromRGB(120, 10, 10)
    Lighting.FogStart = 0
    Lighting.FogEnd = 200
    Lighting.Ambient = Color3.fromRGB(80, 5, 5)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 10, 10)
    Lighting.Brightness = 1
    Lighting.ClockTime = 0
    Lighting.GlobalShadows = true
    
    local atmosphere = Lighting:FindFirstChild("DomainAtmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere", Lighting)
        atmosphere.Name = "DomainAtmosphere"
    end
    atmosphere.Density = 0.4
    atmosphere.Offset = 0.5
    atmosphere.Color = Color3.fromRGB(150, 20, 20)
    atmosphere.Decay = Color3.fromRGB(100, 10, 10)
    atmosphere.Glare = 0.2
    atmosphere.Haze = 2
    
    local pulseTime = 0
    FogPulseConnection = RunService.RenderStepped:Connect(function(dt)
        if not DomainActive then
            if FogPulseConnection then
                FogPulseConnection:Disconnect()
                FogPulseConnection = nil
            end
            return
        end
        
        pulseTime = pulseTime + dt
        local pulse = math.sin(pulseTime * 0.5) * 25 + 175
        Lighting.FogEnd = pulse
        Lighting.Brightness = 0.9 + math.sin(pulseTime * 0.5) * 0.2
    end)
end

local function RestoreLighting()
    if FogPulseConnection then
        FogPulseConnection:Disconnect()
        FogPulseConnection = nil
    end
    
    local atmosphere = Lighting:FindFirstChild("DomainAtmosphere")
    if atmosphere then
        atmosphere:Destroy()
    end
    
    task.wait()
    
    Lighting.FogColor = OriginalFogColor
    Lighting.FogStart = OriginalFogStart
    Lighting.FogEnd = OriginalFogEnd
    Lighting.Ambient = OriginalAmbient
    Lighting.OutdoorAmbient = OriginalOutdoorAmbient
    Lighting.Brightness = OriginalBrightness
    Lighting.ClockTime = OriginalClockTime
    Lighting.GlobalShadows = true
    
    task.wait(0.1)
    local atmosphere2 = Lighting:FindFirstChild("DomainAtmosphere")
    if atmosphere2 then
        atmosphere2:Destroy()
    end
    
    print("✅ Fog and lighting fully restored!")
end

-- 🗡️ SLASH GENERATION
local function GenerateSlashes(center, count)
    for i = 1, count do
        local angle1 = math.rad(math.random(0, 360))
        local angle2 = math.rad(math.random(0, 360))
        local dist1 = math.random(20, SlashRange)
        local dist2 = math.random(20, SlashRange)
        
        local pos1 = center + Vector3.new(
            math.cos(angle1) * dist1,
            math.random(-SlashRange/3, SlashRange/3),
            math.sin(angle1) * dist1
        )
        
        local pos2 = center + Vector3.new(
            math.cos(angle2) * dist2,
            math.random(-SlashRange/3, SlashRange/3),
            math.sin(angle2) * dist2
        )
        
        CreateVisibleSlash(pos1, pos2)
        
        if i % 5 == 0 then
            task.wait()
        end
    end
end

-- 💀 AGGRESSIVE DEATH HANDLER
local function SetupDeathHandler()
    if DeathConnection then
        DeathConnection:Disconnect()
        DeathConnection = nil
    end
    
    local character = Player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    DeathConnection = humanoid.Died:Connect(function()
        print("💀 Player died - FORCING domain close and camera fix!")
        
        DomainActive = false
        KillAuraActive = false
        TargetedPlayer = nil
        
        if KillAuraConnection then
            task.cancel(KillAuraConnection)
            KillAuraConnection = nil
        end
        
        if ResetConnection then 
            ResetConnection:Disconnect() 
            ResetConnection = nil
        end
        
        IntroSound:Stop()
        SukunaOST:Stop()
        
        if CameraFixLoop then
            CameraFixLoop:Disconnect()
        end
        
        CameraFixLoop = RunService.RenderStepped:Connect(function()
            Camera.CameraType = Enum.CameraType.Custom
            Camera.FieldOfView = 70
            
            local char = Player.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    Camera.CameraSubject = hum
                end
            end
        end)
        
        task.delay(5, function()
            if CameraFixLoop then
                CameraFixLoop:Disconnect()
                CameraFixLoop = nil
            end
        end)
        
        task.spawn(RestoreLighting)
        task.spawn(RestoreOriginalColors)
        
        task.spawn(function()
            for _, obj in pairs(DomainParts) do 
                pcall(function()
                    if obj and obj.Parent then 
                        obj:Destroy() 
                    end
                end)
            end
            
            for _, slash in pairs(PersistentSlashes) do 
                pcall(function()
                    if slash and slash.Parent then 
                        slash:Destroy() 
                    end
                end)
            end
            
            if CurrentShrine then 
                pcall(function()
                    CurrentShrine:Destroy()
                end)
                CurrentShrine = nil
            end
            
            table.clear(DomainParts)
            table.clear(PersistentSlashes)
        end)
        
        print("✅ Death cleanup complete!")
    end)
end

-- 🔄 RESET PROTECTION
local function SetupResetProtection(shrineCenter)
    if ResetConnection then 
        ResetConnection:Disconnect() 
    end
    
    ResetConnection = Player.CharacterAdded:Connect(function()
        if DomainActive then
            task.wait(0.2)
            local character = Player.Character
            if not character then return end
            
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            if hrp and shrineCenter then
                hrp.CFrame = CFrame.new(shrineCenter + Vector3.new(0, 5, 0))
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
            end
            
            SetupDeathHandler()
        end
    end)
end

-- ⛩️ MAIN ACTIVATION
local function ActivateDomain()
    if DomainActive then
        print("⚠️ Domain already active")
        return
    end
    
    print("🔥 Starting domain activation...")
    
    if KillAuraConnection then
        task.cancel(KillAuraConnection)
        KillAuraConnection = nil
    end
    
    if ResetConnection then 
        ResetConnection:Disconnect() 
        ResetConnection = nil
    end
    
    if DeathConnection then
        DeathConnection:Disconnect()
        DeathConnection = nil
    end
    
    if CameraFixLoop then
        CameraFixLoop:Disconnect()
        CameraFixLoop = nil
    end
    
    if FogPulseConnection then
        FogPulseConnection:Disconnect()
        FogPulseConnection = nil
    end
    
    IntroSound:Stop()
    SukunaOST:Stop()
    
    if CurrentShrine then
        CurrentShrine:Destroy()
        CurrentShrine = nil
    end
    
    for _, obj in pairs(DomainParts) do 
        if obj and obj.Parent then 
            obj:Destroy() 
        end 
    end
    table.clear(DomainParts)
    
    for _, slash in pairs(PersistentSlashes) do 
        if slash and slash.Parent then 
            slash:Destroy() 
        end 
    end
    table.clear(PersistentSlashes)
    
    RestoreOriginalColors()
    RestoreLighting()
    
    task.wait(0.2)
    
    DomainActive = true
    KillAuraActive = false
    TargetedPlayer = nil
    
    local character = Player.Character
    if not character then 
        print("❌ No character found")
        DomainActive = false
        return 
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        print("❌ No HumanoidRootPart found")
        DomainActive = false
        return 
    end
    
    SetupDeathHandler()
    
    local playerPos = hrp.Position
    local playerLookVector = hrp.CFrame.LookVector
    
    local shrinePositionBehind = playerPos - (playerLookVector * 150)
    
    IntroSound:Play()
    local activationSound = Instance.new("Sound", SoundService)
    activationSound.SoundId = "rbxassetid://5567523008"
    activationSound.Volume = 1.2
    activationSound:Play()
    Debris:AddItem(activationSound, 3)
    
    task.spawn(function()
        task.wait(IntroSound.TimeLength > 0 and IntroSound.TimeLength or 3)
        if DomainActive then
            SukunaOST:Play()
        end
    end)
    
    local shrineTopPosition
    
    if PlayCinematic then
        local character = Player.Character
        if character then
            local gui = Instance.new("ScreenGui", Player.PlayerGui)
            gui.Name = "CinematicGUI"
            
            local flash = Instance.new("Frame", gui)
            flash.Size = UDim2.new(1, 0, 1, 0)
            flash.BackgroundColor3 = Color3.new(0, 0, 0)
            flash.BackgroundTransparency = 0
            flash.ZIndex = 100
            
            local domainText = Instance.new("TextLabel", gui)
            domainText.Size = UDim2.new(0.8, 0, 0.2, 0)
            domainText.Position = UDim2.new(0.1, 0, 0.4, 0)
            domainText.BackgroundTransparency = 1
            domainText.Font = Enum.Font.GothamBold
            domainText.TextSize = 60
            domainText.TextColor3 = Color3.fromRGB(255, 255, 255)
            domainText.TextStrokeTransparency = 0.5
            domainText.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
            domainText.Text = "Domain Expansion"
            domainText.TextTransparency = 1
            domainText.ZIndex = 101
            
            TweenService:Create(flash, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(domainText, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
            
            task.wait(1.5)
            
            TweenService:Create(domainText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            
            task.wait(0.5)
            
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.lookAt(playerPos + Vector3.new(0, 5, 10), playerPos)
            
            task.spawn(function()
                shrineTopPosition = CreateGroundShrine(shrinePositionBehind)
            end)
            
            local targetCam = CFrame.lookAt(shrinePositionBehind + Vector3.new(0, 30, 60), shrinePositionBehind)
            local camTween = TweenService:Create(Camera, TweenInfo.new(2.5, Enum.EasingStyle.Sine), {CFrame = targetCam})
            camTween:Play()
            
            task.wait(2.5)
            
            ForceResetCamera()
            
            domainText:Destroy()
            flash:Destroy()
            gui:Destroy()
        end
    else
        task.wait(0.5)
        shrineTopPosition = CreateGroundShrine(shrinePositionBehind)
    end
    
    task.wait(2.8)
    
    if SpawnOnShrine and shrineTopPosition then
        local teleportHeight = shrineTopPosition.Y + 20
        hrp.CFrame = CFrame.new(shrineTopPosition.X, teleportHeight, shrineTopPosition.Z)
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
        
        print("✅ Teleported player above shrine!")
    end
    
    if UseKillAura then
        ActivateEnhancedKillAura()
    end
    
    local shrineCenter = shrineTopPosition or (shrinePositionBehind + Vector3.new(0, 40, 0))
    
    SetupResetProtection(shrineCenter)
    
    task.wait(0.1)
    GenerateSlashes(shrineCenter, 15)
    CreateRedFog()
    TintNearbyObjects(shrineCenter, DomainSize)
    
    task.spawn(function()
        local startTime = tick()
        local lastSlashTime = tick()
        
        local trackedEnemies = {}
        
        while DomainActive and (tick() - startTime) < DomainDuration do
            if tick() - lastSlashTime >= 1 then
                GenerateSlashes(shrineCenter, SlashesPerSecond)
                lastSlashTime = tick()
            end
            
            if AutoDisableOnDeath and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                local myPos = Player.Character.HumanoidRootPart.Position
                
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= Player and plr.Character then
                        local enemyHrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        local enemyHumanoid = plr.Character:FindFirstChild("Humanoid")
                        
                        if enemyHrp and enemyHumanoid then
                            local distance = (myPos - enemyHrp.Position).Magnitude
                            
                            if distance <= 5000 then
                                if not trackedEnemies[plr.UserId] then
                                    trackedEnemies[plr.UserId] = {
                                        player = plr,
                                        wasAlive = enemyHumanoid.Health > 0
                                    }
                                else
                                    if trackedEnemies[plr.UserId].wasAlive and enemyHumanoid.Health <= 0 then
                                        print("💀 Enemy died - Auto-closing domain")
                                        DomainActive = false
                                        break
                                    end
                                    trackedEnemies[plr.UserId].wasAlive = enemyHumanoid.Health > 0
                                end
                            end
                        end
                    end
                end
            end
            
            task.wait(0.1)
        end
        
        print("⏰ Domain duration ended")
        DomainActive = false
        KillAuraActive = false
        TargetedPlayer = nil
        
        if KillAuraConnection then
            task.cancel(KillAuraConnection)
            KillAuraConnection = nil
        end
        
        if ResetConnection then 
            ResetConnection:Disconnect() 
            ResetConnection = nil
        end
        
        if DeathConnection then
            DeathConnection:Disconnect()
            DeathConnection = nil
        end
        
        if CameraFixLoop then
            CameraFixLoop:Disconnect()
            CameraFixLoop = nil
        end
        
        IntroSound:Stop()
        SukunaOST:Stop()
        
        ForceResetCamera()
        RestoreLighting()
        RestoreOriginalColors()
        
        task.wait(0.1)
        
        for _, obj in pairs(DomainParts) do 
            if obj and obj.Parent then 
                obj:Destroy() 
            end 
        end
        
        for _, slash in pairs(PersistentSlashes) do 
            if slash and slash.Parent then 
                slash:Destroy() 
            end 
        end
        
        if CurrentShrine then 
            CurrentShrine:Destroy() 
            CurrentShrine = nil 
        end
        
        table.clear(DomainParts)
        table.clear(PersistentSlashes)
        
        print("✅ Domain cleanup complete!")
    end)
end

-- 🛑 FORCE CLOSE
local function ForceClose()
    print("🛑 Force closing domain...")
    DomainActive = false
    KillAuraActive = false
    TargetedPlayer = nil
    
    if KillAuraConnection then
        task.cancel(KillAuraConnection)
        KillAuraConnection = nil
    end
    
    if ResetConnection then 
        ResetConnection:Disconnect() 
        ResetConnection = nil
    end
    
    if DeathConnection then
        DeathConnection:Disconnect()
        DeathConnection = nil
    end
    
    if CameraFixLoop then
        CameraFixLoop:Disconnect()
        CameraFixLoop = nil
    end
    
    if FogPulseConnection then
        FogPulseConnection:Disconnect()
        FogPulseConnection = nil
    end
    
    IntroSound:Stop()
    SukunaOST:Stop()
    
    ForceResetCamera()
    RestoreLighting()
    RestoreOriginalColors()
    
    task.wait(0.1)
    
    for _, obj in pairs(DomainParts) do 
        pcall(function()
            if obj and obj.Parent then 
                obj:Destroy() 
            end
        end)
    end
    
    for _, slash in pairs(PersistentSlashes) do 
        pcall(function()
            if slash and slash.Parent then 
                slash:Destroy() 
            end
        end)
    end
    
    if CurrentShrine then 
        pcall(function()
            CurrentShrine:Destroy()
        end)
        CurrentShrine = nil
    end
    
    table.clear(DomainParts)
    table.clear(PersistentSlashes)
    
    print("✅ Force close complete!")
end

-- ⚙️ UI SETUP FOR MALEVOLENT SHRINE
ShrineTab:CreateSection("🔥 DOMAIN EXPANSION")

ShrineTab:CreateButton({
    Name = "⛩️ ACTIVATE MALEVOLENT SHRINE", 
    Callback = ActivateDomain
})

ShrineTab:CreateSection("⚙️ Domain Settings")

ShrineTab:CreateSlider({
    Name = "Domain Size", 
    Range = {200, 3000},
    Increment = 100, 
    Suffix = " studs", 
    CurrentValue = 1500,
    Callback = function(v) DomainSize = v end
})

ShrineTab:CreateSlider({
    Name = "Slash Range", 
    Range = {50, 1000},
    Increment = 50, 
    Suffix = " studs", 
    CurrentValue = 500,
    Callback = function(v) SlashRange = v end
})

ShrineTab:CreateSlider({
    Name = "Duration", 
    Range = {5, 60}, 
    Increment = 5, 
    Suffix = " seconds", 
    CurrentValue = 15, 
    Callback = function(v) DomainDuration = v end
})

ShrineTab:CreateSlider({
    Name = "Slashes Per Second", 
    Range = {3, 20}, 
    Increment = 1, 
    Suffix = " slashes", 
    CurrentValue = 8, 
    Callback = function(v) SlashesPerSecond = v end
})

ShrineTab:CreateSection("📍 Spawn Position")

ShrineTab:CreateToggle({
    Name = "Spawn on Top of Shrine", 
    CurrentValue = false,
    Flag = "SpawnOnShrine",
    Callback = function(v) 
        SpawnOnShrine = v 
    end
})

ShrineTab:CreateSection("🎭 Mahoraga Besto Friendo Skin")

ShrineTab:CreateSlider({
    Name = "Mahoraga Height Offset",
    Range = {-5, 10},
    Increment = 0.5,
    Suffix = " studs",
    CurrentValue = 3,
    Flag = "MahoragaHeight",
    Callback = function(Value)
        MahoragaHeightOffset = Value
        
        for character, skinData in pairs(ActiveMahoragaSkins) do
            if skinData and skinData.model then
                for _, part in pairs(skinData.model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local weld = part:FindFirstChildOfClass("Weld")
                        if weld then
                            weld.C0 = CFrame.new(0, MahoragaHeightOffset, 0)
                        end
                    end
                end
            end
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Enable Mahoraga Skin for Besto Friendo",
    CurrentValue = false,
    Flag = "MahoragaSkin",
    Callback = function(Value)
        MahoragaSkinEnabled = Value
        
        if MahoragaSkinEnabled then
            LoadMahoragaModel()
            StartMahoragaMonitor()
            print("✅ Mahoraga skin enabled!")
            Rayfield:Notify({
                Title = "Mahoraga Skin Enabled",
                Content = "Besto Friendo NPCs will now use Mahoraga skin!",
                Duration = 3,
                Image = 4483362458,
            })
        else
            StopMahoragaMonitor()
            print("❌ Mahoraga skin disabled")
        end
    end
})

ShrineTab:CreateButton({
    Name = "🔍 Scan for NPCs Now",
    Callback = function()
        print("🔍 Scanning workspace for NPCs...")
        local count = 0
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                local isPlayer = false
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr.Character == obj then
                        isPlayer = true
                        break
                    end
                end
                
                if not isPlayer then
                    count = count + 1
                    print(count .. ". NPC Found:", obj.Name)
                    
                    if MahoragaSkinEnabled and IsBestoFriendoNPC(obj) then
                        ApplyMahoragaSkin(obj)
                    end
                end
            end
        end
        
        Rayfield:Notify({
            Title = "NPC Scan Complete",
            Content = "Found " .. count .. " NPCs in workspace",
            Duration = 3,
            Image = 4483362458,
        })
    end
})

ShrineTab:CreateParagraph({
    Title = "🎭 Mahoraga Skin Info",
    Content = "✅ VISIBLE & CAN MOVE! When enabled, Besto Friendo NPCs get Mahoraga skin (3x size). Sword hidden in chest. 🔊 Plays spawn audio!"
})

ShrineTab:CreateButton({
    Name = "🔄 Reload Mahoraga Model",
    Callback = function()
        MahoragaModel = nil
        LoadMahoragaModel()
        Rayfield:Notify({
            Title = "Model Reloaded",
            Content = "Mahoraga model has been reloaded",
            Duration = 2,
            Image = 4483362458,
        })
    end
})

-- NEW: PLAYER MAHORAGA TRANSFORMATION SECTION
ShrineTab:CreateSection("👥 Transform Player to Mahoraga")

local function refreshPlayerList()
    local playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(playerNames, p.Name)
    end
    return playerNames
end

local PlayerMahoragaDropdown = ShrineTab:CreateDropdown({
    Name = "Select Player to Transform",
    Options = refreshPlayerList(),
    CurrentOption = {Player.Name},
    MultipleOptions = false,
    Flag = "PlayerMahoragaSelect",
    Callback = function(Option)
        local targetPlayer = Players:FindFirstChild(Option[1])
        if targetPlayer then
            SelectedPlayerForMahoraga = targetPlayer
            print("🎯 Selected player for Mahoraga:", targetPlayer.Name)
        end
    end,
})

ShrineTab:CreateButton({
    Name = "🔄 Refresh Player List",
    Callback = function()
        if PlayerMahoragaDropdown then
            PlayerMahoragaDropdown:Refresh(refreshPlayerList())
            Rayfield:Notify({
                Title = "Player List Refreshed",
                Content = "Updated available players",
                Duration = 2,
                Image = 4483362458,
            })
        end
    end,
})

ShrineTab:CreateButton({
    Name = "🎭 Transform Selected Player to Mahoraga",
    Callback = function()
        if not SelectedPlayerForMahoraga then
            Rayfield:Notify({
                Title = "No Player Selected",
                Content = "Please select a player from the dropdown first!",
                Duration = 3,
                Image = 4483362458,
            })
            return
        end
        
        local success = ApplyPlayerMahoragaSkin(SelectedPlayerForMahoraga)
        
        if success then
            Rayfield:Notify({
                Title = "Mahoraga Applied!",
                Content = SelectedPlayerForMahoraga.Name .. " is now Mahoraga!",
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Transform Failed",
                Content = "Could not apply Mahoraga to " .. SelectedPlayerForMahoraga.Name,
                Duration = 3,
                Image = 4483362458,
            })
        end
    end
})

ShrineTab:CreateButton({
    Name = "🔓 Remove Mahoraga from Selected Player",
    Callback = function()
        if not SelectedPlayerForMahoraga then
            Rayfield:Notify({
                Title = "No Player Selected",
                Content = "Please select a player from the dropdown first!",
                Duration = 3,
                Image = 4483362458,
            })
            return
        end
        
        local success = RemovePlayerMahoragaSkin(SelectedPlayerForMahoraga)
        
        if success then
            Rayfield:Notify({
                Title = "Mahoraga Removed!",
                Content = "Removed Mahoraga from " .. SelectedPlayerForMahoraga.Name,
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Remove Failed",
                Content = SelectedPlayerForMahoraga.Name .. " doesn't have Mahoraga skin",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end
})

ShrineTab:CreateButton({
    Name = "🗑️ Remove All Player Mahoraga Skins",
    Callback = function()
        local count = 0
        for userId, skinData in pairs(PlayerMahoragaSkins) do
            if skinData.player then
                RemovePlayerMahoragaSkin(skinData.player)
                count = count + 1
            end
        end
        
        Rayfield:Notify({
            Title = "All Removed!",
            Content = "Removed Mahoraga from " .. count .. " player(s)",
            Duration = 3,
            Image = 4483362458,
        })
    end
})

ShrineTab:CreateParagraph({
    Title = "ℹ️ Player Mahoraga Transform",
    Content = "Transform ANY player in the server into Mahoraga! They will get the same visible, moving Mahoraga skin. Perfect for trolling or making your friends look epic!"
})

ShrineTab:CreateSection("🗡️ Mahoraga STICKY Teleport Attack")

ShrineTab:CreateToggle({
    Name = "Enable Teleport Attack",
    CurrentValue = true,
    Flag = "MahoragaTeleportAttack",
    Callback = function(Value)
        MahoragaTeleportAttackEnabled = Value
    end
})

ShrineTab:CreateKeybind({
    Name = "Mahoraga Sticky Attack",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Flag = "MahoragaAttackKey",
    Callback = function()
        MahoragaTeleportAttack()
    end
})

ShrineTab:CreateButton({
    Name = "🗡️ Execute Sticky Attack Now",
    Callback = function()
        MahoragaTeleportAttack()
    end
})

ShrineTab:CreateKeybind({
    Name = "Unstick Mahoraga",
    CurrentKeybind = "U",
    HoldToInteract = false,
    Flag = "MahoragaUnstickKey",
    Callback = function()
        UnstickMahoraga()
    end
})

ShrineTab:CreateButton({
    Name = "🔓 Unstick Mahoraga Now",
    Callback = function()
        local success = UnstickMahoraga()
        if success then
            Rayfield:Notify({
                Title = "Unstuck!",
                Content = "Mahoraga is no longer stuck to target",
                Duration = 2,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Not Stuck",
                Content = "Mahoraga isn't stuck to anyone",
                Duration = 2,
                Image = 4483362458,
            })
        end
    end
})

ShrineTab:CreateParagraph({
    Title = "🧲 STICKY Teleport Attack Info",
    Content = "Press P to make Mahoraga teleport and STICK to the enemy!\n\n🧲 FEATURES:\n• Glues to target\n• Follows everywhere\n• Matches velocity\n• Auto-unsticks if target dies\n\n🔓 Press U to manually unstick!"
})

ShrineTab:CreateSection("🎯 Target Selection")

local function refreshTargetPlayers()
    local playerNames = {"None (All Enemies)"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            table.insert(playerNames, p.Name)
        end
    end
    return playerNames
end

local TargetDropdown = ShrineTab:CreateDropdown({
    Name = "Select Direct Target",
    Options = refreshTargetPlayers(),
    CurrentOption = {"None (All Enemies)"},
    MultipleOptions = false,
    Flag = "TargetSelect",
    Callback = function(Option)
        if Option[1] == "None (All Enemies)" then
            TargetedPlayer = nil
            print("🎯 Targeting all enemies")
        else
            local targetPlayer = Players:FindFirstChild(Option[1])
            if targetPlayer then
                TargetedPlayer = targetPlayer
                print("🎯 Direct target:", targetPlayer.Name)
            end
        end
    end,
})

ShrineTab:CreateButton({
    Name = "Refresh Target List",
    Callback = function()
        if TargetDropdown then
            TargetDropdown:Refresh(refreshTargetPlayers())
            Rayfield:Notify({
                Title = "Target List Refreshed",
                Content = "Updated available targets",
                Duration = 2,
                Image = 4483362458,
            })
        end
    end,
})

ShrineTab:CreateSection("🎨 Visual Effects")

ShrineTab:CreateToggle({
    Name = "Cinematic Camera", 
    CurrentValue = true, 
    Callback = function(v) PlayCinematic = v end
})

ShrineTab:CreateToggle({
    Name = "Red Fog", 
    CurrentValue = true, 
    Callback = function(v) ShowRedFog = v end
})

ShrineTab:CreateToggle({
    Name = "Red Tinting", 
    CurrentValue = true, 
    Callback = function(v) EnableRedTinting = v end
})

ShrineTab:CreateSection("⚔️ Combat")

ShrineTab:CreateToggle({
    Name = "Use Enhanced Kill Aura", 
    CurrentValue = true,
    Flag = "KillAuraToggle",
    Callback = function(v) 
        UseKillAura = v 
    end
})

ShrineTab:CreateSlider({
    Name = "Kill Aura Range",
    Range = {100, 5000},
    Increment = 100,
    Suffix = " studs",
    CurrentValue = 2000,
    Flag = "KillAuraRange",
    Callback = function(v)
        KillAuraRange = v
    end
})

ShrineTab:CreateToggle({
    Name = "Auto-Disable on Enemy Death", 
    CurrentValue = true,
    Flag = "AutoDisableOnDeath",
    Callback = function(v) 
        AutoDisableOnDeath = v 
    end
})

ShrineTab:CreateSection("🎮 Controls")

ShrineTab:CreateKeybind({
    Name = "Activate Domain", 
    CurrentKeybind = "Z", 
    HoldToInteract = false,
    Flag = "DomainKeybind",
    Callback = function()
        ActivateDomain()
    end
})

ShrineTab:CreateKeybind({
    Name = "Force Close", 
    CurrentKeybind = "X",
    HoldToInteract = false,
    Flag = "ForceCloseKeybind", 
    Callback = function()
        ForceClose()
    end
})

ShrineTab:CreateButton({
    Name = "🛑 Force Close Domain",
    Callback = ForceClose
})

ShrineTab:CreateButton({
    Name = "📷 Manual Camera Fix",
    Callback = ForceResetCamera
})

ShrineTab:CreateParagraph({
    Title = "ℹ️ COMPLETE STICKY SCRIPT",
    Content = "• 🧲 Sticky teleport system\n• 🔊 Spawn audio on Mahoraga\n• 👥 Transform any player to Mahoraga\n• 🚀 Real teleport movement\n• 🔓 Manual unstick (U key)\n• Full domain expansion with slashes"
})

print("✅ COMPLETE STICKY SCRIPT WITH PLAYER TRANSFORM LOADED!")
print("✅ Mahoraga STICKS to targets!")
print("✅ Can transform ANY player to Mahoraga!")
print("🧲 Press P to stick, U to unstick!")
print("🔊 Spawn audio: " .. MAHORAGA_SPAWN_AUDIO_ID)
-- ═══════════════════════════════════════════════════════════════
-- 🎨 TAB 3: COLOR TOOLS (FROM ORIGINAL SCRIPT)
-- ═══════════════════════════════════════════════════════════════

local ColorTab = Window:CreateTab("🎨 Color Tools", 4483362458)
local ColorSection = ColorTab:CreateSection("Color Picker")

local currentColor = {r = 255, g = 100, b = 50}
local secondaryColor = {r = 100, g = 150, b = 255}
local colorLabels = {}
local brightnessMultiplier = 1.0
local gradientEnabled = false

local function updateColorInfo()
    local r, g, b = currentColor.r, currentColor.g, currentColor.b
    r, g, b = ColorConverter.multiplyBrightness(r, g, b, brightnessMultiplier)
    local hex = ColorConverter.rgbToHex(r, g, b)
    local h, s, v = ColorConverter.rgbToHsv(r, g, b)
    if colorLabels.rgb then colorLabels.rgb:Set(string.format("RGB: (%d, %d, %d)", r, g, b)) end
    if colorLabels.hex then colorLabels.hex:Set(string.format("HEX: %s", hex)) end
    if colorLabels.hsv then colorLabels.hsv:Set(string.format("HSV: (H:%d°, S:%d%%, V:%d%%)", h, s, v)) end
    if colorLabels.brightness then colorLabels.brightness:Set(string.format("Brightness: %.0f%%", brightnessMultiplier * 100)) end
end

ColorTab:CreateColorPicker({
    Name = "Primary Color",
    Color = Color3.fromRGB(currentColor.r, currentColor.g, currentColor.b),
    Flag = "ColorPicker1",
    Callback = function(Value)
        local r, g, b = ColorConverter.color3ToRgb(Value)
        currentColor.r, currentColor.g, currentColor.b = r, g, b
        updateColorInfo()
    end
})

ColorTab:CreateColorPicker({
    Name = "Secondary Color (for Gradients)",
    Color = Color3.fromRGB(secondaryColor.r, secondaryColor.g, secondaryColor.b),
    Flag = "ColorPicker2",
    Callback = function(Value)
        local r, g, b = ColorConverter.color3ToRgb(Value)
        secondaryColor.r, secondaryColor.g, secondaryColor.b = r, g, b
    end
})

colorLabels.rgb = ColorTab:CreateLabel("RGB: (255, 100, 50)")
colorLabels.hex = ColorTab:CreateLabel("HEX: #FF6432")
colorLabels.hsv = ColorTab:CreateLabel("HSV: (H:21°, S:80%, V:100%)")
colorLabels.brightness = ColorTab:CreateLabel("Brightness: 100%")

updateColorInfo()

ColorTab:CreateSection("🔆 Brightness Control")

ColorTab:CreateSlider({
    Name = "Color Brightness",
    Range = {0, 200},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "BrightnessSlider",
    Callback = function(Value)
        brightnessMultiplier = Value / 100
        updateColorInfo()
    end
})

ColorTab:CreateSection("🌈 Gradient Settings")

ColorTab:CreateToggle({
    Name = "Enable Gradient Mode",
    CurrentValue = false,
    Flag = "GradientToggle",
    Callback = function(Value)
        gradientEnabled = Value
    end
})

ColorTab:CreateParagraph({
    Title = "Gradient Info",
    Content = "When enabled, effects will use a gradient between Primary and Secondary colors instead of a solid color!"
})

local effectsEnabled = false
local activeConnections = {}
local processedEffects = {}

local function shouldRecolorEffect(obj)
    local t = obj.ClassName
    if t == "Beam" or t == "Trail" or t == "ParticleEmitter" or t == "Fire" or t == "Sparkles" then
        return true
    end
    if obj:IsA("BasePart") and obj.Material == Enum.Material.Neon then
        return true
    end
    return false
end

local function recolorEffect(obj)
    local r1, g1, b1 = ColorConverter.multiplyBrightness(currentColor.r, currentColor.g, currentColor.b, brightnessMultiplier)
    local r2, g2, b2 = ColorConverter.multiplyBrightness(secondaryColor.r, secondaryColor.g, secondaryColor.b, brightnessMultiplier)
    local c1 = ColorConverter.rgbToColor3(r1, g1, b1)
    local c2 = ColorConverter.rgbToColor3(r2, g2, b2)
    local ok = pcall(function()
        local t = obj.ClassName
        if t == "Beam" or t == "Trail" or t == "ParticleEmitter" then
            if gradientEnabled then
                obj.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, c1),
                    ColorSequenceKeypoint.new(0.5, ColorConverter.rgbToColor3(
                        (r1 + r2)/2, (g1 + g2)/2, (b1 + b2)/2
                    )),
                    ColorSequenceKeypoint.new(1, c2)
                })
            else
                obj.Color = ColorSequence.new(c1)
            end
        elseif t == "Fire" then
            obj.Color = c1
            obj.SecondaryColor = gradientEnabled and c2 or c1
        elseif t == "Sparkles" then
            obj.SparkleColor = c1
        elseif obj:IsA("BasePart") then
            obj.Color = c1
        end
    end)
    return ok
end

local function cleanupConnections()
    for _, c in pairs(activeConnections) do
        if c and c.Connected then c:Disconnect() end
    end
    activeConnections = {}
    processedEffects = {}
end

ColorTab:CreateToggle({
    Name = "Enable Move Color Changer",
    CurrentValue = false,
    Flag = "EffectsToggle",
    Callback = function(Value)
        effectsEnabled = Value
        if effectsEnabled then
            cleanupConnections()
            local function onDescendantAdded(obj)
                if not effectsEnabled or processedEffects[obj] then return end
                if shouldRecolorEffect(obj) then
                    processedEffects[obj] = true
                    recolorEffect(obj)
                    local conn = obj:GetPropertyChangedSignal("Color"):Connect(function()
                        if effectsEnabled then recolorEffect(obj) end
                    end)
                    table.insert(activeConnections, conn)
                end
            end
            local wsConn = workspace.DescendantAdded:Connect(onDescendantAdded)
            table.insert(activeConnections, wsConn)
            if Player.Character then
                local charConn = Player.Character.DescendantAdded:Connect(onDescendantAdded)
                table.insert(activeConnections, charConn)
            end
        else
            cleanupConnections()
        end
    end
})

ColorTab:CreateButton({
    Name = "Recolor Character Effects (One-Time)",
    Callback = function()
        if not Player.Character then return end
        local count = 0
        for _, obj in pairs(Player.Character:GetDescendants()) do
            if shouldRecolorEffect(obj) and recolorEffect(obj) then
                count = count + 1
            end
        end
        Rayfield:Notify({
            Title = "Effects Recolored",
            Content = "Recolored " .. count .. " effects!",
            Duration = 3,
            Image = 4483362458,
        })
    end
})

ColorTab:CreateButton({
    Name = "Copy HEX Code",
    Callback = function()
        local r, g, b = ColorConverter.multiplyBrightness(currentColor.r, currentColor.g, currentColor.b, brightnessMultiplier)
        local hex = ColorConverter.rgbToHex(r, g, b)
        if setclipboard then
            setclipboard(hex)
            Rayfield:Notify({
                Title = "HEX Copied",
                Content = hex .. " copied to clipboard!",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end
})

ColorTab:CreateButton({
    Name = "Swap Primary ↔ Secondary",
    Callback = function()
        local tmp = {r = currentColor.r, g = currentColor.g, b = currentColor.b}
        currentColor.r, currentColor.g, currentColor.b = secondaryColor.r, secondaryColor.g, secondaryColor.b
        secondaryColor.r, secondaryColor.g, secondaryColor.b = tmp.r, tmp.g, tmp.b
        updateColorInfo()
        Rayfield:Notify({
            Title = "Colors Swapped",
            Content = "Primary and Secondary colors swapped!",
            Duration = 2,
            Image = 4483362458,
        })
    end
})

-- ═══════════════════════════════════════════════════════════════
-- 🎯 TAB 4: HITBOX EXPANDER (FROM ORIGINAL SCRIPT)
-- ═══════════════════════════════════════════════════════════════

local HitboxTab = Window:CreateTab("🎯 Hitbox", 4483362458)
local HitboxSection = HitboxTab:CreateSection("Hitbox Settings")

local hitboxSize = 20
local hitboxEnabled = false
local originalSizes = {}
local transparencyEnabled = false

local function expandHitboxes()
    if not hitboxEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local head = plr.Character:FindFirstChild("Head")
            if hrp then
                if not originalSizes[plr.UserId] then
                    originalSizes[plr.UserId] = hrp.Size
                end
                local s = math.min(hitboxSize, 5000)
                hrp.Size = Vector3.new(s, s, s)
                hrp.Transparency = 1
                hrp.CanCollide = false
                hrp.Massless = true
                if head then
                    if not originalSizes[plr.UserId .. "Head"] then
                        originalSizes[plr.UserId .. "Head"] = head.Size
                    end
                    head.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    head.Transparency = transparencyEnabled and 0.5 or 1
                    head.CanCollide = false
                    head.Massless = true
                end
            end
        end
    end
end

local function restoreHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and originalSizes[plr.UserId] then
                hrp.Size = originalSizes[plr.UserId]
                hrp.Transparency = 1
                hrp.CanCollide = false
            end
            for _, part in pairs(plr.Character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local key = plr.UserId .. part.Name
                    if originalSizes[key] then
                        part.Size = originalSizes[key]
                        part.Transparency = 0
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end

HitboxTab:CreateToggle({
    Name = "Enable Hitbox Expander",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        hitboxEnabled = Value
        if hitboxEnabled then
            expandHitboxes()
            Rayfield:Notify({
                Title = "Hitbox Expander Enabled",
                Content = "All enemy hitboxes expanded!",
                Duration = 3,
                Image = 4483362458,
            })
        else
            restoreHitboxes()
            Rayfield:Notify({
                Title = "Hitbox Expander Disabled",
                Content = "Hitboxes restored to normal",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end
})

HitboxTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {0, 5000},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 20,
    Flag = "HitboxSize",
    Callback = function(Value)
        hitboxSize = Value
        if hitboxEnabled then
            expandHitboxes()
        end
    end
})

HitboxTab:CreateToggle({
    Name = "Show Hitboxes (Transparency)",
    CurrentValue = false,
    Flag = "TransparencyToggle",
    Callback = function(Value)
        transparencyEnabled = Value
        if hitboxEnabled then
            expandHitboxes()
        end
    end
})

HitboxTab:CreateButton({
    Name = "Refresh Hitboxes",
    Callback = function()
        if hitboxEnabled then
            restoreHitboxes()
            task.wait(0.1)
            expandHitboxes()
            Rayfield:Notify({
                Title = "Hitboxes Refreshed",
                Content = "All hitboxes have been refreshed!",
                Duration = 2,
                Image = 4483362458,
            })
        end
    end
})

RunService.Heartbeat:Connect(function()
    if hitboxEnabled then
        expandHitboxes()
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    originalSizes[plr.UserId] = nil
end)

HitboxTab:CreateParagraph({
    Title = "ℹ️ Hitbox Expander Info",
    Content = "Expands enemy hitboxes to make them easier to hit. Automatically maintains expanded hitboxes. Toggle 'Show Hitboxes' to see them visually."
})

-- ═══════════════════════════════════════════════════════════════
-- 🔧 TAB 5: CHARACTER ATTRIBUTES (UNBREAKABLE) (FROM ORIGINAL SCRIPT)
-- ═══════════════════════════════════════════════════════════════

local AttributesTab = Window:CreateTab("🔧 Attributes", 4483362458)
local AttrSection = AttributesTab:CreateSection("Unbreakable Controls")

local function findAndEnableUnbreakableAll()
    local playerChar = Player.Character
    if not playerChar then
        Rayfield:Notify({
            Title = "No Character",
            Content = "Character not found!",
            Duration = 3,
            Image = 4483362458,
        })
        return
    end
    local count = 0
    for _, obj in pairs(playerChar:GetDescendants()) do
        local objName = obj.Name:lower()
        if objName:match("unbreakable") then
            if obj:IsA("BoolValue") then
                obj.Value = true
                count = count + 1
            elseif obj:IsA("IntValue") or obj:IsA("NumberValue") then
                obj.Value = 1
                count = count + 1
            end
        end
        local attrs = obj:GetAttributes()
        for attrName, _ in pairs(attrs) do
            if attrName:lower():find("unbreakable") then
                obj:SetAttribute(attrName, true)
                count = count + 1
            end
        end
    end
    local charAttrs = playerChar:GetAttributes()
    for attrName, _ in pairs(charAttrs) do
        if attrName:lower():find("unbreakable") then
            playerChar:SetAttribute(attrName, true)
            count = count + 1
        end
    end
    
    Rayfield:Notify({
        Title = "Unbreakable Enabled",
        Content = "Enabled " .. count .. " unbreakable attributes!",
        Duration = 3,
        Image = 4483362458,
    })
end

AttributesTab:CreateButton({
    Name = "🛡️ Enable All Unbreakable",
    Callback = function()
        findAndEnableUnbreakableAll()
    end
})

AttributesTab:CreateButton({
    Name = "🔍 Show All Character Attributes",
    Callback = function()
        local playerChar = Player.Character
        if not playerChar then 
            Rayfield:Notify({
                Title = "No Character",
                Content = "Character not found!",
                Duration = 3,
                Image = 4483362458,
            })
            return 
        end
        print("=== ALL CHARACTER ATTRIBUTES ===")
        local count = 0
        for attrName, attrValue in pairs(playerChar:GetAttributes()) do
            count = count + 1
            print(attrName .. " = " .. tostring(attrValue))
        end
        print("=== END ATTRIBUTES ===")
        print("Total attributes: " .. count)
        
        Rayfield:Notify({
            Title = "Attributes Logged",
            Content = "Found " .. count .. " attributes! Check console (F9)",
            Duration = 5,
            Image = 4483362458,
        })
    end
})

AttributesTab:CreateParagraph({
    Title = "Auto-Enable on Respawn",
    Content = "Unbreakable attributes will auto-enable when you respawn!"
})

local function setupCharacter(character)
    if character then
        task.wait(0.5)
        findAndEnableUnbreakableAll()
    end
end

if Player.Character then
    setupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(setupCharacter)

-- ═══════════════════════════════════════════════════════════════
-- 📋 TAB 6: INFO & CREDITS
-- ═══════════════════════════════════════════════════════════════

local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateSection("📖 Script Information")

InfoTab:CreateParagraph({
    Title = "Ultimate Roblox Toolkit",
    Content = "Version: 4.0 STICKY EDITION WITH PLAYER TRANSFORM\nCreated: 2024\n\nThis is an all-in-one script featuring:\n• Malevolent Shrine Domain Expansion\n• Mahoraga NPC & Player Skins\n• Sticky Teleport Attack System\n• Transform ANY Player to Mahoraga\n• Color Conversion Tools\n• Hitbox Expander\n• Unbreakable Attributes\n• Blox Fruits Cooldown Control"
})

InfoTab:CreateSection("✨ Features")

InfoTab:CreateParagraph({
    Title = "🔥 Domain Expansion",
    Content = "• Full Malevolent Shrine with slashes\n• Red fog and tinting effects\n• Enhanced kill aura system\n• Cinematic camera sequences\n• Ground-level shrine rising\n• Auto-cleanup on death/duration"
})

InfoTab:CreateParagraph({
    Title = "🎭 Mahoraga System",
    Content = "• Transform NPCs to Mahoraga\n• Transform ANY player to Mahoraga\n• Visible & moving model (3x scale)\n• Walking animations\n• Spawn audio effects\n• Sword hidden in chest"
})

InfoTab:CreateParagraph({
    Title = "🧲 Sticky Teleport",
    Content = "• Press P to teleport & stick to enemy\n• Follows target everywhere\n• Matches target velocity\n• Press U to manually unstick\n• Auto-unstick on target death\n• Visual effects & sounds"
})

InfoTab:CreateParagraph({
    Title = "🎨 Color Tools",
    Content = "• RGB/HEX/HSV color picker\n• Gradient mode for effects\n• Real-time move color changer\n• Brightness & saturation control\n• Apply colors to character effects"
})

InfoTab:CreateParagraph({
    Title = "🎯 Utilities",
    Content = "• Hitbox expander (up to 5000 studs)\n• Unbreakable attribute enabler\n• Auto-enable on respawn\n• Show/hide hitboxes\n• Attribute viewer & debugger"
})

InfoTab:CreateSection("⌨️ Keybinds")

InfoTab:CreateParagraph({
    Title = "Default Controls",
    Content = "Z - Activate Domain Expansion\nX - Force Close Domain\nM - Play/Stop Shrine Audio\nP - Mahoraga Sticky Attack\nU - Unstick Mahoraga\n\nAll keybinds can be changed in their respective tabs!"
})

InfoTab:CreateSection("🔧 Tips & Tricks")

InfoTab:CreateParagraph({
    Title = "Pro Tips",
    Content = "1. Load Mahoraga model before activating skin\n2. Use 'Scan for NPCs' if auto-detection fails\n3. Camera fixes automatically on respawn\n4. Domain auto-closes on enemy death (if enabled)\n5. Sticky attack works on closest enemy\n6. Transform players for epic screenshots!\n7. Use F9 console for detailed logs\n8. Hitbox expander works on all players\n9. Unbreakable auto-enables on respawn"
})

InfoTab:CreateSection("⚠️ Known Issues")

InfoTab:CreateParagraph({
    Title = "Potential Issues",
    Content = "• Some NPCs may not auto-detect (use manual scan)\n• Domain lighting may persist rarely (use force close)\n• Mahoraga model requires asset ID to load\n• Kill aura depends on game's RemoteEvents\n• Works best in games with standard NPC structure\n• Hitbox expander may not work in some games"
})

InfoTab:CreateSection("🎮 Support")

InfoTab:CreateButton({
    Name = "Copy Discord (Example)",
    Callback = function()
        setclipboard("discord.gg/example")
        Rayfield:Notify({
            Title = "Discord Copied",
            Content = "Discord link copied to clipboard!",
            Duration = 3,
            Image = 4483362458,
        })
    end
})

InfoTab:CreateButton({
    Name = "Check for Updates",
    Callback = function()
        Rayfield:Notify({
            Title = "Version Check",
            Content = "You are running v4.0 STICKY - Latest Version!",
            Duration = 5,
            Image = 4483362458,
        })
    end
})

InfoTab:CreateSection("💝 Credits")

InfoTab:CreateParagraph({
    Title = "Special Thanks",
    Content = "• Rayfield UI Library\n• Roblox InsertService for models\n• Community feedback & testing\n• Original Malevolent Shrine concept\n• Mahoraga model creators\n• Original script developers\n\nThank you for using this script!"
})

InfoTab:CreateButton({
    Name = "⭐ Enjoy the Script!",
    Callback = function()
        Rayfield:Notify({
            Title = "Thank You!",
            Content = "Have fun with the Ultimate Toolkit!",
            Duration = 3,
            Image = 4483362458,
        })
        
        -- Easter egg: Spawn confetti effect
        for i = 1, 20 do
            local confetti = Instance.new("Part")
            confetti.Size = Vector3.new(0.5, 0.5, 0.5)
            confetti.Position = Player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-10, 10), math.random(5, 15), math.random(-10, 10))
            confetti.Anchored = false
            confetti.CanCollide = false
            confetti.Material = Enum.Material.Neon
            confetti.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            confetti.Parent = workspace
            
            Debris:AddItem(confetti, 3)
        end
    end
})

-- ═══════════════════════════════════════════════════════════════
-- 🚀 FINAL INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

print("═══════════════════════════════════════════════════════════════")
print("🎮 ULTIMATE ROBLOX TOOLKIT v4.0 STICKY EDITION")
print("═══════════════════════════════════════════════════════════════")
print("✅ All tabs loaded successfully!")
print("✅ Malevolent Shrine Domain Expansion: READY")
print("✅ Mahoraga NPC Skin System: READY")
print("✅ Mahoraga Player Transform: READY")
print("✅ Sticky Teleport Attack: READY")
print("✅ Color Conversion Tools: READY")
print("✅ Hitbox Expander: READY")
print("✅ Unbreakable Attributes: READY")
print("✅ Blox Fruits Tools: READY")
print("═══════════════════════════════════════════════════════════════")
print("⌨️ KEYBINDS:")
print("   Z - Activate Domain")
print("   X - Force Close Domain")
print("   M - Shrine Audio")
print("   P - Mahoraga Sticky Attack")
print("   U - Unstick Mahoraga")
print("═══════════════════════════════════════════════════════════════")
print("🎭 MAHORAGA INFO:")
print("   Model ID: " .. MAHORAGA_MODEL_ID)
print("   Spawn Audio: " .. MAHORAGA_SPAWN_AUDIO_ID)
print("   Height Offset: " .. MahoragaHeightOffset .. " studs")
print("═══════════════════════════════════════════════════════════════")
print("🔊 DOMAIN AUDIO:")
print("   Intro: rbxassetid://85929440442310")
print("   Main OST: rbxassetid://106240568414882")
print("═══════════════════════════════════════════════════════════════")
print("🚀 Script loaded! Open the GUI to get started.")
print("💡 Press F9 for console logs and debugging info.")
print("👥 NEW: Transform any player to Mahoraga in Red Shrine tab!")
print("═══════════════════════════════════════════════════════════════")

Rayfield:Notify({
    Title = "🎮 Ultimate Toolkit Loaded!",
    Content = "All systems ready! Transform players to Mahoraga!",
    Duration = 5,
    Image = 4483362458,
})

-- Auto-load Mahoraga model on startup
task.spawn(function()
    task.wait(2)
    LoadMahoragaModel()
    print("✅ Mahoraga model pre-loaded!")
end)
--// Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer



--// Window
local Window = Rayfield:CreateWindow({
    Name = "Fruit Cooldown Controller",
    LoadingTitle = "Fruit Tools",
    LoadingSubtitle = "Inf f",
})

--// Tab named "Inf f"
local Tab = Window:CreateTab("Inf f", 4483362458)

--// Helper: get current character
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

--// Ensure Fruit-F attribute exists on current character
local character = getCharacter()
if character:GetAttribute("FruitFCooldown") == nil then
    character:SetAttribute("FruitFCooldown", 0)
end

--// Slider ONLY for Fruit-F cooldown
local FruitFSlider = Tab:CreateSlider({
    Name = "Fruit F Cooldown",
    Range = {0, 55},
    Increment = 1,
    Suffix = "sec",
    CurrentValue = character:GetAttribute("FruitFCooldown") or 0,
    Flag = "FruitFCooldownSlider",
    Callback = function(value)
        local char = getCharacter()
        -- This line changes ONLY the Fruit-F cooldown attribute
        char:SetAttribute("FruitFCooldown", value)
    end,
})

--// Keep Fruit-F value on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    local current = FruitFSlider.CurrentValue or 0
    newChar:SetAttribute("FruitFCooldown", current)
end)
