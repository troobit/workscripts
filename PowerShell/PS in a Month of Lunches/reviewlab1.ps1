<# 1.
Run a command that will show the newest 100 entries from the application event log.
Do NOT use Get-WinEvent #>
Get-EventLog -LogName Application -Newest 100
<# 2.
Get the top 5 Processes  based on virtual memory (VM) usage #>
Get-Process | Sort-Object -Property VirtualMemorySize -Descending | Select-Object -First 5 | Out-GridView
<# 3.
Create a CSV that contains ALL services, including only the service name and status.
Have running services listed BEFORE stopped services. #>
Get-Service | Select-Object -Property Name,Status | Sort-Object -Property Status -Descending #May be a better way to do this one... Descending works because R < S?
<# 4.
Consider BITS (Background Intelligent Transfer System - used for using available bandwidth to
download update files et al). Write a command line that changes the startup type of the BITS service to Manual#>

Get-Service -Name BITS | Set-Service -StartupType Manual
Get-Service -Name BITS | Set-Service -StartupType Automatic

<# 5.
Display a list of files named win*.* on your computer.
Start in the C:\ folder. You may need to experiment and use
Some new parameters of a cmdlet in order to complete this task #>

Get-ChildItem C:\ -Recurse -Filter 'win`*.`*' -File

<# 6.
Get a directory listing for C:\Program Files.
Include all subfolders and files. Direct it to a text file named C:\Dir.txt
(Remember the > redirector, or out-file cmdlet #>

Get-ChildItem 'C:\Program Files' -Recurse | Out-File -FilePath C:\Dir.txt

<# 7.
Get a list of the 20 most recent entries from the security event log.
Convert the info to XML. Do not create a file on disk, but display the XML
in the console window#>
(Get-EventLog -LogName Security -Newest 20 | ConvertTo-Xml).InnerXml
<# 8.
Get a list of all event logs on the computer, selecting the log name,
the maximum size, and overflow action. Convert it to CSV, without writing
to a log file. #>
get-eventlog * | Select-Object -Property OverflowAction,MaximumKilobytes,LogDisplayName | ConvertTo-Csv
<# 9.
Get a list of services - keeping only the names, display names, & statuses.
Send the info to an HTML file with a title of "Service Report".
Have the phrase "Installed Services" displayed before the table of service info.
If possible display Installed Services with an <H1> tag. Verify in a browser.#>
Get-Service | Select-Object DisplayName,Name,Status
<# 10.
Create a new alias named D which runs Get-ChildItem.
Export JUST that alias to a file. Now, close the shell and
open a new console window, and import the alias.
Make sure it works.#>
New-Alias d Get-ChildItem
Export-Alias -Path C:\Users\ronan.obrien\Documents\WindowsPowerShell\alias -Name d
Import-Alias -Path C:\Users\ronan.obrien\Documents\WindowsPowerShell\alias
<# 11.
Display installed hotfixes that are either 'Hotfix' or 'Update'
but not Security Update.#>
Get-HotFix | Where-Object -Property Description -In Update,Hotfix | Format-Table -AutoSize
<# 12.
Run a command that will display the current directory the shell is in#>
Get-Location
<# 13.
Run a command that will display the most recent commands that you have run in the
shell. Locate the command that you ran for task 11. Using two commands connected
by a pipeline, rerun the command from task 11.
In other words, if Get-Something is the command that retrieves historical commands,
5 is the ID number of the command from task 11, and Do-Something is the
command that runs historical commands, run this:
Get-Something id 5 | Do-Something
Of course, those aren’t the correct cmdlet names—you’ll need to find those. Hint:
both commands that you need have the same noun.
#>
Get-History
<# 14.
Run a command that modifies the Security event log to overwrite old events as
needed.
#>

<# 15.
Use the New-Item cmdlet to make a new directory named C:\Review. This is not the
same as running Mkdir; the New-Item cmdlet will need to know what kind of new item
you want to create. Read the help for the cmdlet.
#>

<# 16.
Display the contents of this registry key:
HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
Note: “User Shell Folders” is not exactly like a directory. If you change into that "directory,"
you won’t see anything in a directory listing. User Shell Folders is an item, and
what it contains are item properties. There’s a cmdlet capable of displaying item properties
(although cmdlets use singular nouns, not plural).
#>

<# 17.
Find (but do not run) cmdlets that can...
 Restart a computer
 Shut down a computer
 Remove a computer from a workgroup or domain
 Restore a computer’s System Restore checkpoint
#>

<# 18.
What command do you think could change a registry value? Hint: it’s the same noun
as the cmdlet you found for task 16.
#>
