
local class = require 'middleclass'

-- クラス
local Enemy = require 'Enemy'

-- ウォーカー
local Walker = class('Walker', Enemy)

-- 初期化
function Walker:initialize(args)
    -- デフォルト値
    args.state = args.state or 'walk'
    args.speed = args.speed or 10
    args.stateArgs = args.stateArgs or { args.object.properties.direction or 'left' }

    -- 親クラス初期化
    Enemy.initialize(self, args)
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
    -- 着地してないなら動かない
    if not self:isGrounded() then
        Walker.update(self, dt)
        return
    end

    -- 向きを変えるか判定
    local turn = false

    -- 足元に足場がない
    do
        local radius = self._walk.direction == 'right' and self.radius or -self.radius
        local colliders = self.world:queryLine(self.x + radius, self.y, self.x + radius, self.y + 10, { 'platform', 'one_way' })
        if #colliders == 0 then
            turn = true
        end
    end

    -- 進行方向に障害がある
    if not turn then
        local radius = self._walk.direction == 'right' and self.radius or -self.radius
        local offset = self._walk.direction == 'right' and 3 or -3
        local colliders = self.world:queryLine(self.x + radius, self.y - self.radius, self.x + radius + offset, self.y - self.radius, { 'platform' })
        if #colliders > 0 then
            turn = true
        end
    end

    -- 他の敵に接触した
    if not turn and self:enterCollider('enemy') then
        turn = true
    end

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

return Walker
