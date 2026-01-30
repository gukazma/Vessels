-- 创建一棵带摆动动画的像素树
-- 画布大小 32x32，4帧动画

local sprite = Sprite(32, 32)
sprite.filename = "tree_animated.aseprite"

-- 定义颜色
local brown = Color(101, 67, 33)      -- 树干棕色
local darkBrown = Color(71, 47, 23)   -- 深棕色阴影
local green = Color(34, 139, 34)      -- 叶子绿色
local darkGreen = Color(0, 100, 0)    -- 深绿色阴影
local lightGreen = Color(50, 205, 50) -- 浅绿色高光
local transparent = Color(0, 0, 0, 0)

-- 绘制树干函数 (树干保持不动)
local function drawTrunk(image)
    local trunkPixels = {
        {14, 28}, {15, 28}, {16, 28}, {17, 28},
        {14, 27}, {15, 27}, {16, 27}, {17, 27},
        {14, 26}, {15, 26}, {16, 26}, {17, 26},
        {15, 25}, {16, 25},
        {15, 24}, {16, 24},
        {15, 23}, {16, 23},
        {15, 22}, {16, 22},
        {15, 21}, {16, 21},
    }

    for _, pos in ipairs(trunkPixels) do
        image:drawPixel(pos[1], pos[2], brown)
    end

    -- 树干阴影
    local trunkShadowPixels = {
        {14, 28}, {14, 27}, {14, 26},
        {15, 25}, {15, 24}, {15, 23}, {15, 22}, {15, 21},
    }

    for _, pos in ipairs(trunkShadowPixels) do
        image:drawPixel(pos[1], pos[2], darkBrown)
    end
end

