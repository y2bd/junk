local tick = require('lib/tick/tick')
local Window = require("window")

local Framerate = {
    slow = false
}

local FRAMERATE_FILE = 'framerate.data'

Framerate.initialize = function()
    if love.filesystem.getInfo(FRAMERATE_FILE) then
        Framerate.slow = true
        love.run = tick.run
    end
end

Framerate.keyPressed = function(key, scan, isrepeat)
    if key == 'f7' and not isrepeat then
        Framerate.slow = not Framerate.slow
        if Framerate.slow then
            local data = 'slow_down'
            love.filesystem.write(FRAMERATE_FILE, data, #data)
        else
            love.filesystem.remove(FRAMERATE_FILE)
        end

        Window.save()
        love.event.quit('restart')
    end
end

Framerate.initialize()

return Framerate
