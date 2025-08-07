# Setup

## 📃 Requirements
- You must have Admin role activated on your account
- Follow general PowerShell [instructions](https://github.com/PWrona86/PowerShell-Scripts/blob/main/README.md)

## ⚙️ Configuration
Provide necessary input in Configuration secrion of the code:
- **scriptMode** (0 - to fetch all workspaces from specified Capacity, 1 - to provide list of workspaces manually)
- **upn** - your organizational user email, it will be used to grant Workspace access in case it is missing
- **sourceCapacityId/sourceWorkspaces** - depending on Script Mode selected, provide either Capacity ID or IDs of Workspace you would like to migrate
- **targetCapacityId** - Capacity where workspaces will be migrated
- **outputFilesPath** - if provided, script will save logs to given location

More detailed description of the script can be found here:
https://otcbi.net/move-power-bi-workspaces-to-a-different-region-powershell-script/

## High-level algorithm
Script contains a lot of comments to make it easier to understand the process. Please find below high-level diagrams showing how script works.

### Main Program:
<p align="center">
  <img src="./images/ps_main_program.svg" alt="Main Program" width="600">
</p>

### Processing Workspaces:
<p align="center">
  <img src="./images/ps_process_workspaces.svg" alt="Process Workspaces" width="600">
</p>

### Processing Large Semantic Models:
<p align="center">
  <img src="./images/ps_process_semantic_models.svg" alt="Process Large Semantic Models" width="600">
</p>
