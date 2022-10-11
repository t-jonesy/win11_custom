$path = $pwd.Path
$path_lower = $path.ToLower()

new-item -force -itemtype directory mount | Out-Null
new-item -force -itemtype directory tmp | Out-Null

#Mount ISO and copy files to tmp folder
$iso = Get-ChildItem $pwd\iso | Where-Object {$_.Name -like "*iso"}
$iso = "$path\iso\$($iso.Name)"
Write-Output "Using $iso"
$mountResult = Mount-DiskImage $iso -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter
Write-Output "Mounted to $driveLetter, copying files to tmp folder"
Get-ChildItem "$($driveLetter):\" | Copy-Item -Destination $pwd\tmp\ -Recurse
Write-Output "Copy complete, dismounting"
Dismount-DiskImage $iso | out-null
Write-Output "Dismount complete"

#Mount image
Get-WindowsImage -ImagePath "$path\tmp\sources\install.wim"
Set-ItemProperty -Path "$path\tmp\sources\install.wim" -Name IsReadOnly -Value $false
#Index 6 is win11 pro
$index = Read-Host -Prompt 'Which index?'
Dism /Mount-Image /ImageFile:"$path\tmp\sources\install.wim" /Index:$index /MountDir:"$path\mount"


#Remove unused drivers
$drivers = pnputil /enum-drivers
$oems = $drivers | Select-String -Pattern "Published Name" | %{$_.Line.Split(" ")} | Select-String -Pattern ".inf"
foreach($line in $oems) {
  pnputil.exe /delete-driver $line
}

#Export and add drivers
Write-Output "Exporting drivers"
dism /Online /Export-Driver /Destination:$path\drivers | out-null
Write-Output "Adding drivers"
dism /Image:$path\mount /Add-Driver /Driver:$path\drivers /Recurse | out-null

#add autounattend.xml
Copy-Item "$path\unattend\autounattend.xml" -Destination "$path\tmp\" | out-null

#unmount image
dism /Unmount-Image /MountDir:"$path\mount" /Commit

#create custom iso
$wim = Get-WindowsImage -ImagePath "$path\tmp\sources\install.wim" -Index $index
$iso_name = "$($wim.ImageName.Replace(" ","_"))_$($wim.Version.Replace(".","_"))"
oscdimg.exe -m -o -u2 -udfver102 -bootdata:2#p0,e,b$path_lower\tmp\boot\etfsboot.com#pEF,e,b$path_lower\tmp\efi\microsoft\boot\efisys.bin $path_lower\tmp $path_lower\output\$iso_name

#remove leftovers
rm -r -fo $path\tmp\*
rm -r -fo $path\drivers\*