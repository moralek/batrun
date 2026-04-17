unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, Process, fgl, Windows, DateUtils, IniFiles, Menus;

const
  MAX_GUI_VARIABLES = 10;
  NEW_TAB_CAPTION = '[nueva]';
  TAB_ADD_BUTTON_SIZE = 34;
  TAB_ADD_BUTTON_MARGIN = 7;
  TAB_CLOSE_HIT_WIDTH = 56;
  TAB_MIN_CAPTION_WIDTH = 96;
  ACTION_BUTTON_BASE_COLOR = 14872565;
  ACTION_BUTTON_PRESSED_COLOR = 13942710;
  EXECUTE_BUTTON_BASE_COLOR = 14872565;
  EXECUTE_BUTTON_PRESSED_COLOR = 13942710;
  CONSOLE_FONT_SIZE = 9;

type
  TVariableItem = class
  public
    DefaultValue: string;
    DefineDefaultButton: TSpeedButton;
    HasTaggedDefault: Boolean;
    VarName: string;
    RemoveDefaultButton: TSpeedButton;
    ResetButton: TSpeedButton;
    ValueEdit: TEdit;
    NameLabel: TLabel;
  end;

  TVariableList = specialize TFPGObjectList<TVariableItem>;

  TBatchTab = class
  public
    BatchFileName: string;
    CustomName: string;
    Output: TStringList;
    Process: TProcess;
    ProcessStart: TDateTime;
    StatusText: string;
    Values: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  TBatchTabList = specialize TFPGObjectList<TBatchTab>;

  { TMainForm }

  TMainForm = class(TForm)
    btnClearOutput: TBitBtn;
    btnEditBatch: TPanel;
    btnExecute: TPanel;
    btnLoad: TPanel;
    EditorDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    MemoOutput: TMemo;
    miArchivo: TMenuItem;
    miCargarBat: TMenuItem;
    miCerrarPestana: TMenuItem;
    miConsola: TMenuItem;
    miConfiguracion: TMenuItem;
    miConfigurarEditor: TMenuItem;
    miDefinirValoresDefault: TMenuItem;
    miEliminarValoresDefault: TMenuItem;
    miEditarBat: TMenuItem;
    miLimpiarConsola: TMenuItem;
    miNuevaPestana: TMenuItem;
    miSalir: TMenuItem;
    miResetearValores: TMenuItem;
    miSoloPrecomentadas: TMenuItem;
    miVariables: TMenuItem;
    N1: TMenuItem;
    OpenDialog1: TOpenDialog;
    pnlExe: TPanel;
    pnlConsole: TPanel;
    pnlActions: TPanel;
    pnlRight: TPanel;
    ScrollBox1: TScrollBox;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    procedure btnEditBatchClick(Sender: TObject);
    procedure btnEditBatchMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnEditBatchMouseLeave(Sender: TObject);
    procedure btnEditBatchMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnExecuteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnExecuteMouseEnter(Sender: TObject);
    procedure btnExecuteMouseLeave(Sender: TObject);
    procedure btnExecuteMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnLoadClick(Sender: TObject);
    procedure btnLoadMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnLoadMouseLeave(Sender: TObject);
    procedure btnLoadMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnClearOutputClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure miConfigurarEditorClick(Sender: TObject);
    procedure miCerrarPestanaClick(Sender: TObject);
    procedure miDefinirValoresDefaultClick(Sender: TObject);
    procedure miEliminarValoresDefaultClick(Sender: TObject);
    procedure miNuevaPestanaClick(Sender: TObject);
    procedure miResetearValoresClick(Sender: TObject);
    procedure miSalirClick(Sender: TObject);
    procedure miSoloPrecomentadasClick(Sender: TObject);
    procedure ProcessTimerTimer(Sender: TObject);
    procedure ScrollBox1Resize(Sender: TObject);
  private
    FBatchFileName: string;
    FConfigFileName: string;
    FEditorPath: string;
    FEditPressed: Boolean;
    FExecuteIcon: TImage;
    FExecuteLabel: TLabel;
    FInitialLoadDone: Boolean;
    FLastBatchDir: string;
    FLoadPressed: Boolean;
    FOnlyPrecommentedVariables: Boolean;
    FProcessTimer: TTimer;
    FStartupDir: string;
    FActiveTabIndex: Integer;
    FEditingTabIndex: Integer;
    FEditingTabOriginalName: string;
    FLastTabClickIndex: Integer;
    FLastTabClickTime: DWORD;
    FSuppressTabChange: Boolean;
    FTabDragIndex: Integer;
    FTabDragStartPos: TPoint;
    FTabDragging: Boolean;
    FNewTabButton: TSpeedButton;
    FTabNameEdit: TEdit;
    FTabNameEditTimer: TTimer;
    FTabNameMouseDown: Boolean;
    FTabControl: TPageControl;
    FTabs: TBatchTabList;
    FExecutePressed: Boolean;
    FUpdatingVariableControls: Boolean;
    FVariables: TVariableList;
    procedure ApplyGuiValuesToBatchFile;
    procedure BringProcessWindowToFront(const APID: DWORD);
    procedure BringSelfToFront;
    procedure btnDefineDefaultClick(Sender: TObject);
    procedure btnRemoveDefaultClick(Sender: TObject);
    procedure btnResetVariableClick(Sender: TObject);
    procedure ClearVariableControls;
    function ConfigureEditor: Boolean;
    procedure CreateAppIcon;
    procedure CreateExecuteIcon;
    function ActiveBatchTab: TBatchTab;
    procedure AddBatchTab(const AFileName: string; const AActivate: Boolean);
    procedure ApplySavedVariableValues(ATab: TBatchTab);
    procedure BeginRenameBatchTab(const AIndex: Integer);
    procedure CancelRenameBatchTab;
    procedure CommitRenameBatchTab;
    function CmdQuote(const S: string): string;
    procedure DefineVariableAsDefault(AItem: TVariableItem);
    procedure EditBatchFile;
    function ExtractAssignment(const Line: string; out VarName, VarValue: string): Boolean;
    function ExtractTaggedDefault(const Line: string; out VarName, VarValue: string): Boolean;
    function FormatElapsed(const AStart, AFinish: TDateTime): string;
    procedure LayoutActionButtons;
    procedure LayoutExecuteIcon;
    procedure LayoutNewTabButton;
    procedure CreateTabControl;
    procedure DefineVisibleVariablesAsDefault;
    procedure LayoutVariableControls;
    procedure LoadDroppedBatchFile(const FileName: string);
    procedure LoadBatchVariables(const FileName: string);
    procedure LoadBatchVariablesForActiveTab(const FileName: string);
    procedure PositionExecuteButton;
    procedure LoadSettings;
    procedure LoadTabToUi(ATab: TBatchTab);
    function FindNewTabIndex: Integer;
    procedure PageControlChange(Sender: TObject);
    procedure PageControlMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PageControlMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PageControlMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NewTabButtonClick(Sender: TObject);
    procedure RefreshTabCaption(ATab: TBatchTab);
    procedure RenameBatchTab(const AIndex: Integer);
    procedure RemoveVisibleVariableDefaults;
    procedure RemoveVariableDefault(AItem: TVariableItem);
    procedure ResetVariablesToDefault;
    procedure CloseBatchTab(const AIndex: Integer);
    procedure SaveActiveTabState;
    procedure SaveSettings;
    procedure SaveVariableValues(ATab: TBatchTab);
    procedure TabNameEditExit(Sender: TObject);
    procedure TabNameEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TabNameEditTimerTimer(Sender: TObject);
    function IsOverTabCloseButton(const X, Y: Integer; out AIndex: Integer): Boolean;
    function TabIndexAt(const X, Y: Integer; const AIncludeCloseButton: Boolean): Integer;
    procedure SwapBatchTabs(const AIndex1, AIndex2: Integer);
    procedure UpdateActionButtonVisual(AButton: TPanel; APressed: Boolean);
    procedure SetStatus(const S: string);
    procedure UpdateExecuteButtonVisual;
    procedure UpdateRunState;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

type
  PFindWindowData = ^TFindWindowData;
  TFindWindowData = record
    PID: DWORD;
    Wnd: HWND;
  end;

function EnumWindowsProc(Wnd: HWND; LParam: LPARAM): BOOL; stdcall;
var
  Data: PFindWindowData;
  WinPID: DWORD;
begin
  Result := True;
  Data := PFindWindowData(LParam);
  GetWindowThreadProcessId(Wnd, @WinPID);
  if (WinPID = Data^.PID) and IsWindowVisible(Wnd) and (GetWindow(Wnd, GW_OWNER) = 0) then
  begin
    Data^.Wnd := Wnd;
    Result := False;
  end;
end;

constructor TBatchTab.Create;
begin
  inherited Create;
  BatchFileName := '';
  CustomName := '';
  Output := TStringList.Create;
  Process := nil;
  ProcessStart := 0;
  StatusText := 'Listo';
  Values := TStringList.Create;
end;

destructor TBatchTab.Destroy;
begin
  FreeAndNil(Process);
  Output.Free;
  Values.Free;
  inherited Destroy;
end;

{ TMainForm }

function TMainForm.ActiveBatchTab: TBatchTab;
begin
  Result := nil;
  if (FTabs = nil) or (FTabs.Count = 0) then
    Exit;
  if (FTabControl = nil) or (FTabControl.PageIndex < 0) or (FTabControl.PageIndex >= FTabs.Count) then
    Result := FTabs[0]
  else
    Result := FTabs[FTabControl.PageIndex];
end;

procedure TMainForm.AddBatchTab(const AFileName: string; const AActivate: Boolean);
var
  ExistingNewIndex: Integer;
  NewTab: TBatchTab;
  Sheet: TTabSheet;
