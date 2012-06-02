New Relic Windows Azure Nuget Package
=============

Includes the latest New Relic x64 installer, so that you can easily include New Relic in your Windows Azure deployment.  

Make sure you go to New Relic first to sign up and get your key from [New Relic]( http://newrelic.com). Performance monitoring will never be the same after you do!  

The package is available through your NuGet package manager and on the [web](http://nuget.org/packages/NewRelicWindowsAzure)

**Set up:**

1. install-package NewRelicWindowsAzure  
2. The Package installer will prompt you for your NewRelic.AppName and your New Relic license key  

**Note:** If you want to instrument more than one project in your solution, simply change the "Default project" in the package manager console and install the package 

Visit [New Relic](http://rpm.newrelic.com) after your package deploy is complete to see your performance metrics.  

For more information on what this package is doing go to: https://support.newrelic.com/help/kb/dotnet/installing-the-net-agent-on-azure