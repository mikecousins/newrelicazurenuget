param($installPath, $toolsPath, $package, $project)

$newrelicMsi = $project.ProjectItems.Item("NewRelicAgent_x64_2.0.8.4.msi")
$copyToOutput = $newrelicMsi.Properties.Item("CopyToOutputDirectory")
$copyToOutput.Value = 1

$newrelicMsi = $project.ProjectItems.Item("newrelic.cmd")
$copyToOutput = $newrelicMsi.Properties.Item("CopyToOutputDirectory")
$copyToOutput.Value = 1

$filepath = $project.ProjectName + '.Azure\ServiceDefinition.csdef'
$ServiceDefinitionConfig = $installPath.Replace("packages\NewRelicWindowsAzure.1.0.0.4", $filepath)

Write-Host $ServiceDefinitionConfig
 
[xml] $xml = gc $ServiceDefinitionConfig

$startupNode = $xml.CreateElement('Startup','http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition')

$newRelicTaskNode = $xml.CreateElement('Task','http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition')
$newRelicTaskNode.SetAttribute('commandLine','newrelic.cmd')
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
   		if ($i.commandLine -eq 'newrelic.cmd'){
			$nodeExists = $true
		}
	}
	if($NewRelicTask -eq $null -and !$nodeExists){
		$modified.AppendChild($newRelicTaskNode)
	}
}

$xml.Save($ServiceDefinitionConfig);