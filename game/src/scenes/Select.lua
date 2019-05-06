
local Scene = require 'Scene'

-- エイリアス
local lg = love.graphics

-- レベル選択
local Select = Scene:newState 'select'

-- 次のステートへ
function Select:nextState(...)
    self:gotoState('game', ...)
end

-- 読み込み
function Select:load()
end

-- ステート開始
function Select:enteredState(width, height, pieceTypes, ...)
    -- 親
    Scene.enteredState(self, ...)
end

-- ステート終了
function Select:exitedState(...)
end

-- 更新
function Select:update(dt)
end

-- 描画
function Select:draw()
end

-- キー入力
function Select:keypressed(key, scancode, isrepeat)
    self:nextState()
end

-- マウス入力
function Select:mousepressed(x, y, button, istouch, presses)
    self:keypressed('return')
end

return Select
