-- Player sprite: 16x16, 8 directions x 4 frames
-- Layout: 4 columns x 8 rows = 64x128
-- Row order: down, down_left, left, up_left, up, up_right, right, down_right
local spr = Sprite(64, 128, ColorMode.RGB)
app.activeSprite = spr
local lyr = spr.layers[1]
lyr.name = "Player"

-- Colors
local skin = Color(237, 195, 154)
local hair = Color(60, 40, 30)
local shirt = Color(70, 130, 180)
local shirt_d = Color(55, 105, 150)
local pants = Color(60, 80, 120)
local shoes = Color(80, 50, 30)
local eye = Color(30, 30, 30)
local tr = Color(0, 0, 0, 0)

local function px(img, x, y, c)
    if x >= 0 and x < img.width and y >= 0 and y < img.height then
        img:drawPixel(x, y, c)
    end
end

local function row(img, ox, oy, x1, x2, c)
    for x = x1, x2 do px(img, ox + x, oy, c) end
end

-- ============ DOWN (front) ============
local function draw_down(img, ox, oy, f)
    row(img, ox, oy+0, 5,10, hair)
    row(img, ox, oy+1, 4,11, hair)
    for y=2,4 do row(img, ox, oy+y, 4,11, skin) end
    px(img, ox+6, oy+3, eye); px(img, ox+9, oy+3, eye)
    row(img, ox, oy+5, 5,10, skin)
    for y=6,9 do row(img, ox, oy+y, 5,10, shirt) end
    px(img, ox+4, oy+7, shirt); px(img, ox+11, oy+7, shirt)
    px(img, ox+4, oy+8, skin); px(img, ox+11, oy+8, skin)
    row(img, ox, oy+10, 5,10, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 5,7, shoes); row(img, ox, oy+13, 8,10, shoes)
    elseif f==1 then
        for y=11,12 do row(img, ox, oy+y, 4,6, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 4,6, shoes); row(img, ox, oy+13, 9,10, shoes)
    else
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 9,11, pants) end
        row(img, ox, oy+13, 5,6, shoes); row(img, ox, oy+13, 9,11, shoes)
    end
end

-- ============ UP (back) ============
local function draw_up(img, ox, oy, f)
    row(img, ox, oy+0, 5,10, hair)
    for y=1,4 do row(img, ox, oy+y, 4,11, hair) end
    row(img, ox, oy+5, 6,9, skin)
    for y=6,9 do row(img, ox, oy+y, 5,10, shirt_d) end
    px(img, ox+4, oy+7, shirt_d); px(img, ox+11, oy+7, shirt_d)
    px(img, ox+4, oy+8, skin); px(img, ox+11, oy+8, skin)
    row(img, ox, oy+10, 5,10, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 5,7, shoes); row(img, ox, oy+13, 8,10, shoes)
    elseif f==1 then
        for y=11,12 do row(img, ox, oy+y, 4,6, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 4,6, shoes); row(img, ox, oy+13, 9,10, shoes)
    else
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 9,11, pants) end
        row(img, ox, oy+13, 5,6, shoes); row(img, ox, oy+13, 9,11, shoes)
    end
end

-- ============ LEFT (side) ============
local function draw_left(img, ox, oy, f)
    row(img, ox, oy+0, 5,9, hair)
    row(img, ox, oy+1, 4,10, hair)
    for y=2,4 do
        row(img, ox, oy+y, 5,9, skin)
        px(img, ox+4, oy+y, hair)
    end
    px(img, ox+6, oy+3, eye)
    row(img, ox, oy+5, 5,8, skin)
    for y=6,9 do row(img, ox, oy+y, 5,10, shirt) end
    px(img, ox+4, oy+7, shirt); px(img, ox+4, oy+8, skin)
    row(img, ox, oy+10, 5,10, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 5,9, pants) end
        row(img, ox, oy+13, 5,9, shoes)
    elseif f==1 then
        row(img, ox, oy+11, 4,8, pants); row(img, ox, oy+12, 6,10, pants)
        row(img, ox, oy+13, 4,7, shoes); px(img, ox+10, oy+13, shoes)
    else
        row(img, ox, oy+11, 6,10, pants); row(img, ox, oy+12, 4,8, pants)
        row(img, ox, oy+13, 7,10, shoes); px(img, ox+4, oy+13, shoes)
    end
