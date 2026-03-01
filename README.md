# PowerShell for Power BI Repository

![Language](https://img.shields.io/badge/Language-PowerShell-blue)
![Runtime](https://img.shields.io/badge/Runtime-Local%20%7C%20Azure%20Automation-purple)
![Editor](https://img.shields.io/badge/Editor-VS%20Code-0078d7)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Cross--Platform-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-success)

---

## Overview

This repository provides a collection of PowerShell scripts to automate and manage Power BI resources and environments. Whether you're a BI admin or developer, these tools are designed to streamline your workflow using PowerShell.

---

## ⚙️ Recommended Setup

### 💻 PowerShell Version
- **Recommended:** PowerShell **7.2** or higher (cross-platform and more robust scripting support)
- To check your version:
  ```powershell
  $PSVersionTable.PSVersion

### 🧩 Required PowerShell Modules
These are modules that must be installed before running the scripts in this repo:

#### 🔹 Power BI Management
- [MicrosoftPowerBIMgmt Module](https://learn.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps)
- Installs all necessary submodules:
  - MicrosoftPowerBIMgmt.Admin
  - MicrosoftPowerBIMgmt.Capacities
  - MicrosoftPowerBIMgmt.Data
  - MicrosoftPowerBIMgmt.Profile
  - MicrosoftPowerBIMgmt.Reports
  - MicrosoftPowerBIMgmt.Workspaces
- Install with:
  ```powershell
  Install-Module -Name MicrosoftPowerBIMgmt

#### 🔐 Use Connect-PowerBIServiceAccount to authenticate.
#### ℹ️ Other modules will be covered in dedicated scripts


## 🛠 Recommended Development Environment
### 💡 Visual Studio Code
- Install: https://code.visualstudio.com
- Get extension: [PowerShell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)


  
## 📁 Project Structure
Each script has its own folder with:
- A .ps1 or .psm1 file
- A dedicated README.md for usage and parameters

## 🤝 Contributions
Contributions, issues, and suggestions are welcome! Feel free to fork this repository and open a pull request.

