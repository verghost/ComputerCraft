
--TODO: COLOR SIZE

local w,h = term.getSize()

local size = 8
local cSize = 6

local xO = 4
local yO = 0

local score = 0
local hs = nil
local color = 0

local blokz = {}
local clz = {}
local hLBlok
local clickCheck = 0
local blokSym = "H"
local validXBlok = false
local validYBlok = false


--Setup blok colors
if term.isColor() then
    clz = {colors.blue, colors.yellow, colors.red, colors.brown, colors.purple, colors.green, colors.pink, colors.lime, colors.black}
else
	error( "Cannot load on computer without colors", 2 )
end

--Get valid board size
-- repeat
	-- term.setCursorPos(1, 14)
	-- term.clearLine()

	-- cwrite("Enter board size (5-12):")
	-- size = read()
	
	-- size = tonumber(size)
	-- if not size then
		-- size = 0
	-- end
-- until size > 4 and size < 13


--GAME UTILS

--Draws the menu/Updates score values
local function drawMenu()
	
	term.setTextColour(colors.white)
	
	term.setCursorPos(41, 16)
	term.write("SCORE ")
	
	term.setCursorPos(48, 16)
	term.write(tostring(score))
	term.setTextColour(colors.white)
	
	term.setTextColour(colours.white)
	
end

--Dutch Rounding
local function rnd(num)
	return math.floor(0.5 + (num/2))
end

--Creates a square at x, y of color c
local function makeBlok(x, y, c)
	local x_n = (x * 3) + xO
	local y_n = (y * 2) + yO
	term.setCursorPos(x_n, y_n)
	paintutils.drawBox(x_n, y_n, x_n+2, y_n+1, c)
	term.setBackgroundColor(colors.black)
end

--Swap b1 and b2
local function swap(blok1, blok2)
	local temp = blokz[blok1[2]][blok1[1]]
	blokz[blok1[2]][blok1[1]] = blokz[blok2[2]][blok2[1]]
	blokz[blok2[2]][blok2[1]] = temp
	makeBlok(blok1[1], blok1[2], clz[blok2[3]])
	makeBlok(blok2[1], blok2[2], clz[blok1[3]])
end

--Draws the board
local function drawBoard()
	for col = 1, size do
		for row = 1, size do
			makeBlok(row, col, clz[blokz[col][row]])
		end
	end
end

--Are blok1 and blok2 adjacent
local function areAdjacent(blok1, blok2)
	local x1, x2, y1, y2 = blok1[1], blok2[1], blok1[2], blok2[2]
	return ((math.abs(x1-x2) == 1) and (math.abs(y1-y2) == 0)) or ((math.abs(y1-y2) == 1) and (math.abs(x1-x2) == 0))
end

local function makeCheckableCopy()
    local copyBlokz = {}
	for col = 1, (size + 3) do
		copyBlokz[col] = {}
        for row = 1, (size + 3) do
			if row <= size and col <= size then
				copyBlokz[col][row] = blokz[col][row]
			else
				copyBlokz[col][row] = 0
			end
	    end
    end
    return copyBlokz
end

--Clears bloks found to be matching
local function clear(matchedBlokz, l)
	local inc = 0
	for i = 1, l do
		inc = inc + 1
		blokz[matchedBlokz[i][2]][matchedBlokz[i][1]] = 9
		makeBlok(matchedBlokz[i][1], matchedBlokz[i][2], colors.black)
    end
    score = score + inc
	drawMenu()
end

local function fall(mb, l)
	local blok
	for i = 1, l do
		sleep(0.2)
		blok = mb[i]
		while blokz[blok[2]][blok[1]] == 9 do
			if blok[2] == 1 then
				blokz[blok[2]][blok[1]] = math.floor(math.random(1, cSize))
				makeBlok(blok[1], blok[2], clz[blokz[blok[2]][blok[1]]])
			else
				swap({blok[1], blok[2], blokz[blok[2]][blok[1]]}, {blok[1], blok[2]-1, blokz[blok[2]-1][blok[1]]})
				blok[2] = blok[2] - 1
				--print(toString(blok[2]))
			end
		end
	end
	drawBoard()
end

--Check pattern array
local function swapCheck()
	local matchedBlokz = {}
	local inc = 0
    for col = 1, size do
        for row = 1, size do
            if (row <= size - 2) then
                if (blokz[col][row] == blokz[col][row + 1]) and (blokz[col][row] == blokz[col][row + 2]) then
                    matchedBlokz[inc+1] = {row, col}
                    matchedBlokz[inc+2] = {row+1, col}
                    matchedBlokz[inc+3] = {row+2, col}
					inc = inc + 3
                end
            end
            if (col <= size - 2) then
                if (blokz[col][row] == blokz[col + 1][row] and blokz[col][row] == blokz[col + 2][row]) then
                    matchedBlokz[inc+1] = {row, col}
                    matchedBlokz[inc+2] = {row, col+1}
                    matchedBlokz[inc+3] = {row, col+2}
					inc = inc + 3
                end
            end
        end
    end
    if not (inc == 0) then
        clear(matchedBlokz, inc)
		fall(matchedBlokz, inc)
		swapCheck()
        return true
    end
	return false
