-- Timers: "bonusSpawnerTimer", "temporaryTimer", "surviveTimer", "gunSpawnerTimer"

local composer = require("composer")

local scene = composer.newScene()

local physics = require("physics")
physics.start()
physics.setGravity(0, 0);

local backgroundGroup
local mainGroup
local uiGroup

local player
local playerSpeed = 5
local playerLives = 3
local playerLivesUI
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

local speedUpBonusIcon
local speedUpBonusIsActive = false
local speedUpBonusSpawned = false
local shieldBonusIcon
local shieldBonusIsActive = false
local shieldBonusSpawned = false
local explosionBonusIcon
local explosionBonusIsActive = false
local explosionBonusSpawned = false
local explosionSprite

local bonusSpawnChance = 0.15
local bonusSpawnTime = 1000 -- In ms

local dummy
local dummyHp = 9
local dummyHpUI

local gunSpawnChance = 0.2
local gunSpawnTime = 1500
local gunSpawned = false
local bulletDamage = 1

local laserSound
local musicTrack
local skyLaserSound



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
    -- composer.gotoScene()
end

local function hideCautionText()
    cautionText.text = ""
end

local function theEnd()
    local function first()
        cautionText.text = "Тебе никогда не победить меня"
    end
    local function second()
        cautionText.text = "Ты слишком слаб"
    end
    local function third()
        cautionText.text = "Было забавно с тобой поиграться"
    end
    local function fourth()
        cautionText.text = "А теперь.."
    end
    local function fifth()
        hideCautionText()
        local endText = display.newText(uiGroup, "УМРИ", display.contentCenterX, display.contentCenterY, native.systemFont, 200)
        endText:setFillColor(1, 0, 0)

        local function performEnd()
            local endRectangle = display.newRect(uiGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight);
        end

        local function closeGame()
            os.exit(1)
        end
        timer.performWithDelay(800, performEnd, "temporaryTimer")
        timer.performWithDelay(900, closeGame, "temporaryTimer")
    end
    first()
    timer.performWithDelay(2500, second, "temporaryTimer")
    timer.performWithDelay(5000, third, "temporaryTimer");
    timer.performWithDelay(7500, fourth, "temporaryTimer");
    timer.performWithDelay(10000, fifth, "temporaryTimer");
end

local function stopGame(win)
    timer.cancel("bonusSpawnerTimer")
    timer.cancel("temporaryTimer")
    timer.cancel("surviveTimer")
    timer.cancel("gunSpawnerTimer")

    Runtime:removeEventListener("onMove", player)
    Runtime:removeEventListener("enterFrame", player)
    Runtime:removeEventListener("key", onKeyEvent)
    Runtime:removeEventListener("collision", onCollision)

    physics.pause()

    display.remove(player)

    if win then
        theEnd()
    else
        local failreText = display.newText(uiGroup, "Ты никогда меня не победишь..", display.contentCenterX, display.contentCenterY, native.systemFont, 72)
        failreText:setFillColor(1, 0, 0)
        timer.performWithDelay(2000, gotoLevels, "temporaryTimer");
    end
end

local function updateDummyHp()
    dummyHpUI.height = dummyHp
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
        timer.performWithDelay(1200 / 5, flicker, 5, "temporaryTimer")

        local function activateLaser() 
            physics.addBody(laser, "dynamic")
            laser.isSensor = true
            audio.play(laserSound)
        end
        timer.performWithDelay(1200, activateLaser, "temporaryTimer")

        local glower = function() return glow(laser, 1, 1.15, 15) end
        timer.performWithDelay(1200, glower, "temporaryTimer")

        local function removeLaser()
            if (laser ~= nil) then
                display.remove(laser)
            end
        end
        timer.performWithDelay(2700, removeLaser, "temporaryTimer")
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
        timer.performWithDelay(1200 / 5, flicker, 5, "temporaryTimer")

        local function activateLaser() 
            physics.addBody(laser, "dynamic")
            laser.isSensor = true
            audio.play(laserSound)
        end
        timer.performWithDelay(1200, activateLaser, "temporaryTimer")

        local glower = function() return glow(laser, 1.15, 1, 15) end
        timer.performWithDelay(1200, glower, "temporaryTimer")

        local function removeLaser()
            if (laser ~= nil) then
                display.remove(laser)
            end
        end
        timer.performWithDelay(2700, removeLaser, "temporaryTimer")
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
        timer.performWithDelay(1000 / 5, flicker, 5, "temporaryTimer")

        local function activateRay() 
            physics.addBody(ray, "dynamic")
            ray.isSensor = true
            audio.play(skyLaserSound)
        end
        timer.performWithDelay(1000, activateRay, "temporaryTimer")

        local glower = function() return glow(ray, 1.15, 1.15, 15) end
        timer.performWithDelay(1000, glower, "temporaryTimer")

        local function removeRay()
            if (ray ~= nil) then
               display.remove(ray) 
            end
        end
        timer.performWithDelay(2500, removeRay, "temporaryTimer")
    end
