local Module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

function Module.Init(Settings)
    local STATE_FLAG = 16842753
    local STATE_OFFSET = 0x1E0 
    local UpVector = vector.create(0, 1, 0)
    local SpinAngle = 0
    local AA_LookVector = vector.create(0, 0, 0)

    local function Update()
        if not LocalPlayer then LocalPlayer = Players.LocalPlayer end
        if not Camera then Camera = Workspace.CurrentCamera end
        
        -- Debug Line
        if Settings.ShowAADebug and vector.magnitude(AA_LookVector) > 0 and LocalPlayer and LocalPlayer.Character then
            local RootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if RootPart then
                local s1, v1 = Camera:WorldToScreenPoint(RootPart.Position)
                local s2, v2 = Camera:WorldToScreenPoint(RootPart.Position + AA_LookVector * 5)
                if v1 and v2 then
                    DrawingImmediate.Line(vector.create(s1.X, s1.Y, 0), vector.create(s2.X, s2.Y, 0), Color3.fromRGB(0, 255, 255), 1, 1)
                end
            end
        end

        -- Logic
        if LocalPlayer and LocalPlayer.Character then
            local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            local RootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if Humanoid and RootPart and Humanoid.Health > 0 then
                local isActiveAA = Settings.AntiAimMasterEnabled and Settings.AntiAimActive -- Keypicker flag
                local currentAAMode = Settings.AntiAimMode

                if isActiveAA and currentAAMode ~= "None" then
                    memory.writei32(Humanoid, STATE_OFFSET, STATE_FLAG)
                    local TargetAngle = 0
                    local camLook = Camera.LookVector
                    local camYaw = math.atan2(camLook.X, camLook.Z) 

                    if currentAAMode == "Jitter" then
                        local jMin, jMax = Settings.JitterMin, Settings.JitterMax
                        if jMin > jMax then jMin, jMax = jMax, jMin end 
                        TargetAngle = camYaw + math.rad(math.random(jMin, jMax)) + math.pi
                    elseif currentAAMode == "Spin" then
                        SpinAngle = SpinAngle + math.rad(Settings.SpinSpeed) * 0.1
                        TargetAngle = SpinAngle
                    elseif currentAAMode == "Static" then
                        TargetAngle = camYaw + math.rad(Settings.StaticOffset)
                    end

                    AA_LookVector = vector.create(math.sin(TargetAngle), 0, math.cos(TargetAngle))
                    RootPart.LookVector = AA_LookVector
                    RootPart.RightVector = vector.cross(UpVector, AA_LookVector)
                else
                    AA_LookVector = vector.create(0,0,0) 
                end
            end
        end
    end

    return { Update = Update }
end

return Module
