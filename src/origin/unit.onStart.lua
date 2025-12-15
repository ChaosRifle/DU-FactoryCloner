--system.print(tableIO.tableToString(core.getElementIndustryInfoById(slot3.getLocalId())))

local opLimit = 200
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
                    industryElementData['s' .. elementId] = {
                        ['item'] = info.currentProducts[1].id,
                        ['maintain'] = info.maintainProductAmount,
                        ['mode'] = mode
                    }
                else
                    mode = 0
                end

            end
    end
    GatherComplete = true
    
    
    local output = tableIO.tableToString(industryElementData)
    DB.setStringValue('Industry',output)
    system.print('COMPLETE!')
    --system.print(output)
    unit.exit()
end
DataGather = coroutine.create(DataGather)
unit.setTimer('second',1)
