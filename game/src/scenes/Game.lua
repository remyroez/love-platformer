
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- ゲーム
local Game = Base:newState 'game'

-- エイリアス
local lg = love.graphics
local lk = love.keyboard
local lm = love.mouse

-- 読み込み
function Game:load(state, ...)
end

-- ステート開始
function Game:entered(state, ...)
end

-- ステート終了
function Game:exited(state, ...)
end

-- 更新
function Game:update(state, dt)
end

-- 描画
function Game:draw(state)
end

-- キー入力
function Game:keypressed(key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(x, y, button, istouch, presses)
end

return Game
