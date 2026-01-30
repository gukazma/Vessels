-- Player Character Sprite (16x16, 4 directions, 4 walk frames)
-- Directions: down(0), left(1), right(2), up(3)
-- Each direction has 4 walk frames

local sprite = Sprite(64, 64)  -- 4 directions horizontally, 4 frames vertically
sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\player\\player_walk.aseprite"

-- Color palette
local skin = Color(255, 213, 170)       -- Skin tone
local hair = Color(60, 40, 30)          -- Dark brown hair
local shirt = Color(70, 130, 180)       -- Steel blue shirt
local pants = Color(50, 50, 70)         -- Dark pants
local outline = Color(30, 30, 30)       -- Dark outline
local eyes = Color(40, 40, 40)          -- Eyes
local transparent = Color(0, 0, 0, 0)   -- Transparent

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

-- Draw player for a specific direction and frame
local function drawPlayer(baseX, baseY, direction, frame)
    -- Animation offsets for walk cycle
    local bodyOffset = 0
    local legFrame = frame  -- 1-4

    if frame == 2 or frame == 4 then
        bodyOffset = -1  -- Bob up slightly
    end

    -- Head (4x4 centered at top)
    for y = 2, 5 do
        for x = 6, 9 do
            setPixel(baseX + x, baseY + y + bodyOffset, skin)
        end
    end

    -- Hair on top
    if direction == 0 then  -- Down
        for x = 6, 9 do
            setPixel(baseX + x, baseY + 2 + bodyOffset, hair)
        end
        -- Eyes
        setPixel(baseX + 7, baseY + 4 + bodyOffset, eyes)
        setPixel(baseX + 8, baseY + 4 + bodyOffset, eyes)
    elseif direction == 1 then  -- Left
        for x = 7, 9 do
            setPixel(baseX + x, baseY + 2 + bodyOffset, hair)
        end
        setPixel(baseX + 9, baseY + 3 + bodyOffset, hair)
        -- Eye
        setPixel(baseX + 7, baseY + 4 + bodyOffset, eyes)
    elseif direction == 2 then  -- Right
        for x = 6, 8 do
            setPixel(baseX + x, baseY + 2 + bodyOffset, hair)
        end
        setPixel(baseX + 6, baseY + 3 + bodyOffset, hair)
        -- Eye
        setPixel(baseX + 8, baseY + 4 + bodyOffset, eyes)
    else  -- Up (direction == 3)
        for x = 6, 9 do
            setPixel(baseX + x, baseY + 2 + bodyOffset, hair)
            setPixel(baseX + x, baseY + 3 + bodyOffset, hair)
        end
    end

    -- Body/Shirt (6x4)
    for y = 6, 9 do
        for x = 5, 10 do
            setPixel(baseX + x, baseY + y + bodyOffset, shirt)
        end
    end

    -- Arms
    if frame == 2 then
        setPixel(baseX + 4, baseY + 7 + bodyOffset, skin)
        setPixel(baseX + 11, baseY + 8 + bodyOffset, skin)
    elseif frame == 4 then
        setPixel(baseX + 4, baseY + 8 + bodyOffset, skin)
        setPixel(baseX + 11, baseY + 7 + bodyOffset, skin)
    else
        setPixel(baseX + 4, baseY + 7 + bodyOffset, skin)
        setPixel(baseX + 11, baseY + 7 + bodyOffset, skin)
    end

    -- Legs/Pants
    if frame == 1 then  -- Standing
        setPixel(baseX + 6, baseY + 10, pants)
        setPixel(baseX + 6, baseY + 11, pants)
        setPixel(baseX + 6, baseY + 12, pants)
        setPixel(baseX + 9, baseY + 10, pants)
        setPixel(baseX + 9, baseY + 11, pants)
        setPixel(baseX + 9, baseY + 12, pants)
    elseif frame == 2 then  -- Left leg forward
        setPixel(baseX + 5, baseY + 10, pants)
        setPixel(baseX + 5, baseY + 11, pants)
        setPixel(baseX + 5, baseY + 12, pants)
        setPixel(baseX + 9, baseY + 10, pants)
        setPixel(baseX + 10, baseY + 11, pants)
        setPixel(baseX + 10, baseY + 12, pants)
    elseif frame == 3 then  -- Standing
        setPixel(baseX + 6, baseY + 10, pants)
        setPixel(baseX + 6, baseY + 11, pants)
        setPixel(baseX + 6, baseY + 12, pants)
        setPixel(baseX + 9, baseY + 10, pants)
        setPixel(baseX + 9, baseY + 11, pants)
        setPixel(baseX + 9, baseY + 12, pants)
    else  -- frame == 4, Right leg forward
        setPixel(baseX + 6, baseY + 10, pants)
        setPixel(baseX + 5, baseY + 11, pants)
        setPixel(baseX + 5, baseY + 12, pants)
        setPixel(baseX + 10, baseY + 10, pants)
        setPixel(baseX + 10, baseY + 11, pants)
        setPixel(baseX + 10, baseY + 12, pants)
    end

    -- Outline around head
    setPixel(baseX + 5, baseY + 2 + bodyOffset, outline)
    setPixel(baseX + 10, baseY + 2 + bodyOffset, outline)
    setPixel(baseX + 5, baseY + 5 + bodyOffset, outline)
    setPixel(baseX + 10, baseY + 5 + bodyOffset, outline)
end

-- Draw all 4 directions (columns) x 4 frames (rows)
for frame = 1, 4 do
    for dir = 0, 3 do
        drawPlayer(dir * 16, (frame - 1) * 16, dir, frame)
    end
end

sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\player\\player_walk.aseprite")

-- Export sprite sheet
app.command.ExportSpriteSheet {
    ui = false,
    askOverwrite = false,
    type = SpriteSheetType.ROWS,
    textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\player\\player_walk.png",
    dataFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\player\\player_walk.json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    layer = "",
    tag = "",
    splitLayers = false,
    listLayers = true,
    listTags = true,
    listSlices = true
}

print("Player walk sprite created successfully!")
