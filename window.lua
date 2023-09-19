local String = require 'stringutil'

local Window = {}

local WINDOW_FILE = 'window.data'

Window.initialize = function()
    local fileInfo = love.filesystem.getInfo(WINDOW_FILE)
    if fileInfo then
        local contents = love.filesystem.read(WINDOW_FILE)
        local windowArr = String.split(contents, ',')

        local x = windowArr[1]
        local y = windowArr[2]
        local display = windowArr[3]

        love.window.setMode(640, 640, {
            x = tonumber(x),
            y = tonumber(y),
            display = tonumber(display)
        })
    else
        love.window.setMode(640, 640)
    end

    love.window.setTitle("Junk (for LD40)")
end

Window.save = function()
    local x, y, display = love.window.getPosition()

    local windowStr = string.format('%d,%d,%d', x, y, display)
    love.filesystem.write(WINDOW_FILE, windowStr, #windowStr)
end

return Window
