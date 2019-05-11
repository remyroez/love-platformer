
-- アニメーションモジュール
local Animation = {}

-- 初期化
function Animation:initializeAnimation(...)
    self._animation = {}
    self:resetAnimations(...)
end

-- 現在のアニメーションを返す
function Animation:resetAnimations(animations, duration, index, loop)
    local anim = self._animation
    anim.animations = animations or {}
    self:resetAnimationIndex(index)
    self:resetAnimationDuration(duration or anim.duration)
    anim.timer = anim.duration
    anim.loop = loop == nil and true or loop
end

-- アニメーションのインデックスを設定する
function Animation:resetAnimationIndex(index)
    self._animation.index = index or 1
end

-- アニメーションの間隔を設定する
function Animation:resetAnimationDuration(duration)
    self._animation.duration = duration or 0.1
end

-- 現在のアニメーションを返す
function Animation:getCurrentAnimation()
    return self._animation.animations[self._animation.index]
end

-- 更新
function Animation:updateAnimation(dt)
    local anim = self._animation

    -- タイマーを減らす
    anim.timer = anim.timer - dt
    if anim.timer < 0 then
        -- ０未満になったらリセット
        anim.timer = anim.timer + anim.duration

        -- インデックスをインクリメント
        anim.index = anim.index + 1

        -- インデックスをループ
        if anim.index > #anim.animations then
            if anim.loop then
                anim.index = 1
            else
                anim.index = #anim.animations
            end
        end
    end
end

return Animation
