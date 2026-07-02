local sqlite3 = require"lsqlite3"
local OOP = require"Moonrise.OOP"

local DataManager = OOP.Declarator.Shortcuts"OverlayBot.PointsManager"

function DataManager:Initialize(Instance, Path)
	Instance.Database = sqlite3.open(Path)

	Instance.Database:exec[[
		CREATE TABLE IF NOT EXISTS CommandUsageData (
			UserID Integer,
			Amount Integer,
			UNIQUE(UserID)
		);
	]]
end

function DataManager:GetPoints(UserID)
	local SelectStatement = self.Database:prepare("SELECT Amount FROM CommandUsagePoints WHERE UserID = ?")
	SelectStatement:bind_values(UserID)
	local StepState = SelectStatement:step() 
	local Total
	if StepState == sqlite3.ROW then
		Total = SelectStatement:get_value(0) or 0
	else
		print"Not found"
		Total = 0
	end
	SelectStatement:finalize()
	return Total
end

function DataManager:AddPoints(UserID, Amount)
	local CurrentTotal = self:GetPoints(UserID)
	local NewTotal = math.max(0, CurrentTotal + Amount)
	local InsertStatement, Error = self.Database:prepare"INSERT OR REPLACE INTO CommandUsagePoints (UserID, Amount) VALUES (?, ?)"
	assert(InsertStatement, Error)
	InsertStatement:bind_values(UserID, NewTotal)
	assert(InsertStatement:step() == sqlite3.DONE)
	InsertStatement:finalize()
	return NewTotal
end

function DataManager:RemovePoints(UserID, Amount)
	return self:AddPoints(UserID, -Amount)
end

return DataManager
