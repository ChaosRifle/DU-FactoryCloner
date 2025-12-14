--system.print(tableIO.tableToString(core.getElementIndustryInfoById(slot3.getLocalId())))

local opLimit = 20
local elementIdList = core.getElementIdList()
system.print(#elementIdList .. ' Elements detected')
local classList = {
    ['Industry1'] = true,
    ['Industry2'] = true,
    ['Industry3'] = true,
    ['Industry4'] = true,
    ['Industry5'] = true,
    ['IndustryUnit'] = true
}

GatherComplete = false
local coRoIndex = 0
local industryElementData = {}
function DataGather() 
    for key, elementId in pairs(elementIdList) do
            coRoIndex = coRoIndex + 1
            if coRoIndex > opLimit then 
                coRoIndex = 0
                coroutine.yield()
            end
            local elementClass = core.getElementClassById(elementId)
            if classList[elementClass] == true then
                local info = core.getElementIndustryInfoById(elementId)
                local mode
                if info.state > 1 then
                    if info.maintainProductAmount == 0.0 then --set to infinite or batches
                        mode = 1 --infinite
                    else
                        mode = 2 -- maintain number
                    end
                else
                    mode = 0
                end
                industryElementData['s' .. elementId] = { 
                    ['item'] = info.currentProducts[1].id, 
                    ['maintain'] = info.maintainProductAmount, 
                    ['mode'] = mode 
                }
            end
    end
    GatherComplete = true
    
    
    local output = tableIO.tableToString(industryElementData)
    system.print(output)
    DB.setStringValue('Industry',output)
end
DataGather = coroutine.create(DataGather)
unit.setTimer('second',1)
