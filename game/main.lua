
-- グローバルに影響があるライブラリ
require 'autobatch'
require 'sbss'

-- ライブラリ
local lume = require 'lume'
local lurker = require 'lurker'

-- シーンステート
local scenes = require 'scenes'

-- クラス
local Scene = require 'Scene'

-- シーン
local scene = Scene()
scene:gotoState 'boot'

-- ホットスワップ後の対応
lurker.postswap = function (f)
    if lume.find(scenes, f:match('%/([^%/%.]+).lua$')) then
        -- シーンステートなら main もホットスワップ
        lurker.hotswapfile('main.lua')
    elseif f:match('^assets%/') then
        -- アセットならシーンをリセット
        scene:resetState()
    end
end

-- デバッグモード
local debugMode = false

-- 画面のサイズ
local width, height = 0, 0

-- 読み込み
function love.load()
    love.math.setRandomSeed(love.timer.getTime())
    width, height = love.graphics.getDimensions()
end

-- 更新
function love.update(dt)
    -- シーンの更新
    scene:update(dt)
end

-- 描画
function love.draw()
    -- 画面のリセット
    love.graphics.reset()

    -- シーンの描画
    scene:draw()

    -- ステートの描画
    if debugMode then
        love.graphics.setColor(1, 1, 1)
        scene:printStates(0, 0)
    end
end

-- キー入力
function love.keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        -- 終了
        love.event.quit()
    elseif key == 'printscreen' then
        -- スクリーンショット
        love.graphics.captureScreenshot(os.time() .. ".png")
    elseif key == 'f1' then
        -- スキャン
        lurker.scan()
    elseif key == 'f5' then
        -- リスタート
        love.event.quit('restart')
    elseif key == 'f12' then
        -- デバッグモード切り替え
        debugMode = not debugMode

        -- シーンに反映
        scene:setDebugMode(debugMode)
    else
        -- シーンに処理を渡す
        scene:keypressed(key, scancode, isrepeat)
    end
end

-- マウス入力
function love.mousepressed(...)
    -- シーンに処理を渡す
    scene:mousepressed(...)
end
