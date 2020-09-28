
--State: 0 = blank, 1 = flagged, 2 = ?, 3 = dug
--Bless this mess

--Terminal size: width, height
local w, h = term.getSize()

--Colors for objects and numbers
local blankColor, flagColor = colors.gray, colors.red
local numColors = {colors.blue, colors.green, colors.red, colors.purple, colors.brown, colors.pink, colors.orange, colors.yellow,}

--Border for height and width
local xB, yB = 4, 1

--Game params
local sizeX, sizeY --Board size
local numBombs --Number of bombs

--Number of flags
local numFlags

--Board object
local board = {}

--Game vars
local timer --Timer vars
local tmr = nil
local tLeft --Time left
local bomb = 9 --Bomb value

--Patterns for checking adjacent squares
local patt = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}, {-1, 0}, {0, 1}, {1, 0}, {0, -1}}

--Read size of the board and number of bombs + timer y/n
local function getParams()
	--Get valid board sizes
	repeat
		term.setCursorPos(1, 14)
		term.clearLine()
		term.write("Enter board size X (10-41):")
		sizeX = read()
		
		term.setCursorPos(1, 14)
		term.clearLine()
		term.write("Enter board size Y (4-16):")
		sizeY = read()
		
		sizeX = tonumber(sizeX)
		sizeY = tonumber(sizeY)
		if not sizeX or not sizeY then
			sizeX, sizeY = 0, 0
		end
	until sizeX >= 8 and sizeX <= 41 and sizeY >= 4 and sizeY <= 16
	
	--Get bombs and timer settings
	local bombNums = {math.floor((sizeX * sizeY) * 0.1), math.floor((sizeX * sizeY) * 0.15), 
						math.floor((sizeX * sizeY) * 0.2), math.floor((sizeX * sizeY) * 0.8)}
	local yOrN = ""
	repeat
		term.clear()
		term.setCursorPos(1, 8)
		term.write("Min: 1")
		term.setCursorPos(1, 9)
		term.write("Easy: " .. tostring(bombNums[1]))
		term.setCursorPos(1, 10)
		term.write("Medium: " .. tostring(bombNums[2]))
		term.setCursorPos(1, 11)
		term.write("Hard: " .. tostring(bombNums[3]))
		term.setCursorPos(1, 12)
		term.write("Max: " .. tostring(bombNums[4]))
		term.setCursorPos(1, 14)
		term.write("Enter number of bombs:")
		numBombs = read()
		numBombs = tonumber(numBombs)
		
		term.clearLine()
		term.write("Timer? (y/n):")
		yOrN = read()
		yOrN = string.upper(tostring(yOrN))
		
		if yOrN == "Y" then
			timer = true
		elseif yOrN == "N" then
			timer = false
		end
		if not numBombs then
			numBombs = 0
		end
	until numBombs >= 1 and numBombs <= bombNums[4] and ((yOrN == "N") or (yOrN == "Y"))
	numFlags = numBombs
end

--Generate the game board tables
local function boardGen()
	board = {}
	for x=1, sizeX do
		board[x] = {}
		for y=1, sizeY do
			board[x][y] = {state = 0, val = 0}
		end
	end
end

