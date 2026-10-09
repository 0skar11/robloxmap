-- Loads every ModuleScript in the Anomalies folder. To add an anomaly, drop a new module there:
--
--   return {
--       Name = "MyAnomaly",
--       Horror = true,  -- optional: only from Config.HorrorStartsAtLevel on
--       Apply = function(ctx) ctx:Set(ctx.Refs.LineBadge, "Text", "41") end,
--       Reset = function(ctx) ctx:Restore() end,
--   }

export type Anomaly = {
	Name: string,
	Horror: boolean?, -- true: only in the dark half of the game
	Apply: (ctx: any) -> (),
	Reset: (ctx: any) -> (),
}

local AnomalyRegistry = {}

function AnomalyRegistry.load(): { Anomaly }
	local anomalies = {}
	for _, module in script.Parent.Anomalies:GetChildren() do
		if not module:IsA("ModuleScript") then
			continue
		end

		local ok, anomaly = pcall(require, module)
		if not ok or type(anomaly) ~= "table" or type(anomaly.Apply) ~= "function" then
			warn("[EndlessSubway] skipping anomaly", module.Name, if ok then "(no Apply function)" else anomaly)
			continue
		end

		anomaly.Name = anomaly.Name or module.Name
		anomaly.Reset = anomaly.Reset or function(ctx)
			ctx:Restore()
		end
		table.insert(anomalies, anomaly)
	end

	table.sort(anomalies, function(a, b)
		return a.Name < b.Name
	end)
	return anomalies
end

return AnomalyRegistry
