
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
        title = 'FIRST',
        path = 'assets/red-1.lua',
    },
    {
        title = 'STRANGE FOREST',
        path = 'assets/yellow-1.lua',
    },
    {
        title = 'ICE MOUNTAIN',
        path = 'assets/blue-1.lua',
    },
    {
        title = 'PROTOTYPE',
        path = 'assets/prototype.lua',
    },
}

-- 次のステートへ
function Select:nextState(...)
    self:gotoState('game', ...)
end

-- 読み込み
function Select:load(state, ...)
end

-- 開始
function Select:entered(state, from, background, bgX, ...)
    local fromTitle = from == 'title'
    local fromFailed = from == 'failed'
    local fromNext = from == 'next'

    -- 次のレベルへ
    if fromNext then
        self.selectedLevel = self.selectedLevel + 1
        if self.selectedLevel > #levels then
            self.selectedLevel = #levels
        end
    end

    -- タイトルから背景を引き継ぐ
    state.background = background or Background(2, self.width * 2, self.height)
    state.bgX = bgX or 0

    -- タイマー
    state.timer = Timer()

    -- 演出
    state.busy = true
    state.visiblePressAnyKey = true
    state.fade = { fromFailed and 0 or 1, fromFailed and 0 or 1, fromFailed and 0 or 1, fromTitle and 0 or 1 }
    state.alpha = 0
    state.offset = 0

    -- 開始演出
    state.timer:tween(
        0.5,
        state,
        { fade = { [4] = 0 }, alpha = 1 },
        'in-out-cubic',
        function ()
            -- キー入力表示の点滅
            state.timer:every(
                0.5,
                function ()
                    state.visiblePressAnyKey = not state.visiblePressAnyKey
                end
            )

            -- 操作可能
            state.busy = false
        end
    )

    -- ＢＧＭ
    self:playMusic('outgame')
end

-- 終了
function Select:exited(state, ...)
    -- タイマー開放
    state.timer:destroy()
    state.timer = nil

    -- 背景開放
    state.background:destroy()
    state.background = nil

    -- ＢＧＭ
    self:stopMusic()
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
    lg.setColor(1, 1, 1, state.alpha)
    local level = levels[self.selectedLevel]
    lg.printf('SELECT LEVEL', self.font16, 0, self.height * 0.2 - self.font16:getHeight() * 0.5, self.width, 'center')
    lg.printf(
        self.selectedLevel .. '. ' .. level.title,
        self.font32,
        state.offset,
        self.height * 0.4 - self.font32:getHeight() * 0.5,
        self.width,
        'center'
    )

    -- クリア表示
    if self.clearedLevelScores[self.selectedLevel] ~= nil then
        local x, y = state.offset, self.height * 0.65 - self.font16:getHeight() * 0.5
        lg.printf('best', self.font16, x, y, self.width, 'center')
        lg.printf(self.clearedLevelScores[self.selectedLevel], self.font32, x, y + self.font16:getHeight() * 1.5, self.width, 'center')
    end

    -- キー入力表示
    if not state.busy and state.visiblePressAnyKey then
        lg.printf('left/right/enter', self.font8, 0, self.height * 0.5 - self.font8:getHeight() * 0.5, self.width, 'center')
    end

    -- フェード
    if state.fade[4] > 0 then
        lg.setColor(unpack(state.fade))
        lg.rectangle('fill', 0, 0, self.width, self.height)
    end
end

-- キー入力
function Select:keypressed(state, key, scancode, isrepeat)
    if state.busy then
        -- 操作不可
    elseif key == 'return' then
        -- 決定
        state.busy = true
        state.fade = { 1, 1, 1, 0 }
        state.timer:tween(
            0.5,
            state,
            { fade = { [4] = 1 } },
            'in-out-cubic',
            function ()
                local level = levels[self.selectedLevel]
                self:nextState(level.path)
            end
        )

        -- ＳＥ
        self:playSound('ok')

    elseif key == 'left' or key == 'a' then
        -- 左
        self.selectedLevel = self.selectedLevel - 1
        if self.selectedLevel <= 0 then
            self.selectedLevel = self.debugMode and #levels or math.min(self.clearedLevel + 1, #levels)
        end

        -- 演出
        state.offset = 64
        state.timer:tween(
            0.2,
            state,
            { offset = 0 },
            'out-elastic',
            'select'
        )

        -- ＳＥ
        self:playSound('select')

    elseif key == 'right' or key == 'd' then
        -- 右
        self.selectedLevel = self.selectedLevel + 1
        if self.selectedLevel > (self.debugMode and #levels or math.min(self.clearedLevel + 1, #levels)) then
            self.selectedLevel = 1
        end

        -- 演出
        state.offset = -64
        state.timer:tween(
            0.2,
            state,
            { offset = 0 },
            'out-elastic',
            'select'
        )

        -- ＳＥ
        self:playSound('select')
    end
end

-- マウス入力
function Select:mousepressed(state, x, y, button, istouch, presses)
    if state.busy then
        -- 操作不可
    else
        self:keypressed(state, 'return')
    end
end

return Select
