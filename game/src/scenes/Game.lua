
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- ゲーム
local Game = Base:newState 'game'

-- ライブラリ
local wf = require 'windfield'

-- クラス
local Character = require 'Character'

-- エイリアス
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

-- 読み込み
function Game:load(state, ...)
end

-- ステート開始
function Game:entered(state, ...)
    -- ワールド
    state.world = wf.newWorld(0, 0, true)
    state.world:setGravity(0, 512)

    -- キャラクター
    state.player = Character {
        spriteType = 'playerRed',
        spriteSheet = self.spriteSheet,
        x = 100,
        y = 100,
        offsetY = 16,
        collider = state.world:newRectangleCollider(0, 0, 24, 32),
        h_align = 'center',
        v_align = 'bottom',
    }

    state.block = state.world:newRectangleCollider(0, 500, 800, 50)
    state.block:setType('static')
end

-- ステート終了
function Game:exited(state, ...)
    state.player:destroy()
end

-- 更新
function Game:update(state, dt)
    state.world:update(dt)
    state.player:update(dt)
end

-- 描画
function Game:draw(state)
    state.player:draw()
    state.world:draw()
end

-- キー入力
function Game:keypressed(state, key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(state, x, y, button, istouch, presses)
end

return Game
