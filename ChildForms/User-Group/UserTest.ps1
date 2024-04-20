#Requires -Version 5
<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2024 v5.8.237
	 Created on:   	2024/4/5 20:13
	 Created by:   	Asuka
	 Organization: 	
	 Filename:     	UserTest.ps1
	===========================================================================
	.DESCRIPTION
		Description of the PowerShell class.
#>


class UserTest:System.Windows.Forms.Form  {
	
	# Class Properties
	[string]$MyProperty
	
	#Hidden Properties
	hidden [int]$MyHiddenProperty
	
	# Class Constructors
	UserTest::[System.Windows.Forms.Form] ()
	
	#Static Class Methods
	static [Boolean] MyStaticMethod ([int]$parameter)
	{
		if ($parameter -gt 0)
		{
			return $true
		}
		else
		{
			return $false
		}
	}
}

#Sample code to instantiate the class
#$myClassObject = [UserTest:System.Windows.Forms.Form]::new()

#Invoke a static method
#[UserTest:System.Windows.Forms.Form]::MyStaticMethod(1)

