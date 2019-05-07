
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

-- 読み込み
function Splash:load(state, ...)
    local config = { ... }
    config.base_folder = 'lib'

    self.state.splash = o_ten_one(config)
    self.state.splash.onDone = function ()
        self:nextState()
    end
end

-- 更新
function Splash:update(state, dt)
    self.state.splash:update(dt)
end

-- 描画
function Splash:draw(state)
    self.state.splash:draw()
end

-- キー入力
function Splash:keypressed(key, scancode, isrepeat)
    self.state.splash:skip()
end

-- マウス入力
function Splash:mousepressed(x, y, button, istouch, presses)
    self.state.splash:skip()
end

return Splash
