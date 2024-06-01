-- Timers: "surviveTimer", "temporaryTimer"

local composer = require("composer")

local scene = composer.newScene()

local physics = require("physics")
physics.start()
physics.setGravity(0, 0);

local secondsLeft = 52
local died = false
local isWin = false

local backgroundGroup
local mainGroup
local uiGroup

local surviveText

local player
local playerSpeed = 5
local bounds
local boundsStrokeWidth = 5
local cautionText

local wPressed = false
local aPressed = false
local sPressed = false
local dPressed = false
local upPressed = false
local leftPressed = false
local downPressed = false
local rightPressed = false
local leftStick

local laserSound
local musicTrack
local skyLaserSound

audio.reserveChannels(1);
audio.setVolume( 0.5, { channel=1 } )



local function movePlayer(axis, value)
    if (axis == "X") then
        if (value ~= 0) then
            Runtime:dispatchEvent({name = "onMove", x = value * playerSpeed, phase = "began"})
        else
            Runtime:dispatchEvent({name = "onMove", x = value * playerSpeed, phase = "ended"})
        end
    elseif (axis == "Y") then
        if (value ~= 0) then
            Runtime:dispatchEvent({name = "onMove", y = value * playerSpeed, phase = "began"})
        else
            Runtime:dispatchEvent({name = "onMove", y = value * playerSpeed, phase = "ended"})
        end
    end
end

local function moveByAxis(event)
    if (event.axis.number == 10) then
        movePlayer("X", event.normalizedValue)
    elseif (event.axis.number == 11) then
        movePlayer("Y", event.normalizedValue)
    end
end

local function axis(event)
    moveByAxis(event)
end


local function onKeyEvent(event)
    local phase = event.phase
    local keyName = event.keyName

    if (phase == "down") then
        if keyName == "w" then
            wPressed = true
            movePlayer("Y", -1)
        end
        if keyName == "up" then
            upPressed = true
            movePlayer("Y", -1)
        end
        if keyName == "a" then
            aPressed = true
            movePlayer("X", -1)
        end
        if keyName == "left" then
            leftPressed = true
            movePlayer("X", -1)
        end
        if keyName == "s" then
            sPressed = true
            movePlayer("Y", 1)
        end
        if keyName == "down" then
            downPressed = true
            movePlayer("Y", 1)
        end
        if keyName == "d" then
            dPressed = true
            movePlayer("X", 1)
        end
        if keyName == "right" then
            rightPressed = true
            movePlayer("X", 1)
        end
    elseif (phase == "up") then
        if keyName == "w" then
            wPressed = false
            if upPressed == false and sPressed == false and downPressed == false then
                movePlayer("Y", 0)
            end
        end
        if keyName == "up" then
            upPressed = false
            if wPressed == false and sPressed == false and downPressed == false then
                movePlayer("Y", 0)
            end
        end
        if keyName == "a" then
            aPressed = false
            if leftPressed == false and dPressed == false and rightPressed == false then
                movePlayer("X", 0)
            end
        end
        if keyName == "left" then
            leftPressed = false
            if aPressed == false and dPressed == false and rightPressed == false then
                movePlayer("X", 0)
            end
        end
        if keyName == "s" then
            sPressed = false
            if downPressed == false and wPressed == false and upPressed == false then
                movePlayer("Y", 0)
            end
        end
        if keyName == "down" then
            downPressed = false
            if sPressed == false and wPressed == false and upPressed == false then
                movePlayer("Y", 0)
            end
        end
        if keyName == "d" then
            dPressed = false
            if rightPressed == false and aPressed == false and leftPressed == false then
                movePlayer("X", 0)
            end
        end
        if keyName == "right" then
            rightPressed = false
            if dPressed == false and aPressed == false and leftPressed == false then
                movePlayer("X", 0)
            end
        end
    end
end

local function gotoLevels()
    composer.gotoScene("levels", {time = 800, effect="crossFade"});
end

local function gotoNextLevel()
    composer.gotoScene("second-level", {time = 800, effect="crossFade"})
end

