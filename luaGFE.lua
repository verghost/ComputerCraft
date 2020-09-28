
--Lua Graphic File Explorer Version 1.1
--File Format = {x_coord, y_coord, object_file}
--Warning: Hard-Coded values ahead!

--Bless this mess

--Terminal Size
local w, h = term.getSize()

--Graphics Constants
local xB = 4 --X-Border
local rW = 7 --Right click menu width
local rOH = 1 --RC menu option height
local tbW, tbH = 8, 3 --Text box width, height
local oW, oH = 7, 3 --Object width, height
local tW, tH = 3, 2 --Object text width, height

--Current Directory
local cDir = shell.dir()
local origin = shell.dir()

--Objects
local sel = {x = nil, y = nil, obj = nil} --Selected file/directory
local clip = nil --Clipboard
local rMenu = {x= nil, y = nil, h = nil, options = nil} --Right-click menu

--Colors
local dColor, fColor, hColor, rmColor

--Flags
local isRC --Right click flag
local isRoot = (shell.dir() == "") --Root Flag
local isROM = string.sub(shell.dir(), 1, 3) == "rom"

--List of objects for a directory as well as length
local objList = {}
local numObj = 0
local selI = nil


if term.isColour and term.isColour() then
	dColor, fColor, hColor, rmColor = colors.yellow, colors.lightBlue, colors.lightGray, colors.gray
else
	error("Must run on advanced terminal!")
end


--LOCAL UTILITIES

--Save function from "edit" program
local function save( _sPath )
	-- Create intervening folder
	local sDir = _sPath:sub(1, _sPath:len() - fs.getName(_sPath):len() )
	if not fs.exists( sDir ) then
		fs.makeDir( sDir )
	end

	-- Save
	local file = nil
	local function innerSave()
		file = fs.open( _sPath, "w" )
		if file then
			for n, sLine in ipairs( tLines ) do
				file.write( sLine .. "\n" )
			end
		else
			error( "Failed to open ".._sPath )
		end
	end
	
	local ok, err = pcall( innerSave )
	if file then 
		file.close()
	end
	return ok, err
end

--Returns color the object should be
local function getObjColor(o)
	if fs.isDir("/" .. tostring(cDir) .. "/" .. tostring(o.obj)) then
		return dColor
	else
		return fColor
	end
end

--Dutch Rounding
local function rnd(num)
	return math.floor(num + 0.5)
end

--Add spaces to center text
local function center(text)
	local l = tW-math.floor(text:len() / 2)
	for i = 1, l do
		text = " " .. text
	end
	return text
end

--Get text formatted for File Explorer
local function textCutoff(text)
	local l = text:len()
	local lim = (2 * tW) + 1
	if l > lim then
		local extra
		if l <= (lim*2) then
			extra = center(string.sub(text, lim+1))
		else
			extra = string.sub(text, lim+1, (lim*2)-3) .. "..."
		end
		return string.sub(text, 1, lim), extra 
	else
		return center(text), ""
	end
end

--Get Stuff In cDir
local function getStuff()

	-- Get all the files in the directory
	local sDir = "/" .. cDir
	local yI = 7 --Y increment
	
	-- Sort into dirs/files, and calculate column count
	local tAll = fs.list( sDir )
	local tFiles = {}
	local tDirs = {}
	numObj = 0
	objList = {}
	
	for n, sItem in pairs( tAll ) do
		if string.sub( sItem, 1, 1 ) ~= "." then
			local sPath = fs.combine( sDir, sItem )
			if fs.isDir( sPath ) then
				table.insert( tDirs, sItem )
			else
				table.insert( tFiles, sItem )
			end
		end
	end
	
	table.sort( tDirs )
	table.sort( tFiles )
	local inc = 1
	local xInc, yInc = xB, 2
	for n, d in pairs(tDirs) do
		if inc > 7 then
			inc = 1
			yInc = yInc + oH
			xInc = xB
		end
		table.insert(objList, {x = xInc, y = yInc, obj = d})
		xInc = xInc + oW
		inc = inc + 1
	end
	for n, f in pairs(tFiles) do
		if inc > 7 then
			inc = 1
			yInc = yInc + oH
			xInc = xB
		end
		table.insert(objList, {x = xInc, y = yInc, obj = f})
		xInc = xInc + oW
		inc = inc + 1
	end
	
	numObj = #objList
	
	if tDirs == {} and tFiles == {} then
		return nil
	else
		return 1
	end
end


--GRAPHICS

--Draw file explorer
local function drawFE()
	getStuff()
	term.clear()
	
	local color = nil
	local t1, t2
	
	if #objList > 35 then
		--Add screen scroll
	end
	
	for n, o in pairs(objList) do
		if fs.exists("/" .. tostring(cDir) .. "/" .. tostring(o.obj)) then
			color = getObjColor(o)
			t1, t2 = textCutoff(tostring(o.obj))
			paintutils.drawPixel(o.x, o.y, color)
			term.setBackgroundColor(colors.black)
			term.setCursorPos(o.x-tW, o.y+1)
			print(t1)
			term.setCursorPos(o.x-tW, o.y+2)
			print(t2)
		end
	end
	
	
	if not isRoot then
		term.setCursorPos(48, 18)
		term.write("<--")
	end
	term.setCursorPos(2, 18)
	print("To exit press \"Q\"")
