
local folderOfThisFile = (...):gsub("%.init$", "") .. "."

local Base = require(folderOfThisFile .. 'Base')

Base.static.scenes = {
    "Boot",
    "Splash",
    "Title",
    "Select",
    "Game"
}

for _, name in ipairs(Base.static.scenes) do
    require(folderOfThisFile .. name)
end

return Base
