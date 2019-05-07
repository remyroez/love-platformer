
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- タイトル
local Title = Base:newState 'title'

-- エイリアス
local lg = love.graphics

-- 次のステートへ
function Title:nextState(...)
    self:gotoState('select', ...)
end

-- 読み込み
function Title:load(state, ...)
end

-- ステート開始
function Title:entered(state, ...)
end

-- ステート終了
function Title:exited(state, ...)
end

-- 更新
function Title:update(state, dt)
end

-- 描画
function Title:draw(state)
end

-- キー入力
function Title:keypressed(key, scancode, isrepeat)
    self:nextState()
end

-- マウス入力
function Title:mousepressed(x, y, button, istouch, presses)
    self:keypressed('space')
end

return Title
