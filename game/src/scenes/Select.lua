
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- レベル選択
local Select = Base:newState 'select'

-- クラス
local Background = require 'Background'
local Timer = require 'Timer'

-- エイリアス
local lg = love.graphics

-- レベル情報
local levels = {
    {
        title = 'PROTOTYPE',
        path = 'assets/prototype.lua',
    }
}

-- 次のステートへ
function Select:nextState(...)
    self:gotoState('game', ...)
end

-- 読み込み
function Select:load(state, ...)
end

-- 開始
function Select:entered(state, background, bgX, ...)
    -- タイトルから背景を引き継ぐ
    state.background = background or Background(2, self.width * 2, self.height)
    state.bgX = bgX or 0

    -- タイマー
    state.timer = Timer()
end

-- 終了
function Select:exited(state, ...)
    -- タイマー開放
    state.timer:destroy()
    state.timer = nil

    -- 背景開放
    state.background:destroy()
    state.background = nil
end

-- 更新
function Select:update(state, dt)
    -- タイマー
    state.timer:update(dt)

    -- 背景のスクロール
    state.bgX = state.bgX + dt * 100
    if state.bgX > 640 then
        state.bgX = state.bgX - 640
    end
end

-- 描画
function Select:draw(state)
    -- 背景
    if state.background then
        lg.push()
        lg.translate(math.ceil(-state.bgX), 0)
        state.background:draw()
        lg.pop()
    end

    -- レベル選択
    local level = levels[self.selectedLevel]
    lg.printf('SELECT LEVEL', self.font16, 0, self.height * 0.3 - self.font16:getHeight() * 0.5, self.width, 'center')
    lg.printf(self.selectedLevel .. '. ' .. level.title, self.font32, 0, self.height * 0.5 - self.font32:getHeight() * 0.5, self.width, 'center')
end

-- キー入力
function Select:keypressed(state, key, scancode, isrepeat)
    if key == 'return' then
        -- 決定
        local level = levels[self.selectedLevel]
        self:nextState(level.path)
    elseif key == 'left' or key == 'a' then
        -- 左
        self.selectedLevel = self.selectedLevel - 1
        if self.selectedLevel <= 0 then
            self.selectedLevel = #levels
        end
    elseif key == 'right' or key == 'd' then
        -- 右
        self.selectedLevel = self.selectedLevel + 1
        if self.selectedLevel > #levels then
            self.selectedLevel = 1
        end
    end
end

-- マウス入力
function Select:mousepressed(state, x, y, button, istouch, presses)
    self:keypressed(state, 'return')
end

return Select
