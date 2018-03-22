UNIT MyFrxPDFPage;

INTERFACE
uses
  Windows, Messages, SysUtils, Classes, Graphics, Menus, Controls, Variants,
  frxClass, frxDsgnIntf, fs_iinterpreter, frxXML, frxXMLSerializer,
  MyPDFRender, MyChromePDFRender;
type
   TMyFrxPDFSource   =
   (
      srcFileFromDisk,
      srcEmbeddedFile,
      srcFileFromDB
   );

   TMyFrxPDFPageView = class(TfrxView)
   private
      FPDFSource        : TMyFrxPDFSource;
      FPDFRender        : TCustomMyPDFRender;
      FVisiblePDFPage   : integer;
      FFileFromDisk     : string;
      FEmbeddedFile     : TCustomMyPDFRender;
      FVectorDrawing    : boolean;
      FAutoRotate       : boolean;
      FCenterInBounds   : boolean;

      function  GetSourceIsEmbeddedFile(): boolean;
      function  GetSourceIsFileFromDB(): boolean;
      function  GetSourceIsFileFromDisk(): boolean;
      procedure SetSourceIsEmbeddedFile(const Value: boolean);
      procedure SetSourceIsFileFromDB(const Value: boolean);
      procedure SetSourceIsFileFromDisk(const Value: boolean);
      procedure SetPDFSource(ANewSource: TMyFrxPDFSource);
      procedure SetEmbeddedFile(const Value: TCustomMyPDFRender);

      function  GetTotalPDFPages(): integer;
      procedure SetVisiblePDFPage(const Value: integer);
      procedure LoadPDFFromSource();
      procedure SetFileFromDisk(const Value: string);

      procedure SetVectorDrawing(const Value: boolean);
      procedure SetAutoRotate(const Value: boolean);
      procedure SetCenterInBounds(const Value: boolean);

      (*
      function  CreateMetafile(): TMetafile;
      *)      
   protected
      procedure AssignTo(Dest: TPersistent); override;
      procedure LoadFromStream(Stream: TStream); override;
      procedure SaveToStream(Stream: TStream;
                             SaveChildren: Boolean;
                             SaveDefaultValues: Boolean); override;

   public
      class function GetDescription(): String; override;

      constructor Create(AOwner: TComponent); override;
      destructor Destroy(); override;

      procedure GetData(); override;
      procedure Draw(Canvas: TCanvas; ScaleX, ScaleY, OffsetX, OffsetY: Extended); override;
   published
      property SourceIsFileFromDisk: boolean read GetSourceIsFileFromDisk write SetSourceIsFileFromDisk;
      property SourceIsEmbeddedFile: boolean read GetSourceIsEmbeddedFile write SetSourceIsEmbeddedFile;
      property SourceIsFileFromDB: boolean read GetSourceIsFileFromDB write SetSourceIsFileFromDB;

      property FileFromDisk: string read FFileFromDisk write SetFileFromDisk;
      property EmbeddedFile: TCustomMyPDFRender read FEmbeddedFile write SetEmbeddedFile;

      property TotalPDFPages: integer read GetTotalPDFPages; 
      property VisiblePDFPage: integer read FVisiblePDFPage write SetVisiblePDFPage;

      property VectorDrawing: boolean read FVectorDrawing write SetVectorDrawing;
      property AutoRotate: boolean read FAutoRotate write SetAutoRotate;
      property CenterInBounds: boolean read FCenterInBounds write SetCenterInBounds;
   published
      property Frame;
      property TagStr;
      property Cursor;

      property DataField;
      property DataSet;
      property DataSetName;
   end;

   TMyFrxPDFPageViewObject = class(TComponent)  // fake component for Delphi's Components-Palette
   end;

   TMyFrxPDFPageViewRTTI = class(TfsRTTIModule)
   public
     constructor Create(AScript : TfsScript); override;
   end;

   TfrxCustomMyPDFRenderProperty=class(TfrxClassProperty)
   public
      function GetValue(): string; override;
      function GetAttributes: TfrxPropertyAttributes; override;
      function Edit(): boolean; override;
   end;

IMPLEMENTATION
uses Dialogs, fqbUtils, frxPrinter;

VAR
  _LogoForFRDesigner : TBitmap;

