
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

-- エイリアス
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

-- 読み込み
function Game:load(state, ...)
    state.input = Input()
    state.camera = Camera()
end

-- ステート開始
function Game:entered(state, ...)
    -- レベル
    state.level = Level('assets/prototype.lua')
    state.level:setDebug(self.debugMode)
    state.level:setupCharacters(self.spriteSheet)

    -- ワールド
    state.world = state.level.world

    -- キャラクター
    state.player = state.level:getPlayer() or Character {
        spriteType = 'playerRed',
        spriteSheet = self.spriteSheet,
        x = 100,
        y = 100,
        offsetY = 16,
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
end

-- ステート終了
function Game:exited(state, ...)
    state.input:unbindAll()
    state.level:destroy()
end

-- 更新
function Game:update(state, dt)
    -- プレイヤー操作
    if state.player.alive then
        self:controlPlayer(state)
    end

    -- レベル更新
    state.level:update(dt)

    -- カメラ更新
    state.camera:update(dt)

    -- キャラクター追従
    if state.player.alive then
        state.camera:follow(state.player:getPosition())
    end
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
            state.camera.scale)
    end
    state.camera:detach()

    -- カメラ演出描画
    state.camera:draw()
end

-- キー入力
function Game:keypressed(state, key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(state, x, y, button, istouch, presses)
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
    if state.input:down('left') then
        direction = 'left'
    elseif state.input:down('right') then
        direction = 'right'
    end

    if state.input:down('up') then
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
    if state.input:pressed('jump') then
        state.player:jump()
    elseif vdirection then
        state.player:climb(vdirection)
    end

    -- ダメージ判定
    if state.player:enterCollider('damage') then
        local vx, vy = state.player:getLinearVelocity()
        state.player:damage(1, vx > 0 and 'right' or vx < 0 and 'left' or nil)
    end
end

return Game