--Dig out a 0 space and dig all adjacent 0 spaces
local function doDig(pX, pY)
	paintutils.drawPixel(pX, pY, colors.black)
	board[pX-xB][pY-yB].state = 3
	local function helper(list)
		local l = #list
		local ret = {}
		for s = 1, l do
			local x, y = list[s][1]-xB, list[s][2]-yB
			for i = 1, 8 do
				if board[x+patt[i][1]] and board[x+patt[i][1]][y+patt[i][2]] and not (board[x+patt[i][1]][y+patt[i][2]].val == bomb) and board[x+patt[i][1]][y+patt[i][2]].state == 0 then
					board[x+patt[i][1]][y+patt[i][2]].state = 3
					paintutils.drawPixel(list[s][1]+patt[i][1], list[s][2]+patt[i][2], colors.black)
					
					if (board[x+patt[i][1]][y+patt[i][2]].val == 0) then
						table.insert(ret, {list[s][1]+patt[i][1], list[s][2]+patt[i][2]})
					else
						term.setCursorPos(list[s][1]+patt[i][1], list[s][2]+patt[i][2])
						term.setTextColour(numColors[board[x+patt[i][1]][y+patt[i][2]].val])
						term.write(tostring(board[x+patt[i][1]][y+patt[i][2]].val))
					end
				end
			end
		end
		return ret
	end
	
	local h = helper({{pX, pY}})
	local temp = h
	local id, p1
	
	while not (#h == 0) do
		--sleep(0.01) --Aesthetic delay interferes with timer
		h = helper(h)
	end
	term.setTextColour(colors.white)
	term.setBackgroundColor(colors.black)
end

--Determine proper value for space
local function getVal(x, y)
	local ret = 0
	for i = 1, 8 do
		if board[x+patt[i][1]] and board[x+patt[i][1]][y+patt[i][2]] and (board[x+patt[i][1]][y+patt[i][2]].val == bomb) then
			ret = ret + 1
		end
	end
	return ret
end

--Generate the full game, along with timer and flag count
local function gameGen()
	boardGen()
	term.clear()
	
	--Set default params
	if timer then tLeft = 10000 end
	numFlags = numBombs
	
	--Set bombs
	local seedX, seedY = math.random(1, sizeX), math.random(1, sizeY)
	for i = 1, numBombs do
		while board[seedX][seedY].val == bomb do
			seedX, seedY = math.random(1, sizeX), math.random(1, sizeY)
		end
		board[seedX][seedY] = {state = 0, val = bomb}
	end
	
	--Set board values
	for x = 1, sizeX do
		for y = 1, sizeY do
			if not (board[x][y].val == bomb) then
				board[x][y].val = getVal(x, y)
			end
		end
	end
	
	--Draw Game board
	for x = 1, sizeX do
		if math.floor(x/2) == (x/2) then
			paintutils.drawPixel(x+xB, 1, colors.white)
		end
		for y = 1, sizeY do
			if not (math.floor(y/2) == (y/2)) then
				paintutils.drawPixel(xB, y+yB, colors.white)
				paintutils.drawPixel(xB-1, y+yB, colors.white)
			end
			paintutils.drawPixel(x+xB, y+yB, blankColor)
			----Debug Colors
			-- if board[x][y].val == 0 then
				-- paintutils.drawPixel(x+xB, y+yB, colors.cyan)
			-- elseif board[x][y].val == bomb then
				-- paintutils.drawPixel(x+xB, y+yB, blankColor)
			-- else
				-- paintutils.drawPixel(x+xB, y+yB, numColors[board[x][y].val])
			-- end
		end
	end
	
	--Draw timer + flag count
	term.setTextColour(colors.white)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(w,1)
	term.write("X")
	
	if timer then
		term.setCursorPos(w-4, 3)
		term.write("TIME:")
		term.setCursorPos(w-4, 4)
		term.write("0000")
	end
	
	term.setCursorPos(w-4, 7)
	term.write("FLAGS:")
	term.setCursorPos((w-4), 8)
	term.write(tostring(numFlags))
end

--Check for a winning board state
local function checkForWin()
	local chk = numBombs
	for x = 1, sizeX do
		for y = 1, sizeY do
			if board[x][y].state == 1 and board[x][y].val == bomb then
				chk = chk - 1
			end
		end
	end
	if chk == 0 then
		return true
	end
	return false
end

--Get a space on the board given mouse x and y
local function getSpace(x, y)
	if x > xB and y > yB and x <= (xB + sizeX) and  y <= (yB + sizeY)then
		return board[x-xB][y-yB]
	end
	return nil
end

--Game end display for exit/win/quit
local function gameEnd(msg, noQuit)
	term.setCursorPos(math.floor((w - string.len(msg)) / 2) + 1, h-1)
	term.write(msg)
	term.setCursorPos(math.floor((w - string.len(msg)) / 2) + 1, h)
	local cont = false
	local yorn = ""
	while noQuit do
		term.write("Play again? (y/n):")
		yorn = read()
		if yorn then
			if string.upper(yorn) == "Y" then
				cont = true
				break
			elseif string.upper(yorn) == "N" then
				break
			end
		end
	end
	
	if cont then
		gameGen()
		--Set timer
		if timer then
			tmr = os.startTimer(1)
		else
			tmr = nil
		end
	else
		term.clear()
		term.setCursorPos(math.floor((w - string.len(msg)) / 2) + 1, h)
		term.write("Click to quit...")
		parallel.waitForAll(
			function() os.pullEvent( "mouse_click" ) end
		)
		term.setCursorPos(1,1)

		term.setTextColour(colors.white)
		term.setBackgroundColor(colors.black)
		term.clear()
	end
	
	return cont
end


--MAIN LOOP

local id, p1, p2, p3

term.clear()
getParams()
gameGen()
--local kpx, kpy = 1, 1

--Turn on timer
if timer then
	tmr = os.startTimer(1)
end

while true do
	id, p1, p2, p3 = os.pullEvent()
	
	if id == "timer" and p1 == tmr then --Timer code
		tLeft = tLeft + 1
		term.setCursorPos(w-4, 4)
		term.write(string.sub(tostring(tLeft), 2))
		tmr = os.startTimer(1)
		if tLeft >= 19999 then
			if not gameEnd("You're out of time!", true) then
				break
			end
			break
		end
	end
	if id == "mouse_click" then
		if p1 == 1 and p2 == w and p3 == 1 then --Left click on "X"
			gameEnd("Goodbye!", false)
			break
		end
		local space = getSpace(p2, p3)
		if space then
			if p1 == 1 then --Left click
				if space.val == bomb then
					term.setCursorPos(p2, p3)
					term.write("B")
					if not gameEnd("You hit a bomb!", true) then
						break
					end
				elseif space.val == 0 then
					doDig(p2, p3)
				else
					board[p2-xB][p3-yB].state = 3
					paintutils.drawPixel(p2, p3, colors.black)
					term.setTextColour(numColors[space.val])
					term.setCursorPos(p2, p3)
					term.write(tostring(space.val))
					term.setTextColour(colors.white)
					term.setBackgroundColor(colors.black)
				end
			elseif p1 == 2 then --Right click
				if space.state == 0 and numFlags > 0 then
					numFlags = numFlags - 1
					space.state = 1
					paintutils.drawPixel(p2, p3, flagColor)
					if numFlags == 0 and checkForWin() then
						if not gameEnd("You win!", true) then
							break
						end
					end
				elseif space.state == 1 then
					numFlags = numFlags + 1
					space.state = 0
					paintutils.drawPixel(p2, p3, blankColor)
				end
				term.setBackgroundColor(colors.black)
				term.setCursorPos(w-4, 8)
				term.write(tostring(numFlags))
				if numFlags < 100 then term.write("   ") end
			end
		end
	end
end

