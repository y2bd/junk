local Keymap = require('keymap')

local Input = {}

Input.MAX_INPUT_BUFFER = 1
Input.REPEAT_DELAY = 0.2

Input.TYPING_KEYS = {
    a = true,
    c = true,
    b = true,
    d = true,
    e = true,
    f = true,
    g = true,
    h = true,
    i = true,
    j = true,
    k = true,
    l = true,
    m = true,
    n = true,
    o = true,
    p = true,
    q = true,
    r = true,
    s = true,
    t = true,
    u = true,
    v = true,
    w = true,
    x = true,
    y = true,
    z = true,
    ["1"] = true,
    ["2"] = true,
    ["3"] = true,
    ["4"] = true,
    ["5"] = true,
    ["6"] = true,
    ["7"] = true,
    ["8"] = true,
    ["9"] = true,
    ["0"] = true
}

Input.BUFFERABLE_KEYS = {
    left = true,
    right = true,
    down = true
}

Input.down = {}
Input.downtime = {}

local function initializeInput()
    Input.keymap = Keymap.loadKeymapFromSaveData()
end
Input.initialize = initializeInput

local function keyPressed(key, scan, dorepeat)
    Input.down[key] = true
    Input.downtime[key] = 0
end
Input.keyPressed = keyPressed

local function keyReleased(key)
    Input.down[key] = nil
    Input.downtime[key] = nil
end
Input.keyReleased = keyReleased

local function pollInput(key, bypassKeymap)
    if bypassKeymap then
        return Input.down[key] == true
    else
        local mappedKey = Input.keymap[key]
        if mappedKey == nil then
            mappedKey = key
        end

        return Input.down[mappedKey] == true
    end
end
Input.pollInput = pollInput

local function updatePost(dt)
    for k, v in pairs(Input.down) do
        Input.down[k] = false
        Input.downtime[k] = Input.downtime[k] + dt

        -- BUFFERABLE_KEYS more corresponds to virtual keys than physical
        -- so we might need to respect the keymap
        -- need to do inverted lookup in keymap
        local bufferableKey = Input.keymap['_' .. k] ~= nil and Input.keymap['_' .. k] or k
        if Input.BUFFERABLE_KEYS[bufferableKey] == true and Input.downtime[k] >= Input.REPEAT_DELAY then
            Input.down[k] = true
        end
    end
end
Input.updatePost = updatePost

return Input
