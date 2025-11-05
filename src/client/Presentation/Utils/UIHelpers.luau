-- Utils.luau
-- Utilidades generales para UI

local function formatTime(sec: number): string
	sec = math.max(0, math.floor(sec))
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format("%02d:%02d", m, s)
end

return {
	formatTime = formatTime,
}