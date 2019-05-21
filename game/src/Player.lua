
local class = require 'middleclass'
local lume = require 'lume'

-- クラス
local Character = require 'Character'

-- プレイヤー
local Player = class('Player', Character)

-- 初期化
function Player:initialize(args)
    -- デフォルト値
    args.spriteType = args.spriteType or 'playerRed'
    args.collisionClass = args.collisionClass or 'player'
    args.life = args.life or 3

    -- 親クラス初期化
    Character.initialize(self, args)

    -- 接触先によって当たり判定を調整する
    self.collider:setPreSolve(
        function(collider_1, collider_2, contact)
            if collider_1.collision_class ~= self.collider.collision_class then
                -- 自分ではない？
            elseif self.leave and collider_2.collision_class ~= 'deadline' then
                -- 退場時はデッドライン以外はスルー
                contact:setEnabled(false)
            elseif collider_2.collision_class == 'enemy' then
                -- スルー
                contact:setEnabled(false)
            elseif collider_2.collision_class == 'one_way' then
                if self:isClimbing() then
                    -- 登っている間は通り抜ける
                    contact:setEnabled(false)
                else
                    -- 下からは通過する
                    local px, py = collider_1:getPosition()
                    local character = collider_1:getObject()
                    local ph = character and character.radius or 16
                    local collision = collider_2:getObject()
                    local tx, ty = collision.left, collision.top
                    if py + ph/2 > ty then
                        contact:setEnabled(false)
                    end
                end
            elseif collider_2.collision_class == 'ladder' then
                -- ハシゴは当たり判定なし
                contact:setEnabled(false)
            elseif collider_2.collision_class == 'goal' then
                -- ゴールは当たり判定なし
                contact:setEnabled(false)
            end
        end
    )

    -- ハシゴ判定
    self.inLadderCount = 0
end

-- 前更新
function Player:preUpdate(dt)
    self:reduceSpeed()
    self:applyAlternativeGravity()
    self:checkLadder()

    if self.alive then
        self:checkEnemy()
        self:checkDamage()
        self:checkItem()
        self:checkGoal()
    end
end

-- デバッグ描画
function Player:drawDebug()
    love.graphics.print('x = ' .. self.x .. ', y = ' .. self.y, self.x, self.y)
    love.graphics.print('alive: ' .. tostring(self.alive), self.x, self.y + 12)
    love.graphics.print('grounded: ' .. tostring(self:isGrounded()), self.x, self.y + 24)
    love.graphics.print('ladder: ' .. tostring(self.inLadderCount), self.x, self.y + 36)
    love.graphics.line(self.x, self.y, self.x, self.y + 10)
end

-- ハシゴの接触チェック
function Player:checkLadder()
    local events = self:getCollisionEvents('ladder')
    if events and #events > 0  then
        for _, e in ipairs(events) do
            if e.collision_type == 'enter' then
                self.inLadderCount = self.inLadderCount + 1
            elseif e.collision_type == 'exit' then
                self.inLadderCount = self.inLadderCount - 1
            end
        end
    end
end

-- 敵の接触チェック
function Player:checkEnemy()
    if self.invincible then
        -- 無敵
    elseif self:enterCollider('enemy') then
        local data = self:getEnterCollisionData('enemy')
        local enemy = data.collider:getObject()
        if enemy and enemy.alive then
            local vx, vy = lume.vector(lume.angle(self.x, self.y, enemy.x, enemy.y), 1)
            local dot = vx * 0 + vy * 1
            local dir = self.x > enemy.x and 'right' or self.x < enemy.x and 'left' or nil
            if dot < 0.5 then
                self:damage(enemy.attack, dir, enemy)
            else
                self:gotoState 'jump'
                enemy:damage(self.attack, dir, self)
            end
        end
    end
end

