
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- ブート
local Boot = Base:newState 'boot'

-- エイリアス
local lg = love.graphics
local la = love.audio

-- 次のステートへ
function Boot:nextState(...)
    self:gotoState('game', ...)
end

-- 読み込み
function Boot:load(state, ...)
    -- 画面のサイズ
    local width, height = lg.getDimensions()
    self.width = width
    self.height = height

    -- スプライトシートの読み込み
    self.spriteSheet = sbss:new('assets/spritesheet_players.xml')
end

-- 更新
function Boot:update(state, dt, ...)
    self:nextState()
end

return Boot