begin
  ExistingNewIndex := FindNewTabIndex;
  if (AFileName = '') and (ExistingNewIndex >= 0) then
  begin
    if AActivate and (FTabControl <> nil) and (ExistingNewIndex < FTabControl.PageCount) then
    begin
      SaveActiveTabState;
      FSuppressTabChange := True;
      try
        FTabControl.PageIndex := ExistingNewIndex;
        FActiveTabIndex := ExistingNewIndex;
      finally
        FSuppressTabChange := False;
      end;
      LoadTabToUi(FTabs[ExistingNewIndex]);
    end;
    Exit;
  end;

  NewTab := TBatchTab.Create;
  NewTab.BatchFileName := AFileName;
  if AFileName <> '' then
    NewTab.StatusText := 'Listo';
  FTabs.Add(NewTab);

  Sheet := TTabSheet.Create(FTabControl);
  Sheet.PageControl := FTabControl;
  Sheet.Tag := PtrInt(NewTab);
  RefreshTabCaption(NewTab);

  if AActivate then
  begin
    SaveActiveTabState;
    FSuppressTabChange := True;
    try
      FTabControl.ActivePage := Sheet;
      FActiveTabIndex := FTabControl.PageIndex;
    finally
      FSuppressTabChange := False;
    end;
    LoadTabToUi(NewTab);
  end;
end;

procedure TMainForm.ApplySavedVariableValues(ATab: TBatchTab);
var
  Item: TVariableItem;
  I: Integer;
begin
  if ATab = nil then
    Exit;

  for Item in FVariables do
  begin
    I := ATab.Values.IndexOfName(Item.VarName);
    if I >= 0 then
      Item.ValueEdit.Text := ATab.Values.ValueFromIndex[I];
  end;
end;

procedure TMainForm.BeginRenameBatchTab(const AIndex: Integer);
var
  R: TRect;
  Tab: TBatchTab;
  EditText: string;
begin
  if (AIndex < 0) or (AIndex >= FTabs.Count) or (FTabControl = nil) then
    Exit;

  Tab := FTabs[AIndex];
  EditText := Tab.CustomName;
  if (EditText = '') and (Tab.BatchFileName <> '') then
    EditText := ChangeFileExt(ExtractFileName(Tab.BatchFileName), '')
  else if EditText = '' then
    EditText := NEW_TAB_CAPTION;

  if FTabNameEdit = nil then
  begin
    FTabNameEdit := TEdit.Create(Self);
    FTabNameEdit.Parent := FTabControl;
    FTabNameEdit.OnExit := @TabNameEditExit;
    FTabNameEdit.OnKeyDown := @TabNameEditKeyDown;
  end;

  R := FTabControl.TabRect(AIndex);
  FEditingTabIndex := AIndex;
  FEditingTabOriginalName := EditText;
  FTabNameEdit.SetBounds(R.Left + 6, R.Top + 4, (R.Right - R.Left) - 34, (R.Bottom - R.Top) - 8);
  if FTabNameEdit.Width < 80 then
    FTabNameEdit.Width := 80;
  FTabNameEdit.Text := EditText;
  FTabNameEdit.Visible := True;
  FTabNameEdit.BringToFront;
  FTabNameEdit.SetFocus;
  FTabNameEdit.SelectAll;
  FTabNameMouseDown := GetKeyState(VK_LBUTTON) < 0;
  FTabNameEditTimer.Enabled := True;
end;

procedure TMainForm.CancelRenameBatchTab;
begin
  if FTabNameEdit <> nil then
    FTabNameEdit.Visible := False;
  if FTabNameEditTimer <> nil then
    FTabNameEditTimer.Enabled := False;
  FEditingTabIndex := -1;
  FEditingTabOriginalName := '';
end;

procedure TMainForm.CommitRenameBatchTab;
var
  Tab: TBatchTab;
begin
  if (FTabNameEdit = nil) or (FEditingTabIndex < 0) or (FEditingTabIndex >= FTabs.Count) then
  begin
    CancelRenameBatchTab;
    Exit;
  end;

  Tab := FTabs[FEditingTabIndex];
  if (Trim(FTabNameEdit.Text) = '') or SameText(Trim(FTabNameEdit.Text), NEW_TAB_CAPTION) then
  begin
    MessageDlg('El nombre de la pestaña no puede estar vacío ni ser ' + NEW_TAB_CAPTION + '.', mtWarning, [mbOK], 0);
    FTabNameEdit.Text := FEditingTabOriginalName;
    FTabNameEdit.SelectAll;
    FTabNameEdit.SetFocus;
    Exit;
  end;
  Tab.CustomName := Trim(FTabNameEdit.Text);
  FTabNameEdit.Visible := False;
  if FTabNameEditTimer <> nil then
    FTabNameEditTimer.Enabled := False;
  FEditingTabIndex := -1;
  FEditingTabOriginalName := '';
  RefreshTabCaption(Tab);
end;

procedure TMainForm.CreateTabControl;
begin
  FTabControl := TPageControl.Create(Self);
  FTabControl.Parent := Self;
  FTabControl.Align := alTop;
  FTabControl.Height := 48;
  FTabControl.TabOrder := 0;
  FTabControl.OnChange := @PageControlChange;
  FTabControl.OnMouseDown := @PageControlMouseDown;
  FTabControl.OnMouseMove := @PageControlMouseMove;
  FTabControl.OnMouseUp := @PageControlMouseUp;
  FTabControl.ShowTabs := True;

  FNewTabButton := TSpeedButton.Create(Self);
  FNewTabButton.Parent := Self;
  FNewTabButton.Caption := '+';
  FNewTabButton.Cursor := crHandPoint;
  FNewTabButton.Flat := False;
  FNewTabButton.Font.Height := -24;
  FNewTabButton.Font.Style := [fsBold];
  FNewTabButton.Hint := 'Nueva pestaña';
  FNewTabButton.ShowHint := True;
  FNewTabButton.OnClick := @NewTabButtonClick;
  LayoutNewTabButton;

  miNuevaPestana := TMenuItem.Create(MainMenu1);
  miNuevaPestana.Caption := 'Nueva pestaña';
  miNuevaPestana.OnClick := @miNuevaPestanaClick;
  miArchivo.Insert(0, miNuevaPestana);

  miCerrarPestana := TMenuItem.Create(MainMenu1);
  miCerrarPestana.Caption := 'Cerrar pestaña';
  miCerrarPestana.OnClick := @miCerrarPestanaClick;
  miArchivo.Insert(1, miCerrarPestana);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FTabs := TBatchTabList.Create(True);
  FVariables := TVariableList.Create(True);
  FBatchFileName := '';
  FConfigFileName := ChangeFileExt(Application.ExeName, '.ini');
  FEditorPath := '';
  FInitialLoadDone := False;
  FLastBatchDir := '';
  FProcessTimer := TTimer.Create(Self);
  FProcessTimer.Enabled := False;
  FProcessTimer.Interval := 300;
  FProcessTimer.OnTimer := @ProcessTimerTimer;
  FStartupDir := GetCurrentDir;
  FActiveTabIndex := 0;
  FEditingTabIndex := -1;
  FLastTabClickIndex := -1;
  FLastTabClickTime := 0;
  FSuppressTabChange := False;
  FTabDragIndex := -1;
  FTabDragStartPos.X := 0;
  FTabDragStartPos.Y := 0;
  FTabDragging := False;
  FNewTabButton := nil;
  FTabNameEdit := nil;
  FTabNameEditTimer := TTimer.Create(Self);
  FTabNameEditTimer.Enabled := False;
  FTabNameEditTimer.Interval := 40;
  FTabNameEditTimer.OnTimer := @TabNameEditTimerTimer;
  FTabNameMouseDown := False;
  FExecutePressed := False;
  FUpdatingVariableControls := False;
  FOnlyPrecommentedVariables := False;
  OpenDialog1.Filter := 'Batch files|*.bat|All files|*.*';
  OpenDialog1.Options := OpenDialog1.Options + [ofFileMustExist, ofPathMustExist];
  OpenDialog1.InitialDir := FStartupDir;
  EditorDialog1.Filter := 'Aplicaciones|*.exe|Todos los archivos|*.*';
  EditorDialog1.Options := EditorDialog1.Options + [ofFileMustExist, ofPathMustExist];
  EditorDialog1.InitialDir := FStartupDir;
  MemoOutput.Font.Size := CONSOLE_FONT_SIZE;
  FEditPressed := False;
  btnExecute.Height := 60;
  btnExecute.Width := 72;
  FLoadPressed := False;
  miConfiguracion.Caption := 'Configuración';
  CreateTabControl;
  CreateAppIcon;
  CreateExecuteIcon;
  UpdateActionButtonVisual(btnLoad, False);
  UpdateActionButtonVisual(btnEditBatch, False);
  UpdateExecuteButtonVisual;
  LayoutActionButtons;
  LoadSettings;
  if FTabs.Count = 0 then
    AddBatchTab('', True);
  miSoloPrecomentadas.Checked := FOnlyPrecommentedVariables;
  PositionExecuteButton;
  SetStatus('Listo');
  UpdateRunState;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  SaveSettings;
  FProcessTimer.Enabled := False;
  FVariables.Free;
  FTabs.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if FInitialLoadDone then
    Exit;
  FInitialLoadDone := True;
  LayoutActionButtons;
  LayoutVariableControls;
  PositionExecuteButton;
  LoadTabToUi(ActiveBatchTab);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if FUpdatingVariableControls then
    Exit;
  LayoutActionButtons;
  LayoutVariableControls;
  PositionExecuteButton;
  LayoutNewTabButton;
