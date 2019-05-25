
local class = require 'middleclass'

local Timer = require 'Timer'

-- キャラクター
local Character = class('Character', require 'Entity')
Character:include(require 'stateful')
Character:include(require 'Rectangle')
Character:include(require 'SpriteRenderer')
Character:include(require 'Transform')
Character:include(require 'Collider')
Character:include(require 'Animation')
Character:include(require 'SoundPlayer')

-- 初期化
function Character:initialize(args)
    self.initialized = false
    self.postponeEnterState = false

    self.timer = Timer()

    -- オブジェクト
    self.object = args.object

    -- Animation 初期化
    self:initializeAnimation()

    -- SoundPlayer 初期化
    self:initializeSoundPlayer(args.sounds)

    -- スプライト及びステート
    self.spriteType = args.spriteType or 'playerRed'
    self:gotoState(args.state or 'stand', unpack(args.stateArgs or {}))

    -- 初期設定
    self.spriteName = self:getCurrentSpriteName()
    self.color = args.color or { 1, 1, 1, 1 }
    self.offsetY = args.offsetY or 16
    self.radius = args.radius or 16
    self.world = args.world or {}
    self.speed = args.speed or 100
    self.jumpPower = args.jumpPower or 700
    self.attack = args.attack or 1
    self.life = args.life or 1
    self.score = args.score or 0
    self.alive = true
    self.visible = true
    self.animation = true
    self.grounded = false
    self.invincible = false
    self.leave = false

    self.onDying = args.onDying or function () end
    self.onDead = args.onDead or function () end
    self.onGoal = args.onGoal or function () end
    self.hasKey = args.hasKey or function () return false end

    -- SpriteRenderer 初期化
    self:initializeSpriteRenderer(args.spriteSheet)

    -- スプライト
    local spriteWidth, spriteHeight = self:getSpriteSize(self.spriteName)
    local w = args.width or spriteWidth
    local h = args.height or spriteHeight

    -- Rectangle 初期化
    self:initializeRectangle(args.x, args.y, w, h, args.h_align or 'center', args.v_align or 'bottom')

    -- Transform 初期化
    self:initializeTransform(self.x, self.y, args.rotation, w / spriteWidth, h / spriteHeight)

    -- ベーススケール
    self.baseScaleX, self.baseScaleY = self.scaleX, self.scaleY

    -- Collider 初期化
    self:initializeCollider(args.collider or self.world:newCircleCollider(0, 0, self.radius))

    -- Collider 初期設定
    self.collider:setObject(self)
    self.collider:setFixedRotation(true)
    self.collider:setSleepingAllowed(false)
    local mx, my, mass, inertia = self.collider:getMassData()
    local newMass = args.mass or mass
    self.collider:setMassData(mx, my, newMass, inertia * (newMass / mass))
    if args.collisionClass then
        self.collider:setCollisionClass(args.collisionClass)
    end

    -- 接触先によって当たり判定を調整する
    self.collider:setPreSolve(
        function(collider_1, collider_2, contact)
            if collider_1.collision_class ~= self.collider.collision_class then
                -- 自分ではない？
            elseif self.leave and collider_2.collision_class ~= 'deadline' then
                -- 退場時はデッドライン以外はスルー
                contact:setEnabled(false)
            elseif collider_2.collision_class == 'one_way' then
                -- 下からは通過する
                local px, py = collider_1:getPosition()
                local character = collider_1:getObject()
                local ph = character and character.radius or 16
                local collision = collider_2:getObject()
                local tx, ty = collision.left, collision.top
                if py + ph/2 > ty then
                    contact:setEnabled(false)
                end
            elseif collider_2.collision_class == 'ladder' then
                -- ハシゴは当たり判定なし
                contact:setEnabled(false)
            end
        end
    )

    -- デバッグフラグ
    self.debug = args.debug ~= nil and args.debug or false

    -- 初期化完了
    self.initialized = true

    -- ステート開始を延期していれば再開
    if self.postponeEnterState then
        self:gotoState(args.state or 'stand', unpack(args.stateArgs or {}))
        self.postponeEnterState = false
    end
end

-- 破棄
function Character:destroy()
    self.timer:destroy()
    self:gotoState(nil)
    self:destroyCollider()
end

-- 前更新
function Character:preUpdate(dt)
    self:reduceSpeed()
    self:applyAlternativeGravity()
end

-- 更新
function Character:update(dt)
    self:preUpdate(dt)

    -- コライダーの位置を取得して適用
    self:applyPositionFromCollider()

    -- 足元を起点にしたいのでズラす
    self.y = self.y + self.offsetY

    -- アニメーション更新
    if self.animation then
        self:updateAnimation(dt)
    end

    self:postUpdate(dt)

    self.timer:update(dt)
end

-- 後更新
function Character:postUpdate(dt)
    -- 着地判定
    self:checkGrounded()

    -- 強制死亡判定
    if self.alive then
        self:checkDeadline()
    end
end

-- 描画
function Character:draw()
    -- スプライト描画
    if self.visible then
        self:pushTransform(self:left(), self:top())
        love.graphics.setColor(self.color)
        self:drawSprite(self:getCurrentSpriteName())
        self:popTransform()
    end

    -- デバッグ描画
    if self.debug then
        self:drawDebug()
    end
end

-- デバッグ描画
function Character:drawDebug()
    love.graphics.print('x = ' .. self.x .. ', y = ' .. self.y, self.x, self.y)
    love.graphics.print('alive: ' .. tostring(self.alive), self.x, self.y + 12)
end

-- 描画
function Character:getCurrentSpriteName()
    return self:getCurrentAnimation()
end

-- 減速
function Character:reduceSpeed()
    local vx, vy = self:getLinearVelocity()
    self:setLinearVelocity(vx * 0.8, vy)
end

-- 地面に押し付ける
function Character:applyAlternativeGravity()
    self:applyLinearImpulse(0, 40)
end

-- 着地しているかどうか更新
function Character:checkGrounded()
    local grounded = self.grounded

    if self.leave then
        grounded = false
    elseif self:isFalling() then
        local colliders = self.world:queryLine(self.x, self.y, self.x, self.y + 10, { 'platform', 'one_way' })
        grounded = #colliders > 0
    end

    if grounded ~= self.grounded then
        self.grounded = grounded
    end

    -- 空中なら摩擦０
    self.collider:setFriction(self.grounded and 1 or 0)
end

-- 死亡ラインを超えたかどうか判定
function Character:checkDeadline()
    if self:enterCollider('deadline') then
        self:die()
    end
end

-- 落下しているかどうか返す
function Character:isFalling()
    local vx, vy = self:getLinearVelocity()
    return vy >= 0
end

-- 着地しているかどうか返す
function Character:isGrounded()
    return self.grounded
end

-- ダメージ
function Character:damage(damage, direction)
    -- 無敵
    if self.invincible then
        return
    end

    -- ライフが０以上ならダメージを受ける
    if self.life > 0 then
        self.life = self.life - (damage or 1)
    end

    -- ライフが０以下になったら死ぬ
    if self.life <= 0 then
        self.onDying(self)
        self:die()
    end
end

-- 死ぬ
function Character:die()
    self.alive = false
    self.onDead(self)
end

return Character
