-- UI Elements
-- Panel (9-slice), Button states, Status icons, Inventory slot

local transparent = Color(0, 0, 0, 0)

-- ============== UI PANEL (9-slice, 48x48) ==============
local function createPanel()
    local sprite = Sprite(48, 48)
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_panel.aseprite"

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

    local border = Color(60, 50, 45)
    local borderLight = Color(90, 80, 70)
    local bg = Color(45, 40, 38)
    local bgLight = Color(55, 50, 48)

    -- Fill background
    for y = 0, 47 do
        for x = 0, 47 do
            -- Corners (16x16 each)
            local isCorner = (x < 16 or x >= 32) and (y < 16 or y >= 32)
            local isEdge = x < 16 or x >= 32 or y < 16 or y >= 32

            -- Border (outer 2 pixels)
            if x <= 1 or x >= 46 or y <= 1 or y >= 46 then
                if x == 0 or y == 0 then
                    setPixel(x, y, border)
                else
                    setPixel(x, y, borderLight)
                end
            -- Inner area
            else
                if (x + y) % 8 == 0 then
                    setPixel(x, y, bgLight)
                else
                    setPixel(x, y, bg)
                end
            end
        end
    end

    -- Corner decorations
    local corner = Color(80, 70, 60)
    -- Top-left
    setPixel(2, 2, corner)
    setPixel(3, 2, corner)
    setPixel(2, 3, corner)
    -- Top-right
    setPixel(44, 2, corner)
    setPixel(45, 2, corner)
    setPixel(45, 3, corner)
    -- Bottom-left
    setPixel(2, 44, corner)
    setPixel(2, 45, corner)
    setPixel(3, 45, corner)
    -- Bottom-right
    setPixel(44, 45, corner)
    setPixel(45, 44, corner)
    setPixel(45, 45, corner)

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_panel.aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_panel.png",
    }
    print("UI Panel created")
end

-- ============== BUTTONS (3 states: normal, hover, pressed) ==============
local function createButtons()
    local sprite = Sprite(96, 24)  -- 3 buttons, 32x24 each
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_button.aseprite"

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

    local function drawButton(baseX, bgColor, borderColor, highlightColor, shadowColor)
        -- Button body
        for y = 2, 21 do
            for x = baseX + 2, baseX + 29 do
                setPixel(x, y, bgColor)
            end
        end

        -- Top highlight
        for x = baseX + 2, baseX + 29 do
            setPixel(x, 2, highlightColor)
            setPixel(x, 3, highlightColor)
        end

        -- Bottom shadow
        for x = baseX + 2, baseX + 29 do
            setPixel(x, 20, shadowColor)
            setPixel(x, 21, shadowColor)
        end

        -- Border
        for x = baseX + 2, baseX + 29 do
            setPixel(x, 0, borderColor)
            setPixel(x, 1, borderColor)
            setPixel(x, 22, borderColor)
            setPixel(x, 23, borderColor)
        end
        for y = 2, 21 do
            setPixel(baseX, y, borderColor)
            setPixel(baseX + 1, y, borderColor)
            setPixel(baseX + 30, y, borderColor)
            setPixel(baseX + 31, y, borderColor)
        end

        -- Rounded corners
        setPixel(baseX, 0, transparent)
        setPixel(baseX + 1, 0, transparent)
        setPixel(baseX, 1, transparent)
        setPixel(baseX + 30, 0, transparent)
        setPixel(baseX + 31, 0, transparent)
        setPixel(baseX + 31, 1, transparent)
        setPixel(baseX, 22, transparent)
        setPixel(baseX, 23, transparent)
        setPixel(baseX + 1, 23, transparent)
        setPixel(baseX + 30, 23, transparent)
        setPixel(baseX + 31, 22, transparent)
        setPixel(baseX + 31, 23, transparent)
    end

    -- Button 1: Normal
    drawButton(0,
        Color(80, 120, 160),   -- bg
        Color(50, 80, 110),    -- border
        Color(100, 150, 200),  -- highlight
        Color(60, 90, 130))    -- shadow

    -- Button 2: Hover
    drawButton(32,
        Color(100, 150, 200),  -- bg (brighter)
        Color(60, 100, 140),   -- border
        Color(130, 180, 230),  -- highlight
        Color(80, 120, 160))   -- shadow

    -- Button 3: Pressed
    drawButton(64,
        Color(60, 90, 130),    -- bg (darker)
        Color(40, 60, 90),     -- border
        Color(50, 80, 110),    -- highlight (inverted - shadow on top)
        Color(80, 120, 160))   -- shadow (inverted - highlight on bottom)

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_button.aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_button.png",
    }
    print("UI Buttons created")
end

