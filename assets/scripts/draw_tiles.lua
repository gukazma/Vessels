-- Environment Tiles (16x16 each)
-- Ground tileset, Walls tileset, Furniture tileset

local transparent = Color(0, 0, 0, 0)

-- ============== GROUND TILES ==============
local function createGroundTiles()
    local sprite = Sprite(64, 16)  -- 4 tiles: grass, road, dirt, concrete
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_ground.aseprite"

    local img = sprite.cels[1].image

    -- Clear
    for y = 0, img.height - 1 do
        for x = 0, img.width - 1 do
            img:drawPixel(x, y, transparent)
        end
    end

    local function setPixel(x, y, color)
        if x >= 0 and x < img.width and y >= 0 and y < img.height then
            img:drawPixel(x, y, color)
        end
    end

    -- Tile 1: Grass (0-15)
    local grass1 = Color(80, 140, 80)
    local grass2 = Color(70, 120, 70)
    local grass3 = Color(90, 150, 90)
    for y = 0, 15 do
        for x = 0, 15 do
            local c = grass1
            if (x + y) % 3 == 0 then c = grass2
            elseif (x * y) % 5 == 0 then c = grass3 end
            setPixel(x, y, c)
        end
    end
    -- Add grass blades
    setPixel(3, 5, Color(60, 100, 60))
    setPixel(8, 3, Color(60, 100, 60))
    setPixel(12, 10, Color(60, 100, 60))
    setPixel(5, 13, Color(60, 100, 60))

    -- Tile 2: Road (16-31)
    local road1 = Color(80, 80, 90)
    local road2 = Color(70, 70, 80)
    local roadLine = Color(200, 200, 150)
    for y = 0, 15 do
        for x = 16, 31 do
            local c = road1
            if (x + y) % 4 == 0 then c = road2 end
            setPixel(x, y, c)
        end
    end
    -- Road marking
    for x = 22, 25 do
        setPixel(x, 7, roadLine)
        setPixel(x, 8, roadLine)
    end

    -- Tile 3: Dirt (32-47)
    local dirt1 = Color(140, 110, 80)
    local dirt2 = Color(120, 95, 70)
    local dirt3 = Color(150, 120, 90)
    for y = 0, 15 do
        for x = 32, 47 do
            local c = dirt1
            if (x * 3 + y) % 5 == 0 then c = dirt2
            elseif (x + y * 2) % 7 == 0 then c = dirt3 end
            setPixel(x, y, c)
        end
    end
    -- Add pebbles
    setPixel(35, 4, Color(100, 80, 60))
    setPixel(40, 9, Color(100, 80, 60))
    setPixel(44, 2, Color(100, 80, 60))

    -- Tile 4: Concrete (48-63)
    local concrete1 = Color(170, 170, 170)
    local concrete2 = Color(160, 160, 160)
    local concrete3 = Color(180, 180, 180)
    for y = 0, 15 do
        for x = 48, 63 do
            local c = concrete1
            if (x + y) % 6 == 0 then c = concrete2
            elseif (x - y) % 8 == 0 then c = concrete3 end
            setPixel(x, y, c)
        end
    end
    -- Crack
    setPixel(52, 5, Color(120, 120, 120))
    setPixel(53, 6, Color(120, 120, 120))
    setPixel(54, 7, Color(120, 120, 120))

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_ground.aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_ground.png",
    }
    print("Ground tiles created")
end