end

local function spawnMovingBarriers()
    local barriersSpeed = 0.25
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
        timer.performWithDelay(6000 + 500 * i, removeBarrier, "temporaryTimer")
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
        timer.performWithDelay(6000 + 500 * i, removeBarrier, "temporaryTimer")
    end
end

local function spawnBossDiagonalLasers(side)
    local laserX
    local laserY = bounds.y - bounds.height / 2 - 50
    local laserRotation
    if (side == "left") then
        laserX = bounds.x - bounds.width / 2 + 50
        laserRotation = -70
    else
        laserX = bounds.x + bounds.width / 2 - 50
        laserRotation = 70
    end

    local laser = display.newRect(mainGroup, laserX, laserY, 100, 3000)
    laser.name = "enemy"
    physics.addBody(laser, "dynamic");
    laser.isSensor = true

    transition.to(laser, {time = 1200, rotation = laserRotation, iterations = 1})
    local function removeLaser()
        if (laser ~= nil) then
            display.remove(laser)
        end
    end
    timer.performWithDelay(1200, removeLaser, "temporaryTimer")

    if(side == "right")then
        local function leftLaser()
            spawnBossDiagonalLasers("left")
        end
        timer.performWithDelay(1200, leftLaser, "temporaryTimer")
    end
end

local function spawnShrinkingWalls()
    local centerX = display.contentCenterX
    local centerY = display.contentCenterY
    local screenWidth = display.actualContentWidth
    local screenHeight = display.actualContentHeight

    local wall1 = display.newRect(mainGroup, centerX, centerY - screenHeight/2, screenWidth, 10) -- Up
    local wall2 = display.newRect(mainGroup, centerX, centerY + screenHeight/2, screenWidth, 10) -- Down
    local wall3 = display.newRect(mainGroup, centerX - screenWidth/2, centerY, 10, screenHeight) -- Left
    local wall4 = display.newRect(mainGroup, centerX + screenWidth/2, centerY, 10, screenHeight) -- Right

    wall1.name = "enemy"
    wall2.name = "enemy"
    wall3.name = "enemy"
    wall4.name = "enemy"

    physics.addBody(wall1, "dynamic")
    physics.addBody(wall2, "dynamic")
    physics.addBody(wall3, "dynamic")
    physics.addBody(wall4, "dynamic")

    wall1.isSensor = true
    wall2.isSensor = true
    wall3.isSensor = true
    wall4.isSensor = true

    local squareX = math.random(bounds.x - bounds.width / 2 + boundsStrokeWidth + 200, bounds.x + bounds.width / 2 - boundsStrokeWidth - 200)
    local squareY = math.random(bounds.y - bounds.height / 2 + boundsStrokeWidth + 200, bounds.y + bounds.height / 2 - boundsStrokeWidth - 200)

    local function moveWalls()
        transition.to( wall1, { x = squareX, y = squareY - 50, width = 90, time = 1700 } )
        transition.to( wall2, { x = squareX, y = squareY + 50, width = 90, time = 1700 } )
        transition.to( wall3, { x = squareX - 50, y = squareY, height = 110, time = 1700 } )
        transition.to( wall4, { x = squareX + 50, y = squareY, height = 110, time = 1700 } )
    end

    moveWalls()

    local function removeWalls()
        if (wall1 ~= nil) then
           display.remove(wall1) 
        end
        if (wall2 ~= nil) then
            display.remove(wall2) 
         end
         if (wall3 ~= nil) then
            display.remove(wall3) 
         end
         if (wall4 ~= nil) then
            display.remove(wall4) 
         end
    end

    timer.performWithDelay(1750, removeWalls, "temporaryTimer")
