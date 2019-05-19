
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")
local Base = require(folderOfThisFile .. 'Base')

-- ブート
local Boot = Base:newState 'boot'

-- エイリアス
local lg = love.graphics
local la = love.audio

-- 次のステートへ
function Boot:nextState(...)
    self:gotoState('splash', ...)
end

-- 読み込み
function Boot:load(state, ...)
    -- 画面のサイズ
    local width, height = lg.getDimensions()
    self.width = width
    self.height = height

    -- スプライトシートの読み込み
    self.spriteSheet = sbss:new('assets/spritesheet.xml')

    -- フォントの読み込み
    local fontPath = 'assets/Kenney Space.ttf'
    self.font64 = lg.newFont(fontPath, 64)
    self.font32 = lg.newFont(fontPath, 32)
    self.font16 = lg.newFont(fontPath, 16)
    self.font8 = lg.newFont(fontPath, 8)

    -- レベル関連
    self.selectedLevel = 1
    self.clearedLevel = 0
    self.clearedLevelScores = {}
    self.collectedItems = {}
end

-- 更新
function Boot:update(state, dt, ...)
    self:nextState()
end

return Boot
