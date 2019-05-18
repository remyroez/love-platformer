
local class = require 'middleclass'
local sti = require 'sti'
local wf = require 'windfield'
local lume = require 'lume'

-- エンティティ
local Level = class 'Level'

-- クラス
local Character = require 'Character'
local Player = require 'Player'
local Item = require 'Item'
local Background = require 'Background'

-- 敵クラス
local enemyClasses = {
    walker = require 'Walker',
    spikey = require 'Spikey',
    floater = require 'Floater',
}

-- コリジョンクラス
local collisionClasses = {
    -- 名前
    'frame',
    'player',
    'enemy',
    'friend',
    'collection',
    'damage',
    'object',
    'ladder',
    'platform',
    'one_way',
    'deadline',

    -- オプション
    frame = {},
    player = {},
    enemy = { ignores = { 'frame' } },
    friend = { ignores = { 'frame' } },
    collection = {},
    damage = {},
    object = {},
    ladder = {},
    platform = {},
    one_way = {},
    deadline = {},
}

-- 初期化
function Level:initialize(path)
    -- ワールド作成
    self.world = wf.newWorld(0, 1000, true)

    -- キャラクター
    self.characters = {}

    -- 獲得アイテム
    self.collection = {}

    -- コリジョンクラスの追加
    for index, name in ipairs(collisionClasses) do
        self.world:addCollisionClass(name, collisionClasses[name] or {})
        self.characters[name] = {}
    end

    -- マップ読み込み
    self.map = sti(path, { 'windfield' })
    self.map:windfield_init(self.world)

    -- マップ情報の取得
    self.left = 0
    self.right = 0
    self.top = 0
    self.bottom = 0
    local bgIndex = nil
    local customIndex = nil
    for index, layer in ipairs(self.map.layers) do
        if layer == self.map.layers['character'] then
            customIndex = index
        end
        if layer.type == 'tilelayer' then
            -- チャンクから上下左右の端を取得
            if layer.chunks then
                for __, chunk in ipairs(layer.chunks) do
                    if chunk.x < self.left then
                        self.left = chunk.x
                    end
                    if chunk.y < self.top then
                        self.top = chunk.y
                    end
                    if chunk.x + chunk.width > self.right then
                        self.right = chunk.x + chunk.width
                    end
                    if chunk.y + chunk.height > self.bottom then
                        self.bottom = chunk.y + chunk.height
                    end
                end
            end
        end
    end
    self.left = self.left * self.map.tilewidth
    self.right = self.right * self.map.tilewidth
    self.top = self.top * self.map.tileheight
    self.bottom = self.bottom * self.map.tileheight
    self.width = self.right - self.left
    self.height = self.bottom - self.top

    -- 外に出ないためのフレーム作成
    self.frames = {}
    do
        local rects = {
            { self.left - 8, self.top - 8, 8, self.height + 16 + 100, dir = 'left' },
            { self.left - 8, self.top - 8, self.width + 16, 8, dir = 'up' },
            { self.right, self.top - 8, 8, self.height + 16 + 100, dir = 'right' },
            { self.left - 8, self.bottom + 100, self.width + 16, 8, dir = 'down' },
        }
        for _, rect in ipairs(rects) do
            local r = rect
            local frame = self.world:newRectangleCollider(unpack(rect))
            if r.dir == 'down' then
                frame:setCollisionClass('deadline')
                frame:setType('kinematic')
            else
                frame:setCollisionClass('frame')
                frame:setType('static')
            end
            frame:setFriction(0)
            table.insert(self.frames, frame)
        end
    end

    -- カスタムレイヤー
    if customIndex then
        local level = self
        local layer = self.map:addCustomLayer('entity', customIndex)
        function layer:update(dt)
            lume.each(level.entities, 'update', dt)
        end
        function layer:draw()
            lume.each(level.entities, 'draw')
        end
    end

    -- タイルレイヤーのコリジョンをすべてプラットフォームに
    for _, collision in ipairs(self.map.windfield_collision) do
        if collision.collider.collision_class ~= 'Default' then
            -- 設定済み
        elseif collision.object.layer and collision.object.layer.type == 'tilelayer' then
            collision.collider:setCollisionClass('platform')
        elseif collision.baseObj and collision.baseObj.layer and collision.baseObj.layer.type == 'tilelayer' then
            collision.collider:setCollisionClass('platform')
        end
        collision.collider:setFriction(0)
    end

    -- 背景
    if self.map.layers.ground then
        self.background = Background(self.map.layers.ground.properties.set, self.width, self.height)
    end

    -- エンティティ
    self.entities = {}
    self.removes = {}

    -- デバッグモード
    self.debug = true
end

-- 破棄
function Level:destroy()
    self:clearEntities()
    self.world:destroy()
    if self.background then
        self.background:destroy()
    end
end

-- 更新
function Level:update(dt)
    self.world:update(dt)
    self.map:update(dt)
    self:removeEntities()
end

-- 描画
function Level:draw(x, y, scale)
    if self.background then
        self.background:draw()
    end

    -- マップ
    self.map:draw(x, y, scale)

    -- デバッグ描画
    if self.debug then
        self:drawDebug(x, y, scale)
    end
end

