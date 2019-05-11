
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

-- エイリアス
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

-- 読み込み
function Game:load(state, ...)
    state.input = Input()
    state.camera = Camera()
    state.camera:setFollowStyle('PLATFORMER')
end

-- ステート開始
function Game:entered(state, ...)
    -- ワールド
    state.world = wf.newWorld(0, 1000, true)
    state.world:addCollisionClass('platform')
    state.world:addCollisionClass('player')
    state.world:addCollisionClass('damage')

    -- キャラクター
    state.player = Character {
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
    state.player.collider:setFixedRotation(true)
    state.player.collider:setFriction(1)

    state.block = state.world:newRectangleCollider(0, 500, 2000, 50)
    state.block:setType('static')
    state.block:setCollisionClass('platform')

    state.block2 = state.world:newRectangleCollider(0, 400, 300, 10)
    state.block2:setType('static')
    state.block2:setAngle(math.pi * 0.25)
    state.block2:setCollisionClass('platform')

    state.block3 = state.world:newRectangleCollider(500, 490, 100, 20)
    state.block3:setType('kinematic')
    --state.block3:setAngle(math.pi * 0.25)
    state.block3:setCollisionClass('damage')

    -- 操作設定
    local binds = {
        left = { 'left', 'a' },
        right = { 'right', 'd' },
        jump = { 'up', 'w', 'space' },
        crouch = { 'down', 's', 'lctrl' },
    }
    for name, keys in pairs(binds) do
        for _, key in ipairs(keys) do
            state.input:bind(key, name)
        end
    end
end

-- ステート終了
function Game:exited(state, ...)
    state.player:destroy()
end

-- 更新
function Game:update(state, dt)
    -- プレイヤー操作
    if state.player.alive then
        self:controlPlayer(state)
    end

    -- ワールド更新
    state.world:update(dt)

    -- キャラクター更新
    state.player:update(dt)

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
        state.player:draw()
        state.world:draw()
    end
    state.camera:detach()

    state.camera:draw()
end

-- キー入力
function Game:keypressed(state, key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(state, x, y, button, istouch, presses)
end

-- プレイヤー操作
function Game:controlPlayer(state)
    local direction

    -- 移動判定
    if state.input:down('left') then
        direction = 'left'
    elseif state.input:down('right') then
        direction = 'right'
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
    end

    -- 地面にいる
    if state.player:isGrounded() then
    else
    end

    -- ダメージ判定
    if state.player:enterCollider('damage') then
        local vx, vy = state.player:getLinearVelocity()
        state.player:damage(1, vx > 0 and 'right' or vx < 0 and 'left' or nil)
    end

    -- 強制死亡
    local bx, by = state.block:getPosition()
    if state.player.y > by + 100 then
        state.player:die()
    end
end

return Game
