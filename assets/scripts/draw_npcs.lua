-- NPC Sprites (16x16 each)
-- 5 NPCs: Li Qiang (soldier), Chen Yuqing (nurse), Wang Chef, Xiaoxue (student), Old Zhou (engineer)

local transparent = Color(0, 0, 0, 0)
local outline = Color(30, 30, 30)
local skin = Color(255, 213, 170)
local skinDark = Color(220, 180, 140)
local eyes = Color(40, 40, 40)

-- NPC specific colors
local npcs = {
    {
        name = "li_qiang",
        -- Soldier in camouflage
        hair = Color(30, 25, 20),          -- Military cut
        clothes1 = Color(85, 100, 70),      -- Camo green
        clothes2 = Color(100, 90, 60),      -- Camo brown
        accent = Color(60, 70, 50),         -- Dark camo
        hat = Color(85, 100, 70)            -- Military cap
    },
    {
        name = "chen_yuqing",
        -- Nurse in white
        hair = Color(50, 35, 25),           -- Brown hair
        clothes1 = Color(240, 240, 245),    -- White uniform
        clothes2 = Color(220, 220, 230),    -- Light gray
        accent = Color(200, 50, 50),        -- Red cross
        hat = Color(240, 240, 245)          -- Nurse cap
    },
    {
        name = "wang_chef",
        -- Chef with white hat
        hair = Color(40, 35, 30),           -- Dark hair
        clothes1 = Color(240, 240, 240),    -- White coat
        clothes2 = Color(30, 30, 30),       -- Black pants
        accent = Color(200, 200, 200),      -- Apron
        hat = Color(255, 255, 255)          -- Chef hat
    },
    {
        name = "xiaoxue",
        -- Student in school uniform
        hair = Color(30, 25, 20),           -- Black hair (pigtails)
        clothes1 = Color(50, 80, 140),      -- Navy blazer
        clothes2 = Color(200, 200, 200),    -- White shirt
        accent = Color(180, 50, 50),        -- Red ribbon
        hat = nil
    },
    {
        name = "old_zhou",
        -- Engineer in work clothes
        hair = Color(150, 150, 150),        -- Gray hair
        clothes1 = Color(70, 100, 140),     -- Blue coveralls
        clothes2 = Color(50, 80, 120),      -- Darker blue
        accent = Color(200, 150, 50),       -- Yellow safety
        hat = Color(200, 150, 50)           -- Hard hat
    }
}

