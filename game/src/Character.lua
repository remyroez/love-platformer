
local class = require 'middleclass'

-- キャラクター
local Character = class('Character', require 'Entity')
Character:include(require 'stateful')
Character:include(require 'Rectangle')
Character:include(require 'SpriteRenderer')
Character:include(require 'Transform')
Character:include(require 'Collider')
Character:include(require 'Animation')

-- 初期化
function Character:initialize(args)
    -- Animation 初期化
    self:initializeAnimation()

    -- 初期設定
    self.spriteType = args.spriteType or 'playerRed'
    self:gotoState 'stand'

    self.spriteName = self:getCurrentSpriteName()
    self.color = args.color or { 1, 1, 1, 1 }
    self.offsetY = args.offsetY or 0
    self.world = args.world or {}
    self.speed = args.speed or 100
    self.jumpPower = args.jumpPower or 1500
    self.alive = true

    -- SpriteRenderer 初期化
    self:initializeSpriteRenderer(args.spriteSheet)

    -- スプライト
    local spriteWidth, spriteHeight = self:getSpriteSize(self.spriteName)
    local w = args.width or spriteWidth
    local h = args.height or spriteHeight

    -- Rectangle 初期化
    self:initializeRectangle(args.x, args.y, w, h, args.h_align, args.v_align)

    -- Transform 初期化
    self:initializeTransform(self.x, self.y, args.rotation, w / spriteWidth, h / spriteHeight)

    local x, y = args.collider:getPosition()

    -- Collider 初期化
    self:initializeCollider(args.collider)

    -- Collider 初期設定
    --self.collider:setMass(args.mass or 10)
    local mx, my, mass, inertia = self.collider:getMassData()
    local newMass = args.mass or mass
    self.collider:setMassData(mx, my, newMass, inertia * (newMass / mass))
    --self.collider:setLinearDamping(args.linearDamping or 10)
    --self.collider:setAngularDamping(args.angularDamping or 10)
    if args.collisionClass then
        self.collider:setCollisionClass(args.collisionClass)
    end
    self.collider:setSleepingAllowed(false)

    self.grounded = false
    self.groundedTime = 0
end

-- 破棄
function Character:destroy()
    self:gotoState(nil)
    self:destroyCollider()
end

-- 更新
function Character:update(dt)
    -- コライダーの位置を取得して適用
    self:applyPositionFromCollider()

    -- 足元を起点にしたいのでズラす
    self.y = self.y + self.offsetY

    -- アニメーション更新
    self:updateAnimation(dt)

    -- 着地判定
    self:updateGrounded()
end

-- 描画
function Character:draw()
    self:pushTransform(self:left(), self:top())
    love.graphics.setColor(self.color)
    self:drawSprite(self:getCurrentSpriteName())
    self:popTransform()

    love.graphics.print('x = ' .. self.x .. ', y = ' .. self.y, self.x, self.y)
    love.graphics.print('grounded: ' .. tostring(self:isGrounded()), self.x, self.y + 12)
    love.graphics.line(self.x, self.y, self.x, self.y + 20)
end

-- 描画
function Character:getCurrentSpriteName()
    return self:getCurrentAnimation()
end

-- 着地しているかどうか更新
function Character:updateGrounded()
    local vx, vy = self:getLinearVelocity()
    --print(vx, vy)

    local grounded = self.grounded
    if vy >= 0 then
        grounded = false
        local colliders = self.world:queryLine(self.x, self.y, self.x, self.y + 20, { 'platform' })
        for _, collider in ipairs(colliders) do
            grounded = true
        end
    end
    if grounded ~= self.grounded then
        self.grounded = grounded
    end
end

-- 着地しているかどうか返す
function Character:isGrounded()
    return self.grounded -- and self.groundedTime > 0.1
end

-- 立つ
function Character:stand()
    self:gotoState('stand')
end

-- 歩く
function Character:walk(direction)
    self:gotoState('walk', direction)
end

-- ジャンプ
function Character:jump()
    self:gotoState 'jump'
end

-- 死ぬ
function Character:die()
    self:gotoState 'dead'
end

-- 立ちステート
local Stand = Character:addState 'stand'

-- 立ち: ステート開始
function Stand:enteredState()
    self:resetAnimations(
        { self.spriteType .. '_stand.png' }
    )
end

-- 立ち: ジャンプ
function Stand:jump()
    if self:isGrounded() then
        self:gotoState 'jump'
    end
end

-- 歩きステート
local Walk = Character:addState 'walk'

-- 歩き: ステート開始
function Walk:enteredState(direction)
    self:resetAnimations(
        { self.spriteType .. '_walk1.png', self.spriteType .. '_walk2.png' },
        0.1
    )
    self._walk = {}
    self._walk.direction = direction or 'right'
end

-- 歩き: 更新
function Walk:update(dt)
    -- 移動
    self:applyLinearImpulse(self._walk.direction == 'right' and self.speed or -self.speed, 0)

    Character.update(self, dt)
end

-- 歩き: 歩く
function Walk:walk(direction)
    if direction ~= self._walk.direction then
        self:gotoState('walk', direction)
    end
end

-- ジャンプステート
local Jump = Character:addState 'jump'

-- ジャンプ: ステート開始
function Jump:enteredState()
    self:resetAnimations(
        { self.spriteType .. '_up1.png', self.spriteType .. '_up2.png' },
        0.1,
        1,
        false
    )

    -- ジャンプ
    self:applyLinearImpulse(0, -self.jumpPower)

    self.grounded = false
end

-- 更新
function Jump:update(dt)
    Character.update(self, dt)

    -- 着地したら立つ
    if self:isGrounded() then
        self:gotoState 'stand'
    end
end

-- ジャンプ: 立つ
function Jump:stand(...)
end

-- ジャンプ: 歩く
function Jump:walk(direction)
    if direction then
        self:applyLinearImpulse(direction == 'right' and self.speed or -self.speed, 0)
    end
end

-- ジャンプ: ジャンプ
function Jump:jump()
end

-- 死亡ステート
local Dead = Character:addState 'dead'

-- 死亡: ステート開始
function Dead:enteredState()
    self:resetAnimations(
        { self.spriteType .. '_dead.png' }
    )
    self.alive = false
end

-- 死亡: 立つ
function Dead:stand()
end

-- 死亡: 歩く
function Dead:walk()
end

-- 死亡: ジャンプ
function Dead:jump()
end

-- 死亡: 死ぬ
function Dead:die()
end


return Character
