DefinitionBlock ("", "SSDT", 2, "ARPT", "WIFIPCI", 0x00001000)
{
    External (_SB_.PCI0.RP04, DeviceObj)

    Scope (_SB.PCI0.RP04)
    {
        Device (ARPT)
        {
             Name (_ADR, Zero)  // _ADR: Address
        }
    }
}
