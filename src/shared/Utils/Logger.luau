-- Logger.luau
-- Logger sin dependencias de gameplay. Configuración vía Logger.configure(...)
-- desde los entry points (init.server / init.client), no leyendo GameConfig.

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR"

local Logger = {}
Logger.__index = Logger

Logger._enabled = true
Logger._verbose = false

function Logger.configure(opts: { enabled: boolean?, verbose: boolean? })
	if opts.enabled ~= nil then
		Logger._enabled = opts.enabled
	end
	if opts.verbose ~= nil then
		Logger._verbose = opts.verbose
	end
end

function Logger.new(moduleName: string)
	return setmetatable({ moduleName = moduleName }, Logger)
end

local function safeFormat(message: string, ...): string
	if select("#", ...) == 0 then
		return message
	end
	local ok, formatted = pcall(string.format, message, ...)
	if ok then
		return formatted
	end
	return message
end

function Logger:_log(level: LogLevel, message: string, ...)
	local timestamp = os.date("%H:%M:%S")
	local prefix = string.format("[%s][%s][%s]", timestamp, level, self.moduleName)
	local formatted = safeFormat(message, ...)
	if level == "ERROR" or level == "WARN" then
		warn(prefix .. " " .. formatted)
	else
		print(prefix .. " " .. formatted)
	end
end

function Logger:Debug(message: string, ...)
	if Logger._verbose then
		self:_log("DEBUG", message, ...)
	end
end

function Logger:Info(message: string, ...)
	if Logger._enabled then
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
