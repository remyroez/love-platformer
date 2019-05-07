
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- スプラッシュスクリーン
local Splash = Base:newState 'splash'

-- クラス
local o_ten_one = require 'o-ten-one'

-- エイリアス
local lg = love.graphics

-- 次のステートへ
function Splash:nextState(...)
    self:gotoState('title', ...)
end

-- 開始
function Splash:entered(state, args)
    -- スプラッシュスクリーンの設定
    local config = args or {}
    config.base_folder = config.base_folder or 'lib'

    -- スプラッシュスクリーン
    state.splash = o_ten_one(config)
    state.splash.onDone = function ()
        self:nextState()
    end
end

-- 終了
function Splash:exited(state, ...)
    self:clearState()
end

-- 更新
function Splash:update(state, dt)
    state.splash:update(dt)
end

-- 描画
function Splash:draw(state)
    state.splash:draw()
end

-- キー入力
function Splash:keypressed(state, key, scancode, isrepeat)
    state.splash:skip()
end

-- マウス入力
function Splash:mousepressed(state, x, y, button, istouch, presses)
    state.splash:skip()
end

return Splash
