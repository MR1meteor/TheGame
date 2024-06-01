local composer = require("composer")

local scene = composer.newScene();



local function gotoMenu()
    composer.gotoScene("menu", { time=800, effect="crossFade" });
end

local function gotoFirstLevel()
    composer.gotoScene("first-level", { time=800, effect="crossFade" })
end

local function gotoSecondLevel()
    composer.gotoScene("second-level", { time=800, effect="crossFade" })
end

local function gotoThirdLevel()
    composer.gotoScene("third-level", { time=800, effect="crossFade" })
end

local function gotoFourthLevel()
    composer.gotoScene("fourth-level", { time = 800, effect="crossFade" })
end



function scene:create(event)

    local sceneGroup = self.view

    local firstLevelButton = display.newText(sceneGroup, "1", display.contentCenterX - 200, display.contentCenterY, native.systemFont, 44)
    firstLevelButton:setFillColor(1, 1, 0)

    local secondLevelButton = display.newText(sceneGroup, "2", display.contentCenterX - 100, display.contentCenterY, native.systemFont, 44)
    secondLevelButton:setFillColor(1, 1, 0)

    local thirdLevelButton = display.newText(sceneGroup, "3", display.contentCenterX, display.contentCenterY, native.systemFont, 44)
    thirdLevelButton:setFillColor(1, 1, 0)

    local fourthLevelButton = display.newText(sceneGroup, "4", display.contentCenterX + 100, display.contentCenterY, native.systemFont, 44)
    fourthLevelButton:setFillColor(1, 1, 0)

    local fifthLevelButton = display.newText(sceneGroup, "5", display.contentCenterX + 200, display.contentCenterY, native.systemFont, 44)
    fifthLevelButton:setFillColor(1, 1, 0)

    local menuButton = display.newText(sceneGroup, "Menu", display.contentCenterX, display.contentCenterY + 100, native.systemFont, 44)
    menuButton:setFillColor(1, 1, 0)

    menuButton:addEventListener("tap", gotoMenu)
    firstLevelButton:addEventListener("tap", gotoFirstLevel)
    secondLevelButton:addEventListener("tap", gotoSecondLevel)
    thirdLevelButton:addEventListener("tap", gotoThirdLevel)
    fourthLevelButton:addEventListener("tap", gotoFourthLevel)
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



scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene