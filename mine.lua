-- Mine a Mountain Advanced Automation Script
-- Dibuat untuk Roblox executor dengan UI Rayfield, otomatisasi dinamis, dan fitur anti-freeze/anti-AFK.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local configFileName = "mine_a_mountain_advanced_config.json"

-- Pastikan Rayfield UI library tersedia. Jika tidak, pesan error akan dicetak.
local loaded, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
end)

if not loaded or not Rayfield then
    warn("[Mine a Mountain] Gagal memuat Rayfield UI. Pastikan executor Anda mengizinkan HttpGet.")
    return
end

-- Simpan nilai toggle global untuk masing-masing fitur
local settings = {
    AutoMine = false,
    AutoSell = false,
    AntiFreeze = false,
    AntiAFK = false,
}

local lastMineTimestamp = 0
local sellThresholdSeconds = 12 -- Jarak waktu sebelum coba jual

-- Fungsi utilitas untuk mendapatkan Character dan HumanoidRootPart
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getRootPart()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- Fungsi untuk mendeteksi apakah sebuah objek kemungkinan besar adalah target tambang
local function isMineableTarget(instance)
    if not instance or not instance:IsA("Instance") then
        return false
    end

    local name = instance.Name:lower()
    if name:find("crystal") or name:find("ore") or name:find("rock") or name:find("stone") or name:find("mineral") then
        return true
    end

    -- Beberapa game hanya menggunakan ClickDetector/ProximityPrompt tanpa nama yang jelas.
    local parent = instance.Parent
    if parent and parent:IsA("BasePart") then
        local parentName = parent.Name:lower()
        return parentName:find("crystal") or parentName:find("ore") or parentName:find("rock") or parentName:find("stone") or parentName:find("mineral")
    end

    return false
end

-- Temukan objek tambang dari Workspace dengan detektor Click atau ProximityPrompt
local function getMineTargets()
    local targets = {}

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("ClickDetector") or descendant:IsA("ProximityPrompt") then
            local root = descendant.Parent or descendant
            if isMineableTarget(descendant) or isMineableTarget(root) then
                table.insert(targets, descendant)
            end
        end
    end

    return targets
end

-- Temukan lokasi jual berdasarkan nama.
local function findSellTarget()
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        local name = descendant.Name:lower()
        if name:find("sell") or name:find("sellarea") or name:find("sellpart") or name:find("sell base") then
            if descendant:IsA("BasePart") then
                return descendant
            elseif descendant:IsA("Model") and descendant.PrimaryPart then
                return descendant.PrimaryPart
            elseif descendant:IsA("Folder") then
                for _, child in ipairs(descendant:GetChildren()) do
                    if child:IsA("BasePart") then
                        return child
                    end
                end
            end
        end
    end
    return nil
end

-- Coba baca status inventory / leaderstats untuk tahu kapan harus menjual
local function isInventoryFullOrReadyToSell()
    -- Periksa leaderstats yang umum digunakan di banyak game mining
    if player:FindFirstChild("leaderstats") then
        for _, stat in ipairs(player.leaderstats:GetChildren()) do
            local statName = stat.Name:lower()
            if statName:find("crystal") or statName:find("ore") or statName:find("inventory") or statName:find("bag") or statName:find("capacity") then
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    if stat.Value > 0 then
                        return true
                    end
                end
            end
        end
    end

    -- Jika ada Backpack, periksa jumlah tool / item.
    if player:FindFirstChild("Backpack") then
        if #player.Backpack:GetChildren() >= 8 then
            return true
        end
    end

    return false
end

-- Teleport karakter ke posisi dekat target. Gunakan CFrame agar tidak mengunci karakter.
local function teleportToTarget(part)
    local root = getRootPart()
    if not root or not part or not part:IsA("BasePart") then
        return false
    end

    local success, err = pcall(function()
        local targetCFrame = part.CFrame
        local forward = targetCFrame.LookVector
        local offset = Vector3.new(0, 3, 0) - forward * 4
        root.CFrame = CFrame.new(targetCFrame.Position + offset, targetCFrame.Position)
    end)

    if not success then
        warn("[Mine a Mountain] Gagal teleport: " .. tostring(err))
    end

    return success
end

-- Picu interaksi dengan target tambang melalui ClickDetector atau ProximityPrompt
local function fireMineInteraction(detector)
    if not detector or not detector.Parent then
        return
    end

    pcall(function()
        if detector:IsA("ClickDetector") then
            fireclickdetector(detector)
        elseif detector:IsA("ProximityPrompt") then
            fireproximityprompt(detector)
        end
    end)
end

-- Loop utama Auto Mine
task.spawn(function()
    while true do
        if settings.AutoMine then
            local targets = getMineTargets()
            for _, detector in ipairs(targets) do
                if not settings.AutoMine then
                    break
                end

                local root = detector.Parent
                if root and root:IsA("BasePart") then
                    lastMineTimestamp = tick()
                    teleportToTarget(root)
                    fireMineInteraction(detector)

                    -- Biarkan game mengunci hit atau menghancurkan objek terlebih dahulu
                    task.wait(0.08)
                else
                    local parentPart = detector.Parent
                    if parentPart and parentPart:IsA("BasePart") then
                        lastMineTimestamp = tick()
                        teleportToTarget(parentPart)
                        fireMineInteraction(detector)
                        task.wait(0.08)
                    end
                end
            end
        end

        task.wait(0.2)
    end
end)

