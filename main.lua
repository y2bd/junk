local Matrix = require("matrix")
local Tetris = require("tetris")
local Input = require("input")

local MIN_ROWS = 16
local COLS = 10

local ROW_GROWTH = 8
local GROW_BUFFER = 4
local ROW_SHRINK = 6
local SHRINK_BUFFER = 14
local currentRows = 16

local FALL_ELAPSE = 0.3
local GROUND_ELAPSE = 0.2

-- fix
_coroutine_resume = coroutine.resume
function coroutine.resume(...)
	local state,result = _coroutine_resume(...)
	if not state then
		error( tostring(result), 2 )	-- Output error message
	end
	return state,result
end

local function drawBoard(board, rows, cols)
    local totalWidth = TILE_SIZE * cols;
    local totalHeight = TILE_SIZE * rows;
    local left = (WIN_WIDTH - totalWidth) / 2
    local top = TILE_SIZE * 2

    for i=1,math.min(rows,16) do
        for j=1,cols do
            local val = board[i * cols + j]
            local x = left + (j-1) * TILE_SIZE
            local y = top + (i-1) * TILE_SIZE

            if val ~= 0 then
                local alpha = 255
                if val > 7 then
                    alpha = 128
                    val = val - 7
                end

                love.graphics.setColor(Tetris.colors[val][1], Tetris.colors[val][2], Tetris.colors[val][3], alpha)
                love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
            love.graphics.setColor(128, 128, 128, 128)
            love.graphics.rectangle("line", x, y, TILE_SIZE, TILE_SIZE)
        end
    end
end

