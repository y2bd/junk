local String = require 'stringutil'

local Keymap = {}

local KEYMAP_FILE = "keymap.data"

Keymap.loadKeymapFromSaveData = function()
    -- move left, move right, hard drop, soft drop, rotate ccw, rotate cw
    local keymapString = 'left,right,up,down,z,x'

    local fileInfo = love.filesystem.getInfo(KEYMAP_FILE)
    if (fileInfo) then
        local contents = love.filesystem.read(KEYMAP_FILE)
        if contents ~= nil then
            keymapString = contents
        end
    else
        love.filesystem.write(KEYMAP_FILE, keymapString, #keymapString)
    end

    local keymapArr = String.split(String.trim(keymapString), ',')

    local keymapTable = {}
    keymapTable.left = keymapArr[1]
    keymapTable.right = keymapArr[2]
    keymapTable.up = keymapArr[3]
    keymapTable.down = keymapArr[4]
    keymapTable.z = keymapArr[5]
    keymapTable.x = keymapArr[6]

    -- store inverted map starting with underscores
    keymapTable['_' .. keymapArr[1]] = 'left'
    keymapTable['_' .. keymapArr[2]] = 'right'
    keymapTable['_' .. keymapArr[3]] = 'up'
    keymapTable['_' .. keymapArr[4]] = 'down'
    keymapTable['_' .. keymapArr[5]] = 'z'
    keymapTable['_' .. keymapArr[6]] = 'x'

    return keymapTable
end

return Keymap
