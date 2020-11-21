class 'RacingCheckpoint'

function RacingCheckpoint:__init(number, transform, start, finish, blueprint)
    self.number = number
    self.transform = transform
    self.start = start
    self.finish = finish
    self.effect = nil

    if SharedUtils:IsClientModule() then
        self.effect = EntityManager:CreateEntity(blueprint, self.transform)
        self.effect:Init(Realm.Realm_Client, true)
    end
end

function RacingCheckpoint:SetActive(active)
    if not SharedUtils:IsClientModule() then
        return
    end

    if self.effect ~= nil then
        if active then
            self.effect:FireEvent('Start')
        else
            self.effect:FireEvent('Stop')
        end
    end
end
