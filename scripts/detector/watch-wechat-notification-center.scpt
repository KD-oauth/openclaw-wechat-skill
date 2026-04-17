on run argv
	set logPath to ""
	if (count of argv) > 0 then
		set logPath to item 1 of argv
	else
		set logPath to POSIX path of ((path to desktop as text) & "wechat_notify.log")
	end if
	
	set lastSnapshot to ""
	set lastLoggedAt to missing value
	set repeatWindowSeconds to 5
	my appendLine(logPath, "===== start watch: " & (current date as string) & " =====")
	
	repeat
		try
			set foundText to my readTopNotification()
			set nowDate to current date
			if foundText is not "" then
				set shouldLog to false
				if foundText is not lastSnapshot then
					set shouldLog to true
				else if lastLoggedAt is missing value then
					set shouldLog to true
				else if ((nowDate - lastLoggedAt) as number) ≥ repeatWindowSeconds then
					set shouldLog to true
				end if
				if shouldLog then
					set lastSnapshot to foundText
					set lastLoggedAt to nowDate
					my appendLine(logPath, "WECHAT:" & foundText)
				end if
			else
				set lastSnapshot to ""
				set lastLoggedAt to missing value
			end if
		on error errMsg number errNum
			my appendLine(logPath, "ERROR:" & errNum & ":" & errMsg)
		end try
		delay 0.5
	end repeat
end run

on readTopNotification()
	tell application "System Events"
		tell process "NotificationCenter"
			if not (exists window "Notification Center") then return ""
			set sa to scroll area 1 of group 1 of group 1 of window "Notification Center"
			return my findFirstTextPair(sa)
		end tell
	end tell
end readTopNotification

on findFirstTextPair(elem)
	tell application "System Events"
		try
			set tList to value of every static text of elem
			if (count of tList) ≥ 2 then
				set chatName to item 1 of tList
				set messageText to item 2 of tList
				if chatName is not "" and messageText is not "" then
					return chatName & "|||" & messageText
				end if
			end if
		end try
		
		try
			set childElems to every UI elements of elem
			repeat with childElem in childElems
				set resultText to my findFirstTextPair(childElem)
				if resultText is not "" then return resultText
			end repeat
		end try
	end tell
	return ""
end findFirstTextPair

on appendLine(logPath, lineText)
	do shell script "/bin/echo " & quoted form of lineText & " >> " & quoted form of logPath
end appendLine
