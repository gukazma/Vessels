-- Zombie Enemy Sprite (16x16, 4 directions, 4 walk frames)
-- Directions: down(0), left(1), right(2), up(3)
-- Shambling walk animation

local sprite = Sprite(64, 64)  -- 4 directions horizontally, 4 frames vertically
sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\enemies\\zombie_walk.aseprite"

-- Color palette - zombie colors
local zombieSkin = Color(130, 150, 120)      -- Greenish gray skin
local zombieDark = Color(90, 110, 80)        -- Darker green for shadows
local blood = Color(120, 40, 40)             -- Dark blood stains
local tornCloth = Color(80, 70, 60)          -- Torn clothing
local eyes = Color(200, 200, 150)            -- Pale yellowish eyes
local outline = Color(40, 40, 35)            -- Dark outline
local transparent = Color(0, 0, 0, 0)

-- Clear sprite
local img = sprite.cels[1].image
for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
        img:drawPixel(x, y, transparent)
    end
end

-- Helper function to draw a pixel
local function setPixel(x, y, color)
    if x >= 0 and x < img.width and y >= 0 and y < img.height then
        img:drawPixel(x, y, color)
    end
end

-- Draw zombie for a specific direction and frame
local function drawZombie(baseX, baseY, direction, frame)
    -- Shambling animation - more exaggerated than player
    local bodyOffset = 0
    local tiltX = 0

    if frame == 1 then
        bodyOffset = 0
        tiltX = 0
    elseif frame == 2 then
        bodyOffset = -1
        tiltX = 1
    elseif frame == 3 then
        bodyOffset = 0
        tiltX = 0
    else  -- frame 4
        bodyOffset = -1
        tiltX = -1
    end

    -- Head (slightly misshapen, 4x4)
    for y = 2, 5 do
        for x = 6, 9 do
            setPixel(baseX + x + tiltX, baseY + y + bodyOffset, zombieSkin)
        end
    end
    -- Dark patches on head
    setPixel(baseX + 7 + tiltX, baseY + 3 + bodyOffset, zombieDark)
    setPixel(baseX + 9 + tiltX, baseY + 4 + bodyOffset, zombieDark)

    -- Eyes based on direction
    if direction == 0 then  -- Down
        setPixel(baseX + 7 + tiltX, baseY + 4 + bodyOffset, eyes)
        setPixel(baseX + 8 + tiltX, baseY + 4 + bodyOffset, eyes)
        -- Open mouth
        setPixel(baseX + 7 + tiltX, baseY + 5 + bodyOffset, blood)
        setPixel(baseX + 8 + tiltX, baseY + 5 + bodyOffset, blood)
    elseif direction == 1 then  -- Left
        setPixel(baseX + 6 + tiltX, baseY + 4 + bodyOffset, eyes)
    elseif direction == 2 then  -- Right
        setPixel(baseX + 9 + tiltX, baseY + 4 + bodyOffset, eyes)
    end
    -- No visible eyes from behind (direction 3)

    -- Body - torn clothes
    for y = 6, 9 do
        for x = 5, 10 do
            setPixel(baseX + x, baseY + y + bodyOffset, tornCloth)
        end
    end
    -- Blood stains on body
    setPixel(baseX + 6, baseY + 7 + bodyOffset, blood)
    setPixel(baseX + 7, baseY + 8 + bodyOffset, blood)
    setPixel(baseX + 9, baseY + 6 + bodyOffset, blood)

    -- Arms - one arm hangs lower (zombie characteristic)
    if direction == 0 or direction == 3 then  -- Front or back
        -- Left arm normal
        setPixel(baseX + 4, baseY + 7 + bodyOffset, zombieSkin)
        setPixel(baseX + 4, baseY + 8 + bodyOffset, zombieSkin)
        -- Right arm hangs lower/extended
        if frame == 2 or frame == 4 then
            setPixel(baseX + 11, baseY + 7 + bodyOffset, zombieSkin)
            setPixel(baseX + 11, baseY + 8 + bodyOffset, zombieSkin)
            setPixel(baseX + 12, baseY + 9 + bodyOffset, zombieSkin)
        else
            setPixel(baseX + 11, baseY + 7 + bodyOffset, zombieSkin)
            setPixel(baseX + 11, baseY + 8 + bodyOffset, zombieSkin)
            setPixel(baseX + 11, baseY + 9 + bodyOffset, zombieSkin)
        end
    else  -- Side views
        setPixel(baseX + 4, baseY + 7 + bodyOffset, zombieSkin)
        setPixel(baseX + 11, baseY + 8 + bodyOffset, zombieSkin)
    end

    -- Legs - shambling gait
    if frame == 1 then
        setPixel(baseX + 6, baseY + 10, tornCloth)
        setPixel(baseX + 6, baseY + 11, tornCloth)
        setPixel(baseX + 6, baseY + 12, zombieSkin)
        setPixel(baseX + 9, baseY + 10, tornCloth)
        setPixel(baseX + 9, baseY + 11, tornCloth)
        setPixel(baseX + 9, baseY + 12, zombieSkin)
    elseif frame == 2 then
        -- Dragging left leg
        setPixel(baseX + 4, baseY + 10, tornCloth)
        setPixel(baseX + 4, baseY + 11, tornCloth)
        setPixel(baseX + 4, baseY + 12, zombieSkin)
        setPixel(baseX + 9, baseY + 10, tornCloth)
        setPixel(baseX + 9, baseY + 11, tornCloth)
        setPixel(baseX + 9, baseY + 12, zombieSkin)
    elseif frame == 3 then
        setPixel(baseX + 6, baseY + 10, tornCloth)
        setPixel(baseX + 6, baseY + 11, tornCloth)
        setPixel(baseX + 6, baseY + 12, zombieSkin)
        setPixel(baseX + 9, baseY + 10, tornCloth)
        setPixel(baseX + 9, baseY + 11, tornCloth)
        setPixel(baseX + 9, baseY + 12, zombieSkin)
    else  -- frame 4
        setPixel(baseX + 6, baseY + 10, tornCloth)
        setPixel(baseX + 6, baseY + 11, tornCloth)
        setPixel(baseX + 6, baseY + 12, zombieSkin)
        -- Dragging right leg
        setPixel(baseX + 11, baseY + 10, tornCloth)
        setPixel(baseX + 11, baseY + 11, tornCloth)
        setPixel(baseX + 11, baseY + 12, zombieSkin)
    end

    -- Outline
    setPixel(baseX + 5 + tiltX, baseY + 2 + bodyOffset, outline)
    setPixel(baseX + 10 + tiltX, baseY + 2 + bodyOffset, outline)
end

-- Draw all 4 directions x 4 frames
for frame = 1, 4 do
    for dir = 0, 3 do
        drawZombie(dir * 16, (frame - 1) * 16, dir, frame)
    end
end

sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\enemies\\zombie_walk.aseprite")

-- Export sprite sheet
app.command.ExportSpriteSheet {
    ui = false,
    askOverwrite = false,
    type = SpriteSheetType.ROWS,
    textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\enemies\\zombie_walk.png",
    dataFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\enemies\\zombie_walk.json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    layer = "",
    tag = "",
    splitLayers = false,
    listLayers = true,
    listTags = true,
    listSlices = true
}

print("Zombie sprite created successfully!")
