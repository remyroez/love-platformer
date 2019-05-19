
-- サウンドプレイヤーモジュール
local SoundPlayer = {}

-- 初期化
function SoundPlayer:initializeSoundPlayer(sounds)
    -- プライベート
    self._soundPlayer = {}

    -- サウンドリスト
    self._soundPlayer.sounds = sounds
end

-- サウンドの取得
function SoundPlayer:getSound(name)
    return self._soundPlayer.sounds ~= nil and self._soundPlayer.sounds[name] or nil
end

-- サウンドの再生
function SoundPlayer:playSound(name, reset)
    reset = reset == nil and true or reset
    local sound = self:getSound(name)
    if sound then
        if sound then
            sound:seek(0)
        end
        sound:play()
    end
end

-- サウンドの停止
function SoundPlayer:stopSound(name)
    local sound = self:getSound(name)
    if sound then
        sound:stop()
    end
end

return SoundPlayer
