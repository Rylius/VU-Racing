class 'RacingClient'

local debug = false

function RacingClient:__init()
    print('Initializing client module')

    self.lastCheckpoint = nil
    self.nextCheckpoint = nil
    self.track = nil

    Events:Subscribe('Level:Loaded', self, self.OnLoad)
    Events:Subscribe('Level:Destroy', self, self.OnDestroy)

    Events:Subscribe('Extension:Loaded', function()
        WebUI:Init()
        WebUI:Hide()
    end)
end

function RacingClient:OnLoad()
    Events:Subscribe('Client:PostFrameUpdate', self, self.Update)
    Events:Subscribe('Player:UpdateInput', self, self.UpdateInput)

    NetEvents:Subscribe('Checkpoint:Reset', self, self.ResetCheckpoint)
    NetEvents:Subscribe('Checkpoint:Change', self, self.CheckpointChanged)
    NetEvents:Subscribe('Time', self, self.TimeChanged)
    NetEvents:Subscribe('Position', self, self.PositionChanged)
    NetEvents:Subscribe('Scoreboard', self, self.ScoreboardUpdated)

    Hooks:Install('UI:PushScreen', 1, function(hook, screen, priority, parentGraph)
        screen = UIScreenAsset(screen)

        local scoreboardDir = 'UI/Flow/Screen/Scoreboards/'
        if screen.name:sub(1, #scoreboardDir) == scoreboardDir then
            hook:Return(nil)
        end
    end)

    self.lastCheckpoint = nil
    self.nextCheckpoint = nil
    self.track = g_RacingShared.track
    self:ResetCheckpoint()

    WebUI:ExecuteJS('setScoreboardVisible(false)')
    WebUI:ExecuteJS('trackChanged(' .. json.encode({ name = self.track.name, checkpoints = #self.track.checkpoints }) .. ')')

    WebUI:Show()

    NetEvents:SendLocal('Scoreboard')

    if debug then
        Events:Subscribe('UI:DrawHud', self, self.DrawTrack)
    end
end

function RacingClient:OnDestroy()
    Events:Unsubscribe('Client:PostFrameUpdate')
    Events:Unsubscribe('Player:UpdateInput')
    Events:Unsubscribe('UI:DrawHud')

    NetEvents:Unsubscribe()

    WebUI:Hide()

    self.lastCheckpoint = nil
    self.nextCheckpoint = nil
    self.track = nil
end

function RacingClient:ResetCheckpoint()
    self.lastCheckpoint = nil

    if self.nextCheckpoint ~= nil then
        self.nextCheckpoint:SetActive(false)
        self.nextCheckpoint = nil

        local data = {
            number = 0,
            position = Vec2(),
        }
        WebUI:ExecuteJS('updateWaypoint(' .. json.encode(data) .. ')')
    end

    WebUI:ExecuteJS('updateCheckpoint(' .. json.encode({ number = 0 }) .. ')')
end

function RacingClient:CheckpointChanged(newNumber)
    if self.nextCheckpoint ~= nil then
        if self.nextCheckpoint.number == newNumber then
            return
        end

        self.lastCheckpoint = self.nextCheckpoint
        self.nextCheckpoint = nil

        if newNumber >= 1 then
            WebUI:ExecuteJS('checkpointReached(' .. json.encode({ number = self.lastCheckpoint.number }) .. ')')
        end
        self.lastCheckpoint:SetActive(false)
    end

    if newNumber <= 0 then
        self.nextCheckpoint = nil
        return
    end

    if #g_RacingShared.checkpoints > 0 then
        self.nextCheckpoint = g_RacingShared.checkpoints[newNumber]
        self.nextCheckpoint:SetActive(true)
    end

    if self.lastCheckpoint ~= nil then
        WebUI:ExecuteJS('updateCheckpoint(' .. json.encode({ number = self.lastCheckpoint.number }) .. ')')
    else
        WebUI:ExecuteJS('updateCheckpoint(' .. json.encode({ number = 0 }) .. ')')
    end
end

function RacingClient:TimeChanged(data)
    WebUI:ExecuteJS('updateTime(' .. json.encode(data) .. ')')
end

function RacingClient:PositionChanged(data)
    WebUI:ExecuteJS('updatePosition(' .. json.encode(data) .. ')')
end

function RacingClient:ScoreboardUpdated(data)
    for _, entry in ipairs(data) do
        local player = PlayerManager:GetPlayerById(entry.id)
        if player ~= nil then
            entry.name = player.name
        else
            entry.name = '???'
        end
    end

    WebUI:ExecuteJS('updateScoreboard(' .. json.encode(data) .. ')')
end

function RacingClient:Update(_)
    if self.nextCheckpoint ~= nil then
        local data
        local position = ClientUtils:WorldToScreen(self.nextCheckpoint.transform.trans)
        if position == nil then
            data = {
                number = 0,
                position = Vec2(),
                finish = false,
            }
        else
            data = {
                number = self.nextCheckpoint.number,
                position = position,
                finish = self.nextCheckpoint.finish,
            }
        end
        WebUI:ExecuteJS('updateWaypoint(' .. json.encode(data) .. ')')
    end
end

function RacingClient:UpdateInput()
    if debug and InputManager:WentKeyDown(InputDeviceKeys.IDK_Q) then
        local player = PlayerManager:GetLocalPlayer()
        if player == nil or not player.alive or player.soldier == nil then
            return
        end

        local transform = player.soldier.worldTransform
        print(string.format('LinearTransform(Vec3%s, Vec3%s, Vec3%s, Vec3%s)', transform.left, transform.up, transform.forward, transform.trans))
    end

    if InputManager:WentDown(InputConceptIdentifiers.ConceptScoreboard) then
        NetEvents:SendLocal('Scoreboard')
        WebUI:ExecuteJS('setScoreboardVisible(true)')
    elseif InputManager:WentUp(InputConceptIdentifiers.ConceptScoreboard) then
        WebUI:ExecuteJS('setScoreboardVisible(false)')
    end
end

function RacingClient:DrawTrack()
    if self.track == nil then
        return
    end

    local startColor = Vec4(0, 1, 0, 1)
    local endColor = Vec4(1, 0, 0, 1)

    local previousCheckpoint
    for i, checkpoint in ipairs(self.track.checkpoints) do
        local progress = i / #self.track.checkpoints
        local color = Vec4(
                MathUtils:Lerp(startColor.x, endColor.x, progress),
                MathUtils:Lerp(startColor.y, endColor.y, progress),
                MathUtils:Lerp(startColor.z, endColor.z, progress),
                MathUtils:Lerp(startColor.w, endColor.w, progress)
        )

        if previousCheckpoint ~= nil then
            DebugRenderer:DrawLine(previousCheckpoint.trans, checkpoint.trans, color, color)
        end

        local position = ClientUtils:WorldToScreen(checkpoint.trans)
        if position ~= nil then
            DebugRenderer:DrawText2D(position.x, position.y, tostring(i), color, 1)
        end

        previousCheckpoint = checkpoint
    end
end

g_RacingClient = RacingClient()
