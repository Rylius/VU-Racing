class 'RacingServer'

local debug = false

function RacingServer:__init()
    print('Initializing server module')

    self:ResetState()

    Events:Subscribe('Level:Loaded', self, self.OnLoad)
    Events:Subscribe('Level:Destroy', self, self.ResetState)
    Events:Subscribe('Player:Left', self, self.OnPlayerLeft)
end

function RacingServer:__gc()
    Events:Unsubscribe('Level:Loaded')
    Events:Unsubscribe('Level:Destroy')
    Events:Unsubscribe('Player:Left')

    Events:Unsubscribe('Player:Update')
    Events:Unsubscribe('Player:Respawn')
    Events:Unsubscribe('Vehicle:Exit')

    NetEvents:Unsubscribe()
end

function RacingServer:OnLoad()
    Events:Unsubscribe('Player:Update')
    Events:Unsubscribe('Player:Respawn')
    Events:Unsubscribe('Vehicle:Exit')

    NetEvents:Unsubscribe()

    self:ResetState()

    Events:Subscribe('Player:Update', self, self.OnPlayerUpdate)
    Events:Subscribe('Player:Respawn', self, self.OnPlayerRespawn)
    Events:Subscribe('Vehicle:Exit', self, self.OnVehicleExit)

    NetEvents:Subscribe('Scoreboard', self, self.OnScoreboardRequested)
end

function RacingServer:ResetState()
    self.roundLength = 6 * 60
    self.roundStartTime = -1
    self.playerCheckpoints = {}
    self.playerStartTimes = {}
    self.playerCheckpointTimes = {}
    self.playerTrackTimes = {}
    self.scoreboard = {}

    if debug then
        self.playerCheckpointTimes = {
            [9999999] = { [1] = 0, [2] = 7732, [3] = 11599, [4] = 16432, [5] = 21733, [6] = 26667, [7] = 33066, [8] = 38700, [9] = 45499, [10] = 53366, [11] = 58400, [12] = 61732, [13] = 67499, [14] = 72800, [15] = 78932, [16] = 82799, [17] = 88566, [18] = 94299, [19] = 99600, [20] = 103332 }
        }
        self.playerTrackTimes = {
            [9999999] = 120000,
        }
    end
end

function RacingServer:OnPlayerLeft(player)
    self.playerCheckpoints[player.id] = nil
    self.playerStartTimes[player.id] = nil
    self.playerCheckpointTimes[player.id] = nil
    self.playerTrackTimes[player.id] = nil

    self:UpdateRanking()
    self:CheckRoundEnd()
end

function RacingServer:OnPlayerUpdate(player, deltaTime)
    if not player.alive or not player.hasSoldier then
        return
    end

    local checkpoint = self.playerCheckpoints[player.id]
    if checkpoint == nil then
        return
    end

    local distance = player.soldier.worldTransform.trans:Distance(checkpoint.transform.trans)
    if distance < 8 then
        local now = SharedUtils:GetTimeMS()
        local start = now
        if self.playerStartTimes[player.id] ~= nil then
            start = self.playerStartTimes[player.id]
        end
        local time = now - start

        if self.playerCheckpointTimes[player.id] == nil then
            self.playerCheckpointTimes[player.id] = {}
        end
        self.playerCheckpointTimes[player.id][checkpoint.number] = time

        NetEvents:SendToLocal('Time', player, { time = time, running = not checkpoint.finish })

        local finish = checkpoint.finish or checkpoint.number >= #g_RacingShared.checkpoints
        if finish then
            if self.playerTrackTimes[player.id] == nil or self.playerTrackTimes[player.id] > time then
                self.playerTrackTimes[player.id] = time
            end

            print('Player ' .. player.name .. ' reached the finish (' .. tostring(time) .. 'ms)')

            self.playerCheckpoints[player.id] = nil
            self.playerStartTimes[player.id] = nil
            NetEvents:SendToLocal('Checkpoint:Reset', player)

            self:UpdatePlayerCheckpoint(player, g_RacingShared.checkpoints[1])
        else
            print('Player ' .. player.name .. ' reached checkpoint ' .. tostring(checkpoint.number) .. ' (' .. tostring(time) .. 'ms)')

            if checkpoint.number == 1 then
                self.playerStartTimes[player.id] = now
            end

            self:UpdatePlayerCheckpoint(player, g_RacingShared.checkpoints[checkpoint.number + 1])
        end

        self:UpdateRanking()

        --print(self.playerCheckpointTimes)

        if finish then
            self:CheckRoundEnd()
        end
    end
end

function RacingServer:OnPlayerRespawn(player)
    if self.roundStartTime < 0 then
        self.roundStartTime = SharedUtils:GetTime()
    end

    NetEvents:SendToLocal('Checkpoint:Reset', player)
    NetEvents:SendToLocal('Time', player, { time = 0, running = false })

    self:SpawnPlayerVehicle(player)
    if #g_RacingShared.checkpoints > 0 then
        self:UpdatePlayerCheckpoint(player, g_RacingShared.checkpoints[1])
    end

    self:UpdateRanking()
end

function RacingServer:OnVehicleExit(vehicle, player)
    if vehicle ~= nil and player ~= nil then
        self:ForcePlayerIntoVehicle(player, vehicle)
    end