local function stopGame(win)
    if(isWin)then
        return
    end

    isWin = win
    timer.cancel("surviveTimer")
    timer.cancel("temporaryTimer")

    Runtime:removeEventListener("onMove", player)
    Runtime:removeEventListener("enterFrame", player)
    Runtime:removeEventListener("key", onKeyEvent)
    Runtime:removeEventListener("collision", onCollision)

    physics.pause()

    display.remove(player)

    if win then
        local winText = display.newText(uiGroup, "Уровень пройден!", display.contentCenterX, display.contentCenterY, native.systemFont, 44)
        winText:setFillColor(1, 1, 0)
        timer.performWithDelay(2000, gotoNextLevel, "temporaryTimer")
    else
        local failreText = display.newText(uiGroup, "Ты умер..", display.contentCenterX, display.contentCenterY, native.systemFont, 72)
        failreText:setFillColor(1, 0, 0)
        timer.performWithDelay(2000, gotoLevels, "temporaryTimer");
    end
end

local function onCollision(event)
    local obj1 = event.object1
    local obj2 = event.object2
    
    if  obj1.name == "enemy" and obj2.name == "player" or
        obj1.name == "player" and obj2.name == "enemy" then
        stopGame(false)
    end
end

local function updateTime(event)
    if (secondsLeft == 0) then
        stopGame(true)
    else
        secondsLeft = secondsLeft - 1
 
        local minutes = math.floor( secondsLeft / 60 )
        local seconds = secondsLeft % 60
    
        local timeDisplay = string.format("Выживи на протяжении: %02d:%02d", minutes, seconds )
        
        surviveText.text = timeDisplay
    end
end

local function hideCautionText()
    cautionText.text = ""
end

local function flick(object, neededFlicks)
    if (object.flicks % 2 == 0) then
        object.alpha = 0.3
    else 
        object.alpha = 0.1
    end

    if (object.flicks == neededFlicks - 1) then
        object.alpha = 1
    end

    object.flicks = object.flicks + 1
end

local function glow(object, xGlow, yGlow, iterations)
    transition.to(object, {time = 100, xScale = xGlow, yScale = yGlow, iterations = iterations, transition = easing.outElastic})
end

local function spawnHorizontalLasers()
    for i = 1, 4 do
        local laserY = math.random(bounds.y - bounds.height / 2, bounds.y + bounds.height / 2)
        local laser = display.newRect(mainGroup, display.contentCenterX, laserY, display.contentWidth, 100)
        laser:setFillColor(1, 1, 1)
        laser.alpha = 0.1
        laser.flicks = 0
        laser.name = "enemy"

        local flicker = function() return flick(laser, 5) end
        timer.performWithDelay(2000 / 5, flicker, 5, "temporaryTimer")

        local function activateLaser() 
            physics.addBody(laser, "dynamic")
            laser.isSensor = true
            audio.play(laserSound)
        end
        timer.performWithDelay(2000, activateLaser, "temporaryTimer")

        local glower = function() return glow(laser, 1, 1.15, 20) end
        timer.performWithDelay(2000, glower, "temporaryTimer")

        local function removeLaser()
            laser:removeSelf()
        end
        timer.performWithDelay(4000, removeLaser, "temporaryTimer")
    end
end

local function spawnVerticalLasers()
    for i = 1, 8 do
        local laserX = math.random(bounds.x - bounds.width / 2, bounds.x + bounds.width / 2)
        local laser = display.newRect(mainGroup, laserX, display.contentCenterY, 100, display.contentHeight)
        laser:setFillColor(1, 1, 1)
        laser.alpha = 0.1
        laser.flicks = 0
        laser.name = "enemy"

        local flicker = function() return flick(laser, 5) end
        timer.performWithDelay(2000 / 5, flicker, 5, "temporaryTimer")

        local function activateLaser() 
            physics.addBody(laser, "dynamic")
            laser.isSensor = true
            audio.play(laserSound)
        end
        timer.performWithDelay(2000, activateLaser, "temporaryTimer")

        local glower = function() return glow(laser, 1.15, 1, 20) end
        timer.performWithDelay(2000, glower, "temporaryTimer")

        local function removeLaser()
            laser:removeSelf()
        end
        timer.performWithDelay(4000, removeLaser, "temporaryTimer")
    end
