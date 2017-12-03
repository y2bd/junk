local Matrix = {}

local function getIn(m, i, j, c)
    return m[i * c + j]
end

local function setIn(v, m, i, j, c)
    m[i * c + j] = v
end

function Matrix.create(rows, cols, default)
    local mat = {}
    for i=1,rows do
        for j=1,cols do
            mat[i * cols + j] = default
        end
    end

    return mat
end

function Matrix.copy(rows, cols, from)
    local mat = {}
    for i=1,rows do
        for j=1,cols do
            mat[i * cols + j] = from[i * cols + j]
        end
    end

    return mat
end

function Matrix.rotate90C(base, rows, cols)
    local mat = {}
    for i=1,rows do
        for j=1,cols do
            setIn(getIn(base, i, j, cols), mat, (cols-j + 1), i, cols)
        end
    end

    return mat
end

function Matrix.rotate90CC(base, rows, cols)
    local mat = {}
    for i=1,rows do
        for j=1,cols do
            setIn(getIn(base, i, j, cols), mat, j, (rows-i+1), cols)
        end
    end

    return mat
end

function Matrix.rotate180(base, rows, cols)
    local mat = {}
    for i=1,rows do
        for j=1,cols do
            setIn(getIn(base, i, j, cols), mat, (rows-i+1), (cols-j+1), cols)
        end
    end

    return mat
end

function Matrix.ghostify(base, rows, cols)
    local mat = {}
    for i=1,rows do
        for j=1,cols do
            local source = base[i * cols + j]
            if source > 0 then
                source = source + 7
            end
            mat[i * cols + j] = source
        end
    end

    return mat
end

function Matrix.applyInto(base, rows, cols, target, tr, tc, ti, tj)
    local mat = {}
    for i=1,rows do
        for j=1,cols do
            mat[i * cols + j] = base[i * cols + j]
            if i >= ti and i < (ti + tr) and 
               j >= tj and j < (tj + tc) and 
               target[(i - ti + 1) * tc + (j - tj + 1)] ~= 0 then
                mat[i * cols + j] = target[(i - ti + 1) * tc + (j - tj + 1)]
            end
        end
    end
    
    return mat
end

function Matrix.collides(base, rows, cols, target, tr, tc, ti, tj)
    for i=ti,(ti+tr-1) do
        for j=tj,(tj+tc-1) do 
            local b = base[i * cols + j]
            local t = target[(i - ti + 1) * tc + (j - tj + 1)]

            if (t ~= 0) then
                if j < 1 or j > cols then 
                    return true
                end
            end

            if b == nil and (t ~= 0) then
                return true
            end

            if (b ~= 0) and (t ~= 0) then
                return true
            end
        end
    end

    return false
end

function Matrix.print(matrix, rows, cols)
    for i=1,rows do
        for j=1,cols do
            local val = matrix[i * cols + j]
            io.write(val)
            io.write(",")
        end
        print("")
    end
end

return Matrix