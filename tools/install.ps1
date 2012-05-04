param($installPath, $toolsPath, $package, $project)
$newrelicMsi = $project.ProjectItems.Item("NewRelicAgent_x64_2.0.8.4.msi")
$copyToOutput = $newrelicMsi.Properties.Item("CopyToOutputDirectory")
$copyToOutput.Value = 1