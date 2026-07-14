function IsAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

--- Oyuncu bu booth'u kontrol edebilir mi (panel açma + tüm aksiyonlar)
---@param src number
---@param booth table
function CanControlBooth(src, booth)
    if not booth then return false end
    if IsAdmin(src) then return true end
    if booth.public then return true end
    if booth.jobs and next(booth.jobs) then
        local job = Bridge.GetJob(src)
        if job then
            local minGrade = booth.jobs[job.name]
            if minGrade ~= nil and job.grade >= minGrade then
                return true
            end
        end
    end
    return false
end
