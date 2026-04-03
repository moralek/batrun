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
    DefineDefaultButton: TSpeedButton;
    HasTaggedDefault: Boolean;
    VarName: string;
    RemoveDefaultButton: TSpeedButton;
    ResetButton: TSpeedButton;
    ValueEdit: TEdit;
    NameLabel: TLabel;
  end;

  TVariableList = specialize TFPGObjectList<TVariableItem>;

  { TMainForm }

  TMainForm = class(TForm)
    btnEditBatch: TPanel;
    btnExecute: TPanel;
    btnLoad: TPanel;
    EditorDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    MemoOutput: TMemo;
    miArchivo: TMenuItem;
    miCargarBat: TMenuItem;
    miConsola: TMenuItem;
    miConfiguracion: TMenuItem;
    miConfigurarEditor: TMenuItem;
    miDefinirValoresDefault: TMenuItem;
    miEliminarValoresDefault: TMenuItem;
    miEditarBat: TMenuItem;
    miLimpiarConsola: TMenuItem;
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
    procedure btnExecuteClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnClearOutputClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure miConfigurarEditorClick(Sender: TObject);
    procedure miDefinirValoresDefaultClick(Sender: TObject);
    procedure miEliminarValoresDefaultClick(Sender: TObject);
    procedure miResetearValoresClick(Sender: TObject);
    procedure miSalirClick(Sender: TObject);
    procedure miSoloPrecomentadasClick(Sender: TObject);
    procedure ProcessTimerTimer(Sender: TObject);
    procedure ScrollBox1Resize(Sender: TObject);
  private
    FBatchFileName: string;
    FConfigFileName: string;
    FEditorPath: string;
    FExecuteIcon: TImage;
    FExecuteLabel: TLabel;
    FInitialLoadDone: Boolean;
    FLastBatchDir: string;
    FOnlyPrecommentedVariables: Boolean;
    FProcess: TProcess;
    FProcessStart: TDateTime;
    FProcessTimer: TTimer;
    FStartupDir: string;
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
    function CmdQuote(const S: string): string;
    procedure DefineVariableAsDefault(AItem: TVariableItem);
    procedure EditBatchFile;
    function ExtractAssignment(const Line: string; out VarName, VarValue: string): Boolean;
    function ExtractTaggedDefault(const Line: string; out VarName, VarValue: string): Boolean;
    function FormatElapsed(const AStart, AFinish: TDateTime): string;
    procedure LayoutActionButtons;
    procedure LayoutExecuteIcon;
    procedure DefineVisibleVariablesAsDefault;
    procedure LayoutVariableControls;
    procedure LoadDroppedBatchFile(const FileName: string);
    procedure LoadBatchVariables(const FileName: string);
    procedure PositionExecuteButton;
    procedure LoadSettings;
    procedure RemoveVisibleVariableDefaults;
    procedure RemoveVariableDefault(AItem: TVariableItem);
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
  FUpdatingVariableControls := False;
  FOnlyPrecommentedVariables := False;
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
  pnlActions.Color := RGBToColor(232, 222, 204);
  ScrollBox1.Color := RGBToColor(232, 222, 204);
  StatusBar1.Color := RGBToColor(219, 205, 179);
  MemoOutput.Font.Color := RGBToColor(143, 255, 186);
  btnLoad.Caption := 'Abrir...';
  btnEditBatch.Caption := '✎ Editar';
  btnLoad.Color := RGBToColor(245, 239, 226);
  btnLoad.Alignment := taCenter;
  btnLoad.BevelOuter := bvNone;
  btnLoad.Cursor := crHandPoint;
  btnLoad.ParentBackground := False;
  btnLoad.Font.Name := 'Segoe UI';
  btnLoad.Font.Size := 10;
  btnLoad.Font.Color := RGBToColor(60, 49, 35);
  btnEditBatch.Color := RGBToColor(245, 239, 226);
  btnEditBatch.Alignment := taCenter;
  btnEditBatch.BevelOuter := bvNone;
  btnEditBatch.Cursor := crHandPoint;
  btnEditBatch.ParentBackground := False;
  btnEditBatch.Font.Name := 'Segoe UI';
  btnEditBatch.Font.Size := 10;
  btnEditBatch.Font.Color := RGBToColor(60, 49, 35);
  btnEditBatch.Caption := 'Editar';
  btnExecute.Caption := '▶';
  btnExecute.Font.Style := [fsBold];
  btnExecute.Font.Size := 11;
  btnExecute.Font.Name := 'Segoe UI';
  btnExecute.Font.Color := RGBToColor(60, 49, 35);
  btnExecute.Caption := '';
  btnExecute.Height := 60;
  btnExecute.Width := 72;
  btnExecute.Color := RGBToColor(219, 205, 179);
  btnExecute.Alignment := taCenter;
  btnExecute.BevelOuter := bvNone;
  btnExecute.Cursor := crHandPoint;
  btnExecute.ParentBackground := False;
  btnExecute.Hint := 'Ejecutar';
  btnExecute.ShowHint := True;
  miConfiguracion.Caption := 'Configuración';
  CreateAppIcon;
  CreateExecuteIcon;
  LayoutActionButtons;
  LoadSettings;
  miSoloPrecomentadas.Checked := FOnlyPrecommentedVariables;
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
  LayoutActionButtons;
  LayoutVariableControls;
  PositionExecuteButton;
  if FileExists(FBatchFileName) then
    LoadBatchVariables(FBatchFileName);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if FUpdatingVariableControls then
    Exit;
  LayoutActionButtons;
  LayoutVariableControls;
  PositionExecuteButton;
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
  SetStatus('Consola limpia');
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

  FProcess := Proc;
  FProcessStart := Now;
  MemoOutput.Clear;
  MemoOutput.Lines.Add('Inicio: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', FProcessStart));
  MemoOutput.Lines.Add('Archivo: ' + FBatchFileName);
  if FVariables.Count = 0 then
    MemoOutput.Lines.Add('Ejecución sin reemplazos desde la GUI.');
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
  MemoOutput.Lines.Add('Duración: ' + FormatElapsed(FProcessStart, FinishTime));
  MemoOutput.Lines.Add('Finalizado. Código de salida: ' + IntToStr(FProcess.ExitStatus));
  FreeAndNil(FProcess);
  UpdateRunState(False);
  SetStatus('Finalizado');
  BringSelfToFront;
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

  LayoutExecuteIcon;
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
  if FileExists(FBatchFileName) then
    LoadBatchVariables(FBatchFileName);
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

  LoadBatchVariables(FileName);
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
  LastFile: string;
begin
  Ini := TIniFile.Create(FConfigFileName);
  try
    FEditorPath := Ini.ReadString('General', 'EditorPath', '');
    FLastBatchDir := Ini.ReadString('General', 'LastBatchDir', FStartupDir);
    LastFile := Ini.ReadString('General', 'LastBatchFile', '');
    FOnlyPrecommentedVariables := Ini.ReadBool('General', 'OnlyPrecommentedVariables', False);
    FBatchFileName := LastFile;
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
begin
  Ini := TIniFile.Create(FConfigFileName);
  try
    Ini.WriteString('General', 'EditorPath', FEditorPath);
    Ini.WriteString('General', 'LastBatchDir', FLastBatchDir);
    Ini.WriteString('General', 'LastBatchFile', FBatchFileName);
    Ini.WriteBool('General', 'OnlyPrecommentedVariables', FOnlyPrecommentedVariables);
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.miConfigurarEditorClick(Sender: TObject);
begin
  ConfigureEditor;
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

procedure TMainForm.UpdateRunState(const ARunning: Boolean);
begin
  btnExecute.Enabled := not ARunning;
  btnLoad.Enabled := not ARunning;
  btnEditBatch.Enabled := not ARunning;
end;

end.
