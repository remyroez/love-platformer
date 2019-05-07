
-- エイリアス
local lg = love.graphics

-- トランスフォームモジュール
local Transform = {}

-- 角度
local function angle(x1, y1, x2, y2)
  return math_atan2(y2 - y1, x2 - x1)
end

-- ベクトル
local function vector(angle, magnitude)
    return math.cos(angle) * magnitude, math.sin(angle) * magnitude
  end

-- 初期化
function Transform:initializeTransform(x, y, rotation, scaleX, scaleY, pivotX, pivotY)
    self.x = x or self.x or 0
    self.y = y or self.y or 0
    self.rotation = rotation or self.rotation or 0
    self.scaleX = scaleX or self.scaleX or 1
    if scaleX ~= nil and scaleY == nil then
        scaleY = scaleX
    end
    self.scaleY = scaleY or self.scaleY or 1
    self:setPivot(pivotX, pivotY)

    -- プライベート
    self._transform = {}
end

-- ピボット
function Transform:setPivot(pivotX, pivotY)
    self.pivotX = pivotX or self.pivotX or 0
    self.pivotY = pivotY or self.pivotY or 0
end

-- 座標
function Transform:getPosition()
    return self.x, self.y
end

-- 移動
function Transform:move(x, y)
    self.x = self.x + x
    self.y = self.y + y
end

-- 回転
function Transform:rotate(rotation)
    rotation = rotation or 0
    self.rotation = self.rotation + rotation
    while self.rotation > (math.pi * 2) do
        self.rotation = self.rotation - (math.pi * 2)
    end
end

-- 座標の方向へ回転する
function Transform:setRotationTo(x, y)
    self.rotation = angle(self.x, self.y, x, y)
end

-- 前方へのベクトルを返す
function Transform:forward(magnitude)
    return vector(self.rotation, magnitude or 1)
end

-- 前方へ移動する
function Transform:moveForward(magnitude)
    return self:move(self:forward(magnitude))
end

-- トランスフォームを積む
function Transform:pushTransform(x, y)
    x = x or self.x
    y = y or self.y

    lg.push()
    lg.translate(x, y)
    lg.translate(self.pivotX, self.pivotY)
    lg.rotate(self.rotation)
    lg.scale(self.scaleX, self.scaleY)
    lg.translate(-self.pivotX, -self.pivotY)
end

-- トランスフォームを除く
function Transform:popTransform()
    lg.pop()
end

return Transform
