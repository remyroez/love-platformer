
-- エイリアス
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

-- クラス
local Scene = require 'Scene'

-- ゲーム
local Game = Scene:newState 'game'

-- 読み込み
function Game:load()
end

-- ステート開始
function Game:enteredState(width, height, pieceTypes, ...)
    -- 親
    Scene.enteredState(self, ...)
end

-- ステート終了
function Game:exitedState(...)
end

-- 更新
function Game:update(dt)
end

-- 描画
function Game:draw()
end

-- キー入力
function Game:keypressed(key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(x, y, button, istouch, presses)
end

return Game