local ControlStates = {
    SPAWN=1,
    FALL=2,
    GROUND=3,
    COMPLETE=4,
    COLLAPSE=5,
    GROW=6,
    SHRINK=7
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

local function getCurrentPiece(spin)
    if spin == 1 then
        return Tetris.pieces[currentPiece]
    elseif spin == 2 then
        return Matrix.rotate90CC(Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
    elseif spin == 3 then
        return Matrix.rotate180(Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
    elseif spin == 4 then
        return Matrix.rotate90C(Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
    end
end

local function rotate(spin, dir)
    spin = spin + dir
    if spin < 1 then
        spin = 4
    elseif spin > 4 then
        spin = 1
    end

    return spin
end

local function collides(checkRow, checkCol, checkSpin) 
    return Matrix.collides(board, currentRows, COLS, getCurrentPiece(checkSpin), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], checkRow, checkCol)
end

local function beamKick(row, col, oldSpin, newSpin)
    local key = tostring(oldSpin) .. tostring(newSpin)
    local kickMap = Tetris.beamKick[key]

    for k=1,#kickMap do
        local kr = -kickMap[k][2]
        local kc = kickMap[k][1]
        if not collides(row+kr, col+kc, newSpin) then
            return row+kr, col+kc, newSpin
        end
    end

    return row, col, oldSpin
end

local function wallKick(row, col, oldSpin, newSpin, piece)
    if piece == 1 then
        return beamKick(row, col, oldSpin, newSpin)
    elseif piece == 7 then
        return row, col, oldSpin
    end

    local key = tostring(oldSpin) .. tostring(newSpin)
    print(key)
    local kickMap = Tetris.wallKick[key]
    
    print(#kickMap)
    for k=1,#kickMap do
        local kr = -kickMap[k][2]
        local kc = kickMap[k][1]
        if not collides(row+kr, col+kc, newSpin) then
            return row+kr, col+kc, newSpin
        end
    end

    return row, col, oldSpin
end

local function getSlamRow(forColumn, startRow, withSpin)
    while not collides(startRow, forColumn, withSpin) do
        startRow = startRow + 1
    end

    return startRow - 1
end

function love.keypressed(key, scan, isrepeat)
    Input.keyPressed(key, scan, isrepeat)
end

function love.load()
    print("Starting the game ...")
    math.randomseed( os.time() )

    love.keyboard.setKeyRepeat(true)

    WIN_WIDTH, WIN_HEIGHT = love.window.getMode()
    TILE_SIZE = ((WIN_WIDTH + WIN_HEIGHT) / 4) / COLS;  

    currentBag = shuffle({1, 2, 3, 4, 5, 6, 7})
    for x=1,7 do
        print(currentBag[x])
    end

    currentBagIndex = 1

    currentPiece = 4
    currentPieceRow = 2
    currentPieceCol = 4
    currentPieceSpin = 1

    board = Matrix.create(currentRows, COLS, 0)
end

local collapser = function (board)
    local needToCollapse = false
    local bottomRow = nil
    for i=1,currentRows do
        local fullRow = true
        for j=1,COLS do
            if board[i * COLS + j] == 0 then
                fullRow = false
            end
        end

        if fullRow then
            print("fullRow at row" .. tostring(i))
            needToCollapse = true
            if bottomRow == nil then
                bottomRow = i
            end

            for j=1,COLS do
                table.remove(board, i * COLS + j)
                table.insert(board, 1 * COLS + 1, 0)
                board[i * COLS + j] = 0
            end

            for delay=1,5 do
                board = coroutine.yield(board)
            end

            print("cleared row")
        end
    end

    return board
end

local grower = function (board) 
    local topRow = currentRows
    for i=1,currentRows do
        for j=1,COLS do
            if board[i * COLS + j] ~= 0 then
                topRow = i
                break
            end
        end
        if topRow < currentRows then
            break
        end
    end

    if topRow <= GROW_BUFFER then
        for i=1,ROW_GROWTH do
            for j=1,COLS do
                table.insert(board, 1 * COLS + 1, 0)
            end
            board = coroutine.yield(board)
        end
        currentRows = currentRows + ROW_GROWTH
    end

    return board
end

local shrinker = function (board)
    if currentRows <= MIN_ROWS then
        return board
    end

    local topRow = currentRows
    for i=1,currentRows do
        for j=1,COLS do
            if board[i * COLS + j] ~= 0 then
                topRow = i
                break
            end
        end
        if topRow < currentRows then
            break
        end
    end

    if topRow >= SHRINK_BUFFER then
        for i=1,ROW_SHRINK do
            for j=1,COLS do
                table.remove(board, 1 * COLS + 1)
            end
            board = coroutine.yield(board)
        end
        currentRows = currentRows - ROW_SHRINK
    end

    return board
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
        currentPieceSpin = 1

        fallTimer = 0
        ControlState = ControlStates.FALL
    elseif ControlState == ControlStates.FALL then
        -- only allowed to buffer down when falling so we don't carry onto next piece accidentally
        Input.BUFFERABLE_KEYS.down = true

        local currentPieceRowNext = currentPieceRow
        local currentPieceColNext = currentPieceCol
        local currentPieceSpinNext = currentPieceSpin

        if Input.pollInput("z") then
            currentPieceSpinNext = rotate(currentPieceSpin, -1)
        end

        if Input.pollInput("x") then
            currentPieceSpinNext = rotate(currentPieceSpin, 1)
        end

        -- wall kick
        if currentPieceSpinNext ~= currentPieceSpin then
            currentPieceRowNext, currentPieceColNext, currentPieceSpinNext = wallKick(currentPieceRowNext, currentPieceColNext, currentPieceSpin, currentPieceSpinNext, currentPiece)
        end

        if Input.pollInput("left") then
            if not collides(currentPieceRowNext, currentPieceColNext - 1, currentPieceSpinNext) then
                currentPieceColNext = currentPieceColNext - 1
            end
        end
        
        if Input.pollInput("right") then 
            if not collides(currentPieceRowNext, currentPieceColNext + 1, currentPieceSpinNext) then
                currentPieceColNext = currentPieceColNext + 1
            end
        end

        if Input.pollInput("up") then
            currentPieceRowNext = getSlamRow(currentPieceColNext, currentPieceRowNext, currentPieceSpinNext)

            groundTimer = 0
            ControlState = ControlStates.COMPLETE 
            
            currentPieceRow = currentPieceRowNext
            currentPieceCol = currentPieceColNext
            currentPieceSpin = currentPieceSpinNext

            return
        end

        if Input.pollInput("down") then
            currentPieceRowNext = currentPieceRow + 1
            fallTimer = 0
        end

        fallTimer = fallTimer + dt
        if fallTimer > FALL_ELAPSE then
            fallTimer = fallTimer - FALL_ELAPSE
            currentPieceRowNext = currentPieceRow + 1
        end
        
        -- ground collision
        if collides(currentPieceRowNext, currentPieceColNext, currentPieceSpinNext) then 
            currentPieceRowNext = currentPieceRow
            currentPieceColNext = currentPieceCol

            groundTimer = 0
            ControlState = ControlStates.GROUND
            print("HIT GROUND")
        end

        currentPieceRow = currentPieceRowNext
        currentPieceCol = currentPieceColNext
        currentPieceSpin = currentPieceSpinNext
    elseif ControlState == ControlStates.GROUND then
        Input.BUFFERABLE_KEYS.down = false

        local currentPieceRowNext = currentPieceRow
        local currentPieceColNext = currentPieceCol
        local currentPieceSpinNext = currentPieceSpin
        
        if Input.pollInput("z") then
            currentPieceSpinNext = rotate(currentPieceSpin, 1)
        end

        if Input.pollInput("x") then
            currentPieceSpinNext = rotate(currentPieceSpin, -1)
        end

        -- wall kick
        if currentPieceSpinNext ~= currentPieceSpin then
            currentPieceRowNext, currentPieceColNext, currentPieceSpinNext = wallKick(currentPieceRowNext, currentPieceColNext, currentPieceSpin, currentPieceSpinNext, currentPiece)
        end

        -- allow for movement until the ground timer ellapses
        if Input.pollInput("left") then
            if not collides(currentPieceRowNext, currentPieceColNext - 1, currentPieceSpinNext) then
                currentPieceColNext = currentPieceColNext - 1
            end
        end
        
        if Input.pollInput("right") then 
            if not collides(currentPieceRowNext, currentPieceColNext + 1, currentPieceSpinNext) then
                currentPieceColNext = currentPieceColNext + 1
            end
        end

        -- if a movement gave us space to fall again
        if not collides(currentPieceRowNext + 1, currentPieceColNext, currentPieceSpinNext) then
            fallTimer = 0
            groundTimer = 0

            print("BACK IN THE AIR")
            ControlState = ControlStates.FALL
            return
        end

        groundTimer = groundTimer + dt
        if groundTimer > GROUND_ELAPSE then
            groundTimer = 0
            ControlState = ControlStates.COMPLETE
        end
        
        currentPieceRow = currentPieceRowNext
        currentPieceCol = currentPieceColNext
        currentPieceSpin = currentPieceSpinNext
    elseif ControlState == ControlStates.COMPLETE then
        board = Matrix.applyInto(board, currentRows, COLS, getCurrentPiece(currentPieceSpin), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], currentPieceRow, currentPieceCol)
        ControlState = ControlStates.COLLAPSE
    elseif ControlState == ControlStates.COLLAPSE then
        if currentCollapser == nil then
            currentCollapser = coroutine.create(collapser)
        end

        -- collapse empty rows
        if coroutine.status(currentCollapser) == 'dead' then
            ControlState = ControlStates.GROW
            currentCollapser = nil
        else
            _, board = coroutine.resume(currentCollapser, board)
        end
    elseif ControlState == ControlStates.GROW then
        if currentGrower == nil then
            currentGrower = coroutine.create(grower)
        end

        if coroutine.status(currentGrower) == 'dead' then
            ControlState = ControlStates.SHRINK
            currentGrower = nil
        else
            _, board = coroutine.resume(currentGrower, board)
        end
    elseif ControlState == ControlStates.SHRINK then
        if currentShrinker == nil then
            currentShrinker = coroutine.create(shrinker)
        end

        if coroutine.status(currentShrinker) == 'dead' then
            ControlState = ControlStates.SPAWN
            currentShrinker = nil
        else
            _, board = coroutine.resume(currentShrinker, board)
        end
    end

end

function love.draw()
    -- Matrix.print(getCurrentPiece(), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
    local boardWithGhost = board
    if ControlState == ControlStates.FALL then
        local ghostRow = getSlamRow(currentPieceCol, currentPieceRow, currentPieceSpin)
        local ghostPiece = Matrix.ghostify(getCurrentPiece(currentPieceSpin), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
        boardWithGhost = Matrix.applyInto(board, currentRows, COLS, ghostPiece, Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], ghostRow, currentPieceCol)
    end

    local currentBoard = boardWithGhost
    if ControlState == ControlStates.FALL or ControlState == ControlStates.GROUND then
        currentBoard = Matrix.applyInto(boardWithGhost, currentRows, COLS, getCurrentPiece(currentPieceSpin), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], currentPieceRow, currentPieceCol)
    end

    -- Matrix.print(currentBoard, currentRows, COLS)
    drawBoard(currentBoard, currentRows, COLS)
end