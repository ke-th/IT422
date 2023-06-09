'----------------------------------------------------------------------
'
' Copyright (c) Microsoft Corporation. All rights reserved.
'
' Abstract:
' prnmngr.vbs - printer script for WMI on Windows 
'     used to add, delete, and list printers and connections
'     also for getting and setting the default printer
'
' Usage:
' prnmngr [-adxgtl?][co] [-s server][-p printer][-m driver model][-r port]
'                       [-u user name][-w password]
'
' Examples:
' prnmngr -a -p "printer" -m "driver" -r "lpt1:"
' prnmngr -d -p "printer" -s server
' prnmngr -ac -p "\\server\printer"
' prnmngr -d -p "\\server\printer"
' prnmngr -x -s server
' prnmngr -l -s server
' prnmngr -g
' prnmngr -t -p "printer"
'
'----------------------------------------------------------------------

option explicit

'
' Debugging trace flags, to enable debug output trace message
' change gDebugFlag to true.
'
const kDebugTrace = 1
const kDebugError = 2
dim   gDebugFlag

gDebugFlag = false

'
' Operation action values.
'
const kActionUnknown           = 0
const kActionAdd               = 1
const kActionAddConn           = 2
const kActionDel               = 3
const kActionDelAll            = 4
const kActionDelAllCon         = 5
const kActionDelAllLocal       = 6
const kActionList              = 7
const kActionGetDefaultPrinter = 8
const kActionSetDefaultPrinter = 9

const kErrorSuccess            = 0
const KErrorFailure            = 1

const kFlagCreateOnly          = 2

const kNameSpace               = "root\cimv2"

'
' Generic strings
'
const L_Empty_Text                 = ""
const L_Space_Text                 = " "
const L_Error_Text                 = "Error"
const L_Success_Text               = "Success"
const L_Failed_Text                = "Failed"
const L_Hex_Text                   = "0x"
const L_Printer_Text               = "Printer"
const L_Operation_Text             = "Operation"
const L_Provider_Text              = "Provider"
const L_Description_Text           = "Description"
const L_Debug_Text                 = "Debug:"
const L_Connection_Text            = "connection"

'
' General usage messages
'
const L_Help_Help_General01_Text   = "Usage: prnmngr [-adxgtl?][c] [-s server][-p printer][-m driver model]"
const L_Help_Help_General02_Text   = "               [-r port][-u user name][-w password]"
const L_Help_Help_General03_Text   = "Arguments:"
const L_Help_Help_General04_Text   = "-a     - add local printer"
const L_Help_Help_General05_Text   = "-ac    - add printer connection"
const L_Help_Help_General06_Text   = "-d     - delete printer"
const L_Help_Help_General07_Text   = "-g     - get the default printer"
const L_Help_Help_General08_Text   = "-l     - list printers"
const L_Help_Help_General09_Text   = "-m     - driver model"
const L_Help_Help_General10_Text   = "-p     - printer name"
const L_Help_Help_General11_Text   = "-r     - port name"
const L_Help_Help_General12_Text   = "-s     - server name"
const L_Help_Help_General13_Text   = "-t     - set the default printer"
const L_Help_Help_General14_Text   = "-u     - user name"
const L_Help_Help_General15_Text   = "-w     - password"
const L_Help_Help_General16_Text   = "-x     - delete all printers"
const L_Help_Help_General17_Text   = "-xc    - delete all printer connections"
const L_Help_Help_General18_Text   = "-xo    - delete all local printers"
const L_Help_Help_General19_Text   = "-?     - display command usage"
const L_Help_Help_General20_Text   = "Examples:"
const L_Help_Help_General21_Text   = "prnmngr -a -p ""printer"" -m ""driver"" -r ""lpt1:"""
const L_Help_Help_General22_Text   = "prnmngr -d -p ""printer"" -s server"
const L_Help_Help_General23_Text   = "prnmngr -ac -p ""\\server\printer"""
const L_Help_Help_General24_Text   = "prnmngr -d -p ""\\server\printer"""
const L_Help_Help_General25_Text   = "prnmngr -x -s server"
const L_Help_Help_General26_Text   = "prnmngr -xo"
const L_Help_Help_General27_Text   = "prnmngr -l -s server"
const L_Help_Help_General28_Text   = "prnmngr -g"
const L_Help_Help_General29_Text   = "prnmngr -t -p ""\\server\printer"""

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
const L_Text_Msg_General01_Text    = "Added printer"
const L_Text_Msg_General02_Text    = "Unable to add printer"
const L_Text_Msg_General03_Text    = "Added printer connection"
const L_Text_Msg_General04_Text    = "Unable to add printer connection"
const L_Text_Msg_General05_Text    = "Deleted printer"
const L_Text_Msg_General06_Text    = "Unable to delete printer"
const L_Text_Msg_General07_Text    = "Attempting to delete printer"
const L_Text_Msg_General08_Text    = "Unable to delete printers"
const L_Text_Msg_General09_Text    = "Number of local printers and connections enumerated"
const L_Text_Msg_General10_Text    = "Number of local printers and connections deleted"
const L_Text_Msg_General11_Text    = "Unable to enumerate printers"
const L_Text_Msg_General12_Text    = "The default printer is"
const L_Text_Msg_General13_Text    = "Unable to get the default printer"
const L_Text_Msg_General14_Text    = "Unable to set the default printer"
const L_Text_Msg_General15_Text    = "The default printer is now"
const L_Text_Msg_General16_Text    = "Number of printer connections enumerated"
const L_Text_Msg_General17_Text    = "Number of printer connections deleted"
const L_Text_Msg_General18_Text    = "Number of local printers enumerated"
const L_Text_Msg_General19_Text    = "Number of local printers deleted"

'
' Printer properties
'
const L_Text_Msg_Printer01_Text    = "Server name"
const L_Text_Msg_Printer02_Text    = "Printer name"
const L_Text_Msg_Printer03_Text    = "Share name"
const L_Text_Msg_Printer04_Text    = "Driver name"
const L_Text_Msg_Printer05_Text    = "Port name"
const L_Text_Msg_Printer06_Text    = "Comment"
const L_Text_Msg_Printer07_Text    = "Location"
const L_Text_Msg_Printer08_Text    = "Separator file"
const L_Text_Msg_Printer09_Text    = "Print processor"
const L_Text_Msg_Printer10_Text    = "Data type"
const L_Text_Msg_Printer11_Text    = "Parameters"
const L_Text_Msg_Printer12_Text    = "Attributes"
const L_Text_Msg_Printer13_Text    = "Priority"
const L_Text_Msg_Printer14_Text    = "Default priority"
const L_Text_Msg_Printer15_Text    = "Start time"
const L_Text_Msg_Printer16_Text    = "Until time"
const L_Text_Msg_Printer17_Text    = "Job count"
const L_Text_Msg_Printer18_Text    = "Average pages per minute"
const L_Text_Msg_Printer19_Text    = "Printer status"
const L_Text_Msg_Printer20_Text    = "Extended printer status"
const L_Text_Msg_Printer21_Text    = "Detected error state"
const L_Text_Msg_Printer22_Text    = "Extended detected error state"


