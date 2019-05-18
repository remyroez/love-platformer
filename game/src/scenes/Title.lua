
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- タイトル
local Title = Base:newState 'title'

-- クラス
local Background = require 'Background'
local Timer = require 'Timer'

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
    -- 背景
    state.background = Background(2, self.width * 2, self.height)
    state.bgX = 0

    -- タイマー
    state.timer = Timer()
end

-- ステート終了
function Title:exited(state, ...)
    -- タイマー開放
    state.timer:destroy()
    state.timer = nil
end

-- 更新
function Title:update(state, dt)
    -- タイマー
    state.timer:update(dt)

    -- 背景のスクロール
    state.bgX = state.bgX + dt * 100
    if state.bgX > 640 then
        state.bgX = state.bgX - 640
    end
end

-- 描画
function Title:draw(state)
    -- 背景
    if state.background then
        lg.push()
        lg.translate(math.ceil(-state.bgX), 0)
        state.background:draw()
        lg.pop()
    end

    -- タイトル
    lg.printf('PLATFORMER', self.font64, 0, self.height * 0.3 - self.font64:getHeight() * 0.5, self.width, 'center')

    -- タイトル
    lg.printf('PRESS ANY KEY', self.font32, 0, self.height * 0.7 - self.font32:getHeight() * 0.5, self.width, 'center')
end

-- キー入力
function Title:keypressed(state, key, scancode, isrepeat)
    self:nextState(state.background, state.bgX)
end

-- マウス入力
function Title:mousepressed(state, x, y, button, istouch, presses)
    self:keypressed('space')
end

return Title