end;

procedure TMainForm.btnLoadClick(Sender: TObject);
begin
  if (FTabNameEdit <> nil) and FTabNameEdit.Visible then
  begin
    CommitRenameBatchTab;
    if FTabNameEdit.Visible then
      Exit;
  end;

  if DirectoryExists(FLastBatchDir) then
    OpenDialog1.InitialDir := FLastBatchDir
  else
    OpenDialog1.InitialDir := FStartupDir;

  if FileExists(FBatchFileName) then
    OpenDialog1.FileName := FBatchFileName
  else
    OpenDialog1.FileName := '';

  if OpenDialog1.Execute then
    LoadBatchVariablesForActiveTab(OpenDialog1.FileName);
end;

procedure TMainForm.btnLoadMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or (not btnLoad.Enabled) then
    Exit;
  FLoadPressed := True;
  UpdateActionButtonVisual(btnLoad, True);
end;

procedure TMainForm.btnLoadMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FLoadPressed := False;
  UpdateActionButtonVisual(btnLoad, False);
end;

procedure TMainForm.btnLoadMouseLeave(Sender: TObject);
begin
  FLoadPressed := False;
  UpdateActionButtonVisual(btnLoad, False);
end;

procedure TMainForm.btnEditBatchClick(Sender: TObject);
begin
  EditBatchFile;
end;

procedure TMainForm.btnEditBatchMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or (not btnEditBatch.Enabled) then
    Exit;
  FEditPressed := True;
  UpdateActionButtonVisual(btnEditBatch, True);
end;

procedure TMainForm.btnEditBatchMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FEditPressed := False;
  UpdateActionButtonVisual(btnEditBatch, False);
end;

procedure TMainForm.btnEditBatchMouseLeave(Sender: TObject);
begin
  FEditPressed := False;
  UpdateActionButtonVisual(btnEditBatch, False);
end;

procedure TMainForm.SetStatus(const S: string);
var
  Tab: TBatchTab;
begin
  StatusBar1.SimpleText := S;
  Tab := ActiveBatchTab;
  if Tab <> nil then
    Tab.StatusText := S;
end;

procedure TMainForm.UpdateExecuteButtonVisual;
begin
  if not btnExecute.Enabled then
  begin
    btnExecute.Color := EXECUTE_BUTTON_BASE_COLOR;
    btnExecute.BevelInner := bvNone;
    btnExecute.BevelOuter := bvNone;
    Exit;
  end;

  if FExecutePressed then
  begin
    btnExecute.Color := EXECUTE_BUTTON_PRESSED_COLOR;
    btnExecute.BevelInner := bvLowered;
    btnExecute.BevelOuter := bvLowered;
  end
  else
  begin
    btnExecute.Color := EXECUTE_BUTTON_BASE_COLOR;
    btnExecute.BevelInner := bvNone;
    btnExecute.BevelOuter := bvNone;
  end;
end;

procedure TMainForm.UpdateActionButtonVisual(AButton: TPanel; APressed: Boolean);
begin
  if not AButton.Enabled then
  begin
    AButton.Color := ACTION_BUTTON_BASE_COLOR;
    AButton.BevelInner := bvNone;
    AButton.BevelOuter := bvNone;
    Exit;
  end;

  if APressed then
  begin
    AButton.Color := ACTION_BUTTON_PRESSED_COLOR;
    AButton.BevelInner := bvLowered;
    AButton.BevelOuter := bvLowered;
  end
  else
  begin
    AButton.Color := ACTION_BUTTON_BASE_COLOR;
    AButton.BevelInner := bvNone;
    AButton.BevelOuter := bvNone;
  end;
end;

procedure TMainForm.btnClearOutputClick(Sender: TObject);
var
  Tab: TBatchTab;
begin
  MemoOutput.Clear;
  Tab := ActiveBatchTab;
  if Tab <> nil then
    Tab.Output.Clear;
  SetStatus('Consola limpia');
end;

procedure TMainForm.btnExecuteClick(Sender: TObject);
var
  Proc: TProcess;
  Tab: TBatchTab;
