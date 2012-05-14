param($installPath, $toolsPath, $package, $project)

$newrelicMsiFileName = "NewRelicAgent_x64_2.0.8.4.msi"
$newrelicCmdFileName = "newrelic.cmd"

$licenseKey = Read-Host "Please enter in your New Relic license key (optional)"

#Modify NewRelic.msi and NewRelic.cmd so that they will be copy always
$newrelicMsi = $project.ProjectItems.Item($newrelicMsiFileName)
$copyToOutputMsi = $newrelicMsi.Properties.Item("CopyToOutputDirectory")
$copyToOutputMsi.Value = 1

$newrelicCmd = $project.ProjectItems.Item($newrelicCmdFileName)
$copyToOutputCmd = $newrelicCmd.Properties.Item("CopyToOutputDirectory")
$copyToOutputCmd.Value = 1

#Modify NewRelic.cmd to accept the user's license key input 
if($licenseKey.Length -gt 0){
	$newrelicCmdFile = $newrelicCmd.Properties.Item("FullPath").Value
	$fileContent =  Get-Content $newrelicCmdFile | Foreach-Object {$_ -replace 'REPLACE_WITH_LICENSE_KEY', $licenseKey}
	Set-Content -Value $fileContent -Path $newrelicCmdFile
}
else{
	Write-Host "No Key was provided, please make sure to edit the newrelic.cmd file and add a valid New Relic license key"
}

#Modify the service config - adding a new Startup task to run the newrelic.cmd
$svcConfigFile = $DTE.Solution.Projects|Select-Object -Expand ProjectItems|Where-Object{$_.Name -eq 'ServiceDefinition.csdef'}
$ServiceDefinitionConfig = $svcConfigFile.Properties.Item("FullPath").Value
[xml] $xml = gc $ServiceDefinitionConfig

#Create startup and newrelic task nodes
$startupNode = $xml.CreateElement('Startup','http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition')
$newRelicTaskNode = $xml.CreateElement('Task','http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition')
$newRelicTaskNode.SetAttribute('commandLine',$newrelicCmdFileName)
$newRelicTaskNode.SetAttribute('executionContext','elevated')
$newRelicTaskNode.SetAttribute('taskType','simple')
$startupNode.AppendChild($newRelicTaskNode)


$modified = $xml.ServiceDefinition.WebRole.StartUp
if($modified -eq $null){
	$modified = $xml.ServiceDefinition.WebRole
	$modified.PrependChild($startupNode)
}
else{
	$nodeExists = $false
	foreach ($i in $xml.ServiceDefinition.WebRole.Startup.Task){
   		if ($i.commandLine -eq $newrelicCmdFileName){
			$nodeExists = $true
		}
	}
	if($NewRelicTask -eq $null -and !$nodeExists){
		$modified.AppendChild($newRelicTaskNode)
	}
}
$xml.Save($ServiceDefinitionConfig);

Write-Host "Package install is complete"