//##############################################################################
{ TMyFrxPDFPageView }
//##############################################################################
constructor TMyFrxPDFPageView.Create(AOwner: TComponent);
begin
   inherited;

   FVisiblePDFPage:=1;
   FVectorDrawing:=true;
   FAutoRotate:=true;
   FCenterInBounds:=false;

   FPDFRender:=TMyChromePDFRender.Create();
   FEmbeddedFile:=TMyChromePDFRender.Create();

   SetPDFSource(srcFileFromDisk);

   Width:=100;
   Height:=140;
end;
//------------------------------------------------------------------------------
destructor TMyFrxPDFPageView.Destroy();
begin
   FPDFRender.Free();
   FEmbeddedFile.Free();

   inherited;
end;
////////////////////////////////////////////////////////////////////////////////
class function TMyFrxPDFPageView.GetDescription(): String;
begin
   Result:='MyFrxPDFPageView';
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.AssignTo(Dest: TPersistent);
begin
   inherited;

   if Dest is TMyFrxPDFPageView then
      TMyFrxPDFPageView(Dest).FEmbeddedFile.Assign(FEmbeddedFile);
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetEmbeddedFile(const Value: TCustomMyPDFRender);
begin
   FEmbeddedFile.Assign(Value);
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.LoadFromStream(Stream: TStream);
begin
   inherited;
   //...
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SaveToStream(Stream: TStream;
  SaveChildren: Boolean; SaveDefaultValues: Boolean);
begin
   inherited;
   //...
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMyFrxPDFPageView.SetPDFSource(ANewSource: TMyFrxPDFSource);
begin
   FPDFSource:=ANewSource;
end;
//------------------------------------------------------------------------------
function TMyFrxPDFPageView.GetSourceIsFileFromDisk(): boolean;
begin
   Result:=(FPDFSource=srcFileFromDisk);
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetSourceIsFileFromDisk(const Value: boolean);
begin
   if Value then SetPDFSource(srcFileFromDisk);
end;
//------------------------------------------------------------------------------
function TMyFrxPDFPageView.GetSourceIsEmbeddedFile(): boolean;
begin
   Result:=(FPDFSource=srcEmbeddedFile);
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetSourceIsEmbeddedFile(const Value: boolean);
begin
   if Value then SetPDFSource(srcEmbeddedFile);
end;
//------------------------------------------------------------------------------
function TMyFrxPDFPageView.GetSourceIsFileFromDB(): boolean;
begin
   Result:=(FPDFSource=srcFileFromDB);
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetSourceIsFileFromDB(const Value: boolean);
begin
   if Value then SetPDFSource(srcFileFromDB);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMyFrxPDFPageView.SetFileFromDisk(const Value: string);
begin
   FFileFromDisk:=Value;
end;
//------------------------------------------------------------------------------
function TMyFrxPDFPageView.GetTotalPDFPages(): integer;
begin
   Result:=FPDFRender.PagesCount;
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetVisiblePDFPage(const Value: integer);
begin
   FVisiblePDFPage:=Value;
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetVectorDrawing(const Value: boolean);
begin
   FVectorDrawing:=Value;
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetAutoRotate(const Value: boolean);
begin
  FAutoRotate := Value;
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.SetCenterInBounds(const Value: boolean);
begin
  FCenterInBounds := Value;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMyFrxPDFPageView.LoadPDFFromSource();
var
   mem   : TMemoryStream;
begin
   FPDFRender.Clear();

   case FPDFSource of
      srcFileFromDisk: FPDFRender.LoadPDFFromFile(FFileFromDisk);
      srcEmbeddedFile: FPDFRender.Assign(FEmbeddedFile);
      srcFileFromDB:
         begin
            FPDFRender.Clear();
            if IsDataField and DataSet.IsBlobField(DataField) then
            begin
               mem:=TMemoryStream.Create();
               try
                  DataSet.AssignBlobTo(DataField, mem);
                  mem.Position:=0;
                  FPDFRender.LoadPDFFromStream(mem);
               finally
                  FreeAndNil(mem);
               end;
            end;
         end;
      else raise EMyPDFRendererError.Create('PDFSourceType = ?????');
   end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMyFrxPDFPageView.GetData();
begin
   inherited;

   LoadPDFFromSource();
end;
//------------------------------------------------------------------------------

