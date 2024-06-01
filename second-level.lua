-- Timers: "bonusSpawnerTimer", "temporaryTimer", "surviveTimer"

local composer = require("composer")

local scene = composer.newScene()

local physics = require("physics")
physics.start()
physics.setGravity(0, 0);

local secondsLeft = 60

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

local speedUpBonusIcon
local speedUpBonusIsActive = false
local speedUpBonusSpawned = false
local shieldBonusIcon
local shieldBonusIsActive = false
local shieldBonusSpawned = false
local explosionBonusIcon
local explosionBonusIsActive = false
local explosionBonusSpawned = false

local bonusSpawnChance = 1
local bonusSpawnTime = 1000 -- In ms
local tutorialBonusActive = false
local tutorialSpeedUpPicked = false
local tutorialShieldPicked = false
local tutorialExplosionPicked = false

local tutorialActive = false



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
    -- composer.gotoScene()
end

local function stopGame(win)
    timer.cancel("bonusSpawnerTimer")
    timer.cancel("temporaryTimer")
    timer.cancel("surviveTimer")

    Runtime:removeEventListener("onMove", player)
    Runtime:removeEventListener("enterFrame", player)
    Runtime:removeEventListener("key", onKeyEvent)
    Runtime:removeEventListener("collision", onCollision)

    physics.pause()

    display.remove(player)

    if win then
        local winText = display.newText(uiGroup, "Congratulations!", display.contentCenterX, display.contentCenterY, native.systemFont, 44)
        winText:setFillColor(1, 1, 0)
        timer.performWithDelay(2000, gotoNextLevel, "temporaryTimer")
    else
        local failreText = display.newText(uiGroup, "You are dead", display.contentCenterX, display.contentCenterY, native.systemFont, 72)
        failreText:setFillColor(1, 0, 0)
        timer.performWithDelay(2000, gotoLevels, "temporaryTimer");
    end
end

local function updateTime(event)
    if (secondsLeft == 0) then
        stopGame(true)
        return
    end

    secondsLeft = secondsLeft - 1
 
    local minutes = math.floor( secondsLeft / 60 )
    local seconds = secondsLeft % 60
 
    local timeDisplay = string.format("Выживи на протяжении: %02d:%02d", minutes, seconds )
     
    surviveText.text = timeDisplay
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
        end
        timer.performWithDelay(2000, activateLaser, "temporaryTimer")

        local glower = function() return glow(laser, 1, 1.15, 20) end
        timer.performWithDelay(2000, glower, "temporaryTimer")

        local function removeLaser()
            if (laser ~= nil) then
                display.remove(laser)
            end
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
        end
        timer.performWithDelay(2000, activateLaser, "temporaryTimer")

        local glower = function() return glow(laser, 1.15, 1, 20) end
        timer.performWithDelay(2000, glower, "temporaryTimer")

        local function removeLaser()
            if (laser ~= nil) then
                display.remove(laser)
            end
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
        end
        timer.performWithDelay(1500, activateRay, "temporaryTimer")

        local glower = function() return glow(ray, 1.15, 1.15, 20) end
        timer.performWithDelay(1500, glower, "temporaryTimer")

        local function removeRay()
            if (ray ~= nil) then
               display.remove(ray) 
            end
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
            if (barrier ~= nil) then
                display.remove(barrier)
            end
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
            if (barrier ~= nil) then
                display.remove(barrier)
            end
        end
        timer.performWithDelay(12000 + 1000 * i, removeBarrier, "temporaryTimer")
    end
end

local function startRandomEnemiesSpawn()
    local randomSpawnType = math.random(1, 4);
    local enemyExecutionTime = 0

    if randomSpawnType == 1 then
        spawnHorizontalLasers()
        enemyExecutionTime = 4000
    elseif randomSpawnType == 2 then
        spawnVerticalLasers()
        enemyExecutionTime = 4000
    elseif randomSpawnType == 3 then
        spawnSkyRays()
        enemyExecutionTime = 4000
    elseif randomSpawnType == 4 then
        spawnMovingBarriers()
        enemyExecutionTime = 21000
    end

    timer.performWithDelay(enemyExecutionTime + 1500, startRandomEnemiesSpawn, "temporaryTimer")
end



local function activateBonus(bonus)
    if (bonus == "speedUp") then
        speedUpBonusIsActive = true
        speedUpBonusIcon.alpha = 1
        speedUpBonusSpawned = false
        playerSpeed = 7.5
        local function deactivateSpeedUp()
            speedUpBonusIsActive = false
            speedUpBonusIcon.alpha = 0.3
            speedUpBonusSpawned = false
            playerSpeed = 5
        end
        timer.performWithDelay(5000, deactivateSpeedUp, "temporaryTimer")
    elseif (bonus == "shield") then
        shieldBonusIsActive = true
        shieldBonusIcon.alpha = 1
        player:setStrokeColor(0, 0, 1)
        player.strokeWidth = 3
    elseif (bonus == "explosion") then
        explosionBonusIsActive = true
        explosionBonusIcon.alpha = 1
    end
end

