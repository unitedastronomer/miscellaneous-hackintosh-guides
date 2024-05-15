# Guide to Restoring Atheros WiFi Functionality on macOS Monterey+

This guide is based on [PG7's tutorial](https://www.insanelymac.com/forum/topic/359007-wifi-atheros-monterey-ventura-sonoma-work/) on InsanelyMac.

## Purpose of This Guide

* **Issue:** WiFi didn’t work on the AR9565 even after following the original guide. Extra steps were necessary.
* **Simplification:** Some steps can be simplified.
    * Instead of forcing OCLP to root patch, you can just tweak your config so OCLP will automatically detect **"Legacy Wireless"** _out of the box_.
 
## Steps

### 1. Download Required Files
Download the OCLP app (not the source code) where you can easily access it later.

Download the following:
* [`corecaptureElCap.kext`](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi)
* [`IO80211ElCap.kext`](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi)
* [`AMFIPass.kext`](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Acidanthera)
* chunnann's [`AirPortAtheros40.kext`](https://www.insanelymac.com/forum/topic/312045-atheros-wireless-driver-os-x-101112-for-unsupported-cards/?do=findComment&comment=2509900) **10.11.x version** (el-capitan)

### 2. Modify Kexts
1. Delete all three kexts inside the Plugins folder of `IO80211ElCap.kext`.
2. Add Chunnann's version of `AirportAtheros40` inside the `IO80211ElCap.kext`'s Plugins folder.
3. Delete __CodeSignature_ and _Version.plist_ inside `AirportAtheros40`.
4. Open _Info.plist_ under AirportAtheros40, find `com.apple.iokit.IO80211Family`, and replace it with `com.apple.iokit.IO80211ElCap`.

You could try to use the AirportAtheros40 that came with the ElCapIO80211, I have not personally tested this.

### 3. Update config.plist

#### Kernel Section

* Add the kexts and adjust their `MinKernel` accordingly.
![image](https://github.com/unitedastronomer/miscellaneous-hackintosh-guides/assets/155970773/ee650a22-ada6-486d-800d-4b56bd689479)
* Remove any previously added kexts such as `HS80211Family`, along with its matching `AirportAtheros40`; the kexts we just added will work for earlier macOS versions too.
* If yours was not included in chunnan's list, try the one that came with `ElCap80211`.


#### Device Properties Section

Add these in device properties of your WiFi's device path AS IS:
| Key*   | Value      |   Type |
|--------|------------|--------|
| IOName | pci168c,2a | String |
| compatible| pci168c,2a | String |
| device-id | 2A000000 | Data |

* **Do not change this value**; we spoof the IOName to an Atheros found on iMac11,x which OCLP supports.
* You can identify where your WiFi card's path via Hackintool.
![](screenshots/hackintool_devicepath.png)
* This will allow OCLP to automatically detect **"Legacy Wireless"**, eliminating the need to [force-enable Wi-Fi Patching in OCLP](https://github.com/5T33Z0/OC-Little-Translated/blob/main/14_OCLP_Wintel/Enable_Features/WiFi_Sonoma.md#troubleshooting-force-enable-wi-fi-patching-in-oclp).
* `compatible` and `device-id` was optional in my case as I use the one from Chunnan, however you may need it if you use the `AirportAtheros40` that came one from `ElCap`.

### Misc/Security Section
* Change `SecureBootModel` to `Disabled`.
   * Note: Do an NVRAM reset at least once everytime you change this value.

### NVRAM Section
* Change `csr-active-config` to `03080000`.
* Add `amfi=0x80` to boot-args.

#### For AR9565 users, if the above didn't work, import the set of patches `ar9565.plist` from this repo under `Kernel -> Patches` of your config.plist:
* Patches are based on ATH9Fixup source code.
![](https://github.com/unitedastronomer/miscellaneous-hackintosh-guides/blob/fc929cac5a61b103ff4d5c574efa05c0d4a4ac67/Atheros_Wifi_Monterey_and_newer/screenshots/import-ocat.gif)
Restart and open the OCLP app, then apply root patches.


# Supplemental Guide: Assigning an ACPI Name

This section addresses a specific scenario where the guide may not work as expected. It applies if, after following the steps above, OpenCore Legacy Patcher (OCLP) doesn't show **"Legacy Wireless"** for your Atheros WiFi card.


### Issue Overview
If you have already followed the guide above, but OCLP does not show a "**Legacy Wireless**". Your WiFi card is probably hidden under a PCI bridge, and/or not enumerated in ACPI at all. OpenCore's Device Properties can only overwrite properties for named devices in ACPI.

To solve this, you need to assign a name to the card in ACPI using an SSDT. This allows you to successfully inject the necessary device properties so that OpenCore Legacy Patcher (OCLP) can recognize the WiFi card.

#### Example:
It ends with `pci168c,36`, which is **unnamed**, so the `IOName` we try to inject is **not** applied.
![](screenshots/hackintool_pcie_tab.png)

If it has a name, such as `ARPT`. In this case, the `IOName` we try to inject is applied.
![](screenshots/hackintool_pci1683,36_to_ARPT.png)

### Steps to Assign an ACPI Name

1. Download, and run Hackintool
2. Identify PCI Path
* Navigate to the PCIe tab. Identify your WiFi card and note its ACPI path and debug values. For instance:

![](screenshots/hackintool_pcie_tab.png)

**`PCI0`**<sup> @0 /</sup> **`RP04`**<sup> @1C,3 /</sup> pci168c,36<sup> @0</sup>
* Path: PCI0.RP04 (actually the ACPI path for it's parent/PCI Bridge)
* Debug: 02 00 0

Download the sample SSDT, and edit it according to your values:

```asl
DefinitionBlock ("", "SSDT", 2, "WIFI", "WIFIPCI", 0x00001000)
{
    External (_SB_.PCI0.RP04, DeviceObj)  // Replace "PCI0.RP04" with your WiFi's parent/PCI Bridge ACPI path

    Scope (_SB.PCI0.RP04)  // Replace "PCI0.RP04", same as above
    {
        Device (ARPT) // We assign a name for "pci168c,36" as "ARPT", "ARPT" is the ACPI name of WiFi card in Macs.
        {
            Name (_ADR, 0x02000000)  // Add your debug value here, e.g., "02 00 0" becomes 0x02000000, `00 1C 4` becomes 0x001C40000
        }
    }
}
```

Save the edited SSDT file and add it to your OpenCore ACPI folder. Ensure your config.plist is updated to include the new SSDT by adding it to the ACPI section of your config.plist.

After restart, in my case, **PCI0**<sup> @0 /</sup> **RP04**<sup> @1C,3 /</sup> `pci168c,36`<sup> @0</sup> would now be **PCI0**<sup> @0 /</sup> **RP04**<sup> @1C,3 /</sup>`ARPT`<sup> @0</sup>

Before:
![](screenshots/hackintool_pcie_tab.png)
After:
![](screenshots/hackintool_pci1683,36_to_ARPT.png)


You can now see the `IOName` is properly injected/spoofed. Force injecting would not be necessary anymore as OCLP will now recognize the spoofed `IOName` (of an iMac11,x Atheros card - of which OCLP supports).

|Before|After|
|-|-|
|![](screenshots/real_ioname.png)|![](screenshots/spoofed_ioname.png)|

Open the OCLP app, then apply root patches.

# AR9565 Patches
In some cases (or in my case for AR9565), even when the kext shows as loaded via `kextstat` in Terminal, the WiFi still doesn't work. I am not sure if this is also is the case for other Atheros cards like AR9485 or 946x.

#### Here's a bit of background:
Back in the day, it was common practice to inject `AirportAtheros40` into System/Library/Extensions (S/L/E). Alongside this, `Ath9Fixup.kext` was also loaded via the bootloader.

You might wonder why don't we just inject `Ath9Fixup.kext` too . The reason lies in the original source code, which requires `AirportAtheros40` to reside in S/L/E to function, which isn't the case for us. 
Fortunately, OpenCore can patch the injected `AirportAtheros40` via the `Kernel` -> `Patch` section of the config.plist. The kernel patches on `ar9565.plist` are based on `ATH9ixup` source code. Note that the patches are different for each cards. 


Credits:
* [PG7](https://www.insanelymac.com/forum/topic/359007-wifi-atheros-monterey-ventura-sonoma-work/) for the tutorial
* [Chunnan](https://www.insanelymac.com/forum/topic/312045-atheros-wireless-driver-os-x-101112-for-unsupported-cards/?do=findComment&comment=2509900) for patched ElCap AirPortAtheros40.kext, and patches from ATH9Fixup
* [Dortania](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Wifi) for IO80211ElCap.kext