(*
function TMyFrxPDFPageView.CreateMetafile(): TMetafile;
var
   hPrinterCanvas : THandle;
   EMFCanvas      : TMetafileCanvas;
   R              : TRect;
begin
   if frxPrinters.HasPhysicalPrinters then
      hPrinterCanvas := frxPrinters.Printer.Canvas.Handle
   else
      hPrinterCanvas := GetDC(0);

   Result:=TMetafile.Create();
   Result.Width := Round(Width * GetDeviceCaps(hPrinterCanvas, LOGPIXELSX) / 96);
   Result.Height := Round(Height * GetDeviceCaps(hPrinterCanvas, LOGPIXELSY) / 96);

   EMFCanvas := TMetafileCanvas.Create(Result, hPrinterCanvas);
   try
      //R:=Rect(0, 0, Result.Width, Result.Height);

      R:=Rect(0, 0, Round(Width * 1440 / 96), Round(Height * 1440 / 96));

      FPDFRender.RenderPDFToCanvas(EMFCanvas, R, FVisiblePDFPage, 600, 600,
                                   FAutoRotate, FCenterInBounds)
   finally
      FreeAndNil(EMFCanvas);
   end;

   if not frxPrinters.HasPhysicalPrinters then
      ReleaseDC(0, hPrinterCanvas);
end;
*)
//------------------------------------------------------------------------------
procedure GetPrinterDPI(out ADPIX: integer; out ADPIY: integer);
var
   hPrinterCanvas : THandle;
begin
   if frxPrinters.HasPhysicalPrinters then
   begin
      hPrinterCanvas := frxPrinters.Printer.Canvas.Handle;
      ADPIX:=GetDeviceCaps(hPrinterCanvas, LOGPIXELSX);
      ADPIY:=GetDeviceCaps(hPrinterCanvas, LOGPIXELSY);
   end
   else
   begin
      ADPIX := 600;
      ADPIY := 600;
   end;
end;
//------------------------------------------------------------------------------
procedure TMyFrxPDFPageView.Draw(Canvas: TCanvas; ScaleX, ScaleY, OffsetX,
  OffsetY: Extended);
var
   R     : TRect;
   bmp   : Graphics.TBitmap;
   (*
   EMF   : TMetafile;
   *)
   iDPIX : integer;
   iDPIY : integer;
begin
   BeginDraw(Canvas, ScaleX, ScaleY, OffsetX, OffsetY);

   GetPrinterDPI(iDPIX, iDPIY);

   DrawBackground();
   try
      try
         LoadPDFFromSource();

         if not FPDFRender.IsEmpty() then
         begin
            R:=Rect(FX, FY, FX1, FY1);

            if FVectorDrawing then
            begin
               FPDFRender.RenderPDFToCanvas(Canvas, R, FVisiblePDFPage, iDPIX, iDPIY,
                                            FAutoRotate, FCenterInBounds)
            end
            else
            begin
               bmp:=TBitmap.Create();
               try
                  bmp.Width:=FDX;
                  bmp.Height:=FDY;

                  FPDFRender.RenderPDFToBitmap(bmp, FVisiblePDFPage, iDPIX, iDPIY,
                                               FAutoRotate, FCenterInBounds,
                                               false);
                  Canvas.Draw(FX, FY, bmp);
               finally
                  FreeAndNil(bmp);
               end;
               (*
               EMF:= CreateMetafile();
               try
                  Canvas.StretchDraw(Rect(FX, FY, FX1, FY1), EMF);
               finally
                  FreeAndNil(EMF);
               end;
               *)
            end;
         end
         else
         if IsDesigning then
         begin
            Canvas.Draw(FX, FY, _LogoForFRDesigner);
         end;
      except
         on E: Exception do
         begin
            //Draw an Exception-Text
            Canvas.Font.Color:=clRed;
            Canvas.TextOut(FX, FY, E.Message);
         end;
      end;
   finally
      DrawFrame();
   end;
end;
//##############################################################################
{ TMyFrxPDFPageViewRTTI }
//##############################################################################
constructor TMyFrxPDFPageViewRTTI.Create(AScript: TfsScript);
begin
   inherited;

   AScript.AddClass(TMyFrxPDFPageView, 'TMyFrxPDFPageView');
end;

//##############################################################################
{ TfrxCustomMyPDFRenderProperty }
//##############################################################################
function TfrxCustomMyPDFRenderProperty.GetValue(): string;
var
   Render   : TCustomMyPDFRender;
