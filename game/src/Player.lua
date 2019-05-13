
local class = require 'middleclass'

-- クラス
local Character = require 'Character'

-- プレイヤー
local Player = class('Player', Character)

-- 初期化
function Player:initialize(args)
    Character.initialize(self, args)
end

return Player
