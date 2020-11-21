class 'RacingShared'

require('__shared/checkpoint')
require('__shared/util/emitter_helper')

local tracks = {
    ['Levels/MP_007/MP_007'] = { 'mp_007/airport' },
    ['Levels/MP_011/MP_011'] = { 'mp_011/seine' },
    ['Levels/MP_013/MP_013'] = { 'mp_013/quarry' },
    ['Levels/MP_017/MP_017'] = { 'mp_017/canals' },
    ['Levels/MP_018/MP_018'] = { 'mp_018/invasion' },
    ['Levels/XP3_Alborz/XP3_Alborz'] = { 'xp3_alborz/mountain' },
    ['Levels/XP5_003/XP5_003'] = { 'xp5_003/offroad' },
    ['Levels/XP5_004/XP5_004'] = { 'xp5_004/pipeline' },
}

-- Partitions containing spawn points which will be moved to the track's spawns
local spawnPartitions = {
    ['C458603F-BFB2-4248-BC04-9CB496CA956B'] = true, -- Levels/MP_007/TeamDeathmatch_Logic
    ['39AB109C-E3A3-4882-BD1F-901B763A9E1E'] = true, -- Levels/MP_011/TeamDeathmatch_01_Logic
    ['23964A80-7509-4F19-9E67-916FE44114EF'] = true, -- Levels/MP_013/TeamDeathmatch_Logic
    ['821FBE42-A891-4490-A12C-54FA980A84B5'] = true, -- Levels/MP_017/TDM_Logic
    ['BA806334-EF6F-4F5B-AFD3-7EB387C4B3AA'] = true, -- Levels/MP_018/TeamDeathmatch_Logic
    ['37ED954B-DBA7-4B4A-9DB2-02D09D43D0C1'] = true, -- Levels/XP3_Alborz/TDM_Logic
    ['78F42633-9834-44DC-8E8F-55E2D6908D9A'] = true, -- Levels/XP5_002/DM_Shared
    ['0AAC29B8-7499-48C5-9441-E4434B278716'] = true, -- Levels/XP5_003/DM_Shared
    ['561069E9-40A1-470C-9C71-3E29A5D602C9'] = true, -- Levels/XP5_004/DM_Shared
}

-- TDM usually blocks off the play area with static model groups, we don't want those
local staticModelGroupsToRemove = {
    ['F372480F-7C8D-48B5-9133-3ECFC0F1D8A9'] = Guid('25A6B6AD-1F49-EEEF-3D2A-EFE9B5FB96FF'), -- Levels/MP_007/TeamDeathmatch
    ['15ECEAFB-8ED0-4CB2-B150-EB0DFBFB86D7'] = Guid('96AC25CA-666D-7E6A-A808-8283DAB3EC0B'), -- Levels/MP_011/TeamDeathmatch_01
    ['B24034BE-6980-4EA7-AAC3-65261891C0B0'] = Guid('763C9E20-D2E7-CA84-2385-041BDCCBEF58'), -- Levels/MP_013/TeamDeathmatch
    ['BF04112A-BD58-42D4-B5CB-57BB8B6D66DA'] = Guid('539648D4-B541-9642-8AD7-D63882FF7393'), -- Levels/MP_017/TDM
    ['33EBD9D3-5F5B-4668-B2D2-330B97753C90'] = Guid('DCD36D63-6F51-D21A-31B2-B65FADC95F81'), -- Levels/MP_018/TeamDeathmatch
    ['084CF593-D6A5-42C0-A503-93373FA412D6'] = Guid('949A07CF-E4C0-0439-66FB-EBDF5F5EF841'), -- Levels/XP5_002/TDM
    ['3AFAB808-F90A-492F-9659-B9DB8E9C7BA7'] = Guid('3DE17DFB-E9B1-60A9-08EB-7063F21EF142'), -- Levels/XP5_002/DM
    ['65413D06-8113-49B7-BC73-506CC3E34372'] = Guid('0168FC07-C3C4-09C5-510B-0F7AB9F26CC4'), -- Levels/XP5_003/TDM
    ['DD29B28D-31AE-48A8-A781-ADECCA0D6A62'] = Guid('110A3310-20BB-E7E7-583E-5462C4BA1079'), -- Levels/XP5_003/DM
    ['445E676C-BF09-4E7A-BC69-172DDB479918'] = Guid('6B3AF92E-4C07-0E50-C967-65A495AAB0F3'), -- Levels/XP5_004/TDM
    ['B1C0033B-E684-42E9-83DC-3304B867ECED'] = Guid('10C74383-2235-6BE8-E4B6-FDA4832934DA'), -- Levels/XP5_004/DM
}