begin
  Tab := ActiveBatchTab;
  if Tab = nil then
    Exit;

  if FBatchFileName = '' then
  begin
    MessageDlg('Debe cargar un archivo .bat.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if Assigned(Tab.Process) then
  begin
    MessageDlg('Ya hay una ejecución en curso.', mtWarning, [mbOK], 0);
    Exit;
  end;

  ApplyGuiValuesToBatchFile;

  Proc := TProcess.Create(nil);
  Proc.Executable := 'cmd.exe';
  Proc.Parameters.Add('/C');
  Proc.Parameters.Add('call ' + CmdQuote(FBatchFileName));
  Proc.CurrentDirectory := ExtractFileDir(FBatchFileName);
  Proc.Options := [poNewConsole];
  Proc.ShowWindow := swoShowNormal;
  Proc.Execute;

  Tab.Process := Proc;
  Tab.ProcessStart := Now;
  MemoOutput.Clear;
  MemoOutput.Lines.Add('Inicio: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Tab.ProcessStart));
  MemoOutput.Lines.Add('Archivo: ' + FBatchFileName);
  if FVariables.Count = 0 then
    MemoOutput.Lines.Add('Ejecución sin reemplazos desde la GUI.');
  Tab.Output.Assign(MemoOutput.Lines);
  Tab.StatusText := 'Ejecutando...';
  SetStatus(Tab.StatusText);
  UpdateRunState;
  BringProcessWindowToFront(Tab.Process.ProcessID);
  FProcessTimer.Enabled := True;
end;

procedure TMainForm.btnExecuteMouseEnter(Sender: TObject);
begin
  if not btnExecute.Enabled then
    Exit;
  btnExecute.Tag := 1;
  UpdateExecuteButtonVisual;
end;

procedure TMainForm.btnExecuteMouseLeave(Sender: TObject);
begin
  btnExecute.Tag := 0;
  FExecutePressed := False;
  UpdateExecuteButtonVisual;
end;

procedure TMainForm.btnExecuteMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or (not btnExecute.Enabled) then
    Exit;
  FExecutePressed := True;
  UpdateExecuteButtonVisual;
end;

procedure TMainForm.btnExecuteMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FExecutePressed := False;
  UpdateExecuteButtonVisual;
end;

procedure TMainForm.ProcessTimerTimer(Sender: TObject);
var
  FinishTime: TDateTime;
  I: Integer;
  RunningCount: Integer;
  Tab: TBatchTab;
begin
  RunningCount := 0;
  for I := 0 to FTabs.Count - 1 do
  begin
    Tab := FTabs[I];
    if not Assigned(Tab.Process) then
      Continue;

    if Tab.Process.Running then
    begin
      Inc(RunningCount);
      Continue;
    end;

    FinishTime := Now;
    Tab.Output.Add('Fin: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FinishTime));
    Tab.Output.Add('Duración: ' + FormatElapsed(Tab.ProcessStart, FinishTime));
    Tab.Output.Add('Finalizado. Código de salida: ' + IntToStr(Tab.Process.ExitStatus));
    FreeAndNil(Tab.Process);
    Tab.StatusText := 'Finalizado';

    if Tab = ActiveBatchTab then
    begin
      MemoOutput.Lines.Assign(Tab.Output);
      SetStatus(Tab.StatusText);
      UpdateRunState;
      BringSelfToFront;
    end;
  end;

  FProcessTimer.Enabled := RunningCount > 0;
end;

procedure TMainForm.ClearVariableControls;
var
  I: Integer;
begin
  FUpdatingVariableControls := True;
  for I := ScrollBox1.ControlCount - 1 downto 0 do
    ScrollBox1.Controls[I].Free;
  FVariables.Clear;
end;

procedure TMainForm.btnResetVariableClick(Sender: TObject);
var
  Item: TVariableItem;
begin
  Item := TVariableItem(PtrUInt((Sender as TSpeedButton).Tag));
  if Item = nil then
    Exit;
  Item.ValueEdit.Text := Item.DefaultValue;
  ApplyGuiValuesToBatchFile;
  SetStatus('Variable restablecida: ' + Item.VarName);
end;

procedure TMainForm.btnDefineDefaultClick(Sender: TObject);
var
  Item: TVariableItem;
  VarName: string;
begin
  Item := TVariableItem(PtrUInt((Sender as TSpeedButton).Tag));
  if Item = nil then
    Exit;
  VarName := Item.VarName;
  DefineVariableAsDefault(Item);
  SetStatus('Default definido: ' + VarName);
end;

procedure TMainForm.btnRemoveDefaultClick(Sender: TObject);
var
  Item: TVariableItem;
  VarName: string;
begin
  Item := TVariableItem(PtrUInt((Sender as TSpeedButton).Tag));
  if Item = nil then
    Exit;
  VarName := Item.VarName;
  RemoveVariableDefault(Item);
  SetStatus('Default eliminado: ' + VarName);
end;

function TMainForm.ConfigureEditor: Boolean;
begin
  if FileExists(FEditorPath) then
  begin
    EditorDialog1.InitialDir := ExtractFileDir(FEditorPath);
    EditorDialog1.FileName := FEditorPath
  end
  else
  begin
    EditorDialog1.InitialDir := FStartupDir;
    EditorDialog1.FileName := '';
  end;

  if EditorDialog1.Execute then
  begin
    FEditorPath := EditorDialog1.FileName;
    SetStatus('Editor configurado');
    Result := True;
  end
  else
    Result := False;
end;

procedure TMainForm.CreateAppIcon;
var
  Bmp: Graphics.TBitmap;
  Png: TPortableNetworkGraphic;
  P: array[0..19] of TPoint;
  IconFileName: string;
  DestRect: TRect;
begin
  IconFileName := ExtractFilePath(Application.ExeName) + 'bat.png';
  if not FileExists(IconFileName) then
    IconFileName := ExpandFileName(ExtractFilePath(Application.ExeName) + '..\bat.png');

  if FileExists(IconFileName) then
  begin
    Bmp := Graphics.TBitmap.Create;
    Png := TPortableNetworkGraphic.Create;
    try
      Png.LoadFromFile(IconFileName);
      Bmp.SetSize(64, 64);
      DestRect.Left := 0;
      DestRect.Top := 0;
      DestRect.Right := 64;
      DestRect.Bottom := 64;
      Bmp.Canvas.StretchDraw(DestRect, Png);
      Icon.Assign(Bmp);
      Application.Icon.Assign(Icon);
    finally
      Png.Free;
      Bmp.Free;
    end;
    Exit;
  end;

  Bmp := Graphics.TBitmap.Create;
  try
    Bmp.SetSize(64, 64);
    Bmp.Canvas.Brush.Color := RGBToColor(219, 205, 179);
    Bmp.Canvas.FillRect(0, 0, 64, 64);

    Bmp.Canvas.Pen.Style := psSolid;
    Bmp.Canvas.Pen.Color := RGBToColor(25, 28, 33);
    Bmp.Canvas.Pen.Width := 2;
    Bmp.Canvas.Brush.Color := RGBToColor(48, 49, 51);
    P[0].X := 2;  P[0].Y := 24;
    P[1].X := 7;  P[1].Y := 20;
    P[2].X := 14; P[2].Y := 17;
    P[3].X := 20; P[3].Y := 18;
    P[4].X := 23; P[4].Y := 27;
    P[5].X := 26; P[5].Y := 33;
    P[6].X := 29; P[6].Y := 36;
    P[7].X := 29; P[7].Y := 31;
    P[8].X := 32; P[8].Y := 33;
    P[9].X := 35; P[9].Y := 31;
    P[10].X := 35; P[10].Y := 36;
    P[11].X := 38; P[11].Y := 33;
    P[12].X := 41; P[12].Y := 27;
    P[13].X := 44; P[13].Y := 18;
    P[14].X := 50; P[14].Y := 17;
    P[15].X := 57; P[15].Y := 20;
    P[16].X := 62; P[16].Y := 24;
    P[17].X := 56; P[17].Y := 24;
    P[18].X := 56; P[18].Y := 32;
    P[19].X := 48; P[19].Y := 32;
    Bmp.Canvas.Polygon(P);

    Bmp.Canvas.Brush.Color := RGBToColor(219, 205, 179);
    Bmp.Canvas.Pen.Color := RGBToColor(219, 205, 179);
    Bmp.Canvas.Ellipse(12, 31, 28, 43);
    Bmp.Canvas.Ellipse(24, 33, 40, 49);
    Bmp.Canvas.Ellipse(36, 31, 52, 43);

    Bmp.Canvas.Brush.Color := RGBToColor(143, 255, 186);
    Bmp.Canvas.Pen.Color := RGBToColor(143, 255, 186);
    Bmp.Canvas.Ellipse(29, 24, 33, 29);
    Bmp.Canvas.Ellipse(35, 24, 39, 29);

    Icon.Assign(Bmp);
    Application.Icon.Assign(Icon);
  finally
    Bmp.Free;
  end;
end;

procedure TMainForm.CreateExecuteIcon;
begin
  if Assigned(FExecuteLabel) then
    FreeAndNil(FExecuteLabel);

  if Assigned(FExecuteIcon) then
    FreeAndNil(FExecuteIcon);

  FExecuteIcon := TImage.Create(btnExecute);
  FExecuteIcon.Parent := btnExecute;
  FExecuteIcon.Center := True;
  FExecuteIcon.Stretch := True;
  FExecuteIcon.Proportional := True;
  FExecuteIcon.Transparent := True;
  FExecuteIcon.Cursor := crHandPoint;
  FExecuteIcon.Hint := 'Ejecutar';
  FExecuteIcon.ShowHint := True;
  FExecuteIcon.OnClick := @btnExecuteClick;
  FExecuteIcon.OnMouseEnter := @btnExecuteMouseEnter;
  FExecuteIcon.OnMouseLeave := @btnExecuteMouseLeave;
  FExecuteIcon.OnMouseDown := @btnExecuteMouseDown;
  FExecuteIcon.OnMouseUp := @btnExecuteMouseUp;
  FExecuteIcon.Picture.Assign(Icon);

  FExecuteLabel := TLabel.Create(btnExecute);
  FExecuteLabel.Parent := btnExecute;
  FExecuteLabel.Caption := 'RUN!';
  FExecuteLabel.Font.Assign(btnExecute.Font);
  FExecuteLabel.Font.Style := [fsBold];
  FExecuteLabel.Font.Color := btnExecute.Font.Color;
  FExecuteLabel.Transparent := True;
  FExecuteLabel.Cursor := crHandPoint;
  FExecuteLabel.OnClick := @btnExecuteClick;
  FExecuteLabel.OnMouseEnter := @btnExecuteMouseEnter;
  FExecuteLabel.OnMouseLeave := @btnExecuteMouseLeave;
  FExecuteLabel.OnMouseDown := @btnExecuteMouseDown;
  FExecuteLabel.OnMouseUp := @btnExecuteMouseUp;

  LayoutExecuteIcon;
end;

procedure TMainForm.LayoutExecuteIcon;
var
  IconSize: Integer;
  Gap: Integer;
  TextWidth: Integer;
  TextHeight: Integer;
  ContentWidth: Integer;
  StartLeft: Integer;
begin
  if (not Assigned(FExecuteIcon)) or (not Assigned(FExecuteLabel)) then
    Exit;

  if btnExecute.ClientWidth < btnExecute.ClientHeight then
    IconSize := btnExecute.ClientWidth div 2
  else
    IconSize := btnExecute.ClientHeight div 2;

  if IconSize < 24 then
    IconSize := 24;
  if IconSize > 56 then
    IconSize := 56;

  btnExecute.Canvas.Font.Assign(FExecuteLabel.Font);
  TextWidth := btnExecute.Canvas.TextWidth(FExecuteLabel.Caption);
  TextHeight := btnExecute.Canvas.TextHeight(FExecuteLabel.Caption);
  Gap := 10;
  if TextWidth > 0 then
    ContentWidth := IconSize + Gap + TextWidth
  else
    ContentWidth := IconSize;

  StartLeft := (btnExecute.ClientWidth - ContentWidth) div 2;
  if StartLeft < 8 then
    StartLeft := 8;

  FExecuteIcon.Width := IconSize;
  FExecuteIcon.Height := IconSize;
  FExecuteIcon.Left := StartLeft;
  FExecuteIcon.Top := (btnExecute.ClientHeight - FExecuteIcon.Height) div 2;

  FExecuteLabel.Left := FExecuteIcon.Left + FExecuteIcon.Width + Gap;
  FExecuteLabel.Top := (btnExecute.ClientHeight - TextHeight) div 2;
  FExecuteLabel.BringToFront;
end;

procedure TMainForm.ApplyGuiValuesToBatchFile;
var
  I: Integer;
  Item: TVariableItem;
  Lines: TStringList;
  VarName: string;
  VarValue: string;
  TaggedName: string;
  TaggedValue: string;
begin
  Lines := TStringList.Create;
  try
    if FVariables.Count = 0 then
      Exit;

    Lines.LoadFromFile(FBatchFileName);
    for I := 1 to Lines.Count - 1 do
    begin
      if not ExtractAssignment(Lines[I], VarName, VarValue) then
        Continue;
      if FOnlyPrecommentedVariables then
      begin
        if not ExtractTaggedDefault(Lines[I - 1], TaggedName, TaggedValue) then
          Continue;
        if not SameText(TaggedName, VarName) then
          Continue;
      end;

      for Item in FVariables do
        if SameText(Item.VarName, VarName) then
        begin
          Lines[I] := 'set ' + Item.VarName + '=' + Item.ValueEdit.Text;
          Break;
        end;
    end;

    Lines.SaveToFile(FBatchFileName);
  finally
    Lines.Free;
  end;
end;

procedure TMainForm.BringProcessWindowToFront(const APID: DWORD);
var
  Data: TFindWindowData;
  ProcHandle: THandle;
begin
  Data.PID := APID;
  Data.Wnd := 0;
  ProcHandle := OpenProcess(SYNCHRONIZE or PROCESS_QUERY_INFORMATION, False, APID);
  if ProcHandle <> 0 then
  try
    WaitForInputIdle(ProcHandle, 1500);
  finally
    CloseHandle(ProcHandle);
  end;
  EnumWindows(@EnumWindowsProc, LPARAM(@Data));
  if Data.Wnd <> 0 then
  begin
    ShowWindow(Data.Wnd, SW_SHOWNORMAL);
    SetForegroundWindow(Data.Wnd);
    BringWindowToTop(Data.Wnd);
  end;
end;

procedure TMainForm.BringSelfToFront;
begin
  if WindowState = wsMinimized then
    WindowState := wsNormal;
  Show;
  BringToFront;
  SetForegroundWindow(Handle);
end;

function TMainForm.CmdQuote(const S: string): string;
begin
  Result := '"' + StringReplace(S, '"', '\"', [rfReplaceAll]) + '"';
end;

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
begin
  if Length(FileNames) > 0 then
    LoadDroppedBatchFile(FileNames[0]);
end;

procedure TMainForm.miSoloPrecomentadasClick(Sender: TObject);
begin
  FOnlyPrecommentedVariables := not FOnlyPrecommentedVariables;
  miSoloPrecomentadas.Checked := FOnlyPrecommentedVariables;
  LoadTabToUi(ActiveBatchTab);
end;

procedure TMainForm.EditBatchFile;
var
  Proc: TProcess;
begin
  if FBatchFileName = '' then
  begin
    MessageDlg('Debe cargar un archivo .bat.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if (FEditorPath = '') or (not FileExists(FEditorPath)) then
  begin
    MessageDlg('Primero configura el editor para abrir el .bat.', mtInformation, [mbOK], 0);
    if not ConfigureEditor then
      Exit;
  end;

  Proc := TProcess.Create(nil);
  try
    Proc.Executable := FEditorPath;
    Proc.Parameters.Add(FBatchFileName);
    Proc.Options := [];
    Proc.Execute;
    SetStatus('Abierto en editor');
  finally
    Proc.Free;
  end;
end;

procedure TMainForm.LoadDroppedBatchFile(const FileName: string);
begin
  if not FileExists(FileName) then
    Exit;

  if not SameText(ExtractFileExt(FileName), '.bat') then
  begin
    MessageDlg('Solo puede arrastrar archivos .bat.', mtWarning, [mbOK], 0);
    Exit;
  end;

  LoadBatchVariablesForActiveTab(FileName);
end;

procedure TMainForm.LoadBatchVariablesForActiveTab(const FileName: string);
var
  Tab: TBatchTab;
begin
  Tab := ActiveBatchTab;
  if Tab = nil then
  begin
    AddBatchTab(FileName, True);
    Tab := ActiveBatchTab;
  end;
  if Tab = nil then
    Exit;

  Tab.BatchFileName := FileName;
  Tab.Values.Clear;
  LoadBatchVariables(FileName);
  Tab.Output.Assign(MemoOutput.Lines);
  Tab.StatusText := StatusBar1.SimpleText;
  RefreshTabCaption(Tab);
end;

function TMainForm.FormatElapsed(const AStart, AFinish: TDateTime): string;
var
  TotalSeconds: Int64;
  Hours: Int64;
  Minutes: Int64;
  Seconds: Int64;
begin
  TotalSeconds := SecondsBetween(AFinish, AStart);
  Hours := TotalSeconds div 3600;
  Minutes := (TotalSeconds mod 3600) div 60;
  Seconds := TotalSeconds mod 60;
  Result := Format('%.2d:%.2d:%.2d', [Hours, Minutes, Seconds]);
end;

procedure TMainForm.LayoutActionButtons;
var
  Margin: Integer;
  Gap: Integer;
  AvailableWidth: Integer;
  ButtonWidth: Integer;
begin
  Margin := 16;
  Gap := 16;
  AvailableWidth := pnlActions.ClientWidth - (Margin * 2) - Gap;
  if AvailableWidth < 200 then
    AvailableWidth := 200;

  ButtonWidth := AvailableWidth div 2;
  if ButtonWidth < 96 then
    ButtonWidth := 96;

  btnLoad.Left := Margin;
  btnLoad.Top := 16;
  btnLoad.Width := ButtonWidth;

  btnEditBatch.Left := btnLoad.Left + btnLoad.Width + Gap;
  btnEditBatch.Top := btnLoad.Top;
  btnEditBatch.Width := ButtonWidth;
end;

procedure TMainForm.LayoutNewTabButton;
begin
  if (FTabControl = nil) or (FNewTabButton = nil) then
    Exit;

  FNewTabButton.SetBounds(
    ClientWidth - TAB_ADD_BUTTON_SIZE - TAB_ADD_BUTTON_MARGIN,
    FTabControl.Top + TAB_ADD_BUTTON_MARGIN,
    TAB_ADD_BUTTON_SIZE,
    TAB_ADD_BUTTON_SIZE
  );
  FNewTabButton.BringToFront;
end;

procedure TMainForm.DefineVariableAsDefault(AItem: TVariableItem);
var
  Lines: TStringList;
  I: Integer;
  ExistingTagName: string;
  ExistingTagValue: string;
  VarName: string;
  VarValue: string;
begin
  if (AItem = nil) or (FBatchFileName = '') or (not FileExists(FBatchFileName)) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FBatchFileName);
    for I := 0 to Lines.Count - 1 do
    begin
      if not ExtractAssignment(Lines[I], VarName, VarValue) then
        Continue;
      if not SameText(VarName, AItem.VarName) then
        Continue;

      Lines[I] := 'set ' + AItem.VarName + '=' + AItem.ValueEdit.Text;
      if (I > 0)
        and ExtractTaggedDefault(Lines[I - 1], ExistingTagName, ExistingTagValue)
        and SameText(ExistingTagName, AItem.VarName) then
        Lines[I - 1] := '::' + AItem.VarName + '=' + AItem.ValueEdit.Text
      else
        Lines.Insert(I, '::' + AItem.VarName + '=' + AItem.ValueEdit.Text);
      Break;
    end;
    Lines.SaveToFile(FBatchFileName);
  finally
    Lines.Free;
  end;

  LoadBatchVariables(FBatchFileName);
end;

procedure TMainForm.RemoveVariableDefault(AItem: TVariableItem);
var
  Lines: TStringList;
  I: Integer;
  ExistingTagName: string;
  ExistingTagValue: string;
  VarName: string;
  VarValue: string;
begin
  if (AItem = nil) or (FBatchFileName = '') or (not FileExists(FBatchFileName)) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FBatchFileName);
    for I := 0 to Lines.Count - 1 do
    begin
      if not ExtractAssignment(Lines[I], VarName, VarValue) then
        Continue;
      if not SameText(VarName, AItem.VarName) then
        Continue;

      if (I > 0)
        and ExtractTaggedDefault(Lines[I - 1], ExistingTagName, ExistingTagValue)
        and SameText(ExistingTagName, AItem.VarName) then
        Lines.Delete(I - 1);
      Break;
    end;
    Lines.SaveToFile(FBatchFileName);
  finally
    Lines.Free;
  end;

  LoadBatchVariables(FBatchFileName);
end;

procedure TMainForm.RemoveVisibleVariableDefaults;
var
  Lines: TStringList;
  Item: TVariableItem;
  I: Integer;
  ExistingTagName: string;
  ExistingTagValue: string;
  VarName: string;
  VarValue: string;
begin
  if (FBatchFileName = '') or (not FileExists(FBatchFileName)) or (FVariables.Count = 0) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FBatchFileName);

    for Item in FVariables do
      for I := 0 to Lines.Count - 1 do
      begin
        if not ExtractAssignment(Lines[I], VarName, VarValue) then
          Continue;
        if not SameText(VarName, Item.VarName) then
          Continue;

        if (I > 0)
          and ExtractTaggedDefault(Lines[I - 1], ExistingTagName, ExistingTagValue)
          and SameText(ExistingTagName, Item.VarName) then
            Lines.Delete(I - 1);
        Break;
      end;

    Lines.SaveToFile(FBatchFileName);
  finally
    Lines.Free;
  end;

  LoadBatchVariables(FBatchFileName);
end;

procedure TMainForm.DefineVisibleVariablesAsDefault;
var
  Lines: TStringList;
  Item: TVariableItem;
  I: Integer;
  ExistingTagName: string;
  ExistingTagValue: string;
  VarName: string;
  VarValue: string;
begin
  if (FBatchFileName = '') or (not FileExists(FBatchFileName)) or (FVariables.Count = 0) then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FBatchFileName);

    for Item in FVariables do
      for I := 0 to Lines.Count - 1 do
      begin
        if not ExtractAssignment(Lines[I], VarName, VarValue) then
          Continue;
        if not SameText(VarName, Item.VarName) then
          Continue;

        Lines[I] := 'set ' + Item.VarName + '=' + Item.ValueEdit.Text;
        if (I > 0)
          and ExtractTaggedDefault(Lines[I - 1], ExistingTagName, ExistingTagValue)
          and SameText(ExistingTagName, Item.VarName) then
          Lines[I - 1] := '::' + Item.VarName + '=' + Item.ValueEdit.Text
        else
          Lines.Insert(I, '::' + Item.VarName + '=' + Item.ValueEdit.Text);
        Break;
      end;

    Lines.SaveToFile(FBatchFileName);
  finally
    Lines.Free;
  end;

  LoadBatchVariables(FBatchFileName);
