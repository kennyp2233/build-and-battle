-- runTests.server.luau
-- Runner de la suite TestEZ. Solo se incluye en test.project.json (no en el build
-- de producción). Para correr los tests:
--   1. rojo build test.project.json --output test.rbxl
--   2. abrir test.rbxl en Studio
--   3. Play -> resultados en el Output
-- TestBootstrap escanea descendientes y corre solo los ModuleScripts *.spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

TestEZ.TestBootstrap:run({ ServerScriptService.Tests })