begin
   Render:=TCustomMyPDFRender(GetOrdValue());

   if Render.IsEmpty() then
      Result:='< empty >'
   else
      Result:='PDF: '+IntToStr(Render.SizeInBytes div 1024)+' kB';
end;
//------------------------------------------------------------------------------
function TfrxCustomMyPDFRenderProperty.GetAttributes(): TfrxPropertyAttributes;
begin
   Result:=[paDialog, paReadOnly];
end;
//------------------------------------------------------------------------------
function  YesNoDialog(const AMessage, ACaption: string;
  ADefaultVal:boolean):boolean;
var
   iButtonDef  : integer;
begin
   if ADefaultVal then
      iButtonDef:=MB_DEFBUTTON1
   else
      iButtonDef:=MB_DEFBUTTON2;

   //Result:=Application.MessageBox(PChar(sMessage),PChar(sCaption),
   Result:=Windows.MessageBox(0,PChar(AMessage),PChar(ACaption),
                              iButtonDef or MB_YESNO or MB_ICONQUESTION
                              )=IDYES;

end;
//------------------------------------------------------------------------------
function TfrxCustomMyPDFRenderProperty.Edit(): boolean;
var
   dlg         : TOpenDialog;
   Render      : TCustomMyPDFRender;
   bDoSearch   : boolean;
begin
   Render:=TCustomMyPDFRender(GetOrdValue());

   bDoSearch:=true;
   if not Render.IsEmpty() then
   begin
      if YesNoDialog('Do you want to clear embedded-file?','Clear',false) then
      begin
         Render.Clear();
         bDoSearch:=false;   
      end;
   end;

   if bDoSearch then
   begin
      dlg:=TOpenDialog.Create(nil);
      try
         dlg.Filter:='PDF files (*.pdf)|*.pdf';
         dlg.FileName:='';

         Result:=dlg.Execute();
         Render.LoadPDFFromFile(dlg.FileName);

         if Component is TMyFrxPDFPageView then
            TMyFrxPDFPageView(Component).SourceIsEmbeddedFile:=true;
      finally
         dlg.Free();
      end;
   end;
end;
//##############################################################################
procedure LoadLogoForFRDesigner(); //better as from Resource
const
   LOGO_BMP_FR_DESIGNER_BASE64 =
      'Qk32AAAAAAAAAHYAAAAoAAAAEAAAABAAAAABAAQAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAA'+
      'AAAAAAAAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAICAgADAwMAAAAD/AAD/AAAA//8A/wAA'+
      'AP8A/wD//wAA////ADM4iIiIiIiDMwAAAAAAAIMzD//////wgzMP//////CDMw//////8I'+
      'MzD//////wgzMP//////CDMw//////8IMzD//////wg5mZmZmZ//CDmZmZmZn/8IOZmZmZ'+
      'mf/wg5mZmZmZAAAzmZmZmZkPAzMzD////wAzMzMAAAAAAzMz';
var
   mem         : TMemoryStream;
   sDecoded    : string;
begin
   mem:=TMemoryStream.Create();
   try
      sDecoded:=fqbBase64Decode(LOGO_BMP_FR_DESIGNER_BASE64);
      mem.Write(PChar(sDecoded)^, Length(sDecoded));
      mem.Position:=0;

      _LogoForFRDesigner.LoadFromStream(mem);
   finally
      FreeAndNil(mem);
   end;

   _LogoForFRDesigner.Transparent:=true;
   _LogoForFRDesigner.TransparentColor:=
      _LogoForFRDesigner.Canvas.Pixels[0,_LogoForFRDesigner.Height-1];
end;
//------------------------------------------------------------------------------

INITIALIZATION
   _LogoForFRDesigner:=TBitmap.Create();
   LoadLogoForFRDesigner();

   frxObjects.RegisterObject1(TMyFrxPDFPageView, _LogoForFRDesigner);
   fsRTTIModules.Add(TMyFrxPDFPageViewRTTI);
   //--- maybe: frxHideProperties(TMyFrxPDFPageView, 'TotalPDFPages');
   
   frxPropertyEditors.Register(
      TypeInfo(TCustomMyPDFRender),
      nil,
      '',
      TfrxCustomMyPDFRenderProperty
      );
FINALIZATION
  frxObjects.Unregister(TMyFrxPDFPageView);
  _LogoForFRDesigner.Free;
END.