end

-- ============ RIGHT (side) ============
local function draw_right(img, ox, oy, f)
    row(img, ox, oy+0, 6,10, hair)
    row(img, ox, oy+1, 5,11, hair)
    for y=2,4 do
        row(img, ox, oy+y, 6,10, skin)
        px(img, ox+11, oy+y, hair)
    end
    px(img, ox+9, oy+3, eye)
    row(img, ox, oy+5, 7,10, skin)
    for y=6,9 do row(img, ox, oy+y, 5,10, shirt) end
    px(img, ox+11, oy+7, shirt); px(img, ox+11, oy+8, skin)
    row(img, ox, oy+10, 5,10, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 6,10, pants) end
        row(img, ox, oy+13, 6,10, shoes)
    elseif f==1 then
        row(img, ox, oy+11, 7,11, pants); row(img, ox, oy+12, 5,9, pants)
        row(img, ox, oy+13, 8,11, shoes); px(img, ox+5, oy+13, shoes)
    else
        row(img, ox, oy+11, 5,9, pants); row(img, ox, oy+12, 7,11, pants)
        row(img, ox, oy+13, 5,8, shoes); px(img, ox+11, oy+13, shoes)
    end
end

-- ============ DOWN-LEFT (3/4 front-left) ============
local function draw_down_left(img, ox, oy, f)
    row(img, ox, oy+0, 4,9, hair)
    row(img, ox, oy+1, 3,10, hair)
    for y=2,4 do
        row(img, ox, oy+y, 4,10, skin)
        px(img, ox+3, oy+y, hair)
    end
    px(img, ox+5, oy+3, eye); px(img, ox+8, oy+3, eye)
    row(img, ox, oy+5, 4,9, skin)
    for y=6,9 do row(img, ox, oy+y, 4,10, shirt) end
    px(img, ox+3, oy+7, shirt); px(img, ox+11, oy+7, shirt)
    px(img, ox+3, oy+8, skin); px(img, ox+11, oy+8, skin)
    row(img, ox, oy+10, 4,10, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 4,7, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 4,7, shoes); row(img, ox, oy+13, 8,10, shoes)
    elseif f==1 then
        for y=11,12 do row(img, ox, oy+y, 3,6, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 3,6, shoes); row(img, ox, oy+13, 9,10, shoes)
    else
        for y=11,12 do row(img, ox, oy+y, 4,7, pants); row(img, ox, oy+y, 9,11, pants) end
        row(img, ox, oy+13, 4,6, shoes); row(img, ox, oy+13, 9,11, shoes)
    end
end

-- ============ DOWN-RIGHT (3/4 front-right) ============
local function draw_down_right(img, ox, oy, f)
    row(img, ox, oy+0, 6,11, hair)
    row(img, ox, oy+1, 5,12, hair)
    for y=2,4 do
        row(img, ox, oy+y, 5,11, skin)
        px(img, ox+12, oy+y, hair)
    end
    px(img, ox+7, oy+3, eye); px(img, ox+10, oy+3, eye)
    row(img, ox, oy+5, 6,11, skin)
    for y=6,9 do row(img, ox, oy+y, 5,11, shirt) end
    px(img, ox+4, oy+7, shirt); px(img, ox+12, oy+7, shirt)
    px(img, ox+4, oy+8, skin); px(img, ox+12, oy+8, skin)
    row(img, ox, oy+10, 5,11, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 8,11, pants) end
        row(img, ox, oy+13, 5,7, shoes); row(img, ox, oy+13, 8,11, shoes)
    elseif f==1 then
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 9,12, pants) end
        row(img, ox, oy+13, 5,6, shoes); row(img, ox, oy+13, 9,12, shoes)
    else
        for y=11,12 do row(img, ox, oy+y, 4,7, pants); row(img, ox, oy+y, 8,11, pants) end
        row(img, ox, oy+13, 4,7, shoes); row(img, ox, oy+13, 9,11, shoes)
    end
