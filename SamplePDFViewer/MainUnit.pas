UNIT MainUnit;

INTERFACE

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, ComCtrls, MyPDFRender, MyChromePDFRender;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    ScrollBox1: TScrollBox;
    imgPage: TImage;
    btnGoPrevPage: TSpeedButton;
    btnGoNextPage: TSpeedButton;
    btnOpen: TSpeedButton;
    btnZoomIn: TSpeedButton;
    btnZoomOut: TSpeedButton;
    StatusBar: TStatusBar;
    dlgOpenPDFFile: TOpenDialog;
    panPageNumber: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnGoPrevPageClick(Sender: TObject);
    procedure btnGoNextPageClick(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
  private
    { Private-Deklarationen }
    FFormFirstActivated    : boolean;
    FPDFRenderer           : TMyChromePDFRender;
    FCurrPageNr            : integer;
    FCurrDpi               : integer;

    procedure ReloadCurrPage();
    procedure OpenPDFFile(const AFileName: string);
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

IMPLEMENTATION

{$R *.dfm}
////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.FormCreate(Sender: TObject);
begin
   FFormFirstActivated := false;
   FPDFRenderer := TMyChromePDFRender.Create();
end;
//------------------------------------------------------------------------------
procedure TMainForm.FormActivate(Sender: TObject);
var
   sSamplePDFFile : string;
begin
   if not FFormFirstActivated then
   begin
      FFormFirstActivated:=true;

      sSamplePDFFile:=ExtractFilePath(Application.ExeName)+'sample.pdf';
      OpenPDFFile(sSamplePDFFile);
   end;
end;
//------------------------------------------------------------------------------
procedure TMainForm.FormDestroy(Sender: TObject);
begin
   FPDFRenderer.Free();
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.ReloadCurrPage();
begin
   FPDFRenderer.RenderPDFToBitmap(imgPage.Picture.Bitmap, // ABitmap
                                  FCurrPageNr,  // APageNumber
                                  FCurrDpi,     // ADpiX
                                  FCurrDpi,     // ADpiY
                                  false,        // ADoAutoRotate
                                  false,        // ADoCenterInBounds
                                  true);        // ADoAutoSizeBitmap

   panPageNumber.Caption:='Page '+IntToStr(FCurrPageNr)+' '+
                          'from '+IntToStr(FPDFRenderer.PagesCount);
end;
//------------------------------------------------------------------------------
procedure TMainForm.OpenPDFFile(const AFileName: string);
begin
   if not FileExists(AFileName) then
      ShowMessage('File "'+AFileName+'" not found')
   else
   begin
      FPDFRenderer.LoadPDFFromFile(AFileName);
      StatusBar.SimpleText:=' '+AFileName;
      FCurrPageNr:=1;
      FCurrDpi:=50;

      ReloadCurrPage();     
   end;
end;
//------------------------------------------------------------------------------
procedure TMainForm.btnOpenClick(Sender: TObject);
begin
   if dlgOpenPDFFile.Execute() then
      OpenPDFFile(dlgOpenPDFFile.FileName);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMainForm.btnGoPrevPageClick(Sender: TObject);
begin
   if FCurrPageNr>1 then
      FCurrPageNr:=FCurrPageNr-1;

   ReloadCurrPage();
end;
//------------------------------------------------------------------------------
procedure TMainForm.btnGoNextPageClick(Sender: TObject);
begin
   if FCurrPageNr<FPDFRenderer.PagesCount then
      FCurrPageNr:=FCurrPageNr+1;

   ReloadCurrPage();
end;
//------------------------------------------------------------------------------
procedure TMainForm.btnZoomInClick(Sender: TObject);
begin
   FCurrDpi:=FCurrDpi+50;
   ReloadCurrPage();
end;
//------------------------------------------------------------------------------
procedure TMainForm.btnZoomOutClick(Sender: TObject);
begin
   if FCurrDpi>50 then
   begin
      FCurrDpi:=FCurrDpi-50;
      ReloadCurrPage();
   end;
end;
////////////////////////////////////////////////////////////////////////////////

END.
