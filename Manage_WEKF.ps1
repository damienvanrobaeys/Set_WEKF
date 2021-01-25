Function Set_WEKF
	{
		param (
			[switch]$List,
			[Switch]$Remove,			
			[String]$Key_ID,
			[String]$Action
		)

		If($List)
			{
				$WEKF_Keys = @()
						
				$Get_CustomKey = (Get-WMIObject -class WEKF_CustomKey -namespace "root\standardcimv2\embedded") | Select ID, Enabled
				ForEach($Key in $Get_CustomKey)
					{
						$WEKF_Values = New-Object PSObject
						$WEKF_Values = $WEKF_Values | Add-Member NoteProperty Combination $Key.ID -passthru -force
						$WEKF_Values = $WEKF_Values | Add-Member NoteProperty "Is blocked ?" $Key.Enabled -passthru -force
						$WEKF_Values = $WEKF_Values | Add-Member NoteProperty Type "Custom" -passthru -force					
						$WEKF_Keys += $WEKF_Values
					}
						
				$Get_Pedefined = (Get-WMIObject -class WEKF_PredefinedKey -namespace "root\standardcimv2\embedded") | Select ID, Enabled
				ForEach($Key in $Get_Pedefined)
					{
						$WEKF_Values = New-Object PSObject
						$WEKF_Values = $WEKF_Values | Add-Member NoteProperty Combination $Key.ID -passthru -force
						$WEKF_Values = $WEKF_Values | Add-Member NoteProperty "Is blocked ?" $Key.Enabled -passthru -force
						$WEKF_Values = $WEKF_Values | Add-Member NoteProperty Type "Predefined" -passthru -force										
						$WEKF_Keys += $WEKF_Values
					}	

				$WEKF_Keys | out-gridview
			}
		Else
			{
				If($Action -eq "Block")
					{
						$Expected_Status = $True
					}
				ElseIf($Action -eq "Unblock")
					{
						$Expected_Status = $False
					}
				ElseIf($Action -eq "") 
					{
						$Expected_Status = $False
						$Action = "Unblock"
					}	
				ElseIf(($Action -ne "Block") -and ($Action -ne "Unblock"))
					{
						$Expected_Status = $False
						$Action = "Unblock"
					}						

				If($Key_ID -eq "")
					{
						write-warning "Please type a Key id using Key_ID switch"
						Break
					}
					
				If($remove)
					{
						$Get_Keys = Get-WMIObject -class WEKF_CustomKey -namespace "root\standardcimv2\embedded" | where {$_.Id -eq "$Key_ID"};
						If($Get_Keys) 
							{
								write-host "The key combination $Key_ID exists in WEKF_CustomKey"							
								write-host "The combination $Key_Status filter will be removed"		
								Try
									{
										$WEKF_CustomKey_Class = [wmiclass]"\\$env:computername\root\standardcimv2\embedded:WEKF_CustomKey"	
										$WEKF_CustomKey_Class.Remove($Key_ID) | out-null										
										write-host "The combination $Key_Status filter has been removed"										
									}
								Catch
									{
										write-warning "The combination $Key_Status filter has not been removed"																			
									}								
							}
						Break
					}
				Else
					{
						write-host "Expected status of this key is: $Action"
						$Change_Key_Status = $False	
						$Get_Keys = Get-WMIObject -class WEKF_PredefinedKey -namespace "root\standardcimv2\embedded" | where {$_.Id -eq "$Key_ID"};
						If($Get_Keys -ne $null)
							{
								$Key_Status = $Get_Keys.Enabled
								write-host "The key combination has been found in the predefined list"
								write-host "Is this key enabled ? $Key_Status"						
							}	
						Else
							{
								write-host "The key combination has not been found in the predefined list"	
								write-host "The custom key class will be used"							
								$Get_Keys = Get-WMIObject -class WEKF_CustomKey -namespace "root\standardcimv2\embedded" | where {$_.Id -eq "$Key_ID"};
								$Key_Status = $Get_Keys.Enabled	

								If($Get_Keys) 
									{
										write-host "The key $Key_ID already exists"
										write-host "Is this key enabled ? $Key_Status"	
									}	
								Else
									{
										write-host "The key $Key_ID does not exists"
									}					
							}
							
						If(($Key_Status -eq $Expected_Status))						
							{
								write-host "The key already have the expected status"									
							}
						Else
							{
								$Change_Key_Status = $True
							}			
							
						If(($Change_Key_Status -eq $True))						
							{
								Try
									{
										write-host "Changing status of the key $Key_ID to $Action"						
										If($Get_Keys -eq $null)							
										
											{
												Set-WMIInstance -class WEKF_CustomKey -argument @{Id="$Key_ID";Enabled=$Expected_Status} -namespace "root\standardcimv2\embedded" | out-null
											}
										Else
											{
												$Get_Keys.Enabled = $Expected_Status;
												$Get_Keys.Put() | Out-Null;								
											}
										write-host "The status for the key $Key_ID has been changed to $Action"							
									}
								Catch
									{
										write-warning "The status for the key $Key_ID has not been changed to $Action"									
									}				
							}						
					}					
			}
	}