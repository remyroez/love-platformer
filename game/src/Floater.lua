
local class = require 'middleclass'
local lume = require 'lume'

-- クラス
local Enemy = require 'Enemy'

-- フローター
local Floater = class('Floater', Enemy)

-- 初期化
function Floater:initialize(args)
    -- デフォルト値
    args.state = args.state or 'float'
    args.speed = args.speed or 10
    args.offsetY = args.offsetY or 0
    args.h_align = args.h_align or 'center'
    args.v_align = args.v_align or 'middle'

    -- 親クラス初期化
    Enemy.initialize(self, args)

    -- 重力を無視
    self.collider:setGravityScale(0)

    -- 摩擦ゼロ
    self.collider:setFriction(0)
    self.collider:setRestitution(1)

    -- 加速
    self.accelSpeed = args.object.properties.accelSpeed or 3
    self.currentSpeed = 0
    self.maxVelocity = args.object.properties.maxVelocity or 200

    self.searchRadius = args.object.properties.searchRadius or 200

    self.grounded = false
end

-- ダメージ
function Floater:damage(damage, direction)
    self:gotoState('damage', damage, direction)
end

-- 減速
function Floater:reduceSpeed()
    local vx, vy = self:getLinearVelocity()
    local dist = lume.distance(0, 0, vx, vy)
    if dist > self.maxVelocity then
        vx, vy = lume.vector(lume.angle(0, 0, vx, vy), self.maxVelocity)
    end
    self:setLinearVelocity(vx * 0.99, vy * 0.99)
end

-- 地面に押し付ける
function Floater:applyAlternativeGravity()
    -- しない
end

-- 着地しているかどうか更新
function Floater:checkGrounded()
    -- しない
end

-- プレイヤーの検索
function Floater:searchPlayer(radius)
    radius = radius or self.searchRadius
    local player
    local colliders = self.world:queryCircleArea(self.x, self.y, radius, { 'player' })
    for _, collider in ipairs(colliders) do
        player = collider:getObject()
        break
    end
    return player
end

-- 浮きステート
local Float = Floater:addState 'float'

-- 浮き: ステート開始
function Float:enteredState()
    self:resetAnimations(
        { 'enemyFloating_3.png' }
    )
end

-- 浮き: 更新
function Float:update(dt)
    Floater.update(self, dt)

    -- プレイヤー検索
    local player = self:searchPlayer()
    if player then
        -- 見つかったので追跡
        self:gotoState('goto', player)
    end
end

-- 浮き: デバッグ描画
function Float:drawDebug()
    Floater.drawDebug(self)
    love.graphics.circle('line', self.x, self.y, self.searchRadius)
end

-- 移動ステート
local Goto = Floater:addState 'goto'

-- 移動: ステート開始
function Goto:enteredState(targetXorTarget, targetY)
    self:resetAnimations(
        { 'enemyFloating_1.png' }
    )

    -- 未初期化なら延期
    if not self.initialized then
        self.postponeEnterState = true
        return
    end

    -- プライベート
    self._goto = self._goto or {}

    -- 移動先
    self._goto.x, self._goto.y = 0, 0
    if type(targetXorTarget) == 'table' then
        self._goto.target = targetXorTarget
        self._goto.x, self._goto.y = targetXorTarget.x, targetXorTarget.y - targetXorTarget.radius * 2
    else
        self._goto.x, self._goto.y = targetXorTarget, targetY
    end

    self.currentSpeed = 0
end

-- 移動: ステート終了
function Goto:exitedState()
end

-- 移動: 更新
function Goto:update(dt)
    -- ターゲット追跡
    if self._goto.target then
        self._goto.x, self._goto.y = self._goto.target.x, self._goto.target.y - self._goto.target.radius * 2
        local dist = lume.distance(self.x, self.y, self._goto.x, self._goto.y)
        if dist > self.searchRadius then
            -- 離れすぎたので解除
            self._goto.target = nil
        elseif not self._goto.target.alive then
            -- 死んでるので解除
            self._goto.target = nil
        end
    else
        -- プレイヤー検索
        self._goto.target = self:searchPlayer()
    end

    -- 加速
    if self.currentSpeed >= self.speed then
        self.currentSpeed = self.speed
    else
        self.currentSpeed = self.currentSpeed + dt * self.accelSpeed
    end

    -- 移動
    local x, y = lume.vector(lume.angle(self.x, self.y, self._goto.x, self._goto.y), self.currentSpeed)
    self:applyLinearImpulse(x, y)

    Floater.update(self, dt)

    -- 到着した
    local dist = lume.distance(self.x, self.y, self._goto.x, self._goto.y)
    if dist < self.radius * 2 then
        -- 到着したので浮きに戻る
        self:gotoState('float')
    end
end

-- 移動: デバッグ描画
function Goto:drawDebug()
    Floater.drawDebug(self)
    love.graphics.circle('line', self.x, self.y, self.searchRadius)
    love.graphics.line(self.x, self.y, self._goto.x, self._goto.y)
end

-- 移動: ダメージ
function Goto:damage(damage, direction, attacker)
    attacker:damage(self.attack, direction, self)
end

-- ダメージステート
local Damage = Floater:addState 'damage'

-- ダメージ: ステート開始
function Damage:enteredState(damage, direction)
    self:resetAnimations(
        { 'enemyFloating_4.png' }
    )

    -- ダメージを受ける
    self.life = self.life - (damage or 1)

    -- 死んだら退場
    if self.life <= 0 then
        -- 飛ばされる方向
        self._damage = {}
        self._damage.direction = direction

        -- Ｙ軸の速度をカット
        local vx, vy = self:getLinearVelocity()
        self:setLinearVelocity(vx, 0)

        -- ジャンプ
        self:applyLinearImpulse(0, -self.jumpPower * 0.75)
        self.collider:setGravityScale(1)
        self.grounded = false

        -- 退場
        self.leave = true
        --self:setColliderActive(false)
    else
        -- しばらく点滅して無敵
        self.invincible = true
        self.timer:every(
            0.05,
            function ()
                self.visible = not self.visible
            end,
            30,
            function ()
                self.visible = true
                self.invincible = false
                self:gotoState 'float'
            end
        )
    end
end

-- ダメージ: ダメージ
function Damage:damage(damage, direction)
end

-- 減速
function Damage:reduceSpeed()
    Enemy.reduceSpeed(self)
end

-- 地面に押し付ける
function Damage:applyAlternativeGravity()
    Enemy.applyAlternativeGravity(self)
end

return Floater
