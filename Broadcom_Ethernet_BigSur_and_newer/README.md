# CatalinaBCM5701Ethernet
You could use the [**CatalinaBCM5701Ethernet.kext**](https://github.com/dortania/OpenCore-Legacy-Patcher/tree/main/payloads/Kexts/Ethernet) provided in OCLP.

#### How to use: 
1. Add your device-id in the kext's Info.plist. <br>
2. Set MinKernel to **20.0.0**. <br>

Add these to **Kernel -> Patch** AS IT IS:
|Identifier*|Find|Replace|minKernel| Comment |
|-|-|-|-|-|
|com.apple.iokit.CatalinaBCM5701Ethernet | E8CA9EFF FF668983 00050000 | B8B41600 00668983 00050000 | 20.0.0 | Broadcom BCM577XX Patch |


#### Cosmetic
This is optional. You could also apply a **Kernel -> Patch** to show the correct model in System Report, edit accordingly to match your model.
|Identifier*|Find|Replace|minKernel| Comment |
|-|-|-|-|-|
|com.apple.iokit.CatalinaBCM5701Ethernet | 35373736 35 | 35373738 35 | 20.0.0 | SysReport 57765 -> 57785 (Cosmetic) |

3 <kbd>5</kbd> 3 <kbd>7</kbd> 3 <kbd>7</kbd> 3 <kbd>**6**</kbd> 3 <kbd>**5**</kbd> -> 3 <kbd>5</kbd> 3 <kbd>7</kbd> 3 <kbd>7</kbd> 3 <kbd>**8**</kbd> 3 <kbd>**5**</kbd>

You could use [HexFriend](http://hexfiend.com) to find and replace these values instead of adding them on Kernel -> Patch.

Credits: 
- **[Sunki](https://www.applelife.ru/threads/patching-applebcm5701ethernet-kext.27866/page-8#post-930901)** for the source of patch.
- **[Andrey1970AppleLife](https://www.applelife.ru/threads/patching-applebcm5701ethernet-kext.27866/page-9#post-1031837)** for cosmetic patch
- Dortania for CatalinaBCM5701Ethernet