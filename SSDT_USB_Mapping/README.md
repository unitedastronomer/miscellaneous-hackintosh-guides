
# Mapping USB ports via ACPI without Replacement table
> [!NOTE]  
>  Disclaimer: I am not a developer, and my knowledge of ACPI is limited. This might, or **MIGHT NOT** conform to ACPI specification. 

Advantage of this method:
* macOS independent!
* No _UPC to XUPC rename! 🎉

### Overview
Each port in the DSDT for Broadwell, or in a SSDT for Skylake and newer, has a method called `_UPC`. This `_UPC` method requires a specific package consisting of four items. This package indicates whether the port is **active** and specifies its **type**. 

In this instance, the package is contained within `UPCP`. Your might be named differently, the structure typically resembles this format.


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
	* Refer to the table below.
2. Identify HUB device path in ACPI.
	* RHUB for XHC/SHCI
		* Such as `\_SB.PCI0.XHC.RHUB`
	* HUBN for EHC/EH01/EH02
		* Such as `\_SB.PCI0.EH01.HUBN`
2. Must already have identified which ports are active, and their type.


#### For SHCI, and EH01/EH02:
* If you needed the rename, make sure the HUB device path in ACPI is the same as the renamed one instead of the original name - because OpenCore does renaming first before adding the custom SSDT. 
	* For instance, if you renamed from `XHCI` to `SHCI`, then the device path will be something like <code>\\\_SB.PCI0.**SHCI**.RHUB</code>.

According to the Dortania's [OpenCore Install Guide](https://dortania.github.io/OpenCore-Post-Install/usb/system-preparation.html#checking-what-renames-you-need), some USB controllers needs to be renamed.  Rename them first if you have the following:

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

1. Disable the `RHUB` of XHC_ Controller, or the `HUBN` of EHC_ Controller by `_STA`ing them. This effectively disables the `_UPC` methods under each ports of each hubs. 
2. Re-introduce them with a new name such as `XHUB` as a replacement for RHUB, or `HUBX` for `HUBN`. We'll now have a nullified hub that we could customize.
4. Add the `_ADR` of `RHUB` or `HUBN` to the new hub, basically taking address of the old hub and assign it to the new one.
5. Declare ports under these new hubs
6. Take the `_ADR` of each ports from DSDT.
5. Adjust `_UPC` for each port.

Download the [`SSDT-USBMAP.dsl`](SSDT_USB_Mapping/SSDT_USBMAP.dsl) and adjust it accordingly.
```asl
DefinitionBlock ("", "SSDT", 2, "USBMAP", "USB_MAP", 0x00001000)
{
    External (_SB_.PCI0.EH01.HUBN, DeviceObj)
    External (_SB_.PCI0.EH02.HUBN, DeviceObj)
    External (_SB_.PCI0.EHC_.HUBN, DeviceObj)
    External (_SB_.PCI0.SHCI.RHUB, DeviceObj)
    External (_SB_.PCI0.XHC_.RHUB, DeviceObj)

    
    Scope (\_SB.PCI0.EH01.HUBN)  // `Scope` - referencing to the HUB in DSDT
    {
        Method (_STA, 0, NotSerialized)  
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero) // Disable original RHUB/HUBN if macOS
            }
            Else
            {
                Return (0x0F) // Enable if other OS
            }
        }
    }
    
    
    /*
    
    ^ Adjust and duplicate if you have both.
    
        EH01:  Scope (\_SB.PCI0.EH01.HUBN)
        EH02:  Scope (\_SB.PCI0.EH02.HUBN)
        SHCI:  Scope (\_SB.PCI0.SHCI.RHUB)
        XHC:   Scope (\_SB.PCI0.XHC_.RHUB)
    
    */ 
    
    

    Device (\_SB.PCI0.EH01.HUBX) // We add a new Hub `Device`, since RHUB or HUBN is status is disabled.
    {
        Name (_ADR, Zero)  // Re-adding the _ADR (Address) of the RHUB/HUBN under the XHC/EHC USB Controller. RHUB or HUBN always have it `Zero`.
        Method (_STA, 0, NotSerialized)  
        {
            If (_OSI ("Darwin"))
            {
                Return (0x0F) // Only enable if macOS
            }
            Else
            {
                Return (Zero) // Disabled for other OS
            }
        }
    }

    /*
    
    ^ Adjust and duplicate if you have both.
    
        EH01:  Device (\_SB.PCI0.EH01.HUBX)
        EH02:  Device (\_SB.PCI0.EH02.HUBX)
        SHCI:  Device (\_SB.PCI0.SHCI.XHUB)
        XHC:   Device (\_SB.PCI0.XHC_.XHUB)
    
    */ 

    Device (\_SB.PCI0.EH01.HUBX.PR01) // Under HUBX, we add the Port such as PR01
    {
        Name (_ADR, One)  // Each port has unique _ADR, please take their _ADR from the DSDT, and add them in each port under HUBX.
        Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
        {
            Return (Package (0x04)
            {
                0xFF, // PR01's active
                0xFF, // It's Internal
                Zero, 
                Zero
            })
        }
    }
    
    /*
    
    Append if there are another port:
    Such as:
		Device (\_SB.PCI0.EH01.HUBX.PR02) // for PR02
    		{
		Name (_ADR, 0x02) // _ADR of PR02
		...
		}
    */
    

    Device (\_SB.PCI0.EH01.HUBX.PR01.PR12) // It happens that some ports are also a HUB. In this case, PR01 is. So under PR01, we add a PR12
    {
        Name (_ADR, One) // _ADR of PR12
        Method (_UPC, 0, Serialized)       
        {
            Return (Package (0x04)
            {
                0xFF, // It's Active
                0x00, // It's USB 2.0
                Zero, 
                Zero
            })
        }
        /*
    
        Append if there are another port under this HUB port.
    
        */
    }
}

```

## Notes
* There are`_PLD` methods exist under each ports in my DSDT, I have not a found of use of them.
* This idea of `_STA`ing things, and re-assigning `_ADR` was based on SSDT-USB-Reset generated by USBMap. Information regarding `_UPC` method are from 5T33Z0's ACPI USB Mapping guide.
* I feel like it's just safe to `_STA` the RHUB/HUBN because there's SSDTs such as SSDT-RHUB. 
* I cannot guarantee that this method could work for all.
* Some information are based on the [ACPI_Mapping_USB_Ports/GUPC_Method](https://github.com/5T33Z0/OC-Little-Translated/tree/main/03_USB_Fixes/ACPI_Mapping_USB_Ports/GUPC_Method) of 5T33Z0/OC-Little-Translated guide, and the Dortania install guide.

