local composer = require("composer")

local scene = composer.newScene()



function scene:create(event)

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

	local centerX = display.contentCenterX  -- Центр экрана по оси X
local centerY = display.contentCenterY  -- Центр экрана по оси Y
local screenWidth = display.actualContentWidth  -- Ширина экрана
local screenHeight = display.actualContentHeight  -- Высота экрана

-- Создание четырех стен
local wall1 = display.newRect( centerX, centerY - screenHeight/2, screenWidth, 10 )  -- Верхняя стена
local wall2 = display.newRect( centerX, centerY + screenHeight/2, screenWidth, 10 )  -- Нижняя стена
local wall3 = display.newRect( centerX - screenWidth/2, centerY, 10, screenHeight )  -- Левая стена
local wall4 = display.newRect( centerX + screenWidth/2, centerY, 10, screenHeight )  -- Правая стена

-- Установка цвета стен
wall1:setFillColor( 0.5 )
wall2:setFillColor( 0.5 )
wall3:setFillColor( 0.5 )
wall4:setFillColor( 0.5 )

local function moveWalls()
    transition.to( wall1, { x = centerX, y = centerY, width = 10, time = 2000 } )
    transition.to( wall2, { x = centerX, y = centerY, width = 10, time = 2000 } )
    transition.to( wall3, { x = centerX, y = centerY, height = 10, time = 2000 } )
    transition.to( wall4, { x = centerX, y = centerY, height = 10, time = 2000 } )
end

-- Вызов функции движения стен через 3 секунды
timer.performWithDelay(3000, moveWalls)
end



function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
	
    end
end



function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		
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