function RacingShared:__init()
    print('Initializing shared module')

    self.track = nil
    self.checkpoints = {}

    Events:Subscribe('Level:LoadResources', function()
        print('Mounting additional super bundles')

        --ResourceManager:MountSuperBundle('SpChunks')

        -- Quad bike
        --ResourceManager:MountSuperBundle('xp3chunks')
        --ResourceManager:MountSuperBundle('levels/xp3_alborz/xp3_alborz')

        -- Dirt bike
        ResourceManager:MountSuperBundle('xp5chunks')
        ResourceManager:MountSuperBundle('levels/xp5_002/xp5_002')
    end)

    Hooks:Install('ResourceManager:LoadBundles', 100, function(hook, bundles, compartment)
        --print('Loading bundle')
        --print(bundles)

        if #bundles == 1 and bundles[1] == SharedUtils:GetLevelName() then
            print('Loading additional bundles')

            bundles = {
                bundles[1]
            }

            --if SharedUtils:GetLevelName() ~= 'Levels/XP3_Alborz/XP3_Alborz' then
            --    table.insert(bundles, 'Levels/XP3_Alborz/XP3_Alborz')
            --end
            --table.insert(bundles, 'Levels/XP3_Alborz/ConquestLarge01')

            if SharedUtils:GetLevelName() ~= 'Levels/XP5_002/XP5_002' then
                table.insert(bundles, 'levels/xp5_002/xp5_002')
            end
            table.insert(bundles, 'Levels/XP5_002/CQL')

            --print(bundles)

            hook:Pass(bundles, compartment)
        end
    end)

    Hooks:Install('Terrain:Load', 100, function(hook, terrainName)
        --print('Terrain:Load: ' .. terrainName)
        if (SharedUtils:GetLevelName() ~= 'Levels/XP3_Alborz/XP3_Alborz' and terrainName == 'levels/mp_whitepeak/terrain/terrain.streamingtree')
                or (SharedUtils:GetLevelName() ~= 'Levels/XP5_002/XP5_002' and terrainName == 'levels/xp5_002/xp5_002_terrain/xp5_002_terrain.streamingtree')
        then
            --print('Not loading terrain ' .. terrainName)
            hook:Return()
        end
    end)

    Hooks:Install('VisualTerrain:Load', 100, function(hook, terrainName)
        --print('VisualTerrain:Load: ' .. terrainName)
        if (SharedUtils:GetLevelName() ~= 'Levels/XP3_Alborz/XP3_Alborz' and terrainName == 'levels/mp_whitepeak/terrain/terrain.visual')
                or (SharedUtils:GetLevelName() ~= 'Levels/XP5_002/XP5_002' and terrainName == 'levels/xp5_002/xp5_002_terrain/xp5_002_terrain.visual')
        then
            --print('Not loading visual terrain ' .. terrainName)
            hook:Return()
        end
    end)

    Events:Subscribe('Level:RegisterEntityResources', self, self.RegisterEntityResources)

    Events:Subscribe('Level:Destroy', self, self.Destroy)

    Events:Subscribe('Engine:Message', self, self.OnEngineMessage)
    Events:Subscribe('Partition:Loaded', self, self.OnPartitionLoaded)

    self.entityCreateHook = Hooks:Install('EntityFactory:Create', 100, function(hookCtx, entityData, _)
        -- Make the entire map accessible
        if entityData:Is(CombatAreaTriggerEntityData.typeInfo.name) or entityData:Is(FriendZoneEntityData.typeInfo.name) then
            hookCtx:Return()
        end
    end)
end

function RacingShared:RegisterEntityResources()
    print('Adding additional registries')

    -- Levels/XP3_Alborz/ConquestLarge01
    --ResourceManager:AddRegistry(RegistryContainer(ResourceManager:FindInstanceByGuid(Guid('3D4CEA4D-3B86-4253-9841-3257927FAB53'), Guid('133F6403-333F-27C6-7C68-19BB4CA87882'))), ResourceCompartment.ResourceCompartment_Game)

    -- Levels/XP5_002/CQL
    ResourceManager:AddRegistry(RegistryContainer(ResourceManager:FindInstanceByGuid(Guid('EDBFB91A-F8EA-492D-A5FA-39D6AC2DC525'), Guid('421454A2-6F76-B4C6-7240-322C71D8DDAB'))), ResourceCompartment.ResourceCompartment_Game)
end

function RacingShared:OnEngineMessage(message)
    if message.type == MessageType.ClientLevelFinalizedMessage or message.type == MessageType.ServerLevelLoadedMessage then
        self:OnLoad()
    end
end

function RacingShared:OnLoad()
    self:ModifyInstances()

    self.checkpoints = {}

    self:SpawnCheckpoints()
end

function RacingShared:Destroy()
    self.track = nil
    self.checkpoints = {}
end

