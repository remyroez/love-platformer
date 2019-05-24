
local class = require 'middleclass'

-- クラス
local Enemy = require 'Enemy'

-- ウォーカー
local Spikey = class('Spikey', Enemy)

-- 初期化
function Spikey:initialize(args)
    -- デフォルト値
    args.state = args.state or 'walk'
    args.speed = args.speed or 10
    args.stateArgs = args.stateArgs or { args.object.properties.direction or 'left' }

    -- 長いタイプかどうか
    self.long = args.object.properties.long ~= nil and args.object.properties.long or false

    -- 親クラス初期化
    Enemy.initialize(self, args)

    -- シェイプの追加
    if self.long then
        self:addColliderShape('long', 'CircleShape', 0, -self.radius * 1.5, self.radius)
    end
end

-- ダメージ
function Spikey:damage(damage, direction, attacker)
    attacker:damage(self.attack, direction, self)
end

-- 立ちステート
local Stand = Spikey:addState 'stand'

-- 立ち: ステート開始
function Stand:enteredState()
    self:resetAnimations(
        { self.long and 'enemySpikey_3.png' or 'enemySpikey_1.png' }
    )
end

-- 歩きステート
local Walk = Spikey:addState 'walk'

-- 歩き: ステート開始
function Walk:enteredState(direction)
    self:resetAnimations(
        { self.long and 'enemySpikey_3.png' or 'enemySpikey_1.png' }
    )

    -- 未初期化なら延期
    if not self.initialized then
        self.postponeEnterState = true
        return
    end

    self._walk = self._walk or {}
    self._walk.direction = direction or self._walk.direction or 'right'
    self.scaleX = direction == 'left' and -self.baseScaleX or self.baseScaleX
end

-- 歩き: ステート終了
function Walk:exitedState()
    self.scaleX = self.baseScaleX
end

-- 歩き: 更新
function Walk:update(dt)
    -- 着地してないなら動かない
    if not self:isGrounded() then
        Spikey.update(self, dt)
        return
    end

    -- 向きを変えるか判定
    local turn =
        self:checkEntity(self._walk.direction)
        or self:checkObstacle(self._walk.direction)
        or self:checkPlatform(self._walk.direction)

    -- 向きを変える
    if turn then
        if self._walk.direction == 'right' then
            self._walk.direction = 'left'
        else
            self._walk.direction = 'right'
        end
        self.scaleX = self._walk.direction == 'left' and -self.baseScaleX or self.baseScaleX
    end

    -- 移動
    self:applyLinearImpulse(self._walk.direction == 'right' and self.speed or -self.speed, 0)

    Spikey.update(self, dt)
end

-- 歩き: 歩く
function Walk:walk(direction)
    if direction ~= self._walk.direction then
        self:gotoState('walk', direction)
    end
end

-- ダメージステート
local Damage = Spikey:addState 'damage'

-- ダメージ: ステート開始
function Damage:enteredState(damage, direction)
    self:resetAnimations(
        { 'enemySpikey_4.png' }
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
        self.grounded = false

        -- 退場
        self.leave = true

        -- 退場時
        self.onDying(self)
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
                self:gotoState 'walk'
            end
        )
    end

    -- ＳＥ
    self:playSound('attack')
end

-- ダメージ: ダメージ
function Damage:damage(damage, direction)
end

return Spikey
