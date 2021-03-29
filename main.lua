local physics = require('physics')

local scenes = {'title', 'play', 'die', 'gameover'}
local scene

--translate
local wScreen, hScreen = display.actualContentWidth, display.actualContentHeight
local xScreen, yScreen = display.contentCenterX, display.contentCenterY
local xBird = xScreen - 50
local yBird = yScreen - 50
local yTitleRaw = -30
local yTitleNew = yScreen - 140
local yScoreBoard = yTitleNew + 100
local hLand = hScreen * 0.2
local rBirdCollision = 18
local wPipeCollision = 52
local hPipeCollision = 320

--variable
local bottomLine = hScreen * 0.8
local pipeDistance = xScreen + 10
local score = 0
local bestScore = 0
local leftEdge = -60
local pipeHoleY = 110
local speed = 3.4
local flyForce = 310
local gravity = 35
local maximumPipe = 3
local holePosition = {}
local triggerLog = {}

--object
local bird
local function makeTwoDimensional(iCount) M = {} for i = 1, iCount do M[i] = {} end return M end
local pipes = makeTwoDimensional(2)
local sensors = {}
local scoreBoard
local landSensor

--images
local ground
local getReady
local land
local textScore
local models = {}

--particle
local explosion

--testing
-- local DEBUG_MODE = true

function calcRandomHole()
	return 170 + 10 * math.random(15)
end

function setupSounds()
  	crashSound = audio.loadSound("Sounds/sfx_die.m4a")
	wingSound = audio.loadSound("Sounds/sfx_wing.m4a")
	swooshSound = audio.loadSound("Sounds/sfx_swooshing.m4a")
	pointSound = audio.loadSound("Sounds/sfx_point.m4a")
	hitSound = audio.loadSound("Sounds/sfx_hit.m4a")
end

function setupBackground()
	--Background
	ground = display.newImageRect("Assets/ground.png", wScreen, hScreen)
	ground.x, ground.y = xScreen, yScreen
end

function resetPipePosition(i ,j)
	pipes[i][j].x = wScreen + 100 + pipeDistance * (j - 1)
	pipes[i][j].y = holePosition[j] + ((pipes[i][j].image.height + pipeHoleY) / 2) * (i == 1 and -1 or 1)
	if i == 1 and sensors[j] then sensors[j].x = pipes[1][j].x + wPipeCollision / 2 - rBirdCollision * 2 end
end

function setupParticle()
	local params = {
          textureFileName = "Assets/habra.png",
          startParticleSize = 30,
		  startParticleSizeVariance = 15,
          startColorAlpha = 0.1,
          finishColorAlpha = 0.75,
          startColorGreen = 1,
          startColorRed = 1,
          blendFuncSource = 770,
          blendFuncDestination = 1,
          particleLifespan = 0.7237,
          maxParticles = 128,
          duration = 0.5,
          speedVariance = 260,
          angleVariance = -300,
	}
	explosion = display.newEmitter(params)
	explosion:stop()
end

function setupObject()
	for i = 1, maximumPipe do holePosition[i] = calcRandomHole() end

	--Pipes
	for i = 1, 2 do --i=1:pipeUp, i=2:pipeDown.
		for j = 1, maximumPipe do
			pipes[i][j] = display.newGroup()
			pipes[i][j].name = 'pipe'
			pipes[i][j].image = display.newImageRect(pipes[i][j], (i == 1 and "Assets/pipeUp.png" or 'Assets/pipeDown.png'), 52, 320)
			pipes[i][j].collision = {x = wPipeCollision, y = hPipeCollision}	
			resetPipePosition(i, j)		
			physics.addBody(pipes[i][j], "static", {box = {halfWidth = wPipeCollision / 2, halfHeight = hPipeCollision / 2}})
		end
	end	

	--Sensor
	for i = 1, maximumPipe do
		sensors[i] = display.newGroup()
		sensors[i].name = 'sensor'
		physics.addBody(sensors[i], "static", {box = {halfWidth = 0, halfHeight = hScreen / 2}})
	end

	--Bird
	local options = {
		width = 70,
		height = 50,
		numFrames = 4,
		sheetContentWidth = 280,
		sheetContentHeight = 50
	}
	local imageSheet = graphics.newImageSheet("Assets/bird.png", options)
	local sequenceData = {
		name = "walking",
		start = 1,
		count = 3,
		time = 300,
		loopCount = 2,
		loopDirection = "bounce"
	}

	bird = display.newGroup()
	bird.name = 'bird'
	bird.image = display.newSprite(bird, imageSheet, sequenceData)
	bird.x, bird.y = xBird, yBird
	physics.addBody(bird, {isSensor=true, density=3.0, friction=0.5, bounce=0.3, radius=rBirdCollision})

	landSensor = display.newLine(0,bottomLine, wScreen,bottomLine)
	landSensor.alpha = 0
	landSensor.name = 'land'
	physics.addBody(landSensor, "static")
