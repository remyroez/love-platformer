
local lume = require 'lume'

-- コライダーモジュール
local Collider = {}

-- 初期化
function Collider:initializeCollider(collider)
    self.x = self.x or 0
    self.y = self.y or 0
    self.collider = collider

    -- コライダー初期設定
    self.collider:setObject(self)
    self:applyPositionToCollider()
end

-- 破棄
function Collider:destroyCollider()
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end
end

-- コライダーの有効状態設定
function Collider:setColliderActive(active)
    if self.collider then
        self.collider:setActive(active == nil and true or active)
    end
end

-- コライダー速度の設定
function Collider:setColliderVelocity(x, y, speed)
    if self.collider == nil then
        -- no collider
    elseif (x == 0 and y == 0) or speed == 0 then
        self.collider:setLinearVelocity(0, 0)
    else
        self.collider:setLinearVelocity(lume.vector(lume.angle(self.x, self.y, self.x + x, self.y + y), speed))
    end
end

-- コライダーへ座標を適用
function Collider:applyPositionToCollider()
    if self.collider then
        self.collider:setPosition(self.x, self.y)
    end
end

-- コライダーから座標を適用
function Collider:applyPositionFromCollider()
    if self.collider then
        self.x, self.y = self.collider:getPosition()
    end
end

-- setLinearVelocity
function Collider:setLinearVelocity(x, y)
    if self.collider then
        self.collider:setLinearVelocity(x, y)
    end
end

-- getLinearVelocity
function Collider:getLinearVelocity()
    if self.collider == nil then
        -- no collider
        return 0, 0
    else
        return self.collider:getLinearVelocity()
    end
end

-- applyLinearImpulse
function Collider:applyLinearImpulse(x, y)
    if self.collider then
        self.collider:applyLinearImpulse(x, y)
    end
end

-- コライダーのスリープ状態設定
function Collider:awakeCollider(awake)
    if self.collider then
        self.collider:setAwake(awake == nil and true or awake)
    end
end

-- コライダーの接触判定
function Collider:enterCollider(collisionClass)
    if self.collider then
        return self.collider:enter(collisionClass)
    else
        return false
    end
end

-- コライダーの接触情報取得
function Collider:getEnterCollisionData(collisionClass)
    if self.collider then
        return self.collider:getEnterCollisionData(collisionClass)
    else
        return nil
    end
end

-- コリジョンイベントの取得
function Collider:getCollisionEvents(collisionClass)
    if self.collider then
        return self.collider.collision_events[collisionClass]
    else
        return nil
    end
end

-- コライダーの形状追加
function Collider:addColliderShape(...)
    if self.collider then
        self.collider:addShape(...)
    end
end

-- コライダーの形状削除
function Collider:removeColliderShape(...)
    if self.collider then
        self.collider:removeShape(...)
    end
end

return Collider
