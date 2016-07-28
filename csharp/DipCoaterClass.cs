/*
*************************************************************
; PROJECT:   Tour1.hpr
; Project Created 31/12/2009 14:45:43 by HIDmaker
; Copyright (c) 2005 by Trace Systems, Inc.  

 File created: 15/01/2010 17:45:39
 Product Name (project description): Dip Coater
 Mfr. Name: Construmaq

 Filename: Tour1_L.cs

 Generated by HIDmaker FS ver. 1.5.0.1 [Copyright (c) 2005 by Trace Systems, Inc.]

*************************************************************
*/


using System;
using System.Collections;



/// <summary>
/// 
/// </summary>
public class TUSBDipCoater
{
    //***************************************************************
    // Project-dependent constants
    //***************************************************************
    //
    // The following constants are generated automatically from the design data
    // that was created in HIDmaker FS(R).
    // The the reason that the following lines are accessable even without creating 
    // an instance of this class is that all const fields are also static in C#



    //*****************************************************************************
    //
    // The following constants are generated automatically from the design data
    // that was created in HIDmaker(R).  These constants describe the data items
    // (variables), and the HID reports that will contain them, in a way that
    // makes it possible for this object to automatically BIND them to properties
    // and functions that are a lot easier to use in your programs than the normal
    // HID system calls.
    //
    // This HID has the following Reports, which contain the following variables:
    //
    //  InputRptA :
    //    InVarDirection  - 8 bit value
    //    InVarLSBCounter  - 8 bit value
    //    InVarMSBCounter  - 8 bit value
    // You may read these variables by first calling function ReadInputRptA to get
    // the report from the device, then accessing the properties InVarDirection etc.
    // For array variables, see the special instructions below.
    //
    //  OutputRptB :
    //    OutVarSpeed  - 8 bit value
    //    OutVarDirection  - 8 bit value
    // You may write these variables by first setting the properties InVarDirection etc.,
    // then calling function WriteOutputRptB to send the data to the device.
    // For array variables, see the special instructions below.
    //
    //
    // This class also provides methods like ReadAllInputRpts and
    // WriteAllOutputRpts to simultaneously update all reports of each time
    // with a single function call.
    //
    //*****************************************************************************

    public const string HM_PROJECT_NAME = "Dip Coater";

    // Declare as constants the information about the TYPE of device we know about
    public const int MY_VID = 0x04D8;      // Expected Vendor ID
    public const bool MATCH_MY_VID = true;  // Set true to try to match this parameter

    public const int MY_PID = 0x2000;     // Expected Product ID
    public const bool MATCH_MY_PID = true;  // Set true to try to match this parameter

    public const string MY_MFR = "Construmaq";   // Mfr string
    public const bool MATCH_MY_MFR = false;  // Set true to try to match this parameter

    public const string MY_PROD = "Dip Coater";    // Prod name string
    public const bool MATCH_MY_PROD = false;  // Set true to try to match this parameter

    public const int MY_VER = 0;            // Version number
    public const bool MATCH_MY_VER = false;  // Set true to try to match this parameter

    public const string MY_SER = "";           // Serial "number" (string)
    public const bool MATCH_MY_SER = false;  // Set true to try to match this parameter


    // Declare as constants the facts we know about all the variables
    // in this Device (which may contain more than one Interface)

    private const int NUM_OF_VARS = 5;

    private const string INVARDIRECTION_NAME = "InVarDirection";   // No spaces, please! Will become a property name!
    private const int INVARDIRECTION_USG_PG = 0x0001;
    private const int INVARDIRECTION_USG = 0x0030;
    private const int INVARDIRECTION_RPT_TYPE = 0;  // Input   (0 = Input,  1 = Output,  2 = Feature)
    private const int INVARDIRECTION_IDENTITY = 1;  // Config or Identity this var belongs to

