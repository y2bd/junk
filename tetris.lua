local Tetris = {}

--- I
local a = {0,0,0,0,
           1,1,1,1,
           0,0,0,0,
           0,0,0,0}

--- T
local b = {0,2,0,
           2,2,2,
           0,0,0}

--- L
local c = {0,0,3,
           3,3,3,
           0,0,0}

--- J
local d = {4,0,0,
           4,4,4,
           0,0,0}

--- S
local e = {0,5,5,
           5,5,0,
           0,0,0}

--- Z
local f = {6,6,0,
           0,6,6,
           0,0,0}

--- O
local g = {0,0,0,0,
           0,7,7,0,
           0,7,7,0,
           0,0,0,0}

local function fix(arr, width)
    local real = {}
    for i=width+1,width+#arr+1 do
        io.write(i)
        io.write(i-width)
        real[i]=arr[i-width]
    end
    print("")
    return real
end

local pieces = {}
pieces[1] = fix(a, 4)
pieces[2] = fix(b, 3)
pieces[3] = fix(c, 3)
pieces[4] = fix(d, 3)
pieces[5] = fix(e, 3)
pieces[6] = fix(f, 3)
pieces[7] = fix(g, 4)

local sizes = {}
sizes[1] = {4, 4}
sizes[2] = {3, 3}
sizes[3] = {3, 3}
sizes[4] = {3, 3}
sizes[5] = {3, 3}
sizes[6] = {3, 3}
sizes[7] = {4, 4}

local colors = {}
colors[1] = {255, 0, 0}
colors[2] = {255, 255, 0}
colors[3] = {255, 0, 255}
colors[4] = {0, 255, 0}
colors[5] = {0, 255, 255}
colors[6] = {0, 0, 255}
colors[7] = {255, 255, 255}

love.graphics.setDefaultFilter("nearest", "nearest", 1)
local imgs = {}
imgs[1] = love.graphics.newImage("assets/01.png")
imgs[2] = love.graphics.newImage("assets/02.png")
imgs[3] = love.graphics.newImage("assets/03.png")
imgs[4] = love.graphics.newImage("assets/04.png")
imgs[5] = love.graphics.newImage("assets/05.png")
imgs[6] = love.graphics.newImage("assets/06.png")
imgs[7] = love.graphics.newImage("assets/07.png")

local beamKick = {}
beamKick["12"] = {{0,0},{-2,0},{1,0},{-2,-1},{1,2}}
beamKick["21"] = {{0,0},{2,0},{-1,0},{2,1},{-1,-2}}
beamKick["23"] = {{0,0},{-1,0},{2,0},{-1,2},{2,-1}}
beamKick["32"] = {{0,0},{1,0},{-2,0},{1,-2},{-2,1}}
beamKick["34"] = {{0,0},{2,0},{-1,0},{2,1},{-1,-2}}
beamKick["43"] = {{0,0},{-2,0},{1,0},{-2,-1},{1,2}}
beamKick["41"] = {{0,0},{1,0},{-2,0},{1,-2},{-2,1}}
beamKick["14"] = {{0,0},{-1,0},{2,0},{-1,2},{2,-1}}

local wallKick = {}
wallKick["12"] = {{0,0},{-1,0},{-1,1},{0,-2},{-1,-2}}
wallKick["21"] = {{0,0},{1,0},{1,-1},{0,2},{1,2}}
wallKick["23"] = {{0,0},{1,0},{1,-1},{0,2},{1,2}}
wallKick["32"] = {{0,0},{-1,0},{-1,1},{0,-2},{-1,-2}}
wallKick["34"] = {{0,0},{1,0},{1,1},{0,-2},{1,-2}}
wallKick["43"] = {{0,0},{-1,0},{-1,-1},{0,2},{-1,2}}
wallKick["41"] = {{0,0},{-1,0},{-1,-1},{0,2},{-1,2}}
wallKick["14"] = {{0,0},{1,0},{1,1},{0,-2},{1,-2}}

Tetris.pieces = pieces
Tetris.sizes = sizes
Tetris.colors = colors
Tetris.imgs = imgs

Tetris.beamKick = beamKick
Tetris.wallKick = wallKick

return Tetris