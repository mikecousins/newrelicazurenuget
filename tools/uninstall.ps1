param($installPath, $toolsPath, $package, $project)

#Modify the service config - removing the Startup task to run the newrelic.cmd
$svcConfigFile = $DTE.Solution.Projects|Select-Object -Expand ProjectItems|Where-Object{$_.Name -eq 'ServiceDefinition.csdef'}
$ServiceDefinitionConfig = $svcConfigFile.Properties.Item("FullPath").Value
[xml] $xml = gc $ServiceDefinitionConfig

$startupnode = $xml.ServiceDefinition.WebRole.Startup
if($startupnode.ChildNodes.Count -gt 0){
	$node = $xml.ServiceDefinition.WebRole.Startup.Task | where { $_.commandLine -eq "newrelic.cmd" }
	[Void]$node.ParentNode.RemoveChild($node)
	if($startupnode.ChildNodes.Count -eq 0){
		[Void]$startupnode.ParentNode.RemoveChild($startupnode)
	}
	$xml.Save($ServiceDefinitionConfig)
}