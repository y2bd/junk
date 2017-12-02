local Matrix = {}

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
                    print("SIDEOFF")
                    return true
                end
            end

            if b == nil and (t ~= 0) then
                print("OFFSIDES")
                return true
            end

            if (b ~= 0) and (t ~= 0) then
                print("COL")
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