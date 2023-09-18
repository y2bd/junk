local Matrix = require("matrix")
local Tetris = require("tetris")
local Input = require("input")
local Net = require("net")
local Dialogue = require("dialogue")
local Save = require("save")
local Framerate = require("framerate")

local MIN_ROWS = 16
local COLS = 10

local ROW_GROWTH = 8
local GROW_BUFFER = 4
local ROW_SHRINK = 6
local SHRINK_BUFFER = 14
local currentRows = 16

local FALL_ELAPSE = 0.6
local GROUND_ELAPSE = 0.2

local viewportDelta = 0
local VIEWPORT_SCROLL = 12
local VIEWPORT_BUFFER = 12
local VIEWPORT_SLAM_BUFFER = 4

local GAME_TIME = 121

local MAX_LINE = 24

local ControlStates = {
    LOAD_BOARD = {},
    SAVE_BOARD = {},
    DONE = {},

    INTRO = {},
    OUTRO = {},

    SPAWN = {},
    FALL = {},
    GROUND = {},
    COMPLETE = {},
    COLLAPSE = {},
    GROW = {},
    SHRINK = {},
    SCROLL_DOWN = {},
    SCROLL_UP = {}

}

local ControlState = ControlStates.INTRO

-- porting to love2d v11+
local setColorF = function(r, g, b, a)
    love.graphics.setColor(r / 255.0, g / 255.0, b / 255.0, a / 255.0)
end

-- fix
_coroutine_resume = coroutine.resume
function coroutine.resume(...)
    local state, result = _coroutine_resume(...)
    if not state then
        error(tostring(result), 2) -- Output error message
    end
    return state, result
end

-- goddamn hoisting
local function getNumberOfLines()
    for i = 1, currentRows do
        for j = 1, COLS do
            if board[i * COLS + j] ~= 0 then
                return currentRows - i + 1
            end
        end
    end

    return 0
end

local SAVE_BOARD = false
local savedBoard = false
local function saveBoard(board, rows, cols)
    if SAVE_BOARD and (not savedBoard) then
        if ControlState == ControlStates.FALL then
            local canv = love.graphics.newCanvas(cols * TILE_SIZE, rows * TILE_SIZE)
            love.graphics.setCanvas(canv)
            for i = 1, rows do
                for j = 1, cols do
                    local val = board[i * cols + j]
                    local x = 0 + (j - 1) * TILE_SIZE
                    local y = 0 + (i - 1) * TILE_SIZE

                    if val ~= 0 and val ~= nil and val <= 7 then
                        local alpha = 255
                        -- setColorF(Tetris.colors[val][1], Tetris.colors[val][2], Tetris.colors[val][3], alpha)
                        setColorF(255, 255, 255, alpha)
                        love.graphics.draw(Tetris.imgs[val], x, y, 0, 0.5)
                        -- love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
                    end
                end
            end
            love.graphics.setCanvas()

            local id = canv:newImageData()
            id:encode("png", "board_" .. tostring(returnBoardNumber) .. ".png")
            -- print("output!!")

            savedBoard = true
        end
    end

    return
end

