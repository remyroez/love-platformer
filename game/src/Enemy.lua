
local class = require 'middleclass'

-- クラス
local Character = require 'Character'

-- エネミー
local Enemy = class('Enemy', Character)

-- 初期化
function Enemy:initialize(args)
    -- デフォルト値
    args.spriteType = args.spriteType or 'enemy'
    args.collisionClass = args.collisionClass or 'enemy'
    args.score = args.score or 100

    -- 親クラス初期化
    Character.initialize(self, args)
end

-- 足場の判定
function Enemy:checkPlatform(direction)
    local turn = false

    local radius = direction == 'right' and self.radius or -self.radius
    local colliders = self.world:queryLine(self.x + radius, self.y, self.x + radius, self.y + 10, { 'platform', 'one_way' })
    if #colliders == 0 then
        turn = true
    end

    return turn
end

-- 障害物の判定
function Enemy:checkObstacle(direction, collisionClass)
    collisionClass = collisionClass or 'platform'

    local turn = false

    if self:enterCollider(collisionClass) then
        -- platform と接触
        local events = self:getCollisionEvents(collisionClass)
        if events and #events > 0  then
            for _, e in ipairs(events) do
                if e.collision_type == 'enter' then
                    -- 接触開始
                    local collision = e.collider_2:getObject()
                    local y = self.y - self.radius
                    local w = collision.bottom - collision.top
                    local h = collision.right - collision.left
                    local px = collision.left + w / 2
                    local py = collision.top + h / 2
                    if collision.top > y or collision.bottom < y then
                        -- 高さが合っていない
                    elseif px > self.x and direction == 'right' then
                        -- 右方向に進んでいる時に右側に障害があった
                        turn = true
                        break
                    elseif px < self.x and direction == 'left' then
                        -- 左方向に進んでいる時に右側に障害があった
                        turn = true
                        break
                    end
                end
            end
        end
    end

    return turn
end

-- エンティティとの接触の判定
function Enemy:checkEntity(direction, collisionClass)
    collisionClass = collisionClass or 'enemy'

    local turn = false

    if self:enterCollider(collisionClass) then
        local data = self:getEnterCollisionData(collisionClass)
        local enemy = data.collider:getObject()
        if enemy == nil then
            -- エネミー情報が取れなかった
        elseif enemy.x > self.x and direction == 'right' then
            turn = true
        elseif enemy.x < self.x and direction == 'left' then
            turn = true
        end
    end

    return turn
end

return Enemy
