on run
	set newline to ASCII character 10
	set stdout to ""
	set stdout to stdout & "  shutdown TotalSpacesCrashWatcher ..." & newline
	try
		do shell script "killall -SIGINT TotalSpacesCrashWatcher" with administrator privileges
	on error
		set stdout to stdout & "    TotalSpacesCrashWatcher was not running" & newline
	end try
	set stdout to stdout & "  shutdown TotalSpaces2 ..." & newline
	try
		do shell script "killall TotalSpaces2" with administrator privileges
    on error
		set stdout to stdout & "    TotalSpaces2 was not running" & newline
	end try
	
	set stdout to stdout & "  shutdown Dock ..." & newline
	try
		tell application "Dock" to quit
	on error
		set stdout to stdout & "    Dock was not running prior uninstallation" & newline
	end try
	
	set stdout to stdout & "  remove TotalSpaces2.app from login items ..." & newline
	try
		tell application "System Events"
			if login item "TotalSpaces2.app" exists then
				delete login item "TotalSpaces2.app"
			end if
			if login item "TotalSpaces2" exists then
				delete login item "TotalSpaces2"
			end if
		end tell	
	on error
		set stdout to stdout & "    Encountered problems when removing TotalSpaces2.app from login items"
	end try
		
	set stdout to stdout & "  remove TotalSpaces2.app ..." & newline
	try
		do shell script "sudo rm -rf \"/Applications/TotalSpaces2.app\"" with administrator privileges
	on error
		set stdout to stdout & "    unable to remove /Applications/TotalSpaces2.app" & newline
	end try
	
	
	set stdout to stdout & "  remove TotalSpaces.osax ..." & newline
	try
		do shell script "sudo rm -rf \"/Library/ScriptingAdditions/TotalSpaces.osax\"" with administrator privileges
	on error
		set stdout to stdout & "    unable to remove /Library/ScriptingAdditions/TotalSpaces.osax" & newline
	end try
		
	set stdout to stdout & "  relaunch Dock ..." & newline
	try
		tell application "Dock" to launch
	on error
		set stdout to stdout & "    failed to relaunch Dock" & newline
	end try
	
	set stdout to stdout & "TotalSpaces2 uninstallation done"
	
	-- at this point Dock should start cleanly and with no signs of TotalSpaces
	-- you may check Events/Replies tab to see if there were no issues with uninstallation
	
	stdout -- this is needed for platypus to display output in details window
end run
