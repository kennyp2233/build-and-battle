-- Logger.luau (Logging centralizado)
-- Imprime con prefijo "[HH:MM:SS][LEVEL][Module]". Errores van por warn() para que
-- aparezcan en Output con su stack y color naranja nativo de Studio.

local GameConfig = require(script.Parent.Parent.Config.GameConfig)

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR"

local Logger = {}
Logger.__index = Logger

function Logger.new(moduleName: string)
	local self = setmetatable({}, Logger)
	self.moduleName = moduleName
	return self
end

function Logger:_log(level: LogLevel, message: string, ...)
	local timestamp = os.date("%H:%M:%S")
	local prefix = string.format("[%s][%s][%s]", timestamp, level, self.moduleName)
	local formatted = string.format(message, ...)

	if level == "ERROR" or level == "WARN" then
		warn(prefix .. " " .. formatted)
	else
		print(prefix .. " " .. formatted)
	end
end

function Logger:Debug(message: string, ...)
	if GameConfig.DEBUG.VERBOSE_LOGGING then
		self:_log("DEBUG", message, ...)
	end
end

function Logger:Info(message: string, ...)
	if GameConfig.DEBUG.ENABLED then
		self:_log("INFO", message, ...)
	end
end

function Logger:Warn(message: string, ...)
	self:_log("WARN", message, ...)
end

function Logger:Error(message: string, ...)
	self:_log("ERROR", message, ...)
end

return Logger
