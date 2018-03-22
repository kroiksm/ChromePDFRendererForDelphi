UNIT MainUnit;

INTERFACE

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, frxClass, frxDesgn, ExtCtrls, DB, frxDBSet, DBClient;

type
  TMainForm = class(TForm)
    ReportDesigner: TfrxDesigner;
    GroupBox1: TGroupBox;
    ShowDesigner: TButton;
    DSLoadedPDF: TClientDataSet;
    frxDBLoadedPDF: TfrxDBDataset;
    DSLoadedPDFLOADED_DATA: TBlobField;
    edLoadedInDS: TEdit;
    Label1: TLabel;
    procedure ShowDesignerClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
    FReport : TfrxReport;
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

IMPLEMENTATION
uses ShellAPI;

{$R *.dfm}
//------------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
var
   sPDFFile    : string;
   BLOBStream  : TStream;
   F           : TFileStream;
begin
   FReport:=TfrxReport.Create(Self);

   DSLoadedPDF.Active:=false;
   DSLoadedPDF.CreateDataSet();
   DSLoadedPDF.Open();

   sPDFFile:=ExtractFilePath(Application.ExeName)+'sample.pdf';
   if FileExists(sPDFFile) then
   begin
      F:=TFileStream.Create(sPDFFile, fmOpenRead or fmShareDenyNone);
      try

         DSLoadedPDF.Append();
         BLOBStream:=DSLoadedPDF.CreateBlobStream(DSLoadedPDFLOADED_DATA, bmWrite);
         try
            BLOBStream.CopyFrom(F, F.Size);
         finally
            FreeAndNil(BLOBStream);
         end;
         DSLoadedPDF.Post();
      finally
         FreeAndNil(F);
      end;

      edLoadedInDS.Text:=sPDFFile;
      DSLoadedPDF.First();
   end;
end;
//------------------------------------------------------------------------------
procedure TMainForm.ShowDesignerClick(Sender: TObject);
begin
   if not Assigned(FReport.DataSets.Find(frxDBLoadedPDF)) then
      FReport.DataSets.Add(frxDBLoadedPDF);
      
   FReport.DesignReport();
end;
//------------------------------------------------------------------------------
END.
