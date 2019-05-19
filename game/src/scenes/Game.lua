
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- ゲーム
local Game = Base:newState 'game'

-- ライブラリ
local wf = require 'windfield'
local lume = require 'lume'

-- クラス
local Character = require 'Character'
local Input = require 'Input'
local Camera = require 'Camera'
local Level = require 'Level'
local Timer = require 'Timer'

-- エイリアス
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

-- 次のステートへ
function Game:nextState(...)
    self:gotoState('select', ...)
end

-- 読み込み
function Game:load(state, ...)
    state.input = Input()
    state.camera = Camera()
end

-- ステート開始
function Game:entered(state, path, ...)
    -- レベルのパス
    state.path = state.path or path

    -- レベル
    state.level = Level(state.path)
    state.level:setDebug(self.debugMode)
    state.level:setupCharacters(self.spriteSheet)
    state.level:setupItems(self.spriteSheet)

    -- ワールド
    state.world = state.level.world

    -- キャラクター
    state.player = state.level:getPlayer() or Character {
        spriteType = 'playerRed',
        spriteSheet = self.spriteSheet,
        x = 100,
        y = 100,
        radius = 16,
        collider = state.world:newRectangleCollider(0, 0, 24, 32),
        collisionClass = 'player',
        world = state.world,
        h_align = 'center',
        v_align = 'bottom',
    }

    -- カメラ初期設定
    state.camera:setFollowStyle('NO_DEADZONE')
    state.camera:follow(state.player:getPosition())
    state.camera:update()
    state.camera:setFollowLerp(0.1)
    state.camera:setFollowLead(2)
    state.camera:setFollowStyle('PLATFORMER')
    state.camera:setBounds(state.level.left, state.level.top, state.level.width, state.level.height)
    --state.camera.scale = 0.5

    -- 操作設定
    local binds = {
        left = { 'left', 'a' },
        right = { 'right', 'd' },
        up = { 'up', 'w' },
        down = { 'down', 's' },
        climb = { 'up', 'w' },
        crouch = { 'lctrl' },
        jump = { 'space' },
    }
    for name, keys in pairs(binds) do
        for _, key in ipairs(keys) do
            state.input:bind(key, name)
        end
    end

    -- 演出
    state.timer = Timer()
    state.busy = true
    state.pause = false
    state.visiblePressAnyKey = false
    state.fade = { 1, 1, 1, 1 }
    state.alpha = 0
    state.gameover = false
    state.cleared = false

    -- 開始演出
    state.timer:tween(
        0.5,
        state,
        { fade = { [4] = 0 } },
        'in-out-cubic',
        function ()
            -- 操作可能
            state.busy = false
            state.pause = false
        end
    )
end

-- ステート終了
function Game:exited(state, ...)
    state.timer:destroy()
    state.input:unbindAll()
    state.level:destroy()
end

-- 更新
function Game:update(state, dt)
    -- プレイヤー操作
    if state.player.alive then
        self:controlPlayer(state)
    end

    -- 更新
    if state.pause then
        -- ポーズ中は更新しない
    else
        -- レベル更新
        state.level:update(dt)

        -- クリア／ゲームオーバー判定
        if state.cleared or state.gameover then
            -- クリア／ゲームオーバー済み
        elseif state.level.cleared then
            -- まだクリア画面じゃなくて、レベルクリアしたとき
            state.cleared = true

            -- クリア演出
            state.busy = true
            state.timer:tween(
                0.5,
                state,
                { alpha = 1 },
                'in-out-cubic',
                function ()
                    -- キー入力表示の点滅
                    state.visiblePressAnyKey = true
                    state.timer:every(
                        0.5,
                        function ()
                            state.visiblePressAnyKey = not state.visiblePressAnyKey
                        end
                    )

                    -- 操作可能
                    state.busy = false
                    state.pause = true
                end
            )

        elseif not state.player.alive then
            -- まだゲームオーバー画面じゃなくて、プレイヤーが死んだとき
            state.gameover = true

            -- ゲームオーバー演出
            state.busy = true
            state.timer:tween(
                0.5,
                state,
                { alpha = 1 },
                'in-out-cubic',
                function ()
                    -- キー入力表示の点滅
                    state.visiblePressAnyKey = true
                    state.timer:every(
                        0.5,
                        function ()
                            state.visiblePressAnyKey = not state.visiblePressAnyKey
                        end
                    )

                    -- 操作可能
                    state.busy = false
                    state.pause = true
                end
            )
        end
    end

    -- カメラ更新
    state.camera:update(dt)

    -- キャラクター追従
    if state.player.alive then
        state.camera:follow(state.player:getPosition())
    end

    -- タイマー更新
    state.timer:update(dt)
end

