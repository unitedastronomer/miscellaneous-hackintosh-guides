# Guide to Restoring Atheros WiFi Functionality on macOS Monterey+

This guide is based on [PG7's tutorial](https://www.insanelymac.com/forum/topic/359007-wifi-atheros-monterey-ventura-sonoma-work/) on InsanelyMac.

## Purpose of This Guide

* **Issue:** After following the original guide, WiFi did not work on the AR9565 even when the kexts were loaded. Additional tinkering was needed.
* **Simplification:** Some steps can be simplified. 
    * Note that you may need to force install it if your card is hidden under a PCI bridge, as OpenCore will fail to add device properties if the device is not enumerated in ACPI.
        * Or you could assign it a name in ACPI so device property will apply.

## Steps

### 1. Download Required Files
Download the OCLP app (not the source code) where you can easily access it later.

Download the following:
* `corecaptureElCap.kext` [(link)](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi)
* `IO80211ElCap.kext` [(link)](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi)
* [`AMFIPass.kext`](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Acidanthera)
* chunnann's [AirPortAtheros40.kext](https://www.insanelymac.com/forum/topic/312045-atheros-wireless-driver-os-x-101112-for-unsupported-cards/?do=findComment&comment=2509900) **10.11.x version** (el-capitan)
<br>

### 2. Modify Kexts
1. Delete all three kexts inside the Plugins folder of IO80211ElCap.kext.
2. Add Chunnann's version of AirportAtheros40 inside the IO80211ElCap.kext's Plugins folder.
3. Delete _CodeSignature and Version.plist inside AirportAtheros40.
4. Open Info.plist under AirportAtheros40, find com.apple.iokit.IO80211Family, and replace it with com.apple.iokit.IO80211ElCap.

### 3. Update config.plist

#### Kernel Section

Add the kexts and adjust `MinKernel` accordingly:

#### Device Properties Section

This will allow OCLP to automatically detect "Legacy Wireless", eliminating the need to [Force-enable Wi-Fi Patching in OCLP](https://github.com/5T33Z0/OC-Little-Translated/blob/main/14_OCLP_Wintel/Enable_Features/WiFi_Sonoma.md#troubleshooting-force-enable-wi-fi-patching-in-oclp).

For AR9565 users, import the set of patches `ar9565.plist` from this repo under `Kernel -> Patches` of the config.plist:
* Patches are based on ATH9Fixup source code.

### 4. Update NVRAM
Change csr-active-config to 03080000.
Add amfi=0x80 to boot-args.

Restart and open the OCLP app, then apply root patches.


# Supplemental Guide: Assigning an ACPI Name

### Issue Overview
If your WiFi card sits behind a PCI bridge and lacks an assigned ACPI name, OpenCore will be unable to inject device properties for it. To solve this, you need to assign a name to the card in ACPI using an SSDT. This allows you to successfully inject the necessary device properties so that OpenCore Legacy Patcher (OCLP) can recognize the WiFi card.

### Steps to Assign an ACPI Name
Download and Install Hackintool

1. Download and Install Hackintool
2. Identify PCI Path
Open Hackintool and navigate to the PCIe tab. Identify your WiFi card and note its ACPI path and debug values. For instance:

* ACPI Path: PCI0.RP04
* Debug Values: 02 00 00

Download the sample SSDT, and edit it according to your values:

```asl
DefinitionBlock ("", "SSDT", 2, "WIFI", "WIFIPCI", 0x00001000)
{
    External (_SB_.PCI0.RP04, DeviceObj)  // Replace "PCI0.RP04" with your ACPI path

    Scope (_SB.PCI0.RP04)  // Replace "PCI0.RP04" with your ACPI path
    {
        Device (ARPT)  // Assign a name to the device, "ARPT" is used in real Macs
        {
            Name (_ADR, 0x02000000)  // Add your debug value here, e.g., "02 00 00" becomes 0x02000000, `00 1C 4` becomes 0x001C40000
        }
    }
}
```

Save the edited SSDT file and add it to your OpenCore ACPI folder. Ensure your config.plist is updated to include the new SSDT by adding it to the ACPI section of your config.plist.
