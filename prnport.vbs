'----------------------------------------------------------------------
'
' Copyright (c) Microsoft Corporation. All rights reserved.
'
' Abstract:
' prnport.vbs - Port script for WMI on Windows 
'     used to add, delete and list ports
'     also for getting and setting the port configuration
'
' Usage:
' prnport [-adlgt?] [-r port] [-s server] [-u user name] [-w password]
'                   [-o raw|lpr] [-h host address] [-q queue] [-n number]
'                   [-me | -md ] [-i SNMP index] [-y community] [-2e | -2d]"
'
' Examples
' prnport -a -s server -r IP_1.2.3.4 -e 1.2.3.4 -o raw -n 9100
' prnport -d -s server -r c:\temp\foo.prn
' prnport -l -s server
' prnport -g -s server -r IP_1.2.3.4
' prnport -t -s server -r IP_1.2.3.4 -me -y public -i 1 -n 9100
'
'----------------------------------------------------------------------

option explicit

'
' Debugging trace flags, to enable debug output trace message
' change gDebugFlag to true.
'
dim   gDebugFlag
const kDebugTrace = 1
const kDebugError = 2

gDebugFlag = false

'
' Operation action values.
'
const kActionAdd          = 0
const kActionDelete       = 1
const kActionList         = 2
const kActionUnknown      = 3
const kActionGet          = 4
const kActionSet          = 5

const kErrorSuccess       = 0
const KErrorFailure       = 1

const kFlagCreateOrUpdate = 0

const kNameSpace          = "root\cimv2"


'
' Constants for the parameter dictionary
'
const kServerName      = 1
const kPortName        = 2
const kDoubleSpool     = 3
const kPortNumber      = 4
const kPortType        = 5
const kHostAddress     = 6
const kSNMPDeviceIndex = 7
const kCommunityName   = 8
const kSNMP            = 9
const kQueueName       = 10
const kUserName        = 11
const kPassword        = 12

'
' Generic strings
'
const L_Empty_Text                 = ""
const L_Space_Text                 = " "
const L_Colon_Text                 = ":"
const L_LPR_Queue                  = "LPR"
const L_Error_Text                 = "Error"
const L_Success_Text               = "Success"
const L_Failed_Text                = "Failed"
const L_Hex_Text                   = "0x"
const L_Printer_Text               = "Printer"
const L_Operation_Text             = "Operation"
const L_Provider_Text              = "Provider"
const L_Description_Text           = "Description"
const L_Debug_Text                 = "Debug:"

'
' General usage messages
'
const L_Help_Help_General01_Text   = "Usage: prnport [-adlgt?] [-r port][-s server][-u user name][-w password]"
const L_Help_Help_General02_Text   = "               [-o raw|lpr][-h host address][-q queue][-n number]"
const L_Help_Help_General03_Text   = "               [-me | -md ][-i SNMP index][-y community][-2e | -2d]"
const L_Help_Help_General04_Text   = "Arguments:"
const L_Help_Help_General05_Text   = "-a     - add a port"
const L_Help_Help_General06_Text   = "-d     - delete the specified port"
const L_Help_Help_General07_Text   = "-g     - get configuration for a TCP port"
const L_Help_Help_General08_Text   = "-h     - IP address of the device"
const L_Help_Help_General09_Text   = "-i     - SNMP index, if SNMP is enabled"
const L_Help_Help_General10_Text   = "-l     - list all TCP ports"
const L_Help_Help_General11_Text   = "-m     - SNMP type. [e] enable, [d] disable"
const L_Help_Help_General12_Text   = "-n     - port number, applies to TCP RAW ports"
const L_Help_Help_General13_Text   = "-o     - port type, raw or lpr"
const L_Help_Help_General14_Text   = "-q     - queue name, applies to TCP LPR ports only"
const L_Help_Help_General15_Text   = "-r     - port name"
const L_Help_Help_General16_Text   = "-s     - server name"
const L_Help_Help_General17_Text   = "-t     - set configuration for a TCP port"
const L_Help_Help_General18_Text   = "-u     - user name"
const L_Help_Help_General19_Text   = "-w     - password"
const L_Help_Help_General20_Text   = "-y     - community name, if SNMP is enabled"
const L_Help_Help_General21_Text   = "-2     - double spool, applies to TCP LPR ports. [e] enable, [d] disable"
const L_Help_Help_General22_Text   = "-?     - display command usage"
const L_Help_Help_General23_Text   = "Examples:"
const L_Help_Help_General24_Text   = "prnport -l -s server"
const L_Help_Help_General25_Text   = "prnport -d -s server -r IP_1.2.3.4"
const L_Help_Help_General26_Text   = "prnport -a -s server -r IP_1.2.3.4 -h 1.2.3.4 -o raw -n 9100"
const L_Help_Help_General27_Text   = "prnport -t -s server -r IP_1.2.3.4 -me -y public -i 1 -n 9100"
const L_Help_Help_General28_Text   = "prnport -g -s server -r IP_1.2.3.4"
const L_Help_Help_General29_Text   = "prnport -a -r IP_1.2.3.4 -h 1.2.3.4"
const L_Help_Help_General30_Text   = "Remark:"
const L_Help_Help_General31_Text   = "The last example will try to get the device settings at the specified IP address."
const L_Help_Help_General32_Text   = "If a device is detected, then a TCP port is added with the preferred settings for that device."

'
' Messages to be displayed if the scripting host is not cscript
'
const L_Help_Help_Host01_Text      = "This script should be executed from the Command Prompt using CScript.exe."
const L_Help_Help_Host02_Text      = "For example: CScript script.vbs arguments"
const L_Help_Help_Host03_Text      = ""
const L_Help_Help_Host04_Text      = "To set CScript as the default application to run .VBS files run the following:"
const L_Help_Help_Host05_Text      = "     CScript //H:CScript //S"
const L_Help_Help_Host06_Text      = "You can then run ""script.vbs arguments"" without preceding the script with CScript."

'
' General error messages
'
const L_Text_Error_General01_Text  = "The scripting host could not be determined."
const L_Text_Error_General02_Text  = "Unable to parse command line."
const L_Text_Error_General03_Text  = "Win32 error code"

'
' Miscellaneous messages
'
const L_Text_Msg_General01_Text    = "Added port"
const L_Text_Msg_General02_Text    = "Unable to delete port"
const L_Text_Msg_General03_Text    = "Unable to get port"
const L_Text_Msg_General04_Text    = "Created/updated port"
const L_Text_Msg_General05_Text    = "Unable to create/update port"
const L_Text_Msg_General06_Text    = "Unable to enumerate ports"
const L_Text_Msg_General07_Text    = "Number of ports enumerated"
const L_Text_Msg_General08_Text    = "Deleted port"
const L_Text_Msg_General09_Text    = "Unable to get SWbemLocator object"
const L_Text_Msg_General10_Text    = "Unable to connect to WMI service"


'
' Port properties
'
const L_Text_Msg_Port01_Text       = "Server name"
const L_Text_Msg_Port02_Text       = "Port name"
const L_Text_Msg_Port03_Text       = "Host address"
const L_Text_Msg_Port04_Text       = "Protocol RAW"
const L_Text_Msg_Port05_Text       = "Protocol LPR"
const L_Text_Msg_Port06_Text       = "Port number"
const L_Text_Msg_Port07_Text       = "Queue"
const L_Text_Msg_Port08_Text       = "Byte Count Enabled"
const L_Text_Msg_Port09_Text       = "Byte Count Disabled"
const L_Text_Msg_Port10_Text       = "SNMP Enabled"
const L_Text_Msg_Port11_Text       = "SNMP Disabled"
const L_Text_Msg_Port12_Text       = "Community"
const L_Text_Msg_Port13_Text       = "Device index"

'
' Debug messages
'
const L_Text_Dbg_Msg01_Text        = "In function DelPort"
const L_Text_Dbg_Msg02_Text        = "In function CreateOrSetPort"
const L_Text_Dbg_Msg03_Text        = "In function ListPorts"
const L_Text_Dbg_Msg04_Text        = "In function GetPort"
const L_Text_Dbg_Msg05_Text        = "In function ParseCommandLine"

main

'
' Main execution starts here
'
sub main

    on error resume next

    dim iAction
    dim iRetval
    dim oParamDict

    '
    ' Abort if the host is not cscript
    '
    if not IsHostCscript() then

        call wscript.echo(L_Help_Help_Host01_Text & vbCRLF & L_Help_Help_Host02_Text & vbCRLF & _
                          L_Help_Help_Host03_Text & vbCRLF & L_Help_Help_Host04_Text & vbCRLF & _
                          L_Help_Help_Host05_Text & vbCRLF & L_Help_Help_Host06_Text & vbCRLF)

        wscript.quit

    end if

    set oParamDict = CreateObject("Scripting.Dictionary")

    iRetval = ParseCommandLine(iAction, oParamDict)

    if iRetval = 0 then

        select case iAction

            case kActionAdd
                iRetval = CreateOrSetPort(oParamDict)

            case kActionDelete
                iRetval = DelPort(oParamDict)

            case kActionList
                iRetval = ListPorts(oParamDict)

            case kActionGet
                iRetVal = GetPort(oParamDict)

            case kActionSet
                iRetVal = CreateOrSetPort(oParamDict)

            case else
                Usage(true)
                exit sub

        end select

    end if

end sub

'
' Delete a port
'
function DelPort(oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg01_Text
    DebugPrint kDebugTrace, L_Text_Msg_Port01_Text & L_Space_Text & oParamDict(kServerName)
    DebugPrint kDebugTrace, L_Text_Msg_Port02_Text & L_Space_Text & oParamDict(kPortName)

    dim oService
    dim oPort
    dim iResult
    dim strServer
    dim strPort
    dim strUser
    dim strPassword

    iResult = kErrorFailure

    strServer   = oParamDict(kServerName)
    strPort     = oParamDict(kPortName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPort = oService.Get("Win32_TCPIPPrinterPort='" & strPort & "'")

    else

        DelPort = kErrorFailure

        exit function

    end if

    '
    ' Check if Get succeeded
    '
    if Err.Number = kErrorSuccess then

        '
        ' Try deleting the instance
        '
        oPort.Delete_

        if Err.Number = kErrorSuccess then

            wscript.echo L_Text_Msg_General08_Text & L_Space_Text & strPort

        else

            wscript.echo L_Text_Msg_General02_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                         & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

            '
            ' Try getting extended error information
            '
            call LastError()

        end if

    else

        wscript.echo L_Text_Msg_General02_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

    end if

    DelPort = iResult

end function

'
' Add or update a port
'
function CreateOrSetPort(oParamDict)

    on error resume next

    dim oPort
    dim oService
    dim iResult
    dim PortType
    dim strServer
    dim strPort
    dim strUser
    dim strPassword

    DebugPrint kDebugTrace, L_Text_Dbg_Msg02_Text
    DebugPrint kDebugTrace, L_Text_Msg_Port01_Text & L_Space_Text & oParamDict.Item(kServerName)
    DebugPrint kDebugTrace, L_Text_Msg_Port02_Text & L_Space_Text & oParamDict.Item(kPortName)
    DebugPrint kDebugTrace, L_Text_Msg_Port06_Text & L_Space_Text & oParamDict.Item(kPortNumber)
    DebugPrint kDebugTrace, L_Text_Msg_Port07_Text & L_Space_Text & oParamDict.Item(kQueueName)
    DebugPrint kDebugTrace, L_Text_Msg_Port13_Text & L_Space_Text & oParamDict.Item(kSNMPDeviceIndex)
    DebugPrint kDebugTrace, L_Text_Msg_Port12_Text & L_Space_Text & oParamDict.Item(kCommunityName)
    DebugPrint kDebugTrace, L_Text_Msg_Port03_Text & L_Space_Text & oParamDict.Item(kHostAddress)

    strServer   = oParamDict(kServerName)
    strPort     = oParamDict(kPortName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    '
    ' If the port exists, then get the settings. Later PutInstance will do an update
    '
    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPort = oService.Get("Win32_TCPIPPrinterPort.Name='" & strPort & "'")

        '
        ' If get was unsuccessful then spawn a new port instance. Later PutInstance will do a create
        '
        if Err.Number <> kErrorSuccess then

            '
            ' Clear the previous error
            '
            Err.Clear

            set oPort = oService.Get("Win32_TCPIPPrinterPort").SpawnInstance_

        end if

    else

        CreateOrSetPort = kErrorFailure

        exit function

    end if

    if Err.Number <> kErrorSuccess then

        wscript.echo L_Text_Msg_General03_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        CreateOrSetPort = kErrorFailure

        exit function

    end if

    oPort.Name          = oParamDict.Item(kPortName)
    oPort.HostAddress   = oParamDict.Item(kHostAddress)
    oPort.PortNumber    = oParamDict.Item(kPortNumber)
    oPort.SNMPEnabled   = oParamDict.Item(kSNMP)
    oPort.SNMPDevIndex  = oParamDict.Item(kSNMPDeviceIndex)
    oPort.SNMPCommunity = oParamDict.Item(kCommunityName)
    oPort.Queue         = oParamDict.Item(kQueueName)
    oPort.ByteCount     = oParamDict.Item(kDoubleSpool)

    PortType     = oParamDict.Item(kPortType)

    '
    ' Update the port object with the settings corresponding
    ' to the port type of the port to be added
    '
    select case lcase(PortType)

            case "raw"

                 oPort.Protocol      = 1

                 if Not IsNull(oPort.Queue) then

                     wscript.echo L_Error_Text & L_Colon_Text & L_Space_Text _
                     & L_Help_Help_General14_Text

                     CreateOrSetPort = kErrorFailure

                     exit function

                 end if

            case "lpr"

                 oPort.Protocol      = 2

                 if IsNull(oPort.Queue) then

                     oPort.Queue = L_LPR_Queue

                 end if

            case else

                 '
                 ' PutInstance will attempt to get the configuration of
                 ' the device based on its IP address. Those settings
                 ' will be used to add a new port
                 '
    end select

    '
    ' Try creating or updating the port
    '
    oPort.Put_(kFlagCreateOrUpdate)

    if Err.Number = kErrorSuccess then

        wscript.echo L_Text_Msg_General04_Text & L_Space_Text & oPort.Name

        iResult = kErrorSuccess

    else

        wscript.echo L_Text_Msg_General05_Text & L_Space_Text & oPort.Name & L_Space_Text _
                     & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) _
                     & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

        iResult = kErrorFailure

    end if

    CreateOrSetPort = iResult

end function

'
' List ports on a machine.
'
function ListPorts(oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg03_Text

    dim Ports
    dim oPort
    dim oService
    dim iRetval
    dim iTotal
    dim strServer
    dim strUser
    dim strPassword

    iResult = kErrorFailure

    strServer   = oParamDict(kServerName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set Ports = oService.InstancesOf("Win32_TCPIPPrinterPort")

    else

        ListPorts = kErrorFailure

        exit function

    end if

    if Err.Number <> kErrorSuccess then

        wscript.echo L_Text_Msg_General06_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        ListPrinters = kErrorFailure

        exit function

    end if

    iTotal = 0

    for each oPort in Ports

        iTotal = iTotal + 1

        wscript.echo L_Empty_Text
        wscript.echo L_Text_Msg_Port01_Text & L_Space_Text & strServer
        wscript.echo L_Text_Msg_Port02_Text & L_Space_Text & oPort.Name
        wscript.echo L_Text_Msg_Port03_Text & L_Space_Text & oPort.HostAddress

        if oPort.Protocol = 1 then

            wscript.echo L_Text_Msg_Port04_Text
            wscript.echo L_Text_Msg_Port06_Text & L_Space_Text & oPort.PortNumber

        else

            wscript.echo L_Text_Msg_Port05_Text
            wscript.echo L_Text_Msg_Port07_Text & L_Space_Text & oPort.Queue

            if oPort.ByteCount then

                wscript.echo L_Text_Msg_Port08_Text

            else

                wscript.echo L_Text_Msg_Port09_Text

            end if

        end if

        if oPort.SNMPEnabled then

            wscript.echo L_Text_Msg_Port10_Text
            wscript.echo L_Text_Msg_Port12_Text & L_Space_Text & oPort.SNMPCommunity
            wscript.echo L_Text_Msg_Port13_Text & L_Space_Text & oPort.SNMPDevIndex

        else

            wscript.echo L_Text_Msg_Port11_Text

        end if

        Err.Clear

    next

    wscript.echo L_Empty_Text
    wscript.echo L_Text_Msg_General07_Text & L_Space_Text & iTotal

    ListPorts = kErrorSuccess

end function

'
' Gets the configuration of a port
'
function GetPort(oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg04_Text
    DebugPrint kDebugTrace, L_Text_Msg_Port01_Text & L_Space_Text & oParamDict(kServerName)
    DebugPrint kDebugTrace, L_Text_Msg_Port02_Text & L_Space_Text & oParamDict(kPortName)

    dim oService
    dim oPort
    dim iResult
    dim strServer
    dim strPort
    dim strUser
    dim strPassword

    iResult = kErrorFailure

    strServer   = oParamDict(kServerName)
    strPort     = oParamDict(kPortName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPort = oService.Get("Win32_TCPIPPrinterPort.Name='" & strPort & "'")

    else

        GetPort = kErrorFailure

        exit function

    end if

    if Err.Number = kErrorSuccess then

        wscript.echo L_Empty_Text
        wscript.echo L_Text_Msg_Port01_Text & L_Space_Text & strServer
        wscript.echo L_Text_Msg_Port02_Text & L_Space_Text & oPort.Name
        wscript.echo L_Text_Msg_Port03_Text & L_Space_Text & oPort.HostAddress

        if oPort.Protocol = 1 then

            wscript.echo L_Text_Msg_Port04_Text
            wscript.echo L_Text_Msg_Port06_Text & L_Space_Text & oPort.PortNumber

        else

            wscript.echo L_Text_Msg_Port05_Text
            wscript.echo L_Text_Msg_Port07_Text & L_Space_Text & oPort.Queue

            if oPort.ByteCount then

                wscript.echo L_Text_Msg_Port08_Text

            else

                wscript.echo L_Text_Msg_Port09_Text

            end if

        end if

        if oPort.SNMPEnabled then

            wscript.echo L_Text_Msg_Port10_Text
            wscript.echo L_Text_Msg_Port12_Text & L_Space_Text & oPort.SNMPCommunity
            wscript.echo L_Text_Msg_Port13_Text & L_Space_Text & oPort.SNMPDevIndex

        else

            wscript.echo L_Text_Msg_Port11_Text

        end if

        iResult = kErrorSuccess

    else

        wscript.echo L_Text_Msg_General03_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

    end if

    GetPort = iResult

end function

'
' Debug display helper function
'
sub DebugPrint(uFlags, strString)

    if gDebugFlag = true then

        if uFlags = kDebugTrace then

            wscript.echo L_Debug_Text & L_Space_Text & strString

        end if

        if uFlags = kDebugError then

            if Err <> 0 then

                wscript.echo L_Debug_Text & L_Space_Text & strString & L_Space_Text _
                             & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) _
                             & L_Space_Text & Err.Description

            end if

        end if

    end if

end sub

'
' Parse the command line into its components
'
function ParseCommandLine(iAction, oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg05_Text

    dim oArgs
    dim iIndex

    iAction = kActionUnknown

    set oArgs = Wscript.Arguments

    while iIndex < oArgs.Count

        select case oArgs(iIndex)

            case "-g"
                iAction = kActionGet

            case "-t"
                iAction = kActionSet

            case "-a"
                iAction = kActionAdd

            case "-d"
                iAction = kActionDelete

            case "-l"
                iAction = kActionList

            case "-2e"
                oParamDict.Add kDoubleSpool, true

            case "-2d"
                oParamDict.Add kDoubleSpool, false

            case "-s"
                iIndex = iIndex + 1
                oParamDict.Add kServerName, RemoveBackslashes(oArgs(iIndex))

            case "-u"
                iIndex = iIndex + 1
                oParamDict.Add kUserName, oArgs(iIndex)

            case "-w"
                iIndex = iIndex + 1
                oParamDict.Add kPassword, oArgs(iIndex)

            case "-n"
                iIndex = iIndex + 1
                oParamDict.Add kPortNumber, oArgs(iIndex)

            case "-r"
                iIndex = iIndex + 1
                oParamDict.Add kPortName, oArgs(iIndex)

            case "-o"
                iIndex = iIndex + 1
                oParamDict.Add kPortType, oArgs(iIndex)

            case "-h"
                iIndex = iIndex + 1
                oParamDict.Add kHostAddress, oArgs(iIndex)

            case "-q"
                iIndex = iIndex + 1
                oParamDict.Add kQueueName, oArgs(iIndex)

            case "-i"
                iIndex = iIndex + 1
                oParamDict.Add kSNMPDeviceIndex, oArgs(iIndex)

            case "-y"
                iIndex = iIndex + 1
                oParamDict.Add kCommunityName, oArgs(iIndex)

            case "-me"
                oParamDict.Add kSNMP, true

            case "-md"
                oParamDict.Add kSNMP, false

            case "-?"
                Usage(True)
                exit function

            case else
                Usage(True)
                exit function

        end select

        iIndex = iIndex + 1

    wend

    if Err = kErrorSuccess then

        ParseCommandLine = kErrorSuccess

    else

        wscript.echo L_Text_Error_General02_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_text & Err.Description


        ParseCommandLine = kErrorFailure

    end if

end  function

'
' Display command usage.
'
sub Usage(bExit)

    wscript.echo L_Help_Help_General01_Text
    wscript.echo L_Help_Help_General02_Text
    wscript.echo L_Help_Help_General03_Text
    wscript.echo L_Help_Help_General04_Text
    wscript.echo L_Help_Help_General05_Text
    wscript.echo L_Help_Help_General06_Text
    wscript.echo L_Help_Help_General07_Text
    wscript.echo L_Help_Help_General08_Text
    wscript.echo L_Help_Help_General09_Text
    wscript.echo L_Help_Help_General10_Text
    wscript.echo L_Help_Help_General11_Text
    wscript.echo L_Help_Help_General12_Text
    wscript.echo L_Help_Help_General13_Text
    wscript.echo L_Help_Help_General14_Text
    wscript.echo L_Help_Help_General15_Text
    wscript.echo L_Help_Help_General16_Text
    wscript.echo L_Help_Help_General17_Text
    wscript.echo L_Help_Help_General18_Text
    wscript.echo L_Help_Help_General19_Text
    wscript.echo L_Help_Help_General20_Text
    wscript.echo L_Help_Help_General21_Text
    wscript.echo L_Help_Help_General22_Text
    wscript.echo L_Empty_Text
    wscript.echo L_Help_Help_General23_Text
    wscript.echo L_Help_Help_General24_Text
    wscript.echo L_Help_Help_General25_Text
    wscript.echo L_Help_Help_General26_Text
    wscript.echo L_Help_Help_General27_Text
    wscript.echo L_Help_Help_General28_Text
    wscript.echo L_Help_Help_General29_Text
    wscript.echo L_Empty_Text
    wscript.echo L_Help_Help_General30_Text
    wscript.echo L_Help_Help_General31_Text
    wscript.echo L_Help_Help_General32_Text

    if bExit then

        wscript.quit(1)

    end if

end sub

'
' Determines which program is being used to run this script.
' Returns true if the script host is cscript.exe
'
function IsHostCscript()

    on error resume next

    dim strFullName
    dim strCommand
    dim i, j
    dim bReturn

    bReturn = false

    strFullName = WScript.FullName

    i = InStr(1, strFullName, ".exe", 1)

    if i <> 0 then

        j = InStrRev(strFullName, "\", i, 1)

        if j <> 0 then

            strCommand = Mid(strFullName, j+1, i-j-1)

            if LCase(strCommand) = "cscript" then

                bReturn = true

            end if

        end if

    end if

    if Err <> 0 then

        wscript.echo L_Text_Error_General01_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

    end if

    IsHostCscript = bReturn

end function

'
' Retrieves extended information about the last error that occurred
' during a WBEM operation. The methods that set an SWbemLastError
' object are GetObject, PutInstance, DeleteInstance
'
sub LastError()

    on error resume next

    dim oError

    set oError = CreateObject("WbemScripting.SWbemLastError")

    if Err = kErrorSuccess then

        wscript.echo L_Operation_Text            & L_Space_Text & oError.Operation
        wscript.echo L_Provider_Text             & L_Space_Text & oError.ProviderName
        wscript.echo L_Description_Text          & L_Space_Text & oError.Description
        wscript.echo L_Text_Error_General04_Text & L_Space_Text & oError.StatusCode

    end if

end sub

'
' Connects to the WMI service on a server. oService is returned as a service
' object (SWbemServices)
'
function WmiConnect(strServer, strNameSpace, strUser, strPassword, oService)

   on error resume next

   dim oLocator
   dim bResult

   oService = null

   bResult  = false

   set oLocator = CreateObject("WbemScripting.SWbemLocator")

   if Err = kErrorSuccess then

      set oService = oLocator.ConnectServer(strServer, strNameSpace, strUser, strPassword)

      if Err = kErrorSuccess then

          bResult = true

          oService.Security_.impersonationlevel = 3

          '
          ' Required to perform administrative tasks on the spooler service
          '
          oService.Security_.Privileges.AddAsString "SeLoadDriverPrivilege"

          Err.Clear

      else

          wscript.echo L_Text_Msg_General10_Text & L_Space_Text & L_Error_Text _
                       & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                       & Err.Description

      end if

   else

       wscript.echo L_Text_Msg_General09_Text & L_Space_Text & L_Error_Text _
                    & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                    & Err.Description

   end if

   WmiConnect = bResult

end function

'
' Remove leading "\\" from server name
'
function RemoveBackslashes(strServer)

    dim strRet

    strRet = strServer

    if Left(strServer, 2) = "\\" and Len(strServer) > 2 then

        strRet = Mid(strServer, 3)

    end if

    RemoveBackslashes = strRet

end function

'' SIG '' Begin signature block
'' SIG '' MIIlYQYJKoZIhvcNAQcCoIIlUjCCJU4CAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' JP2OI/dGh8Dr4i1IHJc1kEljUqgI55azox+O936+ZZqg
'' SIG '' ggrlMIIFBjCCA+6gAwIBAgITMwAAAzyJxmp7RbsfvQAA
'' SIG '' AAADPDANBgkqhkiG9w0BAQsFADCBhDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEuMCwGA1UEAxMlTWljcm9zb2Z0IFdpbmRv
'' SIG '' d3MgUHJvZHVjdGlvbiBQQ0EgMjAxMTAeFw0yMTA5MDIx
'' SIG '' ODIzNDFaFw0yMjA5MDExODIzNDFaMHAxCzAJBgNVBAYT
'' SIG '' AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
'' SIG '' EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
'' SIG '' cG9yYXRpb24xGjAYBgNVBAMTEU1pY3Jvc29mdCBXaW5k
'' SIG '' b3dzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
'' SIG '' AQEA0C1bs/cyz18F/sjVyPtMJbiPDuv1On88IsAkc4XN
'' SIG '' wCCSU2Tl+IdwjuJqz8f2Ma1JA4mldik+l51VmqKr6qxi
'' SIG '' /ukVtavRqYBr9TFs0WjoZttLvhiRlrARwfbQPOIIzZC0
'' SIG '' pq6BNTO1bN+njWBw1cNH9WBcW5NxuaV5wIZHbMWqvVPm
'' SIG '' ny0xc/MRoeg4FduG+luu/YjloRJs3V6otzGisFhy/n6k
'' SIG '' p6oMuAWSVaR7nzIvHVqL99A6biayntOfKnuJNut8HzCa
'' SIG '' cJGs/l0L/PB2rhIEJ1EpJYJaQXb7h/ZtE7/bebokdWnn
'' SIG '' shxUOvnGAteaCLVchlfIUr6aJVJToNeeGvgebwIDAQAB
'' SIG '' o4IBgjCCAX4wHwYDVR0lBBgwFgYKKwYBBAGCNwoDBgYI
'' SIG '' KwYBBQUHAwMwHQYDVR0OBBYEFEiFOkMS40DUq3mPeNLS
'' SIG '' ifgdMnk4MFQGA1UdEQRNMEukSTBHMS0wKwYDVQQLEyRN
'' SIG '' aWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0
'' SIG '' ZWQxFjAUBgNVBAUTDTIyOTg3OSs0Njc1ODAwHwYDVR0j
'' SIG '' BBgwFoAUqSkCOY4WxJd4zZD5nk+a4XxVr1MwVAYDVR0f
'' SIG '' BE0wSzBJoEegRYZDaHR0cDovL3d3dy5taWNyb3NvZnQu
'' SIG '' Y29tL3BraW9wcy9jcmwvTWljV2luUHJvUENBMjAxMV8y
'' SIG '' MDExLTEwLTE5LmNybDBhBggrBgEFBQcBAQRVMFMwUQYI
'' SIG '' KwYBBQUHMAKGRWh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
'' SIG '' bS9wa2lvcHMvY2VydHMvTWljV2luUHJvUENBMjAxMV8y
'' SIG '' MDExLTEwLTE5LmNydDAMBgNVHRMBAf8EAjAAMA0GCSqG
'' SIG '' SIb3DQEBCwUAA4IBAQBpkEV0LEA4Et4b356iviITLoKn
'' SIG '' wAarJ44Mn0YL1DU4Y0gDGmtcvfRQrlokMzHcssx+rOg3
'' SIG '' HPcew1pvZjFHvSEeo1dhTmphHurMpkhqd41M14gQat4S
'' SIG '' 1mJVdOeonsq06wu5kpXEmN1fVlaAotJr8lRecnxCBAI8
'' SIG '' SNgCG2CP2QHG/v0Wzgw6Zp+wznWNxnHyzddDTBY/nelF
'' SIG '' PlUj2Up4IFyCikYV5QMw2fUqinf3aD0rYf8TJDgtQNMQ
'' SIG '' AcUYtWsob7uMdU9pQFkMIHE4XtCpOHtSnAa/cf/4nHRj
'' SIG '' RVD8Mxs4nVWGlqzgV4cUTlr1PSCnWoSYG/g4DdrDdD9A
'' SIG '' fY/yfAieMIIF1zCCA7+gAwIBAgIKYQd2VgAAAAAACDAN
'' SIG '' BgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
'' SIG '' aWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMTExMDE5MTg0
'' SIG '' MTQyWhcNMjYxMDE5MTg1MTQyWjCBhDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEuMCwGA1UEAxMlTWljcm9zb2Z0IFdpbmRv
'' SIG '' d3MgUHJvZHVjdGlvbiBQQ0EgMjAxMTCCASIwDQYJKoZI
'' SIG '' hvcNAQEBBQADggEPADCCAQoCggEBAN0Mu6LkLgnj58X3
'' SIG '' lmm8ACG9aTMz760Ey1SA7gaDu8UghNn30ovzOLCrpK0t
'' SIG '' fGJ5Bf/jSj8ENSBw48Tna+CcwDZ16Yox3Y1w5dw3tXRG
'' SIG '' lihbh2AjLL/cR6Vn91EnnnLrB6bJuR47UzV85dPsJ7mH
'' SIG '' HP65ySMJb6hGkcFuljxB08ujP10Cak3saR8lKFw2//1D
'' SIG '' FQqU4Bm0z9/CEuLCWyfuJ3gwi1sqCWsiiVNgFizAaB1T
'' SIG '' uuxJ851hjIVoCXNEXX2iVCvdefcVzzVdbBwrXM68nCOL
'' SIG '' b261Jtk2E8NP1ieuuTI7QZIs4cfNd+iqVE73XAsEh2W0
'' SIG '' QxiosuBtGXfsWiT6SAMCAwEAAaOCAUMwggE/MBAGCSsG
'' SIG '' AQQBgjcVAQQDAgEAMB0GA1UdDgQWBBSpKQI5jhbEl3jN
'' SIG '' kPmeT5rhfFWvUzAZBgkrBgEEAYI3FAIEDB4KAFMAdQBi
'' SIG '' AEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB
'' SIG '' /zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvXzpoY
'' SIG '' xDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNS
'' SIG '' b29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUH
'' SIG '' AQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1
'' SIG '' dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG9w0BAQsFAAOC
'' SIG '' AgEAFPx8cVGlecJusu85Prw8Ug9uKz8QE3P+qGjQSKY0
'' SIG '' TYqWBSbuMUaQYXnW/zguRWv0wOUouNodj4rbCdcax0wK
'' SIG '' NmZqjOwb1wSQqBgXpJu54kAyNnbEwVrGv+QEwOoW06zD
'' SIG '' aO9irN1UbFAwWKbrfP6Up06O9Ox8hnNXwlIhczRa86OK
'' SIG '' VsgE2gcJ7fiL4870fo6u8PYLigj7P8kdcn9TuOu+Y+Dj
'' SIG '' PTFlsIHl8qzNFqSfPaixm8JC0JCEX1Qd/4nquh1HkG+w
'' SIG '' c05Bn0CfX+WhKrIRkXOKISjwzt5zOV8+q1xg7N8DEKjT
'' SIG '' Cen09paFtn9RiGZHGY2isBI9gSpoBXe7kUxie7bBB8e6
'' SIG '' eoc0Aw5LYnqZ6cr8zko3yS2kV3wc/j3cuA9a+tbEswKF
'' SIG '' Ajrqs9lu5GkhN96B0fZ1GQVn05NXXikbOcjuLeHN5EVz
'' SIG '' W9DSznqrFhmCRljQXp2Bs2evbDXyvOU/JOI1ogp1BvYY
'' SIG '' VpnUeCzRBRvr0IgBnaoQ8QXfun4sY7cGmyMhxPl4bOJY
'' SIG '' FwY2K5ESA8yk2fItuvmUnUDtGEXxzopcaz6rA9NwGCoK
'' SIG '' auBfR9HVYwoy8q/XNh8qcFrlQlkIcUtXun6DgfAhPPQc
'' SIG '' wcW5kJMOiEWThumxIJm+mMvFlaRdYtagYwggvXUQd309
'' SIG '' 80W5n5efy1eAbzOpBM93pGIcWX4xghnUMIIZ0AIBATCB
'' SIG '' nDCBhDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
'' SIG '' bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
'' SIG '' FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEuMCwGA1UEAxMl
'' SIG '' TWljcm9zb2Z0IFdpbmRvd3MgUHJvZHVjdGlvbiBQQ0Eg
'' SIG '' MjAxMQITMwAAAzyJxmp7RbsfvQAAAAADPDANBglghkgB
'' SIG '' ZQMEAgEFAKCCAQQwGQYJKoZIhvcNAQkDMQwGCisGAQQB
'' SIG '' gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
'' SIG '' ARUwLwYJKoZIhvcNAQkEMSIEIKB3KTvjHOwjJx/hn7dw
'' SIG '' 25GG9ZVY36lHuHhwdldxEuIxMDwGCisGAQQBgjcKAxwx
'' SIG '' LgwsQkMyV2E3YWphdlFZK1N5ZWRHVlhiRjBqcDAwZkUy
'' SIG '' RG50VE5yU1BIRWdDdz0wWgYKKwYBBAGCNwIBDDFMMEqg
'' SIG '' JIAiAE0AaQBjAHIAbwBzAG8AZgB0ACAAVwBpAG4AZABv
'' SIG '' AHcAc6EigCBodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
'' SIG '' d2luZG93czANBgkqhkiG9w0BAQEFAASCAQC3ZtDfMq+6
'' SIG '' Yu5YuTuXAQpgaD2PraeG48Wz0GMeC7OAEUqWvkhXlSi4
'' SIG '' PVJPyAyhZ+kAYf3LbGsNTHfZewIBLk19qumgrbt1Rw2L
'' SIG '' pmTN0Hq7FRzVnCxUVBLWgkrbnQ5yPOJTL5Q9uIpy1+iA
'' SIG '' Ze4oBswGOStCo6FR6PELroLpK3nAv8Swmd6BnihngZW0
'' SIG '' yDK9EED3P6AnOH13/8Uo6gzKnw3SNYzzMowxNRgyWOJP
'' SIG '' NjwMJo35fwbKYEdsj1NCC5MOnZviiT5jwHWs9a3p0tpE
'' SIG '' /wOMbScefyKnMOJvPV7OCvkceuYEaoBetUFIIaxMyN+5
'' SIG '' jO1lkS45fXV0dnIeIcTkk0DxoYIXADCCFvwGCisGAQQB
'' SIG '' gjcDAwExghbsMIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUC
'' SIG '' AQMxDzANBglghkgBZQMEAgEFADCCAVEGCyqGSIb3DQEJ
'' SIG '' EAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEw
'' SIG '' DQYJYIZIAWUDBAIBBQAEIJly34eMyQKZDcDvgrWEZ6f2
'' SIG '' kFMR2IJOAdu6G7vOGKTuAgZiadiVZzYYEzIwMjIwNTA3
'' SIG '' MDMyNzQ3LjY1MlowBIACAfSggdCkgc0wgcoxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
'' SIG '' bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxl
'' SIG '' cyBUU1MgRVNOOjIyNjQtRTMzRS03ODBDMSUwIwYDVQQD
'' SIG '' ExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloIIR
'' SIG '' VzCCBwwwggT0oAMCAQICEzMAAAGYdrOMxdAFoQEAAQAA
'' SIG '' AZgwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMx
'' SIG '' EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
'' SIG '' ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
'' SIG '' dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
'' SIG '' bXAgUENBIDIwMTAwHhcNMjExMjAyMTkwNTE1WhcNMjMw
'' SIG '' MjI4MTkwNTE1WjCByjELMAkGA1UEBhMCVVMxEzARBgNV
'' SIG '' BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
'' SIG '' HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEl
'' SIG '' MCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0
'' SIG '' aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MjI2
'' SIG '' NC1FMzNFLTc4MEMxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
'' SIG '' AQUAA4ICDwAwggIKAoICAQDG1JWsVksp8xG4sLMnfxfi
'' SIG '' t3ShI+7G1MfTT+5XvQzuAOe8r5MRAFITTmjFxzoLFfma
'' SIG '' xLvPVlmDgkDi0rqsOs9Al9jVwYSFVF/wWC2+B76Oysiy
'' SIG '' Rjw+NPj5A4cmMhPqIdNkRLCE+wtuI/wCaq3/Lf4koDGu
'' SIG '' dIcEYRgMqqToOOUIV4e7EdYb3k9rYPN7SslwsLFSp+Fv
'' SIG '' m/Qcy5KqfkmMX4S3oJx7HdiQhKbK1C6Zfib+761bmrdP
'' SIG '' LT6eddlnywls7hCrIIuFtgUbUj6KJIZn1MbYY8hrAM59
'' SIG '' tvLpeGmFW3GjeBAmvBxAn7o9Lp2nykT1w9I0s9ddwpFn
'' SIG '' jLT2PK74GDSsxFUZG1UtLypi/kZcg9WenPAZpUtPFfO5
'' SIG '' Mtif8Ja8jXXLIP6K+b5LiQV8oIxFSBfgFN7/TL2tSSfQ
'' SIG '' VcvqX1mcSOrx/tsgq3L6YAxI6Pl4h1zQrcAmToypEoPY
'' SIG '' Nc/RlSBk6ljmNyNDsX3gtK8p6c7HCWUhF+YjMgfanQmM
'' SIG '' jUYsbjdEsCyL6QAojZ0f6kteN4cV6obFwcUEviYygWbe
'' SIG '' daT86OGe9LEOxPuhzgFv2ZobVr0J8hl1FVdcZFbfFN/g
'' SIG '' djHZ/ncDDqLNWgcoMoEhwwzo7FAObqKaxfB5zCBqYSj4
'' SIG '' 5miNO5g3hP8AgC0eSCHl3rK7JPMr1B+8JTHtwRkSKz/+
'' SIG '' cwIDAQABo4IBNjCCATIwHQYDVR0OBBYEFG6RhHKNpsg3
'' SIG '' mgons7LR5YHTzeE3MB8GA1UdIwQYMBaAFJ+nFV0AXmJd
'' SIG '' g/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0
'' SIG '' dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3Js
'' SIG '' L01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
'' SIG '' MDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYB
'' SIG '' BQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
'' SIG '' a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFt
'' SIG '' cCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQC
'' SIG '' MAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcN
'' SIG '' AQELBQADggIBACT6B6F33i/89zXTgqQ8L6CYMHx9BiaH
'' SIG '' OV+wk53JOriCzeaLjYgRyssJhmnnJ/CdHa5qjcSwvRpt
'' SIG '' WpZJPVK5sxhOIjRBPgs/3+ER0vS87IA+aGbf7NF7LZZl
'' SIG '' xWPOl/yFBg9qZ3tpOGOohQInQn5zpV23hWopaN4c49jG
'' SIG '' JHLPAfy9u7+ZSGQuw14CsW/XRLELHT18I60W0uKOBa5P
'' SIG '' m2ViohMovcbpNUCEERqIO9WPwzIwMRRw34/LgjuslHJo
'' SIG '' p+/1Ve/CfyNqweUmwepQHJrd+wTLUlgm4ENbXF6i52jF
'' SIG '' fYpESwLdAn56o/pj+grsd2LrAEPQRyh49rWvI/qZfOht
'' SIG '' T2FWmzFw6IJvZ7CzT1O+Fc0gIDBNqass5QbmkOkKYy9U
'' SIG '' 7nFA6qn3ZZ+MrZMsJTj7gxAf0yMkVqwYWZRk4brY9q8J
'' SIG '' DPmcfNSjRrVfpYyzEVEqemGanmxvDDTzS2wkSBa3zcNw
'' SIG '' OgYhWBTmJdLgyiWJGeqyj1m5bwNgnOw6NzXCiVMzfbzt
'' SIG '' dkqOdTR88LtAJGNRjevWjQd5XitGuegSp2mMJglFzRwk
'' SIG '' ncQau1BJsCj/1aDY4oMiO8conkmaWBrYe11QCS896/sZ
'' SIG '' wSdnEUJak0qpnBRFB+THRIxIivCKNbxG2QRZ8dh95cOX
'' SIG '' go0YvBN5a1p+iJ3vNwzneU2AIC7z3rrIbN2fMIIHcTCC
'' SIG '' BVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
'' SIG '' hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
'' SIG '' BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
'' SIG '' HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
'' SIG '' MDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNh
'' SIG '' dGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1
'' SIG '' WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzET
'' SIG '' MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
'' SIG '' bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
'' SIG '' aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
'' SIG '' cCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIP
'' SIG '' ADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6c
'' SIG '' BwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNx
'' SIG '' WuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5G
'' SIG '' awcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWEC
'' SIG '' esSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+
'' SIG '' tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzp
'' SIG '' cGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7
'' SIG '' mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKN
'' SIG '' iOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRf
'' SIG '' NN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9itu
'' SIG '' qBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zb
'' SIG '' r17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEB
'' SIG '' c8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaD
'' SIG '' IV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2
'' SIG '' XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cI
'' SIG '' FRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGj
'' SIG '' ggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsG
'' SIG '' AQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAd
'' SIG '' BgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYD
'' SIG '' VR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEF
'' SIG '' BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
'' SIG '' aW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQM
'' SIG '' MAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1
'' SIG '' AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTAD
'' SIG '' AQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fO
'' SIG '' mhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
'' SIG '' bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01p
'' SIG '' Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEF
'' SIG '' BQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cu
'' SIG '' bWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2Vy
'' SIG '' QXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUA
'' SIG '' A4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5H
'' SIG '' ZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zR
'' SIG '' oZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gng
'' SIG '' ugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe5
'' SIG '' 3Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09
'' SIG '' J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlC
'' SIG '' GVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyR
'' SIG '' gNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1
'' SIG '' MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkk
'' SIG '' vnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZ
'' SIG '' KCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJ
'' SIG '' sWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcV
'' SIG '' v7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6
'' SIG '' TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq
'' SIG '' 0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NN
'' SIG '' je6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEB
'' SIG '' MIH4oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEGA1UE
'' SIG '' CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
'' SIG '' MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUw
'' SIG '' IwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRp
'' SIG '' b25zMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjoyMjY0
'' SIG '' LUUzM0UtNzgwQzElMCMGA1UEAxMcTWljcm9zb2Z0IFRp
'' SIG '' bWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA
'' SIG '' 8ywe/iF5M8fIU2aT6yQ3vnPpV5OggYMwgYCkfjB8MQsw
'' SIG '' CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
'' SIG '' MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
'' SIG '' b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
'' SIG '' ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
'' SIG '' AQUFAAIFAOYgNEwwIhgPMjAyMjA1MDcwNzU3MDBaGA8y
'' SIG '' MDIyMDUwODA3NTcwMFowdzA9BgorBgEEAYRZCgQBMS8w
'' SIG '' LTAKAgUA5iA0TAIBADAKAgEAAgIBEwIB/zAHAgEAAgIT
'' SIG '' NDAKAgUA5iGFzAIBADA2BgorBgEEAYRZCgQCMSgwJjAM
'' SIG '' BgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAID
'' SIG '' AYagMA0GCSqGSIb3DQEBBQUAA4GBABBKMJV63yzm3NXY
'' SIG '' I2nqsMarZJKsgbBJL4Hu2Jylzhu1QsKOxZSXYHsLps49
'' SIG '' ekXkVq+JtDeeJCEzB14K7zNZfBKWGB337kkA1iVwZp46
'' SIG '' 5uhsQiVQwbpcvTXLl3C9gBYWS0NauypqhEM9m43ay3FS
'' SIG '' Znf4hvbJHBFaCLk+cIWBliBRMYIEDTCCBAkCAQEwgZMw
'' SIG '' fDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
'' SIG '' cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGY
'' SIG '' drOMxdAFoQEAAQAAAZgwDQYJYIZIAWUDBAIBBQCgggFK
'' SIG '' MBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkq
'' SIG '' hkiG9w0BCQQxIgQgYWWHyYk7/j88RXSf5k2W1Xg+fwWK
'' SIG '' 3UctYW3I9UV+2wkwgfoGCyqGSIb3DQEJEAIvMYHqMIHn
'' SIG '' MIHkMIG9BCC/ps4GOTn/9wO1NhHM9Qfe0loB3slkw1FF
'' SIG '' 3r+bh21WxDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
'' SIG '' IFBDQSAyMDEwAhMzAAABmHazjMXQBaEBAAEAAAGYMCIE
'' SIG '' IPWaWQy/3Jv/qFI8fXFEJnC8oDUrggCTYRT3d5hYCPyd
'' SIG '' MA0GCSqGSIb3DQEBCwUABIICAFStlOfBWwR469dlCb2c
'' SIG '' kRZRM9HiQvQQXm9u/LXQJPqrocHASP0/Z5mep4JjlS3y
'' SIG '' oePCdp7Ld1wsks1KF96UCw1eqbsQLd8XgM4vfBpMrKS4
'' SIG '' nfIAEu50bkbVsQ0TMKVPsY6kEr5cZHYglc9eoC+SshqX
'' SIG '' YOMJiqbBqfgCkXUjZjFpkvkM+SYb2Rj+KeV/4WHgu1Gw
'' SIG '' bmHihRgkP2Nr+rWevWGax/kDL46OXOLX/DAZqHTFpWVh
'' SIG '' JqF+D0XkFaztISO/rZMZuNSL3oK/Vi78wkV94mGwPR5B
'' SIG '' lzuaIs0FEO6GB4yRfrwjAbNZKKa4JviclGKoyCSQnl4n
'' SIG '' JJDYgi7DSPK23EkG03l8dOWE6rMbC3NubFVsDbOdsVZo
'' SIG '' T1HESYta8pBxNNfTrnqvVriiC3CKDBZeweUu6tD7VCv/
'' SIG '' jY6PmBqb+krxuxBj5fSlU+W7vpgaNX8A8PeXuXer65hB
'' SIG '' KiZEfQjbQUqA9Hz8HUPDAg9upfU8+VcdJXLnj1JiIeBz
'' SIG '' GVIRGwQz8vvOGPdD2gIKgVgNoFX/HQAG2EG+Sfg4AmJT
'' SIG '' 21imNWkaNN0h01CWZ4GQhflqDOlNidPBJovHzWRyFUwK
'' SIG '' Wk7ObJsldpGp8NBH/6GWH843AVzzoSg9LcaoifIY5oDd
'' SIG '' 1tQaEyxZaKBqzgv9PUQGIAqYRc2gohpsL0UbBYO2Kg+m
'' SIG '' ujAv
'' SIG '' End signature block
