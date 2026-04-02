unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, Process, fgl, Windows, DateUtils, IniFiles, Menus;

const
  MAX_GUI_VARIABLES = 10;

type
  TVariableItem = class
  public
    DefaultValue: string;
    VarName: string;
    ResetButton: TSpeedButton;
    ValueEdit: TEdit;
    NameLabel: TLabel;
  end;

  TVariableList = specialize TFPGObjectList<TVariableItem>;

  { TMainForm }

  TMainForm = class(TForm)
    btnEditBatch: TButton;
    btnExecute: TButton;
    btnLoad: TButton;
    EditorDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    MemoOutput: TMemo;
    miArchivo: TMenuItem;
    miCargarBat: TMenuItem;
    miConfigurarEditor: TMenuItem;
    miEditarBat: TMenuItem;
    miLimpiarSalida: TMenuItem;
    miResetearValores: TMenuItem;
    miSalida: TMenuItem;
    OpenDialog1: TOpenDialog;
    pnlActions: TPanel;
    pnlRight: TPanel;
    ScrollBox1: TScrollBox;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    procedure btnEditBatchClick(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnClearOutputClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure miConfigurarEditorClick(Sender: TObject);
    procedure miResetearValoresClick(Sender: TObject);
    procedure ProcessTimerTimer(Sender: TObject);
    procedure ScrollBox1Resize(Sender: TObject);
  private
    FBatchFileName: string;
    FConfigFileName: string;
    FEditorPath: string;
    FInitialLoadDone: Boolean;
    FLastBatchDir: string;
    FProcess: TProcess;
    FProcessStart: TDateTime;
    FProcessTimer: TTimer;
    FStartupDir: string;
    FVariables: TVariableList;
    procedure ApplyGuiValuesToBatchFile;
    procedure BringProcessWindowToFront(const APID: DWORD);
    procedure BringSelfToFront;
    procedure btnResetVariableClick(Sender: TObject);
    procedure ClearVariableControls;
    function ConfigureEditor: Boolean;
    procedure CreateAppIcon;
    function CmdQuote(const S: string): string;
    procedure EditBatchFile;
    function ExtractAssignment(const Line: string; out VarName, VarValue: string): Boolean;
    function ExtractTaggedDefault(const Line: string; out VarName, VarValue: string): Boolean;
    function FormatElapsed(const AStart, AFinish: TDateTime): string;
    procedure LoadBatchVariables(const FileName: string);
    procedure PositionExecuteButton;
    procedure LoadSettings;
    procedure ResetVariablesToDefault;
    procedure SaveSettings;
    procedure SetStatus(const S: string);
    procedure UpdateRunState(const ARunning: Boolean);
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

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FVariables := TVariableList.Create(True);
  FProcess := nil;
  FBatchFileName := '';
  FConfigFileName := ChangeFileExt(Application.ExeName, '.ini');
  FEditorPath := '';
  FInitialLoadDone := False;
  FLastBatchDir := '';
  FProcessStart := 0;
  FProcessTimer := TTimer.Create(Self);
  FProcessTimer.Enabled := False;
  FProcessTimer.Interval := 300;
  FProcessTimer.OnTimer := @ProcessTimerTimer;
  FStartupDir := GetCurrentDir;
  OpenDialog1.Filter := 'Batch files|*.bat|All files|*.*';
  OpenDialog1.Options := OpenDialog1.Options + [ofFileMustExist, ofPathMustExist];
  OpenDialog1.InitialDir := FStartupDir;
  EditorDialog1.Filter := 'Aplicaciones|*.exe|Todos los archivos|*.*';
  EditorDialog1.Options := EditorDialog1.Options + [ofFileMustExist, ofPathMustExist];
  EditorDialog1.InitialDir := FStartupDir;
  Color := RGBToColor(245, 239, 226);
  MemoOutput.Color := RGBToColor(17, 20, 24);
  MemoOutput.Font.Color := RGBToColor(143, 255, 186);
  MemoOutput.Font.Name := 'Consolas';
  MemoOutput.Font.Size := 10;
  pnlRight.Color := RGBToColor(232, 222, 204);
  StatusBar1.Color := RGBToColor(219, 205, 179);
  MemoOutput.Font.Color := RGBToColor(143, 255, 186);
  CreateAppIcon;
  btnExecute.Parent := ScrollBox1;
  btnExecute.Anchors := [akTop, akRight];
  LoadSettings;
  PositionExecuteButton;
  SetStatus('Listo');
  UpdateRunState(False);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  SaveSettings;
  FProcessTimer.Enabled := False;
  FreeAndNil(FProcess);
  FVariables.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if FInitialLoadDone then
    Exit;
  FInitialLoadDone := True;
  if FileExists(FBatchFileName) then
    LoadBatchVariables(FBatchFileName);
end;

procedure TMainForm.btnLoadClick(Sender: TObject);
begin
  if DirectoryExists(FLastBatchDir) then
    OpenDialog1.InitialDir := FLastBatchDir
  else
    OpenDialog1.InitialDir := FStartupDir;

  if FileExists(FBatchFileName) then
    OpenDialog1.FileName := FBatchFileName
  else
    OpenDialog1.FileName := '';

  if OpenDialog1.Execute then
    LoadBatchVariables(OpenDialog1.FileName);
end;

procedure TMainForm.btnEditBatchClick(Sender: TObject);
begin
  EditBatchFile;
end;

procedure TMainForm.SetStatus(const S: string);
begin
  StatusBar1.SimpleText := S;
end;

procedure TMainForm.btnClearOutputClick(Sender: TObject);
begin
  MemoOutput.Clear;
  SetStatus('Salida limpiada');
end;

procedure TMainForm.btnExecuteClick(Sender: TObject);
var
  Proc: TProcess;
begin
  if FBatchFileName = '' then
  begin
    MessageDlg('Debe cargar un archivo .bat.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if Assigned(FProcess) then
  begin
    MessageDlg('Ya hay una ejecucion en curso.', mtWarning, [mbOK], 0);
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

  FProcess := Proc;
  FProcessStart := Now;
  MemoOutput.Clear;
  MemoOutput.Lines.Add('Inicio: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FProcessStart));
  MemoOutput.Lines.Add('Archivo: ' + FBatchFileName);
  if FVariables.Count = 0 then
    MemoOutput.Lines.Add('Ejecucion sin reemplazos desde la GUI.');
  SetStatus('Ejecutando...');
  UpdateRunState(True);
  BringProcessWindowToFront(FProcess.ProcessID);
  FProcessTimer.Enabled := True;
end;

procedure TMainForm.ProcessTimerTimer(Sender: TObject);
var
  FinishTime: TDateTime;
begin
  if not Assigned(FProcess) then
  begin
    FProcessTimer.Enabled := False;
    Exit;
  end;

  if FProcess.Running then
    Exit;

  FinishTime := Now;
  FProcessTimer.Enabled := False;
  MemoOutput.Lines.Add('Fin: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FinishTime));
  MemoOutput.Lines.Add('Duracion: ' + FormatElapsed(FProcessStart, FinishTime));
  MemoOutput.Lines.Add('Finalizado. Codigo de salida: ' + IntToStr(FProcess.ExitStatus));
  FreeAndNil(FProcess);
  UpdateRunState(False);
  SetStatus('Finalizado');
  BringSelfToFront;
end;

procedure TMainForm.ClearVariableControls;
var
  I: Integer;
begin
  for I := ScrollBox1.ControlCount - 1 downto 0 do
    if ScrollBox1.Controls[I] <> btnExecute then
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

function TMainForm.ConfigureEditor: Boolean;
begin
  if FileExists(FEditorPath) then
    EditorDialog1.FileName := FEditorPath
  else
    EditorDialog1.FileName := '';

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
  P: array[0..11] of TPoint;
begin
  Bmp := Graphics.TBitmap.Create;
  try
    Bmp.SetSize(32, 32);
    Bmp.Canvas.Brush.Color := RGBToColor(219, 205, 179);
    Bmp.Canvas.FillRect(0, 0, 32, 32);

    Bmp.Canvas.Pen.Style := psClear;
    Bmp.Canvas.Brush.Color := RGBToColor(25, 28, 33);
    P[0].X := 2;  P[0].Y := 13;
    P[1].X := 7;  P[1].Y := 8;
    P[2].X := 11; P[2].Y := 4;
    P[3].X := 13; P[3].Y := 10;
    P[4].X := 16; P[4].Y := 12;
    P[5].X := 19; P[5].Y := 10;
    P[6].X := 21; P[6].Y := 4;
    P[7].X := 25; P[7].Y := 8;
    P[8].X := 30; P[8].Y := 13;
    P[9].X := 24; P[9].Y := 18;
    P[10].X := 16; P[10].Y := 28;
    P[11].X := 8; P[11].Y := 18;
    Bmp.Canvas.Polygon(P);

    Icon.Assign(Bmp);
  finally
    Bmp.Free;
  end;
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
      if not ExtractTaggedDefault(Lines[I - 1], TaggedName, TaggedValue) then
        Continue;
      if not ExtractAssignment(Lines[I], VarName, VarValue) then
        Continue;
      if not SameText(TaggedName, VarName) then
        Continue;

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
  P := Pos('=', S);
  if P <= 1 then
    Exit;

  VarName := Trim(Copy(S, 1, P - 1));
  VarValue := Copy(S, P + 1, MaxInt);
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

procedure TMainForm.LoadBatchVariables(const FileName: string);
var
  Lines: TStringList;
  I: Integer;
  TopPos: Integer;
  LabelLeft: Integer;
  ResetLeft: Integer;
  EditLeft: Integer;
  EditWidth: Integer;
  LabelGap: Integer;
  ItemGap: Integer;
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

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    LabelLeft := 20;
    ResetLeft := ScrollBox1.ClientWidth - 44;
    if ResetLeft < 160 then
      ResetLeft := 160;
    EditLeft := 20;
    EditWidth := ScrollBox1.ClientWidth - (EditLeft * 2);
    if EditWidth < 280 then
      EditWidth := 280;
    LabelGap := 22;
    ItemGap := 16;
    TopPos := 20;
    TotalEditableVars := 0;
    WarnTooManyVariables := False;

    for I := 1 to Lines.Count - 1 do
    begin
      if not ExtractTaggedDefault(Lines[I - 1], TaggedName, TaggedValue) then
        Continue;
      if not ExtractAssignment(Lines[I], VarName, VarValue) then
        Continue;
      if not SameText(TaggedName, VarName) then
        Continue;
      Inc(TotalEditableVars);
      if FVariables.Count >= MAX_GUI_VARIABLES then
      begin
        WarnTooManyVariables := True;
        Continue;
      end;

      Item := TVariableItem.Create;
      Item.DefaultValue := TaggedValue;
      Item.VarName := VarName;

      Item.NameLabel := TLabel.Create(ScrollBox1);
      Item.NameLabel.Parent := ScrollBox1;
      Item.NameLabel.Caption := VarName;
      Item.NameLabel.Left := LabelLeft;
      Item.NameLabel.Top := TopPos + 2;

      Item.ResetButton := TSpeedButton.Create(ScrollBox1);
      Item.ResetButton.Parent := ScrollBox1;
      Item.ResetButton.Caption := '↺';
      Item.ResetButton.Hint := 'Restablecer ' + VarName;
      Item.ResetButton.ShowHint := True;
      Item.ResetButton.ParentShowHint := False;
      Item.ResetButton.Flat := True;
      Item.ResetButton.Width := 24;
      Item.ResetButton.Height := 24;
      Item.ResetButton.Left := ResetLeft;
      Item.ResetButton.Top := TopPos;
      Item.ResetButton.Anchors := [akTop, akRight];
      Item.ResetButton.Tag := PtrInt(Item);
      Item.ResetButton.OnClick := @btnResetVariableClick;

      Item.ValueEdit := TEdit.Create(ScrollBox1);
      Item.ValueEdit.Parent := ScrollBox1;
      Item.ValueEdit.Text := VarValue;
      Item.ValueEdit.Left := EditLeft;
      Item.ValueEdit.Top := TopPos + LabelGap;
      Item.ValueEdit.Width := EditWidth;
      Item.ValueEdit.Anchors := [akLeft, akTop, akRight];

      FVariables.Add(Item);
      Inc(TopPos, LabelGap + Item.ValueEdit.Height + ItemGap);
    end;

  finally
    Lines.Free;
  end;

  PositionExecuteButton;

  if FVariables.Count = 0 then
    SetStatus('Sin variables editables')
  else
    SetStatus(IntToStr(FVariables.Count) + ' variable(s) editable(s)');

  if WarnTooManyVariables or (TotalEditableVars > MAX_GUI_VARIABLES) then
    MessageDlg('hay mas de 10 variables', mtWarning, [mbOK], 0);
end;

procedure TMainForm.PositionExecuteButton;
var
  LastBottom: Integer;
begin
  if FVariables.Count > 0 then
    LastBottom := FVariables[FVariables.Count - 1].ValueEdit.Top +
      FVariables[FVariables.Count - 1].ValueEdit.Height
  else
    LastBottom := 20;

  btnExecute.Left := ScrollBox1.ClientWidth - btnExecute.Width - 20;
  if btnExecute.Left < 20 then
    btnExecute.Left := 20;
  btnExecute.Top := LastBottom + 20;
end;

procedure TMainForm.LoadSettings;
var
  Ini: TIniFile;
  LastFile: string;
begin
  Ini := TIniFile.Create(FConfigFileName);
  try
    FEditorPath := Ini.ReadString('General', 'EditorPath', '');
    FLastBatchDir := Ini.ReadString('General', 'LastBatchDir', FStartupDir);
    LastFile := Ini.ReadString('General', 'LastBatchFile', '');
    FBatchFileName := LastFile;
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.ResetVariablesToDefault;
var
  Item: TVariableItem;
begin
  if FVariables.Count = 0 then
  begin
    SetStatus('Sin variables para restablecer');
    Exit;
  end;

  for Item in FVariables do
    Item.ValueEdit.Text := Item.DefaultValue;
  ApplyGuiValuesToBatchFile;
  SetStatus('Valores restablecidos');
end;

procedure TMainForm.ScrollBox1Resize(Sender: TObject);
begin
  PositionExecuteButton;
end;

procedure TMainForm.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FConfigFileName);
  try
    Ini.WriteString('General', 'EditorPath', FEditorPath);
    Ini.WriteString('General', 'LastBatchDir', FLastBatchDir);
    Ini.WriteString('General', 'LastBatchFile', FBatchFileName);
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.miConfigurarEditorClick(Sender: TObject);
begin
  ConfigureEditor;
end;

procedure TMainForm.miResetearValoresClick(Sender: TObject);
begin
  ResetVariablesToDefault;
end;

procedure TMainForm.UpdateRunState(const ARunning: Boolean);
begin
  btnExecute.Enabled := not ARunning;
  btnLoad.Enabled := not ARunning;
  btnEditBatch.Enabled := not ARunning;
end;

end.
