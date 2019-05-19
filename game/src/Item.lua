
local class = require 'middleclass'

local Timer = require 'Timer'

-- アイテム
local Item = class('Item', require 'Entity')
Item:include(require 'stateful')
Item:include(require 'Rectangle')
Item:include(require 'SpriteRenderer')
Item:include(require 'Transform')
Item:include(require 'Collider')
Item:include(require 'SoundPlayer')

-- 一部のスプライト名
local itemColor = {
    red = 'Red',
    green = 'Green',
}

-- 初期化
function Item:initialize(args)
    self.initialized = false

    self.timer = Timer()

    -- オブジェクト
    self.object = args.object

    -- SoundPlayer 初期化
    self:initializeSoundPlayer(args.sounds)

    -- スプライト及びステート
    self.item = args.item or 'jewel'
    self.spriteType = args.spriteType or 'red'
    self:gotoState(self.item)

    -- 初期設定
    self.spriteName = self:getCurrentSpriteName()
    self.color = args.color or { 1, 1, 1, 1 }
    self.radius = args.radius or 16
    self.score = args.score or 0
    self.world = args.world
    self.got = false
    self.visible = true

    self.onGet = args.onGet or function () end
    self.onCollected = args.onCollected or function () end

    -- SpriteRenderer 初期化
    self:initializeSpriteRenderer(args.spriteSheet)

    -- スプライト
    local spriteWidth, spriteHeight = self:getSpriteSize(self.spriteName)
    local w = args.width or spriteWidth
    local h = args.height or spriteHeight

    -- Rectangle 初期化
    self:initializeRectangle(args.x, args.y, w, h, args.h_align or 'center', args.v_align or 'middle')

    -- Transform 初期化
    self:initializeTransform(self.x, self.y, args.rotation, w / spriteWidth, h / spriteHeight)

    -- ベーススケール
    self.baseScaleX, self.baseScaleY = self.scaleX, self.scaleY

    -- Collider 初期化
    self:initializeCollider(args.collider or self.world:newCircleCollider(0, 0, self.radius))

    -- Collider 初期設定
    self.collider:setObject(self)
    self.collider:setFixedRotation(true)
    self.collider:setGravityScale(0)
    self.collider:setCollisionClass(args.collisionClass or 'collection')

    -- 接触先によって当たり判定を調整する
    self.collider:setPreSolve(
        function(collider_1, collider_2, contact)
            contact:setEnabled(false)
        end
    )

    -- デバッグフラグ
    self.debug = args.debug ~= nil and args.debug or false

    -- 初期化完了
    self.initialized = true
end

-- 破棄
function Item:destroy()
    self.timer:destroy()
    self:gotoState(nil)
    self:destroyCollider()
end

-- 更新
function Item:update(dt)
    -- コライダーの位置を取得して適用
    self:applyPositionFromCollider()

    self.timer:update(dt)
end

-- 描画
function Item:draw()
    -- スプライト描画
    if self.visible then
        self:pushTransform(self:left(), self:top())
        love.graphics.setColor(self.color)
        --[[
        if self:getEmptySpriteName() then
            self:drawSprite(self:getEmptySpriteName())
        end
        --]]
        if self:getCurrentSpriteName() then
            self:drawSprite(self:getCurrentSpriteName())
        end
        self:popTransform()
    end

    -- デバッグ描画
    if self.debug then
        self:drawDebug()
    end
end

-- デバッグ描画
function Item:drawDebug()
end

-- 現在のスプライト名
function Item:getCurrentSpriteName()
    return nil
end

-- 空のスプライト名
function Item:getEmptySpriteName()
    return nil
end

-- 取得時のＳＥ名
function Item:getCollectSoundName()
    return 'gem'
end

-- 取得（取った瞬間）
function Item:get()
    -- 獲得済みなら何もしない
    if self.got then
        return
    end

    -- 獲得処理
    self.got = true
    self.onGet(self)

    -- 消える処理
    self.timer:tween(
        0.5,
        self,
        { color = { [4] = 0 } },
        'in-out-cubic',
        function ()
            self:collect()
        end
    )
    self.collider:setGravityScale(1)
    self:applyLinearImpulse(0, -300)

    -- ＳＥ
    self:playSound(self:getCollectSoundName())
end

-- 取得（獲得した）
function Item:collect()
    self.onCollected(self)
end

-- 宝石（小）ステート
local Jewel = Item:addState 'jewel'

-- 宝石（小）: 現在のスプライト名
function Jewel:getCurrentSpriteName()
    return self.spriteType .. 'Jewel.png'
end

-- 宝石（小）: 空のスプライト名
function Jewel:getEmptySpriteName()
    return 'outlineJewel.png'
end

-- 宝石（中）ステート
local Gem = Item:addState 'gem'

-- 宝石（中）: 現在のスプライト名
function Gem:getCurrentSpriteName()
    return self.spriteType .. 'Gem.png'
end

-- 宝石（中）: 空のスプライト名
function Gem:getEmptySpriteName()
    return 'outlineGem.png'
end

-- 宝石（大）ステート
local Crystal = Item:addState 'crystal'

-- 宝石（大）: 現在のスプライト名
function Crystal:getCurrentSpriteName()
    return self.spriteType .. 'Crystal.png'
end

-- 宝石（大）: 空のスプライト名
function Crystal:getEmptySpriteName()
    return 'outlineCrystal.png'
end

-- ディスクステート
local Disc = Item:addState 'disc'

-- ディスク: 現在のスプライト名
function Disc:getCurrentSpriteName()
    local spriteType = itemColor[self.spriteType] or 'Red'
    return 'disc' .. spriteType .. '.png'
end

-- ディスク: 空のスプライト名
function Disc:getEmptySpriteName()
    return 'outlineDisc_alt.png'
end

-- ディスク: 取得時のＳＥ名
function Disc:getCollectSoundName()
    return 'key'
end

-- キーステート
local Key = Item:addState 'key'

-- キー: 現在のスプライト名
function Key:getCurrentSpriteName()
    local spriteType = itemColor[self.spriteType] or 'Red'
    return 'key' .. spriteType .. '.png'
end

-- キー: 空のスプライト名
function Key:getEmptySpriteName()
    return 'outlineKey.png'
end

-- キー: 取得時のＳＥ名
function Key:getCollectSoundName()
    return 'key'
end

-- パズルステート
local Puzzle = Item:addState 'puzzle'

-- パズル: 現在のスプライト名
function Puzzle:getCurrentSpriteName()
    local spriteType = itemColor[self.spriteType] or 'Red'
    return 'puzzle' .. spriteType .. '.png'
end

-- パズル: 空のスプライト名
function Puzzle:getEmptySpriteName()
    return 'outlinePuzzle.png'
end

-- パズル: 取得時のＳＥ名
function Puzzle:getCollectSoundName()
    return 'key'
end

return Item
