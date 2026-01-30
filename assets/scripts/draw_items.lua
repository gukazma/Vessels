-- Item Icons (16x16 each)
-- Food, Weapons, Materials, Tools, Medical

local transparent = Color(0, 0, 0, 0)

-- Helper to create sprites
local function createItemSheet(name, drawFunc, count)
    local sprite = Sprite(count * 16, 16)
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\items\\" .. name .. ".aseprite"

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

    drawFunc(setPixel)

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\items\\" .. name .. ".aseprite")
    app.command.ExportSpriteSheet {
        ui = false, askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\items\\" .. name .. ".png",
    }
    print("Items created: " .. name)
end

-- ============== FOOD ITEMS ==============
createItemSheet("items_food", function(setPixel)
    -- Item 1: Bread (0-15)
    local breadCrust = Color(180, 130, 70)
    local breadInner = Color(230, 200, 140)
    for y = 6, 12 do
        for x = 2, 13 do
            local distTop = math.abs(y - 6)
            if distTop <= 2 then
                setPixel(x, y, breadCrust)
            else
                setPixel(x, y, breadInner)
            end
        end
    end
    -- Rounded top
    for x = 4, 11 do
        setPixel(x, 5, breadCrust)
    end
    for x = 6, 9 do
        setPixel(x, 4, breadCrust)
    end

    -- Item 2: Can (16-31)
    local canMetal = Color(180, 180, 190)
    local canDark = Color(140, 140, 150)
    local canLabel = Color(200, 80, 80)
    for y = 3, 12 do
        for x = 20, 27 do
            if y <= 4 or y >= 11 then
                setPixel(x, y, canDark)
            elseif y >= 6 and y <= 9 then
                setPixel(x, y, canLabel)
            else
                setPixel(x, y, canMetal)
            end
        end
    end
    -- Top rim
    for x = 21, 26 do
        setPixel(x, 2, canDark)
    end

    -- Item 3: Energy Bar (32-47)
    local wrapper = Color(50, 130, 200)
    local wrapperLight = Color(80, 160, 230)
    for y = 5, 10 do
        for x = 34, 45 do
            if y == 5 or y == 10 then
                setPixel(x, y, wrapperLight)
            else
                setPixel(x, y, wrapper)
            end
        end
    end
    -- Stripe
    for y = 6, 9 do
        setPixel(39, y, Color(255, 220, 50))
        setPixel(40, y, Color(255, 220, 50))
    end
end, 3)

-- ============== WEAPONS ==============
createItemSheet("items_weapons", function(setPixel)
    -- Item 1: Baseball Bat (0-15)
    local wood = Color(160, 120, 80)
    local woodDark = Color(130, 95, 65)
    for i = 0, 11 do
        setPixel(2 + i, 13 - i, wood)
        setPixel(3 + i, 13 - i, wood)
        if i < 4 then
            setPixel(4 + i, 13 - i, wood)  -- Thicker handle end
        end
    end
    -- Grip
    for i = 0, 2 do
        setPixel(2 + i, 13 - i, woodDark)
    end

    -- Item 2: Kitchen Knife (16-31)
    local blade = Color(200, 200, 210)
    local bladeDark = Color(170, 170, 180)
    local handle = Color(80, 50, 30)
    -- Blade
    for i = 0, 8 do
        setPixel(17 + i, 12 - i, blade)
        setPixel(18 + i, 12 - i, bladeDark)
    end
    -- Handle
    for i = 0, 3 do
        setPixel(26 + i, 4 - i + 6, handle)
        setPixel(27 + i, 4 - i + 6, handle)
    end

    -- Item 3: Axe (32-47)
    local axeHead = Color(160, 160, 170)
    local axeEdge = Color(200, 200, 210)
    local axeHandle = Color(140, 100, 60)
    -- Handle
    for i = 0, 10 do
        setPixel(34 + i, 13 - i, axeHandle)
    end
    -- Head
    for y = 2, 7 do
        for x = 42, 46 do
            if x == 46 then
                setPixel(x, y, axeEdge)
            else
                setPixel(x, y, axeHead)
            end
        end
    end

    -- Item 4: Pistol (48-63)
    local gunMetal = Color(60, 60, 70)
    local gunDark = Color(40, 40, 50)
    local gunGrip = Color(80, 60, 45)
    -- Barrel
    for x = 50, 60 do
        setPixel(x, 6, gunMetal)
        setPixel(x, 7, gunDark)
    end
    -- Body
    for y = 8, 9 do
        for x = 52, 58 do
            setPixel(x, y, gunMetal)
        end
    end
    -- Grip
    for y = 10, 13 do
        setPixel(53, y, gunGrip)
        setPixel(54, y, gunGrip)
        setPixel(55, y, gunGrip)
    end
    -- Trigger guard
    setPixel(56, 10, gunDark)
    setPixel(57, 10, gunDark)
    setPixel(57, 11, gunDark)
end, 4)

