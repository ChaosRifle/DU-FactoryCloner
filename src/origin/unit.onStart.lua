--system.print(tableIO.tableToString(core.getElementIndustryInfoById(slot3.getLocalId())))
local version = 'v1.1.0'

local sourceInfo1 = 'Chaos FactoryCloner: ' .. version
local sourceInfo2 = 'https://github.com/ChaosRifle/DU-FactoryCloner'
system.print(sourceInfo1)
system.print(sourceInfo2)
local opLimit = 2000 --export: number of calls per second. warning: does not smooth operations over the course of that second!
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
local tableEntryCount = 0
local Progress = 0
ProgressPercent = 0
local searchListSize = #elementIdList
local dbLimit = 23300 --export: character cap for DB block. its possible a server may change this. def 30000
local expectedDBEntryCost = 47 + 1 --export: number of chars per entry, after compression. No compression = 48*entries + 2 for the main table {}
local entriesPerDB = math.floor((dbLimit - 2) / expectedDBEntryCost) - 1
system.print(table.concat({'attempting ',entriesPerDB,' entries per DB'}))
local entyCap = 9999
local requiredNumberOfDB


local databanks = {}
for slotName in pairs(unit) do
    if type(unit[slotName])=='table' and  slotName~= nil and unit[slotName].getClass ~= nil and slotName~='system' and slotName~='library' and slotName~='unit' and slotName~='export' then
        if string.find(slotName, 'DB', 0) then
            databanks[#databanks +1] = slotName
            --system.print('DB found: ' .. slotName)
        end
    end
end
for _,slot in pairs(databanks) do
    unit[slot].clear()
    system.print(unit[slot].getNbKeys() .. ' entries detected')
    system.print(table.concat({unit[slot].getName(),' (', slot, ') has been cleared.'}))
end
system.print('all ' .. #databanks  .. ' connected databanks cleared')


function DataGather()
    for key, elementId in pairs(elementIdList) do
        coRoIndex = coRoIndex + 1
        Progress = Progress + 1
        ProgressPercent = Progress / searchListSize
        local elementClass = core.getElementClassById(elementId)
        if classList[elementClass] == true then
            local info = core.getElementIndustryInfoById(elementId)
            local mode
            if info.state > 1 and tableEntryCount < entyCap then
                if info.maintainProductAmount == 0.0 then --set to infinite or batches
                    mode = 1 --infinite
                else
                    mode = 2 -- maintain number
                end
                tableEntryCount = tableEntryCount + 1
                industryElementData['s' .. elementId] = {
                    [1] = info.currentProducts[1].id,
                    [2] = mode,
                    [3] = math.ceil(info.maintainProductAmount)
                }
            else
                mode = 0
            end

        end
        if coRoIndex > opLimit then
            coRoIndex = 0
            coroutine.yield()
        end
    end
    GatherComplete = true
    system.print('gather done..')
    system.print('entries: ' .. tableEntryCount)

    local tableSplit = {}
    local output = {}
    do --compression and separation
        local lengthPreCompression = 0
        local lengthPostCompression = 0
        local separatedTableIndex = 0
        local entryIndex = entriesPerDB + 1
        for key, value in pairs(industryElementData) do
            if entryIndex > entriesPerDB then
                system.print('modifying tableindex from: ' .. separatedTableIndex)
                system.print('modifying entryIndex from: ' .. entryIndex)
                separatedTableIndex = separatedTableIndex + 1
                tableSplit[separatedTableIndex] = {}
                entryIndex = 1
            end
            --system.print('tableIndex: '.. separatedTableIndex)
            --system.print('entryIndex: '.. entryIndex)
            --system.print('key: ' .. key)
            --system.print('val datatype: ' .. type(value))
            --system.print('value: ' .. tableIO.tableToString(vaule))
            --system.print('writing on tableindex: ' .. separatedTableIndex)
            --system.print('writing on entryIndex: ' .. entryIndex)
            tableSplit[separatedTableIndex][key] = value
            --system.print(tableIO.tableToString(tableSplit[separatedTableIndex][key]))
            --system.print(tableSplit[separatedTableIndex][key][1])
            --system.print('--------------')
            entryIndex = entryIndex + 1
        end
        system.print('number of table splits: ' .. #tableSplit)
        for i=1, #tableSplit do
            system.print('tableSplit i == ' .. i)
            output[i] = tableIO.tableToString(tableSplit[i])--tableIO.tableToString({['test'] = {1,2,4},['test2'] = {2,2,4},['test3'] = {3,2,4},['test4'] = {4,2,4},})
            --system.print(tableIO.tableToString(tableSplit[i]))
            --system.print('-output-')
            --system.print(output[i])
            system.print('uncompressed length: ' .. string.len(output[i]))
            lengthPreCompression = lengthPreCompression + string.len(output[i])

            local substitutions = {
                [" = "] = "=",
                ["{ "] = "{",
                [",  "] = ",",
                [" }"] = "}",
            }
            output[i] = string.gsub(output[i], ' = ', '=')
            --output[i] = string.gsub(output[i], ', ', ',')

            --system.print(output[i])
            --for key,value in pairs(substitutions) do
            --    output = string.gsub(output, key, value)
            --end
            local entryLength = string.len(output[i])
            system.print('compressed length: ' .. entryLength)
            if  entryLength > dbLimit then
                system.print('ERROR! expectedDBEntryCost IS SET TOO LOW, VALUE EXCEEDED dbLimit. YOUR COMPRESSION ESTIMATES OR DB LIMIT IS WRONG')
                system.print(table.concat({'expected number <= ', dbLimit, ', got ', entryLength}))
                unit.exit()
            end
            lengthPostCompression = lengthPostCompression + entryLength
            system.print('------')
        end
        system.print('total uncompressed length: ' .. lengthPreCompression)
        system.print('total compressed length: ' .. lengthPostCompression)
        system.print('total compression ratio: ' .. lengthPreCompression / lengthPostCompression)
    end


    do --distribution
        requiredNumberOfDB = #output --math.ceil(tableEntryCount / entriesPerDB)
        system.print(#databanks .. ' databanks found, ' .. requiredNumberOfDB .. ' total databanks required ')
        if #databanks >= requiredNumberOfDB then
            for i=1, requiredNumberOfDB do
                system.print('i: ' .. i)
                system.print('databank: ' .. databanks[i] .. ' will have a length of ' .. string.len(output[i]))
                system.print('type: ' .. type(output[i]))
                unit[databanks[i]].setStringValue('Industry', output[i])

                --DB.setStringValue('Industry',output)
                --screen.setRenderScript(output)
            end
            system.print('COMPLETE!')
        else
            system.print('ERROR! YOU NEED MORE DATABANKS OR DID NOT NAME THEM!')
        end

    end
    --screen2.setRenderScript(test)
    --system.print(tableIO.tableToString(test))

    system.print(sourceInfo1)
    system.print(sourceInfo2)
    unit.exit()
end
DataGather = coroutine.create(DataGather)
unit.setTimer('second',1)