end

-- ============ UP-LEFT (3/4 back-left) ============
local function draw_up_left(img, ox, oy, f)
    row(img, ox, oy+0, 4,9, hair)
    for y=1,4 do row(img, ox, oy+y, 3,10, hair) end
    row(img, ox, oy+5, 5,8, skin)
    for y=6,9 do row(img, ox, oy+y, 4,10, shirt_d) end
    px(img, ox+3, oy+7, shirt_d); px(img, ox+11, oy+7, shirt_d)
    px(img, ox+3, oy+8, skin); px(img, ox+11, oy+8, skin)
    row(img, ox, oy+10, 4,10, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 4,7, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 4,7, shoes); row(img, ox, oy+13, 8,10, shoes)
    elseif f==1 then
        for y=11,12 do row(img, ox, oy+y, 3,6, pants); row(img, ox, oy+y, 8,10, pants) end
        row(img, ox, oy+13, 3,6, shoes); row(img, ox, oy+13, 9,10, shoes)
    else
        for y=11,12 do row(img, ox, oy+y, 4,7, pants); row(img, ox, oy+y, 9,11, pants) end
        row(img, ox, oy+13, 4,6, shoes); row(img, ox, oy+13, 9,11, shoes)
    end
end

-- ============ UP-RIGHT (3/4 back-right) ============
local function draw_up_right(img, ox, oy, f)
    row(img, ox, oy+0, 6,11, hair)
    for y=1,4 do row(img, ox, oy+y, 5,12, hair) end
    row(img, ox, oy+5, 7,10, skin)
    for y=6,9 do row(img, ox, oy+y, 5,11, shirt_d) end
    px(img, ox+4, oy+7, shirt_d); px(img, ox+12, oy+7, shirt_d)
    px(img, ox+4, oy+8, skin); px(img, ox+12, oy+8, skin)
    row(img, ox, oy+10, 5,11, pants)
    if f==0 or f==2 then
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 8,11, pants) end
        row(img, ox, oy+13, 5,7, shoes); row(img, ox, oy+13, 8,11, shoes)
    elseif f==1 then
        for y=11,12 do row(img, ox, oy+y, 5,7, pants); row(img, ox, oy+y, 9,12, pants) end
        row(img, ox, oy+13, 5,6, shoes); row(img, ox, oy+13, 9,12, shoes)
    else
        for y=11,12 do row(img, ox, oy+y, 4,7, pants); row(img, ox, oy+y, 8,11, pants) end
        row(img, ox, oy+13, 4,7, shoes); row(img, ox, oy+13, 9,11, shoes)
    end
end

-- Keep only 1 frame
while #spr.frames > 1 do
    spr:deleteFrame(spr.frames[#spr.frames])
end

local cel = spr.cels[1]
local image = cel.image

-- Clear
for y = 0, 127 do
    for x = 0, 63 do
        px(image, x, y, tr)
    end
end

-- Row order: down, down_left, left, up_left, up, up_right, right, down_right
local funcs = {draw_down, draw_down_left, draw_left, draw_up_left, draw_up, draw_up_right, draw_right, draw_down_right}
for r = 0, 7 do
    for c = 0, 3 do
        funcs[r + 1](image, c * 16, r * 16, c)
    end
end

spr:saveAs("D:\\codes\\games\\Vessels\\assets\\sprites\\player\\player_walk.aseprite")
