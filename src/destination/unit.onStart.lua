local version = 'v1.1.1'

local sourceInfo1 = 'Chaos FactoryCloner: ' .. version
local sourceInfo2 = 'https://github.com/ChaosRifle/DU-FactoryCloner'
system.print(sourceInfo1)
system.print(sourceInfo2)

local Progress = 0
ProgressPercent = 0
local searchListSize = 0
--system.print(tableIO.tableToString(unit))
local opLimit = 200 --export: operations per second
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

local databanks = {}
for slotName in pairs(unit) do
    if type(unit[slotName])=='table' and slotName~= nil and unit[slotName].getClass ~= nil and unit[slotName].getClass() == 'DataBankUnit' then
        --if string.find(slotName, 'DB', 0) then
            databanks[#databanks +1] = slotName
            --system.print('DB found: ' .. slotName)
        --end
    end
end
system.print(#databanks .. ' databanks found')
local importTable = {}
for i=1, #databanks do
    if unit[databanks[i]].hasKey('Industry') then
        --system.print(databanks[i] .. ' has key!')
        local decompressionString = unit[databanks[i]].getStringValue('Industry')
        --system.print('compressed length: ' .. string.len(decompressionString))
        --system.print(decompressionString)
        do --decompression, this MUST be the inverse of the origin script compression!
            local substitutions = {
                [" = "] = "=",
                ["{ "] = "{",
                [",  "] = ",",
                [" }"] = "}",
            }
            decompressionString = string.gsub(decompressionString, '=', ' = ')
            --decompressionString = string.gsub(decompressionString, ',', ', ')
        end
        importTable[#importTable + 1] = tableIO.stringToTable(decompressionString)
        --system.print(tableIO.tableToString(importTable[#importTable]))
    end
end
local industryData = importTable[1]
--system.print('step1:')
--system.print(tableIO.tableToString(industryData))
for i=2, #importTable do
    for key,value in pairs(importTable[i]) do
        --system.print('k: ' .. key)
        --system.print(value)
        industryData[key] = value
    end
    --system.print('step' .. i .. ':')
    --system.print(tableIO.tableToString(industryData))
end
--system.print('completed import:')
--system.print(tableIO.tableToString(industryData))

--system.print('==================')
--system.print(type(industryData['s83']))
--system.print(industryData['s83'][1])
--system.print(tableIO.tableToString(industryData['s83']))
--local tempindust = tableIO.tableToString(industryData)
--system.print(tempindust)
--system.print('total length of import after decompression: ' .. string.len(tempindust))

local slotTable = {}
function WriteData()
    for slotName in pairs(unit) do
        --coRoIndex = coRoIndex + 1
        --system.print('slotOp: ' .. coRoIndex)
        --if coRoIndex > opLimit then
        --    coRoIndex = 0
        --    coroutine.yield()
        --end

        if type(unit[slotName])=='table' and slotName~= nil and unit[slotName].getClass ~= nil and unit[slotName].getClass() ~= 'DataBankUnit' and unit[slotName].getClass() ~= 'CoreUnitDynamic' and slotName~='system' and slotName~='library' and slotName~='unit' and slotName~='export' then
            slotTable[#slotTable + 1] = slotName
            --system.print('added ' .. unit[slotName].getName() .. ' to the table as ' .. slotName .. ' and class of ' .. unit[slotName].getClass())
        end
    end
    system.print('slot table generated: ' .. #slotTable)
    if slotTable == {} then
        system.print('ERROR: NO INDUSTRY CONNECTED!! THIS SCRIPT WRITES TO LINKED INDUSTRY UNITS!')
        unit.exit()
    else
        --system.print('slot table: ' .. tableIO.tableToString(slotTable))
    end

    searchListSize = #slotTable
    local slotWriteIndex = 0
    system.print('starting write:')
    for key, slot in pairs(slotTable) do
        coRoIndex = coRoIndex + 1
        if coRoIndex > opLimit then
            coRoIndex = 0
            coroutine.yield()
        end
        slotWriteIndex = slotWriteIndex + 1
        ProgressPercent = slotWriteIndex / searchListSize

        if classList[unit[slot].getClass()] then
            local id = unit[slot].getLocalId()
            local sid = 's' .. id
            if industryData[sid] then
                if unit[slot].getState() == 1 then
                    unit[slot].setOutput(industryData[sid][1])
                    if industryData[sid][2] == 2 then --maintain
                        unit[slot].startMaintain(industryData[sid][3])
                    elseif industryData[sid][2] == 1 then --infinite
                        unit[slot].startRun()
                    elseif industryData[sid][2] == 0 then --off
                    end
                else --industry not stopped!
                    system.print(id .. ' UNIT IS NOT STOPPED SO WAS NOT WRITTEN. state currently is ' .. unit[slot].getState())
                end
            else --sid not in table!
                system.print('connections sid not found in master table: ' .. sid)
            end
        else --not of industry classlist type!
            system.print('class not in industry: ' .. unit[slot].getClass() .. ' - id: ' .. id)
        end
    end
    DataWriteComplete = true
    system.print('COMPLETE!')
    system.print(sourceInfo1)
    system.print(sourceInfo2)
    unit.exit()
end

WriteData = coroutine.create(WriteData)
unit.setTimer('second',1)

