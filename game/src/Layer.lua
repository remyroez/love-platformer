
local class = require 'middleclass'

-- レイヤー
local Layer = class 'Layer'

-- エイリアス
local lg = love.graphics

-- 初期化
function Layer:initialize(path, width, height, h_wrap, v_wrap)
    -- 画像読み込み
    self.image = lg.newImage(path)

    -- ラップモード
    self.image:setWrap(h_wrap or 'repeat', v_wrap or 'repeat')

    -- 矩形
    local w, h = self.image:getDimensions()
    self.quad = lg.newQuad(0, 0, width or w, height or h, w, h)

    local x, y, qw, qh = self.quad:getViewport()
    self.width, self.height = qw, qh
end

-- 破棄
function Layer:destroy()
    self.quad:release()
    self.quad = nil

    self.image:release()
    self.image = nil
end

-- 更新
function Layer:update(dt)
end

-- 描画
function Layer:draw(...)
    lg.draw(self.image, self.quad, ...)
end

return Layer
