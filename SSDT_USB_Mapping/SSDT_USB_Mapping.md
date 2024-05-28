# SSDT USB Mapping
It is still highly recommended to go for a kext in mapping USB ports.


#### Overview
macOS enumerates USB ports (of it's type, and if it is present) based on Method _UPC of each ports present under your USB Controller (such as XHC) in your DSDT. 
##### `**_UPC**` = **USB Port Capabilities

The _UPC method under your DSDT may look like similar to this.
Sample 1. Under each port, it has it's own reference GUPC method for _UPC. GUPC might be named differently compared to yours, but the structure may looks like this.

Sample 2. The _UPC method is referencing a GUPC method outside its scope to reference. 

Grab:
- Hackintool
- MaciASL

1. Let's identify the location IDs of the USB Controller, and it's ports.

Lets find where the USB controller 
So in this case \_SB.PCI0.EHC1

### It requires
Let's disable the EHC1, and add a new device



Method 1: Applicable for EHC1, EHC0, XHCI, XHC1, XHC2

Method 1: Easy way
Find the ACPI Path of your USB Controller device in your DSDT.

In this part, we will disable the original EHC1, and then re-enable it with it back but with a different name. All methods and devices under EHC1 becomes will be disabled. So we will add it back.





