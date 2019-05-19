
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

return Enemy
