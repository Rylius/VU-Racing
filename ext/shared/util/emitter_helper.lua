class 'EmitterHelper'

function EmitterHelper:Clone(sourceEmitterEntityData)
    local emitterEntityData = EmitterEntityData(sourceEmitterEntityData):Clone(MathUtils:RandomGuid())
    emitterEntityData:MakeWritable()

    if emitterEntityData.emitter == nil then
        return emitterEntityData
    end
    local emitterDocument = EmitterDocument(emitterEntityData.emitter):Clone()
    emitterDocument:MakeWritable()
    emitterEntityData.emitter = emitterDocument

    if emitterDocument.templateData == nil then
        return emitterEntityData
    end
    local emitterTemplateData = EmitterTemplateData(emitterDocument.templateData):Clone()
    emitterTemplateData:MakeWritable()
    emitterDocument.templateData = emitterTemplateData

    if emitterTemplateData.rootProcessor == nil then
        return emitterEntityData
    end
    local rootProcessor = ProcessorData(emitterTemplateData.rootProcessor):Clone()
    rootProcessor:MakeWritable()
    emitterTemplateData.rootProcessor = rootProcessor

    local previousProcessorData = rootProcessor
    local currentProcessorData = rootProcessor.nextProcessor
    while currentProcessorData ~= nil do
        local processorData = _G[currentProcessorData.typeInfo.name](currentProcessorData):Clone()
        processorData:MakeWritable()
        previousProcessorData.nextProcessor = processorData

        previousProcessorData = _G[processorData.typeInfo.name](processorData)
        currentProcessorData = processorData.nextProcessor
    end

    return emitterEntityData
end

function EmitterHelper:FindData(processorData, dataType)
    if processorData:Is(dataType.typeInfo.name) then
        return dataType(processorData)
    end

    if processorData.nextProcessor ~= nil then
        return self:FindData(processorData.nextProcessor, dataType)
    end

    return nil
end

EmitterHelper = EmitterHelper()
