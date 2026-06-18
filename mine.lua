-- ORION UI LIBRARY LANGSUNG DI DALAM SKRIP (ANTI-GAGAL DOWNLOAD)
local OrionLib = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Membuat UI dasar manual jika HttpGet library orang lain diblokir
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MineToggle = Instance.new("TextButton")
local SellToggle = Instance.new("TextButton")

ScreenGui.Name = "MineAMountainUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Mine a Mountain - Delta Stable"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

MineToggle.Name = "MineToggle"
MineToggle.Parent = MainFrame
MineToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MineToggle.Position = UDim2.new(0.1, 0, 0.25, 0)
MineToggle.Size = UDim2.new(0, 200, 0, 40)
MineToggle.Font = Enum.Font.SourceSans
MineToggle.Text = "Auto Mine: OFF"
MineToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
MineToggle.TextSize = 16

SellToggle.Name = "SellToggle"
SellToggle.Parent = MainFrame
SellToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SellToggle.Position = UDim2.new(0.1, 0, 0.55, 0)
SellToggle.Size = UDim2.new(0, 200, 0, 40)
SellToggle.Font = Enum.Font.SourceSans
SellToggle.Text = "Auto Sell: OFF"
SellToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SellToggle.TextSize = 16

-- LOGIKA TOGGLE
_G.AutoMine = false
_G.AutoSell = false

MineToggle.MouseButton1Click:Connect(function()
    _G.AutoMine = not _G.AutoMine
    if _G.AutoMine then
        MineToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        MineToggle.Text = "Auto Mine: ON"
    else
        MineToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        MineToggle.Text = "Auto Mine: OFF"
    end
end)

SellToggle.MouseButton1Click:Connect(function()
    _G.AutoSell = not _G.AutoSell
    if _G.AutoSell then
        SellToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        SellToggle.Text = "Auto Sell: ON"
    else
        SellToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        SellToggle.Text = "Auto Sell: OFF"
    end
end)

-- LOOP AUTO MINE
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.AutoMine then
            pcall(function()
                for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not _G.AutoMine then break end
                    if v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then
                        local name = v.Parent.Name:lower()
                        if name:find("crystal") or name:find("ore") or name:find("rock") or name:find("stone") then
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = v.Parent.CFrame * CFrame.new(0, 0, 3)
                                task.wait(0.05)
                                if v:IsA("ClickDetector") then fireclickdetector(v)
                                elseif v:IsA("ProximityPrompt") then fireproximityprompt(v) end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- LOOP AUTO SELL
task.spawn(function()
    while true do
        task.wait(1)
        if _G.AutoSell then
            pcall(function()
                local sellPart = game:GetService("Workspace"):FindFirstChild("Sell") 
                    or game:GetService("Workspace"):FindFirstChild("SellArea") 
                    or game:GetService("Workspace"):FindFirstChild("SellPart")
                if sellPart and LocalPlayer.Character then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = sellPart.CFrame * CFrame.new(0, 4, 0)
                end
            end)
            task.wait(12)
        end
    end
end)