end

local function spawnSkyRays()
    for i = 1, 15 do
        local rayX = math.random(bounds.x - bounds.width / 2, bounds.x + bounds.width / 2)
        local rayY = math.random(bounds.y - bounds.height / 2, bounds.y + bounds.height / 2)
        local ray = display.newCircle(mainGroup, rayX, rayY, 100)
        ray:setFillColor(1, 1, 1)
        ray.alpha = 0.1
        ray.flicks = 0
        ray.name = "enemy"

        local flicker = function() return flick(ray, 5) end
        timer.performWithDelay(1500 / 5, flicker, 5, "temporaryTimer")

        local function activateRay() 
            physics.addBody(ray, "dynamic")
            ray.isSensor = true
            audio.play(skyLaserSound)
        end
        timer.performWithDelay(1500, activateRay, "temporaryTimer")

        local glower = function() return glow(ray, 1.15, 1.15, 20) end
        timer.performWithDelay(1500, glower, "temporaryTimer")

        local function removeRay()
            ray:removeSelf()
        end
        timer.performWithDelay(3500, removeRay, "temporaryTimer")
    end
end

local function spawnMovingBarriers()
    local barriersSpeed = 0.15
    local barriersCount = 20

    for i = 0, barriersCount do
        local barrierX = display.contentWidth + 120 * i
        local barrierY = bounds.y - bounds.height / 4
        local barrier = display.newRect(mainGroup, barrierX, barrierY, 10, bounds.height / 2);
        barrier:setFillColor(1, 1, 1)
        barrier.name = "enemy"
        
        physics.addBody(barrier, "dynamic");
        barrier.isSensor = true
        barrier:applyLinearImpulse(-barriersSpeed, 0, barrier.x, barrier.y)
    
        local function removeBarrier()
            barrier:removeSelf()
        end
        timer.performWithDelay(12000 + 1000 * i, removeBarrier, "temporaryTimer")
    end

    for i = 0, barriersCount do
        local barrierX = 60 - 120 * i
        local barrierY = bounds.y + bounds.height / 4
        local barrier = display.newRect(mainGroup, barrierX, barrierY, 10, bounds.height / 2);
        barrier:setFillColor(1, 1, 1)
        barrier.name = "enemy"
        
        physics.addBody(barrier, "dynamic");
        barrier.isSensor = true
        barrier:applyLinearImpulse(barriersSpeed, 0, barrier.x, barrier.y)
        
        local function removeBarrier()
            barrier:removeSelf()
        end
        timer.performWithDelay(12000 + 1000 * i, removeBarrier, "temporaryTimer")
    end
end

local function firstPhase() -- 15 seconds
    cautionText.text = "Берегись лазеров!"
    timer.performWithDelay(3000, hideCautionText, "temporaryTimer")

    -- Horizontal lasers after 1 second | 4 seconds
    timer.performWithDelay(1000, spawnHorizontalLasers, "temporaryTimer")

    -- Vertical lasers after 6 seconds (1 wait + 4 horizontals + 1 wait) | 4 seconds
    timer.performWithDelay(6000, spawnVerticalLasers, "temporaryTimer")

    -- Horizontal lasers after 11 seconds (1 wait + 4 horizontals + 1 wait + 4 verticals + 1 wait) | 4 seconds
    timer.performWithDelay(11000, spawnHorizontalLasers, "temporaryTimer")
end

local function secondPhase() -- 10.5 seconds
    cautionText.text = "Что за лучи в небе?"
    timer.performWithDelay(3000, hideCautionText, "temporaryTimer")

    local function timedRaysSpawner()
        spawnSkyRays()
        timer.performWithDelay(4000, spawnSkyRays, 2, "temporaryTimer")
    end

    -- Sky rays 3 times | 1 sec first wait and 0.5 others + 3.5 sec per ray
    timer.performWithDelay(1000, timedRaysSpawner, "temporaryTimer")
end

local function thirdPhase()
    cautionText.text = "Что-то надвигается с краю.."
    timer.performWithDelay(3000, hideCautionText, "temporaryTimer")

    timer.performWithDelay(1000, spawnMovingBarriers, "temporaryTimer")