end

function setupForntGround()
	--Land
	land = display.newImageRect("Assets/land.png", wScreen * 2, hLand)
	land.x, land.y = xScreen, bottomLine + (hLand / 2)
end

function setupUI()	
	--GetReady
	getReady = display.newImageRect("Assets/getready.png", 200, 60)

	gameOver = display.newImageRect("Assets/gameover.png", 200, 60)

	scoreBoard = display.newGroup()
	scoreBoard.image = display.newImageRect(scoreBoard, "Assets/board.png", 240, 140)
	scoreBoard.score = display.newText(scoreBoard, '0', 80, -18, "Assets/troika.otf", 21)
	scoreBoard.score:setFillColor(0.75, 0, 0)
	scoreBoard.best = display.newText(scoreBoard, '0', 80, 24, "Assets/troika.otf", 21)
	scoreBoard.best:setFillColor(0.75, 0, 0)

	models.sliver = display.newImageRect(scoreBoard, "Assets/silver.png", 44, 44)
	models.gold = display.newImageRect(scoreBoard, "Assets/gold.png", 44, 44)
	models.sliver.x, models.sliver.y = -64, 4
	models.gold.x, models.gold.y = -64, 4

	textScore = display.newText(score, xScreen, 60, "Assets/troika.otf", 35)
	textScore:setFillColor(1, 1, 1)
end

function setupDebug()
	for i = 1, 2 do
		for j = 1, maximumPipe do
			pipes[i][j].debugBox = display.newRect(pipes[i][j], 0, 0, pipes[i][j].collision.x, pipes[i][j].collision.y)
			pipes[i][j].debugBox:setFillColor(1, 0, 0, 0.5)
		end
	end
	bird.debugBox = display.newCircle(bird, 0, 0, rBirdCollision)
	bird.debugBox:setFillColor(0, 1, 0, 0.5)
	for i = 1, maximumPipe do
		sensors[i].debugBox = display.newLine(sensors[i], 0, 0, 0, hScreen)
		sensors[i].debugBox:setStrokeColor(0, 0, 1, 0.5)
	end
	landSensor.alpha = 1
	landSensor:setStrokeColor(1, 0, 0, 0.5)
end

function playParticle(x, y)	
	explosion.x, explosion.y = x, y
	explosion:start()
end

function moving()
	for i = 1, 2 do
		for j = 1, maximumPipe do
			pipes[i][j]:translate(-speed, 0)
			if pipes[1][j].x < leftEdge then
				holePosition[j] = calcRandomHole()
				for k=1, 2 do
					pipes[k][j].x = pipes[k][j].x + pipeDistance * 3
					pipes[k][j].y = holePosition[j] + ((pipes[k][j].image.height + pipeHoleY) / 2) * (k == 1 and -1 or 1)
				end		

			end
		end
	end
	for i = 1, maximumPipe do
		sensors[i].x = pipes[1][i].x + wPipeCollision / 2 - rBirdCollision * 2
	end
	land:translate(-speed, 0)
	if land.x < 0 then land.x = land.x + wScreen end
end

function handleBestScore(command)
	local path = system.pathForFile("bestscore.txt", system.DocumentsDirectory)
	local access = (command == "save" and "w") or (command == "load" and "r")
	local file, errorStr = io.open(path, access)
	if file then
		if command == "save" then file:write(bestScore)			
		elseif command == "load" then bestScore = tonumber(file:read("*a")) or 0
		else print("ERROR: A wrong command in handleBestScore function.") end
		io.close(file)
	else
		print("ERROR: " .. errorStr)
	end
	file = nil
end

function prompt()
end


function gameLoop()
end

