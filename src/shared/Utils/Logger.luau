-- Logger.luau (Sistema de logging centralizado)
-- Proporciona logging consistente y configurable en toda la aplicación

local GameConfig = require(script.Parent.Parent.Config.GameConfig)

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR"

local Logger = {}
Logger.__index = Logger

local LOG_COLORS = {
	DEBUG = "\27[36m", -- Cyan
	INFO = "\27[32m", -- Green
	WARN = "\27[33m", -- Yellow
	ERROR = "\27[31m", -- Red
	RESET = "\27[0m",
}

function Logger.new(moduleName: string)
	local self = setmetatable({}, Logger)
	self.moduleName = moduleName
	return self
end

function Logger:_log(level: LogLevel, message: string, ...)
	if not GameConfig.DEBUG.ENABLED and level == "DEBUG" then
		return
	end

	local timestamp = os.date("%H:%M:%S")
	local prefix = string.format("[%s][%s][%s]", timestamp, level, self.moduleName)
	local formattedMessage = string.format(message, ...)

	if level == "ERROR" then
		warn(prefix .. " " .. formattedMessage)
	else
		print(prefix .. " " .. formattedMessage)
	end
end

function Logger:Debug(message: string, ...)
	if GameConfig.DEBUG.VERBOSE_LOGGING then
		self:_log("DEBUG", message, ...)
	end
end

function Logger:Info(message: string, ...)
	self:_log("INFO", message, ...)
end

function Logger:Warn(message: string, ...)
	self:_log("WARN", message, ...)
end

function Logger:Error(message: string, ...)
	self:_log("ERROR", message, ...)
end

return Logger
