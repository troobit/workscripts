# formatting
$Style = "
<style>
.wp-table tr:nth-child(odd) {
    background-color: #fff;
}

.wp-table tr:nth-child(even) {
    background-color: #f1f1f1;
}

.wp-table tr {
    border-bottom: 1px solid #ddd;
}

.wp-table th:first-child, 
.wp-table td:first-child {
    padding-left: 16px;
}


.wp-table td, 
.wp-table th {
    padding: 8px 8px;
    display: table-cell;
    text-align: left;
    vertical-align: top;
}
.wp-table td {
	white-space:nowrap;

}
.wp-table td:last-child {
	white-space:normal;

}
.wp-table th {
    font-weight: bold;
	background-color:#918d8c;
	color:white;
	
}
.wp-table th {
	white-space:nowrap;

}
.wp-table th:last-child {
	white-space:normal;

}
 
.wp-table {
    font-size: 13px!important;
    border: 1;
    border-color:#ccc;
    border-collapse: collapse;
    border-spacing: 0;
    width: 50%;
    display: table;
    font-family:Arial, Helvetica, sans-serif;
	
}
 #cectble{
    
        border:1px solid #888585;
        max-width:auto;
        background-color:#E2E2E2;

    }

    #Cectble th{

        background-color:#dc9c63;

    }

    #cectble tr{
    
        border:1px solid #888585;  

    }

    #cectble td{
    
        border:1px solid #888585; 

    }
.heading {
	color:white;
	font-size:20px;
	font-weight:bold;
	font-family:Arial, Helvetica, sans-serif;
	padding-left:10px;
    padding-right:10px;
    padding-top:10px;
    padding-bottom:10px;

}

.headingcolor {
	background-color:#026adf;

}
body {
font-family:Arial, Helvetica, sans-serif;

}
</style>
"

$Results = @()
#$Results = Get-ADGroupMember -Identity Group1 -Server s1 | Select-Object name 
#$Results.Count
$ADGroups = ('Group1','Group2','Group3')
foreach ($Group in $ADGroups)
    {
     $count = 0
     $count = (Get-ADGroupMember -Identity $Group -Server s1 | Where-Object objectclass -eq user).count

     $Result = New-Object PSObject
     $Result | Add-Member NoteProperty -Name 'Group_Name' -Value $Group
     $Result | Add-Member NoteProperty -Name 'Member_Count' -Value $Count
     $Results += $Result
    }

 $ADGroups1 = ('Group4')
    foreach ($Group1 in $ADGroups1)
    {
     $count = 0
     $count = (Get-ADGroupMember -Identity $Group1 -Server dpe | Where-Object objectclass -eq user).count

     $Result = New-Object PSObject
     $Result | Add-Member NoteProperty -Name 'Group_Name' -Value $Group1
     $Result | Add-Member NoteProperty -Name 'Member_Count' -Value $Count
     $Results += $Result
    }


# convert array into html format, Change -Property to include required columns from the array
$Table1 = ($Results | ConvertTo-Html -Fragment -Property Group_Name, Member_Count) -replace "<table>", "<table class=`"wp-table`" style=`"border-color:#ccc;`" border=`"1`" >"
        
# apply final formatting and body makeup
$Date = Get-Date -Format 'yyyy-MM-dd HH:mm'
$To = 'ronan@test.com', 'ronan@test.com','ronan@test.com'
$CC = 'ronan@test.com','ronan@test.com', 'ronan@test.com'
$Subject = "Ad things []"

$Body = "$style
    <p><H3>PROTECTED</H3></p>
    <H2 style='color:blue;'>AD Group Check -$Date</H2>
    <p>Hi all,</p>
    <p></p>
    <p>This report provides you with a total count of users added to each AD group.</p>
    <p></p>
    <p>NOTE:</p>
    <p>Group3 AD Group provides users with internet access.</p>
    <p>Group2 AD Group provides users with an O365 E5 licence.</p>
    <p>$Table1</p>
    </br>
         
    <p><font face='calibri' size='3' color='red'>Warning about defence ownership of email</font></p>
"

$Body = $Body -replace '&lt;', '<'
$Body = $Body -replace '&quot;', '"'
$Body = $Body -replace '&gt;', '>'

Send-MailMessage -from hadeel.alsaad@defence.gov.au -To $To -cc $CC -Subject $Subject -BodyAsHtml -Body $Body -SmtpServer $Server