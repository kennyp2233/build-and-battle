-- Result.luau (Patrón Result para manejo de errores)
-- Result<T, E> inmutable estilo Rust. Los objetos se congelan con table.freeze
-- para que los callers no puedan mutar .success por accidente.

export type Result<T, E> = {
	success: boolean,
	value: T?,
	error: E?,
}

local Result = {}

function Result.Ok<T>(value: T): Result<T, any>
	return table.freeze({
		success = true,
		value = value,
		error = nil,
	})
end

function Result.Err<E>(err: E): Result<any, E>
	return table.freeze({
		success = false,
		value = nil,
		error = err,
	})
end

function Result.IsOk(result: Result<any, any>): boolean
	return result.success
end

function Result.IsErr(result: Result<any, any>): boolean
	return not result.success
end

function Result.Unwrap<T>(result: Result<T, any>): T
	if result.success then
		return (result.value :: any) :: T
	end
	error("Attempted to unwrap an error Result: " .. tostring(result.error))
end

function Result.UnwrapOr<T>(result: Result<T, any>, defaultValue: T): T
	if result.success then
		return (result.value :: any) :: T
	end
	return defaultValue
end

function Result.UnwrapErr<E>(result: Result<any, E>): E
	if not result.success then
		return (result.error :: any) :: E
	end
	error("Attempted to unwrap an Ok Result as error")
end

return Result