end

--Display brief message
local function alert(text, redraw)
	paintutils.drawLine((w/2)-(tbW-1), h/2, (w/2)+tbW-1, h/2, colors.red)
	term.setCursorPos(w/2-(rnd(text:len()/2)), h/2)
	term.write(text)
	term.setBackgroundColor(colors.black)
	local t = os.startTimer(1)
	local id, p
	repeat
		id, p = os.pullEvent("timer")
	until p == t
	redraw()
end

--Highlights selection given mouse x and mouse y
local function drawSel(mX, mY)

	--Get index from mouse x and y
	local nX = rnd((mX-xB) / oW)
	local nY = rnd((mY-2) / (oH))
	local ind = (nX + (nY * 7)) + 1
	
	--Redraw last selected object if it hasn't been deleted
	if not (sel.obj == objList[ind]) and not (sel.x == nil) and fs.exists("/" .. tostring(cDir) .. "/" .. tostring(sel.obj)) then
		local color = getObjColor(sel)
		paintutils.drawFilledBox(sel.x-math.floor(oW/2), sel.y-(math.floor(oH/2)-1), sel.x+math.floor(oW/2), sel.y+math.floor(oH/2), colors.black)
		paintutils.drawPixel(sel.x, sel.y, color)
		
		term.setBackgroundColor(colors.black)
		term.setCursorPos(sel.x-tW, sel.y+1)
		local t1, t2 = textCutoff(tostring(sel.obj))
		print(t1)
		term.setCursorPos(sel.x-tW, sel.y+2)
		print(t2)
	end
	
	--If empty space is clicked return. We do not have to draw a new HL box.
	if ind > #objList then
		sel = {x = nil, y = nil, obj = nil}
		selI = nil
		return 
	end
	
	--If we haven't clicked on the same object, then draw new stuff
	if not (sel.obj == objList[ind]) then
		sel = objList[ind]
		selI = ind
		--Set height of hl box
		local height = 1
		if (tostring(sel.obj)):len() > oW then
			height = 2
		end
		
		--draw highlight
		paintutils.drawPixel(sel.x, sel.y, hColor)
		term.setBackgroundColor(colors.black)
		term.setCursorPos(sel.x-tW, sel.y+1)
		term.setTextColour(hColor)
		local t1, t2 = textCutoff(tostring(sel.obj))
		print(t1)
		term.setCursorPos(sel.x-tW, sel.y+2)
		print(t2)
		term.setTextColour(colors.white)
	else
		sel = {x = nil, y = nil, obj = nil}
		selI = nil
	end
end

--Determine if we clicked on the rMenu and return the selected option
local function drawRCSelect(x, y)
	local xEnd = rMenu.x + rW - 1
	local yEnd = rMenu.y + (rMenu.h * rOH) - 1
	if ((x >= rMenu.x) and (x <= xEnd)) and ((y >= rMenu.y) and (y <= yEnd)) then
		local ind = y - rMenu.y + 1
		local opt = rMenu.options[ind]
		
		paintutils.drawLine(rMenu.x, rMenu.y + ((ind-1) * rOH), xEnd, rMenu.y + ((ind-1) * rOH), rmColor)
		
		term.setCursorPos(rMenu.x, rMenu.y + ((ind-1) * rOH))
		term.write(opt)
		
		sleep(0.01) --Aesthetic delay
		
		term.setBackgroundColor(colors.black)
		return opt
	end
	return nil
end

--Draw right click
local function drawRC(x, y)
	
	drawSel(x, y)
	
	if not sel.obj then
		if clip then
			rMenu.options = {"File", "Folder", "Paste"}
		else
			rMenu.options = {"File", "Folder"}
		end
	else
		if fs.isDir("/" .. tostring(cDir) .. "/" .. tostring(sel.obj)) then
			rMenu.options = {"Open", "Copy", "Delete", "Rename"}
		else
			rMenu.options = {"Run", "Edit", "Copy", "Delete", "Rename"}
		end
	end
	
	rMenu.h = #(rMenu.options)
	rMenu.x = x+1
	rMenu.y = y+1
	
	local optY
	for i = 0, rMenu.h-1 do
		optY = (y + ((i) * rOH)) + 1
		paintutils.drawFilledBox(x+1, optY, x+rW, (optY + rOH) - 1, colors.lightGray)
		
		term.setCursorPos(x+1, optY)
		term.write(rMenu.options[i+1])
		
		sleep(0.01) --Aesthetic delay
	end
	term.setBackgroundColor(colors.black)
end

