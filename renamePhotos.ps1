param (
	[string]$path
)

if (!$path) {
	Write-Host "No path provided";
	Exit;
}

function ConfirmMessageBox {
    param(
        [parameter(Mandatory=$False)][String]$WinTitle='Rename Photos?',
        [parameter(Mandatory=$False)]$MsgText='Do you want to proceed?'
    )
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $result = [Windows.Forms.MessageBox]::Show($MsgText, $WinTitle, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Question)
    If ($result -eq [Windows.Forms.DialogResult]::Yes) {
        Return $true
    }
    Else {
        Return $false
    }
}

function gatherPhotos {
	[parameter(Mandatory=$True)][String]$path | Out-Null
	
	$validExtensions = @("*.jpg","*.arw")
	$path = $path + "\*"
	[Array]$photoArray = Get-ChildItem -Path $path -File -Include $validExtensions
	
	return $photoArray
}

function processPhotos {
	param(
		[parameter(Mandatory=$True)][Array]$photoArray,
		[Switch]$renamePhotos
	)
	if ($renamePhotos.IsPresent) {
		Write-Host "Renaming photos:"
	} else {
		Write-Host "Photos will be renamed as follows if you choose to proceed:"
	}
	foreach ($photo in $photoArray) {
		#Write-Host $photo
		$photoTags = [TagLib.File]::Create((resolve-path $photo))
		switch ($photoTags.Tag.Model) {
			"iPhone" { $cameraModel = "IPHONE" }
			"iPhone 3G" { $cameraModel = "IPHONE3G" }
			"iPhone 3GS" { $cameraModel = "IPHONE3GS" }
			"iPhone 4" { $cameraModel = "IPHONE4" }
			"iPhone 4S" { $cameraModel = "IPHONE4S" }
			"Canon PowerShot SD880 IS" { $cameraModel = "SD880" }
			"NEX-5" { $cameraModel = "NEX5" }
			"Nexus 4" { $cameraModel = "NEXUS4" }
			"Nexus 5" { $cameraModel = "NEXUS5" }
		}
		if ($photoTags.Tag.DateTime -eq $null) {
			Write-Host "    **ERR** Skipping file" $photo.Name "as it doesn't contain valid DateTaken value"
			continue
		}
		$dateTaken = $photoTags.Tag.DateTime.ToString("yyyyMMdd")
		[regex]$regex = '_(?<number>[\d]*)$|DSC0(?<number>[\d]*)$'
		$match = $regex.match($photo.BaseName)
		if (!$match) {
			Write-Host "    **ERR** Skipping file" $photo.Name "as it doesn't match a known filename format"
			continue
		} else {
			$photoNumber = $match.groups["number"].captures.Value
		}
		#if ($photo.BaseName -match $regex) {
			#$photoNumber = $matches[1]
		#}
		if ($photoNumber.Length -lt 4) {
			Write-Host "    **ERR** Skipping file" $photo.Name "as it doesn't contain at least 4 digits in it's photo number"
			continue
		}
		$newFileName = $cameraModel + "_IMG_" + $dateTaken + "_" + $photoNumber + $photo.Extension
		if ($renamePhotos.IsPresent) {
			Write-Host "    Renaming:" $photo.Name "->" $newFileName
			$oldFile = $photo
			$newFile = $photo.DirectoryName + "\" + $newFileName
			Rename-Item $oldFile $newFile
		} else {
			Write-Host "   " $photo.Name "->" $newFileName
		}
	}
}


$photoArray = gatherPhotos $path
#foreach ($photo in $photoArray) {Write-Host $photo}
$taglibPath = $env:USERPROFILE + '\OneDrive\Common\taglib.2.1.0.0\lib\taglib-sharp.dll'
[Reflection.Assembly]::LoadFrom((Resolve-Path $taglibPath)) | Out-Null
processPhotos $photoArray
$userAnswer = ConfirmMessageBox

if ($userAnswer) {
	processPhotos $photoArray -renamePhotos
} else {
	Write-Host "Exiting..."
	Exit
}
