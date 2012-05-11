param($installPath, $toolsPath, $package, $project)

$filepath = $project.ProjectName + '.Azure\ServiceDefinition.csdef'
$ServiceDefinitionConfig = $installPath.Replace("packages\NewRelicWindowsAzure.1.0.0.4", $filepath)
 
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