end;

function TMainForm.ExtractAssignment(const Line: string; out VarName, VarValue: string): Boolean;
var
  S: string;
  P: SizeInt;
begin
  Result := False;
  VarName := '';
  VarValue := '';

  S := TrimLeft(Line);
  if CompareText(Copy(S, 1, 4), 'set ') <> 0 then
    Exit;

  Delete(S, 1, 4);
  S := TrimLeft(S);
  if S = '' then
    Exit;

  if (Length(S) >= 2) and (S[1] = '/') then
    Exit;

  if (Length(S) >= 2) and (S[1] = '"') and (S[Length(S)] = '"') then
  begin
    Delete(S, Length(S), 1);
    Delete(S, 1, 1);
  end;

  P := Pos('=', S);
  if P <= 1 then
    Exit;

  VarName := Trim(Copy(S, 1, P - 1));
  VarValue := Copy(S, P + 1, MaxInt);
  if (VarName <> '') and (VarName[1] = '"') and (VarName[Length(VarName)] = '"') then
    VarName := Copy(VarName, 2, Length(VarName) - 2);
  Result := VarName <> '';
end;

function TMainForm.ExtractTaggedDefault(const Line: string; out VarName,
  VarValue: string): Boolean;
var
  S: string;
  P: SizeInt;