end

function RacingServer:ForcePlayerIntoVehicle(player, vehicle)
    player:EnterVehicle(vehicle, 0)
    player:EnableInput(EntryInputActionEnum.EIAInteract, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeVehicle, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry1, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry2, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry3, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry4, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry5, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry6, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry7, false)
    player:EnableInput(EntryInputActionEnum.EIAChangeEntry8, false)
end

-- Spawn a vehicle in front of a player
function RacingServer:SpawnPlayerVehicle(player)
    if player == nil or not player.hasSoldier then
        return
    end

    local spawnOrigin = player.soldier.worldTransform.trans:Clone()
    spawnOrigin = spawnOrigin + (player.soldier.worldTransform.forward * 3)

    local params = EntityCreationParams()
    params.transform = LinearTransform(
            player.soldier.worldTransform.left,
            player.soldier.worldTransform.up,
            player.soldier.worldTransform.forward,
            spawnOrigin
    )
    params.variationNameHash = 0
    params.networked = true

    -- Vehicles/VDV_Buggy/VDV_Buggy
    --local blueprint = VehicleBlueprint(ResourceManager:FindInstanceByGuid(Guid('2EA804A7-8232-11E0-823A-BD52CA6DC6B3'), Guid('D68E417F-6103-5140-3ABC-4C7505160A09')))

    -- Vehicles/XP3/QuadBike/QuadBike
    --local blueprint = VehicleBlueprint(ResourceManager:FindInstanceByGuid(Guid('08D3686F-A96A-11E1-9047-F3806E4ECBA6'), Guid('AE20A64D-871C-EA34-9931-1162BB8B0242')))

    local blueprint = VehicleBlueprint(ResourceManager:SearchForDataContainer('Vehicles/XP5/KLR650/KLR650'))

    local bus = EntityManager:CreateEntitiesFromBlueprint(blueprint, params)
    if bus ~= nil then
        for _, entity in pairs(bus.entities) do
            entity:Init(Realm.Realm_ClientAndServer, true)
        end
    else
        error('Failed to create player vehicle bus')
    end

    for _, entity in pairs(bus.entities) do
        if entity:Is('ServerVehicleEntity') then
            self:ForcePlayerIntoVehicle(player, entity)
            break
        end
    end
end

function RacingServer:UpdatePlayerCheckpoint(player, checkpoint)
    if checkpoint == nil then
        error('checkpoint is required')
    end

    self.playerCheckpoints[player.id] = checkpoint
    NetEvents:SendToLocal('Checkpoint:Change', player, checkpoint.number)
end

function RacingServer:OnScoreboardRequested(player)
    NetEvents:SendToLocal('Scoreboard', player, self.scoreboard)
end

function RacingServer:UpdateRanking()
    local ranking = {}
    self.scoreboard = {}
    self.finishedPlayers = 0

    local playerCount = PlayerManager:GetPlayerCount()
    if debug then
        playerCount = playerCount + 1
    end
    for _, player in ipairs(PlayerManager:GetPlayers()) do
        ranking[player.id] = playerCount
    end

    local rank = 1
    for playerId, _ in sortedPairs(self.playerTrackTimes, sortTrackTimes) do
        ranking[playerId] = rank
        rank = rank + 1
    end

    for playerId, position in pairs(ranking) do
        local trackTime = self.playerTrackTimes[playerId] or -1
        --print(string.format('%2d: %s (%dms)', position, playerId, trackTime))

        if trackTime >= 0 then
            self.finishedPlayers = self.finishedPlayers + 1
        end

        self.scoreboard[position] = { id = playerId, time = trackTime }

        local player = PlayerManager:GetPlayerById(playerId)
        if player ~= nil then
            NetEvents:SendToLocal('Position', player, { position = position, total = playerCount })
        end
    end
end

function RacingServer:CheckRoundEnd()
    print(string.format('Players who finished: %d', self.finishedPlayers))
    if self.finishedPlayers <= 0 then
        -- At least one player must have finished the track
        return
    end

    -- One player not finishing will prevent the next round, probably a bad idea
    --local playerCount = PlayerManager:GetPlayerCount()
    --if playerCount < 2 or self.finishedPlayers < playerCount then
    --    -- All players must have finished the track
    --    return
    --end

    local roundDuration = SharedUtils:GetTime() - self.roundStartTime
    print(string.format('Round duration: %ds (length: %ds)', roundDuration, self.roundLength))
    if roundDuration < self.roundLength then
        return
    end

    -- Pick a random winning team by default (when something went wrong, basically)
    local winningTeam = ({ TeamId.Team1, TeamId.Team2 })[MathUtils:GetRandomInt(1, 2)]

    local topPosition = self.scoreboard[1]
    if topPosition ~= nil then
        local player = PlayerManager:GetPlayerById(topPosition.id)
        if player ~= nil then
            winningTeam = player.teamId
        end
    end

    TicketManager:SetTicketCount(winningTeam, 1000)
end

function sortedPairs(t, sort)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end

    if sort then
        table.sort(keys, function(a, b)
            return sort(t, a, b)
        end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function sortTrackTimes(t, a, b)
    return t[a] < t[b]
end

g_RacingServer = RacingServer()