local function deactivateBonus(bonus)
    if (bonus == "speedUp") then
        speedUpBonusIsActive = false
        speedUpBonusIcon.alpha = 0.3
    elseif (bonus == "shield") then
    elseif (bonus == "explosion") then
    end
end


local function spawnBonusWithChance()
    if (math.random() > bonusSpawnChance) then
        return
    end

    local bonusType
    local bonusColor
    local randomBonusType = math.random(1, 3)

    if (randomBonusType == 1) then
        if (speedUpBonusIsActive or speedUpBonusSpawned) then
            return
        end
        bonusType = "speedUp"
        bonusColor = { r=0, g=1, b=0 }
        speedUpBonusSpawned = true
    elseif (randomBonusType == 2) then
        if (shieldBonusIsActive or shieldBonusSpawned) then
            return
        end
        bonusType = "shield"
        bonusColor = { r=0, g=0, b=1 }
        shieldBonusSpawned = true
    elseif (randomBonusType == 3) then
        if (explosionBonusIsActive or explosionBonusSpawned) then
            return
        end
        bonusType = "explosion"
        bonusColor = { r=1, g=0, b=0 }
        explosionBonusSpawned = true
    end

    local bonusX = math.random(bounds.x - bounds.width / 2 + boundsStrokeWidth, bounds.x + bounds.width / 2 - boundsStrokeWidth)
    local bonuxY = math.random(bounds.y - bounds.height / 2 + boundsStrokeWidth, bounds.y + bounds.height / 2 - boundsStrokeWidth)

    local bonus = display.newCircle(mainGroup, bonusX, bonuxY, 20);
    bonus:setFillColor(bonusColor.r, bonusColor.g, bonusColor.b)
    bonus.name = "bonus"
    bonus.bonusType = bonusType
    physics.addBody(bonus, "static")
    bonus.isSensor = true
end

local function startBonusSpawn()
    timer.performWithDelay(bonusSpawnTime, spawnBonusWithChance, -1, "bonusSpawnerTimer")
end

local function disableAllBonuses()
    speedUpBonusIcon.alpha = 0.3
    speedUpBonusIsActive = false
    speedUpBonusSpawned = false
    playerSpeed = 5

    shieldBonusIcon.alpha = 0.3
    shieldBonusIsActive = false
    shieldBonusSpawned = false
    player.strokeWidth = 0

    explosionBonusIcon.alpha = 0.3
    explosionBonusIsActive = false
    explosionBonusSpawned = false
end

local function gameLoop()
    hideCautionText()
    disableAllBonuses()

    surviveText.alpha = 1
    timer.performWithDelay(1000, updateTime, -1, "surviveTimer")

    startRandomEnemiesSpawn()
    startBonusSpawn()
end

local function performShield()
    local function deactivate()
        shieldBonusIcon.alpha = 0.3
        shieldBonusIsActive = false
        shieldBonusSpawned = false
        player.strokeWidth = 0
    end

    timer.performWithDelay(3000, deactivate, "temporaryTimer")
end

local function performExplosion()
    if (explosionBonusIsActive == false) then
        return
    end

    local area = display.newCircle(mainGroup, player.x, player.y, 150)
    area:setFillColor(0, 1, 0, 0.3)

    explosionBonusIcon.alpha = 0.3
    explosionBonusIsActive = false
    explosionBonusSpawned = false

    for i = mainGroup.numChildren, 1, -1 do
        local child = mainGroup[i]
        local childBounds = child.contentBounds

        if (child.name == "enemy") then
            if (childBounds.xMin < area.x + 150 and childBounds.xMax > area.x - 150 and childBounds.yMin < area.y + 150 and childBounds.yMax > area.y - 150) then
                display.remove(child)
                child = nil
            end
        end
    end

    local function removeArea()
        if (area ~= nil) then
            display.remove(area)
        end
    end

    transition.to(area, {time = 1000, xScale = 0.01, yScale = 0.01, iterations = 1, transition = easing.outElastic})
    timer.performWithDelay(1000, removeArea, "temporaryTimer")
end

local function onCollision(event)
    local obj1 = event.object1
    local obj2 = event.object2
    
    if  obj1.name == "enemy" and obj2.name == "player" or
        obj1.name == "player" and obj2.name == "enemy" then
        if (shieldBonusIsActive) then
            performShield()
            return
        elseif (explosionBonusIsActive) then
            performExplosion()
            return
        else
            stopGame(false)
        end
    end

    if  obj1.name == "player" and obj2.name == "bonus" or
        obj1.name == "bonus" and obj2.name == "player" then
        local bonusType
        if (obj1.name == "bonus") then
            bonusType = obj1.bonusType
            display.remove(obj1)
        else
            bonusType = obj2.bonusType
            display.remove(obj2)
        end

        activateBonus(bonusType)
    end

    if  obj1.name == "player" and obj2.name == "tutorialBonus" or
        obj1.name == "tutorialBonus" and obj2.name == "player" then
        
        if (tutorialBonusActive) then
            return
        end

        local bonusType
        if (obj1.name == "tutorialBonus") then
            bonusType = obj1.bonusType
            display.remove(obj1)
        else
            bonusType = obj2.bonusType
            display.remove(obj2)
        end

        tutorialBonusActive = true
        activateBonus(bonusType)

        local function deactivateTutorialBonus() 
            tutorialBonusActive = false
            hideCautionText()
            deactivateBonus(bonusType)
        end

        if (bonusType == "speedUp") then
            cautionText.text = "Ускоритель. Длится 5 секунд"
            tutorialSpeedUpPicked = true
        elseif (bonusType == "shield") then
            cautionText.text = "Щит. Неуязвимость на 2 секунды после столкновения"
            tutorialShieldPicked = true
        elseif (bonusType == "explosion") then
            cautionText.text = "Взрыв! Срабатывает при столкновении"
            tutorialExplosionPicked = true
        end

        timer.performWithDelay(2500, deactivateTutorialBonus, "temporaryTimer")
        
        if (tutorialSpeedUpPicked and tutorialShieldPicked and tutorialExplosionPicked) then
            timer.performWithDelay(2500, gameLoop, "temporaryTimer")
        end
    end
