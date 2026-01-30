-- 创建一个简单的像素角色
-- 16x16 像素，带行走动画

local sprite = Sprite(16, 16)
sprite.filename = "player.aseprite"

-- 定义颜色
local skin = Color(255, 206, 180)       -- 肤色
local hair = Color(101, 67, 33)         -- 头发棕色
local shirt = Color(65, 105, 225)       -- 衬衫蓝色
local shirtDark = Color(45, 85, 205)    -- 衬衫阴影
local pants = Color(50, 50, 50)         -- 裤子深灰
local shoes = Color(30, 30, 30)         -- 鞋子黑色
local transparent = Color(0, 0, 0, 0)

-- 清除图像函数
local function clearImage(image)
    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            image:drawPixel(x, y, transparent)
        end
    end
end

-- 绘制角色帧
local function drawCharacter(image, frame)
    clearImage(image)

    -- 头发
    local hairPixels = {
        {6, 2}, {7, 2}, {8, 2}, {9, 2},
        {5, 3}, {6, 3}, {7, 3}, {8, 3}, {9, 3}, {10, 3},
        {5, 4}, {10, 4},
    }
    for _, pos in ipairs(hairPixels) do
        image:drawPixel(pos[1], pos[2], hair)
    end

    -- 脸部
    local facePixels = {
        {6, 4}, {7, 4}, {8, 4}, {9, 4},
        {5, 5}, {6, 5}, {7, 5}, {8, 5}, {9, 5}, {10, 5},
        {6, 6}, {7, 6}, {8, 6}, {9, 6},
    }
    for _, pos in ipairs(facePixels) do
        image:drawPixel(pos[1], pos[2], skin)
    end

    -- 眼睛
    image:drawPixel(7, 5, Color(0, 0, 0))
    image:drawPixel(9, 5, Color(0, 0, 0))

    -- 身体
    local bodyPixels = {
        {6, 7}, {7, 7}, {8, 7}, {9, 7},
        {5, 8}, {6, 8}, {7, 8}, {8, 8}, {9, 8}, {10, 8},
        {5, 9}, {6, 9}, {7, 9}, {8, 9}, {9, 9}, {10, 9},
        {6, 10}, {7, 10}, {8, 10}, {9, 10},
    }
    for _, pos in ipairs(bodyPixels) do
        image:drawPixel(pos[1], pos[2], shirt)
    end

    -- 身体阴影
    local bodyShadowPixels = {
        {5, 8}, {5, 9},
        {6, 10},
    }
    for _, pos in ipairs(bodyShadowPixels) do
        image:drawPixel(pos[1], pos[2], shirtDark)
    end

    -- 手臂 (根据帧变化)
    if frame == 1 then
        -- 静止/行走帧1
        image:drawPixel(4, 8, skin)
        image:drawPixel(4, 9, skin)
        image:drawPixel(11, 8, skin)
        image:drawPixel(11, 9, skin)
    elseif frame == 2 then
        -- 行走帧2 - 手臂向前
        image:drawPixel(4, 7, skin)
        image:drawPixel(4, 8, skin)
        image:drawPixel(11, 9, skin)
        image:drawPixel(11, 10, skin)
    elseif frame == 3 then
        -- 行走帧3 - 手臂向后
        image:drawPixel(4, 9, skin)
        image:drawPixel(4, 10, skin)
        image:drawPixel(11, 7, skin)
        image:drawPixel(11, 8, skin)
    end

    -- 裤子
    local pantsPixels = {
        {6, 11}, {7, 11}, {8, 11}, {9, 11},
    }
    for _, pos in ipairs(pantsPixels) do
        image:drawPixel(pos[1], pos[2], pants)
    end

    -- 腿 (根据帧变化)
    if frame == 1 then
        -- 静止
        image:drawPixel(6, 12, pants)
        image:drawPixel(7, 12, pants)
        image:drawPixel(8, 12, pants)
        image:drawPixel(9, 12, pants)
        image:drawPixel(6, 13, shoes)
        image:drawPixel(7, 13, shoes)
        image:drawPixel(8, 13, shoes)
        image:drawPixel(9, 13, shoes)
    elseif frame == 2 then
        -- 行走帧2
        image:drawPixel(5, 12, pants)
        image:drawPixel(6, 12, pants)
        image:drawPixel(9, 12, pants)
        image:drawPixel(10, 12, pants)
        image:drawPixel(5, 13, shoes)
        image:drawPixel(6, 13, shoes)
        image:drawPixel(9, 13, shoes)
        image:drawPixel(10, 13, shoes)
    elseif frame == 3 then
        -- 行走帧3
        image:drawPixel(6, 12, pants)
        image:drawPixel(7, 12, pants)
        image:drawPixel(8, 12, pants)
        image:drawPixel(9, 12, pants)
        image:drawPixel(6, 13, shoes)
        image:drawPixel(7, 13, shoes)
        image:drawPixel(8, 13, shoes)
        image:drawPixel(9, 13, shoes)
    elseif frame == 4 then
        -- 行走帧4
        image:drawPixel(6, 12, pants)
        image:drawPixel(7, 12, pants)
        image:drawPixel(9, 12, pants)
        image:drawPixel(10, 12, pants)
        image:drawPixel(6, 13, shoes)
        image:drawPixel(7, 13, shoes)
        image:drawPixel(9, 13, shoes)
        image:drawPixel(10, 13, shoes)
    end
end

-- 获取活动图层
local layer = sprite.layers[1]
layer.name = "Character"

-- 创建4帧动画
local frameData = {1, 2, 1, 3}  -- idle, walk1, idle, walk2
local frameDurations = {200, 100, 200, 100}

-- 绘制第一帧
local cel1 = sprite.cels[1]
drawCharacter(cel1.image, frameData[1])
sprite.frames[1].duration = frameDurations[1] / 1000

-- 创建后续帧
for i = 2, #frameData do
    sprite:newEmptyFrame(i)
    sprite.frames[i].duration = frameDurations[i] / 1000
    local cel = sprite:newCel(layer, i)
    drawCharacter(cel.image, frameData[i])
end

-- 创建动画标签
local idleTag = sprite:newTag(1, 1)
idleTag.name = "idle"

local walkTag = sprite:newTag(1, 4)
walkTag.name = "walk"
walkTag.aniDir = AniDir.FORWARD

-- 保存文件
local outputPath = "D:/codes/games/Vessels/assets/sprites/player.aseprite"
sprite:saveAs(outputPath)

print("Player sprite created with 4 frames!")
print("Saved to: " .. outputPath)
