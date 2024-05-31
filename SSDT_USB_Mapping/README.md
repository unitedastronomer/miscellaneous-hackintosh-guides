
# Mapping USB ports via ACPI without Replacement table
> [!NOTE]  
>  Disclaimer: I am not a developer, and my knowledge of ACPI is limited. This might, or **MIGHT NOT** conform to ACPI specification. I consider this guide half baked.

Advantage of this method:
* macOS independent!
* No _UPC to XUPC rename! 🎉

### Overview
Each port in the DSDT for Broadwell, or in a SSDT for Skylake and newer, has a method called `_UPC`. This `_UPC` method requires a specific package consisting of four items. This package indicates whether the port is **active** and specifies its **type**. 

In this instance, the package is contained within UPCP. While the naming convention may vary, the structure typically resembles this format.


```asl
Device (HS01) // The USB Port
{
    Name (_ADR, One)  // The address of HS01
    Name (_STA, 0x0F) 

    Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
    {
        Name (UPCP, Package (0x04) // The package
        {
            0xFF, // Determines if a port is on or off | 0xFF = On /  Zero = Off
            0x03, // Determines the type of port. 
            Zero, 
            Zero
        })
    /*
        Yours might have additional `If` statements in this part.
    */
        Return (UPCP) // Send the package from `UPCP` to `_UPC`
    }
}
```


The following values for USB port types are possible:

| Value  | Port Type |       
| :----: | ----------|
|**`0X00`**| USB Type `A` |
|**`0x01`**| USB `Mini-AB` |
|**`0x02`**| USB Smart Card |
|**`0x03`**| USB 3 Standard Type `A` |
|**`0x04`**| USB 3 Standard Type `B` |
|**`0x05`**| USB 3 `Micro-B` |
|**`0x06`**| USB 3 `Micro-AB` |
|**`0x07`**| USB 3 `Power-B` |
|**`0x08`**| USB Type `C` (USB 2 only) |
|**`0x09`**| USB Type `C` (with Switch) | 
|**`0x0A`**| USB Type `C` (w/o Switch) | 
|**`0xFF`**| Internal (e.g, Bluetooth and Camera) |

## Pre-requisites

1. Rename USB Controller
2. Identify HUB device path in ACPI.
	* RHUB for XHC/SHCI
		* Such as `\_SB.PCI0.EH01.HUBN`
	* HUBN for EHC/EH01/EH02
		* Such as `\_SB.PCI0.XHC.RHUB`
2. Must already have identified which ports are active, and their type.


#### For SHCI, and EH01/EH02:
* If you needed the rename, make sure the HUB device path in ACPI is the same as the renamed one instead of the original name - because OpenCore does renaming first before adding the custom SSDT. 
	* For instance, if you renamed from `XHCI` to `SHCI`, then the device path will be something like <code>\\\_SB.PCI0.**SHCI**.RHUB</code>.

According to the Dortania's [OpenCore Install Guide](https://dortania.github.io/OpenCore-Post-Install/usb/system-preparation.html#checking-what-renames-you-need), some USB controllers needs to be renamed.  Rename them firsy if you have the following:

| Key | Type | Value |
| :--- | :--- | :--- |
| Comment | String | XHC1 to SHCI |
| Count | Number | 0 |
| Enabled | Boolean | YES |
| Find | Data | 58484331 |
| Limit | Number | 0 |
| Replace | Data | 53484349 |
| Skip | Number | 0 |
| TableLength | Number | 0 |
| TableSignature | Data |  |

* **EHC1 to EH01**: Needed for Broadwell and older SMBIOS

| Key | Type | Value |
| :--- | :--- | :--- |
| Comment | String | EHC1 to EH01 |
| Count | Number | 0 |
| Enabled | Boolean | YES |
| Find | Data | 45484331 |
| Limit | Number | 0 |
| Replace | Data | 45483031 |
| Skip | Number | 0 |
| TableLength | Number | 0 |
| TableSignature | Data |  |

* **EHC2 to EH02**: Needed for Broadwell and older SMBIOS

| Key | Type | Value |
| :--- | :--- | :--- |
| Comment | String | EHC2 to EH02 |
| Count | Number | 0 |
| Enabled | Boolean | YES |
| Find | Data | 45484332 |
| Limit | Number | 0 |
| Replace | Data | 45483032 |
| Skip | Number | 0 |
| TableLength | Number | 0 |
| TableSignature | Data |  |

## Approach
In order to build our own USB port map via SSDT, we will do the following:

1. Disable the `RHUB` of XHC_ Controller, or the `HUBN` of EHC_ Controller. This effectively disables the `_UPC` methods under each ports of each hubs. 
2. Introduce a new, differently named hubs such as `XHUB` for XHC_ or `HUBX` for EHC. We basically just re-introduce the hubs but with a blank slate.
3. Add the `_ADR` of `RHUB` or `HUBN` to the new hub, basically taking address of the old hub and assign it to the new one.
4. Declare ports under these new hubs
5. Take the `_ADR` of each ports from `RHUB`/`HUBN`
5. Adjust `_UPC` for each port.
 
```asl
DefinitionBlock ("", "SSDT", 2, "USBMAP", "USBMAP", 0x00001000)
{
    External (\_SB_.PCI0.XHC.RHUB, DeviceObj) // Full pathing to XHC's RHUB
    External (\_SB_.PCI0.EH01.HUBN, DeviceObj) // Full pathing to EH01's HUBN


    Scope (\_SB.PCI0.XHC.RHUB) // Full pathing to RHUB
        {
            Method (_STA, 0, NotSerialized)
            {
               If (_OSI ("Darwin"))
                     {
                        Return (Zero) // Disables the RHUB macOS
                     }
                     Else
                     {
                        Return (0x0F) // Re-enables it for Windows
                     }
            }                    
        }
        
        
    Device (\_SB.PCI0.XHC.XHUB) // Add xHUB, under XHC/SHCI, or Add HUBx under EHC/EH01/EH02
    {
            Name (_ADR, Zero)
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F) // Only enable if macOS
                }
                Else
                {
                    Return (Zero) // Disable for other OS
                }
            }
	}
	
	Device (\_SB.PCI0.XHC.XHUB.HS01) // Add HS01 under XHUB
    {
        Name (_ADR, One)  // Address of HS01 in DSDT
        Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
        {
            Return (Package (0x04)
            {
                0xFF, // On / Off
                0x03, // USB Port Type
                Zero, 
                Zero
            })
        }
    }
    

    Device (\_SB.PCI0.EHC.HUBX.PR01.PR12) // If there are ports under (an internal port). e.g, PR12 under PR01 under XHUB
    {
        Name (_ADR, One)  //  Address of PR12 in DSDT
        Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
        {
            Return (Package (0x04)
            {
                0xFF, // On / Off
                0x03, // USB Port Type
                Zero, 
                Zero
            })
        }
    }
                
}
```
> This `.aml` is based on SSDT-RHUB, SSDT-USB-Reset, and the GUPC method. The whole idea of this guide is just disable the HUB under these USB controllers, and then introduce a new one with the `_ADR` of the original devices in DSDT/SSDT

## Notes
* There are`_PLD` methods exist under these ports in DSDT, I have not a found of use of them.
* Some information are based on the [ACPI_Mapping_USB_Ports/GUPC_Method](https://github.com/5T33Z0/OC-Little-Translated/tree/main/03_USB_Fixes/ACPI_Mapping_USB_Ports/GUPC_Method) of 5T33Z0/OC-Little-Translated guide, and the Dortania install guide.
