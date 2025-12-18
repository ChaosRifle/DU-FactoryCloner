if GatherComplete == false then --and true == false
    system.print(ProgressPercent * 100 .. '% done..')
    coroutine.resume(DataGather)
end