-- ダメージ床チェック
function Player:checkDamage()
    if self.invincible then
        -- 無敵
    elseif self:enterCollider('damage') then
        local vx, vy = state.player:getLinearVelocity()
        self:damage(1, vx > 0 and 'right' or vx < 0 and 'left' or nil)
    end
end

-- アイテムチェック
function Player:checkItem()
    if self:enterCollider('collection') then
        local data = self:getEnterCollisionData('collection')
        local item = data.collider:getObject()
        if item and not item.got then
            item:get()
        end
    end
end

-- ゴールチェック
function Player:checkGoal()
    if self:enterCollider('goal') then
        if self.onGoal then
            self.onGoal(self)
            self.onGoal = nil
            self.invincible = true
        end
    end
end

-- ハシゴに接触しているかどうか返す
function Player:inLadder()
    return self.inLadderCount > 0
end

-- ハシゴを登っているかどうか
function Player:isClimbing()
    return false
end

-- 立つ
function Player:stand()
    self:gotoState('stand')
end

-- 歩く
function Player:walk(direction)
    self:gotoState('walk', direction)
end

-- ジャンプ
function Player:jump()
    self:gotoState 'jump'
end

-- はしごを登る
function Player:climb(direction)
    -- はしごがあるかどうか
    local onLadder = false
    -- 下方向
    do
        local colliders = self.world:queryLine(self.x, self.y, self.x, self.y + 10, { 'ladder' })
        if #colliders > 0 then
            onLadder = direction == 'down'
        end
    end
    -- 上方向
    if not onLadder then
        local colliders = self.world:queryLine(self.x, self.y, self.x, self.y - self.radius - 64, { 'ladder' })
        if #colliders > 0 then
            onLadder = direction == 'up'
        end
    end
    if self:inLadder() and onLadder then
        self:gotoState 'ladder'
        return true
    end
    return false
end

-- ダメージ
function Player:damage(damage, direction)
    self:gotoState('damage', damage, direction)
end

-- 死ぬ
function Player:die()
    self:gotoState 'dead'
end

-- 立ちステート
local Stand = Player:addState 'stand'

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
local Walk = Player:addState 'walk'

-- 歩き: ステート開始
function Walk:enteredState(direction)
    self:resetAnimations(
        { self.spriteType .. '_walk1.png', self.spriteType .. '_walk2.png' },
        0.1
    )
    self._walk = {}
    self._walk.direction = direction or 'right'
    self.scaleX = direction == 'left' and -self.baseScaleX or self.baseScaleX
end

-- 歩き: ステート終了
function Walk:exitedState()
    self.scaleX = self.baseScaleX
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

-- ハシゴステート
local Ladder = Player:addState 'ladder'

-- ハシゴ: ステート開始
function Ladder:enteredState()
    self:resetAnimations(
        { self.spriteType .. '_swim1.png', self.spriteType .. '_swim2.png' },
        0.1
    )
    self:setLinearVelocity(0, 0)
    self.collider:setGravityScale(0)
    self.animation = false
end

-- ハシゴ: ステート終了
function Ladder:exitedState()
    self.scaleX = self.baseScaleX
    self.collider:setGravityScale(1)
    self.animation = true
end

-- ハシゴ: 更新
function Ladder:update(dt)
    Character.update(self, dt)

    self.animation = false

    -- ハシゴから離れた
    if not self:inLadder() then
        self:gotoState 'stand'
    end
end

-- 落下しているかどうか返す
function Ladder:isFalling()
    return true
end

-- ハシゴ: ハシゴを登っているかどうか
function Ladder:isClimbing()
    return true
end

-- ハシゴ: 減速
function Ladder:reduceSpeed()
    local vx, vy = self:getLinearVelocity()
    self:setLinearVelocity(vx * 0.8, vy * 0.8)
end

-- ハシゴ: 地面に押し付ける
function Ladder:applyAlternativeGravity()
end

-- ハシゴ: 立つ
function Ladder:stand(...)
end

