
_W = display.contentWidth
_H = display.contentHeight

display.setStatusBar( display.HiddenStatusBar )

local physics = require( "physics" )
physics.start()
--physics.setDrawMode( "hybrid" )
--physics.setDrawMode( "debug" )

local background = display.newRect(0, 0, _W, _H)

local myGradient = graphics.newGradient(
  { 75, 75, 225 },
  { 150, 150, 255 },
  "left" )

--background:setFillColor(100, 200, 255, 255)
background:setFillColor(myGradient)

-- forward reference
local myMoveArrow
local hasArrowBeenReleased = false

local totalScore = 0
local totalShots = 0

local mySounds = {}
mySounds.deadBullsEye = audio.loadSound("sounds/deadbullseye.mp3")
mySounds.closeBullsEye = audio.loadSound("sounds/closebullseye.mp3")
mySounds.bullsEye = audio.loadSound("sounds/bullseye.mp3")
mySounds.whoosh = audio.loadSound("sounds/whoosh.mp3")
mySounds.thunk = audio.loadSound("sounds/thunk.mp3")


-------------------------------------------------
-- Local functions
-------------------------------------------------

    local function pathDislayObjectUpOrDown(turtle, maxVarienceUp, maxVarienceDown, step)
    -- turtle: the display object we wish to move
    -- maxVarience: the + and - from the original location (example 100 pixels)
    -- step = the amount of movement for each step in the UP (-) or Down (+) direction

        
        -- if we do not have a directin, start moving the turtle to the right
        turtle.yDirection = turtle.yDirection or step or 1

        -- if we pass the end, turn around
        -- elseif we passed the beginging, turn around 
        if turtle.y > turtle.startingY + maxVarienceDown then
            turtle.yDirection = -step or -1

        elseif turtle.y < turtle.startingY - maxVarienceUp then
            turtle.yDirection = step or 1

        end

        turtle.y = turtle.y + turtle.yDirection

    end   
    
    local function pathDislayObjectLeftOrRight(turtle, maxVarienceLeft, maxVarienceRight, step)
    -- turtle: the display object we wish to move
    -- maxVarience: the + and - from the original location (example 100 pixels)
    -- step = the amount of movement for each step in the left (-) or right (+) direction
        
        -- if we do not have a directin, start moving the turtle to the right
        turtle.xDirection = turtle.xDirection or step or 1
        

        -- if we pass the end, turn around
        -- elseif we passed the beginging, turn around 
        if turtle.x > turtle.startingX + maxVarienceRight then
            turtle.xDirection = -step or -1

        elseif turtle.x < turtle.startingX - maxVarienceLeft then
            turtle.xDirection = step or 1
        end

        turtle.x = turtle.x + turtle.xDirection

    end    
    
local function postAMessageOnTheScreen(pMessage, startX, startY, endingX, endingY)

    local lblMyMessage

    -- destroys the local label after we are done
    local function destroyLabel()

        lblMyMessage:removeSelf()
        lblMyMessage = nil

    end

    lblMyMessage = display.newText(pMessage, 0 , 0, native.systemFont, 32)
    lblMyMessage:setReferencePoint(display.TopLeftReferencePoint)
    lblMyMessage.x = startX or _W/2
    lblMyMessage.y = startY or 0
    lblMyMessage:setTextColor(255, 255, 255)

    --todo: make sure this rotation is dynamic instead of static
    --lblmyMessage.rotation = 90

    transition.to(lblMyMessage, { time=3000, x=endingX or _W/4, y= endingY or _H/2, onComplete = destroyLabel} )


end 
   
