
local class = require 'middleclass'

-- 背景
local Background = class 'Background'

-- エイリアス
local lg = love.graphics

-- クラス
local Layer = require 'Layer'

-- 初期化
function Background:initialize(set, width, height)
    -- セット番号
    self.set = set or 1

    -- サイズ
    self.width, self.height = width or 800, height or 600

    -- 背景
    self.bg = Layer('assets/set' .. self.set .. '_background.png', self.width, self.height, 'repeat', 'repeat')

    -- 山
    self.hills = Layer('assets/set' .. self.set .. '_hills.png', self.width, self.height * 0.75, 'repeat', 'clamp')

    -- タイル
    self.tiles = Layer('assets/set' .. self.set .. '_tiles.png', self.width, nil, 'repeat', 'clampzero')
end

-- 破棄
function Background:destroy()
    -- 背景
    self.bg:destroy()
    self.bg = nil

    -- 山
    self.hills:destroy()
    self.hills = nil

    -- タイル
    self.tiles:destroy()
    self.tiles = nil
end

-- 更新
function Background:update(dt)
end

-- 描画
function Background:draw()
    self.bg:draw()
    self.tiles:draw(0, self.height * 0.25)
    self.hills:draw(0, self.height * 0.25)
end

return Background
