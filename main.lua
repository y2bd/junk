local Matrix = require("matrix")
local Tetris = require("tetris")

local ROWS = 16
local COLS = 10

local FALL_ELAPSE = 0.4
local GROUND_ELAPSE = 0.25

local MAX_INPUT_BUFFER = 4

local VALID_KEYS = {
    left = true,
    right = true,
    up = true,
    down = true,
}

local BUFFERABLE_KEYS = {
    left = true,
    right = true,
    down = true,
}

local function drawBoard(board, rows, cols)
    local totalWidth = TILE_SIZE * COLS;
    local totalHeight = TILE_SIZE * ROWS;
    local left = (WIN_WIDTH - totalWidth) / 2
    local top = (WIN_HEIGHT - totalHeight) / 2

    for i=1,rows do
        for j=1,cols do
            local val = board[i * cols + j]
            local x = left + (j-1) * TILE_SIZE
            local y = top + (i-1) * TILE_SIZE

            if val ~= 0 then
                love.graphics.setColor(Tetris.colors[val][1], Tetris.colors[val][2], Tetris.colors[val][3], 255)
                love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
            
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.rectangle("line", x, y, TILE_SIZE, TILE_SIZE)
        end
    end
end

local ControlStates = {
    SPAWN=1,
    FALL=2,
    GROUND=3,
    COMPLETE=4,
}

local ControlState = ControlStates.SPAWN

local function shuffle(array)
    len = #array
    for i = len, 1, -1 do
        local rnd = math.random(len)
        array[i], array[rnd] = array[rnd], array[i]
    end
    return array
end

local function spawn(board, piece)
    local pieceShape = Tetris.pieces[piece]
    local pieceRows, pieceCols = Tetris.sizes[piece]

    if piece == 1 or piece == 7 then
        return 0, 4
    end

    return 1, 5
end

local function collides(checkRow, checkCol) 
    return Matrix.collides(board, ROWS, COLS, Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], checkRow, checkCol)
end

local function pollInput(key) 
    if bufferedInputs[bufferedInputIndex] == key then
        bufferedInputIndex = bufferedInputIndex + 1
        return true
    end
    
    return false
end

function love.keypressed(key, scan, isrepeat)
    if VALID_KEYS[key] and (not isrepeat or BUFFERABLE_KEYS[key]) then 
        bufferedInputs[#bufferedInputs + 1] = key
    end

    if #bufferedInputs - bufferedInputIndex > MAX_INPUT_BUFFER then
        bufferedInputIndex = #bufferedInputs - MAX_INPUT_BUFFER
    end
end

function love.load()
    print("Starting the game ...")
    math.randomseed( os.time() )

    love.keyboard.setKeyRepeat(true)

    WIN_WIDTH, WIN_HEIGHT = love.window.getMode()
    TILE_SIZE = ((WIN_WIDTH + WIN_HEIGHT) / 4) / COLS;  

    bufferedInputs = {}
    bufferedInputIndex = 1

    currentBag = shuffle({1, 2, 3, 4, 5, 6, 7})
    for x=1,7 do
        print(currentBag[x])
    end

    currentBagIndex = 1

    currentPiece = 4
    currentPieceRow = 2
    currentPieceCol = 4
    currentPieceSpin = 1

    board = Matrix.create(ROWS, COLS, 0)

    Matrix.print(board, ROWS, COLS)
end

function love.update(dt)
    if currentBagIndex > #currentBag then
        currentBag = shuffle({1, 2, 3, 4, 5, 6, 7})
        currentBagIndex = 1
    end

    if ControlState == ControlStates.SPAWN then
        currentPiece = currentBag[currentBagIndex]
        currentBagIndex = currentBagIndex + 1

        currentPieceRow, currentPieceCol = spawn(board, currentPiece)

        fallTimer = 0
        ControlState = ControlStates.FALL
    elseif ControlState == ControlStates.FALL then
        BUFFERABLE_KEYS.down = true

        local currentPieceRowNext = currentPieceRow
        local currentPieceColNext = currentPieceCol

        if pollInput("left") then
            currentPieceColNext = currentPieceCol - 1
        end

        if pollInput("right") then 
            currentPieceColNext = currentPieceCol + 1
        end

        -- lateral collision
        if collides(currentPieceRowNext, currentPieceColNext) then
            currentPieceRowNext = currentPieceRow
            currentPieceColNext = currentPieceCol
        end

        if pollInput("up") then
            while not collides(currentPieceRowNext, currentPieceColNext) do
                currentPieceRowNext = currentPieceRowNext + 1
            end
            currentPieceRowNext = currentPieceRowNext - 1

            groundTimer = 0
            ControlState = ControlStates.COMPLETE 
            
            currentPieceRow = currentPieceRowNext
            currentPieceCol = currentPieceColNext
        end

        if pollInput("down") then
            currentPieceRowNext = currentPieceRow + 1
            fallTimer = 0
        end

        fallTimer = fallTimer + dt
        if fallTimer > FALL_ELAPSE then
            fallTimer = fallTimer - FALL_ELAPSE
            currentPieceRowNext = currentPieceRow + 1
        end
        
        -- ground collision
        if collides(currentPieceRowNext, currentPieceColNext) then 
            currentPieceRowNext = currentPieceRow
            currentPieceColNext = currentPieceCol

            groundTimer = 0
            ControlState = ControlStates.GROUND 
        end

        currentPieceRow = currentPieceRowNext
        currentPieceCol = currentPieceColNext
    elseif ControlState == ControlStates.GROUND then
        BUFFERABLE_KEYS.down = false

        local currentPieceRowNext = currentPieceRow
        local currentPieceColNext = currentPieceCol

        -- allow for movement until the ground timer ellapses
        if pollInput("left") then
            currentPieceColNext = currentPieceCol - 1
        end
        
        if pollInput("right") then 
            currentPieceColNext = currentPieceCol + 1
        end

        -- lateral collision
        if collides(currentPieceRowNext, currentPieceColNext) then
            currentPieceRowNext = currentPieceRow
            currentPieceColNext = currentPieceCol
        -- elseif currentPieceColNext ~= currentPieceCol then
        --     -- if it was a valid move, reset the ground timer
        --     groundTimer = 0
        end

        -- if a movement gave us space to fall again
        if not collides(currentPieceRowNext + 1, currentPieceColNext) then
            fallTimer = 0
            groundTimer = 0
            ControlState = ControlStates.FALL
        end

        groundTimer = groundTimer + dt
        if groundTimer > GROUND_ELAPSE then
            groundTimer = 0
            ControlState = ControlStates.COMPLETE
        end
        
        currentPieceRow = currentPieceRowNext
        currentPieceCol = currentPieceColNext
    elseif ControlState == ControlStates.COMPLETE then
        board = Matrix.applyInto(board, ROWS, COLS, Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], currentPieceRow, currentPieceCol)
        ControlState = ControlStates.SPAWN
    end

end

function love.draw()
    -- Matrix.print(Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
    local currentBoard = Matrix.applyInto(board, ROWS, COLS, Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], currentPieceRow, currentPieceCol)

    -- Matrix.print(currentBoard, ROWS, COLS)
    drawBoard(currentBoard, ROWS, COLS)
end