end

local function tutorial()
    local speedUpBonus = display.newCircle(mainGroup, bounds.x - 200, bounds.y + 60, 20)
    speedUpBonus:setFillColor(0, 1, 0)
    speedUpBonus.name = "tutorialBonus"
    speedUpBonus.bonusType = "speedUp"
    physics.addBody(speedUpBonus, "static")
    speedUpBonus.isSensor = true
    local shieldBonus = display.newCircle(mainGroup, bounds.x, bounds.y + 60, 20)
    shieldBonus:setFillColor(0, 0, 1)
    shieldBonus.name = "tutorialBonus"
    shieldBonus.bonusType = "shield"
    physics.addBody(shieldBonus, "static")
    shieldBonus.isSensor = true
    local explosionBonus = display.newCircle(mainGroup, bounds.x + 200, bounds.y + 60, 20)
    explosionBonus:setFillColor(1, 0, 0)
    explosionBonus.name = "tutorialBonus"
    explosionBonus.bonusType = "explosion"
    physics.addBody(explosionBonus, "static")
    explosionBonus.isSensor = true
end



function scene:create(event)

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    physics.pause()

    backgroundGroup = display.newGroup()
    sceneGroup:insert(backgroundGroup)

    mainGroup = display.newGroup()
    sceneGroup:insert(mainGroup)

    uiGroup = display.newGroup()
    sceneGroup:insert(uiGroup)

    bounds = display.newRect(mainGroup, display.contentCenterX, display.contentCenterY + 100, 1100, 450);
    bounds:setFillColor(0, 0, 0, 0)
    bounds.strokeWidth = boundsStrokeWidth

    player = display.newCircle(mainGroup, bounds.x, bounds.y - 50, 15)
    player:setFillColor(1, 0, 0)
    player.moveX = 0
    player.moveY = 0
    player.name = "player"
    physics.addBody(player, "dynamic")
    player.isSensor = true

    speedUpBonusIcon = display.newRect(uiGroup, bounds.x - bounds.width / 2 + 30, bounds.y - bounds.height / 2 - 50, 60, 60)
    speedUpBonusIcon.alpha = 0.3
    speedUpBonusIcon:setFillColor(0, 1, 0)

    shieldBonusIcon = display.newRect(uiGroup, speedUpBonusIcon.x + 80, speedUpBonusIcon.y, 60, 60);
    shieldBonusIcon.alpha = 0.3
    shieldBonusIcon:setFillColor(0, 0, 1)
    
    explosionBonusIcon = display.newRect(uiGroup, shieldBonusIcon.x + 80, shieldBonusIcon.y, 60, 60);
    explosionBonusIcon.alpha = 0.3
    explosionBonusIcon:setFillColor(1, 0, 0)

    local minutes = math.floor( secondsLeft / 60 )
    local seconds = secondsLeft % 60
    local timeDisplay = string.format("Выживи на протяжении: %02d:%02d", minutes, seconds )
    surviveText = display.newText(uiGroup, timeDisplay, display.contentCenterX, 50, native.systemFont, 44)
    surviveText:setFillColor(1, 1, 0)
    surviveText.alpha = 0

    cautionText = display.newText(uiGroup, "", display.contentCenterX, 110, native.systemFont, 44)
    cautionText:setFillColor(1, 0, 0)
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

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
        Runtime:addEventListener("onMove", player)
        Runtime:addEventListener("enterFrame", player)
        Runtime:addEventListener("key", onKeyEvent)
        Runtime:addEventListener("collision", onCollision)

        physics.start();

        tutorial()
    end
end



function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
        timer.cancel("surviveTimer")
        timer.cancel("temporaryTimer")
        timer.cancel("bonusSpawnerTimer")
    elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		Runtime:removeEventListener("onMove", player)
        Runtime:removeEventListener("enterFrame", player)
        Runtime:removeEventListener("key", onKeyEvent)
        Runtime:removeEventListener("collision", onCollision)

        physics.pause()

        composer.removeScene("second-level");
	end
end



function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
	
end



scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene