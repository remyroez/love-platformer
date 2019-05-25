
local class = require 'middleclass'

-- クラス
local Enemy = require 'Enemy'

-- ウォーカー
local Walker = class('Walker', Enemy)

-- 初期化
function Walker:initialize(args)
    -- デフォルト値
    args.state = args.state or 'walk'
    args.speed = args.speed or 20
    args.stateArgs = args.stateArgs or { args.object.properties.direction or 'left' }
    --args.life = args.life or 3

    -- 親クラス初期化
    Enemy.initialize(self, args)
end

-- ダメージ
function Walker:damage(damage, direction)
    self:gotoState('damage', damage, direction)
end

-- 立ちステート
local Stand = Walker:addState 'stand'

-- 立ち: ステート開始
function Stand:enteredState()
    self:resetAnimations(
        { 'enemyWalking_1.png' }
    )
end

-- 歩きステート
local Walk = Walker:addState 'walk'

-- 歩き: ステート開始
function Walk:enteredState(direction)
    self:resetAnimations(
        { 'enemyWalking_1.png', 'enemyWalking_2.png' },
        0.1
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
        Walker.update(self, dt)
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

    Walker.update(self, dt)
end

-- 歩き: 歩く
function Walk:walk(direction)
    if direction ~= self._walk.direction then
        self:gotoState('walk', direction)
    end
end

-- ダメージステート
local Damage = Walker:addState 'damage'

-- ダメージ: ステート開始
function Damage:enteredState(damage, direction)
    self:resetAnimations(
        { 'enemyWalking_4.png' }
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

return Walker
