<# =====================================================================================================================
    Script:     CrossRegionWorkspaceMigration.ps1
    Purpose:    Script moves workspaces to a different region, while handling Large Semantic Models
    Author:     Paweł Wrona
    Version:    1.0
    Updated:    2025-07-31
===================================================================================================================== #>



# ====================== [0] Config Section ======================
# Make sure to have your Tenant Admin rights activated before running this script.
# scriptMode = 0 -> You provide $sourceCapacity ID. All workspaces from this Capacity will be migrated.
# scriptMode = 1 -> You provide the list of Workspaces that will be migrated.

# Select Script Mode
$scriptMode = 1

# Your UPN. Will be used to assign Admin role in Workspaces in case it is missing.
$upn = ""

# Set the source and target values.
$sourceWorkspaces = @("") 
$sourceCapacityId = ""
$targetCapacityId = ""

# Insert path to save your output files. Must not end with "\".
$outputFilesPath = ""


# ====================== [1] Start the Script ======================

# Import the Power BI module.
Import-Module MicrosoftPowerBIMgmt
# Connect to Power BI service.
Connect-PowerBIServiceAccount



# ====================== [2] Capacity Validation ======================
# Scripts grabs Capacity information from Tenant and check if Target Capacity exists.
# When $scriptMode = 0, script will also check the source Capacity and collect Workspaces in Scope.

# Fetch capacities in the organization
$capacities = Get-PowerBICapacity -Scope Organization -WarningAction SilentlyContinue

# Check for source Capacity. Only in scriptMode = 0.
if ($scriptMode -eq 0) {
    $sourceCapacity = $capacities | Where-Object { $_.Id -eq $sourceCapacityId }

    # Check if source capacity is found.
    if ($null -eq $sourceCapacity) {
        Write-Host "Error: Source capacity with ID '$sourceCapacityId' not found." -ForegroundColor Red
        Disconnect-PowerBIServiceAccount
        return
    }

    # Display information about current stage.
    Write-Host "Getting all workspaces in a tenant..." -ForegroundColor Blue
    $allWorkspaces = Get-PowerBIWorkspace -Scope Organization -All -WarningAction SilentlyContinue

    # Display information about current stage.
    Write-Host "Limit workspaces to those associated with source capacity: '$($sourceCapacity.DisplayName)'..." -ForegroundColor Blue

    # Filter workspaces based on the source capacity.
    $sourceWorkspaces = $allWorkspaces |
        Where-Object { $_.CapacityId -eq $sourceCapacityId } |
        Select-Object -ExpandProperty Id |
        ForEach-Object { $_.ToString() }

    # Display information about current stage.
    Write-Host "Starting to move workspaces..." -ForegroundColor Blue

}

# Check for target Capacity.
$targetCapacity = $capacities | Where-Object { $_.Id -eq $targetCapacityId }

if ($null -eq $targetCapacity) {
    Write-Host "Error: Target capacity with ID '$targetCapacityId' not found." -ForegroundColor Red
    Disconnect-PowerBIServiceAccount
    return
}

# Confirm operation of moving workspaces to a Target Capacity.
$targetCapacityName = $targetCapacity.DisplayName
Write-Host "Moving workspaces to '$targetCapacityName'..." -ForegroundColor Blue


# ====================== [3] Main Loop: Workspace Level ======================

# When Workspace exists, script will start with collecting Semantic Models.
# It will check if there are Large Semantic Models among them.
# If there are none, Workspace will be moved to a new Capacity.
# If there are Large Semantic Models, script will handle it as described in section [3.1].

# Stores converted datasets for entire script.
$convertedDatasets = New-Object -TypeName System.Collections.ArrayList
# Stores converted datasets within a currnet Workspace in loop.
$convertedDatasetsCurrentWS = New-Object -TypeName System.Collections.ArrayList
# Stores datasets that failed to be converted to Small Semantic Model Storage Format.
$failedToConvertItems = New-Object -TypeName System.Collections.ArrayList
# Stores datasets that failed to be converted back to Large Semantic Model Storeage Format.
$failedToConvertBackItems = New-Object -TypeName System.Collections.ArrayList