function animation(name)
	if name == 'wing' then
		bird.image:setFrame(1) 
		bird.image:play()
		audio.play(wingSound)
	elseif name == 'getReady' then
		getReady.x, getReady.y = xScreen, yTitleRaw
		getReady.alpha = 1
		transition.to(getReady, {
			time = 600,
			y = yTitleNew, 
			transition = easing.outBounce, 
			onComplete = function() 
				animation('wing') 
			end
		})
		audio.play(swooshSound)
	elseif name == 'crash' then
		transition.to(bird, {
			time = 1000, 
			y = bottomLine - bird.image.height / 2 + 10, 
			transition = easing.inCubic,
			rotation = 90,
			onComplete = function()
				nextScene()
			end
		})
		audio.play(crashSound)
	elseif name == 'gameOver' then
		gameOver.x, gameOver.y = xScreen, yTitleRaw
		gameOver.alpha = 1
		transition.to(gameOver, {
			time = 600,
			y = yTitleNew,
			transition = easing.outBounce
		})
	elseif name == 'scoreBoard' then
		scoreBoard.x, scoreBoard.y = xScreen, 0
		scoreBoard.alpha = 1
		scoreBoard.score.text = score
		scoreBoard.best.text = bestScore
		audio.play(hitSound)
		transition.to(scoreBoard, {
			time = 600,
			y = yScoreBoard,
			transition = easing.outBounce
		})
	elseif name == 'resetBird' then
		transition.to(bird, {
			time = 300,
			y = yBird,
			rotation = 0
		})
	end
end

function collision(event)
	if scenes[scene] == "play" then
		if event.phase == "began" then
			if event.object1.name == 'pipe' and event.object2.name == 'bird' then
				playParticle(bird.x, bird.y)
				nextScene()
			elseif event.object1.name == 'land' and event.object2.name == 'bird' then
				playParticle(bird.x, bird.y)
				nextScene("gameover")
			end
		elseif event.phase == "ended" then
			if event.object1.name == 'sensor' and event.object2.name == 'bird' then
				score = score + 1
				textScore.text = score
			end
		end
	end
end

function start()
	if scenes[scene] == "title" then
		bird:setLinearVelocity(0, 0)
		animation('getReady')
		score = 0
		textScore.alpha = 0
		scoreBoard.alpha = 0
		gameOver.alpha = 0
		models.sliver.alpha = 0
		models.gold.alpha = 0
		triggerLog = {}
	elseif scenes[scene] == "play" then
		physics.start()
		getReady.alpha = 0
		textScore.alpha = 1
	elseif scenes[scene] == "die" then		
		animation("crash")
	elseif scenes[scene] == "gameover" then
		physics.pause()
		animation("gameOver")
		if score > bestScore then
			bestScore = score
			handleBestScore("save")
		end
		animation("scoreBoard")
	end
end

function update()
	if scenes[scene] == "title" then
	elseif scenes[scene] == "play" then
		moving()
		local vx, vy = bird:getLinearVelocity()
		bird.rotation = (vy/flyForce) * 30
		trigger("score5", score >= 5)
		trigger("score20", score >= 20)
	elseif scenes[scene] == "die" then
		
	elseif scenes[scene] == "gameover" then
	end
end

function onTouch(event)
	if event.phase ~= "ended" then return end
	if scenes[scene] == "title" then
		nextScene()
	elseif scenes[scene] == "play" then
		animation('wing')
		bird:setLinearVelocity( 0, -flyForce )
	elseif scenes[scene] == "die" then

	elseif scenes[scene] == "gameover" then
		score = 0
		textScore.text = score
		resetScene()
	end
end

function nextScene(special)
	if special then scene = table.indexOf(scenes, special) 
	else scene = scene + 1 end	
	start()
end

function resetScene()
	scene = 1
	animation("resetBird")
	for i = 1, 2 do
		for j = 1, maximumPipe do
			resetPipePosition(i, j)
		end
	end
	land.x = xScreen
	start()
end

function trigger(name, case)
	if triggerLog[name] then return end
	if case then
		if name == "score5" then
			audio.play(pointSound)
			models.sliver.alpha = 1
		elseif name == "score20" then			
			audio.play(pointSound)
			models.gold.alpha = 1
		end
		triggerLog[name] = true
	else
	end
end

function init()
	physics.start()
	physics.setGravity(0, gravity)
	setupSounds()
	setupBackground()
	setupParticle()
	setupObject()
	setupForntGround()
	setupUI()
	if DEBUG_MODE then setupDebug() end
	Runtime:addEventListener( "touch", onTouch )
	Runtime:addEventListener( "enterFrame", update )
	Runtime:addEventListener( "collision", collision )
	scene = 1
	physics.pause()
	handleBestScore("load")
	start()
end 

init()