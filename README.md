# PowerShell for Power BI

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

