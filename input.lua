local Input = {}

Input.MAX_INPUT_BUFFER = 1
Input.REPEAT_DELAY = 0.2

Input.VALID_KEYS = {
    left = true,
    right = true,
    up = true,
    down = true,
    z = true,
    x = true,
    escape = true,
}

Input.TYPING_KEYS = {
    a=true,
    c=true,
    b=true,
    d=true,
    e=true,
    f=true,
    g=true,
    h=true,
    i=true,
    j=true,
    k=true,
    l=true,
    m=true,
    n=true,
    o=true,
    p=true,
    q=true,
    r=true,
    s=true,
    t=true,
    u=true,
    v=true,
    w=true,
    x=true,
    y=true,
    z=true,
    ["1"]=true,
    ["2"]=true,
    ["3"]=true,
    ["4"]=true,
    ["5"]=true,
    ["6"]=true,
    ["7"]=true,
    ["8"]=true,
    ["9"]=true,
    ["0"]=true,
}

Input.BUFFERABLE_KEYS = {
    left = true,
    right = true,
    down = true,
}

Input.down = {}
Input.downtime = {}

local function keyPressed (key, scan, dorepeat)
    Input.down[key] = true
    Input.downtime[key] = 0
end
Input.keyPressed = keyPressed

local function keyReleased (key)
    Input.down[key] = nil
    Input.downtime[key] = nil
end
Input.keyReleased = keyReleased

local function pollInput (key) 
    return Input.down[key] == true
end
Input.pollInput = pollInput

local function updatePost (dt)
    for k, v in pairs(Input.down) do
        Input.down[k] = false
        Input.downtime[k] = Input.downtime[k] + dt

        if Input.BUFFERABLE_KEYS[k] == true and Input.downtime[k] >= Input.REPEAT_DELAY then
            Input.down[k] = true
        end
    end
end
Input.updatePost = updatePost

return Input