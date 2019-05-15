
local class = require 'middleclass'

-- クラス
local Enemy = require 'Enemy'

-- ウォーカー
local Walker = class('Walker', Enemy)

-- 初期化
function Walker:initialize(args)
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

return Walker
