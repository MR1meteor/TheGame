local composer = require("composer")

local scene = composer.newScene()



local function gotoLevels()
    composer.gotoScene("levels", { time=800, effect="crossFade" });
end

local function gotoHelp()
end

local function exit()
    os.exit(1)
end



function scene:create(event)

    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    -- local background = display.newImageRect(sceneGroup, "", width, height)
    -- background.x = display.contentCenterX
    -- background.y = display.contentCenterY

    local levelsButton = display.newText(sceneGroup, "Play", display.contentCenterX, display.contentCenterY - 200, native.systemFont, 44)
    levelsButton:setFillColor(1, 1, 0)

    local helpButton = display.newText(sceneGroup, "Help", display.contentCenterX, display.contentCenterY, native.systemFont, 44)
    helpButton:setFillColor(1, 1, 0)

    local exitButton = display.newText(sceneGroup, "Exit", display.contentCenterX, display.contentCenterY + 200, native.systemFont, 44)
    exitButton:setFillColor(1, 1, 0)

    levelsButton:addEventListener("tap", gotoLevels)
    helpButton:addEventListener("tap", gotoHelp)
    exitButton:addEventListener("tap", exit)
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