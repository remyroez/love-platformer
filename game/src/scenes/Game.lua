
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

-- エイリアス
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

-- 読み込み
function Game:load(state, ...)
    state.input = Input()
end

-- ステート開始
function Game:entered(state, ...)
    -- ワールド
    state.world = wf.newWorld(0, 1000, true)
    state.world:addCollisionClass('platform')
    state.world:addCollisionClass('player')

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

    state.block = state.world:newRectangleCollider(0, 500, 800, 50)
    state.block:setType('static')
    state.block:setCollisionClass('platform')

    state.block2 = state.world:newRectangleCollider(0, 400, 300, 10)
    state.block2:setType('static')
    state.block2:setAngle(math.pi * 0.25)
    state.block2:setCollisionClass('platform')

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
    self:controlPlayer(state)

    state.world:update(dt)
    state.player:update(dt)
end

-- 描画
function Game:draw(state)
    state.player:draw()
    state.world:draw()
end

-- キー入力
function Game:keypressed(state, key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(state, x, y, button, istouch, presses)
end

-- プレイヤー操作
function Game:controlPlayer(state)
    local vx, vy = state.player:getLinearVelocity()

    local speed = 100
    local jumpPower = -1000

    -- 移動判定
    local x, y = 0, 0
    if state.input:down('left') then
        x = -1
    elseif state.input:down('right') then
        x = 1
    else
    end
    -- 減速
    state.player:setLinearVelocity(vx * 0.9, vy)

    -- ジャンプ判定
    local jump = false
    if not state.player:isGrounded() then
        -- 着地していない
    elseif state.input:pressed('jump') then
        jump = true
    end

    -- 地面にいる
    if state.player:isGrounded() then
        -- 地面に押し付ける
        state.player:applyLinearImpulse(0, 20)
    end

    -- 移動処理
    local mx, my = 0, 0
    if (x ~= 0 or y ~= 0) and speed ~= 0 then
        mx, my = lume.vector(lume.angle(state.player.x, state.player.y, state.player.x + x, state.player.y + y), speed)
        state.player:applyLinearImpulse(mx, my)
    end

    -- ジャンプ処理
    if jump then
        --state.player:setLinearVelocity(0, vy)
        state.player:applyLinearImpulse(0, jumpPower)
    else
    end

    --state.player:setColliderVelocity(x, y, speed)
end

return Game