    private const string INVARLSBCOUNTER_NAME = "InVarLSBCounter";   // No spaces, please! Will become a property name!
    private const int INVARLSBCOUNTER_USG_PG = 0x0001;
    private const int INVARLSBCOUNTER_USG = 0x0031;
    private const int INVARLSBCOUNTER_RPT_TYPE = 0;  // Input   (0 = Input,  1 = Output,  2 = Feature)
    private const int INVARLSBCOUNTER_IDENTITY = 1;  // Config or Identity this var belongs to

    private const string OUTVARSPEED_NAME = "OutVarSpeed";   // No spaces, please! Will become a property name!
    private const int OUTVARSPEED_USG_PG = 0x0001;
    private const int OUTVARSPEED_USG = 0x003E;
    private const int OUTVARSPEED_RPT_TYPE = 1;  // Input   (0 = Input,  1 = Output,  2 = Feature)
    private const int OUTVARSPEED_IDENTITY = 1;  // Config or Identity this var belongs to

    private const string INVARMSBCOUNTER_NAME = "InVarMSBCounter";   // No spaces, please! Will become a property name!
    private const int INVARMSBCOUNTER_USG_PG = 0x0001;
    private const int INVARMSBCOUNTER_USG = 0x0032;
    private const int INVARMSBCOUNTER_RPT_TYPE = 0;  // Input   (0 = Input,  1 = Output,  2 = Feature)
    private const int INVARMSBCOUNTER_IDENTITY = 1;  // Config or Identity this var belongs to

    private const string OUTVARDIRECTION_NAME = "OutVarDirection";   // No spaces, please! Will become a property name!
    private const int OUTVARDIRECTION_USG_PG = 0x0001;
    private const int OUTVARDIRECTION_USG = 0x003F;
    private const int OUTVARDIRECTION_RPT_TYPE = 1;  // Input   (0 = Input,  1 = Output,  2 = Feature)
    private const int OUTVARDIRECTION_IDENTITY = 1;  // Config or Identity this var belongs to


    //*********************************************************
    // Private declarations
    //*********************************************************
    private bool FIsStarted;
    private AxHIDagentXControl1.AxHIDagentX HIDagent;
    private int FDeviceIdentity;

    // To make it easy to loop through all the objects, we'll put them in a list
    private ArrayList FVariables;

    // Objects which encapsulate the HID variables
    private TOneHidVar FInVarDirection;
    private TOneHidVar FInVarLSBCounter;
    private TOneHidVar FOutVarSpeed;
    private TOneHidVar FInVarMSBCounter;
    private TOneHidVar FOutVarDirection;

    // Private fields needed for binding Reports
    private int FInputRptA_Index;
    private int FOutputRptB_Index;



    // Public declarations



    public TUSBDipCoater()
    {
        // 
        // Creates an object of type Ttest1, and initializes properties.
        FVariables = new ArrayList();

        FIsStarted = false;
        //FVariables = new TList;
        FDeviceIdentity = 0;   // Unbound

        // Initialize private fields needed for binding Reports
        FInputRptA_Index = -1;   // Unbound
        FOutputRptB_Index = -1;   // Unbound

        // Create the objects for the HID variables
        FInVarDirection = new TOneHidVar(INVARDIRECTION_RPT_TYPE, INVARDIRECTION_USG_PG,
           INVARDIRECTION_USG, INVARDIRECTION_IDENTITY, INVARDIRECTION_NAME);
        FVariables.Add(FInVarDirection);

        FInVarLSBCounter = new TOneHidVar(INVARLSBCOUNTER_RPT_TYPE, INVARLSBCOUNTER_USG_PG,
           INVARLSBCOUNTER_USG, INVARLSBCOUNTER_IDENTITY, INVARLSBCOUNTER_NAME);
        FVariables.Add(FInVarLSBCounter);

        FOutVarSpeed = new TOneHidVar(OUTVARSPEED_RPT_TYPE, OUTVARSPEED_USG_PG,
           OUTVARSPEED_USG, OUTVARSPEED_IDENTITY, OUTVARSPEED_NAME);
        FVariables.Add(FOutVarSpeed);

        FInVarMSBCounter = new TOneHidVar(INVARMSBCOUNTER_RPT_TYPE, INVARMSBCOUNTER_USG_PG,
           INVARMSBCOUNTER_USG, INVARMSBCOUNTER_IDENTITY, INVARMSBCOUNTER_NAME);
        FVariables.Add(FInVarMSBCounter);

        FOutVarDirection = new TOneHidVar(OUTVARDIRECTION_RPT_TYPE, OUTVARDIRECTION_USG_PG,
           OUTVARDIRECTION_USG, OUTVARDIRECTION_IDENTITY, OUTVARDIRECTION_NAME);
        FVariables.Add(FOutVarDirection);

    }  // constructor: public TUSBDipCoater()
    //---------------------------------------------------------------------------