'
' Printer status
'
const L_Text_Msg_Status01_Text     = "Other"
const L_Text_Msg_Status02_Text     = "Unknown"
const L_Text_Msg_Status03_Text     = "Idle"
const L_Text_Msg_Status04_Text     = "Printing"
const L_Text_Msg_Status05_Text     = "Warmup"
const L_Text_Msg_Status06_Text     = "Stopped printing"
const L_Text_Msg_Status07_Text     = "Offline"
const L_Text_Msg_Status08_Text     = "Paused"
const L_Text_Msg_Status09_Text     = "Error"
const L_Text_Msg_Status10_Text     = "Busy"
const L_Text_Msg_Status11_Text     = "Not available"
const L_Text_Msg_Status12_Text     = "Waiting"
const L_Text_Msg_Status13_Text     = "Processing"
const L_Text_Msg_Status14_Text     = "Initializing"
const L_Text_Msg_Status15_Text     = "Power save"
const L_Text_Msg_Status16_Text     = "Pending deletion"
const L_Text_Msg_Status17_Text     = "I/O active"
const L_Text_Msg_Status18_Text     = "Manual feed"
const L_Text_Msg_Status19_Text     = "No error"
const L_Text_Msg_Status20_Text     = "Low paper"
const L_Text_Msg_Status21_Text     = "No paper"
const L_Text_Msg_Status22_Text     = "Low toner"
const L_Text_Msg_Status23_Text     = "No toner"
const L_Text_Msg_Status24_Text     = "Door open"
const L_Text_Msg_Status25_Text     = "Jammed"
const L_Text_Msg_Status26_Text     = "Service requested"
const L_Text_Msg_Status27_Text     = "Output bin full"
const L_Text_Msg_Status28_Text     = "Paper problem"
const L_Text_Msg_Status29_Text     = "Cannot print page"
const L_Text_Msg_Status30_Text     = "User intervention required"
const L_Text_Msg_Status31_Text     = "Out of memory"
const L_Text_Msg_Status32_Text     = "Server unknown"

'
' Debug messages
'
const L_Text_Dbg_Msg01_Text        = "In function AddPrinter"
const L_Text_Dbg_Msg02_Text        = "In function AddPrinterConnection"
const L_Text_Dbg_Msg03_Text        = "In function DelPrinter"
const L_Text_Dbg_Msg04_Text        = "In function DelAllPrinters"
const L_Text_Dbg_Msg05_Text        = "In function ListPrinters"
const L_Text_Dbg_Msg06_Text        = "In function GetDefaultPrinter"
const L_Text_Dbg_Msg07_Text        = "In function SetDefaultPrinter"
const L_Text_Dbg_Msg08_Text        = "In function ParseCommandLine"

main

'
' Main execution starts here
'
sub main

    dim iAction
    dim iRetval
    dim strServer
    dim strPrinter
    dim strDriver
    dim strPort
    dim strUser
    dim strPassword

    '
    ' Abort if the host is not cscript
    '
    if not IsHostCscript() then

        call wscript.echo(L_Help_Help_Host01_Text & vbCRLF & L_Help_Help_Host02_Text & vbCRLF & _
                          L_Help_Help_Host03_Text & vbCRLF & L_Help_Help_Host04_Text & vbCRLF & _
                          L_Help_Help_Host05_Text & vbCRLF & L_Help_Help_Host06_Text & vbCRLF)

        wscript.quit

    end if

    '
    ' Get command line parameters
    '
    iRetval = ParseCommandLine(iAction, strServer, strPrinter, strDriver, strPort, strUser, strPassword)

    if iRetval = kErrorSuccess then

        select case iAction

            case kActionAdd
                 iRetval = AddPrinter(strServer, strPrinter, strDriver, strPort, strUser, strPassword)

            case kActionAddConn
                 iRetval = AddPrinterConnection(strPrinter, strUser, strPassword)

            case kActionDel
                 iRetval = DelPrinter(strServer, strPrinter, strUser, strPassword)

            case kActionDelAll
                 iRetval = DelAllPrinters(kActionDelAll, strServer, strUser, strPassword)

            case kActionDelAllCon
                 iRetval = DelAllPrinters(kActionDelAllCon, strServer, strUser, strPassword)

            case kActionDelAllLocal
                 iRetval = DelAllPrinters(kActionDelAllLocal, strServer, strUser, strPassword)

            case kActionList
                 iRetval = ListPrinters(strServer, strUser, strPassword)

            case kActionGetDefaultPrinter
                 iRetval = GetDefaultPrinter(strUser, strPassword)

            case kActionSetDefaultPrinter
                 iRetval = SetDefaultPrinter(strPrinter, strUser, strPassword)

            case kActionUnknown
                 Usage(true)
                 exit sub

            case else
                 Usage(true)
                 exit sub

        end select

    end if

end sub

