unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, Process, fgl, Windows, DateUtils, IniFiles;

type
  TVariableItem = class
  public
    VarName: string;
    ValueEdit: TEdit;
    NameLabel: TLabel;
  end;

  TVariableList = specialize TFPGObjectList<TVariableItem>;

  { TMainForm }

  TMainForm = class(TForm)
    btnClearOutput: TSpeedButton;
    btnExecute: TButton;
    btnLoad: TButton;
    lblPanelHint: TLabel;
    lblPanelTitle: TLabel;
    MemoOutput: TMemo;
    OpenDialog1: TOpenDialog;
    pnlActions: TPanel;
    pnlRight: TPanel;
    pnlTop: TPanel;
    pnlVarsHeader: TPanel;
    ScrollBox1: TScrollBox;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    procedure btnExecuteClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnClearOutputClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ProcessTimerTimer(Sender: TObject);
  private
    FBatchFileName: string;
    FConfigFileName: string;
    FLastBatchDir: string;
    FProcess: TProcess;
    FProcessStart: TDateTime;
    FProcessTimer: TTimer;
    FStartupDir: string;
    FVariables: TVariableList;
    procedure ApplyGuiValuesToBatchFile;
    procedure BringProcessWindowToFront(const APID: DWORD);
    procedure BringSelfToFront;
    procedure ClearVariableControls;
    procedure CreateAppIcon;
    function CmdQuote(const S: string): string;
    function ExtractAssignment(const Line: string; out VarName, VarValue: string): Boolean;
    function ExtractTaggedDefault(const Line: string; out VarName, VarValue: string): Boolean;
    function FormatElapsed(const AStart, AFinish: TDateTime): string;
    procedure LoadBatchVariables(const FileName: string);
    procedure LoadSettings;
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
  Color := RGBToColor(245, 239, 226);
  MemoOutput.Color := RGBToColor(17, 20, 24);
  MemoOutput.Font.Color := RGBToColor(143, 255, 186);
  MemoOutput.Font.Name := 'Consolas';
  MemoOutput.Font.Size := 10;
  pnlRight.Color := RGBToColor(232, 222, 204);
  pnlTop.Color := RGBToColor(219, 205, 179);
  StatusBar1.Color := RGBToColor(219, 205, 179);
  MemoOutput.Font.Color := RGBToColor(143, 255, 186);
  CreateAppIcon;
  LoadSettings;
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

procedure TMainForm.SetStatus(const S: string);
begin
  StatusBar1.SimpleText := S;
end;

procedure TMainForm.btnClearOutputClick(Sender: TObject);
begin
  MemoOutput.Clear;
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
    ScrollBox1.Controls[I].Free;
  FVariables.Clear;
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
  TaggedName: string;
  TaggedValue: string;
  VarName: string;
  VarValue: string;
  Item: TVariableItem;
begin
  ClearVariableControls;
  FBatchFileName := FileName;
  FLastBatchDir := ExtractFileDir(FileName);
  Caption := 'Batch Runner - ' + ExtractFileName(FileName);

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    TopPos := 12;

    for I := 1 to Lines.Count - 1 do
    begin
      if not ExtractTaggedDefault(Lines[I - 1], TaggedName, TaggedValue) then
        Continue;
      if not ExtractAssignment(Lines[I], VarName, VarValue) then
        Continue;
      if not SameText(TaggedName, VarName) then
        Continue;

      Item := TVariableItem.Create;
      Item.VarName := VarName;

      Item.NameLabel := TLabel.Create(ScrollBox1);
      Item.NameLabel.Parent := ScrollBox1;
      Item.NameLabel.Caption := VarName;
      Item.NameLabel.Left := 12;
      Item.NameLabel.Top := TopPos + 4;
      Item.NameLabel.Width := 180;

      Item.ValueEdit := TEdit.Create(ScrollBox1);
      Item.ValueEdit.Parent := ScrollBox1;
      Item.ValueEdit.Text := VarValue;
      Item.ValueEdit.Left := 200;
      Item.ValueEdit.Top := TopPos;
      Item.ValueEdit.Width := 420;
      Item.ValueEdit.Anchors := [akLeft, akTop, akRight];

      FVariables.Add(Item);
      Inc(TopPos, 32);
    end;

  finally
    Lines.Free;
  end;

  if FVariables.Count = 0 then
    SetStatus('Sin variables editables')
  else
    SetStatus(IntToStr(FVariables.Count) + ' variable(s) editable(s)');
end;

procedure TMainForm.LoadSettings;
var
  Ini: TIniFile;
  LastFile: string;
begin
  Ini := TIniFile.Create(FConfigFileName);
  try
    FLastBatchDir := Ini.ReadString('General', 'LastBatchDir', FStartupDir);
    LastFile := Ini.ReadString('General', 'LastBatchFile', '');
    if FileExists(LastFile) then
      LoadBatchVariables(LastFile)
    else
      FBatchFileName := LastFile;
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FConfigFileName);
  try
    Ini.WriteString('General', 'LastBatchDir', FLastBatchDir);
    Ini.WriteString('General', 'LastBatchFile', FBatchFileName);
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.UpdateRunState(const ARunning: Boolean);
begin
  btnExecute.Enabled := not ARunning;
  btnLoad.Enabled := not ARunning;
end;

end.