    ~TUSBDipCoater()
    {
        // Destructor
        FVariables.Clear();
    }  // destructor: ~TUSBDipCoater()
    //---------------------------------------------------------------------------


    //*****************************************************************
    //  Public methods
    //*****************************************************************

    // Binds as many variables as it can
    public int BindVars(AxHIDagentXControl1.AxHIDagentX AHIDagent)
    {
        int Result;
        //
        FIsStarted = true;
        HIDagent = AHIDagent;
        HIDagent.SelectOpenedIntf(HIDagent.OpenedIntfCount() - 1);

        // See if the latest opened device is known to us. If not, return -1
        Result = -1;
        if (!DeviceIsMatched())
            return Result;

        // Device is known: Bind as many variables as we can,
        // then report how many are left as Result
        Result = BindAllVars();
        BindAllReports();
        return Result;
    }  // public int BindVars()
    //---------------------------------------------------------------------------

    // Re-binds as many reports and variables as it can
    public int ReBind(AxHIDagentXControl1.AxHIDagentX AHIDagent)
    {
        int Result;
        int i;
        TOneHidVar AVar;

        // Unbind all reports and vars first
        for (i = 0; i < NUM_OF_VARS; i++)
        {
            AVar = Variable(i);
            UnBindRpt(AVar);
            AVar.UnBind();
        }
        // Now we're ready to re-bind things
        Result = BindAllVars();
        BindAllReports();
        BindEvents();
        return Result;
    }  // public int ReBind()
    //---------------------------------------------------------------------------


    // Bind events between HIDagent and this intermediate object
    public void BindEvents()
    {
        // This method doesn't need to do anything for ActiveX events
    }  // public void BindEvents()
    //---------------------------------------------------------------------------


    // Shuts down HID access
    public void Shutdown()
    {
        // Do not execute Shutdown method a second time
        if (!FIsStarted)
            return;

        FIsStarted = false;
        // This method doesn't need to do anything for ActiveX events
    }  // public void Shutdown()
    //---------------------------------------------------------------------------



    // Reads an Input report 
    public bool ReadInputRptA()
    {
        bool Result;
        int i;
        int Temp;  // Delete this line if not needed in your project

        Result = false;  // In case we abort
        if (FInputRptA_Index >= 0)
        {
            HIDagent.SetCurrentRptNum(FInputRptA_Index);
            Result = HIDagent.ReadAndUnpackRpt();
            //
        }
        return Result;
    }  // public bool ReadInputRptA()  
    //---------------------------------------------------------------------------

    // Writes an Output report 
    public bool WriteOutputRptB()
    {
        bool Result;
        int i;

        Result = false;  // In case we abort
        if (FOutputRptB_Index >= 0)
        {
            //

            HIDagent.SetCurrentRptNum(FOutputRptB_Index);
            Result = HIDagent.PackAndSendRpt();
        }
        return Result;
    }  // public bool WriteOutputRptB()
    //---------------------------------------------------------------------------


