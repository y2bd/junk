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

local FALL_ELAPSE = 0.25
local GROUND_ELAPSE = 0.2

local viewportDelta = 0
local VIEWPORT_SCROLL = 12
local VIEWPORT_BUFFER = 13
local VIEWPORT_SLAM_BUFFER = 4

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
    local left = (WIN_WIDTH - totalWidth) / 5
    local top = TILE_SIZE * 2

    love.graphics.setColor(256, 256, 256, 256)
    love.graphics.rectangle("line", left, top, TILE_SIZE * COLS, TILE_SIZE * MIN_ROWS)

    for i=1,math.min(rows,MIN_ROWS) do
        for j=1,cols do
            local val = board[(i + viewportDelta) * cols + j]
            local x = left + (j-1) * TILE_SIZE
            local y = top + (i-1) * TILE_SIZE

            if val ~= 0 and val ~= nil then
                local alpha = 255
                if val > 7 then
                    alpha = 128
                    val = val - 7
                end

                love.graphics.setColor(Tetris.colors[val][1], Tetris.colors[val][2], Tetris.colors[val][3], alpha)
                love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
        end
    end

    -- draw next piece
    local nextLeft = left + TILE_SIZE * (COLS + 2)
    local nextTop = top

    love.graphics.setColor(256, 256, 256, 256)
    love.graphics.rectangle("line", nextLeft, nextTop, TILE_SIZE * 4, TILE_SIZE * 4)
    for i=1,Tetris.sizes[nextPiece][1] do
        for j=1,Tetris.sizes[nextPiece][2] do
            local val = Tetris.pieces[nextPiece][i * Tetris.sizes[nextPiece][2] + j]
            local x = nextLeft + (j-1) * TILE_SIZE + (4 - Tetris.sizes[nextPiece][1]) * 0.5 * TILE_SIZE
            local y = nextTop + (i-1) * TILE_SIZE + (4 - Tetris.sizes[nextPiece][2]) * 1 * TILE_SIZE

            if val ~= 0 and val ~= nil then
                local alpha = 255
                if val > 7 then
                    alpha = 128
                    val = val - 7
                end

                love.graphics.setColor(Tetris.colors[val][1], Tetris.colors[val][2], Tetris.colors[val][3], alpha)
                love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
        end
    end
end