-- Loop Auto Sell berdasarkan waktu tambang dan data inventory
task.spawn(function()
    while true do
        if settings.AutoSell and (tick() - lastMineTimestamp >= sellThresholdSeconds or isInventoryFullOrReadyToSell()) then
            local sellPart = findSellTarget()
            if sellPart and getRootPart() then
                -- Teleport di atas area jual untuk memastikan transaksi ter-trigger
                pcall(function()
                    local root = getRootPart()
                    root.CFrame = CFrame.new(sellPart.Position + Vector3.new(0, 4, 0))
                end)
                task.wait(0.5)
            end

            -- Cegah terus menerus teleport jika lokasi jual tidak terdeteksi
            task.wait(2)
        end

        task.wait(0.3)
    end
end)

-- Anti-Freeze / God Mode: hapus efek beku lokal dan pastikan Humanoid tetap sehat
task.spawn(function()
    while true do
        if settings.AntiFreeze then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")

                -- Hapus nilai efek beku, status dingin, dan objek blokir lainnya pada karakter
                for _, descendant in ipairs(char:GetDescendants()) do
                    if descendant:IsA("BoolValue") or descendant:IsA("IntValue") or descendant:IsA("NumberValue") or descendant:IsA("StringValue") then
                        local name = descendant.Name:lower()
                        if name:find("freeze") or name:find("frost") or name:find("cold") or name:find("snow") or name:find("chill") or name:find("icing") then
                            pcall(function()
                                descendant:Destroy()
                            end)
                        end
                    end

                    -- Beberapa efek dapat berupa BodyVelocity / BodyForce yang menahan karakter
                    if descendant:IsA("BodyVelocity") or descendant:IsA("BodyForce") or descendant:IsA("BodyGyro") then
                        local name = descendant.Name:lower()
                        if name:find("freeze") or name:find("frost") or name:find("cold") or name:find("chill") then
                            pcall(function()
                                descendant:Destroy()
                            end)
                        end
                    end
                end

                -- Jaga kondisi Humanoid tetap optimal
                if humanoid then
                    pcall(function()
                        humanoid.Health = humanoid.MaxHealth
                        humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, 16)
                        humanoid.JumpPower = math.max(humanoid.JumpPower, 50)
                    end)
                end
            end
        end

        task.wait(1)
    end
end)

-- Anti-AFK menggunakan VirtualUser supaya tidak ter-kick karena idle
task.spawn(function()
    if settings.AntiAFK then
        player.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end)
        end)
    end
end)

-- Memuat konfigurasi dari file jika tersedia
local function loadConfig()
    if isfile and isfile(configFileName) then
        local success, data = pcall(function()
            return readfile(configFileName)
        end)
        if success and data then
            local parsed = HttpService:JSONDecode(data)
            for key, value in pairs(parsed) do
                if settings[key] ~= nil then
                    settings[key] = value
                end
            end
        end
    end
end

-- Menyimpan konfigurasi saat ini ke file JSON
local function saveConfig()
    local success, data = pcall(function()
        return HttpService:JSONEncode(settings)
    end)
    if success then
        pcall(function()
            writefile(configFileName, data)
        end)
    end
end

loadConfig()

-- Membuat UI Rayfield dengan tema gelap
local Window = Rayfield:CreateWindow({
    Name = "Mine a Mountain - Advanced",
    LoadingTitle = "Mine a Mountain Advanced Script",
    LoadingSubtitle = "Mengaktifkan automation...",
    ConfigurationSaving = {
        Enabled = false,
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

local FarmingTab = Window:CreateTab("Farming")
local MiscTab = Window:CreateTab("Miscellaneous")
local SettingsTab = Window:CreateTab("Settings")

FarmingTab:CreateToggle({
    Name = "Auto Mine Crystals",
    CurrentValue = settings.AutoMine,
    Flag = "AutoMine",
    Callback = function(value)
        settings.AutoMine = value
    end,
})

FarmingTab:CreateToggle({
    Name = "Auto Sell Crystals",
    CurrentValue = settings.AutoSell,
    Flag = "AutoSell",
    Callback = function(value)
        settings.AutoSell = value
    end,
})

MiscTab:CreateToggle({
    Name = "Anti-Freeze / God Mode",
    CurrentValue = settings.AntiFreeze,
    Flag = "AntiFreeze",
    Callback = function(value)
        settings.AntiFreeze = value
    end,
})

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = settings.AntiAFK,
    Flag = "AntiAFK",
    Callback = function(value)
        settings.AntiAFK = value
    end,
})

SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        saveConfig()
        Rayfield:Notify({
            Title = "Mine a Mountain",
            Content = "Pengaturan telah disimpan.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        loadConfig()
        Rayfield:Notify({
            Title = "Mine a Mountain",
            Content = "Konfigurasi dimuat dari file.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

SettingsTab:CreateToggle({
    Name = "Auto Load Config On Start",
    CurrentValue = true,
    Flag = "AutoLoadConfig",
    Callback = function() end,
})

Rayfield:CreateNotification({
    Title = "Mine a Mountain",
    Content = "Script aktif. Anda dapat menyalakan fitur di tab Farming dan Misc.",
    Duration = 5,
    Image = 4483362458,
})

-- Jika konfigurasi dimuat pada saat start, pastikan nilai toggle UI mengikuti state.
for _, flag in ipairs({"AutoMine", "AutoSell", "AntiFreeze", "AntiAFK"}) do
    local toggle = Rayfield:FindFirstFlag(flag)
    if toggle and settings[flag] ~= nil then
        toggle:SetValue(settings[flag])
    end
end

-- Pastikan anti-AFK terus aktif walau toggle diaktifkan setelah script berjalan.
player.Idled:Connect(function()
    if settings.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0, 0))
        end)
    end
end)

-- Pastikan konfigurasi tersimpan saat UI ditutup atau script dimatikan.
Window:OnUnload(function()
    saveConfig()
end)
