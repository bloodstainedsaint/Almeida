local Module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

function Module.Init(Settings, MapCache)
    local function LerpColor(a, b, t)
        return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
    end

    local function CalculateRingPoints(centerPos, radius, numSides)
        local points = {}
        local step = (math.pi * 2) / numSides
        for i = 0, numSides do
            local angle = step * i
            local offset = vector.create(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            local worldPoint = centerPos + offset
            local screenPoint, onScreen = Camera:WorldToScreenPoint(worldPoint)
            if onScreen then
                table.insert(points, vector.create(screenPoint.X, screenPoint.Y, 0))
            end
        end
        return points
    end

    local function Update()
        if not Camera then Camera = Workspace.CurrentCamera end
        local viewport = Camera.ViewportSize
        local center = vector.create(viewport.X / 2, viewport.Y / 2, 0)
        local bottomCenter = vector.create(viewport.X / 2, viewport.Y, 0)

        -- Radar
        if Settings.RadarEnabled then
            local rPos = vector.create(Settings.RadarX, Settings.RadarY, 0)
            local rSize = Settings.RadarSize; local rHalf = rSize/2
            local rCenter = rPos + vector.create(rHalf, rHalf, 0)
            DrawingImmediate.FilledRectangle(rPos, vector.create(rSize, rSize, 0), Settings.ColorRadarBG, 0.8)
            DrawingImmediate.Rectangle(rPos, vector.create(rSize, rSize, 0), Color3.new(1,1,1), 1, 1)
            local camAngle = math.atan2(Camera.LookVector.X, Camera.LookVector.Z)
            for _, plr in ipairs(Players:GetChildren()) do
                if plr ~= LocalPlayer and plr.Character then
                    if Settings.TeamCheck and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then continue end
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = vector.magnitude(root.Position - Camera.Position)
                        if dist <= Settings.RadarRange then
                            local delta = root.Position - Camera.Position
                            local dx = delta.X * math.cos(camAngle) - delta.Z * math.sin(camAngle)
                            local dy = delta.X * math.sin(camAngle) + delta.Z * math.cos(camAngle)
                            local scale = rHalf / Settings.RadarRange
                            DrawingImmediate.FilledCircle(rCenter + vector.create(dy*scale, -dx*scale, 0), 3, Settings.ColorRadarDot, 1)
                        end
                    end
                end
            end
        end

        -- ESP
        if Settings.ESPEnabled then
            for _, plr in ipairs(Players:GetChildren()) do
                if plr == LocalPlayer or not plr.Character then continue end
                if Settings.TeamCheck and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then continue end
                local char = plr.Character
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                local head = char:FindFirstChild("Head")
                if root and hum and head and hum.Health > 0 then
                    local rootPos = root.Position
                    local topVis, botVis = true, true
                    local topScreen = Camera:WorldToScreenPoint(rootPos + vector.create(0, 3, 0))
                    local botScreen = Camera:WorldToScreenPoint(rootPos - vector.create(0, 3.5, 0))
                    local headScreen, headVis = Camera:WorldToScreenPoint(head.Position)
                    local _, tVis = Camera:WorldToScreenPoint(rootPos + vector.create(0,3,0))
                    local _, bVis = Camera:WorldToScreenPoint(rootPos - vector.create(0,3.5,0))
                    
                    if tVis and bVis then
                        local height = math.abs(botScreen.Y - topScreen.Y)
                        local width = height / 1.6
                        local pos = vector.create(topScreen.X - width/2, topScreen.Y, 0)
                        
                        if Settings.ESPTracers then DrawingImmediate.Line(bottomCenter, vector.create(botScreen.X, botScreen.Y, 0), Settings.ColorTracer, 1, 1) end
                        if Settings.ESPBox then DrawingImmediate.Rectangle(pos, vector.create(width, height, 0), Settings.ColorBox, 1, 1.5) end
                        if Settings.ESPName then DrawingImmediate.OutlinedText(vector.create(topScreen.X, topScreen.Y - 15, 0), 13, Color3.new(1,1,1), 1, plr.Name, true, "Proggy") end
                        
                        -- Add other ESP elements (Health, Skeleton, etc) here as needed
                    end
                end
            end
        end
    end

    return { Update = Update }
end

return Module
