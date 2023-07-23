unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonDeselect: TButton;
    ButtonSave: TButton;
    ButtonSelect_U: TButton;
    ButtonReInit: TButton;
    ButtonCleanCache: TButton;
    ButtonRemoveSelected: TButton;
    ButtonAddSelected: TButton;
    ButtonClear: TButton;
    ButtonSelect_UTX: TButton;
    ButtonSelect_USX: TButton;
    ButtonSelect_UAX: TButton;
    ButtonSelect_UKX: TButton;
    ButtonSelect_ROM: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ListBoxLog: TListBox;
    ListBoxCurrent: TListBox;
    ListBoxWipeList: TListBox;
    procedure ButtonDeselectClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonAddSelectedClick(Sender: TObject);
    procedure ButtonCleanCacheClick(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonReInitClick(Sender: TObject);
    procedure ButtonRemoveSelectedClick(Sender: TObject);
    procedure ButtonSelect_ROMClick(Sender: TObject);
    procedure ButtonSelect_UAXClick(Sender: TObject);
    procedure ButtonSelect_UClick(Sender: TObject);
    procedure ButtonSelect_UKXClick(Sender: TObject);
    procedure ButtonSelect_USXClick(Sender: TObject);
    procedure ButtonSelect_UTXClick(Sender: TObject);
    procedure Log(LogText: string);
    function StringEndsWith(const Str, SubStr: string): Boolean;
    procedure SelectionFilter(ExtStr:String);
    procedure InitList();
    procedure ReadCacheIni();
    procedure ReadWipeIni();
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  WorkingDir: string;
  INI_CacheIni: TIniFile;
  INI_WipeIni:  TIniFile;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.Log(LogText: string);
begin
  Form1.ListBoxLog.AddItem(LogText, nil);
  Form1.ListBoxLog.ItemIndex := Form1.ListBoxLog.Items.Count - 1;
end;

function TForm1.StringEndsWith(const Str, SubStr: string): Boolean;
var
  StrLength, SubStrLength: Integer;
begin
  StrLength := Length(Str);
  SubStrLength := Length(SubStr);

  if StrLength >= SubStrLength then
    Result := Copy(Str, StrLength - SubStrLength + 1, SubStrLength) = SubStr
  else
    Result := False;
end;

procedure TForm1.SelectionFilter(ExtStr:String);
var
  i:Integer;
begin
  Log('selecting all ' + ExtStr + ' files');
  for i:=0 to ListBoxCurrent.Count - 1 do begin
      if StringEndsWith(ListBoxCurrent.Items[i], ExtStr) then
      begin
        ListBoxCurrent.Selected[i]:=True;
      end;
  end;
end;

procedure TForm1.ButtonAddSelectedClick(Sender: TObject);
var
  i,j: integer;
  selectedItems: TStringList;
begin
  selectedItems := TStringList.Create;

  try
    ListBoxCurrent.Items.BeginUpdate;
    try
      for i := 0 to ListBoxCurrent.Count - 1 do
      begin
        if ListBoxCurrent.Selected[i] then
          selectedItems.Add(ListBoxCurrent.Items[i]);
      end;
    finally
      ListBoxCurrent.Items.EndUpdate;
    end;
    if selectedItems.Count > 0 then
      begin
        for i:=0 to selectedItems.Count - 1 do begin
          ListBoxWipeList.Items.Add(selectedItems.Strings[i]);
        end;
      end
    else
      Log('nothing selected. select something to add it.');
  finally
    selectedItems.Free;
  end;

  //Remove duplicates
  for i := ListBoxWipeList.Items.Count - 1 downto 0 do
  begin
    for j := i - 1 downto 0 do
    begin
      if ListBoxWipeList.Items[i] = ListBoxWipeList.Items[j] then
      begin
        ListBoxWipeList.Items.Delete(i);
        Break;
      end;
    end;
  end;

end;

procedure TForm1.ButtonSaveClick(Sender: TObject);
var
  userChoice:TModalResult;
  i:Integer;
begin
    userChoice := MessageDlg('Are you sure you want to save to wipe.ini?', mtConfirmation, [mbYes, mbNo], 0);

  if userChoice <> mrYes then
    Exit;

  Log('overwriting wipe.ini');

  INI_WipeIni.EraseSection('Wipe');

  for i:= 0 to ListBoxWipeList.Count - 1 do begin
    INI_WipeIni.WriteString('Wipe',IntToStr(i+1),ListBoxWipeList.Items[i]);
  end;

  INI_WipeIni.UpdateFile;

end;

procedure TForm1.ButtonDeselectClick(Sender: TObject);
begin
  Log('deselecting all');
  ListBoxCurrent.ClearSelection;
end;

procedure TForm1.ButtonCleanCacheClick(Sender: TObject);
var
  userChoice:TModalResult;
  i,j:Integer;
  Keys:TStringList;
begin
  userChoice := MessageDlg('Are you sure you want delete the wipelisted items from your cache?', mtConfirmation, [mbYes, mbNo], 0);

  if userChoice <> mrYes then
    Exit;

  Log('cleaning cache');

  Keys:=TStringList.Create;
  INI_CacheIni.ReadSection('Cache',Keys);

  for i:= 0 to ListBoxWipeList.Count - 1 do begin
    for j:= 0 to Keys.Count - 1 do begin
      if INI_CacheIni.ReadString('Cache',Keys[j],'') = ListBoxWipeList.Items[i] then begin

        Log('Deleting: ' + INI_CacheIni.ReadString('Cache',Keys[j],'---');
        INI_CacheIni.DeleteKey('Cache',Keys[j]);
        DeleteFile(WorkingDir + '\Cache\' + Keys[j] + '.uxx');
      end;
    end;
  end;

  INI_CacheIni.UpdateFile;

  ListBoxCurrent.Clear;

  ReadCacheIni();
end;

procedure TForm1.ButtonClearClick(Sender: TObject);
var
  userChoice:TModalResult;
begin
    userChoice := MessageDlg('Are you sure you want to clear the Wipelist?', mtConfirmation, [mbYes, mbNo], 0);

  if userChoice <> mrYes then
    Exit;

  ListBoxWipeList.Clear;;

  Log('cleared wipelist');

end;

procedure TForm1.ButtonReInitClick(Sender: TObject);
var userChoice:TModalResult;
begin
  userChoice := MessageDlg('Are you sure you want to Re-Init?' + LineEnding +
                           'This will also clear the Wipelist.', mtConfirmation, [mbYes, mbNo], 0);

  if userChoice <> mrYes then
    Exit;

  ListBoxWipeList.Clear;;

  Log('cleared wipelist');



  if Assigned(INI_CacheIni) then begin
    INI_CacheIni.Free;
    Log('freed cache.ini object');
  end;

  if Assigned (INI_WipeIni) then begin
    INI_WipeIni.Free;
    Log('freed wipe.ini object');
  end;

  Log('running re-init');
  InitList();
end;

procedure TForm1.ButtonRemoveSelectedClick(Sender: TObject);
begin
  ListBoxWipeList.DeleteSelected;
end;

procedure TForm1.ButtonSelect_ROMClick(Sender: TObject);
begin
  SelectionFilter('.rom');
end;

procedure TForm1.ButtonSelect_UAXClick(Sender: TObject);
begin
  SelectionFilter('.uax');
end;

procedure TForm1.ButtonSelect_UClick(Sender: TObject);
begin
  SelectionFilter('.u');
end;

procedure TForm1.ButtonSelect_UKXClick(Sender: TObject);
begin
  SelectionFilter('.ukx');
end;

procedure TForm1.ButtonSelect_USXClick(Sender: TObject);
begin
  SelectionFilter('.usx');
end;

procedure TForm1.ButtonSelect_UTXClick(Sender: TObject);
begin
  SelectionFilter('.utx');
end;

procedure TForm1.ReadCacheIni();
var
  i: integer;
  INI_CacheValues: TStringList;
begin
  if not FileExists(WorkingDir + '\Cache\cache.ini') then
  begin
    ShowMessage('cache.ini was not found.Exiting.');
    Halt;
  end;
  INI_CacheIni := TIniFile.Create(WorkingDir + '\Cache\cache.ini');

  if not Assigned(INI_CacheIni) then
  begin
    ShowMessage('Something went wrong reading cache.ini. Exiting.');
    Halt;
  end;
  INI_CacheValues := TStringList.Create;
  INI_CacheIni.ReadSectionValues('Cache', INI_CacheValues);

  Log('listing current cache contents');

  for i := 0 to INI_CacheValues.Count - 1 do
  begin
    ListBoxCurrent.AddItem(INI_CacheValues.ValueFromIndex[i], nil);
  end;

  INI_CacheValues.Free;
end;

procedure TForm1.ReadWipeIni();
var
  sectionValues:TStringList;
  i:Integer;
begin
  //if not Assigned(INI_WipeIni) then begin
  //  ShowMessage('ERROR: wipe.ini was found but is also already assigned? Exiting.');
  //  Halt;
  //end;

  INI_WipeIni:=TIniFile.Create(WorkingDir + '\wipe.ini');

  sectionValues:=TStringList.Create;

  INI_WipeIni.ReadSectionValues('Wipe',sectionValues);

  for i:=0 to sectionValues.Count - 1 do begin
    ListBoxWipeList.Items.Add(sectionValues.ValueFromIndex[i]);
  end;



end;

procedure TForm1.InitList();
begin
  Log('--- Initializing ---');
  Log('check working directory');
  WorkingDir := GetCurrentDir;
  Log('    dir: ' + WorkingDir);

  Log('finding cache folder:');
  if not DirectoryExists(WorkingDir + '\Cache') then
  begin
    DefaultMessageBox('Cache folder not found!' + LineEnding +
      'Make sure you are running this in the Killing Floor directory',
      'Error', 0);
    Halt;
  end
  else
    Log('    found it!');

  Log('finding cache.ini');
  if not FileExists(WorkingDir + '\Cache\cache.ini') then
  begin
    DefaultMessageBox('cache.ini not found!' + LineEnding +
      'Make sure that cache.ini is present in the cache folder', 'Error', 0);
    Halt;
  end
  else
    Log('    found it!');

  Log('clearing lists');
  ListBoxCurrent.Items.Clear;
  ListBoxWipeList.Items.Clear;

  Log('reading cache.ini');
  ReadCacheIni();


  Log('finding wipe.ini');
  if not FileExists(WorkingDir + '\wipe.ini') then
  begin
    Log('wipe.ini not foud. creating...');
    INI_WipeIni:=TIniFile.Create(WorkingDir + '\wipe.ini');
  end
  else
  begin
    Log('    found it!');
    ReadWipeIni();
  end;



end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitList();
end;

end.