-- デバッグ描画
function Level:drawDebug(x, y, scale)
    -- ワールドのデバッグ描画
    self.world:draw()
end

-- デバッグモード設定
function Level:setDebug(enable)
    self.debug = enable
    lume.each(self.entities, function (entity) entity.debug = enable end)
end

-- マップキャンバスのリサイズ
function Level:resizeMapCanvas(w, h, scale)
    local width, height = love.graphics.getDimensions()
    w = w or width or 0
    h = h or height or 0
    self.map:resize(w / scale, h / scale)
    self.map.canvas:setFilter("linear", "linear")
end

-- キャラクターのセットアップ
function Level:setupCharacters(spriteSheet)
    self:removeCharacters('player')
    self:removeCharacters('enemy')

    -- character レイヤー
    local layer = self.map.layers['character']
    if layer == nil then
        return
    end
    layer.visible = false

    -- オブジェクトからキャラクター生成
    for _, object in ipairs(layer.objects) do
        -- キャラクターのスポーン
        local entity = self:spawnCharacter(object, spriteSheet)
    end
end

-- キャラクターのスポーン
function Level:spawnCharacter(object, spriteSheet)
    -- エンティティクラス
    local entityClass
    if object.type == 'player' then
        -- プレイヤー
        entityClass = Player
    elseif object.type == 'enemy' then
        -- エネミー
        entityClass = enemyClasses[object.properties.race or 'walker']
    end

    -- エンティティ用クラスを決定できなかったのでキャンセル
    if entityClass == nil then
        return
    end

    -- キャラクターエンティティの登録
    local entity = self:registerEntity(
        entityClass {
            object = object,
            spriteType = object.properties.sprite,
            spriteSheet = spriteSheet,
            x = object.x,
            y = object.y,
            offsetY = object.properties.offsetY,
            radius = object.properties.radius,
            collisionClass = object.properties.collisionClass,
            speed = object.properties.speed,
            jumpPower = object.properties.jumpPower,
            world = self.world,
            h_align = object.properties.h_align,
            v_align = object.properties.v_align,
            onDead = function (entity) table.insert(self.removes, entity) end,
            debug = self.debug,
        }
    )

    -- キャラクターテーブルに登録
    if self.characters[object.type] then
        table.insert(self.characters[object.type], entity)
    else
        print('invalid object type [' .. object.type .. ']')
    end

    return entity
end

-- アイテムのセットアップ
function Level:setupItems(spriteSheet)
    self:removeCharacters('collection')

    -- character レイヤー
    local layer = self.map.layers['collection']
    if layer == nil then
        return
    end
    layer.visible = false

    -- オブジェクトからキャラクター生成
    for _, object in ipairs(layer.objects) do
        -- キャラクターのスポーン
        local entity = self:spawnItem(object, spriteSheet)
    end
end

-- アイテムのスポーン
function Level:spawnItem(object, spriteSheet)
    local entity = self:registerEntity(
        Item {
            object = object,
            item = object.properties.item,
            spriteType = object.properties.sprite,
            spriteSheet = spriteSheet,
            x = object.x,
            y = object.y,
            offsetY = object.properties.offsetY,
            radius = object.properties.radius,
            world = self.world,
            collisionClass = object.properties.collisionClass,
            h_align = object.properties.h_align,
            v_align = object.properties.v_align,
            onGet = function (entity) self:collectItem(entity) end,
            onCollected = function (entity) table.insert(self.removes, entity) end,
            debug = self.debug,
        }
    )

    -- キャラクターテーブルに登録
    if self.characters[object.type] then
        table.insert(self.characters[object.type], entity)
    else
        print('invalid object type [' .. object.type .. ']')
    end

    return entity
end


-- エンティティの追加
function Level:registerEntity(entity)
    table.insert(self.entities, entity)
    return entity
end

-- エンティティの削除
function Level:deregisterEntity(entity)
    entity:destroy()
    lume.remove(self.entities, entity)

    for type, list in pairs(self.characters) do
        lume.remove(list, entity)
    end
end

-- 削除リストにいるエンティティを全て削除
function Level:removeEntities()
    for _, entity in pairs(self.removes) do
        self:deregisterEntity(entity)
    end
    lume.clear(self.removes)
end

-- 全エンティティの削除
function Level:clearEntities()
    lume.each(self.entities, 'destroy')
    lume.clear(self.entities)

    for type, list in pairs(self.characters) do
        lume.clear(list)
    end
end

-- キャラクターリストの取得
function Level:getCharacters(category)
    return self.characters[category]
end

-- 特定のキャラクターを全て削除リストに追加
function Level:removeCharacters(category)
    self.removes = lume.concat(self.removes, self:getCharacters(category))
end

-- プレイヤーリストの取得
function Level:getPlayers()
    return self:getCharacters('player')
end

-- プレイヤーの取得
function Level:getPlayer()
    return lume.first(self:getPlayers())
end

-- アイテムの獲得
function Level:collectItem(item)
    if self.collection[item.item] == nil then
        self.collection[item.item] = {}
    end
    if self.collection[item.item][item.spriteType] == nil then
        self.collection[item.item][item.spriteType] = 0
    end
    self.collection[item.item][item.spriteType] = self.collection[item.item][item.spriteType] + 1
end

return Level