-- ============== WALL TILES ==============
local function createWallTiles()
    local sprite = Sprite(64, 16)  -- 4 tiles: brick wall, fence, door, window
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_walls.aseprite"

    local img = sprite.cels[1].image

    for y = 0, img.height - 1 do
        for x = 0, img.width - 1 do
            img:drawPixel(x, y, transparent)
        end
    end

    local function setPixel(x, y, color)
        if x >= 0 and x < img.width and y >= 0 and y < img.height then
            img:drawPixel(x, y, color)
        end
    end

    -- Tile 1: Brick Wall (0-15)
    local brick = Color(160, 80, 70)
    local mortar = Color(180, 180, 170)
    for y = 0, 15 do
        for x = 0, 15 do
            if y % 4 == 0 then
                setPixel(x, y, mortar)
            elseif x % 8 == (math.floor(y / 4) % 2) * 4 then
                setPixel(x, y, mortar)
            else
                setPixel(x, y, brick)
            end
        end
    end

    -- Tile 2: Fence (16-31)
    local wood = Color(140, 100, 60)
    local woodDark = Color(110, 80, 50)
    for y = 0, 15 do
        for x = 16, 31 do
            local rx = x - 16
            -- Vertical posts every 5 pixels
            if rx % 5 == 0 or rx % 5 == 1 then
                setPixel(x, y, wood)
            -- Horizontal bars
            elseif y >= 3 and y <= 4 then
                setPixel(x, y, woodDark)
            elseif y >= 10 and y <= 11 then
                setPixel(x, y, woodDark)
            end
        end
    end

    -- Tile 3: Door (32-47)
    local doorWood = Color(120, 80, 50)
    local doorFrame = Color(100, 70, 45)
    local doorknob = Color(200, 180, 100)
    for y = 0, 15 do
        for x = 32, 47 do
            local rx = x - 32
            -- Frame
            if rx <= 1 or rx >= 14 or y <= 0 then
                setPixel(x, y, doorFrame)
            else
                setPixel(x, y, doorWood)
            end
        end
    end
    -- Door panels
    for y = 3, 6 do
        for x = 35, 44 do
            setPixel(x, y, doorFrame)
        end
    end
    for y = 9, 12 do
        for x = 35, 44 do
            setPixel(x, y, doorFrame)
        end
    end
    -- Doorknob
    setPixel(43, 8, doorknob)
    setPixel(44, 8, doorknob)

    -- Tile 4: Window (48-63)
    local windowFrame = Color(180, 180, 180)
    local glass = Color(150, 180, 200)
    local glassDark = Color(120, 150, 170)
    for y = 0, 15 do
        for x = 48, 63 do
            local rx = x - 48
            -- Frame
            if rx <= 1 or rx >= 14 or y <= 1 or y >= 14 then
                setPixel(x, y, windowFrame)
            -- Center cross
            elseif rx == 7 or rx == 8 then
                setPixel(x, y, windowFrame)
            elseif y == 7 or y == 8 then
                setPixel(x, y, windowFrame)
            else
                -- Glass with reflection
                if rx < 7 and y < 7 then
                    setPixel(x, y, glassDark)
                else
                    setPixel(x, y, glass)
                end
            end
        end
    end

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_walls.aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_walls.png",
    }
    print("Wall tiles created")
end

-- ============== FURNITURE TILES ==============
local function createFurnitureTiles()
    local sprite = Sprite(64, 16)  -- 4 tiles: bed, table, chair, crate
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_furniture.aseprite"

    local img = sprite.cels[1].image

    for y = 0, img.height - 1 do
        for x = 0, img.width - 1 do
            img:drawPixel(x, y, transparent)
        end
    end

    local function setPixel(x, y, color)
        if x >= 0 and x < img.width and y >= 0 and y < img.height then
            img:drawPixel(x, y, color)
        end
    end

    -- Tile 1: Bed (0-15) - top-down view
    local bedFrame = Color(140, 100, 60)
    local pillow = Color(240, 240, 240)
    local blanket = Color(70, 100, 140)
    for y = 0, 15 do
        for x = 0, 15 do
            -- Frame
            if x <= 1 or x >= 14 or y <= 1 or y >= 14 then
                setPixel(x, y, bedFrame)
            -- Pillow area
            elseif y >= 2 and y <= 5 then
                setPixel(x, y, pillow)
            -- Blanket
            else
                setPixel(x, y, blanket)
            end
        end
    end

    -- Tile 2: Table (16-31) - top-down view
    local tableTop = Color(160, 120, 80)
    local tableDark = Color(130, 95, 65)
    for y = 0, 15 do
        for x = 16, 31 do
            local rx = x - 16
            -- Table edge
            if rx <= 0 or rx >= 15 or y <= 0 or y >= 15 then
                setPixel(x, y, tableDark)
            else
                setPixel(x, y, tableTop)
            end
        end
    end
    -- Wood grain
    for x = 18, 29 do
        setPixel(x, 5, tableDark)
        setPixel(x, 10, tableDark)
    end

    -- Tile 3: Chair (32-47) - top-down view
    local chairSeat = Color(100, 70, 45)
    local chairBack = Color(80, 55, 35)
    for y = 0, 15 do
        for x = 32, 47 do
            local rx = x - 32
            -- Chair back
            if y <= 3 and rx >= 3 and rx <= 12 then
                setPixel(x, y, chairBack)
            -- Seat
            elseif y >= 5 and y <= 13 and rx >= 3 and rx <= 12 then
                setPixel(x, y, chairSeat)
            end
        end
    end

    -- Tile 4: Crate (48-63) - top-down view
    local crateWood = Color(180, 140, 90)
    local crateDark = Color(140, 105, 70)
    local crateNail = Color(120, 120, 130)
    for y = 0, 15 do
        for x = 48, 63 do
            local rx = x - 48
            -- Edge
            if rx <= 1 or rx >= 14 or y <= 1 or y >= 14 then
                setPixel(x, y, crateDark)
            else
                setPixel(x, y, crateWood)
            end
        end
    end
    -- Cross pattern on top
    for i = 2, 13 do
        setPixel(48 + i, i, crateDark)
        setPixel(48 + i, 15 - i, crateDark)
    end
    -- Nails
    setPixel(50, 2, crateNail)
    setPixel(61, 2, crateNail)
    setPixel(50, 13, crateNail)
    setPixel(61, 13, crateNail)

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_furniture.aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\tiles\\tileset_furniture.png",
    }
    print("Furniture tiles created")
end

-- Create all tilesets
createGroundTiles()
createWallTiles()
createFurnitureTiles()

print("All environment tiles created successfully!")
