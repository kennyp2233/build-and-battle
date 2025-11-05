-- Result.luau (Patrón Result para manejo de errores)
-- Implementa un tipo Result<T, E> similar a Rust para manejo robusto de errores

export type Result<T, E> = {
	success: boolean,
	value: T?,
	error: E?,
}

local Result = {}

function Result.Ok<T>(value: T): Result<T, any>
	return {
		success = true,
		value = value,
		error = nil,
	}
end

function Result.Err<E>(error: E): Result<any, E>
	return {
		success = false,
		value = nil,
		error = error,
	}
end

function Result.IsOk<T, E>(result: Result<T, E>): boolean
	return result.success
end

function Result.IsErr<T, E>(result: Result<T, E>): boolean
	return not result.success
end

function Result.Unwrap<T, E>(result: Result<T, E>): T
	if result.success then
		return result.value
	else
		error("Attempted to unwrap an error Result: " .. tostring(result.error))
	end
end

function Result.UnwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T
	if result.success then
		return result.value
	else
		return defaultValue
	end
end

function Result.UnwrapErr<T, E>(result: Result<T, E>): E
	if not result.success then
		return result.error
	else
		error("Attempted to unwrap an Ok Result as error")
	end
end

return Result