begin
  Result := False;
  VarName := '';
  VarValue := '';

  S := Trim(Line);
  if Copy(S, 1, 2) <> '::' then
    Exit;

  Delete(S, 1, 2);
  S := TrimLeft(S);
  P := Pos('=', S);
  if P <= 1 then
    Exit;

  VarName := Trim(Copy(S, 1, P - 1));
  VarValue := Copy(S, P + 1, MaxInt);
  Result := VarName <> '';
end;

procedure TMainForm.LoadTabToUi(ATab: TBatchTab);
begin
  if ATab = nil then
  begin
    FBatchFileName := '';
    Caption := 'Batch Runner';
    ClearVariableControls;
    MemoOutput.Clear;
    SetStatus('Listo');
    UpdateRunState;
    Exit;
  end;

  FBatchFileName := ATab.BatchFileName;
  MemoOutput.Lines.Assign(ATab.Output);
  if FileExists(ATab.BatchFileName) then
  begin
    LoadBatchVariables(ATab.BatchFileName);
    ApplySavedVariableValues(ATab);
  end
  else
  begin
    ClearVariableControls;
    Caption := 'Batch Runner';
  end;

  if ATab.StatusText <> '' then
    SetStatus(ATab.StatusText)
  else
    SetStatus('Listo');
  UpdateRunState;
end;

procedure TMainForm.PageControlChange(Sender: TObject);
begin
  if FSuppressTabChange then
    Exit;
  SaveActiveTabState;
  LoadTabToUi(ActiveBatchTab);
  if FTabControl <> nil then
    FActiveTabIndex := FTabControl.PageIndex;
end;

function TMainForm.FindNewTabIndex: Integer;
var
  I: Integer;
begin
  Result := -1;
  if FTabs = nil then
    Exit;

  for I := 0 to FTabs.Count - 1 do
    if (FTabs[I].BatchFileName = '') and (FTabs[I].CustomName = '') then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TMainForm.RefreshTabCaption(ATab: TBatchTab);
var
  I: Integer;
  CaptionText: string;
begin
  if ATab = nil then
    Exit;
  if ATab.CustomName <> '' then
    CaptionText := ATab.CustomName
  else if ATab.BatchFileName = '' then
    CaptionText := NEW_TAB_CAPTION
  else
    CaptionText := ChangeFileExt(ExtractFileName(ATab.BatchFileName), '');
  if Length(CaptionText) < 8 then
    CaptionText := CaptionText + StringOfChar(' ', 8 - Length(CaptionText));

  for I := 0 to FTabs.Count - 1 do
    if FTabs[I] = ATab then
    begin
      if (FTabControl <> nil) and (I < FTabControl.PageCount) then
        FTabControl.Pages[I].Caption := CaptionText + '  x';
      Break;
    end;
end;

procedure TMainForm.PageControlMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  R: TRect;
  ClickTime: DWORD;
begin
  if Button <> mbLeft then
    Exit;

  if (FTabNameEdit <> nil) and FTabNameEdit.Visible then
  begin
    CommitRenameBatchTab;
    if FTabNameEdit.Visible then
      Exit;
  end;

  if IsOverTabCloseButton(X, Y, I) then
  begin
    CloseBatchTab(I);
    Exit;
  end;

  FTabDragIndex := -1;
  FTabDragging := False;
  for I := 0 to FTabControl.PageCount - 1 do
  begin
    R := FTabControl.TabRect(I);
    if (X >= R.Left) and (X < R.Right - TAB_CLOSE_HIT_WIDTH) and (Y >= R.Top) and (Y <= R.Bottom) then
    begin
      FTabDragIndex := I;
      FTabDragStartPos.X := X;
      FTabDragStartPos.Y := Y;
      ClickTime := GetTickCount;
      if (FLastTabClickIndex = I) and ((ClickTime - FLastTabClickTime) <= DWORD(GetDoubleClickTime)) then
      begin
        BeginRenameBatchTab(I);
        FTabDragIndex := -1;
        FLastTabClickIndex := -1;
        FLastTabClickTime := 0;
      end
      else
      begin
        FLastTabClickIndex := I;
        FLastTabClickTime := ClickTime;
      end;
      Exit;
    end;
  end;
end;

procedure TMainForm.PageControlMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  TabIndex: Integer;
begin
  if (FTabDragIndex >= 0) and (ssLeft in Shift) then
  begin
    if (not FTabDragging) and
      ((Abs(X - FTabDragStartPos.X) > GetSystemMetrics(SM_CXDRAG)) or
       (Abs(Y - FTabDragStartPos.Y) > GetSystemMetrics(SM_CYDRAG))) then
    begin
      FTabDragging := True;
      FLastTabClickIndex := -1;
      FLastTabClickTime := 0;
    end;
  end;

  if FTabDragging then
    FTabControl.Cursor := crSizeWE
  else if IsOverTabCloseButton(X, Y, TabIndex) then
    FTabControl.Cursor := crHandPoint
  else
    FTabControl.Cursor := crDefault;
end;

procedure TMainForm.PageControlMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  TargetIndex: Integer;
begin
  if Button <> mbLeft then
    Exit;

  if FTabDragging and (FTabDragIndex >= 0) then
  begin
    TargetIndex := TabIndexAt(X, Y, True);
    if (TargetIndex >= 0) and (TargetIndex <> FTabDragIndex) then
      SwapBatchTabs(FTabDragIndex, TargetIndex);
  end;

  FTabDragIndex := -1;
  FTabDragging := False;
  FTabControl.Cursor := crDefault;
end;

procedure TMainForm.NewTabButtonClick(Sender: TObject);
begin
  miNuevaPestanaClick(Sender);
end;

procedure TMainForm.RenameBatchTab(const AIndex: Integer);
var
  NewName: string;
  Tab: TBatchTab;
begin
  if (AIndex < 0) or (AIndex >= FTabs.Count) then
    Exit;

  Tab := FTabs[AIndex];
  NewName := Tab.CustomName;
  if (NewName = '') and (Tab.BatchFileName <> '') then
    NewName := ChangeFileExt(ExtractFileName(Tab.BatchFileName), '');

  if InputQuery('Nombre de pestaña', 'Nombre:', NewName) then
  begin
    Tab.CustomName := Trim(NewName);
    RefreshTabCaption(Tab);
  end;
end;

procedure TMainForm.TabNameEditExit(Sender: TObject);
begin
  CommitRenameBatchTab;
end;

procedure TMainForm.TabNameEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    CommitRenameBatchTab;
  end
  else if Key = VK_ESCAPE then
  begin
    Key := 0;
    CancelRenameBatchTab;
  end;
end;

procedure TMainForm.TabNameEditTimerTimer(Sender: TObject);
var
  BottomRight: TPoint;
  IsDown: Boolean;
  MousePos: TPoint;
  R: TRect;
  TopLeft: TPoint;
begin
  if (FTabNameEdit = nil) or (not FTabNameEdit.Visible) then
  begin
    FTabNameEditTimer.Enabled := False;
    FTabNameMouseDown := False;
    Exit;
  end;

  IsDown := GetKeyState(VK_LBUTTON) < 0;
  if IsDown and (not FTabNameMouseDown) then
  begin
    if GetCursorPos(MousePos) then
    begin
      TopLeft.X := 0;
      TopLeft.Y := 0;
      TopLeft := FTabNameEdit.ClientToScreen(TopLeft);
      BottomRight.X := FTabNameEdit.Width;
      BottomRight.Y := FTabNameEdit.Height;
      BottomRight := FTabNameEdit.ClientToScreen(BottomRight);
      R.Left := TopLeft.X;
      R.Top := TopLeft.Y;
      R.Right := BottomRight.X;
      R.Bottom := BottomRight.Y;
      if not PtInRect(R, MousePos) then
        CommitRenameBatchTab;
    end;
  end;
  FTabNameMouseDown := IsDown;
end;

function TMainForm.IsOverTabCloseButton(const X, Y: Integer; out AIndex: Integer): Boolean;
var
  CloseLeft: Integer;
  I: Integer;
  R: TRect;
begin
  Result := False;
  AIndex := -1;
  if FTabControl = nil then
    Exit;

  for I := 0 to FTabControl.PageCount - 1 do
  begin
    R := FTabControl.TabRect(I);
    if (Y < R.Top) or (Y > R.Bottom) then
      Continue;

    CloseLeft := R.Right - TAB_CLOSE_HIT_WIDTH;
    if CloseLeft < R.Left + TAB_MIN_CAPTION_WIDTH then
      CloseLeft := R.Left + TAB_MIN_CAPTION_WIDTH;
    if CloseLeft > R.Right - 16 then
      CloseLeft := R.Right - 16;

    if (X >= CloseLeft) and (X <= R.Right) then
    begin
      AIndex := I;
      Result := True;
      Exit;
    end;
  end;
end;

function TMainForm.TabIndexAt(const X, Y: Integer; const AIncludeCloseButton: Boolean): Integer;
var
  I: Integer;
  RightLimit: Integer;
  R: TRect;
begin
  Result := -1;
  if FTabControl = nil then
    Exit;

  for I := 0 to FTabControl.PageCount - 1 do
  begin
    R := FTabControl.TabRect(I);
    if AIncludeCloseButton then
      RightLimit := R.Right
    else
      RightLimit := R.Right - TAB_CLOSE_HIT_WIDTH;

    if (X >= R.Left) and (X < RightLimit) and (Y >= R.Top) and (Y <= R.Bottom) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

procedure TMainForm.SwapBatchTabs(const AIndex1, AIndex2: Integer);
var
  ActiveTab: TBatchTab;
  Sheet1: TTabSheet;
  Sheet2: TTabSheet;
