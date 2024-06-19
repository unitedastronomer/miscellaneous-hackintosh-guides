
# Mapping USB ports via ACPI without Replacement table

> [!NOTE]  
>  Disclaimer: I am not a developer, and my knowledge of ACPI is limited. This might, or **MIGHT NOT** conform to ACPI specification. Do not consider this a guide. There are much better, easier, and recommended utilities in mapping USB ports - such as USBMap by CorpNewt, or USBToolBox by DhinakG.


Advantage of this method:
* macOS independent!
* No _UPC to XUPC rename! 🎉

### Overview
Each port in the DSDT for Broadwell and older, there's a method `_UPC`. This `_UPC` method carries a package consisting of four data. This package indicates whether the port is **active** and specifies its **type**. 

In my DSDT, the package is contained within `UPCP`. Yours might be named differently, but the structure typically resembles this format.


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
            0x03, // Determines the USB port type. 
            Zero, // USB-C Port Capabilities. Must be Zero for other port type.
            Zero  // Must be Zero
        })
    /*
        Yours might have additional `If` statements in this part.
    */
        Return (UPCP) // Send the package from `UPCP` to `_UPC`
    }
}
```

More information regarding `_UPC` can be found [here](https://uefi.org/sites/default/files/resources/ACPI_Spec_6_5_Aug29.pdf), page 570. 


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

## -
1. You must already know which port are active, and their type as I won't be covering it here.
2. Rename USB Controller
	* USB controllers needs to be renamed in some SMBIOS. Refer to the original link above, refer to the Dortania's [OpenCore Install Guide](https://dortania.github.io/OpenCore-Post-Install/usb/system-preparation.html#checking-what-renames-you-need)
	
* **XHC1 to SHCI**: Needed for Skylake and older SMBIOS

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


3. Identify acpi-path of USB controller.

![](reference/hub_path.png)

IOACPIPlane:/**_SB**/**PCI0**@0/**XHC**@14000000
* XHC's acpi-path is `\_SB.PCI0.XHC`

4. Now let's find the address `_ADR` of each active port.

![](reference/port_adr.png)

IOACPIPlane:/**_SB**//**PCI0**@0/**XHC**@14000000/**RHUB**@0/**HS01**@**1**
* HS01's acpi-path is `\_SB.PCI0.XHC.RHUB.HS01` and it's `_ADR`ess is at `1`. 
* Convert decimal `1` to HEX which is `01`.
  	* This is how we are going to use it later on for reference: `Name (_ADR, 0x01)`
	* e.g, if port is `@10`, it's hex is `0A`. `Name (_ADR, 0x0A)`
* A port can be also an internal hub.
	* The path of a port under an (internal hub) port that will be like:
   		* IOACPIPlane:/**_SB**/**PCI0**@0/**EH01**@1D000000/**HUBN**@0/**PR01**@1/**PR11**@**1**
 	* `\_SB.PCI0.EH01.HUBN.PR01.PR11` PR11 belongs under PR01
  	* `PR11`s `_ADR` is `1`. `Name (_ADR, 0x01)`

Now do that for each ports.


## Approach
In order to build our own USB port map via SSDT, we will do the following:

1. Disable the `RHUB` of XHC_ Controller, or the `HUBN` of EHC_ Controller. This effectively disables the `_UPC` methods under each ports of each hubs. 
2. Re-introduce them with a new name such as `XHUB` as a replacement for RHUB, or `HUBX` for `HUBN`. We'll now have a nullified hub that we could customize.
3. Add the `_ADR` of `RHUB` or `HUBN` to the new hub. Essentially, `XHUB` and `HUBX` will take over the addresses of `RHUB` and `HUBN`.
4. Declare ports under these new hubs, and add the `_ADR`ess of each ports we acquired from each port. 
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

    
    Scope (\_SB.PCI0.EH01.HUBN)  // `Scope`, referencing to the HUBN of EH01 in DSDT. It's RHUB for XHC/SHCI
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
		Duplicate and adjust the above if you have both EHC (EH01/EH02) or XHC (SHCI).
	*/


    Device (\_SB.PCI0.EH01.HUBX) // We add a new `HUBX` `Device`, since HUBN is status is disabled.
    {
        Name (_ADR, Zero)  // Re-adding the _ADR of the HUBN. RHUB or HUBN always have it `Zero`.
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
		Duplicate and adjust the above if you have both EHC `HUBN` or XHC `RHUB`.
	*/
    

    Device (\_SB.PCI0.EH01.HUBX.PR01) // Under HUBX, we add the Port such as PR01
    {
        Name (_ADR, One)  // Each port has unique _ADR, here is where we add the converted HEX we looked for earlier.
        Method (_UPC, 0, Serialized)  // _UPC: USB Port Capabilities
        {
            Return (Package (0x04)
            {
                0xFF, // PR01's active
                0xFF, // It's Internal
                Zero, // If you have Type C port, just refer the info from your system DSDT/SSDT (for now).
                Zero
            })
        }
    }
    
   	 /*
   		 Append if there are another port.
   	 */
    

    Device (\_SB.PCI0.EH01.HUBX.PR01.PR11) // It happens that some ports are also a HUB. In this case, PR01 is. So under PR01, we add a PR11
    {
        Name (_ADR, One) // _ADR of PR11
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

**`Optional`**: if you want`_PLD`, just return the original value from your DSDT for now.

```asl
External (_SB_.PCI0.EH01.HUBN.PR01._PLD, MethodObj) // Referencing the _PLD method of PR01 from DSDT. 

Scope (\_SB.PCI0.EH01.HUBX.PR01) // Referencing the new HUBX's PR01 port
{
	Method (_PLD, 0, Serialized)  // Physical Location Device
	{
		Return (\_SB.PCI0.EH01.HUBN.PR01._PLD ()) // Return _PLD data from the HUBN's PR01 in DSDT to HUBX's PR01.
	}
}
```

## Notes
* There are`_PLD` methods exist under each ports in my DSDT. I didn't include them because they're probably borked anyway. It's apparently `Optional` according to the ACPI spec.
* This idea of `_STA`ing, and re-assigning `_ADR` was based on SSDT-USB-Reset generated by USBMap. Information regarding `_UPC` method are from 5T33Z0's ACPI USB Mapping guide, and the ACPI Spec.
* I feel like it's just safe to `_STA` the RHUB/HUBN as there's SSDTs such as SSDT-RHUB. 
* I cannot guarantee that this method would work for all.
