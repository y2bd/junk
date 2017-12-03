local http = require "socket.http"
local READ = 'http://52.229.27.179:9232/board'
local WRITE = 'http://52.229.27.179:9232/submitboard?data='

local Net = {};

function split(str, pat)
    local t = {}
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
       if s ~= 1 or cap ~= "" then
          table.insert(t,cap)
       end
       last_end = e+1
       s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
       cap = str:sub(last_end)
       table.insert(t, cap)
    end
    return t
 end

local getBoard = function () 
    local body, status, headers = http.request(READ)
    if (status ~= 200) then
        print("got a bad status on read " .. tostring(status))
        return -1
    end

    local data = split(body, ",")

    if #data ~= 4 then
        print("got malformed data of not length 3 on read")
        return -1
    end

    return data[1], data[2], data[3], data[4]
end

local saveBoard = function(boardId, timestamp, name, boardData)
    local params = tostring(boardId) .. "," .. tostring(timestamp) .. "," .. tostring(name) .. "," .. tostring(boardData)
    local body, status, headers = http.request(WRITE .. params)
    if (status ~= 200) then
        print("got a bad status on read " .. tostring(status))
        return -1
    end
end

Net.getBoard = getBoard
Net.saveBoard = saveBoard

return Net