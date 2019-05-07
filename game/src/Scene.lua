
local class = require 'middleclass'
local stateful = require 'stateful'

-- シーン
local Scene = class 'Scene'
Scene:include(stateful)

-- 現在のステートを返す
local function _getCurrentState(self)
    return self.__stateStack[#self.__stateStack]
end

-- ステート名を返す
local function _getStateName(self, target)
    for name, state in pairs(self.class.static.states) do
        if state == target then return name end
    end
end

-- 現在のステート名を返す
local function _getCurrentStateName(self)
    return _getStateName(self, _getCurrentState(self))
end

-- 新規ステート
function Scene.static:newState(name, base)
    if Scene.static.states[name] then Scene.static.states[name] = nil end
    return Scene:addState(name, base or Scene)
end

-- 初期化
function Scene:initialize()
    self._stateObjects = {}
    self.debugMode = false
end

-- ステート開始
function Scene:enteredState(...)
    -- 現在のステート用テーブルを準備
    self:getState(nil, ...)

    -- コールバック
    self:entered(self.state, ...)
end

-- ステート終了
function Scene:exitedState(...)
    -- コールバック
    self:exited(self.state, ...)

    -- ガーベージコレクション
    collectgarbage('collect')
end

-- ステートプッシュ
function Scene:pushedState(...)
    self:pushed(self.state, ...)
end

-- ステートポップ
function Scene:poppedState(...)
    self:popped(self.state, ...)
end

-- ステート停止
function Scene:pausedState(...)
    self:paused(self.state, ...)
end

-- ステート再開
function Scene:continuedState(...)
    self:continued(self.state, ...)
end

-- ステート更新
function Scene:updateState(dt, ...)
    self:update(self.state, dt, ...)
end

-- ステート描画
function Scene:drawState(...)
    self:draw(self.state, ...)
end

-- ステートキー入力
function Scene:keypressedState(...)
    self:keypressed(self.state, ...)
end

-- ステートマウス入力
function Scene:mousepressedState(...)
    self:mousepressed(self.state, ...)
end

-- デバッグモードの設定
function Scene:setDebugMode(mode)
    self.debugMode = mode or false
end

-- ステートのリセット
function Scene:resetState()
    self:gotoState(_getCurrentStateName(self))
end

-- ステートの描画
function Scene:printStates(x, y)
    love.graphics.print('states: ' .. table.concat(self:getStateStackDebugInfo(), '/'), x, y)
end

-- ステート用テーブル
function Scene:getState(name, ...)
    local currentName = _getCurrentStateName(self)
    local name = name or currentName
    local isCurrent = name == currentName

    -- 現在のステート用テーブルが無ければ準備, load を呼ぶ
    if self._stateObjects[name] == nil then
        self._stateObjects[name] = {}
        if isCurrent then
            self.state = self._stateObjects[name]
        end
        self:load(self.state, ...)
    else
        if isCurrent then
            self.state = self._stateObjects[name]
        end
    end

    return self._stateObjects[name]
end

-- ステートオブジェクトのクリア
function Scene:clearState()
    for name, v in pairs(self.state) do
        self.state[name] = nil
    end
end

-- 次のステートへ
function Scene:nextState(...)
end

-- 読み込み
function Scene:load(state, ...)
end

-- 開始
function Scene:entered(state, ...)
end

-- 終了
function Scene:exited(state, ...)
end

-- プッシュ
function Scene:pushed(state, ...)
end

-- ポップ
function Scene:popped(state, ...)
end

-- 停止
function Scene:paused(state, ...)
end

-- 再開
function Scene:continued(state, ...)
end

-- 更新
function Scene:update(state, dt, ...)
end

-- 描画
function Scene:draw(state, ...)
end

-- キー入力
function Scene:keypressed(state, key, scancode, isrepeat)
end

-- マウス入力
function Scene:mousepressed(state, x, y, button, istouch, presses)
end

return Scene
