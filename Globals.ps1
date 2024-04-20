#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------

#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}


###返回用户或组的SID
function GetSidByName
{
	param
	(
		[parameter(Mandatory = $true)]
		[String]
		$name
	)
	try
	{
		$i = Get-LocalGroup -Name $name -ErrorAction Stop
		return $i.SID
	}
	catch
	{
		$i = Get-LocalUser -Name $name 
		return $i.SID
	}
	
}
###

###更新ListView中的数据
function UpdateListView
{
	param
	(
		[parameter(Mandatory = $true)]
		[System.Windows.Forms.ListView]$listView,
		[parameter(Mandatory = $true)]
		[AllowEmptyCollection()]
		[System.Collections.ArrayList]$dataList
	)
	$listView.Items.Clear()
	if ($dataList.Count -eq 0)
	{
		$saveBtn.Enabled = $false
	}
	else
	{
		$saveBtn.Enabled = $true
		$listView.Items.AddRange($dataList)
	}
}
###

### 打开用户添加表，并将所选用户传入datalist
function OpenAccountForm
{
	param
	(
		[parameter(Mandatory = $true)]
		[System.Windows.Forms.ListView]$listView,
		[parameter(Mandatory = $true)]
		[AllowEmptyCollection()]
		[System.Collections.ArrayList]$dataList
	)
	if ((Show-AccountForm_psf) -eq 'OK')
	{
		foreach ($item in $AccountForm_acListView)
		{
			if (!($dataList -contains $item.Text))
			{
				$dataList.add($item.Text)
			}
		}
	}
#	UpdateList -listView $shutDownListView
}
###
### 获取配置文件所需的SID字符串
function GetCfgSIDs  {
	param
	(
		[parameter(Mandatory = $true)]
		[Array]
		$userList
	)
	$settingStr = ""
	$newArray = @()
	foreach ($u in $userList) {
		$newArray +="*" +(GetSidByName($u))
	}
	[string]$settingStr = $newArray -join ","
	return $settingStr
}
###

###应用设置
function SetConfig{
	param
	(
		[parameter(Mandatory = $true)]
		[String]
		$cfgType
	)
	secedit /configure /db 'C:\Windows\security\local.sdb' /cfg "${cfgPath}\${cfgType}.cfg"  /quiet
}

function DelAcItem  {
	param
	(
		[parameter(Mandatory = $true)]
		[System.Windows.Forms.ListView]$listView,
		[parameter(Mandatory = $true)]
		[AllowEmptyCollection()]
		[System.Collections.ArrayList]$dataList
	)
	foreach ($item in $listView.SelectedItems)
	{
		$dataList.Remove($item.Text)
	}
}

function WriteCfgFile
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]$SIDs,
		[parameter(Mandatory = $true)]
		[string]$cfgType
	)
	$cfg =
	@"
[Unicode]
Unicode=yes
[Privilege Rights]
$cfgType = $SIDs
[Version]
signature="`$CHICAGO`$"
Revision=1
"@
	$cfg | Set-Content -Path "${cfgPath}\${cfgType}.cfg"
	
}

###生成当前配置文件
function GetCurrentCfg
{
	if (-not (Test-Path -Path $cfgPath -PathType Container))
	{
		New-Item -Path $cfgPath -ItemType Directory -Force
	}
	secedit /export /cfg $cfgPath\current.cfg
}
###

### 获取指配置设置值
function GetCurrentPolicySetting
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]$settingName,
		[Parameter(Mandatory = $true)]
		[string]$configStr	
	)
	
	$matchPattern = "(?s)$settingName =[\s]*(\d+)"
	try
	{
		$configStr -match $matchPattern | Out-Null # 匹配成功 
		$settingValue = $matches[1] # 第一个捕获组（值）
	}
	catch
	{
		# 匹配失败
		$settingValue=$null
	}
	return $settingValue
}
###

function InitPolicySetting
{
	# 文件路径
	$filePath = "${cfgPath}\current.cfg"
	$configStr = [string](Get-Content -Path $filePath)
	$policySetting['AuditSystemEvents'] =GetCurrentPolicySetting -settingName 'AuditSystemEvents' -configStr $configStr 
	$policySetting['AuditLogonEvents'] = GetCurrentPolicySetting -settingName 'AuditLogonEvents' -configStr $configStr
	$policySetting['AuditObjectAccess'] = GetCurrentPolicySetting -settingName 'AuditObjectAccess' -configStr $configStr
	$policySetting['AuditPrivilegeUse'] = GetCurrentPolicySetting -settingName 'AuditPrivilegeUse' -configStr $configStr 
	$policySetting['AuditPolicyChange'] = GetCurrentPolicySetting -settingName 'AuditPolicyChange' -configStr $configStr
	$policySetting['AuditAccountManage'] = GetCurrentPolicySetting -settingName 'AuditAccountManage' -configStr $configStr
	$policySetting['AuditProcessTracking'] = GetCurrentPolicySetting -settingName 'AuditProcessTracking' -configStr $configStr
	$policySetting['AuditDSAccess'] = GetCurrentPolicySetting -settingName 'AuditDSAccess' -configStr $configStr
	$policySetting['AuditAccountLogon'] = GetCurrentPolicySetting -settingName 'AuditAccountLogon' -configStr $configStr
	$policySetting['PasswordComplexity'] = GetCurrentPolicySetting -settingName 'PasswordComplexity' -configStr $configStr
	$policySetting['LockoutBadCount'] = GetCurrentPolicySetting -settingName 'LockoutBadCount' -configStr $configStr
	$policySetting['LockoutDuration'] = GetCurrentPolicySetting -settingName 'LockoutDuration' -configStr $configStr
	$policySetting['AllowAdministratorLockout'] = GetCurrentPolicySetting -settingName 'AllowAdministratorLockout' -configStr $configStr
	$policySetting['MinimumPasswordLength'] = GetCurrentPolicySetting -settingName 'MinimumPasswordLength' -configStr $configStr
}



[Collections.Generic.Dictionary[string,string]]$policySetting = @{ }
[string]$ScriptDirectory = Get-ScriptDirectory
$acList = @()
$eventLogProp = @{ }
$cfgPath = "C:\Users\${env:USERNAME}\AppData\Local\WinCheck"