local ControlStates = {
    SPAWN={},
    FALL={},
    GROUND={},
    COMPLETE={},
    COLLAPSE={},
    GROW={},
    SHRINK={},
    SCROLL_DOWN={},
    SCROLL_UP={},
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
    local initialRow = startRow
    while not collides(startRow, forColumn, withSpin) do
        startRow = startRow + 1
    end

    return startRow - 1, startRow - initialRow
end

function love.keypressed(key, scan, isrepeat)
    if ControlState == ControlStates.SPAWN or
       ControlState == ControlStates.FALL or
       ControlState == ControlStates.GROUND then

        Input.keyPressed(key, scan, isrepeat)
    end
end

function love.load()
    print("Starting the game ...")
    math.randomseed( os.time() )

    love.keyboard.setKeyRepeat(true)

    WIN_WIDTH, WIN_HEIGHT = love.window.getMode()
    TILE_SIZE = ((WIN_WIDTH + WIN_HEIGHT) / 4) / COLS;  

    currentBag = shuffle({1, 2, 3, 4, 5, 6, 7})
    nextBag = shuffle({1, 2, 3, 4, 5, 6, 7})

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
            needToCollapse = true
            break
        end
    end

    if needToCollapse then
        for delay=1,5 do
            board = coroutine.yield(board)
        end
    end

    for i=1,currentRows do
        local fullRow = true
        for j=1,COLS do
            if board[i * COLS + j] == 0 then
                fullRow = false
            end
        end

        if fullRow then
            if bottomRow == nil then
                bottomRow = i
            end

            for j=1,COLS do
                table.remove(board, i * COLS + j)
                table.insert(board, 1 * COLS + 1, 0)
            end
        end
    end

    if needToCollapse then
        for delay=1,5 do
            board = coroutine.yield(board)
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

function shouldScrollDown ()
    if currentRows <= MIN_ROWS then
        return false
    end

    -- do we scroll down
    if currentPieceRow - viewportDelta > VIEWPORT_BUFFER then
        _, slamDistance = getSlamRow(currentPieceCol, currentPieceRow, currentPieceSpin)
        if slamDistance > VIEWPORT_SLAM_BUFFER then
            return true
        end
    end

    return false
end

local scrollDown = function ()
    if currentRows <= MIN_ROWS then
        return
    end

    -- do we scroll down
    local scrollTo = viewportDelta
    local shouldScroll = false
    if currentPieceRow - viewportDelta > VIEWPORT_BUFFER then
        _, slamDistance = getSlamRow(currentPieceCol, currentPieceRow, currentPieceSpin)
        if slamDistance > VIEWPORT_SLAM_BUFFER then
            scrollTo = scrollTo + VIEWPORT_SCROLL
            shouldScroll = true
        end
    end

    if scrollTo + 3 >= currentRows - MIN_ROWS then
        scrollTo = currentRows - MIN_ROWS
    end

    while viewportDelta < scrollTo do
        viewportDelta = viewportDelta + 1
        coroutine.yield()
    end

    if shouldScroll then
        for delay=1,20 do
            coroutine.yield()
        end
    end
end

local scrollUp = function ()
    if currentRows <= MIN_ROWS then
        return
    end

    local shouldScroll = false
    while viewportDelta > 0 do
        shouldScroll = true
        viewportDelta = viewportDelta - 1
        coroutine.yield()
    end

    viewportDelta = 0

    if shouldScroll then
        for delay=1,15 do
            coroutine.yield()
        end
    end
end

function love.update(dt)
    if currentBagIndex > #currentBag then
        currentBag = nextBag
        nextBag = shuffle({1,2,3,4,5,6,7})
        currentBagIndex = 1
    end

    if ControlState == ControlStates.SPAWN then
        currentPiece = currentBag[currentBagIndex]
        if currentBagIndex >= 7 then
            nextPiece = nextBag[1]
        else
            nextPiece = currentBag[currentBagIndex + 1]
        end

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

        CPRNpreFall = currentPieceRowNext
        if Input.pollInput("down") then
            currentPieceRowNext = currentPieceRowNext + 1
            fallTimer = 0
        end

        fallTimer = fallTimer + dt
        if fallTimer > FALL_ELAPSE then
            fallTimer = fallTimer - FALL_ELAPSE
            currentPieceRowNext = currentPieceRowNext + 1
        end
        
        -- ground collision
        if collides(currentPieceRowNext, currentPieceColNext, currentPieceSpinNext) then 
            currentPieceRowNext = CPRNpreFall

            groundTimer = 0
            ControlState = ControlStates.GROUND
            print("HIT GROUND")
        end

        currentPieceRow = currentPieceRowNext
        currentPieceCol = currentPieceColNext
        currentPieceSpin = currentPieceSpinNext
        
        if shouldScrollDown() then 
            print("SCROLLIN")
            ControlState = ControlStates.SCROLL_DOWN
        end
    elseif ControlState == ControlStates.SCROLL_DOWN then
        if currentScrollDown == nil then
            currentScrollDown = coroutine.create(scrollDown)
        end

        if coroutine.status(currentScrollDown) == 'dead' then
            ControlState = ControlStates.FALL
            currentScrollDown = nil
        else
            coroutine.resume(currentScrollDown)
        end
    elseif ControlState == ControlStates.GROUND then
        Input.BUFFERABLE_KEYS.down = false

        local currentPieceRowNext = currentPieceRow
        local currentPieceColNext = currentPieceCol
        local currentPieceSpinNext = currentPieceSpin
        
        if Input.pollInput("z") then
            currentPieceSpinNext = rotate(currentPieceSpinNext, -1)
        end

        if Input.pollInput("x") then
            currentPieceSpinNext = rotate(currentPieceSpinNext, 1)
        end

        -- wall kick
        if currentPieceSpinNext ~= currentPieceSpin then
            currentPieceRowNext, currentPieceColNext, currentPieceSpinNext = wallKick(currentPieceRowNext, currentPieceColNext, currentPieceSpin, currentPieceSpinNext, currentPiece)
            if currentPieceSpin ~= currentPieceSpinNext then
                groundTimer = -GROUND_ELAPSE
            end
        end

        -- allow for movement until the ground timer ellapses
        if Input.pollInput("left") then
            if not collides(currentPieceRowNext, currentPieceColNext - 1, currentPieceSpinNext) then
                currentPieceColNext = currentPieceColNext - 1
                groundTimer = -GROUND_ELAPSE
            end
        end
        
        if Input.pollInput("right") then 
            if not collides(currentPieceRowNext, currentPieceColNext + 1, currentPieceSpinNext) then
                currentPieceColNext = currentPieceColNext + 1
                groundTimer = 0
            end
        end

        -- if a movement gave us space to fall again
        if not collides(currentPieceRowNext + 1, currentPieceColNext, currentPieceSpinNext) then
            fallTimer = 0
            groundTimer = 0
            
            currentPieceRow = currentPieceRowNext
            currentPieceCol = currentPieceColNext
            currentPieceSpin = currentPieceSpinNext
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
        print("GROW")
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
            ControlState = ControlStates.SCROLL_UP
            currentShrinker = nil
        else
            _, board = coroutine.resume(currentShrinker, board)
        end
    elseif ControlState == ControlStates.SCROLL_UP then
        if currentScrollUp == nil then
            currentScrollUp = coroutine.create(scrollUp)
        end

        if coroutine.status(currentScrollUp) == 'dead' then
            ControlState = ControlStates.SPAWN
            currentScrollUp = nil
        else
            coroutine.resume(currentScrollUp)
        end
    end

end

function love.draw()
    -- Matrix.print(getCurrentPiece(), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
    local boardWithGhost = board
    if ControlState == ControlStates.FALL or ControlState == ControlStates.SCROLL_DOWN then
        local ghostRow = getSlamRow(currentPieceCol, currentPieceRow, currentPieceSpin)
        local ghostPiece = Matrix.ghostify(getCurrentPiece(currentPieceSpin), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])
        boardWithGhost = Matrix.applyInto(board, currentRows, COLS, ghostPiece, Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], ghostRow, currentPieceCol)
    end

    local currentBoard = boardWithGhost
    if ControlState == ControlStates.FALL or 
       ControlState == ControlStates.GROUND or 
       ControlState == ControlStates.SCROLL_DOWN or 
       ControlState == ControlStates.COMPLETE then

        if ControlState == ControlStates.GROW then 
            print ("growing??") 
        end
        currentBoard = Matrix.applyInto(boardWithGhost, currentRows, COLS, getCurrentPiece(currentPieceSpin), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], currentPieceRow, currentPieceCol)
    end

    -- Matrix.print(currentBoard, currentRows, COLS)
    drawBoard(currentBoard, currentRows, COLS)
end