-- ハシゴ: 歩く
function Ladder:walk(direction)
    if direction then
        self:applyLinearImpulse(
            direction == 'right' and self.speed or direction == 'left' and -self.speed or 0,
            0
        )
        self.scaleX = direction == 'left' and -self.baseScaleX or self.baseScaleX
        self.animation = true
    end
end

-- ハシゴ: 登る
function Ladder:climb(direction)
    -- 上方向
    local onLadder = false
    do
        local colliders = self.world:queryLine(self.x - self.radius, self.y, self.x - self.radius, self.y - self.radius - 64, { 'ladder' })
        onLadder =  #colliders > 0
    end
    if not onLadder then
        local colliders = self.world:queryLine(self.x + self.radius, self.y, self.x + self.radius, self.y - self.radius - 64, { 'ladder' })
        onLadder =  #colliders > 0
    end

    if not direction then
        -- 方向なし
    elseif direction == 'down' and self:isGrounded() and onLadder then
        -- 着地中に下へ移動
        self:gotoState 'stand'
    else
        self:applyLinearImpulse(
            0,
            direction == 'down' and self.speed or direction == 'up' and -self.speed or 0
        )
        self.animation = true
    end
    return true
end

-- ジャンプステート
local Jump = Player:addState 'jump'

-- ジャンプ: ステート開始
function Jump:enteredState()
    self:resetAnimations(
        { self.spriteType .. '_up1.png', self.spriteType .. '_up2.png' },
        0.1,
        1,
        false
    )

    -- Ｙ軸の速度をカット
    local vx, vy = self:getLinearVelocity()
    self:setLinearVelocity(vx, 0)

    -- ジャンプ
    self:applyLinearImpulse(0, -self.jumpPower)

    -- 空中へ
    self.grounded = false

    -- ＳＥ
    self:playSound('jump')
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
local Dead = Player:addState 'dead'

-- 死亡: ステート開始
function Dead:enteredState()
    self:resetAnimations(
        { self.spriteType .. '_dead.png' }
    )
    self.alive = false
    self.onDead(self)
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

-- 死亡: ダメージ
function Dead:damage()
end

-- 死亡: 死ぬ
function Dead:die()
end

-- ダメージステート
local Damage = Player:addState 'damage'

-- ダメージ: ステート開始
function Damage:enteredState(damage, direction)
    self:resetAnimations(
        { self.spriteType .. '_dead.png' }
    )

    -- ダメージを受ける
    self.life = self.life - (damage or 1)

    -- 死んだら退場
    if self.life <= 0 then
        self.leave = true
        --self:setColliderActive(false)
    end

    -- 飛ばされる方向
    self._damage = {}
    self._damage.direction = direction

    -- Ｙ軸の速度をカット
    local vx, vy = self:getLinearVelocity()
    self:setLinearVelocity(vx, 0)

    -- ジャンプ
    self:applyLinearImpulse(0, -self.jumpPower * 0.75)
    self.grounded = false

    -- ＳＥ
    self:playSound('damage')
end

-- ダメージ: 更新
function Damage:update(dt)
    -- 移動
    local x = 0
    if self._damage.direction == 'right' then
        x = self.speed
    elseif self._damage.direction == 'left' then
        x = -self.speed
    end
    if x ~= 0 then
        self:applyLinearImpulse(x, 0)
    end

    Character.update(self, dt)

    -- 着地したら次へ
    if not self:isGrounded() then
        -- 空中
    elseif self.life <= 0 then
        --self:die()
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
            end
        )
        self:gotoState 'stand'
    end
end

-- ダメージ: 敵の接触チェック
function Damage:checkEnemy()
end

-- ダメージ: 立つ
function Damage:stand()
end

-- ダメージ: 歩く
function Damage:walk()
end

-- ダメージ: ジャンプ
function Damage:jump()
end

-- ダメージ: ダメージ
function Damage:damage()
end

return Player