'
' Add a printer with minimum settings. Use prncnfg.vbs to
' set the complete configuration of a printer
'
function AddPrinter(strServer, strPrinter, strDriver, strPort, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg01_Text
    DebugPrint kDebugTrace, L_Text_Msg_Printer01_Text & L_Space_Text & strServer
    DebugPrint kDebugTrace, L_Text_Msg_Printer02_Text & L_Space_Text & strPrinter
    DebugPrint kDebugTrace, L_Text_Msg_Printer04_Text & L_Space_Text & strDriver
    DebugPrint kDebugTrace, L_Text_Msg_Printer05_Text & L_Space_Text & strPort

    dim oPrinter
    dim oService
    dim iRetval

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPrinter = oService.Get("Win32_Printer").SpawnInstance_

    else

        AddPrinter = kErrorFailure

        exit function

    end if

    oPrinter.DriverName = strDriver
    oPrinter.PortName   = strPort
    oPrinter.DeviceID   = strPrinter

    oPrinter.Put_(kFlagCreateOnly)

    if Err.Number = kErrorSuccess then

        wscript.echo L_Text_Msg_General01_Text & L_Space_Text & strPrinter

        iRetval = kErrorSuccess

    else

        wscript.echo L_Text_Msg_General02_Text & L_Space_Text & strPrinter & L_Space_Text & L_Error_Text _
                     & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

        iRetval = kErrorFailure

    end if

    AddPrinter = iRetval

end function

'
' Add a printer connection
'
function AddPrinterConnection(strPrinter, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg02_Text

    dim oPrinter
    dim oService
    dim iRetval
    dim uResult

    '
    ' Initialize return value
    '
    iRetval = kErrorFailure

    '
    ' We connect to the local server
    '
    if WmiConnect("", kNameSpace, strUser, strPassword, oService) then

        set oPrinter = oService.Get("Win32_Printer")

    else

        AddPrinterConnection = kErrorFailure

        exit function

    end if

    '
    ' Check if Get was successful
    '
    if Err.Number = kErrorSuccess then

        '
        ' The Err object indicates whether the WMI provider reached the execution
        ' of the function that adds a printer connection. The uResult is the Win32
        ' error code returned by the static method that adds a printer connection
        '
        uResult = oPrinter.AddPrinterConnection(strPrinter)

        if Err.Number = kErrorSuccess then

            if uResult = kErrorSuccess then

                wscript.echo L_Text_Msg_General03_Text & L_Space_Text & strPrinter

                iRetval = kErrorSuccess

            else

                wscript.echo L_Text_Msg_General04_Text & L_Space_Text & L_Text_Error_General03_Text _
                             & L_Space_text & uResult

            end if

        else

            wscript.echo L_Text_Msg_General04_Text & L_Space_Text & strPrinter & L_Space_Text _
                         & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                         & Err.Description

        end if

    else

        wscript.echo L_Text_Msg_General04_Text & L_Space_Text & strPrinter & L_Space_Text _
                     & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                     & Err.Description

    end if

    AddPrinterConnection = iRetval

end function

'
' Delete a printer or a printer connection
'
function DelPrinter(strServer, strPrinter, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg03_Text
    DebugPrint kDebugTrace, L_Text_Msg_Printer01_Text & L_Space_Text & strServer
    DebugPrint kDebugTrace, L_Text_Msg_Printer02_Text & L_Space_Text & strPrinter

    dim oService
    dim oPrinter
    dim iRetval

    iRetval = kErrorFailure

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPrinter = oService.Get("Win32_Printer.DeviceID='" & strPrinter & "'")

    else

        DelPrinter = kErrorFailure

        exit function

    end if

    '
    ' Check if Get was successful
    '
    if Err.Number = kErrorSuccess then

        oPrinter.Delete_

        if Err.Number = kErrorSuccess then

            wscript.echo L_Text_Msg_General05_Text & L_Space_Text & strPrinter

            iRetval = kErrorSuccess

        else

            wscript.echo L_Text_Msg_General06_Text & L_Space_Text & strPrinter & L_Space_Text _
                         & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) _
                         & L_Space_Text & Err.Description

            '
            ' Try getting extended error information
            '
            call LastError()

        end if

    else

        wscript.echo L_Text_Msg_General06_Text & L_Space_Text & strPrinter & L_Space_Text _
                     & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) _
                     & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

    end if

    DelPrinter = iRetval

end function

'
' Delete all local printers and connections on a machine
'
function DelAllPrinters(kAction, strServer, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg04_Text

    dim Printers
    dim oPrinter
    dim oService
    dim iResult
    dim iTotal
    dim iTotalDeleted
    dim strPrinterName
    dim bDelete
    dim bConnection
    dim strTemp

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set Printers = oService.InstancesOf("Win32_Printer")

    else

        DelAllPrinters = kErrorFailure

        exit function

    end if

    if Err.Number <> kErrorSuccess then

        wscript.echo L_Text_Msg_General11_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        DelAllPrinters = kErrorFailure

        exit function

    end if

    iTotal = 0
    iTotalDeleted = 0

    for each oPrinter in Printers

        strPrinterName = oPrinter.DeviceID

        bConnection = oPrinter.Network

        if kAction = kActionDelAll then

            bDelete = 1

            iTotal = iTotal + 1

        elseif kAction = kActionDelAllCon and bConnection then

            bDelete = 1

            iTotal = iTotal + 1

        elseif kAction = kActionDelAllLocal and not bConnection then

            bDelete = 1

            iTotal = iTotal + 1

        else

            bDelete = 0

        end if

        if bDelete = 1 then

            if bConnection then

                strTemp = L_Space_Text & L_Connection_Text & L_Space_Text

            else

                strTemp = L_Space_Text

            end if

            '
            ' Delete printer instance
            '
            oPrinter.Delete_

            if Err.Number = kErrorSuccess then

                wscript.echo L_Text_Msg_General05_Text & strTemp & oPrinter.DeviceID

                iTotalDeleted = iTotalDeleted + 1

            else

                wscript.echo L_Text_Msg_General06_Text & strTemp & strPrinterName _
                             & L_Space_Text & L_Error_Text & L_Space_Text & L_Hex_Text _
                             & hex(Err.Number) & L_Space_Text & Err.Description

                '
                ' Try getting extended error information
                '
                call LastError()

                '
                ' Continue deleting the rest of the printers despite this error
                '
                Err.Clear

            end if

        end if

    next

    wscript.echo L_Empty_Text

    if kAction = kActionDelAll then

        wscript.echo L_Text_Msg_General09_Text & L_Space_Text & iTotal
        wscript.echo L_Text_Msg_General10_Text & L_Space_Text & iTotalDeleted

    elseif kAction = kActionDelAllCon then

        wscript.echo L_Text_Msg_General16_Text & L_Space_Text & iTotal
        wscript.echo L_Text_Msg_General17_Text & L_Space_Text & iTotalDeleted

    elseif kAction = kActionDelAllLocal then

        wscript.echo L_Text_Msg_General18_Text & L_Space_Text & iTotal
        wscript.echo L_Text_Msg_General19_Text & L_Space_Text & iTotalDeleted

    else

    end if

    DelAllPrinters = kErrorSuccess

end function

'
' List the printers
'
function ListPrinters(strServer, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg05_Text

    dim Printers
    dim oService
    dim oPrinter
    dim iTotal

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set Printers = oService.InstancesOf("Win32_Printer")

    else

        ListPrinters = kErrorFailure

        exit function

    end if

    if Err.Number <> kErrorSuccess then

        wscript.echo L_Text_Msg_General11_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        ListPrinters = kErrorFailure

        exit function

    end if

    iTotal = 0

    for each oPrinter in Printers

        iTotal = iTotal + 1

        wscript.echo L_Empty_Text
        wscript.echo L_Text_Msg_Printer01_Text & L_Space_Text & strServer
        wscript.echo L_Text_Msg_Printer02_Text & L_Space_Text & oPrinter.DeviceID
        wscript.echo L_Text_Msg_Printer03_Text & L_Space_Text & oPrinter.ShareName
        wscript.echo L_Text_Msg_Printer04_Text & L_Space_Text & oPrinter.DriverName
        wscript.echo L_Text_Msg_Printer05_Text & L_Space_Text & oPrinter.PortName
        wscript.echo L_Text_Msg_Printer06_Text & L_Space_Text & oPrinter.Comment
        wscript.echo L_Text_Msg_Printer07_Text & L_Space_Text & oPrinter.Location
        wscript.echo L_Text_Msg_Printer08_Text & L_Space_Text & oPrinter.SepFile
        wscript.echo L_Text_Msg_Printer09_Text & L_Space_Text & oPrinter.PrintProcessor
        wscript.echo L_Text_Msg_Printer10_Text & L_Space_Text & oPrinter.PrintJobDataType
        wscript.echo L_Text_Msg_Printer11_Text & L_Space_Text & oPrinter.Parameters
        wscript.echo L_Text_Msg_Printer12_Text & L_Space_Text & CSTR(oPrinter.Attributes)
        wscript.echo L_Text_Msg_Printer13_Text & L_Space_Text & CSTR(oPrinter.Priority)
        wscript.echo L_Text_Msg_Printer14_Text & L_Space_Text & CStr(oPrinter.DefaultPriority)

        if CStr(oPrinter.StartTime) <> "" and CStr(oPrinter.UntilTime) <> "" then

            wscript.echo L_Text_Msg_Printer15_Text & L_Space_Text & Mid(Mid(CStr(oPrinter.StartTime), 9, 4), 1, 2) & "h" & Mid(Mid(CStr(oPrinter.StartTime), 9, 4), 3, 2)
            wscript.echo L_Text_Msg_Printer16_Text & L_Space_Text & Mid(Mid(CStr(oPrinter.UntilTime), 9, 4), 1, 2) & "h" & Mid(Mid(CStr(oPrinter.UntilTime), 9, 4), 3, 2)

        end if

        wscript.echo L_Text_Msg_Printer17_Text & L_Space_Text & CStr(oPrinter.Jobs)
        wscript.echo L_Text_Msg_Printer18_Text & L_Space_Text & CStr(oPrinter.AveragePagesPerMinute)
        wscript.echo L_Text_Msg_Printer19_Text & L_Space_Text & PrnStatusToString(oPrinter.PrinterStatus)
        wscript.echo L_Text_Msg_Printer20_Text & L_Space_Text & ExtPrnStatusToString(oPrinter.ExtendedPrinterStatus)
        wscript.echo L_Text_Msg_Printer21_Text & L_Space_Text & DetectedErrorStateToString(oPrinter.DetectedErrorState)
        wscript.echo L_Text_Msg_Printer22_Text & L_Space_Text & ExtDetectedErrorStateToString(oPrinter.ExtendedDetectedErrorState)

        Err.Clear

    next

    wscript.echo L_Empty_Text
    wscript.echo L_Text_Msg_General09_Text & L_Space_Text & iTotal

    ListPrinters = kErrorSuccess

end function

'
' Get the default printer
'
function GetDefaultPrinter(strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg06_Text

    dim oService
    dim oPrinter
    dim iRetval
    dim oEnum

    iRetval = kErrorFailure

    '
    ' We connect to the local server
    '
    if WmiConnect("", kNameSpace, strUser, strPassword, oService) then

        set oEnum    = oService.ExecQuery("select DeviceID from Win32_Printer where default=true")

    else

        SetDefaultPrinter = kErrorFailure

        exit function

    end if

    if Err.Number = kErrorSuccess then

         for each oPrinter in oEnum

            wscript.echo L_Text_Msg_General12_Text & L_Space_Text & oPrinter.DeviceID

         next

         iRetval = kErrorSuccess

    else

        wscript.echo L_Text_Msg_General13_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

    end if

    GetDefaultPrinter = iRetval

end function

'
' Set the default printer
'
function SetDefaultPrinter(strPrinter, strUser, strPassword)

    'on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg07_Text

    dim oService
    dim oPrinter
    dim iRetval
    dim uResult

    iRetval = kErrorFailure

    '
    ' We connect to the local server
    '
    if WmiConnect("", kNameSpace, strUser, strPassword, oService) then

        set oPrinter = oService.Get("Win32_Printer.DeviceID='" & strPrinter & "'")

    else

        SetDefaultPrinter = kErrorFailure

        exit function

    end if

    '
    ' Check if Get was successful
    '
    if Err.Number = kErrorSuccess then

        '
        ' The Err object indicates whether the WMI provider reached the execution
        ' of the function that sets the default printer. The uResult is the Win32
        ' error code of the spooler function that sets the default printer
        '
        uResult = oPrinter.SetDefaultPrinter

        if Err.Number = kErrorSuccess then

            if uResult = kErrorSuccess then

                wscript.echo L_Text_Msg_General15_Text & L_Space_Text & strPrinter

                iRetval = kErrorSuccess

            else

                wscript.echo L_Text_Msg_General14_Text & L_Space_Text _
                             & L_Text_Error_General03_Text& L_Space_Text & uResult

            end if

        else

            wscript.echo L_Text_Msg_General14_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                         & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        end if

    else

        wscript.echo L_Text_Msg_General14_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

    end if

    SetDefaultPrinter = iRetval

end function

'
' Converts the printer status to a string
'
function PrnStatusToString(Status)

    dim str

    str = L_Empty_Text

    select case Status

        case 1
            str = str + L_Text_Msg_Status01_Text + L_Space_Text

        case 2
            str = str + L_Text_Msg_Status02_Text + L_Space_Text

        case 3
            str = str + L_Text_Msg_Status03_Text + L_Space_Text

        case 4
            str = str + L_Text_Msg_Status04_Text + L_Space_Text

        case 5
            str = str + L_Text_Msg_Status05_Text + L_Space_Text

        case 6
            str = str + L_Text_Msg_Status06_Text + L_Space_Text

        case 7
            str = str + L_Text_Msg_Status07_Text + L_Space_Text

    end select

    PrnStatusToString = str

end function

'
' Converts the extended printer status to a string
'
function ExtPrnStatusToString(Status)

    dim str

    str = L_Empty_Text

    select case Status

        case 1
            str = str + L_Text_Msg_Status01_Text + L_Space_Text

        case 2
            str = str + L_Text_Msg_Status02_Text + L_Space_Text

        case 3
            str = str + L_Text_Msg_Status03_Text + L_Space_Text

        case 4
            str = str + L_Text_Msg_Status04_Text + L_Space_Text

        case 5
            str = str + L_Text_Msg_Status05_Text + L_Space_Text

        case 6
            str = str + L_Text_Msg_Status06_Text + L_Space_Text

        case 7
            str = str + L_Text_Msg_Status07_Text + L_Space_Text

        case 8
            str = str + L_Text_Msg_Status08_Text + L_Space_Text

        case 9
            str = str + L_Text_Msg_Status09_Text + L_Space_Text

        case 10
            str = str + L_Text_Msg_Status10_Text + L_Space_Text

        case 11
            str = str + L_Text_Msg_Status11_Text + L_Space_Text

        case 12
            str = str + L_Text_Msg_Status12_Text + L_Space_Text

        case 13
            str = str + L_Text_Msg_Status13_Text + L_Space_Text

        case 14
            str = str + L_Text_Msg_Status14_Text + L_Space_Text

        case 15
            str = str + L_Text_Msg_Status15_Text + L_Space_Text

        case 16
            str = str + L_Text_Msg_Status16_Text + L_Space_Text

        case 17
            str = str + L_Text_Msg_Status17_Text + L_Space_Text

        case 18
            str = str + L_Text_Msg_Status18_Text + L_Space_Text

    end select

    ExtPrnStatusToString = str

end function

'
' Converts the detected error state to a string
'
function DetectedErrorStateToString(Status)

    dim str

    str = L_Empty_Text

    select case Status

        case 0
            str = str + L_Text_Msg_Status02_Text + L_Space_Text

        case 1
            str = str + L_Text_Msg_Status01_Text + L_Space_Text

        case 2
            str = str + L_Text_Msg_Status01_Text + L_Space_Text

        case 3
            str = str + L_Text_Msg_Status20_Text + L_Space_Text

        case 4
            str = str + L_Text_Msg_Status21_Text + L_Space_Text

        case 5
            str = str + L_Text_Msg_Status22_Text + L_Space_Text

        case 6
            str = str + L_Text_Msg_Status23_Text + L_Space_Text

        case 7
            str = str + L_Text_Msg_Status24_Text + L_Space_Text

        case 8
            str = str + L_Text_Msg_Status25_Text + L_Space_Text

        case 9
            str = str + L_Text_Msg_Status07_Text + L_Space_Text

        case 10
            str = str + L_Text_Msg_Status26_Text + L_Space_Text

        case 11
            str = str + L_Text_Msg_Status27_Text + L_Space_Text

    end select

    DetectedErrorStateToString = str

end function

'
' Converts the extended detected error state to a string
'
function ExtDetectedErrorStateToString(Status)

    dim str

    str = L_Empty_Text

    select case Status

        case 0
            str = str + L_Text_Msg_Status02_Text + L_Space_Text

        case 1
            str = str + L_Text_Msg_Status01_Text + L_Space_Text

        case 2
            str = str + L_Text_Msg_Status01_Text + L_Space_Text

        case 3
            str = str + L_Text_Msg_Status20_Text + L_Space_Text

        case 4
            str = str + L_Text_Msg_Status21_Text + L_Space_Text

        case 5
            str = str + L_Text_Msg_Status22_Text + L_Space_Text

        case 6
            str = str + L_Text_Msg_Status23_Text + L_Space_Text

        case 7
            str = str + L_Text_Msg_Status24_Text + L_Space_Text

        case 8
            str = str + L_Text_Msg_Status25_Text + L_Space_Text

        case 9
            str = str + L_Text_Msg_Status07_Text + L_Space_Text

        case 10
            str = str + L_Text_Msg_Status26_Text + L_Space_Text

        case 11
            str = str + L_Text_Msg_Status27_Text + L_Space_Text

        case 12
            str = str + L_Text_Msg_Status28_Text + L_Space_Text

        case 13
            str = str + L_Text_Msg_Status29_Text + L_Space_Text

        case 14
            str = str + L_Text_Msg_Status30_Text + L_Space_Text

        case 15
            str = str + L_Text_Msg_Status31_Text + L_Space_Text

        case 16
            str = str + L_Text_Msg_Status32_Text + L_Space_Text

    end select

    ExtDetectedErrorStateToString = str

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
function ParseCommandLine(iAction, strServer, strPrinter, strDriver, strPort, strUser, strPassword)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg08_Text

    dim oArgs
    dim iIndex

    iAction = kActionUnknown
    iIndex  = 0

    set oArgs = wscript.Arguments

    while iIndex < oArgs.Count

        select case oArgs(iIndex)

            case "-a"
                iAction = kActionAdd

            case "-ac"
                iAction = kActionAddConn

            case "-d"
                iAction = kActionDel

            case "-x"
                iAction = kActionDelAll

            case "-xc"
                iAction = kActionDelAllCon

            case "-xo"
                iAction = kActionDelAllLocal

            case "-l"
                iAction = kActionList

            case "-g"
                iAction = kActionGetDefaultPrinter

            case "-t"
                iAction = kActionSetDefaultPrinter

            case "-s"
                iIndex = iIndex + 1
                strServer = RemoveBackslashes(oArgs(iIndex))

            case "-p"
                iIndex = iIndex + 1
                strPrinter = oArgs(iIndex)

            case "-m"
                iIndex = iIndex + 1
                strDriver = oArgs(iIndex)

            case "-u"
                iIndex = iIndex + 1
                strUser = oArgs(iIndex)

            case "-w"
                iIndex = iIndex + 1
                strPassword = oArgs(iIndex)

            case "-r"
                iIndex = iIndex + 1
                strPort = oArgs(iIndex)

            case "-?"
                Usage(true)
                exit function

            case else
                Usage(true)
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
    wscript.echo L_Empty_Text
    wscript.echo L_Help_Help_General20_Text
    wscript.echo L_Help_Help_General21_Text
    wscript.echo L_Help_Help_General22_Text
    wscript.echo L_Help_Help_General23_Text
    wscript.echo L_Help_Help_General24_Text
    wscript.echo L_Help_Help_General25_Text
    wscript.echo L_Help_Help_General26_Text
    wscript.echo L_Help_Help_General27_Text
    wscript.echo L_Help_Help_General28_Text
    wscript.echo L_Help_Help_General29_Text

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
        wscript.echo L_Text_Error_General03_Text & L_Space_Text & oError.StatusCode

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

            wscript.echo L_Text_Msg_General11_Text & L_Space_Text & L_Error_Text _
                         & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                         & Err.Description

        end if

    else

        wscript.echo L_Text_Msg_General10_Text & L_Space_Text & L_Error_Text _
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
'' SIG '' MIIlXQYJKoZIhvcNAQcCoIIlTjCCJUoCAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' JgK02eO+gRAvE2IMUc2ETsWGPR1isJdKW/vFu8QQ+Hag
'' SIG '' ggrhMIIFAjCCA+qgAwIBAgITMwAAAztlX67623Xp1gAA
'' SIG '' AAADOzANBgkqhkiG9w0BAQsFADCBhDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEuMCwGA1UEAxMlTWljcm9zb2Z0IFdpbmRv
'' SIG '' d3MgUHJvZHVjdGlvbiBQQ0EgMjAxMTAeFw0yMTA5MDIx
'' SIG '' ODIzNDFaFw0yMjA5MDExODIzNDFaMHAxCzAJBgNVBAYT
'' SIG '' AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
'' SIG '' EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
'' SIG '' cG9yYXRpb24xGjAYBgNVBAMTEU1pY3Jvc29mdCBXaW5k
'' SIG '' b3dzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
'' SIG '' AQEAs0fMLkmGRLB23RrMrtMahzf8J7c5c5MCQHCYHh6a
'' SIG '' 4ZU0cLLIFr0iNuL5LMDyA+yYhao3hzqzDVRLeao5T2Ny
'' SIG '' NNnnIMldoc2WCGeSqRfwovlFsbEVT0q/jhLalxjYVEpY
'' SIG '' hmVK7FvZj7cbpTbo9umh5mSVMhvn08+yfKZPBd8bn3cW
'' SIG '' 0IweT/iSExXjc9gwEbyiTQwj5IOBZiMPCMXg7+QFAPza
'' SIG '' iQjowQWkIAJsM7DffzOS+4lSp/A9vvXWzzGMFNEvFhfQ
'' SIG '' jz2X8i7Q5d7mWruq+CO52OJHZV1MKqTFUoSByHJI5fkj
'' SIG '' zMZ060WnZt+V2pvh9YBaNXR7BdZ+JCSohETpqwIDAQAB
'' SIG '' o4IBfjCCAXowHwYDVR0lBBgwFgYKKwYBBAGCNwoDBgYI
'' SIG '' KwYBBQUHAwMwHQYDVR0OBBYEFFQvNAHaQy3TdBujh7mk
'' SIG '' 4YGuHetNMFAGA1UdEQRJMEekRTBDMSkwJwYDVQQLEyBN
'' SIG '' aWNyb3NvZnQgT3BlcmF0aW9ucyBQdWVydG8gUmljbzEW
'' SIG '' MBQGA1UEBRMNMjI5ODc5KzQ2NzU3OTAfBgNVHSMEGDAW
'' SIG '' gBSpKQI5jhbEl3jNkPmeT5rhfFWvUzBUBgNVHR8ETTBL
'' SIG '' MEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
'' SIG '' cGtpb3BzL2NybC9NaWNXaW5Qcm9QQ0EyMDExXzIwMTEt
'' SIG '' MTAtMTkuY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEF
'' SIG '' BQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
'' SIG '' aW9wcy9jZXJ0cy9NaWNXaW5Qcm9QQ0EyMDExXzIwMTEt
'' SIG '' MTAtMTkuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcN
'' SIG '' AQELBQADggEBAGSt4A47oowWu0fKMom5sEd0GjauFG+P
'' SIG '' VWX2h+Uyf74Lin+uYopDO84j7x8ufz/VnFPubYjPK96F
'' SIG '' QDiT5L3hVT023vuaWhgDVVi3ifKhOSXgMsum/HJSf/mj
'' SIG '' /GC6DYkO95gGmZ+/Mv1c2+HQd5yd30fLkr4YFDzpmWTW
'' SIG '' pq38QoETkyjuzffrU4LChJQbKxQtq999w2pGdGcpXf76
'' SIG '' pDoSWPlRfmKBcrxTGt8cQrWtWvC8BA3QuUbU1eh/BQQq
'' SIG '' SBMakZQ3u9Jdw+aoJan8DT372rbqxj/wje2cTDJlACs9
'' SIG '' Vj4FJM16t+BDNyrmsVTV0WLmsMqCxOS4IQUVBUkf4FGQ
'' SIG '' 0r8wggXXMIIDv6ADAgECAgphB3ZWAAAAAAAIMA0GCSqG
'' SIG '' SIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
'' SIG '' CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
'' SIG '' MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIw
'' SIG '' MAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
'' SIG '' ZSBBdXRob3JpdHkgMjAxMDAeFw0xMTEwMTkxODQxNDJa
'' SIG '' Fw0yNjEwMTkxODUxNDJaMIGEMQswCQYDVQQGEwJVUzET
'' SIG '' MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
'' SIG '' bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
'' SIG '' aW9uMS4wLAYDVQQDEyVNaWNyb3NvZnQgV2luZG93cyBQ
'' SIG '' cm9kdWN0aW9uIFBDQSAyMDExMIIBIjANBgkqhkiG9w0B
'' SIG '' AQEFAAOCAQ8AMIIBCgKCAQEA3Qy7ouQuCePnxfeWabwA
'' SIG '' Ib1pMzPvrQTLVIDuBoO7xSCE2ffSi/M4sKukrS18YnkF
'' SIG '' /+NKPwQ1IHDjxOdr4JzANnXpijHdjXDl3De1dEaWKFuH
'' SIG '' YCMsv9xHpWf3USeecusHpsm5HjtTNXzl0+wnuYcc/rnJ
'' SIG '' IwlvqEaRwW6WPEHTy6M/XQJqTexpHyUoXDb//UMVCpTg
'' SIG '' GbTP38IS4sJbJ+4neDCLWyoJayKJU2AWLMBoHVO67Enz
'' SIG '' nWGMhWgJc0RdfaJUK9159xXPNV1sHCtczrycI4tvbrUm
'' SIG '' 2TYTw0/WJ665MjtBkizhx8136KpUTvdcCwSHZbRDGKiy
'' SIG '' 4G0Zd+xaJPpIAwIDAQABo4IBQzCCAT8wEAYJKwYBBAGC
'' SIG '' NxUBBAMCAQAwHQYDVR0OBBYEFKkpAjmOFsSXeM2Q+Z5P
'' SIG '' muF8Va9TMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
'' SIG '' MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8G
'' SIG '' A1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYG
'' SIG '' A1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9z
'' SIG '' b2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0Nl
'' SIG '' ckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQRO
'' SIG '' MEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9z
'' SIG '' b2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIw
'' SIG '' MTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQAU
'' SIG '' /HxxUaV5wm6y7zk+vDxSD24rPxATc/6oaNBIpjRNipYF
'' SIG '' Ju4xRpBhedb/OC5Fa/TA5Si42h2PitsJ1xrHTAo2ZmqM
'' SIG '' 7BvXBJCoGBekm7niQDI2dsTBWsa/5ATA6hbTrMNo72Ks
'' SIG '' 3VRsUDBYput8/pSnTo707HyGc1fCUiFzNFrzo4pWyATa
'' SIG '' Bwnt+IvjzvR+jq7w9guKCPs/yR1yf1O4675j4OM9MWWw
'' SIG '' geXyrM0WpJ89qLGbwkLQkIRfVB3/ieq6HUeQb7BzTkGf
'' SIG '' QJ9f5aEqshGRc4ohKPDO3nM5Xz6rXGDs3wMQqNMJ6fT2
'' SIG '' loW2f1GIZkcZjaKwEj2BKmgFd7uRTGJ7tsEHx7p6hzQD
'' SIG '' DktiepnpyvzOSjfJLaRXfBz+Pdy4D1r61sSzAoUCOuqz
'' SIG '' 2W7kaSE33oHR9nUZBWfTk1deKRs5yO4t4c3kRXNb0NLO
'' SIG '' eqsWGYJGWNBenYGzZ69sNfK85T8k4jWiCnUG9hhWmdR4
'' SIG '' LNEFG+vQiAGdqhDxBd+6fixjtwabIyHE+Xhs4lgXBjYr
'' SIG '' kRIDzKTZ8i26+ZSdQO0YRfHOilxrPqsD03AYKgpq4F9H
'' SIG '' 0dVjCjLyr9c2HypwWuVCWQhxS1e6foOB8CE89BzBxbmQ
'' SIG '' kw6IRZOG6bEgmb6Yy8WVpF1i1qBjCCC9dRB3fT3zRbmf
'' SIG '' l5/LV4BvM6kEz3ekYhxZfjGCGdQwghnQAgEBMIGcMIGE
'' SIG '' MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
'' SIG '' bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
'' SIG '' cm9zb2Z0IENvcnBvcmF0aW9uMS4wLAYDVQQDEyVNaWNy
'' SIG '' b3NvZnQgV2luZG93cyBQcm9kdWN0aW9uIFBDQSAyMDEx
'' SIG '' AhMzAAADO2VfrvrbdenWAAAAAAM7MA0GCWCGSAFlAwQC
'' SIG '' AQUAoIIBBDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
'' SIG '' BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAv
'' SIG '' BgkqhkiG9w0BCQQxIgQgmJ1ozAbGrtPI5shQ1lBLDn6F
'' SIG '' 0Z3t7d+VVfkHsjGITbkwPAYKKwYBBAGCNwoDHDEuDCxs
'' SIG '' TURlR3RmbS96K3NCOGdWcWxvYk53NTQ1YnFZRFlxNXF3
'' SIG '' SEVKY09LeEx3PTBaBgorBgEEAYI3AgEMMUwwSqAkgCIA
'' SIG '' TQBpAGMAcgBvAHMAbwBmAHQAIABXAGkAbgBkAG8AdwBz
'' SIG '' oSKAIGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS93aW5k
'' SIG '' b3dzMA0GCSqGSIb3DQEBAQUABIIBAEoJVkCdfUBtWFG4
'' SIG '' Y+2wnVYNN2GoAeU/LNlgIcgLLRUJMsFcyxUSlI/0zB+y
'' SIG '' 3Xmat0KLb3AAlGjWsZ5UBVvldBYbp9fWoQIp/MHI5bM9
'' SIG '' U0U6KZDZ8QNa7m+D4mlxnGEa7advyOC5RI/IaFHDxco7
'' SIG '' 7edEho3RHEqibz3hf9gmjVVZrRm9Qjk0+kalQMqITPw0
'' SIG '' /XhBROIfNHa9YJQ71itySTJYmZyBQgPhlcz9D2gQolgN
'' SIG '' Dm+0TpD6j+TF0w16t1jCNzW/szWfjLO2Ir1NQpj78MpY
'' SIG '' IIpmN4jID4Vs2thjm0oGbUaw7nUHPQveFP8hO0WaPMme
'' SIG '' J66Jzgn6Vkn/U9SxtAyhghcAMIIW/AYKKwYBBAGCNwMD
'' SIG '' ATGCFuwwghboBgkqhkiG9w0BBwKgghbZMIIW1QIBAzEP
'' SIG '' MA0GCWCGSAFlAwQCAQUAMIIBUQYLKoZIhvcNAQkQAQSg
'' SIG '' ggFABIIBPDCCATgCAQEGCisGAQQBhFkKAwEwMTANBglg
'' SIG '' hkgBZQMEAgEFAAQgUv6wn07thHmmjFwxRzVaC8PfTLQ5
'' SIG '' 50W9P+ql1dMVmKkCBmJpvkEdwBgTMjAyMjA1MDcwMzI3
'' SIG '' NDQuOTg3WjAEgAIB9KCB0KSBzTCByjELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJp
'' SIG '' Y2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRT
'' SIG '' UyBFU046REQ4Qy1FMzM3LTJGQUUxJTAjBgNVBAMTHE1p
'' SIG '' Y3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghFXMIIH
'' SIG '' DDCCBPSgAwIBAgITMwAAAZwPpk1h0p5LKAABAAABnDAN
'' SIG '' BgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
'' SIG '' A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
'' SIG '' ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
'' SIG '' MSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
'' SIG '' Q0EgMjAxMDAeFw0yMTEyMDIxOTA1MTlaFw0yMzAyMjgx
'' SIG '' OTA1MTlaMIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
'' SIG '' V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
'' SIG '' A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYD
'' SIG '' VQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
'' SIG '' MSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpERDhDLUUz
'' SIG '' MzctMkZBRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
'' SIG '' U3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQAD
'' SIG '' ggIPADCCAgoCggIBANtSKgwZXUkWP6zrXazTaYq7bco9
'' SIG '' Q2zvU6MN4ka3GRMX2tJZOK4DxeBiQACL/n7YV/sKTslw
'' SIG '' pD0f9cPU4rCDX9sfcTWo7XPxdHLQ+WkaGbKKWATsqw69
'' SIG '' bw8hkJ/bjcp2V2A6vGsvwcqJCh07BK3JPmUtZikyy5PZ
'' SIG '' 8fyTyiKGN7hOWlaIU9oIoucUNoAHQJzLq8h20eNgHUh7
'' SIG '' eI5k+Kyq4v6810LHuA6EHyKJOZN2xTw5JSkLy0FN5Mhg
'' SIG '' /OaFrFBl3iag2Tqp4InKLt+Jbh/Jd0etnei2aDHFrmlf
'' SIG '' PmlRSv5wSNX5zAhgEyRpjmQcz1zp0QaSAefRkMm923/n
'' SIG '' gU51IbrVbAeHj569SHC9doHgsIxkh0K3lpw582+0ONXc
'' SIG '' IfIU6nkBT+qADAZ+0dT1uu/gRTBy614QAofjo258TbSX
'' SIG '' 9aOU1SHuAC+3bMoyM7jNdHEJROH+msFDBcmJRl4VKsRe
'' SIG '' I5+S69KUGeLIBhhmnmQ6drF8Ip0ZiO+vhAsD3e9AnqnY
'' SIG '' 7Hcge850I9oKvwuwpVwWnKnwwSGElMz7UvCocmoUMXk7
'' SIG '' Vn2aNti+bdH28+GQb5EMsqhOmvuZOCRpOWN33G+b3g5u
'' SIG '' nwEP0eTiY+LnWa2AuK43z/pplURJVle29K42QPkOcglB
'' SIG '' 6sjLmNpEpb9basJ72eA0Mlp1LtH3oYZGXsggTfuXAgMB
'' SIG '' AAGjggE2MIIBMjAdBgNVHQ4EFgQUu2kJZ1Ndjl2112Sy
'' SIG '' nL6jGMID+rIwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXS
'' SIG '' ZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDov
'' SIG '' L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
'' SIG '' cm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
'' SIG '' MSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcw
'' SIG '' AoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
'' SIG '' cy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
'' SIG '' UENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAT
'' SIG '' BgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQsF
'' SIG '' AAOCAgEApwAqpiMYRzNNYyz3PSbtijbeyCpUXcvIrqA4
'' SIG '' zPtMIcAk34W9u9mRDndWS+tlR3WwTpr1OgaV1wmc6YFz
'' SIG '' qK6EGWm903UEsFE7xBJMPXjfdVOPhcJB3vfvA0PX56oo
'' SIG '' bcF2OvNsOSwTB8bi/ns+Cs39Puzs+QSNQZd8iAVBCSvx
'' SIG '' NCL78dln2RGU1xyB4AKqV9vi4Y/Gfmx2FA+jF0y+YLeo
'' SIG '' b0M40nlSxL0q075t7L6iFRMNr0u8ROhzhDPLl+4ePYfU
'' SIG '' myYJoobvydel9anAEsHFlhKl+aXb2ic3yNwbsoPycZJL
'' SIG '' /vo8OVvYYxCy+/5FrQmAvoW0ZEaBiYcKkzrNWt/hX9r5
'' SIG '' KgdwL61x0ZiTZopTko6W/58UTefTbhX7Pni0MApH3Pvy
'' SIG '' t6N0IFap+/LlwFRD1zn7e6ccPTwESnuo/auCmgPznq80
'' SIG '' OATA7vufsRZPvqeX8jKtsraSNscvNQymEWlcqdXV9hYk
'' SIG '' jb4T/Qse9cUYaoXg68wFHFuslWfTdPYPLl1vqzlPMnNJ
'' SIG '' pC8KtdioDgcq+y1BaSqSm8EdNfwzT37+/JFtVc3Gs915
'' SIG '' fDqgPZDgOSzKQIV+fw3aPYt2LET3AbmKKW/r13Oy8cg3
'' SIG '' +D0D362GQBAJVv0NRI5NowgaCw6oNgWOFPrN72WSEcca
'' SIG '' /8QQiTGP2XpLiGpRDJZ6sWRpRYNdydkwggdxMIIFWaAD
'' SIG '' AgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3
'' SIG '' DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
'' SIG '' V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
'' SIG '' A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYD
'' SIG '' VQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBB
'' SIG '' dXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0z
'' SIG '' MDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYD
'' SIG '' VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
'' SIG '' MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
'' SIG '' JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
'' SIG '' QSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
'' SIG '' CgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9Kp
'' SIG '' bE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5K
'' SIG '' Wv64NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTz
'' SIG '' xXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9
'' SIG '' cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl
'' SIG '' 3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3K
'' SIG '' Ni1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3t
'' SIG '' pK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5Jas
'' SIG '' AUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ
'' SIG '' 1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHo
'' SIG '' vwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz
'' SIG '' 1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymei
'' SIG '' XtcodgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8w
'' SIG '' dJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFd
'' SIG '' Etsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94
'' SIG '' q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0w
'' SIG '' ggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGC
'' SIG '' NxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1Ud
'' SIG '' DgQWBBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAE
'' SIG '' VTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIB
'' SIG '' FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
'' SIG '' L0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYI
'' SIG '' KwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
'' SIG '' AEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8w
'' SIG '' HwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQw
'' SIG '' VgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNy
'' SIG '' b3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9v
'' SIG '' Q2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEB
'' SIG '' BE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNy
'' SIG '' b3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRf
'' SIG '' MjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIB
'' SIG '' AJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEG
'' SIG '' k5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi
'' SIG '' 7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce57
'' SIG '' 32pvvinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OO
'' SIG '' PcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECW
'' SIG '' OKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWK
'' SIG '' NsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3m
'' SIG '' Sj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSw
'' SIG '' ethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23K
'' SIG '' jgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4
'' SIG '' S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFE
'' SIG '' fnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+
'' SIG '' pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/
'' SIG '' Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7t
'' SIG '' fqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJt
'' SIG '' pQUQwXEGahC0HVUzWLOhcGbyoYICzjCCAjcCAQEwgfih
'' SIG '' gdCkgc0wgcoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
'' SIG '' YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
'' SIG '' VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNV
'' SIG '' BAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMx
'' SIG '' JjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkREOEMtRTMz
'' SIG '' Ny0yRkFFMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1T
'' SIG '' dGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQDN2Wnq
'' SIG '' 3fCz9ucStub1zQz7129TQKCBgzCBgKR+MHwxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUA
'' SIG '' AgUA5iAZ6DAiGA8yMDIyMDUwNzA2MDQyNFoYDzIwMjIw
'' SIG '' NTA4MDYwNDI0WjB3MD0GCisGAQQBhFkKBAExLzAtMAoC
'' SIG '' BQDmIBnoAgEAMAoCAQACAhQcAgH/MAcCAQACAhJHMAoC
'' SIG '' BQDmIWtoAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisG
'' SIG '' AQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAw
'' SIG '' DQYJKoZIhvcNAQEFBQADgYEAua+R2AVMP2JabVktGxGn
'' SIG '' knEDRl63mrU/6D4Dhc8DUpJBtIhUAzYiwNLDPbMTOq3d
'' SIG '' sbi0OTbYqc+hbmIISaJfGFBSCzqmE2MLWPYspOC8oBBT
'' SIG '' CzSPr4+sy8Hegi+a/LvtwhXEsMxmqkVwtqivnCV4Uwdm
'' SIG '' cyazJHgjSbvc0U6lYLIxggQNMIIECQIBATCBkzB8MQsw
'' SIG '' CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
'' SIG '' MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
'' SIG '' b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
'' SIG '' ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAZwPpk1h
'' SIG '' 0p5LKAABAAABnDANBglghkgBZQMEAgEFAKCCAUowGgYJ
'' SIG '' KoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3
'' SIG '' DQEJBDEiBCDcDfhBRthiTOkey/AAyPCZO6mYhnbzOlMa
'' SIG '' Q/9ovWSZfjCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQw
'' SIG '' gb0EIDcPRYUgjSzKOhF39d4QgbRZQgrPO7Lo/qE5GtvS
'' SIG '' eqa8MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
'' SIG '' BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
'' SIG '' HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEm
'' SIG '' MCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENB
'' SIG '' IDIwMTACEzMAAAGcD6ZNYdKeSygAAQAAAZwwIgQgAHAq
'' SIG '' EnvUlGbVLtNwco330WEFviEiDM8ExKGcA4vOrQgwDQYJ
'' SIG '' KoZIhvcNAQELBQAEggIAVvBtuMUD5DixhtD62V30QWR7
'' SIG '' vVk9qIRvzWHxO6UtwzSnHa8GCHvF+9lry/8ue8DXHkJ1
'' SIG '' JB3oaGNRuoyhxcmCeFeWagYT3HCEzCacM3SmQPJjtdpX
'' SIG '' THErLQIeRyGe4y/gwmnWKww3YiKd/YkapDM/9XkNUOaq
'' SIG '' JfUEjxvEi0uEf9dfcQqSlht7Ghf4EhGhEc+dYRy9g4i5
'' SIG '' tZbF035KrSla4DAxdWp8NbNIYd96r0AKOvvMUWSPh/qS
'' SIG '' TKrNW77yK/7OpzYm+Mw1OBhCGngJjCVL0ibXzW19sPWl
'' SIG '' oMfLM2JtxaMlPWGuoDZ59lnOHkTcbR10Kz2ZJU/dp0A7
'' SIG '' BVBEIRoiaKQP9h8nbrQpg3kKAG4tFKIEnznZBe5SGhUB
'' SIG '' x2SEf+cwHE2sfu0I1JpYVCtfIjDG+uV4NuXg/R3Mv0+4
'' SIG '' hGW/oYaKpssuE1gpeeK2sPAK57Hve3p51DRTIUSC7kyT
'' SIG '' vpW+PeixfU635M45ASLPbzQecSUKCaTzhYx4zLrbFw9G
'' SIG '' AU2ylZ/vxAzM8zTFRjFwFAOnvDAPRwZVop5J+aT94oIu
'' SIG '' V1CE4DUmFqOeHUdbboxuM3JeMOmn40Jx6srePvs0NGBF
'' SIG '' mElCOynuvct4L8wOAgtglV6NSA3E3F7Y8Lr908JNbM29
'' SIG '' x0efb+1Hu2kr33q7w5mUDrx5gsDW2IgAietK4tXjaK0=
'' SIG '' End signature block