begin
  if (FTabs = nil) or (FTabControl = nil) then
    Exit;
  if (AIndex1 < 0) or (AIndex2 < 0) or
    (AIndex1 >= FTabs.Count) or (AIndex2 >= FTabs.Count) or
    (AIndex1 >= FTabControl.PageCount) or (AIndex2 >= FTabControl.PageCount) or
    (AIndex1 = AIndex2) then
    Exit;

  SaveActiveTabState;
  ActiveTab := ActiveBatchTab;
  Sheet1 := FTabControl.Pages[AIndex1];
  Sheet2 := FTabControl.Pages[AIndex2];

  FSuppressTabChange := True;
  try
    FTabs.Exchange(AIndex1, AIndex2);
    Sheet1.PageIndex := AIndex2;
    Sheet2.PageIndex := AIndex1;
    if ActiveTab <> nil then
      FTabControl.PageIndex := FTabs.IndexOf(ActiveTab);
    FActiveTabIndex := FTabControl.PageIndex;
  finally
    FSuppressTabChange := False;
  end;
  LoadTabToUi(ActiveBatchTab);
end;

procedure TMainForm.SaveActiveTabState;
var
  Tab: TBatchTab;
begin
  if (FTabs = nil) or (FTabs.Count = 0) then
    Exit;
  if (FActiveTabIndex < 0) or (FActiveTabIndex >= FTabs.Count) then
    Tab := ActiveBatchTab
  else
    Tab := FTabs[FActiveTabIndex];
  if Tab = nil then
    Exit;
  Tab.BatchFileName := FBatchFileName;
  Tab.Output.Assign(MemoOutput.Lines);
  Tab.StatusText := StatusBar1.SimpleText;
  SaveVariableValues(Tab);
  RefreshTabCaption(Tab);
end;

procedure TMainForm.SaveVariableValues(ATab: TBatchTab);
var
  Item: TVariableItem;
begin
  if ATab = nil then
    Exit;
  ATab.Values.Clear;
  for Item in FVariables do
    ATab.Values.Values[Item.VarName] := Item.ValueEdit.Text;
end;

procedure TMainForm.CloseBatchTab(const AIndex: Integer);
var
  Index: Integer;
  Tab: TBatchTab;
