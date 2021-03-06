
-- グローバルに影響があるライブラリ
require 'autobatch'
require 'sbss'

-- デバッグモード
local debugMode = false

-- ライブラリ
local lume = require 'lume'
local lurker = debugMode and require 'lurker' or nil

-- フォーカス
local focused = true
local screenshot

-- 画面のサイズ
local width, height = 0, 0

-- シーンステート
local Scenes = require 'scenes'

-- シーン
local scene = Scenes()
scene:gotoState 'boot'
scene:setDebugMode(debugMode)

-- ホットスワップ後の対応
if lurker then
    lurker.postswap = function (f)
        if lume.find(Scenes.static.scenes, f:match('%/([^%/%.]+).lua$')) then
            -- シーンステートなら main もホットスワップ
            lurker.hotswapfile('main.lua')
        elseif f:match('^assets%/') then
            -- アセットならシーンをリセット
            scene:resetState()
        end
    end
end

-- 読み込み
function love.load()
    love.math.setRandomSeed(love.timer.getTime())
    width, height = love.graphics.getDimensions()
end

-- 更新
function love.update(dt)
    -- シーンの更新
    if focused then
        scene:updateState(dt)
    end
end

-- 描画
function love.draw()
    if focused or screenshot == nil then
        -- 画面のリセット
        love.graphics.reset()

        -- シーンの描画
        scene:drawState()

        -- ステートの描画
        if debugMode then
            love.graphics.setColor(1, 1, 1)
            scene:printStates(0, 0)
        end
    elseif screenshot then
        -- スクリーンショットを描画
        love.graphics.draw(screenshot)
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
    elseif key == 'f1' and lurker then
        -- スキャン
        lurker.scan()
    elseif key == 'f2' and debugMode then
        -- ステートに入り直す
        scene:resetState()
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
        scene:keypressedState(key, scancode, isrepeat)
    end
end

-- マウス入力
function love.mousepressed(...)
    -- シーンに処理を渡す
    scene:mousepressedState(...)
end

-- ゲームパッド入力
function love.gamepadpressed(...)
    -- シーンに処理を渡す
    scene:gamepadpressedState(...)
end

-- フォーカス
function love.focus(f)
    focused = f

    if not f then
        -- フォーカスを失ったので、スクリーンショット撮影
        love.graphics.captureScreenshot(
            function (imageData)
                screenshot = love.graphics.newImage(imageData)
            end
        )
    elseif screenshot then
        -- フォーカスが戻ったので、スクリーンショット開放
        screenshot:release()
        screenshot = nil
    end
end
