--system.print(tableIO.tableToString(unit))
local opLimit = 50 --export: operations per second
local coRoIndex = 0
DataWriteComplete = false
local classList = {
    ['Industry1'] = true,
    ['Industry2'] = true,
    ['Industry3'] = true,
    ['Industry4'] = true,
    ['Industry5'] = true,
    ['IndustryUnit'] = true
}
local industryString = DB.getStringValue('Industry')
--system.print(industryString)

local industryData = tableIO.stringToTable(industryString)
system.print(type(industryData))
system.print(tableIO.tableToString(industryData))

local slotTable = {}

function WriteData()
    for slotName in pairs(unit) do
        coRoIndex = coRoIndex + 1
        --system.print('slotOp: ' .. coRoIndex)
        if coRoIndex > opLimit then
            coRoIndex = 0
            coroutine.yield()
        end

        if type(unit[slotName])=='table' and  slotName~= nil and unit[slotName].getClass ~= nil and slotName~='system' and slotName~='library' and slotName~='unit' and slotName~='export' then

            slotTable[#slotTable + 1] = slotName
            system.print('added ' .. unit[slotName].getName() .. ' to the table at ' .. slotName)
        end
    end
    system.print(tableIO.tableToString(slotTable))

    for key, slot in pairs(slotTable) do
        coRoIndex = coRoIndex + 1
        if coRoIndex > opLimit then
            coRoIndex = 0
            coroutine.yield()
        end

        if classList[unit[slot].getClass()] then
            local id = unit[slot].getLocalId()
            local sid = 's' .. id
            if industryData[sid] then
                if unit[slot].getState() == 1 then
                    unit[slot].setOutput(industryData[sid].item)
                    if industryData[sid].mode == 2 then --maintain
                        unit[slot].startMaintain(industryData[sid].maintain)
                    elseif industryData[sid].mode == 1 then --infinite
                        unit[slot].startRun()
                    elseif industryData[sid].mode == 0 then --off
                    end
                else --industry not stopped!
                    system.print(id .. ' unit is not stopped! value is ' .. unit[slot].getState())
                end
            else --sid not in table!
                system.print('connections sid not found in master table: ' .. sid)
            end
        else --not of industry classlist type!
            system.print('class not in industry: ' .. unit[slot].getClass() .. '\n id: ' .. id)
        end
    end
    DataWriteComplete = true
end

WriteData = coroutine.create(WriteData)
unit.setTimer('second',1)
