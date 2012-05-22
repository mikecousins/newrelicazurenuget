
function create_dialog([System.String]$title, [System.String]$msg){
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

	$objForm = New-Object System.Windows.Forms.Form 
	$objForm.Text = $title
	$objForm.Size = New-Object System.Drawing.Size(300,200) 
	$objForm.StartPosition = "CenterScreen"

	$objForm.KeyPreview = $True
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
	    {$x=$objTextBox.Text;$objForm.Close()}})
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
	    {$objForm.Close()}})

	$OKButton = New-Object System.Windows.Forms.Button
	$OKButton.Location = New-Object System.Drawing.Size(75,120)
	$OKButton.Size = New-Object System.Drawing.Size(75,23)
	$OKButton.Text = "OK"
	$OKButton.Add_Click({$x=$objTextBox.Text;$objForm.Close()})
	$objForm.Controls.Add($OKButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Size(150,120)
	$CancelButton.Size = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text = "Cancel"
	$CancelButton.Add_Click({$objForm.Close()})
	$objForm.Controls.Add($CancelButton)

	$objLabel = New-Object System.Windows.Forms.Label
	$objLabel.Location = New-Object System.Drawing.Size(10,20) 
	$objLabel.Size = New-Object System.Drawing.Size(280,60) 
	$objLabel.Text = $msg
	$objForm.Controls.Add($objLabel) 

	$objTextBox = New-Object System.Windows.Forms.TextBox 
	$objTextBox.Location = New-Object System.Drawing.Size(10,80) 
	$objTextBox.Size = New-Object System.Drawing.Size(260,20) 
	$objForm.Controls.Add($objTextBox) 

	$objForm.Topmost = $True

	$objForm.Add_Shown({$objForm.Activate()})
	[void] $objForm.ShowDialog()
	return $x
}

#Modify NewRelic.msi and NewRelic.cmd so that they will be copy always
function update_newrelic_project_items([System.__ComObject] $project, [System.String]$msi){
	$newrelicMsi = $project.ProjectItems.Item($msi)
	$copyToOutputMsi = $newrelicMsi.Properties.Item("CopyToOutputDirectory")
	$copyToOutputMsi.Value = 1

	$newrelicCmd = $project.ProjectItems.Item("newrelic.cmd")
	$copyToOutputCmd = $newrelicCmd.Properties.Item("CopyToOutputDirectory")
	$copyToOutputCmd.Value = 1
	
	#Modify NewRelic.cmd to accept the user's license key input 
	$licenseKey = create_dialog "License Key" "Please enter in your New Relic license key (optional)"

	if($licenseKey.Length -gt 0){
		$newrelicCmdFile = $newrelicCmd.Properties.Item("FullPath").Value
		$fileContent =  Get-Content $newrelicCmdFile | Foreach-Object {$_ -replace 'REPLACE_WITH_LICENSE_KEY', $licenseKey}
		Set-Content -Value $fileContent -Path $newrelicCmdFile
	}
	else{
		Write-Host "No Key was provided, please make sure to edit the newrelic.cmd file and add a valid New Relic license key"
	}	
}

#Modify the service config - adding a new Startup task to run the newrelic.cmd
function update_azure_service_config(){
	$svcConfigFile = $DTE.Solution.Projects|Select-Object -Expand ProjectItems|Where-Object{$_.Name -eq 'ServiceDefinition.csdef'}
	$ServiceDefinitionConfig = $svcConfigFile.Properties.Item("FullPath").Value
	[xml] $xml = gc $ServiceDefinitionConfig

	#Create startup and newrelic task nodes
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
	   		if ($i.commandLine -eq "newrelic.cmd"){
				$nodeExists = $true
			}
		}
		if($NewRelicTask -eq $null -and !$nodeExists){
			$modified.AppendChild($newRelicTaskNode)
		}
	}
	$xml.Save($ServiceDefinitionConfig);
}

# Depending on how many worker roles / web roles there are in this project 
# we will use this value for the config key NewRelic.AppName
# Prompt use to enter a name then >> Solution name >> more than one role we will attempt to use worker role name
function set_newrelic_appname_config_node([System.Xml.XmlElement]$node, [System.String]$pn){
	$appName = create_dialog "NewRelic.AppName Key" "Please enter in the value you would like for the NewRelic.AppName AppSetting for the project named $pn (optional, if none is provided we will use the solution name)"
	if($node -ne $null){
		if($appName.Length -gt 0){
			$node.SetAttribute('value',$appName)
		}
		else{
			if($node.value.Length -lt 1){
				$node.SetAttribute('value',$pn)
			}
		}
	}
	return $node
}

#Modify the [web|app].config so that we can use the project name instead of a static placeholder
function update_project_config([System.__ComObject] $project){
	$config = $project.ProjectItems.Item("Web.Config")
	$configPath = $config.Properties.Item("LocalPath").Value
	[xml] $configXml = gc $configPath

	if($configXml -ne $null){
		$newRelicAppSetting = $configXml.configuration.appSettings.SelectSingleNode("//add[@key = 'NewRelic.AppName']")
		if($newRelicAppSetting -ne $null){
			set_newrelic_appname_config_node $newRelicAppSetting $project.Name.ToString()
		}
		else{
			#add the node
			$settingNode = $configXml.configuration.appSettings
			$addSettingNode = $configXml.CreateElement('add')
			$addSettingNode.SetAttribute('key','NewRelic.AppName')
			set_newrelic_appname_config_node $addSettingNode $project.Name.ToString()
			$settingNode.AppendChild($addSettingNode)
		}
		
		$configXml.Save($configPath);
	}
}