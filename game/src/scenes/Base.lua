
local class = require 'middleclass'

local Scene = require 'Scene'

-- ベース
local Base = class('Base', Scene)

-- 新規ステート
function Base.static:newState(name, base)
    if Base.static.states[name] then Base.static.states[name] = nil end
    return Base:addState(name, base or Base)
end

return Base
