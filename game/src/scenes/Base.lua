
local class = require 'middleclass'

local Scene = require 'Scene'

-- ベース
local Base = class('Base', Scene)

-- 新規ステート
function Base.static:newState(name, base)
    if Base.static.states[name] then Base.static.states[name] = nil end
    return Base:addState(name, base or Base)
end

-- 音楽の取得
function Base:getMusic(name)
    return self.musics ~= nil and self.musics[name] or nil
end

-- 音楽の再生
function Base:playMusic(name, reset)
    reset = reset ~= nil and reset or false

    if name ~= self.currentMusic or reset then
        -- 前の音楽を停止
        self:stopMusic()
    end

    local music = self:getMusic(name)
    if music then
        if reset then
            music:seek(0)
        end
        music:play()
    end

    self.currentMusic = name
end

-- 音楽の停止
function Base:stopMusic()
    local music = self:getMusic(self.currentMusic)
    if music then
        music:stop()
    end
    self.currentMusic = nil
end

-- サウンドの取得
function Base:getSound(name)
    return self.sounds ~= nil and self.sounds[name] or nil
end

-- サウンドの再生
function Base:playSound(name, reset)
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
function Base:stopSound(name)
    local sound = self:getSound(name)
    if sound then
        sound:stop()
    end
end

return Base