local function drawBoard(board, rows, cols)
    local totalWidth = TILE_SIZE * cols;
    local totalHeight = TILE_SIZE * rows;
    local left = (WIN_WIDTH - totalWidth) / 5
    local top = TILE_SIZE * 2

    setColorF(16, 16, 16, 256)
    love.graphics.rectangle("fill", left - 8, top - 8, TILE_SIZE * COLS + 16, TILE_SIZE * MIN_ROWS + 16)

    setColorF(196, 196, 196, 196)
    love.graphics.rectangle("line", left - 8, top - 8, TILE_SIZE * COLS + 16, TILE_SIZE * MIN_ROWS + 16)

    for i = 1, math.min(rows, MIN_ROWS) do
        for j = 1, cols do
            local val = board[(i + viewportDelta) * cols + j]
            local x = left + (j - 1) * TILE_SIZE
            local y = top + (i - 1) * TILE_SIZE

            if val ~= 0 and val ~= nil then
                local alpha = 255
                if val > 7 then
                    alpha = 48
                    val = val - 7

                end

                -- setColorF(Tetris.colors[val][1], Tetris.colors[val][2], Tetris.colors[val][3], alpha)
                setColorF(255, 255, 255, alpha)
                love.graphics.draw(Tetris.imgs[val], x, y, 0, 0.5)
                -- love.graphics.rectangle("fill", x, y, TILE_SIZE, TILE_SIZE)
            end
        end
    end

    if showTitle then
        setColorF(256, 256, 256, 256)

        if isAwesome then
            love.graphics.setFont(timerFont)
            love.graphics.print("JUNK", left + TILE_SIZE * COLS / 2 - 60, top + TILE_SIZE * 3)

            love.graphics.setFont(chatFont)
            love.graphics.printf("a board by\n" .. returnName, left + TILE_SIZE * COLS / 2 - 60, top + TILE_SIZE * 4.2,
                140)
        else
            love.graphics.setFont(timerFont)
            love.graphics.print("JUNK", left + TILE_SIZE * COLS / 2 - 60, top + TILE_SIZE * 3)

            love.graphics.setFont(chatFont)
            love.graphics.print("a game\nby y2bd", left + TILE_SIZE * COLS / 2 - 60, top + TILE_SIZE * 4)
        end
    end

    -- draw next piece
    local nextLeft = left + TILE_SIZE * (COLS + 2)
    local nextTop = top

    setColorF(16, 16, 16, 256)
    love.graphics.rectangle("fill", nextLeft - 8, nextTop - 8, TILE_SIZE * 4 + 16, TILE_SIZE * 4 + 16)

    setColorF(196, 196, 196, 196)
    love.graphics.rectangle("line", nextLeft - 8, nextTop - 8, TILE_SIZE * 4 + 16, TILE_SIZE * 4 + 16)

    setColorF(16, 16, 16, 256)
    love.graphics
        .rectangle("fill", nextLeft - 8, (nextTop + TILE_SIZE * 5) - 8, TILE_SIZE * 4 + 16, TILE_SIZE * 11 + 16)

    setColorF(196, 196, 196, 196)
    love.graphics
        .rectangle("line", nextLeft - 8, (nextTop + TILE_SIZE * 5) - 8, TILE_SIZE * 4 + 16, TILE_SIZE * 11 + 16)

    -- draw timer
    if timerActive or ControlState == ControlStates.OUTRO then
        for i = 1, Tetris.sizes[nextPiece][1] do
            for j = 1, Tetris.sizes[nextPiece][2] do
                local val = Tetris.pieces[nextPiece][i * Tetris.sizes[nextPiece][2] + j]
                local x = nextLeft + (j - 1) * TILE_SIZE + (4 - Tetris.sizes[nextPiece][1]) * 0.5 * TILE_SIZE
                local y = nextTop + (i - 1) * TILE_SIZE + (4 - Tetris.sizes[nextPiece][2]) * 1 * TILE_SIZE

                if nextPiece == 1 then
                    y = y + TILE_SIZE / 2
                end

                if val ~= 0 and val ~= nil then
                    local alpha = 255
                    if val > 7 then
                        alpha = 128
                        val = val - 7
                    end

                    setColorF(255, 255, 255, alpha)
                    love.graphics.draw(Tetris.imgs[val], x, y, 0, 0.5)
                end
            end
        end

        setColorF(256, 256, 256, 256)
        love.graphics.setFont(timerFont)

        if timer < 30 then
            setColorF(256, 32, 32, 256)
        end
        local timerLeft = nextLeft + 12
        local timerTop = nextTop + TILE_SIZE * 5.6
        timerText = tostring(math.floor(timer))
        while #timerText < 4 do
            timerText = "0" .. timerText
        end

        love.graphics.print("time", timerLeft, timerTop)
        love.graphics.print(timerText, timerLeft, timerTop + 48)

        if startingTall > currentTall then
            setColorF(32, 256, 64, 256)
        else
            setColorF(256, 256, 256, 256)
        end
        tallText = tostring(currentTall)
        while #tallText < 4 do
            tallText = "0" .. tallText
        end

        love.graphics.print("junk", timerLeft, timerTop + 112)
        love.graphics.print(tallText, timerLeft, timerTop + 112 + 48)

        setColorF(256, 256, 256, 256)
        tookText = tostring(tookLines)
        while #tookText < 4 do
            tookText = "0" .. tookText
        end

        love.graphics.print("work", timerLeft, timerTop + 224)
        love.graphics.print(tookText, timerLeft, timerTop + 224 + 48)
    end

    if ControlState == ControlStates.INTRO then
        setColorF(0, 0, 0, 196)
        love.graphics.rectangle("fill", 0, 0, WIN_WIDTH, WIN_HEIGHT)

        setColorF(256, 256, 256, 256)
        love.graphics.setFont(chatFont)

        love.graphics.print(intro.currentTextRender or "", TILE_SIZE * 3, TILE_SIZE * 7)

        if isAwesome then
            love.graphics.print("(press esc to skip)", TILE_SIZE * 3, TILE_SIZE * 17)
        end
    end

    if ControlState == ControlStates.LOAD_BOARD then
        if isAwesome and not hyperspeed then
            setColorF(256, 256, 256, 256)
            love.graphics.print("(press esc to speed)", TILE_SIZE * 3 - 12, TILE_SIZE * 17)
        end
    end

    if ControlState == ControlStates.OUTRO then

        setColorF(0, 0, 0, 196)
        love.graphics.rectangle("fill", 0, 0, WIN_WIDTH, WIN_HEIGHT)

        setColorF(256, 256, 256, 256)
        love.graphics.setFont(chatFont)

        if outroRunner == -1 then
            love.graphics.print("Enter your name: ", TILE_SIZE * 3, TILE_SIZE * 6)
            love.graphics.print(outro.username, TILE_SIZE * 3, TILE_SIZE * 8)

            love.graphics.print("<Press Enter to Save and Play Again>", TILE_SIZE * 3, TILE_SIZE * 10)
            love.graphics.print("<Press Escape to Save and Quit>", TILE_SIZE * 3, TILE_SIZE * 11)
        else
            love.graphics.print(outro.currentTextRender or "", TILE_SIZE * 3, TILE_SIZE * 7)
            if isAwesome then
                love.graphics.print("(press esc to skip)", TILE_SIZE * 3, TILE_SIZE * 17)
            end
        end
    end
