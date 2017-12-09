local Save = {}

local SAVE_FILE = "save.data"

Save.save = function(username)
    local saveData = username
    love.filesystem.write(SAVE_FILE, saveData, #saveData)
end

Save.isAwesome = function()
    if love.filesystem.exists(SAVE_FILE) then
        local contents = love.filesystem.read(SAVE_FILE)
        if contents ~= nil then return contents
        else return false end
    else return false end
end

return Save
