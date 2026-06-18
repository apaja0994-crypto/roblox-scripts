-- MENEBAK INTERAKSI & AREA JUAL SECARA OTOMATIS (KAVO VERSION FOR DELTA)
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xazaap/Kavo-Library/main/source.lua"))()
local Window = Kavo.CreateLib("Mine a Mountain - Delta Stable", "DarkTheme")

local MainTab = Window:NewTab("Farming")
local Section = MainTab:NewSection("Automation")

_G.AutoMine = false
_G.AutoSell = false

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
                            local char = game.Players.LocalPlayer.Character
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
                if sellPart and game.Players.LocalPlayer.Character then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = sellPart.CFrame * CFrame.new(0, 4, 0)
                end
            end)
            task.wait(12)
        end
    end
end)

Section:NewToggle("Auto Mine Crystals", "Otomatis menambang", function(state) _G.AutoMine = state end)
Section:NewToggle("Auto Sell Crystals", "Teleport otomatis ke Toko", function(state) _G.AutoSell = state end)
