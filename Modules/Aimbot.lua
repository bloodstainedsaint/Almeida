local Module = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

function Module.Init(Settings, MapCache, TargetCache)
    local TriggerState = { LastFire = 0 }
    
    -- 1. Helper: Geometry Caching
    local function AddPartToCache(part)
        local cf = part.CFrame
        local size = part.Size
        if cf and cf.Position and size then
            local pos = cf.Position
            local entry = {
                Pos = pos, Size = size, HalfSize = size * 0.5,
                Right = cf.RightVector, Up = cf.UpVector, Look = cf.LookVector
            }
            local CellSize = MapCache.CellSize
            local min, max = pos - entry.HalfSize, pos + entry.HalfSize
            local minX, maxX = math.floor(min.X / CellSize), math.floor(max.X / CellSize)
            local minY, maxY = math.floor(min.Y / CellSize), math.floor(max.Y / CellSize)
            local minZ, maxZ = math.floor(min.Z / CellSize), math.floor(max.Z / CellSize)
            
            for x = minX, maxX do
                for y = minY, maxY do
                    for z = minZ, maxZ do
                        local key = x .. "," .. y .. "," .. z
                        if not MapCache.Grid[key] then MapCache.Grid[key] = {} end
                        table.insert(MapCache.Grid[key], entry)
                    end
                end
            end
        end
    end

    local function BuildMapCache()
        if MapCache.IsCaching then return end
        MapCache.IsCaching = true
        MapCache.Ready = false
        MapCache.Grid = {}
        local partsToCache = {}
        for _, obj in Workspace:GetDescendants() do
            if (obj.ClassName == "Part" or obj.ClassName == "MeshPart") and obj.CanCollide and obj.Transparency < 1 then
                table.insert(partsToCache, obj)
            end
            if #partsToCache % 2000 == 0 then task.wait() end
        end
        for i, part in ipairs(partsToCache) do
            AddPartToCache(part)
            if i % 1000 == 0 then task.wait() end
        end
        MapCache.Ready = true
        MapCache.IsCaching = false
        print("Map Cached")
    end

    -- 2. Helper: Intersection
    local function CheckCachedIntersection(entry, rayOrigin, rayDirection, maxDistance)
        local pos = entry.Pos
        local delta = rayOrigin - pos
        local localOrigin = vector.create(vector.dot(delta, entry.Right), vector.dot(delta, entry.Up), vector.dot(delta, entry.Look))
        local localDir = vector.create(vector.dot(rayDirection, entry.Right), vector.dot(rayDirection, entry.Up), vector.dot(rayDirection, entry.Look))
        local tMin, tMax = 0, maxDistance
        local axisNames = {"x", "y", "z"}
        for _, axis in axisNames do
            local originComp = localOrigin[axis]; local dirComp = localDir[axis]; local bound = entry.HalfSize[axis]
            if math.abs(dirComp) < 0.001 then
                if originComp < -bound or originComp > bound then return nil end
            else
                local t1 = (-bound - originComp) / dirComp; local t2 = (bound - originComp) / dirComp
                if t1 > t2 then t1, t2 = t2, t1 end
                tMin = math.max(tMin, t1); tMax = math.min(tMax, t2)
                if tMin > tMax then return nil end
            end
        end
        return tMin
    end

    local function GetWallDistance(origin, dir, maxDist)
        if not MapCache.Ready then return nil end
        local CS = MapCache.CellSize
        local Steps = math.ceil(maxDist / (CS / 2))
        local ClosestHit = math.huge
        local HitFound = false
        local CheckedEntries = {}

        for i = 0, Steps do
            local point = origin + (dir * (i * (CS/2)))
            if vector.magnitude(point - origin) > maxDist then break end
            local key = math.floor(point.X/CS)..","..math.floor(point.Y/CS)..","..math.floor(point.Z/CS)
            local cell = MapCache.Grid[key]
            if cell then
                for _, entry in cell do
                    if not CheckedEntries[entry] then
                        CheckedEntries[entry] = true
                        local hitDist = CheckCachedIntersection(entry, origin, dir, maxDist)
                        if hitDist and hitDist < ClosestHit then
                            ClosestHit = hitDist
                            HitFound = true
                        end
                    end
                end
            end
        end
        return HitFound and ClosestHit or nil
    end

    local function IsVisible(origin, targetPart)
        if not targetPart then return false end
        local dist = vector.magnitude(targetPart.Position - origin)
        local dir = vector.normalize(targetPart.Position - origin)
        local wallDist = GetWallDistance(origin, dir, dist)
        if wallDist and wallDist < (dist - 1.5) then return false end
        return true
    end

    -- 3. Instance Intersection (For Triggerbot)
    local function GetInstanceIntersection(part, rayOrigin, rayDirection, maxDistance)
        local size = part.Size; local cf = part.CFrame
        if not (cf and cf.Position and size) then return nil end 
        local delta = rayOrigin - cf.Position
        local localOrigin = vector.create(vector.dot(delta, cf.RightVector), vector.dot(delta, cf.UpVector), vector.dot(delta, cf.LookVector))
        local localDir = vector.create(vector.dot(rayDirection, cf.RightVector), vector.dot(rayDirection, cf.UpVector), vector.dot(rayDirection, cf.LookVector))
        local tMin, tMax = 0, maxDistance; local halfSize = size * 0.5
        local axisNames = {"x", "y", "z"}
        for _, axis in axisNames do
            local originComp = localOrigin[axis]; local dirComp = localDir[axis]; local bound = halfSize[axis]
            if math.abs(dirComp) < 0.001 then
                if originComp < -bound or originComp > bound then return nil end
            else
                local t1 = (-bound - originComp) / dirComp; local t2 = (bound - originComp) / dirComp
                if t1 > t2 then t1, t2 = t2, t1 end
                tMin = math.max(tMin, t1); tMax = math.min(tMax, t2)
                if tMin > tMax then return nil end
            end
        end
        return tMin
    end

    -- 4. Aimbot & Triggerbot Update Loop
    local function Update()
        if not Camera then Camera = Workspace.CurrentCamera end
        if not Settings.Enabled then return end

        local viewport = Camera.ViewportSize
        local center = vector.create(viewport.X / 2, viewport.Y / 2, 0)

        -- FOV Draw
        if Settings.ShowFOV then
            local pts = {}
            local step = (math.pi*2)/Settings.FOVSides
            for i=0, Settings.FOVSides do
                table.insert(pts, center + vector.create(math.cos(step*i)*Settings.FOV, math.sin(step*i)*Settings.FOV, 0))
            end
            DrawingImmediate.Polyline(pts, Color3.new(1,1,1), 1, 1)
        end

        -- Triggerbot Logic
        if Settings.TriggerEnabled and Settings.TriggerActive then -- TriggerActive is set by UI Keypicker
            local origin = Camera.Position
            local dir = Camera.CFrame.LookVector
            local maxDist = Settings.TriggerDistance
            local wallDist = GetWallDistance(origin, dir, maxDist) or math.huge
            local enemyDist, hitEnemy = math.huge, false
            
            for _, plr in ipairs(Players:GetChildren()) do
                if plr ~= LocalPlayer and plr.Character then
                    if Settings.TeamCheck and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then continue end
                    local char = plr.Character
                    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
                    local hbList = isR15 and Settings.HitboxR15 or Settings.HitboxR6
                    for partName, _ in pairs(hbList) do
                        local part = char:FindFirstChild(partName)
                        if part then
                            local dist = GetInstanceIntersection(part, origin, dir, maxDist)
                            if dist and dist < enemyDist then
                                enemyDist = dist; hitEnemy = true
                            end
                        end
                    end
                end
            end
            if hitEnemy and enemyDist < wallDist then
                if (os.clock() - TriggerState.LastFire) > Settings.TriggerDelay then
                    mouse1click()
                    TriggerState.LastFire = os.clock()
                end
            end
        end

        -- Aimbot Logic
        if not Settings.Aiming then -- Aiming is set by UI Keypicker
            if Settings.StickyAim then TargetCache.Player = nil end
            return
        end

        local activeTargetPart = nil
        if Settings.StickyAim and TargetCache.Player and TargetCache.Player.Character then
            local cachedPart = nil
            if TargetCache.Part and TargetCache.Part.Name then
                cachedPart = TargetCache.Player.Character:FindFirstChild(TargetCache.Part.Name)
            end
            if cachedPart then
                if Settings.WallCheck and not IsVisible(Camera.Position, cachedPart) then
                    activeTargetPart = nil
                else
                    activeTargetPart = cachedPart
                end
            else
                TargetCache.Player = nil
            end
        end

        if not TargetCache.Player and not activeTargetPart then
            local minDist = math.huge
            local bestPart, bestPlr = nil, nil
            for _, plr in ipairs(Players:GetChildren()) do
                if plr == LocalPlayer or not plr.Character then continue end
                if Settings.TeamCheck and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then continue end
                local char = plr.Character
                local isR15 = char:FindFirstChild("UpperTorso") ~= nil
                local hbList = isR15 and Settings.HitboxR15 or Settings.HitboxR6
                for partName, enabled in pairs(hbList) do
                    if not enabled then continue end
                    local part = char:FindFirstChild(partName)
                    if part then
                        if Settings.WallCheck and not IsVisible(Camera.Position, part) then continue end
                        local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
                        if onScreen then
                            local dist = vector.magnitude(vector.create(screenPos.X, screenPos.Y, 0) - center)
                            if dist < Settings.FOV and dist < minDist then
                                minDist = dist; bestPart = part; bestPlr = plr
                            end
                        end
                    end
                end
            end
            if bestPart then
                activeTargetPart = bestPart
                if Settings.StickyAim then TargetCache.Player = bestPlr; TargetCache.Part = bestPart end
            end
        end

        if activeTargetPart then
            local targetPos = activeTargetPart.Position
            if Settings.PredictionEnabled then
                -- Prediction logic simplified for brevity
                local currentPos = targetPos
                local timeNow = os.clock()
                local vel = vector.create(0,0,0)
                if TargetCache.Part == activeTargetPart and TargetCache.LastPos then
                    local dt = timeNow - TargetCache.LastUpdate
                    if dt > 0 then vel = (currentPos - TargetCache.LastPos) * (1/dt) end
                end
                TargetCache.Part = activeTargetPart; TargetCache.LastPos = currentPos; TargetCache.LastUpdate = timeNow
                
                if Settings.PredictionMode == "Combined" then
                    targetPos = targetPos + (vel * Settings.PredAmount)
                else
                    local pVec = vector.create(vel.X * Settings.PredHorizontal, vel.Y * Settings.PredVertical, vel.Z * Settings.PredHorizontal)
                    targetPos = targetPos + pVec
                end
            end
            Camera.LookVector = vector.normalize(targetPos - Camera.Position) * -1
        end
    end

    -- Start Auto Cache
    task.spawn(function() task.wait(1); BuildMapCache() end)

    return {
        Update = Update,
        CacheMap = function() task.spawn(BuildMapCache) end
    }
end

return Module
