local String = require "stringutil"

local http = require "socket.http"
local READ = 'http://52.229.27.179:9232/board'
local WRITE = 'http://52.229.27.179:9232/submitboard?data='

local Net = {};

local getBoard = function()
    local body, status, headers = http.request(READ)
    if (status ~= 200) then
        print("got a bad status on read " .. tostring(status))
        return -1
    end

    local data = String.split(body, ",")

    if #data ~= 4 then
        print("got malformed data of not length 3 on read")
        return -1
    end

    return data[1], data[2], data[3], data[4]
end

local saveBoard = function(boardId, timestamp, name, boardData)
    local params = tostring(boardId) .. "," .. tostring(timestamp) .. "," .. tostring(name) .. "," ..
                       tostring(boardData)
    local body, status, headers = http.request(WRITE .. params)
    if (status ~= 200) then
        print("got a bad status on read " .. tostring(status))
        return -1
    end
end

Net.getBoard = getBoard
Net.saveBoard = saveBoard

return Net
