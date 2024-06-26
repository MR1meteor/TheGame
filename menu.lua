local composer = require("composer")

local scene = composer.newScene()

local musicTrack
audio.reserveChannels(1);
audio.setVolume( 0.5, { channel=1 } )


local function gotoLevels()
    composer.gotoScene("levels", { time=800, effect="crossFade" });
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

	local background = display.newImageRect(sceneGroup, "images/background.jpg", display.actualContentWidth, display.actualContentHeight)
	background.x = display.contentCenterX
	background.y = display.contentCenterY

    local levelsButton = display.newText(sceneGroup, "Начать", display.contentCenterX, display.contentCenterY - 100, native.systemFont, 44)
    levelsButton:setFillColor(1, 1, 0)

    local exitButton = display.newText(sceneGroup, "Выход", display.contentCenterX, display.contentCenterY + 100, native.systemFont, 44)
    exitButton:setFillColor(1, 1, 0)

    levelsButton:addEventListener("tap", gotoLevels)
    exitButton:addEventListener("tap", exit)

	local creditText = display.newText(sceneGroup, "Вдохновлено Undertale", display.contentCenterX + 470, display.contentCenterY + 200, native.systemFont, 30)
	creditText.rotation = -45
	creditText:setFillColor(0.8, 0.8, 0)

    musicTrack = audio.loadStream("audio/main-menu.mp3")
end



function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen
        audio.play( musicTrack, { channel=1, loops=-1 } )
    end
end



function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
	    audio.stop(1)
	end
end



function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
	audio.dispose( musicTrack )
end



scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene