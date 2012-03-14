'Version 1.2
'Author: Mark Sibly (OpenAL Driver)
'Author: Klepto2 3Dsound conversion
'Author: Manel Ibáñez: 1.2 changes
'Modserver: blide
'
'v1.2.0: changed modserver to blide, as this is a forked version based on klepto2 latest release (2 years ago)
'v1.2.0:Increased the space-size subjective gain reduction
'v1.2.0:Added the SetSpeed method to activate doppler effect on OpenAL
'v1.2.0:Most functions now return a valid handler object
'v1.2.0:Fixed a bug when a TSource3D was being updated for a disposed TEntity
'v1.2.0:Entities can now emit loop sounds (ideal for motors, fire sound, etc.)
'v1.2.1:Fixed an issue with SetVolume. It was not working properly for emited sound
'v1.2.1:Fixed an issue with the ScaleFactor value not being affecting the listener SPL emulator
'v1.2.1:Documentation improved
'v1.2.1:Added a console-message on debug mode when loading audio samples not compatible with 3D positioning
'v1.2.1:Added a is3DCompatible method for the TSound3D class
'v1.2.2:Fixed a possible memory leak. Emiter was not released properly when the sound had ended playing (and it was kept open until the minib3d TEntity was freed)
'v1.2.3:Added method Pause to the TSound3D class
'v1.2.3:Added method Rate to the TSound3D class
REM
This file was created by the BLIde solution explorer and should not be modified from outside BLIde
EndRem
'------------------------------------------------------------------------------------------------------------------------------------------------------
'#Region &HFF Program Info
'Program: Sound3D
'Version: 1
'Subversion: 2
'Revision: 3
'#EndRegion &HFF



'------------------------------------------------------------------------------------------------------------------------------------------------------
'#Region &H01 Compile Options
Strict
Rem
    bbdoc:blide\sound3d
End Rem
Module blide.sound3d
ModuleInfo "Version 1.2"
ModuleInfo "Author: Mark Sibly (OpenAL Driver)"
ModuleInfo "Author: Klepto2 3Dsound conversion"
ModuleInfo "Author: Manel Ibáñez: 1.2 changes"
ModuleInfo "Modserver: blide"
ModuleInfo ""
ModuleInfo "v1.2.0: changed modserver to blide, as this is a forked version based on klepto2 latest release (2 years ago)"
ModuleInfo "v1.2.0:Increased the space-size subjective gain reduction"
ModuleInfo "v1.2.0:Added the SetSpeed method to activate doppler effect on OpenAL"
ModuleInfo "v1.2.0:Most functions now return a valid handler object"
ModuleInfo "v1.2.0:Fixed a bug when a TSource3D was being updated for a disposed TEntity"
ModuleInfo "v1.2.0:Entities can now emit loop sounds (ideal for motors, fire sound, etc.)"
ModuleInfo "v1.2.1:Fixed an issue with SetVolume. It was not working properly for emited sound"
ModuleInfo "v1.2.1:Fixed an issue with the ScaleFactor value not being affecting the listener SPL emulator"
ModuleInfo "v1.2.1:Documentation improved"
ModuleInfo "v1.2.1:Added a console-message on debug mode when loading audio samples not compatible with 3D positioning"
ModuleInfo "v1.2.1:Added a is3DCompatible method for the TSound3D class"
ModuleInfo "v1.2.2:Fixed a possible memory leak. Emiter was not released properly when the sound had ended playing (and it was kept open until the minib3d TEntity was freed)"
ModuleInfo "v1.2.3:Added method Pause to the TSound3D class"
ModuleInfo "v1.2.3:Added method Rate to the TSound3D class"
ModuleInfo ""
'#EndRegion &H01



'------------------------------------------------------------------------------------------------------------------------------------------------------
'#Region &H0F Framework
Import brl.linkedlist
Import sidesign.minib3d
Import brl.math
Import brl.audio
Import pub.openal
'#EndRegion &H0F



'------------------------------------------------------------------------------------------------------------------------------------------------------
'#Region &HAF Imports

'#EndRegion &HAF



'------------------------------------------------------------------------------------------------------------------------------------------------------
'#Region &H04 MyNamespace
'GUI
'guid:8ea6ba5f_2e62_4fec_b565_0079d0ca3a0f
Private
TYPE z_8ea6ba5f_2e62_4fec_b565_0079d0ca3a0f_3_0 abstract  'Resource folder
End Type


TYPE z_blide_bg8ea6ba5f_2e62_4fec_b565_0079d0ca3a0f Abstract
    Const Name:string = "Sound3D" 'This string contains the name of the program
    Const MajorVersion:Int = 1  'This Const contains the major version number of the program
    Const MinorVersion:Int = 2  'This Const contains the minor version number of the program
    Const Revision:Int =  3  'This Const contains the revision number of the current program version
    Const VersionString:String = MajorVersion + "." + MinorVersion + "." + Revision   'This string contains the assembly version in format (MAJOR.MINOR.REVISION)
    Const AssemblyInfo:String = Name + " " + MajorVersion + "." + MinorVersion + "." + Revision   'This string represents the available assembly info.
    ?win32
    Const Platform:String = "Win32" 'This constant contains "Win32", "MacOs" or "Linux" depending on the current running platoform for your game or application.
    ?
    ?MacOs
    Const Platform:String = "MacOs"
    ?
    ?Linux
    Const Platform:String = "Linux"
    ?
    ?PPC
    Const Architecture:String = "PPC" 'This const contains "x86" or "Ppc" depending on the running architecture of the running computer. x64 should return also a x86 value
    ?
    ?x86
    Const Architecture:String = "x86" 
    ?
    ?debug
    Const DebugOn : Int = True    'This const will have the integer value of TRUE if the application was build on debug mode, or false if it was build on release mode
    ?
    ?not debug
    Const DebugOn : Int = False
    ?
EndType


Type z_My_8ea6ba5f_2e62_4fec_b565_0079d0ca3a0f Abstract 'This type has all the run-tima binary information of your assembly
    Global Application:z_blide_bg8ea6ba5f_2e62_4fec_b565_0079d0ca3a0f  'This item has all the currently available assembly version information.
    Global Resources:z_8ea6ba5f_2e62_4fec_b565_0079d0ca3a0f_3_0  'This item has all the currently available incbined files names and relative location.
End Type


Global My:z_My_8ea6ba5f_2e62_4fec_b565_0079d0ca3a0f 'This GLOBAL has all the run-time binary information of your assembly, and embeded resources shortcuts.
Public
'#EndRegion &H04 MyNamespace


'------------------------------------------------------------------------------------------------------------------------------------------------------
'#Region &H03 Includes
Include "core.bmx"
Include "audio3ddriver.bmx"
 
'#EndRegion &H03