end

local function gameLoop()
    timer.performWithDelay(1000, updateTime, -1, "surviveTimer");

    firstPhase() -- 15 seconds
    timer.performWithDelay(16000, secondPhase, "temporaryTimer") -- 1 second wait + 11.5 seconds
    timer.performWithDelay(29500, thirdPhase, "temporaryTimer") -- 1 second wait + 21 seconds+-
end


function scene:create(event)

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    physics.pause()

    backgroundGroup = display.newGroup()
    sceneGroup:insert(backgroundGroup)

    local background = display.newImageRect(backgroundGroup, "images/background.jpg", display.actualContentWidth, display.actualContentHeight)
	background.x = display.contentCenterX
	background.y = display.contentCenterY

    mainGroup = display.newGroup()
    sceneGroup:insert(mainGroup)

    uiGroup = display.newGroup()
    sceneGroup:insert(uiGroup)

    local vjoy = require "vjoy"
    leftStick = vjoy.newStick(10)
    leftStick.x, leftStick.y = 196, display.contentHeight - 120
    uiGroup:insert(leftStick)

    bounds = display.newRect(mainGroup, display.contentCenterX, display.contentCenterY + 100, 1100, 450);
    bounds:setFillColor(0, 0, 0, 0)
    bounds.strokeWidth = boundsStrokeWidth

    player = display.newCircle(mainGroup, bounds.x, bounds.y, 15)
    player:setFillColor(1, 0, 0)
    player.moveX = 0
    player.moveY = 0
    player.name = "player"
    physics.addBody(player, "dynamic")
    player.isSensor = true

    local minutes = math.floor( secondsLeft / 60 )
    local seconds = secondsLeft % 60
    local timeDisplay = string.format("Выживи на протяжении: %02d:%02d", minutes, seconds )
    surviveText = display.newText(uiGroup, timeDisplay, display.contentCenterX, 50, native.systemFont, 44)
    surviveText:setFillColor(1, 1, 0)

    cautionText = display.newText(uiGroup, "", display.contentCenterX, 150, native.systemFont, 44)
    cautionText:setFillColor(1, 0, 0)

    laserSound = audio.loadSound("audio/laser.mp3")
    skyLaserSound = audio.loadSound("audio/sky-laser.mp3")
    musicTrack = audio.loadStream("audio/tutorials.mp3")
end



function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

    function player.onMove(self, event)
        self.moveX = event.x or self.moveX
        self.moveY = event.y or self.moveY
    end

    function player.enterFrame(self)
        if (
            (self.x + self.path.radius <= bounds.x + bounds.width / 2 - boundsStrokeWidth or self.moveX < 0) and 
            (self.x - self.path.radius >= bounds.x - bounds.width / 2 + boundsStrokeWidth or self.moveX > 0) 
        ) then
            self.x = self.x + self.moveX
        end

        if (
            (self.y + self.path.radius <= bounds.y + bounds.height / 2 - boundsStrokeWidth or self.moveY < 0) and
            (self.y - self.path.radius >= bounds.y - bounds.height / 2 + boundsStrokeWidth or self.moveY > 0)
        ) then
            self.y = self.y + self.moveY
        end

    end

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
        Runtime:addEventListener("axis", axis)
	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
        Runtime:addEventListener("onMove", player)
        Runtime:addEventListener("enterFrame", player)
        Runtime:addEventListener("key", onKeyEvent)
        Runtime:addEventListener("collision", onCollision)

        physics.start()
        
        audio.play( musicTrack, { channel=1, loops=-1 } )
        gameLoop()
    end
end



function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
        timer.cancel("surviveTimer")
        timer.cancel("temporaryTimer")
	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener("axis", axis)
        Runtime:removeEventListener("onMove", player)
        Runtime:removeEventListener("enterFrame", player)
        Runtime:removeEventListener("key", onKeyEvent)
        Runtime:removeEventListener("collision", onCollision)

        physics.pause()

        audio.stop(1)
        composer.removeScene("first-level");
	end
end



function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
	
    audio.dispose( laserSound )
    audio.dispose( musicTrack )
    audio.dispose( skyLaserSound )
end



scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene