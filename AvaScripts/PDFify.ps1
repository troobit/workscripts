#Create COM (Component Object Model) object to use word within the script
$word = New-Object -ComObject Word.Application

#Where do you want to work
$WorkingPath = Read-Host -Prompt "Enter a directory:"

#Gather the files you want to redo, and save them in an array, $docs
$docs = Get-ChildItem -Path $WorkingPath -filter *.doc*

ForEach ($doc in $docs)
{
    $document = $word.Documents.Open($doc.FullName)
    $newName = "$WorkingPath\$($doc.BaseName).pdf"
    $document.SaveAs([ref] $newName, [ref] 17)
    $document.Close()
}