--Get name from user or params
local function getNName(flag)
	local msg = ""
	if flag then
		msg = "Enter a name"
	else
		msg = "Enter parameters (Seperated by spaces)"
	end
	
	--Redraw for alert
	local function rd()
		term.clear()
		term.setCursorPos(1, h-2)
		term.write(msg)
		term.setCursorPos(1, h-1)
	end
	
	--Initial draw
	rd()
	
	local line = ""
	while true do
		line = read()
		if line:len() > 0 or not flag then
			break
		else
			alert("You must enter a name first", rd)
		end
	end
	return line
end


--CMD LINE FUNCTIONS FOR GUI

--Change Directory
local function chDir(dArg)
	local lDir = cDir
	
	shell.run("cd " .. tostring(dArg))
	cDir = shell.dir()
	
	sel = {x = nil, y= nil, obj = nil}
	selI = nil
	numObj = 0
	objList = {}
	
	--update flags
	isROM = (string.sub(shell.dir(), 1, 3) == "rom")
	isRoot = (shell.dir() == "")
end

--Copy program modified to bypass shell.resolve method
local function copy_obj(src, dest)
	local sSource = src
	local sDest = dest
	local tFiles = fs.find( sSource )
	if #tFiles > 0 then
		for n,sFile in ipairs( tFiles ) do
			if fs.isDir( sDest ) then
				fs.copy( sFile, fs.combine( sDest, fs.getName(sFile) ) )
			elseif #tFiles == 1 then
				fs.copy( sFile, sDest )
			else
				printError( "Cannot overwrite file multiple times" )
				return
			end
		end
	else
		printError( "No matching files" )
	end
end

--Execute a specific command
local function exec(cmd, arg)
	local nName
	
	if isROM and ((cmd == "Paste") or (cmd == "Delete") or (cmd == "Rename") or (cmd == "File") or (cmd == "Folder") or (cmd == "Cut")) then
		alert("You do not have write access to this directory", drawFE)
		return
	end
	
	if cmd == "Run" then
		term.setCursorPos(1, 1)
		term.clear()
		local params = getNName(false)
		local e = shell.run(sel.obj .. " " .. params)
		if not e then -- Error catch
			term.write("ERROR!")
			parallel.waitForAll(
			function() sleep(0.1) end,
			function() os.pullEvent("mouse_click") end
			)
		end
		term.setCursorPos(1, 1)
		term.clear()
	elseif cmd == "Open" then
		chDir(sel.obj)
	elseif cmd == "Copy" then
		clip = cDir .. "/" .. sel.obj
	elseif cmd == "Paste" then
		copy_obj(clip, cDir .. "/")
	elseif cmd == "Edit" then
		shell.run("edit " .. sel.obj)
	elseif cmd == "Delete" then
		shell.run("delete " .. sel.obj)
	elseif cmd == "Rename" then
		nName = getNName(true)
		shell.run("rename " .. sel.obj .. " " .. nName)
	elseif cmd == "File" then
		nName = getNName(true)
		if not fs.exists(cDir .. "/" .. nName) then
			local ok, err = save(cDir .. "/" .. nName)
		end
	elseif cmd == "Folder" then
		nName = getNName(true)
		if not fs.exists(cDir .. "/" .. nName) then
			shell.run("mkdir " .. nName)
		end
	end
	
	drawFE()
	
end


--MAIN LOOP
--Clear screen
term.clear()

--Retrieve and draw initial directory
drawFE()

--Setup main loop variables
local id, p1, p2, p3 --Event Params
local tmr = nil -- timer
isRC = false
local fClick = {0, 0} --First click

while true do
	id, p1, p2, p3 = os.pullEvent()
	if id == "mouse_click" then --Click
		if p1 == 1 then	--Left click
			if isRC then
				isRC = false
				local opt = drawRCSelect(p2, p3)
				if opt then
					exec(opt)
				end
				drawFE()
			end
			if p2 >= 48 and p3 >= 18 and not isRoot then --Going back
				chDir("..")
				drawFE()
			elseif not tmr then --No first click yet
				drawSel(p2, p3)
				tmr = os.startTimer(0.3)
				fClick = {p2, p3}
			elseif p2 == fClick[1] and p3 == fClick[2] then --Second click?
				tmr = nil
				if sel.obj then
					if fs.isDir("/" .. tostring(cDir) .. "/" .. tostring(sel.obj)) then
						if not (sel.obj == "help") then --Fix help directory
							exec("Open")
						end
					else
						exec("Run")
					end
				end
			end
		elseif p1 == 2 then --Right click
			drawFE()
			drawRC(p2, p3)
			isRC = true
		end
	elseif id == "timer"  and p1 == tmr then --Timer code
		tmr = nil
	elseif id == "key" then --Key press
		if p1 == keys.q then
			break
		end
	end
end

--Return to origin directory
shell.run("cd /" .. origin)

parallel.waitForAll(
	function() sleep(0.1) end
	--function() os.pullEvent( "mouse_click" ) end
)
term.setCursorPos(1,1)
term.clear()