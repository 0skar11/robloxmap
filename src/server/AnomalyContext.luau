-- Handed to an anomaly's Apply and Reset. Every change made through it is recorded, so
-- ctx:Restore() puts the station back exactly as it was, whatever the anomaly did.
--
--   ctx.Refs        everything MapBuilder.build() returned (lights, posters, passengers, ...)
--   ctx.Players     players in the server when the station started
--   ctx.Random      a Random object, so a station can be replayed from its seed
--
--   ctx:Set(instance, property, value)       change a property (Parent = nil hides something)
--   ctx:SetAttribute(instance, name, value)  change an attribute
--   ctx:Pivot(model, cframe)                 move a model
--   ctx:Add(instance, parent?)               add something new; destroyed on restore
--   ctx:Connect(signal, callback)            disconnected on restore
--   ctx:Spawn(callback)                      a thread that is cancelled on restore
--   ctx:Pick(list)                           random element of a list

local AnomalyContext = {}
AnomalyContext.__index = AnomalyContext

export type Context = typeof(setmetatable(
	{} :: {
		Refs: any,
		Players: { Player },
		Random: Random,
		_undo: { () -> () },
	},
	AnomalyContext
))

function AnomalyContext.new(refs: any, players: { Player }, random: Random): Context
	return setmetatable({
		Refs = refs,
		Players = players,
		Random = random,
		_undo = {},
	}, AnomalyContext)
end

function AnomalyContext.Set(self: Context, instance: Instance, property: string, value: any)
	local target = instance :: any
	local original = target[property]
	table.insert(self._undo, function()
		target[property] = original
	end)
	target[property] = value
end

function AnomalyContext.SetAttribute(self: Context, instance: Instance, name: string, value: any)
	local original = instance:GetAttribute(name)
	table.insert(self._undo, function()
		instance:SetAttribute(name, original)
	end)
	instance:SetAttribute(name, value)
end

function AnomalyContext.Pivot(self: Context, model: PVInstance, cframe: CFrame)
	local original = model:GetPivot()
	table.insert(self._undo, function()
		model:PivotTo(original)
	end)
	model:PivotTo(cframe)
end

function AnomalyContext.Add(self: Context, instance: Instance, parent: Instance?): Instance
	table.insert(self._undo, function()
		instance:Destroy()
	end)
	instance.Parent = parent or self.Refs.Station
	return instance
end

function AnomalyContext.Connect(self: Context, signal: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
	local connection = signal:Connect(callback)
	table.insert(self._undo, function()
		connection:Disconnect()
	end)
	return connection
end

function AnomalyContext.Spawn(self: Context, callback: () -> ()): thread
	local thread = task.spawn(callback)
	table.insert(self._undo, function()
		if coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
	end)
	return thread
end

function AnomalyContext.Pick<T>(self: Context, list: { T }): T
	return list[self.Random:NextInteger(1, #list)]
end

-- Undoes everything in reverse order, so stacked changes to one property unwind correctly.
function AnomalyContext.Restore(self: Context)
	for i = #self._undo, 1, -1 do
		local ok, err = pcall(self._undo[i])
		if not ok then
			warn("[EndlessSubway] restore step failed:", err)
		end
	end
	table.clear(self._undo)
end

return AnomalyContext
