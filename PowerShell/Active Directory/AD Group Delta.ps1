# 1. Read from AD Groups
# 2. Convert to CSV and save in some directory
# 3. Load from some directory and get a delta if possible
# 4. Create CSV of delta (and save it as a file?)
# Need to have reference files first. n1 = today: n0 = last record (or null)
# 5. Send email with attachment. Saved CSV for today & delta. Still send today's if unable to generate delta.

# VARIABLES - CHANGE THESE AS NECESSARY!!
[string]$dateString = Get-Date -Format "yyyy-MM-dd"
$From = "Ronny Drew <Ronny.Drew@email.com>"
$To = "Seamus Heaney <Seamus.Heaney@email.com>", "Barry McGillicuddy <Barry@email.com>"
$CC = "Paddy Powers <Paddy@email.com", "Martin McFly <marty@email.com>"
$SMTPServer = 'what.server.are.you.using'
$Subject = "User in AD group x | $dateString"
$path = 'C:\scripts'

Set-Location $path

#n0 - the comparison object (yesterday's output), will be NULL if there isn't one prior or it can't find it.
$n0 = Import-Csv -Path (Get-ChildItem -Exclude *delta* -Filter *.csv | Sort-Object LastWriteTime | Select-Object -Last 0).name -ErrorAction SilentlyContinue
$deltaExists = $null -ne $n0 #Boolean for if/else stuff later
$n1 = Get-ADGroupMember -Identity Group2 -Server s1 | Where-Object objectclass -eq user | Select-Object name

#Define the filename based on today's date
$filename = ($path + "\group2Names_" + $dateString + ".csv")
#Export the file!
$n1 | Export-Csv -Path $filename -Force -NoTypeInformation

#IF we got a file input from the Import-Csv statement above, generate a delta
if ($deltaExists){
    $delta = (Compare-Object -ReferenceObject $n0 -DifferenceObject $n1 -Property name -IncludeEqual | Where-Object -Property 'SideIndicator' -eq '=>' | Select-Object -Property name)
    $delta | Export-Csv -Path ($path + "\delta.csv") -Force -NoTypeInformation
}

#Create the email message string!
[String]$Style = Get-Content .\htmlStyle.txt #Imported from a text file in an attempt to keep this file cleaner.

$Body = "$Style
<p><h3>PROTECTED</h3></p>
<h2 style='color:blue;'>O365 License Membership - $dateString</h2>
<p>Good morning team,</p>
<p></p>
<p>Attached to this email is a list of users that are currently in the AD Group which provides access to Project VERA and the Office 356 E5 licence therin</p>
<p></p>
</br>
"
# Include the delta if it exists/could be generated. If not... don't?
if ($deltaExists){
    $attachments = $filename, ($path + "\delta.csv")
    $Body = $Body + "<p>Also included is the delta between the current users and the last time this check was made, as <em>delta.csv</em></p>"
} else {
    $attachments = $filename
}
$Body = $Body + "</br><p><font face='calibri' size='3' color='red'>Warning about defence ownership of email</font></p>"
$Body = $Body -replace '&lt;', '<'
$Body = $Body -replace '&quot;', '"'
$Body = $Body -replace '&gt;', '>'

# Send the email WITH the attachments
Send-MailMessage -From $From -To $To -cc $CC -Subject $Subject -BodyAsHtml -Body $Body -Attachments $attachments -SmtpServer $SMTPServer