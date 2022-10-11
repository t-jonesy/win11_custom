## Windows ISO builder

This is a  powershell script that will build a customized Windows 10/11 ISO bundled with drivers and an answer file to expedite a clean re-install.

### Dependencies

 - oscdming must be available in PATH (provided with Windows ADK)

### How to Use

- Add any drivers you want to include with the image to the drivers directory. Drivers must be .inf files and not .exe. Drivers installed to the system will be included by default.
- Add autounattend.xml to the unattend directory.
- Add the Windows install ISO to the iso directory.
- Run build_custom_iso.ps1 with Administrator permissions.
- Custom iso will be placed in the output folder.