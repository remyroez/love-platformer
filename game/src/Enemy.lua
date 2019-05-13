
local class = require 'middleclass'

-- クラス
local Character = require 'Character'

-- エネミー
local Enemy = class('Enemy', Character)

-- 初期化
function Enemy:initialize(args)
    Character.initialize(self, args)
end

return Enemy
