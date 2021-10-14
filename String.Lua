-- 4thAxis
-- 8/13/21

local Library = {}

--------------------------------------------------------------------
---------------------------  General  ------------------------------
--------------------------------------------------------------------


function Library.TrimFromFront(String, Pattern)
	Pattern = Pattern or "%s"

	return string.gsub(String, "^"..Pattern.."*(.-)"..Pattern.."*", "%1")
end


function Library.TrimString(String, Pattern)
	return Pattern and string.match(String, "^"..Pattern.."*(.-)"..Pattern.."*$") or string.match(String, "^%s*(.-)%s*$")
end


function Library.IsWhitespace(String)
	return string.match(String, "[%s]+") == String
end


function Library.IsStringWhiteSpaceOrEmpty(String)
	return String == "" or Library.IsWhitespace(String)
end


function Library.PutElipseAfterLimit(String, CharacterLimit)
	if #String > CharacterLimit then
		String = string.sub(String, 1, CharacterLimit-3).."..."
	end
	
	return String
end



return Library
