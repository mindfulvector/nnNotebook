unit FNotebook;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, IOUtils,
  htmledit, Crypt2, Global, System.ImageList, Vcl.ImgList, Vcl.VirtualImageList,
  Vcl.BaseImageCollection, Vcl.ImageCollection, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ActnCtrls, htmlcomp, Vcl.Controls, Vcl.Tabs,
  Vcl.Graphics, Vcl.Forms, Vcl.Dialogs,
  System.Generics.Collections,
  VCL.TMSFNCTypes, JvExComCtrls, JvToolBar;

type
  ZeroBasedInteger = integer;
  OneBasedInteger = integer;

  TForm1 = class(TForm)
    HtTabSet1: THtTabSet;
    HtmlEditor1: THtmlEditor;
    tSave: TTimer;
    actman: TActionManager;
    actPageNext: TAction;
    actPagePrev: TAction;
    ActionToolBar2: TActionToolBar;
    actNotebookNext: TAction;
    Action3: TAction;
    unvis: TPanel;
    imgcol: TImageCollection;
    imglst: TVirtualImageList;
    StatusBar1: TStatusBar;
    actPageExport: TAction;
    procedure FormCreate(Sender: TObject);
    procedure HtTabSet1Change(Sender: TObject; NewTab: Integer;
      var AllowChange: Boolean);
    procedure actTabsNextExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tSaveTimer(Sender: TObject);
    procedure actPagePrevExecute(Sender: TObject);
    procedure actPageNextExecute(Sender: TObject);
    procedure Action3Execute(Sender: TObject);
    procedure actNotebookNextExecute(Sender: TObject);
    procedure actPageExportExecute(Sender: TObject);
    procedure HtmlEditor1UrlClick(Sender: TElement);
  private
    { Private declarations }
    zbiCurrentNotebook: ZeroBasedInteger;
    zbiCurrentPage: ZeroBasedInteger;
    AppDataDir: string;
    procedure LoadPage(zbiNewNotebook: ZeroBasedInteger;
                       zbiNewPage: ZeroBasedInteger = 0);
    function GetNotebookDir(zbiNotebook: ZeroBasedInteger = -1): string;
    procedure SavePage;
    procedure NextPage;
    procedure PrevPage;
    procedure ExportPage;
    procedure ImportPage;
    procedure LaunchBrowser(URL: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses ShellApi;

procedure TForm1.actPageExportExecute(Sender: TObject);
begin
  ExportPage;
end;

procedure TForm1.actPageNextExecute(Sender: TObject);
begin
  NextPage;
end;

procedure TForm1.actPagePrevExecute(Sender: TObject);
begin
  PrevPage;
end;

procedure TForm1.Action3Execute(Sender: TObject);
begin
  HtTabSet1.SelectNext(true);
end;

procedure TForm1.actNotebookNextExecute(Sender: TObject);
begin
  SavePage;
  HtTabSet1.SelectNext(false);
end;

procedure TForm1.actTabsNextExecute(Sender: TObject);
begin
  SavePage;
  HtTabSet1.SelectNext(True);
end;

procedure TForm1.NextPage;
begin
  SavePage;
  LoadPage(zbiCurrentNotebook, zbiCurrentPage + 1);
end;

procedure TForm1.ExportPage;
begin

end;

procedure TForm1.ImportPage;
begin

end;

procedure TForm1.PrevPage;
begin
  SavePage;
  if zbiCurrentPage > 0 then
  begin
    LoadPage(zbiCurrentNotebook, zbiCurrentPage - 1);
  end;
end;

procedure TForm1.LoadPage(zbiNewNotebook: ZeroBasedInteger;
                          zbiNewPage: ZeroBasedInteger = 0);
var
  notebookDir: string;
  pageFile: string;
begin
  // Temporarily set the new notebook and page for directory creation
  zbiCurrentNotebook := zbiNewNotebook;
  zbiCurrentPage := zbiNewPage;

  // Ensure new notebook directory exists
  notebookDir := GetNotebookDir;
  notebookDir := Format('%s\Notebook%d\', [AppDataDir, zbiNewNotebook + 1]);
  TDirectory.CreateDirectory(notebookDir);

  // Determine the new notebook directory and page file
  pageFile := Format('%s\Page%d.html', [notebookDir, zbiNewPage + 1]);

  // To notify other events that we are loading, set both values to -1
  // so that other events don't accidentally replace something when
  // we start modifying values in a moment
  zbiCurrentNotebook := -1;
  zbiCurrentPage := -1;

  // Check if the page file we calculated above exists or not, then either
  // load it or clear the editor. On first start of the program, load
  // default text into Notebook 1, Page 1.
  if TFile.Exists(pageFile) then
  begin
    HtmlEditor1.LoadFromFile(pageFile);
  end
  else
  begin
    HtmlEditor1.SelectAll;
    HtmlEditor1.DeleteSelection;
    if (zbiNewNotebook = 0) and (zbiNewPage = 0) then
    begin
      HtmlEditor1.LoadFromString('<html><body><p><b>'+
        '<span style="color: #1F497D">Welcome to the Near North Notebook program!</span></b>&nbsp;<br/>'+
        '<small>aka <b>nnNotebook</b>!</small><br>'+
        'Each Notebook tab above is a directory under Documents\nnNotebook. '+
        'Each one can contain unlimited pages.</p>'+
        '<p>It currently can switch between 10 notebooks, auto saves every 5 minutes '+
        'as well as on tab change and on close. '+
        'Rich text formatting is fairly robust, and accessed by selecting a piece of '+
        'text then using the <span style="background-color: #FFFF00">popup</span>.</p>'+
        '<p>Additional features will be added soon, such as file exporting, '+
        'syncronization, and more.</p><p>&nbsp;</p>'+
        '<p style="text-align:justify;">Example: Select this text with your mouse to see the formatting toolbar</p><p>&nbsp;</p>'+
        '</body></html>')
    end;

  end;

  // Now set current notebook since we have finished loading
  zbiCurrentNotebook := zbiNewNotebook;
  zbiCurrentPage := zbiNewPage;

  Statusbar1.Panels[0].Text := (
    Format('Notebook %d, page %d',
      [zbiCurrentNotebook + 1, zbiCurrentPage + 1]));
end;

function TForm1.GetNotebookDir(zbiNotebook: ZeroBasedInteger): string;
begin
  if zbiNotebook = -1 then zbiNotebook := zbiCurrentNotebook;

  // Ensure current notebook dir exists
  Result := Format('%s\Notebook%d\', [AppDataDir, zbiNotebook + 1]);
  TDirectory.CreateDirectory(Result);
end;

procedure TForm1.SavePage;
var
  notebookDir: string;
begin
  notebookDir := GetNotebookDir;
  // Save current page to directory above
  HtmlEditor1.SavetoFile(Format('%s\Page%d.html', [notebookDir, zbiCurrentPage + 1]));
end;

procedure TForm1.LaunchBrowser(URL: string);
begin
  URL := StringReplace(URL, '"', '%22', [rfReplaceAll]);
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
end;

procedure TForm1.tSaveTimer(Sender: TObject);
begin
  SavePage;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePage;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
  editor: THtmlEditor;
  glob: HCkGlobal;
  success: boolean;
begin

  glob := CkGlobal_Create();
  success := CkGlobal_UnlockBundle(glob,'Anything for 30-day trial');
  if (success <> True) then
  begin
    ShowMessage(Format('Unable to load chikcat.dll, error recieved was: "%s"', [CkGlobal__lastErrorText(glob)]));
    Exit;
  end;

  zbiCurrentNotebook := 0;
  zbiCurrentPage := 0;
  // Crete database directory
  AppDataDir := Format('%s\nnNotebook\', [TPath.GetDocumentsPath]);
  TDirectory.CreateDirectory(AppDataDir);

  LoadPage(0);
end;

procedure TForm1.HtmlEditor1UrlClick(Sender: TElement);
begin
  LaunchBrowser(Sender['href']);
end;

procedure TForm1.HtTabSet1Change(Sender: TObject; NewTab: Integer;
  var AllowChange: Boolean);
begin
  SavePage;
  // Takes only the tab to load for now, defaults to page 1
  LoadPage(NewTab);
end;

end.
