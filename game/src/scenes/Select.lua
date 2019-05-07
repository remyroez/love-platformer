
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- レベル選択
local Select = Base:newState 'select'

-- エイリアス
local lg = love.graphics

-- 次のステートへ
function Select:nextState(...)
    self:gotoState('game', ...)
end

-- 読み込み
function Select:load(state, ...)
end

-- 開始
function Select:entered(state, ...)
end

-- 終了
function Select:exited(state, ...)
end

-- 更新
function Select:update(state, dt)
end

-- 描画
function Select:draw(state)
end

-- キー入力
function Select:keypressed(state, key, scancode, isrepeat)
    self:nextState()
end

-- マウス入力
function Select:mousepressed(state, x, y, button, istouch, presses)
    self:keypressed('return')
end

return Select
