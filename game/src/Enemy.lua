
local class = require 'middleclass'

-- クラス
local Character = require 'Character'

-- エネミー
local Enemy = class('Enemy', Character)

-- 初期化
function Enemy:initialize(args)
    Character.initialize(self, args)
end

-- 立ちステート
local Stand = Enemy:addState 'stand'

-- 立ち: ステート開始
function Stand:enteredState()
    self:resetAnimations(
        { 'enemyWalking_1.png' }
    )
end

return Enemy