local function roundNumber(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end
    
    
-------------------------------------------------
-- screen code
-------------------------------------------------

    local totalScoreText = display.newEmbossedText('Score: 0  Shots: 0  Avg: ?', 5, 5, _W, 50, native.systemFont, 25)


    local target = display.newImageRect( "images/targetbackground.png", 100, 100 )
    target.x = 429
    target.y = 0 + target.height/2
    target.startingY = target.y
    target.enterFrame = function() 
                            pathDislayObjectUpOrDown(target, 0, _H - target.height, 2); 
                        end
        Runtime:addEventListener( "enterFrame", target.enterFrame)    
    
    

    local targetBar = display.newImageRect( "images/targetbar.png", 4, 100 )
    targetBar.x = target.x
    targetBar.y = 0 + target.y
    physics.addBody( targetBar, "static", { density=1, friction=0.3, bounce=0.2 } )
    targetBar.startingY = targetBar.y
    targetBar.enterFrame = function() 

                                targetBar.y = target.y
                                targetBar.x = target.x

                             end
        Runtime:addEventListener( "enterFrame", targetBar.enterFrame)        
    

    local guy = display.newImageRect( "images/guy.png", 50, 50 )
    guy.x = 25
    guy.y = _H - guy.height /2
    guy.startingY = guy.y
    guy.enterFrame = function() 
                            pathDislayObjectUpOrDown(guy, _H - target.height, 0, 2); 
                    end
    Runtime:addEventListener( "enterFrame", guy.enterFrame)    
        
    local arrow
    local function createNewArrow()
        
            arrow = display.newImageRect( "images/arrow.png", 75, 15 )
            arrow.x = 89
            arrow.y = guy.y
            arrow.startingY = arrow.y
            arrow.startingX = arrow.x
            physics.addBody( arrow, "dynamic", { density=1, friction=0.3, bounce=0.2 } )
            arrow.enterFrameForUpDown = function() 

                                            arrow.y = guy.y
                                        end
        Runtime:addEventListener( "enterFrame", arrow.enterFrameForUpDown)
        
    end
    
    local function removeArrow()
        
        -- stop the arrow movement
        hasArrowBeenReleased = false
        
        Runtime:removeEventListener( "enterFrame", arrow.enterFrameForLeftRight)
        Runtime:removeEventListener( "enterFrame", arrow.enterFrameForUpDown)
        Runtime:removeEventListener( "enterFrame", myMoveArrow)
        arrow:removeSelf()
        
    end    
    
    createNewArrow()
    

        


-- upon touch create a listener to move the arrow
local function myTouchListener(event)
                
        if event.phase == 'began' then
                
            if hasArrowBeenReleased == false then
                
                --note that the arrow has been released
                hasArrowBeenReleased = true
                totalShots = totalShots + 1
            
                audio.play(mySounds.whoosh)
                
                
                arrow.enterFrameForLeftRight = function() 
   
                                                    pathDislayObjectLeftOrRight(arrow, 0, _W, 7);

                                                end

                Runtime:addEventListener( "enterFrame", arrow.enterFrameForLeftRight)
                
                
            end
        end
        
end

local function myMoveArrow(e)
    
    -- if we don't have an arrow at the moment, don't move it
    if not arrow.x then
        return
    end

    -- if the arrow is off the screen
    if arrow.x > _W then 
        
        removeArrow()
        createNewArrow()
              
        
        print('we are off the screen')
    end
    
    
end


--local myButton = display.newImage( "button.png" )
background:addEventListener( "touch", myTouchListener )

Runtime:addEventListener("enterFrame", myMoveArrow)


    local function onTargetCollision( self, event )
                  
            if ( event.phase == "began" ) then
                
                local targetBarY = targetBar.y
                local arrowY = arrow.y
                local howFarAwayFromTheCenter = math.abs(targetBarY - arrowY)
                                            
                --print('how far away from the center: ' .. howFarAwayFromTheCenter)
                
                if howFarAwayFromTheCenter <=1 then
                    -- Dead bullsEye
                    totalScore = totalScore + 10
                    postAMessageOnTheScreen('+10!!!', targetBar.x - 50, targetBar.y, targetBar.x - 50, targetBarY-100)                    
                    postAMessageOnTheScreen('Dead Bull!!!', _W/3, 0, _W/3, _H/2)
                    audio.play(mySounds.deadBullsEye)
                    audio.play(mySounds.thunk)                      
                elseif howFarAwayFromTheCenter <=5 then
                    -- Close BullEye
                    totalScore = totalScore + 7
                    postAMessageOnTheScreen('+7!!', targetBar.x - 50, target.y, targetBar.x - 50, targetBarY-100)                    
                    postAMessageOnTheScreen('Close Bull!!', _W/3, 0, _W/3, _H/2)
                    audio.play(mySounds.closeBullsEye)
                    audio.play(mySounds.thunk)                      
                elseif howFarAwayFromTheCenter <=15 then
                    -- BullsEye
                    totalScore = totalScore + 5
                    postAMessageOnTheScreen('+5', targetBar.x - 50, targetBar.y, targetBar.x - 50, targetBarY-100)   
                    postAMessageOnTheScreen('Bull!', _W/3, 0, _W/3, _H/2)
                    audio.play(mySounds.bullsEye)
                    audio.play(mySounds.thunk)  
                elseif howFarAwayFromTheCenter <=25 then
                    -- BullsEye
                    totalScore = totalScore + 4                    
                    postAMessageOnTheScreen('+4', targetBar.x - 50, targetBar.y, targetBar.x - 50, targetBarY-100)   
                    audio.play(mySounds.thunk)
                elseif howFarAwayFromTheCenter <=35 then
                    -- BullsEye
                    totalScore = totalScore + 3                    
                    postAMessageOnTheScreen('+3', targetBar.x - 50, targetBar.y, targetBar.x - 50, targetBarY-100)   
                    audio.play(mySounds.thunk)                    
                elseif howFarAwayFromTheCenter <=45 then
                    -- BullsEye
                    totalScore = totalScore + 2
                    postAMessageOnTheScreen('+2', targetBar.x - 50, targetBar.y, targetBar.x - 50, targetBarY-100)   
                    audio.play(mySounds.thunk)                    
                elseif howFarAwayFromTheCenter <=100 then
                    -- BullsEye
                    totalScore = totalScore + 1
                    postAMessageOnTheScreen('+1', targetBar.x - 50, targetBar.y, targetBar.x - 50, targetBarY-100)                       
                    audio.play(mySounds.thunk)                    
                end
                                
                removeArrow()
                timer.performWithDelay(100, createNewArrow)
                
                -- round to two decimal places
                local averageShot = roundNumber(totalScore / totalShots, 2)
                
                print('total score: ' .. totalScore .. '    Shots: ' .. totalShots .. '    Avg: ' .. averageShot)
                totalScoreText:setText('Score: ' .. totalScore .. '  Shots: ' .. totalShots .. '  Avg: ' .. averageShot)
                --postAMessageOnTheScreen(totalScore)

            end

    end 

    
    targetBar.collision = onTargetCollision
    targetBar:addEventListener( "collision", targetBar)


    

        
        
    