local function createNPCSprite(npc, index)
    local sprite = Sprite(64, 16)  -- 4 frames for idle/walk
    sprite.filename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\npcs\\" .. npc.name .. ".aseprite"

    local img = sprite.cels[1].image

    -- Clear sprite
    for y = 0, img.height - 1 do
        for x = 0, img.width - 1 do
            img:drawPixel(x, y, transparent)
        end
    end

    local function setPixel(x, y, color)
        if x >= 0 and x < img.width and y >= 0 and y < img.height and color then
            img:drawPixel(x, y, color)
        end
    end

    -- Draw NPC for each of 4 frames (idle animation, slight movement)
    for frame = 0, 3 do
        local baseX = frame * 16
        local breathe = 0
        if frame == 1 or frame == 3 then
            breathe = -1
        end

        -- Hat (if applicable)
        if npc.hat then
            if npc.name == "wang_chef" then
                -- Tall chef hat
                for y = 0, 2 do
                    for x = 6, 9 do
                        setPixel(baseX + x, y, npc.hat)
                    end
                end
            elseif npc.name == "old_zhou" then
                -- Hard hat
                for x = 5, 10 do
                    setPixel(baseX + x, 1, npc.hat)
                    setPixel(baseX + x, 2, npc.hat)
                end
            elseif npc.name == "chen_yuqing" then
                -- Nurse cap
                for x = 6, 9 do
                    setPixel(baseX + x, 1, npc.hat)
                end
            elseif npc.name == "li_qiang" then
                -- Military cap
                for x = 5, 10 do
                    setPixel(baseX + x, 2, npc.hat)
                end
            end
        end

        -- Head
        local headY = 2
        if npc.hat then headY = 3 end
        for y = headY, headY + 3 do
            for x = 6, 9 do
                setPixel(baseX + x, y + breathe, skin)
            end
        end

        -- Hair
        if npc.name == "xiaoxue" then
            -- Pigtails
            setPixel(baseX + 5, headY + breathe, npc.hair)
            setPixel(baseX + 5, headY + 1 + breathe, npc.hair)
            setPixel(baseX + 10, headY + breathe, npc.hair)
            setPixel(baseX + 10, headY + 1 + breathe, npc.hair)
            for x = 6, 9 do
                setPixel(baseX + x, headY + breathe, npc.hair)
            end
        elseif npc.name == "old_zhou" then
            -- Balding gray hair
            setPixel(baseX + 6, headY + breathe, npc.hair)
            setPixel(baseX + 9, headY + breathe, npc.hair)
        else
            -- Normal hair
            for x = 6, 9 do
                setPixel(baseX + x, headY + breathe, npc.hair)
            end
        end

        -- Eyes
        setPixel(baseX + 7, headY + 2 + breathe, eyes)
        setPixel(baseX + 8, headY + 2 + breathe, eyes)

        -- Body
        local bodyY = headY + 4
        for y = bodyY, bodyY + 3 do
            for x = 5, 10 do
                if y == bodyY then
                    setPixel(baseX + x, y + breathe, npc.clothes2)  -- Collar/upper
                else
                    setPixel(baseX + x, y + breathe, npc.clothes1)
                end
            end
        end

        -- Accent details
        if npc.name == "chen_yuqing" then
            -- Red cross
            setPixel(baseX + 7, bodyY + 1 + breathe, npc.accent)
            setPixel(baseX + 8, bodyY + 1 + breathe, npc.accent)
            setPixel(baseX + 7, bodyY + 2 + breathe, npc.accent)
            setPixel(baseX + 8, bodyY + 2 + breathe, npc.accent)
        elseif npc.name == "xiaoxue" then
            -- Red ribbon
            setPixel(baseX + 7, bodyY + breathe, npc.accent)
            setPixel(baseX + 8, bodyY + breathe, npc.accent)
        elseif npc.name == "old_zhou" then
            -- Safety stripes
            setPixel(baseX + 5, bodyY + 2 + breathe, npc.accent)
            setPixel(baseX + 10, bodyY + 2 + breathe, npc.accent)
        end

        -- Arms
        setPixel(baseX + 4, bodyY + 1 + breathe, skin)
        setPixel(baseX + 11, bodyY + 1 + breathe, skin)

        -- Legs
        local legY = bodyY + 4
        setPixel(baseX + 6, legY, npc.clothes2)
        setPixel(baseX + 6, legY + 1, npc.clothes2)
        setPixel(baseX + 6, legY + 2, skin)
        setPixel(baseX + 9, legY, npc.clothes2)
        setPixel(baseX + 9, legY + 1, npc.clothes2)
        setPixel(baseX + 9, legY + 2, skin)
    end

    sprite:saveAs("d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\npcs\\" .. npc.name .. ".aseprite")

    -- Export sprite sheet
    app.command.ExportSpriteSheet {
        ui = false,
        askOverwrite = false,
        type = SpriteSheetType.HORIZONTAL,
        textureFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\npcs\\" .. npc.name .. ".png",
        dataFilename = "d:\\codes\\games\\Vessels\\.worktrees\\art\\assets\\sprites\\npcs\\" .. npc.name .. ".json",
        dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
        layer = "",
        tag = "",
        splitLayers = false,
        listLayers = true,
        listTags = true,
        listSlices = true
    }

    print("NPC sprite created: " .. npc.name)
end

-- Create all NPC sprites
for i, npc in ipairs(npcs) do
    createNPCSprite(npc, i)
end

print("All NPC sprites created successfully!")