function RacingShared:OnPartitionLoaded(partition)
    if self.track == nil and SharedUtils:GetLevelName() ~= nil then
        local levelTracks = tracks[SharedUtils:GetLevelName()]
        if levelTracks == nil or #levelTracks <= 0 then
            print('No tracks available for ' .. SharedUtils:GetLevelName())
            self.track = { name = SharedUtils:GetLevelName(), checkpoints = {}, spawns = {} }
        else
            local trackName = levelTracks[MathUtils:GetRandomInt(1, #levelTracks)]
            self.track = require('__shared/tracks/' .. trackName)
            print('Loaded track \'' .. self.track.name .. '\'')
        end
    end

    local partitionGuidString = partition.guid:ToString('D')

    if spawnPartitions[partitionGuidString] then
        if self.track == nil or #self.track.spawns <= 0 then
            -- Leave spawn points where they are
            return
        end

        print('Adjusting spawns')

        for _, instance in pairs(partition.instances) do
            if instance:Is('AlternateSpawnEntityData') then
                local spawn = AlternateSpawnEntityData(instance)
                spawn:MakeWritable()
                spawn.transform = self.track.spawns[MathUtils:GetRandomInt(1, #self.track.spawns)]
            end
        end
    end

    if staticModelGroupsToRemove[partitionGuidString] ~= nil then
        print('Removing static model group ' .. partitionGuidString)
        local staticModelGroup = StaticModelGroupEntityData(partition:FindInstance(staticModelGroupsToRemove[partitionGuidString]))
        staticModelGroup:MakeWritable()
        staticModelGroup.enabled = false
        staticModelGroup.memberDatas:clear()
    end
end

function RacingShared:ModifyInstances()
    print('Modifying instances')

    local blueprint = VehicleBlueprint(ResourceManager:SearchForDataContainer('Vehicles/XP5/KLR650/KLR650'))
    blueprint:MakeWritable()
    local vehicle = VehicleEntityData(blueprint.object)
    vehicle:MakeWritable()
    -- Do not allow leaving the vehicle under any circumstance
    vehicle.exitAllowed = false
    vehicle.throwOutSoldierInsideOnWaterDamage = false
    -- Just immediately explode underwater
    vehicle.belowWaterDamageDelay = 0
    vehicle.waterDamageOffset = 1
    vehicle.waterDamage = 10000
    -- Pretty much disable critical damage
    vehicle.disabledDamageThreshold = 1

    print('Instances modified')
end

function RacingShared:SpawnCheckpoints()
    print('Spawning ' .. #self.track.checkpoints .. ' checkpoints...')

    -- FX/Ambient/Generic/FireSmoke/Fire/Generic/Emitter_L/Em_Amb_Generic_Fire_Embers_L_02
    local fire = EffectEntityData(ResourceManager:FindInstanceByGuid(Guid('9798695A-DA55-46E4-9CAF-C9E393B43EC1'), Guid('425C6B56-E117-4E8B-90CF-D21DA3E02C3B')))
    fire = fire:Clone()
    fire:MakeWritable()
    fire.components:erase(9) -- smoke
    fire.components:erase(8) -- directional fire
    fire.components:erase(6) -- visual environment
    fire.components:erase(5) -- smoke
    fire.components:erase(4) -- directional fire

    for i, component in pairs(fire.components) do
        if component:Is('EmitterEntityData') then
            local emitterEntityData = EmitterHelper:Clone(EmitterEntityData(component))
            local emitterDocument = EmitterDocument(emitterEntityData.emitter)
            if emitterDocument.templateData ~= nil then
                local emitterTemplateData = EmitterTemplateData(emitterDocument.templateData)
                emitterTemplateData:MakeWritable()
                emitterTemplateData.name = 'Ry/Racing/Checkpoint/Emitter_' .. tostring(i)
                emitterTemplateData.killParticlesWithEmitter = false
                emitterTemplateData.actAsPointLight = false

                local spawnRateData = EmitterHelper:FindData(emitterTemplateData.rootProcessor, SpawnRateData)
                if spawnRateData ~= nil then
                    spawnRateData:MakeWritable()
                    spawnRateData.spawnRate = spawnRateData.spawnRate * 10
                end

                local updateAgeData = EmitterHelper:FindData(emitterTemplateData.rootProcessor, UpdateAgeData)
                if updateAgeData ~= nil then
                    updateAgeData:MakeWritable()
                    updateAgeData.lifetime = updateAgeData.lifetime * 0.5
                end

                local spawnPositionData = EmitterHelper:FindData(emitterTemplateData.rootProcessor, SpawnPositionData)
                if spawnPositionData ~= nil then
                    spawnPositionData:MakeWritable()
                    local sphere = SphereEvaluatorData()
                    sphere.radius = 8
                    sphere.scale = Vec3(1, 0, 1)
                    spawnPositionData.pre = sphere
                end
            end

            fire.components:erase(i)
            fire.components:insert(i, emitterEntityData)
        end
    end

    for i, transform in pairs(self.track.checkpoints) do
        self.checkpoints[i] = RacingCheckpoint(i, transform, i == 1, i == #self.track.checkpoints, fire)
    end

    print('Spawned checkpoints')
end

g_RacingShared = RacingShared()
