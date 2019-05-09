
local class = require 'middleclass'

-- キャラクター
local Character = class('Character', require 'Entity')
Character:include(require 'stateful')
Character:include(require 'Rectangle')
Character:include(require 'SpriteRenderer')
Character:include(require 'Transform')
Character:include(require 'Collider')

-- 初期化
function Character:initialize(args)
    -- 初期設定
    self.spriteType = args.spriteType or 'playerRed'
    self.spriteName = self:getCurrentSpriteName()
    self.color = args.color or { 1, 1, 1, 1 }
    self.offsetY = args.offsetY or 0
    self.world = args.world or {}

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
    self:destroyCollider()
end

-- 更新
function Character:update(dt)
    -- コライダーの位置を取得して適用
    self:applyPositionFromCollider()

    -- 足元を起点にしたいのでズラす
    self.y = self.y + self.offsetY

    -- 着地判定
    local grounded = false
    local colliders = self.world:queryLine(self.x, self.y, self.x, self.y + 20, { 'platform' })
    for _, collider in ipairs(colliders) do
        grounded = true
    end
    if grounded ~= self.grounded then
        self.grounded = grounded
        self.groundedTime = dt
    elseif self.grounded then
        self.groundedTime = self.groundedTime + dt
    end
end

-- 描画
function Character:draw()
    self:pushTransform(self:left(), self:top())
    love.graphics.setColor(self.color)
    self:drawSprite(self.spriteName)
    self:popTransform()

    love.graphics.print('grounded: ' .. tostring(self:isGrounded()), self.x, self.y)
    love.graphics.line(self.x, self.y, self.x, self.y + 20)
end

-- 描画
function Character:getCurrentSpriteName()
    return self.spriteType .. '_stand.png'
end

-- 着地しているかどうか返す
function Character:isGrounded()
    return self.grounded -- and self.groundedTime > 0.1
end

-- ジャンプ
function Character:jump()

end

return Character
