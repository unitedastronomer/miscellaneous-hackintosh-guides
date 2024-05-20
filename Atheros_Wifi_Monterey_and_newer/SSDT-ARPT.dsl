DefinitionBlock ("", "SSDT", 2, "ARPT", "WIFIPCI", 0x00001000)
{
    External (_SB_.PCI0.RP04, DeviceObj)

    Scope (_SB.PCI0.RP04)
    {
        If (_OSI ("Darwin"))
        {
            Device (ARPT)
            {
                Name (_ADR, 0x02000000)  // _ADR: Address
            }
        }
        Else
        {
        }
    }
}