end

local function startSpawnWalls()
    spawnShrinkingWalls()
    timer.performWithDelay(1750, spawnShrinkingWalls, 5, "temporaryTimer")
end

local function startRandomEnemiesSpawn()
    local randomSpawnType = math.random(1, 6);
    local enemyExecutionTime = 0

    if randomSpawnType == 1 then
        spawnHorizontalLasers()
        enemyExecutionTime = 2700
    elseif randomSpawnType == 2 then
        spawnVerticalLasers()
        enemyExecutionTime = 2700
    elseif randomSpawnType == 3 then
        spawnSkyRays()
        enemyExecutionTime = 2500
    elseif randomSpawnType == 4 then
        spawnMovingBarriers()
        enemyExecutionTime = 16000
    elseif randomSpawnType == 5 then
        spawnBossDiagonalLasers("right")
        enemyExecutionTime = 2400
    elseif randomSpawnType == 6 then
        startSpawnWalls()
        enemyExecutionTime = 10500
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

local function spawnGunWithChance()
    if (math.random() > gunSpawnChance) then
        return
    end

    if (gunSpawned) then
        return
    end

    local gunX = math.random(bounds.x - bounds.width / 2 + boundsStrokeWidth, bounds.x + bounds.width / 2 - boundsStrokeWidth)
    local gunY = math.random(bounds.y - bounds.height / 2 + boundsStrokeWidth, bounds.y + bounds.height / 2 - boundsStrokeWidth)

    local gun = display.newCircle(mainGroup, gunX, gunY, 20);
    gun:setFillColor(1, 1, 0)
    gun.name = "gunCollectable"
    physics.addBody(gun, "static");
    gun.isSensor = true
    gunSpawned = true
end

local function startGunSpawn()
    timer.performWithDelay(gunSpawnTime, spawnGunWithChance, -1, "gunSpawnerTimer")
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

local function startLevitatingDummy(phase)
    local newY
    local nextPhase
    if (phase == "up") then
        newY = dummy.y + 20
        nextPhase = "down"
    else
        newY = dummy.y - 20
        nextPhase = "up"
    end

    transition.to(dummy, {time = 800, y = newY})

    local function next()
        startLevitatingDummy(nextPhase)
    end
    timer.performWithDelay(800, next, "temporaryTimer")
end

local function gameLoop()
    hideCautionText()
    disableAllBonuses()

    startRandomEnemiesSpawn()
    startBonusSpawn()
    startGunSpawn()
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

    explosionSprite.x = player.x
    explosionSprite.y = player.y
    explosionSprite.alpha = 1
    explosionSprite:play()
    local function hideSprite()
        explosionSprite.alpha = 0
    end
    timer.performWithDelay(700, hideSprite, "temporaryTimer")

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

local function spawnBullet(startX, startY, targetX, targetY)
    local bullet = display.newCircle(mainGroup, startX, startY, 10);
    bullet:setFillColor(1, 0, 0)
    bullet.name = "bullet"
    physics.addBody(bullet, "dynamic");
    bullet.isSensor = true

    local function removeBullet()
        if (bullet ~= nil) then
            display.remove(bullet)
        end
    end
    transition.to(bullet, {time=500, x=targetX, y=targetY, onComplete=removeBullet})
end

local function activateGun(gunX, gunY)
    local gun = display.newImageRect(mainGroup, "images/hole.png", 100, 100)
    gun.x = gunX
    gun.y = gunY

    local function bullet() return spawnBullet(gun.x, gun.y, dummy.x, dummy.y) end
    timer.performWithDelay(800, bullet, 3, "temporaryTimer")
    local function removeGun()
        if (gun ~= nil) then
            display.remove(gun)
        end
        gunSpawned = false
    end
    timer.performWithDelay(2400, removeGun, "temporaryTimer")
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

    if  obj1.name == "player" and obj2.name == "gunCollectable" or
        obj1.name == "gunCollectable" and obj2.name == "player" then
        
        local gunX
        local gunY
        if (obj1.name == "gunCollectable") then
            gunX = obj1.x
            gunY = obj1.y
            display.remove(obj1)
        else
            gunX = obj2.x
            gunY = obj2.y
            display.remove(obj2)
        end

        activateGun(gunX, gunY)
    end

    if  obj1.name == "bullet" and obj2.name == "boss" or
        obj1.name == "boss" and obj2.name == "bullet" then
        
        dummyHp = dummyHp - bulletDamage
        
        local bullet
        if (obj1.name == "bullet") then
            bullet = obj1
        else
            bullet = obj2
        end

        if (bullet ~= nil) then
            display.remove(bullet)
        end

        updateDummyHp()

        if (dummyHp <= 0) then
            stopGame(true)
        end
    end