-- ============== STATUS ICONS (health, hunger, stamina) ==============
local function createStatusIcons()
    local sprite = Sprite(48, 16)  -- 3 icons, 16x16 each
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_icons.aseprite"

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

    -- Icon 1: Heart (Health) 0-15
    local heartRed = Color(220, 50, 60)
    local heartDark = Color(180, 40, 50)
    local heartLight = Color(255, 100, 110)
    -- Heart shape
    local heartPixels = {
        {5, 4}, {6, 4}, {9, 4}, {10, 4},
        {4, 5}, {5, 5}, {6, 5}, {7, 5}, {8, 5}, {9, 5}, {10, 5}, {11, 5},
        {4, 6}, {5, 6}, {6, 6}, {7, 6}, {8, 6}, {9, 6}, {10, 6}, {11, 6},
        {4, 7}, {5, 7}, {6, 7}, {7, 7}, {8, 7}, {9, 7}, {10, 7}, {11, 7},
        {5, 8}, {6, 8}, {7, 8}, {8, 8}, {9, 8}, {10, 8},
        {6, 9}, {7, 9}, {8, 9}, {9, 9},
        {7, 10}, {8, 10},
        {7, 11}, {8, 11}
    }
    for _, p in ipairs(heartPixels) do
        setPixel(p[1], p[2], heartRed)
    end
    -- Highlight
    setPixel(5, 5, heartLight)
    setPixel(6, 5, heartLight)
    -- Shadow
    setPixel(10, 7, heartDark)
    setPixel(9, 8, heartDark)

    -- Icon 2: Drumstick/Food (Hunger) 16-31
    local meatBrown = Color(180, 100, 70)
    local meatLight = Color(220, 150, 120)
    local bone = Color(240, 235, 220)
    -- Meat part
    for y = 4, 9 do
        for x = 18, 25 do
            if (x - 18) + (y - 4) < 8 then
                setPixel(x, y, meatBrown)
            end
        end
    end
    setPixel(19, 5, meatLight)
    setPixel(20, 5, meatLight)
    -- Bone
    for i = 0, 4 do
        setPixel(25 + i, 9 + i, bone)
    end
    setPixel(28, 12, bone)
    setPixel(29, 12, bone)
    setPixel(28, 13, bone)

    -- Icon 3: Lightning (Stamina) 32-47
    local boltYellow = Color(255, 220, 80)
    local boltOrange = Color(255, 180, 50)
    local boltDark = Color(200, 150, 40)
    -- Lightning bolt shape
    local boltPixels = {
        {41, 2}, {42, 2},
        {40, 3}, {41, 3},
        {39, 4}, {40, 4},
        {38, 5}, {39, 5},
        {37, 6}, {38, 6}, {39, 6}, {40, 6}, {41, 6}, {42, 6},
        {40, 7}, {41, 7},
        {39, 8}, {40, 8},
        {38, 9}, {39, 9},
        {37, 10}, {38, 10},
        {36, 11}, {37, 11},
        {35, 12}, {36, 12}
    }
    for _, p in ipairs(boltPixels) do
        setPixel(p[1], p[2], boltYellow)
    end
    -- Shading
    setPixel(42, 6, boltOrange)
    setPixel(36, 12, boltDark)

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_icons.aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_icons.png",
    }
    print("UI Status Icons created")
end

-- ============== INVENTORY SLOT ==============
local function createInventorySlot()
    local sprite = Sprite(32, 32)  -- Single slot, 32x32
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_inventory_slot.aseprite"

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

    local border = Color(80, 70, 60)
    local borderDark = Color(50, 45, 40)
    local bg = Color(40, 35, 32)
    local bgLight = Color(50, 45, 42)
    local highlight = Color(100, 90, 80)

    -- Background
    for y = 0, 31 do
        for x = 0, 31 do
            setPixel(x, y, bg)
        end
    end

    -- Inner shadow (top-left)
    for x = 2, 29 do
        setPixel(x, 2, bgLight)
    end
    for y = 2, 29 do
        setPixel(2, y, bgLight)
    end

    -- Border
    for x = 0, 31 do
        setPixel(x, 0, border)
        setPixel(x, 1, borderDark)
        setPixel(x, 30, borderDark)
        setPixel(x, 31, border)
    end
    for y = 0, 31 do
        setPixel(0, y, border)
        setPixel(1, y, borderDark)
        setPixel(30, y, borderDark)
        setPixel(31, y, border)
    end

    -- Corner highlight
    setPixel(2, 2, highlight)
    setPixel(3, 2, highlight)
    setPixel(2, 3, highlight)

    -- Rounded corners (cut)
    setPixel(0, 0, transparent)
    setPixel(31, 0, transparent)
    setPixel(0, 31, transparent)
    setPixel(31, 31, transparent)

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_inventory_slot.aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\ui\\ui_inventory_slot.png",
    }
    print("UI Inventory Slot created")
end

-- Create all UI elements
createPanel()
createButtons()
createStatusIcons()
createInventorySlot()

print("All UI elements created successfully!")
