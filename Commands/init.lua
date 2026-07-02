--- TODO: Refactor
local OOPEG = require"OOPEG"
local P = OOPEG.Nested.PEG

---@param SharedData OverlayBot.SharedData
---@param Basic table<string, unknown>
---@param Shenanigans table<string, OverlayBot.Commands.Shenanigans.Definition>
---@return unknown
local function GenerateCommandGrammar(SharedData, Basic, Shenanigans)
	--local Basic = require"OverlayBot.Commands.Basic"(SharedData)
	--local Shenanigans = require"OverlayBot.Commands.Shenanigans"(SharedData, GweryangRequestBox, OverlayPortal)
	local ShenanigansCommandGrammars = P.Select{}
	local BasicCommandGrammars = P.Select{}

	CommandsGrammar = OOPEG.Nested.Grammar{
		P.Select{P.Variable.Canonical"Shenanigans", P.Variable.Canonical"Basic"};
		String = P.Apply(
			P.Table(
				P.Sequence{
					P.Pattern'"', 
					P.All(
						P.Select{
							P.Sequence{P.Pattern[[\"]], P.Constant[["]]},
							P.Sequence{P.Pattern[[\\]], P.Constant[[\]]},
							P.Capture(
								P.Dematch(P.Pattern(1), P.Pattern'"')
							),
						}
					),
					P.Pattern'"'
				}
			),
			function(Parts) return table.concat(Parts) end
		);
		Trailing = P.Atleast(1, P.Pattern(1));
		Word = P.Atleast(1, P.Dematch(P.Pattern(1), P.Pattern" "));
		Integer = P.Apply(P.Atleast(1, P.Range"09"), tonumber);
		Shenanigans = OOPEG.Nested.Grammar{
			P.Sequence{P.Pattern"?", ShenanigansCommandGrammars};
		};
		Basic = OOPEG.Nested.Grammar{
			P.Sequence{P.Pattern"!", BasicCommandGrammars};
		};
	};

	for Name, Definition in pairs(Shenanigans) do
		local NamePattern = P.Sequence{}
		for i = 1, #Name do
			table.insert(
				NamePattern.Parts.Items,
				P.Select{
					P.Pattern(Name:sub(i,i):lower());
					P.Pattern(Name:sub(i,i):upper());
				}
			)
		end
		local CommandPattern = P.Sequence{
			NamePattern, P.Select{
				P.Sequence{P.Atleast(1, P.Pattern" "), P.Constant(Definition.Execute), P.Table(Definition.Grammar or P.Constant{}), P.Constant(Definition.CostFunction)};
				P.Sequence{P.Constant(Definition.Execute), P.Constant(Definition.Defaults or {}), P.Constant(Definition.CostFunction)};
			}
		}
		table.insert(ShenanigansCommandGrammars.Options.Items, CommandPattern)
	end

	for Name, Definition in pairs(Basic) do
		local NamePattern = P.Sequence{}
		for i = 1, #Name do
			table.insert(
				NamePattern.Parts.Items,
				P.Select{
					P.Pattern(Name:sub(i,i):lower());
					P.Pattern(Name:sub(i,i):upper());
				}
			)
		end
		local CommandPattern = P.Sequence{
			NamePattern, P.Select{
				P.Sequence{P.Atleast(1, P.Pattern" "), P.Constant(Definition.Execute), P.Table(Definition.Grammar or P.Constant{})};
				P.Sequence{P.Constant(Definition.Execute), P.Constant(Definition.Defaults or {})};
			}
		}
		table.insert(BasicCommandGrammars.Options.Items, CommandPattern)
	end

	SharedData.CompiledCommandsGrammar = CommandsGrammar:Decompose():Decompose()
	return SharedData.CompiledCommandsGrammar
end

return GenerateCommandGrammar
