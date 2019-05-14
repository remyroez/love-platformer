
local class = require 'middleclass'
local sti = require 'sti'
local wf = require 'windfield'
local lume = require 'lume'

-- エンティティ
local Level = class 'Level'

-- クラス
local Character = require 'Character'
local Player = require 'Player'
local Enemy = require 'Enemy'

-- コリジョンクラス
local collisionClasses = {
    -- 名前
    'frame',
    'player',
    'enemy',
    'friend',
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
end

-- 更新
function Level:update(dt)
    self.world:update(dt)
    self.map:update(dt)
    self:removeEntities()
end

-- 描画
function Level:draw(x, y, scale)
    -- マップ
    self.map:draw(x, y, scale)

    -- ワールドのデバッグ描画
    if self.debug then
        self.world:draw()
    end
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
    self:clearEntities()

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
    -- デフォルトプロパティ
    local default = {}
    if object.type == 'player' then
        -- プレイヤー
        default.class = Player
        default.sprite = 'playerRed'
        default.collisionClass = 'player'
    elseif object.type == 'enemy' then
        -- エネミー
        default.class = Enemy
        default.sprite = 'enemy'
        default.collisionClass = 'enemy'
    else
        -- 一致しなかったのでキャンセル
        return
    end

    -- キャラクターエンティティの登録
    local entity = self:registerEntity(
        default.class {
            spriteType = object.properties.sprite or default.sprite,
            spriteSheet = spriteSheet,
            x = object.x,
            y = object.y,
            offsetY = 16,
            collider = self.world:newCircleCollider(0, 0, 16),
            collisionClass = object.properties.collisionClass or default.collisionClass,
            world = self.world,
            h_align = 'center',
            v_align = 'bottom',
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

-- プレイヤーリストの取得
function Level:getPlayers()
    return self:getCharacters('player')
end

-- プレイヤーの取得
function Level:getPlayer()
    return lume.first(self:getPlayers())
end

return Level