    // Reads all Input and Feature reports of this HID
    public bool ReadAllReports()
    {
        bool Result;

        Result = true;
        Result = Result && ReadInputRptA();
        return Result;
    }  // public bool ReadAllReports()
    //---------------------------------------------------------------------------

    // Project dependent: Writes all Output and Feature reports of this HID
    public bool WriteAllReports()
    {
        bool Result;

        Result = true;
        Result = Result && WriteOutputRptB();
        return Result;
    }  // public bool WriteAllReports()
    //---------------------------------------------------------------------------

    public int DeviceIdentity
    {
        get { return FDeviceIdentity; }
    }  // public property int DeviceIdentity
    //---------------------------------------------------------------------------


    //*****************************************************************
    //  Private or Protected Methods
    //*****************************************************************

    // How many variables are Unbound?
    public int UnboundVarCount()
    {
        int Result;
        int i;

        // Returns the number of unbound variables IN THE CURRENT IDENTITY
        Result = NUM_OF_VARS;

        for (i = 0; i < NUM_OF_VARS; i++)
        {
            if ((Variable(i).IsBound())
              || ((Variable(i).VarIdentity != DeviceIdentity) && (Variable(i).VarIdentity != 3)))
                Result--;
        }
        return Result;
    }  // public int UnboundVarCount()
    //---------------------------------------------------------------------------


    // Returns one variable from the list
    public TOneHidVar Variable(int Index)
    {
        return (TOneHidVar)FVariables[Index];
    }  // public TOneHidVar Variable()
    //---------------------------------------------------------------------------

    //
    public int VariableCount
    {
        get
        {
            //
            int i, Last, Result;
            //
            // Returns the number of variables IN THE CURRENT IDENTITY
            Result = FVariables.Count;
            Last = Result - 1;
            for (i = 0; i <= Last; i++)
            {
                if ((Variable(i).VarIdentity != DeviceIdentity) && (Variable(i).VarIdentity != 3))
                    Result--;
            }
            return Result;
        }
    }  // public property int VariableCount
    //---------------------------------------------------------------------------


    private TOneHidVar FindVar(int AVarIndex)
    {
        int i;
        bool Found;
        TOneHidVar AVar;
        TOneHidVar Result;

        // Helper function to locate a particular variable in our FVariables list
        Result = null;
        i = 0;
        Found = false;
        do
        {
            AVar = Variable(i);
            if (AVarIndex == AVar.VarIndex)
            {
                Found = true;
                Result = AVar;
            }
            i++;
        }
        while (!Found && (i < NUM_OF_VARS));
        return Result;
    }  // private TOneHidVar FindVar()
    //---------------------------------------------------------------------------

    // Protected declarations:
    protected bool DeviceIsMatched()
    {
        bool Result;

        Result = true;

        if (Result && MATCH_MY_VID)
        {
            Result = (MY_VID == HIDagent.CurrentIntf_VID());
        }

        if (Result && MATCH_MY_PID)
        {
            Result = (MY_PID == HIDagent.CurrentIntf_PID());
        }

        if (Result && MATCH_MY_MFR)
        {
            Result = (MY_MFR == HIDagent.CurrentIntf_Mfr());
        }

        if (Result && MATCH_MY_PROD)
        {
            Result = (MY_PROD == HIDagent.CurrentIntf_Prod());
        }

        if (Result && MATCH_MY_VER)
        {
            Result = (MY_VER == HIDagent.CurrentIntf_Version());
        }

        if (Result && MATCH_MY_SER)
        {
            Result = (MY_SER == HIDagent.CurrentIntf_Serial());
        }

        return Result;
    }  // protected bool DeviceIsMatched()
    //---------------------------------------------------------------------------


    // If IsAllUnbound is True, this object can be freed
    public bool IsAllUnbound()
    {
        // See if any vars are (still) bound
        return (VariableCount == UnboundVarCount());
    }  // public bool IsAllUnbound()
    //---------------------------------------------------------------------------


