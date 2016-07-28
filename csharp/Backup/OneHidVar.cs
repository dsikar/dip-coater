using System;

	/// <summary>
	/// 
	/// </summary>
	public class TOneHidVar
	{
    public TOneHidVar(int MyRptType, int MyUsgPg, int MyUsg, int MyID, string MyName)
		{
			// 
      FVarIndex = -1;  // Signifies var is UNBOUND at this time
      FRptIndex = -1;
      FHidHandle = 0;
      FRptType = MyRptType;
      FUsagePage = MyUsgPg;
      FUsageID = MyUsg;
      FVarIdentity = MyID;
      FVarName = MyName;
      //
		} // constructor TOneHidVar()
    //---------------------------------------------------------------------------

    // Hid Report "Main item attribute bits"
    private bool FAbsNotRel;
    private bool FAryNotVar;
    private bool FBitsNotBuf;
    private bool FHasNullState;
    private bool FLinear;
    private bool FNoWrap;
    private bool FNoPrefState;
    private bool FVolatile;
    private bool FIsButton;

    // Stuff we need for variable binding
    private AxHIDagentXControl1.AxHIDagentX MyAgent;
    private int FVarIndex;
    private int FRptType;
    private int FUsagePage;
    private int FUsageID;
    private int FHidHandle;  // Windows handle to Interface containing this var
    private int FRptIndex;
    private int FTag;
    private string FVarName;

    // Other attributes
    private int FLogMax;
    private int FLogMin;
    private int FPhysMax;
    private int FPhysMin;
    private int FSizeInBits;
    //private int FUnitsCode;
    //private int FUnitExp;
    private string FStringDescriptor;
    private int FVarIdentity;

    public int ScaledValue
    {
      get
      {
        if (IsBound() )
          return MyAgent.GetScaledValue(FVarIndex);
        else
          return 0;
      }
      set
      {
        if ( IsBound() )
          MyAgent.SetScaledValue(FVarIndex, value);
      }
    }  // public property: int ScaledValue 
    //---------------------------------------------------------------------------


    public bool Bind(AxHIDagentXControl1.AxHIDagentX AHIDagent)
    {
      bool Result;
      //BSTR TempVarName;
      //wchar_t buffer[200] = {L""};

      Result = false;
      MyAgent = AHIDagent;
      FVarIndex = MyAgent.FindAVar(FUsagePage, FUsageID, FRptType, false);
      // If variable was found, then finish the binding process
      if (FVarIndex >= 0)   
      {
        MyAgent.SetCurrentVarNum(FVarIndex);
        FHidHandle = MyAgent.CurrentIntf_Handle();
        FRptIndex = MyAgent.FindRptIndex(FVarIndex);

        // Read all the attributes of this variable
        FAbsNotRel = MyAgent.CurrentVar_AbsNotRel();
        FAryNotVar = MyAgent.CurrentVar_ArrayNotVar();
        FBitsNotBuf = MyAgent.CurrentVar_BitsNotBuf();
        FHasNullState = MyAgent.CurrentVar_HasNullState();
        FIsButton = MyAgent.IsButton(FVarIndex);
        FLinear = MyAgent.CurrentVar_Linear();
        FLogMax = MyAgent.CurrentVar_LogMax();
        FLogMin = MyAgent.CurrentVar_LogMin();
        FNoPrefState = MyAgent.CurrentVar_NoPrefState();
        FNoWrap = MyAgent.CurrentVar_NoWrap();
        FPhysMax = MyAgent.CurrentVar_PhysMax();
        FPhysMin = MyAgent.CurrentVar_PhysMin();
        FSizeInBits = MyAgent.CurrentVar_SizeInBits();
        FStringDescriptor = MyAgent.CurrentVar_StrDescr();
        FVolatile = MyAgent.CurrentVar_Volatile();

        MyAgent.SetVarName(FVarIndex, FVarName );
        //FVarName.WideChar(buffer, FVarName.Length() );
        //MyAgent->SetVarName(FVarIndex, buffer );

        // By default, set ScaleMode to read unscaled values only
        MyAgent.SetCurrentVar_ScaleMode(1);

        Result = true;
      }
      return Result;
    }  // public function: bool Bind()
    //---------------------------------------------------------------------------


    public bool BoolValue
    {
      get
      {
        if ( IsBound() )
          return MyAgent.GetButton(FVarIndex);
        else
          return false;
      }
      set
      {
        if ( IsBound() )
          MyAgent.SetButton(FVarIndex, value);
      }
    } // public property: bool BoolValue
    //---------------------------------------------------------------------------


    public bool IsButton
    {
      get
      {
        return FIsButton;
      }
    }  // public property: bool IsButton
    //---------------------------------------------------------------------------


    public bool AbsoluteNotRelative
    {
      get
      {
        return FAbsNotRel;
      }
    }
    //---------------------------------------------------------------------------


    public bool ArrayNotVariable
    {
      get
      {
        return FAryNotVar;
      }
    }  // public property: bool ArrayNotVariable
    //---------------------------------------------------------------------------


    public bool BitsNotBuffer
    {
      get
      {
        return FBitsNotBuf;
      }
    }  // public property: bool BitsNotBuffer
    //---------------------------------------------------------------------------


    public bool HasNullState
    {
      get
      {
        return FHasNullState;
      }
    }  // public property: bool HasNullState
    //---------------------------------------------------------------------------


    public bool Linear
    {
      get
      {
        return FLinear;
      }
    }  // public property: bool Linear
    //---------------------------------------------------------------------------


    public bool NoPrefState
    {
      get
      {
        return FNoPrefState;
      }
    }  // public property: bool NoPrefState
    //---------------------------------------------------------------------------


    public bool NoWrap
    {
      get
      {
        return FNoWrap;
      }
    }  // public property: bool NoWrap
    //---------------------------------------------------------------------------


    public bool Volatile
    {
      get
      {
        return FVolatile;
      }
    }  // public property: bool Volatile
    //---------------------------------------------------------------------------


    public int SizeInBits
    {
      get
      {
        return FSizeInBits;
      }
    }  // public property: int SizeInBits
    //---------------------------------------------------------------------------


    public int UnScaledValue
    {
      get
      {
        if ( IsBound() )
          return MyAgent.GetUnscaledValue(FVarIndex);
        else
          return 0;
      }
      set
      {
        if ( IsBound() )
          MyAgent.SetUnscaledValue(FVarIndex, value);
      }
    }  // public property: int UnScaledValue
    //---------------------------------------------------------------------------


    public int Tag
    {
      get
      {
        return FTag;
      }
      set
      {
        FTag = value;
      }
    }  // public property: int Tag
    //---------------------------------------------------------------------------


    public int LogicalMaximum
    {
      get
      {
        return FLogMax;
      }
    }
    //---------------------------------------------------------------------------


    public int LogicalMinimum
    {
      get
      {
        return FLogMin;
      }
    }  // public property: int LogicalMinimum
    //---------------------------------------------------------------------------


    public int PhysicalMaximum
    {
      get
      {
        return FPhysMax;
      }
    }  // public property: int PhysicalMaximum
    //---------------------------------------------------------------------------


    public int PhysicalMinimum
    {
      get
      {
        return FPhysMin;
      }
    }  // public property: int PhysicalMinimum
    //---------------------------------------------------------------------------


    public int HidHandle
    {
      get
      {
        return FHidHandle;
      }
    }  // public property: int HidHandle
    //---------------------------------------------------------------------------


    public int UsagePage
    {
      get
      {
        return FUsagePage;
      }
    }  // public property: int UsagePage
    //---------------------------------------------------------------------------


    public int Usage
    {
      get
      {
        return FUsageID;
      }
    }  // public property: int Usage
    //---------------------------------------------------------------------------


    public int RptType
    {
      get
      {
        return FRptType;
      }
    }  // public property: int RptType
    //---------------------------------------------------------------------------


    public int VarIndex
    {
      get
      {
        return FVarIndex;
      }
    }  // public property: int VarIndex
    //---------------------------------------------------------------------------


    public int RptIndex
    {
      get
      {
        return FRptIndex;
      }
    }  // public property: int RptIndex
    //---------------------------------------------------------------------------


    public int VarIdentity
    {
      get
      {
        return FVarIdentity;
      }
    }  // public property: int VarIdentity
    //---------------------------------------------------------------------------


    public string VarName
    {
      get
      {
        return FVarName;
      }
    }  // public property: string VarName
    //---------------------------------------------------------------------------


    public string StringDescriptor
    {
      get
      {
        return FStringDescriptor;
      }
    }  // public property: int StringDescriptor
    //---------------------------------------------------------------------------


    public int ScaleMode
    {
      get
      {
        if (IsBound() )
        {
          MyAgent.SetCurrentVarNum(FVarIndex);
          return MyAgent.GetCurrentVar_ScaleMode();
        }
        else
          return 1;
      }
      set
      {
        if ( IsBound() )
        {
          MyAgent.SetCurrentVarNum(FVarIndex);
          MyAgent.SetCurrentVar_ScaleMode(value);
        }
      }
    }  // public property: int ScaleMode
    //---------------------------------------------------------------------------


    public void UnBind()
    {
      //
      FVarIndex = -1;
      FRptIndex = -1;
      //
      FLogMax = 0;
      FLogMin = 0;
      FPhysMax = 0;
      FPhysMin = 0;
      FVarName = "";
      FStringDescriptor = "";
    }
    //---------------------------------------------------------------------------


    public bool Update(bool Input)
    {
      bool Result;

      // Reads or writes the report which contains this variable.
      // If this variable is part of a Feature report, then the Input
      // parameter tells whether to read (Input = True) or write.
      // If this variable is part of an Input or Output report,
      // argument Input is ignored.
      Result = false;  // In case we abort
      if (FRptIndex >= 0)
      {
        MyAgent.SetCurrentRptNum(FRptIndex);
        switch (FRptType)  
        {
          case 0 :   // Input
          {
            Result = MyAgent.ReadAndUnpackRpt();
            break;
          }
          case 1 :      // Output
          {
            Result = MyAgent.PackAndSendRpt();
            break;
          }
          case 2 :      // Feature
          {
            if (Input)
              Result = MyAgent.ReadAndUnpackRpt();
            else
              Result = MyAgent.PackAndSendRpt();
            break;
          } 
        }    // case FRptType of
      }   // if (FRptIndex >= 0) then
      return Result;
    }  // public function: bool Update()
    //---------------------------------------------------------------------------


    public bool IsBound()
    {
      return (FVarIndex >= 0);
    }
    //---------------------------------------------------------------------------

  }  // public class TOneHidVar