foreach ($workspace in $sourceWorkspaces) {

    # Get Workspace Metadata and concirm if Workspace exists.
    $workspaceInfo = Get-PowerBIWorkspace -Id $workspace -Scope Organization -WarningAction SilentlyContinue
    # Flag that informs if script needed to grant user Admin access for given workspace [1 - access was granted].
    $accessGranted = 0
    # Flag that informs if there were errors during semantic model conversion to Small Semantic Model Storage Format.
    $conversionErrors = 0

    # Reset current workspace collection.
    $convertedDatasetsCurrentWS.Clear()
    $convertedDatasetsCurrentWSCount = 0
    
    
    # Check if Workspace exists and continue the script.
    if ($null -ne $workspaceInfo) {

        # Workspace exists, proceed with further actions.
        Write-Host "`n`n"
        Write-Host "********************************************************************************************" -ForegroundColor Blue
        Write-Host "Processing workspace: '$($workspaceInfo.Name)'" -ForegroundColor Blue
        Write-Host "********************************************************************************************" -ForegroundColor Blue
        Write-Host ""

        # Retrieve datasets from Workspace.
        $datasets = Get-PowerBIDataset -WorkspaceId $workspace -Scope Organization -WarningAction SilentlyContinue

        # Filter datasets where TargetStorageMode is "PremiumFiles".
        $premiumFilesDatasets = $datasets | Where-Object { $_.TargetStorageMode -eq "PremiumFiles" }

        
        
        # ====================== [3.1] If Workspace contains Large Semantic Models ======================
        
        # Script must perform following operations:
        # Check if user has direct access to Workspace. Grant access if needed.
        # Start converting Semantic Models to Small Semantic Models (SSMs).
        # Set $conversionErrors flag to 1 when Semantic Model can't be converted.

        if ($premiumFilesDatasets) {

            # Calculate how many Large Semantic Models are in workspace.
            $premiumDatasetsCount = $premiumFilesDatasets | Measure-Object | Select-Object -ExpandProperty Count

            # Reset the counter.
            $counter = 0

            Write-Host "Found $premiumDatasetsCount datasets with TargetStorageMode 'PremiumFiles' in workspace '$($workspaceInfo.Name)':" -ForegroundColor Blue


            # ====================== [3.2] Check for Workspace Level Access ======================

            # Get Workspace Metadata. If action failes, script will grant access to a Workspace.
            $getWorkspace = Get-PowerBIWorkspace -Id $workspace
            if (-not $getWorkspace) {
                
                Write-Host ""
                Write-Host "Direct access to Workspaces is missing. Granting access..." -ForegroundColor Yellow
                
                # Grant Admin access to this workspace
                Add-PowerBIWorkspaceUser -Scope Organization -Id $workspace -UserPrincipalName $upn -AccessRight Admin -WarningAction SilentlyContinue

                # Set flag indicating that access was granted. It is used later to revoke the access.
                $accessGranted = 1
                Start-Sleep -Seconds 15
                Write-Host "Access to Workspace granted. Proceeding with conversion..." -ForegroundColor Green
                
            } else {
                Write-Host "`nConverting $premiumDatasetsCount datasets..." -ForegroundColor Blue
            }
            
            
            # ====================== [3.3] Convert Semantic Models to Small Storage Format ======================
            
            foreach ($dataset in $premiumFilesDatasets) {

                # Update the storage mode to "Abf" (replace with the appropriate cmdlet or API call).
                try {
                    
                    # Attempt to update the dataset's storage mode.
                    Set-PowerBIDataset -Id $($dataset.Id) -TargetStorageMode Abf -ErrorAction Stop

                    $convertedItem = [PSCustomObject]@{
                        WorkspaceName = $workspaceInfo.Name
                        DatasetId = $dataset.Id
                        DatasetName = $dataset.Name
                    }
                    
                    # Add current Semantic Model to Current WS collection.
                    [void]$convertedDatasetsCurrentWS.Add($convertedItem)
                    
                    # Increment the counter.
                    $counter++
                    # Display the current status with the counter.
                    Write-Host -NoNewline "`rConverted datasets: $counter/$premiumDatasetsCount" -ForegroundColor Blue
        
                } catch {
                    # Handle the error.
                    Write-Host "`rFailed to update dataset '$($dataset.Name)'. Error: $_" -ForegroundColor Red

                    $failedItem = [pscustomobject] @{
                        WorkspaceName = $workspaceInfo.Name
                        DatasetId = $dataset.Id
                        DatasetName = $dataset.Name
                    }
                    
                    # Add failed item to collection
                    [void]$failedToConvertItems.Add($failedItem)

                    # Set conversion error flag
                    $conversionErrors = 1
                }
            }

        # ====================== [3.4] If Workspace doesn't contain Large Semantic Models ======================
        } else {
            Write-Host "No datasets with TargetStorageMode 'PremiumFiles' found in workspace '$($workspaceInfo.Name)'." -ForegroundColor Blue
        }
        

        # ====================== [3.5] Move Workspace to new Capacity ======================

        
        # Updating Semantic Models Storage Format takes time. Workspace can't be moved to new location before process is complete.
        # If Workspace is moved too soon, Storage Format setting appears to be stuck in Power BI Service (spinning wheel).
        # Script is using Get-WorkspaceMigrationStatus method to check if change is done, only then workspace is migrated.

        Write-Host ""
        
        if ($convertedDatasetsCurrentWS) {
            Write-Host "Wait for all datasets to finish conversion..." -ForegroundColor Blue

            # It may happen that you script will check status multiple time.
            # Counter is added just for script interactivity, it will show how many times status was checked.
            $counter = 0
            # Loop until the status is "Completed"
            do {
                # Wait for a few seconds before checking again
                Start-Sleep -Seconds 30
                $counter++
                # Run the command and capture the output
                $result = Get-PowerBIWorkspaceMigrationStatus -Id $workspace

                # Extract the Status field
                $status = $result.Status

                Write-Host -NoNewline "`rCurrent Status: $status | Query Count: $counter" -ForegroundColor Blue

            } while ($status -ne "Completed")

            Write-Host ""
            Write-Host "All Items in workspace have been converted!" -ForegroundColor Green
        }

        # ====================== [3.6] Check for Conversion errros and migrate the Workspace ======================

        # Check if there were errors during conversion.
        # Workspace is migrated only when there were no errors.
        if ($conversionErrors -eq 0){
            
            # Converted Items are added to the collection only when there are no errors.
            [void]$convertedDatasets.Add($convertedDatasetsCurrentWS)
            
            # Move workspace to target Capacity
            try {

                Set-PowerBIWorkspace -Scope Organization -Id $($workspaceInfo.Id) -CapacityId $targetCapacityId -ErrorAction Stop -WarningAction SilentlyContinue
                Write-Host "Succesfully moved workspace: '$($workspaceInfo.Name)' to '$targetCapacityName' Capacity." -ForegroundColor Green

            } catch {
                
                Write-Host "Failed to move workspace '$($workspaceInfo.Name)'. Error: $_" -ForegroundColor Red
            }
        } else {

            # In case there were errors during Semantic Models conversion, Workspace is not moved to new region.
            # Failed Items Log shows which items caused the problem.
            Write-Host "One or more items couldn't be converted, check the logs for more details" -ForegroundColor Red
        }

        
        # ====================== [3.7] Convert Semantic Models back Large Storage Format ======================
        
        # Change Semantic Models back PremiumFiles Storage Mode.
        # If Workspace was not migrated, conversion is done back in original Workspace to restore previous settings.
        Write-Host ""
        $counter = 0
        if ($convertedDatasetsCurrentWS) {
            
            # Calculate the count of Semantic Models that will be converted back to Large Storage Format.
            $convertedDatasetsCurrentWSCount = $convertedDatasetsCurrentWS | Measure-Object | Select-Object -ExpandProperty Count
            
            Write-Host "Converting back $convertedDatasetsCurrentWSCount datasets to PremiumFiles Storage Mode" -ForegroundColor Blue
            
            # Reset the error counter
            $errorCounter = 0

            # Converted Semantic Models back to Large Storage Format
            foreach ($dataset in $convertedDatasetsCurrentWS) {
                $counter++
                try {
                    
                    # Attempt to update the dataset's storage mode.
                    Set-PowerBIDataset -Id $($dataset.DatasetId) -TargetStorageMode PremiumFiles -ErrorAction Stop

                    Write-Host -NoNewline "`rConverted datasets: $counter/$convertedDatasetsCurrentWSCount" -ForegroundColor Blue

                } catch {
                    # Handle the error.
                    Write-Host "`rFailed to update dataset '$($dataset.DatasetName)'. Error: $_" -ForegroundColor Red

                    $failedItem2 = [pscustomobject] @{
                        WorkspaceName = $workspaceInfo.Name
                        DatasetId = $dataset.DatasetId
                        DatasetName = $dataset.DatasetName
                    }
                    
                    # Add failed Semantic Models to collection.
                    [void]$failedToConvertBackItems.Add($failedItem2)
                    $errorCounter += 1
                }

            }

            if ($errorCounter -eq 0) {
                Write-Host ""    
                Write-Host "Datasets were succesfully converted back to Premium Files Storage Mode" -ForegroundColor Green

            } else {
                Write-Host ""
                Write-Host "Operation completed with errors. Check Failed items at the end of the script" -ForegroundColor Red
                
            }
        }

        # Checks if script needed to grant you access to current Workspace.
        # If flag is set to 1, your access will be revoked.
        if ($accessGranted -eq 1) {

            Write-Host "Removing Admin access rights from workspace: '$($workspaceInfo.Name)'" -ForegroundColor Yellow
            # Revoke Admin Access from Workspace
            Remove-PowerBIWorkspaceUser -Scope Organization -Id $workspace -UserPrincipalName $upn -WarningAction SilentlyContinue
        }

    } else {
        # In case Workspace was not found, move to next one.
        Write-Host "Workspace '$workspace' not found. Skipping..." -ForegroundColor Red
    }
}


# ====================== [4] Save output files to your local drive ======================

# Save output files to a specified location.
# If $outputFilesPath was not provided, this step is omitted.

if ($outputFilesPath){
    
    $day = (Get-Date).ToString("yyyy-MM-dd")

    # Initialize File Paths used to read/write operations
    $convertedDatasetsPath = "$($outputFilesPath)\converted-datasets-$($day).csv"
    $failedToConvertItemsPath = "$($outputFilesPath)\failed-datasets-$($day).csv"

    # Save scope Arrays to dedicated .csv files
    $convertedDatasets | Export-Csv -Encoding UTF8 -NoTypeInformation -Path $convertedDatasetsPath
    $failedToConvertItems | Export-Csv -Encoding UTF8 -NoTypeInformation -Path $failedToConvertItemsPath    
}

# Disconnect the session
Disconnect-PowerBIServiceAccount