    // Use HasHandle to tell this object apart among similar objects created for
    // multiple identical HID devices that may be open at the same time
    public bool HasHandle(int AHidHandle)
    {
        bool Result;
        int i, NumVars;
        TOneHidVar AVar;

        // Return True if any known variable comes from an Interface using AHidHandle
        Result = false;
        NumVars = NUM_OF_VARS;
        i = 0;
        do
        {
            AVar = Variable(i++);
            Result = (AVar.HidHandle == AHidHandle);
        }
        while (!Result && (i < NumVars));

        return Result;
    }  // public bool HasHandle()
    //---------------------------------------------------------------------------



    // Methods for doing the binding

    private int BindAllVars()
    {
        int Result;
        int i;
        TOneHidVar AVar;

        Result = NUM_OF_VARS;
        for (i = 0; i < NUM_OF_VARS; i++)
        {
            // These first few lines deal with all the simple variables
            AVar = Variable(i);
            if (AVar.IsBound())
                Result--;
            else if (AVar.Bind(HIDagent))
            {
                Result--;
                if ((FDeviceIdentity == 0) && (AVar.VarIdentity != 3))
                    FDeviceIdentity = AVar.VarIdentity;
            }


        }
        return Result;
    }  // private int BindAllVars()
    //---------------------------------------------------------------------------

    private void BindAllReports()
    {
        int RptNum;

        // Check one var in InputRptA
        RptNum = InVarDirection.RptIndex;
        if (RptNum >= 0)
            FInputRptA_Index = RptNum;


        // Check one var in OutputRptB
        RptNum = OutVarSpeed.RptIndex;
        if (RptNum >= 0)
            FOutputRptB_Index = RptNum;


    }  // private void BindAllReports()
    //---------------------------------------------------------------------------

    private void UnBindRpt(TOneHidVar AVar)
    {
        int ARptIndex;

        ARptIndex = AVar.RptIndex;
        switch (AVar.RptType)
        {
            case 0:    // Input Reports
                {
                    // Check all Input reports (if any) known to be in this device

                    if (FInputRptA_Index == ARptIndex)
                        FInputRptA_Index = -1;
                    break;
                }
            case 1:   // Output Reports
                {
                    // Check all Output reports (if any) known to be in this device
                    if (FOutputRptB_Index == ARptIndex)
                        FOutputRptB_Index = -1;
                    break;
                }
            case 2:   // Feature Reports
                {
                    // Check all Feature reports (if any) known to be in this device
                    break;
                }
        }
    }  // private void UnBindRpt()
    //---------------------------------------------------------------------------


    //*****************************************************************
    // Properties which will be bound to HID data items in this device
    //*****************************************************************

    // Properties which will be bound to data items in this device
    public TOneHidVar InVarDirection
    {
        get { return FInVarDirection; }
        set { FInVarDirection = value; }
    }  // public property TOneHidVar InVarDirection
    //---------------------------------------------------------------------------

    public TOneHidVar InVarLSBCounter
    {
        get { return FInVarLSBCounter; }
        set { FInVarLSBCounter = value; }
    }  // public property TOneHidVar InVarLSBCounter
    //---------------------------------------------------------------------------

    public TOneHidVar OutVarSpeed
    {
        get { return FOutVarSpeed; }
        set { FOutVarSpeed = value; }
    }  // public property TOneHidVar OutVarSpeed
    //---------------------------------------------------------------------------

    public TOneHidVar InVarMSBCounter
    {
        get { return FInVarMSBCounter; }
        set { FInVarMSBCounter = value; }
    }  // public property TOneHidVar InVarMSBCounter
    //---------------------------------------------------------------------------

    public TOneHidVar OutVarDirection
    {
        get { return FOutVarDirection; }
        set { FOutVarDirection = value; }
    }  // public property TOneHidVar OutVarDirection
    //---------------------------------------------------------------------------



}  // public class TUSBDipCoater