begin
  if (FTabs = nil) or (FTabs.Count = 0) or (AIndex < 0) or (AIndex >= FTabs.Count) then
    Exit;

  Tab := FTabs[AIndex];
  if Assigned(Tab.Process) then
  begin
    MessageDlg('No se puede cerrar una pestaña con ejecución en curso.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if FTabs.Count = 1 then
  begin
    if (Tab.BatchFileName = '') and (Tab.CustomName = '') then
    begin
      MessageDlg('Debe quedar al menos una pestaña.', mtInformation, [mbOK], 0);
      Exit;
    end;

    Tab.BatchFileName := '';
    Tab.CustomName := '';
    Tab.Output.Clear;
    Tab.Values.Clear;
    Tab.StatusText := 'Listo';
    FBatchFileName := '';
    FLastBatchDir := FStartupDir;
    RefreshTabCaption(Tab);
    LoadTabToUi(Tab);
    Exit;
  end;

  if (FTabs = nil) or (FTabs.Count = 0) then
  begin
    MessageDlg('Debe quedar al menos una pestaña.', mtInformation, [mbOK], 0);
    Exit;
  end;

  if (AIndex < 0) or (AIndex >= FTabs.Count) then
    Exit;

  Tab := FTabs[AIndex];
  if Assigned(Tab.Process) then
  begin
    MessageDlg('No se puede cerrar una pestaña con ejecución en curso.', mtWarning, [mbOK], 0);
    Exit;
  end;

  Index := AIndex;
  FSuppressTabChange := True;
  try
    FTabControl.Pages[Index].Free;
    FTabs.Delete(Index);
    if Index >= FTabs.Count then
      Index := FTabs.Count - 1;
    FTabControl.PageIndex := Index;
    FActiveTabIndex := Index;
  finally
    FSuppressTabChange := False;
  end;
  LoadTabToUi(ActiveBatchTab);
end;

procedure TMainForm.LoadBatchVariables(const FileName: string);
var
  Lines: TStringList;
  I: Integer;
  TopPos: Integer;
  TaggedName: string;
  TaggedValue: string;
  VarName: string;
  VarValue: string;
  Item: TVariableItem;
  TotalEditableVars: Integer;
  WarnTooManyVariables: Boolean;
begin
  ClearVariableControls;
  FBatchFileName := FileName;
  FLastBatchDir := ExtractFileDir(FileName);
  Caption := 'Batch Runner - ' + ExtractFileName(FileName);

  ScrollBox1.DisableAlign;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    TopPos := 20;
    TotalEditableVars := 0;
    WarnTooManyVariables := False;

    for I := 0 to Lines.Count - 1 do
    begin
      if not ExtractAssignment(Lines[I], VarName, VarValue) then
        Continue;

      Item := TVariableItem.Create;
      Item.VarName := VarName;

      if FOnlyPrecommentedVariables then
      begin
        if I = 0 then
        begin
          Item.Free;
          Continue;
        end;
        if not ExtractTaggedDefault(Lines[I - 1], TaggedName, TaggedValue) then
        begin
          Item.Free;
          Continue;
        end;
        if not SameText(TaggedName, VarName) then
        begin
          Item.Free;
          Continue;
        end;
        Item.HasTaggedDefault := True;
      end
      else
      begin
        Item.HasTaggedDefault := (I > 0) and ExtractTaggedDefault(Lines[I - 1], TaggedName, TaggedValue)
          and SameText(TaggedName, VarName);
        if not Item.HasTaggedDefault then
          TaggedValue := VarValue;
      end;

      Inc(TotalEditableVars);
      if FVariables.Count >= MAX_GUI_VARIABLES then
      begin
        Item.Free;
        WarnTooManyVariables := True;
        Continue;
      end;
      Item.DefaultValue := TaggedValue;

      Item.NameLabel := TLabel.Create(ScrollBox1);
      Item.NameLabel.Parent := ScrollBox1;
      Item.NameLabel.Caption := VarName;
      Item.NameLabel.Left := 16;
      Item.NameLabel.Top := TopPos + 2;
      Item.NameLabel.Font.Name := 'Segoe UI';
      Item.NameLabel.Font.Size := 10;
      Item.NameLabel.Font.Style := [fsBold];
      Item.NameLabel.Font.Color := RGBToColor(60, 49, 35);

      Item.DefineDefaultButton := TSpeedButton.Create(ScrollBox1);
      Item.DefineDefaultButton.Parent := ScrollBox1;
      Item.DefineDefaultButton.Caption := '+';
      Item.DefineDefaultButton.Hint := 'Definir default para ' + VarName;
      Item.DefineDefaultButton.ShowHint := True;
      Item.DefineDefaultButton.ParentShowHint := False;
      Item.DefineDefaultButton.Flat := True;
      Item.DefineDefaultButton.Cursor := crHandPoint;
      Item.DefineDefaultButton.Width := 24;
      Item.DefineDefaultButton.Height := 24;
      Item.DefineDefaultButton.Left := 0;
      Item.DefineDefaultButton.Top := TopPos;
      Item.DefineDefaultButton.Anchors := [akTop];
      Item.DefineDefaultButton.Tag := PtrInt(Item);
      Item.DefineDefaultButton.OnClick := @btnDefineDefaultClick;

      Item.ResetButton := TSpeedButton.Create(ScrollBox1);
      Item.ResetButton.Parent := ScrollBox1;
      Item.ResetButton.Caption := '↺';
      Item.ResetButton.Hint := 'Restablecer ' + VarName;
      Item.ResetButton.ShowHint := True;
      Item.ResetButton.ParentShowHint := False;
      Item.ResetButton.Flat := True;
      Item.ResetButton.Cursor := crHandPoint;
      Item.ResetButton.Width := 24;
      Item.ResetButton.Height := 24;
      Item.ResetButton.Left := 0;
      Item.ResetButton.Top := TopPos;
      Item.ResetButton.Anchors := [akTop];
      Item.ResetButton.Visible := Item.HasTaggedDefault;
      Item.ResetButton.Tag := PtrInt(Item);
      Item.ResetButton.OnClick := @btnResetVariableClick;

      Item.RemoveDefaultButton := TSpeedButton.Create(ScrollBox1);
      Item.RemoveDefaultButton.Parent := ScrollBox1;
      Item.RemoveDefaultButton.Caption := 'x';
      Item.RemoveDefaultButton.Hint := 'Eliminar default de ' + VarName;
      Item.RemoveDefaultButton.ShowHint := True;
      Item.RemoveDefaultButton.ParentShowHint := False;
      Item.RemoveDefaultButton.Flat := True;
      Item.RemoveDefaultButton.Cursor := crHandPoint;
      Item.RemoveDefaultButton.Width := 24;
      Item.RemoveDefaultButton.Height := 24;
      Item.RemoveDefaultButton.Left := 0;
      Item.RemoveDefaultButton.Top := TopPos;
      Item.RemoveDefaultButton.Anchors := [akTop];
      Item.RemoveDefaultButton.Visible := Item.HasTaggedDefault;
      Item.RemoveDefaultButton.Tag := PtrInt(Item);
      Item.RemoveDefaultButton.OnClick := @btnRemoveDefaultClick;

      Item.ValueEdit := TEdit.Create(ScrollBox1);
      Item.ValueEdit.Parent := ScrollBox1;
      Item.ValueEdit.Text := VarValue;
      Item.ValueEdit.Left := 16;
      Item.ValueEdit.Top := TopPos + Item.NameLabel.Height + 6;
      Item.ValueEdit.Width := 280;
      Item.ValueEdit.Color := RGBToColor(251, 247, 239);
      Item.ValueEdit.BorderStyle := bsSingle;
      Item.ValueEdit.Font.Name := 'Segoe UI';
      Item.ValueEdit.Font.Size := 10;
      Item.ValueEdit.Font.Color := RGBToColor(60, 49, 35);
      Item.ValueEdit.Anchors := [akLeft, akTop, akRight];

      FVariables.Add(Item);
      TopPos := Item.ValueEdit.Top + Item.ValueEdit.Height + 16;
    end;

  finally
    Lines.Free;
    ScrollBox1.EnableAlign;
    FUpdatingVariableControls := False;
  end;

  ScrollBox1.VertScrollBar.Position := 0;
  ScrollBox1.HorzScrollBar.Position := 0;
  ScrollBox1.Realign;
  LayoutVariableControls;
  ScrollBox1.Realign;
  LayoutVariableControls;
  ScrollBox1.Invalidate;
  PositionExecuteButton;

  if WarnTooManyVariables or (TotalEditableVars > MAX_GUI_VARIABLES) then
    SetStatus('Hay más de 10 variables; solo se muestran 10')
  else if FVariables.Count = 0 then
    SetStatus('Sin variables editables')
  else
    SetStatus(IntToStr(FVariables.Count) + ' variable(s) editable(s)');
end;

procedure TMainForm.LayoutVariableControls;
var
  Item: TVariableItem;
  TopPos: Integer;
  LabelLeft: Integer;
  EditLeft: Integer;
  EditRight: Integer;
  EditWidth: Integer;
  RemoveLeft: Integer;
  ResetLeft: Integer;
  DefineLeft: Integer;
  RightReserve: Integer;
begin
  if FUpdatingVariableControls then
    Exit;

  LabelLeft := 16;
  EditLeft := LabelLeft;
  RightReserve := GetSystemMetrics(SM_CXVSCROLL) + 8;
  DefineLeft := ScrollBox1.ClientWidth - 16 - RightReserve - 24;
  ResetLeft := DefineLeft - 8 - 24;
  RemoveLeft := ResetLeft - 8 - 24;
  EditRight := RemoveLeft - 8;
  EditWidth := EditRight - EditLeft;
  if EditWidth < 180 then
    EditWidth := 180;

  TopPos := 20;
  for Item in FVariables do
  begin
    Item.NameLabel.Left := LabelLeft;
    Item.NameLabel.Top := TopPos + 2;

    Item.DefineDefaultButton.Left := DefineLeft;
    Item.DefineDefaultButton.Top := TopPos;

    Item.ResetButton.Left := ResetLeft;
    Item.ResetButton.Top := TopPos;

    Item.RemoveDefaultButton.Left := RemoveLeft;
    Item.RemoveDefaultButton.Top := TopPos;

    Item.ValueEdit.Left := EditLeft;
    Item.ValueEdit.Top := Item.NameLabel.Top + Item.NameLabel.Height + 6;
    Item.ValueEdit.Width := EditWidth;

    Item.ValueEdit.BringToFront;
    Item.RemoveDefaultButton.BringToFront;
    Item.ResetButton.BringToFront;
    Item.DefineDefaultButton.BringToFront;
    Item.NameLabel.BringToFront;

    TopPos := Item.ValueEdit.Top + Item.ValueEdit.Height + 16;
  end;
end;

procedure TMainForm.PositionExecuteButton;
begin
  btnExecute.Left := pnlExe.ClientWidth - btnExecute.Width - 16;
  if btnExecute.Left < 0 then
    btnExecute.Left := 0;
  btnExecute.Top := (pnlExe.ClientHeight - btnExecute.Height) div 2;
  if btnExecute.Top < 0 then
    btnExecute.Top := 0;
  LayoutExecuteIcon;
end;

procedure TMainForm.LoadSettings;
var
  Ini: TIniFile;
  I: Integer;
  LastFile: string;
  TabCount: Integer;
  TabName: string;
  TabFile: string;
begin
  Ini := TIniFile.Create(FConfigFileName);
  try
    FEditorPath := Ini.ReadString('General', 'EditorPath', '');
    FLastBatchDir := Ini.ReadString('General', 'LastBatchDir', FStartupDir);
    LastFile := Ini.ReadString('General', 'LastBatchFile', '');
    FOnlyPrecommentedVariables := Ini.ReadBool('General', 'OnlyPrecommentedVariables', False);
    TabCount := Ini.ReadInteger('Tabs', 'Count', 0);
    for I := 0 to TabCount - 1 do
    begin
      TabFile := Ini.ReadString('Tab' + IntToStr(I + 1), 'BatchFile', '');
      TabName := Ini.ReadString('Tab' + IntToStr(I + 1), 'Name', '');
      if SameText(Trim(TabName), NEW_TAB_CAPTION) then
        TabName := '';
      AddBatchTab(TabFile, False);
      if FTabs.Count > 0 then
      begin
        FTabs[FTabs.Count - 1].CustomName := TabName;
        RefreshTabCaption(FTabs[FTabs.Count - 1]);
      end;
    end;
    if (FTabs.Count = 0) and (LastFile <> '') then
      AddBatchTab(LastFile, False);
    if FTabs.Count > 0 then
    begin
      FActiveTabIndex := Ini.ReadInteger('Tabs', 'ActiveIndex', 0);
      if FActiveTabIndex >= FTabs.Count then
        FActiveTabIndex := FTabs.Count - 1;
      if FActiveTabIndex < 0 then
        FActiveTabIndex := 0;
      if FTabControl.PageCount > FActiveTabIndex then
      begin
        FSuppressTabChange := True;
        try
          FTabControl.PageIndex := FActiveTabIndex;
        finally
          FSuppressTabChange := False;
        end;
      end;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.ResetVariablesToDefault;
var
  Item: TVariableItem;
  RestoredCount: Integer;
begin
  if FVariables.Count = 0 then
  begin
    SetStatus('Sin variables para restablecer');
    Exit;
  end;

  RestoredCount := 0;
  for Item in FVariables do
    if Item.HasTaggedDefault then
    begin
      Item.ValueEdit.Text := Item.DefaultValue;
      Inc(RestoredCount);
    end;

  if RestoredCount = 0 then
  begin
    SetStatus('Sin variables con default para restablecer');
    Exit;
  end;

  ApplyGuiValuesToBatchFile;
  SetStatus('Valores restablecidos');
end;

procedure TMainForm.ScrollBox1Resize(Sender: TObject);
begin
  if FUpdatingVariableControls then
    Exit;
  LayoutVariableControls;
  PositionExecuteButton;
end;

procedure TMainForm.SaveSettings;
var
  Ini: TIniFile;
  I: Integer;
  Sections: TStringList;
begin
  SaveActiveTabState;
  Ini := TIniFile.Create(FConfigFileName);
  Sections := TStringList.Create;
  try
    Ini.WriteString('General', 'EditorPath', FEditorPath);
    Ini.WriteString('General', 'LastBatchDir', FLastBatchDir);
    Ini.WriteString('General', 'LastBatchFile', FBatchFileName);
    Ini.WriteBool('General', 'OnlyPrecommentedVariables', FOnlyPrecommentedVariables);
    Ini.ReadSections(Sections);
    for I := 0 to Sections.Count - 1 do
      if Copy(Sections[I], 1, 3) = 'Tab' then
        Ini.EraseSection(Sections[I]);

    Ini.WriteInteger('Tabs', 'Count', FTabs.Count);
    if FTabControl <> nil then
      Ini.WriteInteger('Tabs', 'ActiveIndex', FTabControl.PageIndex)
    else
      Ini.WriteInteger('Tabs', 'ActiveIndex', 0);
    for I := 0 to FTabs.Count - 1 do
    begin
      Ini.WriteString('Tab' + IntToStr(I + 1), 'BatchFile', FTabs[I].BatchFileName);
      Ini.WriteString('Tab' + IntToStr(I + 1), 'Name', FTabs[I].CustomName);
    end;
  finally
    Sections.Free;
    Ini.Free;
  end;
end;

procedure TMainForm.miConfigurarEditorClick(Sender: TObject);
begin
  ConfigureEditor;
end;

procedure TMainForm.miNuevaPestanaClick(Sender: TObject);
begin
  AddBatchTab('', True);
  SetStatus('Nueva pestaña');
end;

procedure TMainForm.miCerrarPestanaClick(Sender: TObject);
begin
  CloseBatchTab(FTabControl.PageIndex);
end;

procedure TMainForm.miDefinirValoresDefaultClick(Sender: TObject);
begin
  DefineVisibleVariablesAsDefault;
  SetStatus('Defaults definidos');
end;

procedure TMainForm.miEliminarValoresDefaultClick(Sender: TObject);
begin
  RemoveVisibleVariableDefaults;
  SetStatus('Defaults eliminados');
end;

procedure TMainForm.miResetearValoresClick(Sender: TObject);
begin
  ResetVariablesToDefault;
end;

procedure TMainForm.miSalirClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.UpdateRunState;
var
  ARunning: Boolean;
  Tab: TBatchTab;
begin
  Tab := ActiveBatchTab;
  ARunning := (Tab <> nil) and Assigned(Tab.Process);
  btnExecute.Enabled := not ARunning;
  btnLoad.Enabled := not ARunning;
  btnEditBatch.Enabled := not ARunning;
  if not ARunning then
  begin
    FLoadPressed := False;
    FEditPressed := False;
  end;
  UpdateActionButtonVisual(btnLoad, FLoadPressed);
  UpdateActionButtonVisual(btnEditBatch, FEditPressed);
  UpdateExecuteButtonVisual;
end;

end.
