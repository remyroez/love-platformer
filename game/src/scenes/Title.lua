
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
    self:gotoState('select', 'title', ...)
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

    -- 演出
    state.busy = true
    state.visiblePressAnyKey = true
    state.fade = { .42, .75, .89, 1 }
    state.alpha = 0

    -- 開始演出
    state.timer:tween(
        1,
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
    lg.setColor(1, 1, 1, state.alpha)
    lg.printf('PLATFORMER', self.font64, 0, self.height * 0.3 - self.font64:getHeight() * 0.5, self.width, 'center')

    -- キー入力表示
    if not state.busy and state.visiblePressAnyKey then
        lg.printf('PRESS ANY KEY', self.font32, 0, self.height * 0.7 - self.font32:getHeight() * 0.5, self.width, 'center')
    end

    -- フェード
    if state.fade[4] > 0 then
        lg.setColor(unpack(state.fade))
        lg.rectangle('fill', 0, 0, self.width, self.height)
    end
end

-- キー入力
function Title:keypressed(state, key, scancode, isrepeat)
    if not state.busy then
        -- 操作不可
        state.busy = true

        -- 終了演出
        state.timer:tween(
            0.5,
            state,
            { alpha = 0 },
            'in-out-cubic',
            function ()
                -- 演出が終わったら次へ
                self:nextState(state.background, state.bgX)
            end
        )
    end
end

-- マウス入力
function Title:mousepressed(state, x, y, button, istouch, presses)
    if not state.busy then
        self:keypressed(state, 'mouse' .. button)
    end
end

return Title