-- ============== MATERIALS ==============
createItemSheet("items_materials", function(setPixel)
    -- Item 1: Wood Planks (0-15)
    local wood1 = Color(180, 140, 90)
    local wood2 = Color(160, 120, 75)
    for y = 3, 5 do
        for x = 2, 13 do setPixel(x, y, wood1) end
    end
    for y = 6, 8 do
        for x = 2, 13 do setPixel(x, y, wood2) end
    end
    for y = 9, 11 do
        for x = 2, 13 do setPixel(x, y, wood1) end
    end

    -- Item 2: Metal Scrap (16-31)
    local metal1 = Color(150, 150, 160)
    local metal2 = Color(130, 130, 140)
    local rust = Color(140, 80, 60)
    -- Irregular shapes
    for y = 4, 11 do
        for x = 18, 29 do
            if (x + y) % 3 == 0 then
                setPixel(x, y, metal1)
            elseif (x * y) % 7 == 0 then
                setPixel(x, y, rust)
            else
                setPixel(x, y, metal2)
            end
        end
    end

    -- Item 3: Cloth/Fabric (32-47)
    local cloth1 = Color(200, 180, 160)
    local cloth2 = Color(180, 160, 140)
    for y = 3, 12 do
        for x = 34, 45 do
            if (x + y) % 2 == 0 then
                setPixel(x, y, cloth1)
            else
                setPixel(x, y, cloth2)
            end
        end
    end
    -- Frayed edge
    setPixel(45, 4, cloth1)
    setPixel(46, 6, cloth2)
    setPixel(45, 8, cloth1)
end, 3)

-- ============== TOOLS ==============
createItemSheet("items_tools", function(setPixel)
    -- Item 1: Flashlight (0-15)
    local body = Color(60, 60, 70)
    local lens = Color(220, 220, 180)
    local button = Color(200, 50, 50)
    -- Body
    for y = 5, 10 do
        for x = 3, 10 do
            setPixel(x, y, body)
        end
    end
    -- Lens
    for y = 6, 9 do
        setPixel(11, y, lens)
        setPixel(12, y, lens)
    end
    -- Button
    setPixel(6, 5, button)

    -- Item 2: Lockpick (16-31)
    local pick = Color(180, 180, 190)
    local handle = Color(50, 50, 60)
    -- Handle
    for y = 10, 13 do
        for x = 18, 21 do
            setPixel(x, y, handle)
        end
    end
    -- Pick
    for x = 19, 28 do
        setPixel(x, 7, pick)
    end
    setPixel(28, 8, pick)
    setPixel(28, 9, pick)

    -- Item 3: Toolbox (32-47)
    local boxRed = Color(180, 50, 50)
    local boxDark = Color(140, 40, 40)
    local boxHandle = Color(60, 60, 70)
    for y = 5, 12 do
        for x = 34, 45 do
            if y == 5 or y == 12 or x == 34 or x == 45 then
                setPixel(x, y, boxDark)
            else
                setPixel(x, y, boxRed)
            end
        end
    end
    -- Handle
    for x = 37, 42 do
        setPixel(x, 4, boxHandle)
    end
    setPixel(37, 5, boxHandle)
    setPixel(42, 5, boxHandle)
    -- Latch
    setPixel(39, 8, boxHandle)
    setPixel(40, 8, boxHandle)
end, 3)

-- ============== MEDICAL ==============
createItemSheet("items_medical", function(setPixel)
    -- Item 1: Bandage Roll (0-15)
    local bandage = Color(240, 235, 220)
    local bandageDark = Color(220, 215, 200)
    for y = 4, 11 do
        for x = 4, 11 do
            if (x + y) % 2 == 0 then
                setPixel(x, y, bandage)
            else
                setPixel(x, y, bandageDark)
            end
        end
    end
    -- Unrolled end
    for x = 11, 13 do
        setPixel(x, 7, bandage)
        setPixel(x, 8, bandageDark)
    end

    -- Item 2: Pills (16-31)
    local pillWhite = Color(240, 240, 245)
    local pillRed = Color(200, 80, 80)
    local bottle = Color(200, 150, 100)
    -- Bottle
    for y = 5, 12 do
        for x = 20, 27 do
            setPixel(x, y, bottle)
        end
    end
    -- Cap
    for x = 21, 26 do
        setPixel(x, 4, Color(240, 240, 240))
        setPixel(x, 5, Color(240, 240, 240))
    end
    -- Pills showing
    setPixel(22, 7, pillWhite)
    setPixel(24, 8, pillRed)
    setPixel(25, 7, pillWhite)

    -- Item 3: First Aid Kit (32-47)
    local kitWhite = Color(240, 240, 245)
    local kitRed = Color(200, 50, 50)
    local kitDark = Color(200, 200, 205)
    for y = 4, 11 do
        for x = 34, 45 do
            if y == 4 or y == 11 or x == 34 or x == 45 then
                setPixel(x, y, kitDark)
            else
                setPixel(x, y, kitWhite)
            end
        end
    end
    -- Red cross
    for y = 6, 9 do
        setPixel(39, y, kitRed)
        setPixel(40, y, kitRed)
    end
    for x = 37, 42 do
        setPixel(x, 7, kitRed)
        setPixel(x, 8, kitRed)
    end
    -- Handle
    for x = 38, 41 do
        setPixel(x, 3, Color(60, 60, 70))
    end
end, 3)

print("All item icons created successfully!")