end

local function tutorial()
    startLevitatingDummy("up")

    dummy.alpha = 1
    dummyHpUI.alpha = 1
    
    cautionText.y = cautionText.y + 60

    local function showFirst()
        cautionText.text = "Ты думал что сможешь так просто меня победить?"
    end
    local function showSecond()
        cautionText.text = "Ты ошибаешься.."
    end

    showFirst()
    timer.performWithDelay(2500, showSecond, "temporaryTimer")
    timer.performWithDelay(5000, gameLoop, "temporaryTimer")
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

    player = display.newCircle(mainGroup, bounds.x, bounds.y - 50, 15)
    player:setFillColor(1, 0, 0)
    player.moveX = 0
    player.moveY = 0
    player.name = "player"
    physics.addBody(player, "dynamic")
    player.isSensor = true

    speedUpBonusIcon = display.newImageRect(uiGroup, "images/speed-up-bonus.png", 60, 60)
    speedUpBonusIcon.x = bounds.x - bounds.width / 2 + 30
    speedUpBonusIcon.y = bounds.y - bounds.height / 2 - 50
    speedUpBonusIcon.alpha = 0.5

    shieldBonusIcon = display.newImageRect(uiGroup, "images/shield-bonus.png", 60, 60);
    shieldBonusIcon.x = speedUpBonusIcon.x + 80
    shieldBonusIcon.y = speedUpBonusIcon.y
    shieldBonusIcon.alpha = 0.5
    
    explosionBonusIcon = display.newImageRect(uiGroup, "images/explosion-bonus.png", 60, 60);
    explosionBonusIcon.x = shieldBonusIcon.x + 80
    explosionBonusIcon.y = shieldBonusIcon.y
    explosionBonusIcon.alpha = 0.5
    explosionBonusIcon:setFillColor(1, 0, 0)
    local explosionImageSheet = graphics.newImageSheet("image-sheets/explosion.png", { width=192, height=192, numFrames=20 })
    local explosionSequenceData = {
        name="explosion",
        start=1,
        count=20,
        time=700,
        loopCount=1
    }
    explosionSprite = display.newSprite(mainGroup, explosionImageSheet, explosionSequenceData)
    explosionSprite.alpha = 0


    cautionText = display.newText(uiGroup, "", display.contentCenterX, 110, native.systemFont, 44)
    cautionText:setFillColor(1, 0, 0)

    dummy = display.newImageRect(mainGroup, 'images/boss.png', 100, 130)
    dummy.x = display.contentCenterX
    dummy.y = 80
    dummy.alpha = 0
    dummy.name = "boss"
    physics.addBody(dummy, "static");
    dummy.isSensor = true

    dummyHpUI = display.newRect(uiGroup, dummy.x + 60, dummy.y + 10, 5, 100)
    dummyHpUI:setFillColor(1, 0, 0)
    dummyHpUI.alpha = 0

    laserSound = audio.loadSound("audio/laser.mp3")
    skyLaserSound = audio.loadSound("audio/sky-laser.mp3")
    musicTrack = audio.loadStream("audio/boss-battles.mp3")
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
        timer.cancel("gunSpawnerTimer")
    elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
        Runtime:removeEventListener("axis", axis)
		Runtime:removeEventListener("onMove", player)
        Runtime:removeEventListener("enterFrame", player)
        Runtime:removeEventListener("key", onKeyEvent)
        Runtime:removeEventListener("collision", onCollision)

        physics.pause()

        audio.stop(1)
        composer.removeScene("fifth-level");
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