end

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
        return Matrix.rotate90CC(Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1],
            Tetris.sizes[currentPiece][2])
    elseif spin == 3 then
        return Matrix.rotate180(Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1],
            Tetris.sizes[currentPiece][2])
    elseif spin == 4 then
        return Matrix.rotate90C(Tetris.pieces[currentPiece], Tetris.sizes[currentPiece][1],
            Tetris.sizes[currentPiece][2])
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
    return Matrix.collides(board, currentRows, COLS, getCurrentPiece(checkSpin), Tetris.sizes[currentPiece][1],
        Tetris.sizes[currentPiece][2], checkRow, checkCol)
end

local function beamKick(row, col, oldSpin, newSpin)
    local key = tostring(oldSpin) .. tostring(newSpin)
    local kickMap = Tetris.beamKick[key]

    for k = 1, #kickMap do
        local kr = -kickMap[k][2]
        local kc = kickMap[k][1]
        if not collides(row + kr, col + kc, newSpin) then
            return row + kr, col + kc, newSpin
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
    -- print(key)
    local kickMap = Tetris.wallKick[key]

    -- print(#kickMap)
    for k = 1, #kickMap do
        local kr = -kickMap[k][2]
        local kc = kickMap[k][1]
        if not collides(row + kr, col + kc, newSpin) then
            return row + kr, col + kc, newSpin
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
    if ControlState == ControlStates.OUTRO and outroRunner == -1 then
        if key == "backspace" then
            outro.username = string.sub(outro.username, 1, -2)
        end

        if key == "return" then
            ControlState = ControlStates.SAVE_BOARD
            pleaseRestart = true
        end

        if key == "escape" then
            ControlState = ControlStates.SAVE_BOARD
            pleaseRestart = false
        end
    elseif ControlState == ControlStates.OUTRO then
        if key == "escape" then
            outroRunner = -1
        end
    end

    if ControlState == ControlStates.INTRO or ControlState == ControlStates.LOAD_BOARD or ControlState ==
        ControlStates.SPAWN or ControlState == ControlStates.FALL or ControlState == ControlStates.GROUND or
        ControlState == ControlStates.COLLAPSE or ControlState == ControlStates.GROW or ControlState ==
        ControlStates.SHRINK or ControlState == ControlStates.SCROLL_UP or ControlState == ControlStates.SCROLL_DOWN then

        Input.keyPressed(key, scan, isrepeat)
        Framerate.keyPressed(key, scan, isrepeat)
    end
end

function love.keyreleased(key)
    Input.keyReleased(key)
end

function love.textinput(text)
    if ControlState == ControlStates.OUTRO and outroRunner == -1 then
        if #outro.username > 24 then
            return
        end

        if Input.TYPING_KEYS[text] then
            outro.username = outro.username .. text
        end

        if text == " " then
            outro.username = outro.username .. "_"
        end
    end
end

function love.load()
    print("Starting the game ...")
    math.randomseed(os.time())

    love.keyboard.setKeyRepeat(false)
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    love.graphics.setBackgroundColor(38 / 255.0, 38 / 255.0, 38 / 255.0)
    love.graphics.setLineWidth(4)

    timerFont = love.graphics.newFont("fonts/coders_crux.ttf", 72)
    chatFont = love.graphics.newFont("fonts/coders_crux.ttf", 36)

    WIN_WIDTH, WIN_HEIGHT = love.window.getMode()
    TILE_SIZE = ((WIN_WIDTH + WIN_HEIGHT) / 4) / COLS;

    currentBag = shuffle({1, 2, 3, 4, 5, 6, 7})
    nextBag = shuffle({1, 2, 3, 4, 5, 6, 7})

    currentBagIndex = 1

    currentPiece = currentBag[1]
    nextPiece = currentBag[2]
    currentPieceRow = 2
    currentPieceCol = 4
    currentPieceSpin = 1

    shouldLoadBoard = true
    tookLines = 0

    intro = {
        currentLine = 1,
        currentTextRender = ""
    }

    outro = {
        currentLine = 1,
        currentTextRender = "",
        rank = Dialogue.outroLazy,
        username = ""
    }

    timerActive = false
    timer = GAME_TIME

    Input.initialize()

    local bn, lm, nm, bd = Net.getBoard()
    if bn ~= -1 then
        returnBoardNumber = bn
        -- print(returnBoardNumber)
        returnName = nm
        returnTimestamp = lm
        loadedBoard = bd
    end

    -- print(bd)

    isAwesome = Save.isAwesome()
    if isAwesome then
        print(isAwesome .. " is awesome")
        outro.username = isAwesome
    end

    board = Matrix.create(currentRows, COLS, 0)
end

local collapser = function(board)
    local needToCollapse = false
    local bottomRow = nil

    topRow = nil
    for i = 1, currentRows do
        local fullRow = true
        local emptyRow = false
        for j = 1, COLS do
            if board[i * COLS + j] == 0 then
                fullRow = false
            end

            if topRow == nil and board[i * COLS + j] ~= 0 then
                topRow = i
            end
        end

        if fullRow then
            needToCollapse = true
            break
        end
    end

    if needToCollapse then
        for delay = 1, 5 do
            board = coroutine.yield(board)
        end
    end

    for i = 1, currentRows do
        local fullRow = true
        for j = 1, COLS do
            if board[i * COLS + j] == 0 then
                fullRow = false
            end
        end

        if fullRow then
            if bottomRow == nil then
                bottomRow = i
            end

            for j = 1, COLS do
                table.remove(board, i * COLS + j)
                table.insert(board, 1 * COLS + 1, 0)
            end

            tookLines = tookLines + 1
        end
    end

    if needToCollapse then
        for delay = 1, 5 do
            board = coroutine.yield(board)
        end
    end

    return board
end

local grower = function(board)
    local topRow = currentRows
    for i = 1, currentRows do
        for j = 1, COLS do
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
        for i = 1, ROW_GROWTH do
            for j = 1, COLS do
                table.insert(board, 1 * COLS + 1, 0)
            end
            board = coroutine.yield(board)
        end
        currentRows = currentRows + ROW_GROWTH
    end

    return board
end

local shrinker = function(board)
    if currentRows <= MIN_ROWS then
        return board
    end

    local topRow = currentRows
    for i = 1, currentRows do
        for j = 1, COLS do
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
        for i = 1, ROW_SHRINK do
            for j = 1, COLS do
                table.remove(board, 1 * COLS + 1)
            end
            board = coroutine.yield(board)
        end
        currentRows = currentRows - ROW_SHRINK
    end

    return board
end

function shouldScrollDown()
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

local scrollDown = function()
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
        for delay = 1, 20 do
            coroutine.yield()
        end
    end
end

local scrollUp = function()
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
        for delay = 1, 15 do
            coroutine.yield()
        end
    end
end

local boardLoader = function(args)
    for delay = 1, 25 do
        args = coroutine.yield({board, boardStr})
    end

    local board = args[1]
    local boardStr = args[2]

    local boardStrIndex = #boardStr

    local insertRows = math.floor(#boardStr / COLS)
    currentRows = insertRows

    local drewAnything = false
    for i = insertRows, 1, -1 do
        if Input.pollInput("escape") then
            hyperspeed = true
        end

        for j = COLS, 1, -1 do
            board[i * COLS + j] = tonumber(string.sub(boardStr, boardStrIndex, boardStrIndex))
            if board[i * COLS + j] ~= 0 then
                drewAnything = true
            end

            boardStrIndex = boardStrIndex - 1
        end

        if drewAnything then
            del = 4
            if isAwesome then
                del = 2
            end

            -- if we're in hyperspeed, we let some full rows get drawn before delaying
            -- rather than delaying per row
            hyperspeedModulo = math.max(3, math.floor(insertRows / 20))
            if (not hyperspeed) or (i % hyperspeedModulo == 0) then
                for delay = 1, del do
                    args = coroutine.yield({board, boardStr})
                end
            end
        end

        viewportDelta = math.max(math.min(insertRows - 16, i - 6) - 1, 0)

        board = args[1]
        boardStr = args[2]
    end

    showTitle = true
    -- to disable the skip text
    hyperspeed = true
    local boardLen = 65
    if isAwesome then
        boardLen = 90
    end

    love.window.setTitle('Junk (for LD40, board by ' .. returnName .. ')')
    for delay = 1, boardLen do
        args = coroutine.yield({board, boardStr})
    end
    showTitle = false
    for delay = 1, 15 do
        args = coroutine.yield({board, boardStr})
    end

    return {board, boardStr}
end

function love.update(dt)
    if ControlState == ControlStates.INTRO then

        if introRunner == nil then
            introRunner = coroutine.create(Dialogue.speak)
        end

        if coroutine.status(introRunner) == 'dead' then
            introRunner = coroutine.create(Dialogue.speak)
            intro.currentLine = intro.currentLine + 1
            intro.currentTextRender = ""

            if intro.currentLine > #Dialogue.lines then
                introRunner = nil
                ControlState = ControlStates.LOAD_BOARD
            end
        else
            if intro.currentLine == Dialogue.nameLine then
                _, args = coroutine.resume(introRunner,
                    {Dialogue.lines[intro.currentLine] .. "..." .. returnName .. "?                     ", MAX_LINE,
                     intro.currentTextRender})
            else
                _, args = coroutine.resume(introRunner,
                    {Dialogue.lines[intro.currentLine], MAX_LINE, intro.currentTextRender})
            end

            intro.currentTextRender = args[3]
        end

        if Input.pollInput("escape") then
            introRunner = nil
            ControlState = ControlStates.LOAD_BOARD
        end
    elseif ControlState == ControlStates.OUTRO then
        if outroRunner == nil then
            outroRunner = coroutine.create(Dialogue.speak)
        end

        if outroRunner ~= -1 and coroutine.status(outroRunner) == 'dead' then
            outroRunner = coroutine.create(Dialogue.speak)
            outro.currentLine = outro.currentLine + 1
            outro.currentTextRender = ""

            if outro.currentLine > #(outro.rank) then
                outro.currentLine = #(outro.rank)
                outroRunner = -1
            end
        elseif outroRunner ~= -1 then
            _, args = coroutine.resume(outroRunner, {outro.rank[outro.currentLine], MAX_LINE, outro.currentTextRender})
            outro.currentTextRender = args[3]
        end
    elseif ControlState == ControlStates.LOAD_BOARD then
        if currentBoardLoader == nil then
            currentBoardLoader = coroutine.create(boardLoader)
        end

        -- collapse empty rows
        if coroutine.status(currentBoardLoader) == 'dead' then
            ControlState = ControlStates.SPAWN
            currentBoardLoader = nil
        else
            _, res = coroutine.resume(currentBoardLoader, {board, loadedBoard})

            return
        end
    elseif ControlState == ControlStates.SAVE_BOARD then
        if returnBoardNumber ~= nil then
            if outro.username == nil or #(outro.username) <= 0 then
                outro.username = "john_titor"
            end

            if isAwesome ~= nil then
                Save.save(outro.username)
                isAwesome = nil
            end

            Net.saveBoard(returnBoardNumber, returnTimestamp, outro.username, Matrix.asString(board, currentRows, COLS))
            ControlState = ControlStates.DONE
        end
        return
    elseif ControlState == ControlStates.DONE then
        if pleaseRestart then
            love.event.quit("restart")
        else
            love.event.quit()
        end
    end

    if currentBagIndex > #currentBag then
        currentBag = nextBag
        nextBag = shuffle({1, 2, 3, 4, 5, 6, 7})
        currentBagIndex = 1
    end

    if timerActive then
        timer = timer - dt

        if timer <= 0 then
            ControlState = ControlStates.OUTRO
            timer = 0
            timerActive = false

            if currentTall - startingTall <= 0 then
                if tookLines >= 30 then
                    outro.rank = Dialogue.outroGreat
                else
                    outro.rank = Dialogue.outroGood
                end
            else
                if tookLines >= 20 then
                    outro.rank = Dialogue.outroLazy
                else
                    outro.rank = Dialogue.outroBad
                end
            end
        end
    end

    if ControlState == ControlStates.SPAWN then
        if not timerActive then
            timerActive = true
        end

        currentPiece = currentBag[currentBagIndex]
        if currentBagIndex >= 7 then
            nextPiece = nextBag[1]
        else
            nextPiece = currentBag[currentBagIndex + 1]
        end

        currentBagIndex = currentBagIndex + 1

        currentPieceRow, currentPieceCol = spawn(board, currentPiece)
        currentPieceSpin = 1

        currentTall = getNumberOfLines()
        if startingTall == nil then
            startingTall = currentTall
        end

        fallTimer = -0.2
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
            currentPieceRowNext, currentPieceColNext, currentPieceSpinNext = wallKick(currentPieceRowNext,
                currentPieceColNext, currentPieceSpin, currentPieceSpinNext, currentPiece)
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

            Input.updatePost(dt)
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
            -- print("HIT GROUND")
        end

        currentPieceRow = currentPieceRowNext
        currentPieceCol = currentPieceColNext
        currentPieceSpin = currentPieceSpinNext

        if shouldScrollDown() then
            -- print("SCROLLIN")
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
            currentPieceRowNext, currentPieceColNext, currentPieceSpinNext = wallKick(currentPieceRowNext,
                currentPieceColNext, currentPieceSpin, currentPieceSpinNext, currentPiece)
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
                groundTimer = -GROUND_ELAPSE
            end
        end

        if Input.pollInput("up") then
            -- you can lock in pieces that are grounded by hard-dropping
            groundTimer = GROUND_ELAPSE
        end

        -- if a movement gave us space to fall again
        if not collides(currentPieceRowNext + 1, currentPieceColNext, currentPieceSpinNext) then
            fallTimer = 0
            groundTimer = 0

            currentPieceRow = currentPieceRowNext
            currentPieceCol = currentPieceColNext
            currentPieceSpin = currentPieceSpinNext
            ControlState = ControlStates.FALL

            Input.updatePost(dt)
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
        board = Matrix.applyInto(board, currentRows, COLS, getCurrentPiece(currentPieceSpin),
            Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], currentPieceRow, currentPieceCol)
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
        -- print("GROW")
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

    Input.updatePost(dt)
end

function love.draw()
    -- Matrix.print(getCurrentPiece(), Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2])

    local boardWithGhost = board
    if ControlState == ControlStates.FALL or ControlState == ControlStates.SCROLL_DOWN then
        local ghostRow = getSlamRow(currentPieceCol, currentPieceRow, currentPieceSpin)
        local ghostPiece = Matrix.ghostify(getCurrentPiece(currentPieceSpin), Tetris.sizes[currentPiece][1],
            Tetris.sizes[currentPiece][2])
        boardWithGhost = Matrix.applyInto(board, currentRows, COLS, ghostPiece, Tetris.sizes[currentPiece][1],
            Tetris.sizes[currentPiece][2], ghostRow, currentPieceCol)
    end

    local currentBoard = boardWithGhost
    if ControlState == ControlStates.FALL or ControlState == ControlStates.GROUND or ControlState ==
        ControlStates.SCROLL_DOWN or ControlState == ControlStates.COMPLETE then
        currentBoard = Matrix.applyInto(boardWithGhost, currentRows, COLS, getCurrentPiece(currentPieceSpin),
            Tetris.sizes[currentPiece][1], Tetris.sizes[currentPiece][2], currentPieceRow, currentPieceCol)
    end

    -- Matrix.print(currentBoard, currentRows, COLS)
    drawBoard(currentBoard, currentRows, COLS)
    saveBoard(currentBoard, currentRows, COLS)
end