-- 描画
function Game:draw(state)
    -- カメラ内で描画
    state.camera:attach()
    do
        -- レベル描画
        state.level:draw(
            state.camera.w / 2 - state.camera.x,
            state.camera.h / 2 - state.camera.y,
            state.camera.scale
        )
    end
    state.camera:detach()

    -- カメラ演出描画
    state.camera:draw()

    -- クリア／ゲームオーバー表示
    if state.gameover and state.alpha > 0 then
        -- 暗転
        lg.setColor(0, 0, 0, state.alpha * 0.75)
        lg.rectangle('fill', 0, 0, self.width, self.height)

        -- ゲームオーバー
        lg.setColor(1, 0, 0, state.alpha)
        lg.printf('GAMEOVER', self.font64, 0, self.height * 0.4 - self.font64:getHeight() * 0.5, self.width, 'center')

        -- キー入力表示
        if not state.busy and state.visiblePressAnyKey then
            lg.printf('PRESS R to RETRY', self.font16, 0, self.height * 0.7 - self.font16:getHeight() * 0.5, self.width, 'center')
            lg.printf('PRESS ENTER to LEVEL SELECTION', self.font16, 0, self.height * 0.7 - self.font16:getHeight() * 0.5 + self.font16:getHeight() * 1.5, self.width, 'center')
        end
    elseif state.cleared and state.alpha > 0 then
        -- 暗転
        lg.setColor(1, 1, 1, state.alpha * 0.75)
        lg.rectangle('fill', 0, 0, self.width, self.height)

        -- クリア
        lg.setColor(0, 0, 0, state.alpha)
        lg.printf('LEVEL CLEAR!', self.font64, 0, self.height * 0.4 - self.font64:getHeight() * 0.5, self.width, 'center')

        -- キー入力表示
        if not state.busy and state.visiblePressAnyKey then
            lg.printf('PRESS ENTER to LEVEL SELECTION', self.font16, 0, self.height * 0.7 - self.font16:getHeight() * 0.5, self.width, 'center')
        end
    end

    -- フェード
    if state.fade[4] > 0 then
        lg.setColor(unpack(state.fade))
        lg.rectangle('fill', 0, 0, self.width, self.height)
    end

    -- デバッグ描画
    if self.debugMode then
        self:drawDebug(state)
    end
end

-- デバッグ描画
function Game:drawDebug(state)
    lg.setColor(1, 1, 1, 1)

    local x, y = 0, 0
    for item, t in pairs(state.level.collection) do
        for spriteType, num in pairs(t) do
            love.graphics.printf(
                item .. '(' .. spriteType .. '): ' .. num,
                x, y,
                self.width,
                'right'
            )
            y = y + 12
        end
    end
end

-- キー入力
function Game:keypressed(state, key, scancode, isrepeat)
    if state.busy then
        -- 操作不可
    elseif state.gameover then
        -- ゲームオーバー時
        if key == 'return' then
            state.busy = true
            state.fade = { 0, 0, 0, 0 }
            state.timer:tween(
                0.5,
                state,
                { fade = { [4] = 1 } },
                'in-out-cubic',
                function ()
                    self:nextState('failed')
                end
            )
        elseif key == 'r' then
            state.busy = true
            state.fade = { 1, 1, 1, 0 }
            state.timer:tween(
                0.5,
                state,
                { fade = { [4] = 1 } },
                'in-out-cubic',
                function ()
                    self:gotoState('game')
                end
            )
        end
    elseif state.cleared and key == 'return' then
        -- クリア時
        state.busy = true
        state.fade = { 1, 1, 1, 0 }
        state.timer:tween(
            0.5,
            state,
            { fade = { [4] = 1 } },
            'in-out-cubic',
            function ()
                if self.clearedLevel < self.selectedLevel then
                    self.clearedLevel = self.selectedLevel
                    self:nextState('next')
                else
                    self:nextState('cleared')
                end
            end
        )
    end
end

-- マウス入力
function Game:mousepressed(state, x, y, button, istouch, presses)
    if state.busy then
        -- 操作不可
    else
        self:keypressed(state, 'return')
    end
end

-- デバッグモードの設定
function Game:setDebugMode(mode)
    Base.setDebugMode(self, mode)

    -- レベル
    self.state.level:setDebug(mode)
end

-- プレイヤー操作
function Game:controlPlayer(state)
    local direction
    local vdirection

    -- 移動判定
    if state.busy then
        -- 操作不可
    elseif state.input:down('left') then
        direction = 'left'
    elseif state.input:down('right') then
        direction = 'right'
    end

    if state.busy then
        -- 操作不可
    elseif state.input:down('up') then
        vdirection = 'up'
    elseif state.input:down('down') then
        vdirection = 'down'
    end

    -- 移動
    if direction then
        state.player:walk(direction)
    else
        state.player:stand()
    end

    -- ジャンプ判定
    if state.busy then
        -- 操作不可
    elseif state.input:pressed('jump') then
        state.player:jump()
    elseif vdirection then
        state.player:climb(vdirection)
    end
end

return Game