-- 绘制树冠函数 (带偏移量用于动画)
local function drawCanopy(image, offsetX)
    -- 深绿色底层
    local darkLeafBase = {
        {12, 20}, {13, 20}, {14, 20}, {15, 20}, {16, 20}, {17, 20}, {18, 20}, {19, 20},
        {10, 19}, {11, 19}, {12, 19}, {13, 19}, {14, 19}, {15, 19}, {16, 19}, {17, 19}, {18, 19}, {19, 19}, {20, 19}, {21, 19},
        {9, 18}, {10, 18}, {11, 18}, {12, 18}, {13, 18}, {14, 18}, {15, 18}, {16, 18}, {17, 18}, {18, 18}, {19, 18}, {20, 18}, {21, 18}, {22, 18},
        {8, 17}, {9, 17}, {10, 17}, {11, 17}, {12, 17}, {13, 17}, {14, 17}, {15, 17}, {16, 17}, {17, 17}, {18, 17}, {19, 17}, {20, 17}, {21, 17}, {22, 17}, {23, 17},
        {8, 16}, {9, 16}, {10, 16}, {11, 16}, {12, 16}, {13, 16}, {14, 16}, {15, 16}, {16, 16}, {17, 16}, {18, 16}, {19, 16}, {20, 16}, {21, 16}, {22, 16}, {23, 16},
        {9, 15}, {10, 15}, {11, 15}, {12, 15}, {13, 15}, {14, 15}, {15, 15}, {16, 15}, {17, 15}, {18, 15}, {19, 15}, {20, 15}, {21, 15}, {22, 15},
        {10, 14}, {11, 14}, {12, 14}, {13, 14}, {14, 14}, {15, 14}, {16, 14}, {17, 14}, {18, 14}, {19, 14}, {20, 14}, {21, 14},
        {11, 13}, {12, 13}, {13, 13}, {14, 13}, {15, 13}, {16, 13}, {17, 13}, {18, 13}, {19, 13}, {20, 13},
        {12, 12}, {13, 12}, {14, 12}, {15, 12}, {16, 12}, {17, 12}, {18, 12}, {19, 12},
        {13, 11}, {14, 11}, {15, 11}, {16, 11}, {17, 11}, {18, 11},
        {14, 10}, {15, 10}, {16, 10}, {17, 10},
        {15, 9}, {16, 9},
    }

    -- 根据Y坐标计算不同的偏移 (顶部摆动更大)
    for _, pos in ipairs(darkLeafBase) do
        local yFactor = (20 - pos[2]) / 11  -- 越高摆动越大
        local actualOffset = math.floor(offsetX * yFactor + 0.5)
        local newX = pos[1] + actualOffset
        if newX >= 0 and newX < 32 then
            image:drawPixel(newX, pos[2], darkGreen)
        end
    end

    -- 中绿色主体
    local greenLeafBase = {
        {13, 19}, {14, 19}, {15, 19}, {16, 19}, {17, 19}, {18, 19},
        {11, 18}, {12, 18}, {13, 18}, {14, 18}, {15, 18}, {16, 18}, {17, 18}, {18, 18}, {19, 18}, {20, 18},
        {10, 17}, {11, 17}, {12, 17}, {13, 17}, {14, 17}, {15, 17}, {16, 17}, {17, 17}, {18, 17}, {19, 17}, {20, 17}, {21, 17},
        {10, 16}, {11, 16}, {12, 16}, {13, 16}, {14, 16}, {15, 16}, {16, 16}, {17, 16}, {18, 16}, {19, 16}, {20, 16}, {21, 16},
        {11, 15}, {12, 15}, {13, 15}, {14, 15}, {15, 15}, {16, 15}, {17, 15}, {18, 15}, {19, 15}, {20, 15},
        {12, 14}, {13, 14}, {14, 14}, {15, 14}, {16, 14}, {17, 14}, {18, 14}, {19, 14},
        {13, 13}, {14, 13}, {15, 13}, {16, 13}, {17, 13}, {18, 13},
        {14, 12}, {15, 12}, {16, 12}, {17, 12},
        {15, 11}, {16, 11},
    }

    for _, pos in ipairs(greenLeafBase) do
        local yFactor = (20 - pos[2]) / 11
        local actualOffset = math.floor(offsetX * yFactor + 0.5)
        local newX = pos[1] + actualOffset
        if newX >= 0 and newX < 32 then
            image:drawPixel(newX, pos[2], green)
        end
    end

    -- 浅绿色高光
    local lightLeafBase = {
        {14, 18}, {15, 18}, {16, 18}, {17, 18},
        {12, 17}, {13, 17}, {14, 17}, {15, 17}, {16, 17}, {17, 17}, {18, 17}, {19, 17},
        {12, 16}, {13, 16}, {14, 16}, {15, 16}, {16, 16}, {17, 16}, {18, 16}, {19, 16},
        {13, 15}, {14, 15}, {15, 15}, {16, 15}, {17, 15}, {18, 15},
        {14, 14}, {15, 14}, {16, 14}, {17, 14},
        {15, 13}, {16, 13},
    }

    for _, pos in ipairs(lightLeafBase) do
        local yFactor = (20 - pos[2]) / 11
        local actualOffset = math.floor(offsetX * yFactor + 0.5)
        local newX = pos[1] + actualOffset
        if newX >= 0 and newX < 32 then
            image:drawPixel(newX, pos[2], lightGreen)
        end
    end
end

-- 清除图像函数
local function clearImage(image)
    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            image:drawPixel(x, y, transparent)
        end
    end
end

-- 动画帧偏移量 (摆动效果: 中间 -> 右 -> 中间 -> 左)
local frameOffsets = {0, 1, 0, -1}
local frameDurations = {150, 150, 150, 150}  -- 每帧持续时间(毫秒)

-- 创建第一帧
local layer = sprite.layers[1]
layer.name = "Tree"

-- 绘制第一帧
local cel1 = sprite.cels[1]
local image1 = cel1.image
clearImage(image1)
drawTrunk(image1)
drawCanopy(image1, frameOffsets[1])
sprite.frames[1].duration = frameDurations[1] / 1000

-- 创建后续帧
for i = 2, #frameOffsets do
    -- 添加新帧
    sprite:newEmptyFrame(i)
    sprite.frames[i].duration = frameDurations[i] / 1000

    -- 获取或创建cel
    local cel = sprite:newCel(layer, i)
    local image = cel.image

    clearImage(image)
    drawTrunk(image)
    drawCanopy(image, frameOffsets[i])
end

-- 创建动画标签
local tag = sprite:newTag(1, #frameOffsets)
tag.name = "sway"
tag.aniDir = AniDir.PING_PONG

-- 保存文件
local outputPath = "D:/codes/games/Vessels/assets/sprites/tree_animated.aseprite"
sprite:saveAs(outputPath)

print("Animated tree sprite created with " .. #frameOffsets .. " frames!")
print("Saved to: " .. outputPath)