end

--Can the player continue?
local function canMakeMove()
	local cBlokz = makeCheckableCopy()
	local patternz = {{{0, 0}, {0, 1}, {0, 3}}, {{0, 2}, {1, 0}, {1, 1}}, {{0, 0}, {0, 1}, {1, 2}}, {{0, 0}, {1, 1}, {1, 2}}, {{0, 0}, {0, 2}, {0, 3}}, {{0, 1}, {0, 2}, {1, 0}}, {{0, 1}, {1, 0}, {1, 2}}, {{0, 0}, {0, 2},{1, 1}}}
	local blok1, blok2, blok3
	local num1, num2
	for col = 1, size do
		for row = 1, size do
			for patt = 1, 8 do
                num1 = col + patternz[patt][3][2]
                num2 = row + patternz[patt][3][1]
				blok1 = cBlokz[col + patternz[patt][1][2]][row + patternz[patt][1][1]]
				blok2 = cBlokz[col + patternz[patt][2][2]][row + patternz[patt][2][1]]
				blok3 = cBlokz[num1][num2]
                if (blok1 == blok2) and (blok1 == blok3) and (not (blok1 == 0)) and (not (blok2 == 0)) and (not (blok3 == 0)) then
					return true
				else
					blok1 = cBlokz[col+patternz[patt][1][1]][row + patternz[patt][1][2]]
					blok2 = cBlokz[col+patternz[patt][2][1]][row + patternz[patt][2][2]]
					blok3 = cBlokz[col+patternz[patt][3][1]][row + patternz[patt][3][2]]
					if (blok1 == blok2) and (blok1 == blok3) and (not (blok1 == 0)) and (not (blok2 == 0)) and (not (blok3 == 0)) then
						return true
					end
				end
			end
		end
	end
	return false
end



--Handles click
local function klik(x, y)
	if clickCheck == 0 then
        clickCheck = 1
        hLBlok = {x, y, blokz[y][x]}
        makeBlok(x, y, colors.white)
    else
		local selBlok = {x, y, blokz[y][x]}
        clickCheck = 0
        if areAdjacent(hLBlok, selBlok) then
            swap(hLBlok, selBlok)
            if not swapCheck() then
                swap({hLBlok[1], hLBlok[2], selBlok[3]}, {selBlok[1], selBlok[2], hLBlok[3]})
			end
        else
			makeBlok(hLBlok[1], hLBlok[2], clz[blokz[hLBlok[2]][hLBlok[1]]])
		end
    end
end

---END OF UTILS


--Setup board
--TODO: Add nSize?
local function setup()
	local blok
	for col = 1, size do
		blokz[col] = {}
		for row = 1, size do
			while (not validXBlok) or (not validYBlok) do
				blok = math.floor(math.random(1, cSize))
				--Check for row match
				if row >= 3 and (not validXBlok) then
					if not ((blokz[col][row - 1] == blok) or (blokz[col][row - 2] == blok)) then
						validXBlok = true
					end
				else
					validXBlok = true
				end
				
				--Check for col match
				if col >= 3 and (not validYBlok) then
					if not ((blokz[col - 1][row] == blok) or (blokz[col - 2][row] == blok)) then
						validYBlok = true
					end
				else
					validYBlok = true
				end
			end
			
			blokz[col][row] = blok
			validXBlok = false
			validYBlok = false
			
		end
	end
end

--Game over
local function gameOver()
	term.clear()
	term.setCursorPos(w/3, h/2)
	print("Game Over!")
	parallel.waitForAll(
		function() sleep(1) end,
		function() os.pullEvent( "mouse_click" ) end
	)
	term.setCursorPos(1,1)
	term.clear()
end

--Clear Screen
term.clear()
--Draw Menu
drawMenu()
--Add closing "x"
term.setBackgroundColor(colors.black)
term.setCursorPos(w, 1)
term.setTextColour(colors.red)
print("x")
drawMenu()

--Setup valid game board
repeat
	setup()
until canMakeMove()


drawBoard()

local id, p1, p2, p3
--GAME LOOP--
--local game_running = true
while true do
	id, p1, p2, p3 = os.pullEvent()
	if id == "mouse_click" then
		if p2 == w and p3 == 1 then
			break
		else
			blokX = math.floor((p2 - xO) / 3)
			blokY = math.floor((p3 - yO) / 2)
			if ((blokX >= 1) and (blokX <= size)) and ((blokY >= 1) and (blokY <= size)) then
				klik(blokX, blokY)
			end
		end
		if not canMakeMove() then
			break
		end
	end
end

gameOver()