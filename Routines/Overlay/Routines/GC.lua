local cqueues = require"cqueues"
local function Main()
	print"Stopping automatic GC"
	collectgarbage"stop"
	while true do
		collectgarbage"collect"
		cqueues.sleep(0)
	end
end; return Main
