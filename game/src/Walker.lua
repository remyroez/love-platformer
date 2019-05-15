
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
