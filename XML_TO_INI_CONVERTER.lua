function WriteToFile(output, file)
  local filehandle = assert(io.open(file, "w"),"io.open: Cannot open file to write: "..file)
  if filehandle ~= nil then
    filehandle:write(output)
    filehandle:flush()
    filehandle:close()
  end
end

function ParseTextFileIntoTable(file)
	local filehandle = assert(io.open(file, "r"),"io.open: Cannot open file to load: "..file)
	local LineTable = {}
	local LineCount = 0
	line = assert(filehandle:read("l"),"read: cannot read line from file: "..file)
	while line ~= nil do 
		LineCount=LineCount+1
		table.insert(LineTable, line) 
		line = filehandle:read("l")
	end
  filehandle:close()
	return LineTable, LineCount
end

function ConvertLineTableToText(LineTable)
	return table.concat(LineTable, "\n")
end

function ExtractString(line)
	local startpos = string.find(line, [["]], 1, true)
	if string.find(line, [[time]], 1, true) then 
		return string.gsub(string.sub(line, startpos+1, string.find(line, [["]], startpos+1, true)-1),"s","")
	else
		return string.sub(line, startpos+1, string.find(line, [["]], startpos+1, true)-1)
	end
end

function CodeCompatReplacement(code)
	if code == "AIUpdate" then return "AIUpdateInterface"
	else return code
	end
end

function ConvertXmlToIni(file)
	print(file)
	local TextFileTable = ParseTextFileIntoTable(file) 
	local INI = {}
	local INI_LINE = ""
	local InObjectDef = false
	local InModule = false
	local ModuleTagCount = 1
	local InBehaviours = false
	local IS = function(line, text)
		if string.find(line, text, 1,true) then return true
		else return false end
	end
	for i=1,#TextFileTable,1 do
		if IS(TextFileTable[i],[[<GameObject]]) then
			InObjectDef = true
		elseif IS(TextFileTable[i],[[</GameObject>]]) then
			InObjectDef = false
			InBehaviours = false
			InModule = false
			ModuleTagCount = 1
			table.insert(INI, "End" .. "\n")
		elseif InObjectDef then
			if IS(TextFileTable[i],[[id=]]) and not IS(TextFileTable[i],"ModuleTag") then 
				table.insert(INI, "Object " .. ExtractString(TextFileTable[i]))
			elseif IS(TextFileTable[i],[[<Behaviors>]]) then
				InBehaviours = true
			elseif IS(TextFileTable[i],[[</Behaviors>]]) then
				InBehaviours = false
			elseif InBehaviours then
				if IS(TextFileTable[i],"ModuleTag") then
					InModule = true
				end
				if InModule == true then
					if IS(TextFileTable[i-1],[[ArmorSet]]) then
						table.insert(INI, "\t" .. "ArmorSet")
					end
					if IS(TextFileTable[i],[[id=]]) then
						if IS(TextFileTable[i-1],[[ActiveBody]]) then
							if ModuleTagCount < 10 then
								table.insert(INI, "\t" .. "Body = " .. CodeCompatReplacement(string.match(TextFileTable[i-1],"%w+")) .. " ModuleTag_" .. "0" .. ModuleTagCount)
							else
								table.insert(INI, "\t" .. "Body = " .. CodeCompatReplacement(string.match(TextFileTable[i-1],"%w+")) .. " ModuleTag_" .. ModuleTagCount)						
							end							
						else
							if ModuleTagCount < 10 then
								table.insert(INI, "\t" .. "Behavior = " .. CodeCompatReplacement(string.match(TextFileTable[i-1],"%w+")) .. " ModuleTag_" .. "0" .. ModuleTagCount)
							else
								table.insert(INI, "\t" .. "Behavior = " .. CodeCompatReplacement(string.match(TextFileTable[i-1],"%w+")) .. " ModuleTag_" .. ModuleTagCount)						
							end
						end
						ModuleTagCount = ModuleTagCount + 1
					elseif IS(TextFileTable[i],[["]]) then
						if string.len(ExtractString(TextFileTable[i])) > 0 then
							if IS(string.match(TextFileTable[i],"%w+"), "DeathTypes") then
								table.insert(INI, "\t\t" .. CodeCompatReplacement(string.match(TextFileTable[i],"%w+")) .. " = " ..  "NONE" .. " +" .. ExtractString(TextFileTable[i]))							
							else					
								table.insert(INI, "\t\t" .. CodeCompatReplacement(string.match(TextFileTable[i],"%w+")) .. " = " ..  ExtractString(TextFileTable[i]))
							end
						end
					end						
					if IS(TextFileTable[i], [[/>]]) or (IS(TextFileTable[i],"</") and IS(TextFileTable[i],">")) then
						table.insert(INI, "\t" .. "End")
						InModule = false
					end
				end
			elseif IS(TextFileTable[i],[[AIUpdate]]) or IS(TextFileTable[i],[[ArmorSet]]) or IS(TextFileTable[i],[[ActiveBody]]) then
				InModule = true
				InBehaviours = true					
			elseif IS(TextFileTable[i],[["]]) then
				table.insert(INI, "\t" .. string.match(TextFileTable[i],"%w+") .. " = " ..  ExtractString(TextFileTable[i]))
			end
		end
	end
	WriteToFile(ConvertLineTableToText(INI), string.gsub(file,".xml",".ini"))
end

ConvertXmlToIni("CONTENT.xml")





function CheckForEntry(TextFileTable, Keyword)
	for i=1,#TextFileTable,1 do
		if (string.find(TextFileTable[i], Keyword)) then return true end
	end
end

function findnth(str, nth)
  local array = {}
  for i in string.gmatch(str, '%s+%d[%d.,]*') do
    table.insert(array, string.gsub(i, "%s+", ""))
  end
  return array[nth]
end

function ExtractNumbersFromLine(str)
  local array = {}
  for i in string.gmatch(str, '%s+%d[%d.,]*') do
	local Extract = string.gsub(i, "%s+", "")
    table.insert(array, Extract)
  end
  return array
end