local Input = {}

Input.MAX_INPUT_BUFFER = 1

Input.VALID_KEYS = {
    left = true,
    right = true,
    up = true,
    down = true,
    z = true,
    x = true,
}

Input.BUFFERABLE_KEYS = {
    left = true,
    right = true,
    down = true,
}

Input.bufferedInputs = {}
Input.bufferedInputIndex = 1

local function keyPressed (key, scan, dorepeat)
    if Input.VALID_KEYS[key] and (not dorepeat or Input.BUFFERABLE_KEYS[key]) then 
        Input.bufferedInputs[#Input.bufferedInputs + 1] = key
    end

    if #Input.bufferedInputs - Input.bufferedInputIndex > Input.MAX_INPUT_BUFFER then
        Input.bufferedInputIndex = #Input.bufferedInputs - Input.MAX_INPUT_BUFFER
    end
end
Input.keyPressed = keyPressed

local function pollInput (key) 
    if Input.bufferedInputs[Input.bufferedInputIndex] == key then
        Input.bufferedInputIndex = Input.bufferedInputIndex + 1
        return true
    end
    
    return false
end
Input.pollInput = pollInput

return Input