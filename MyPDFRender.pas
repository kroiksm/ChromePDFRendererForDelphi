//Wrote by Simon Kroik, 06.2013-03.2018
//Tested with Delphi 6
UNIT MyPDFRender;

INTERFACE
uses Windows, SysUtils, Graphics, Classes, DB;

type
   EMyPDFRendererError = class(Exception)
   end;

type   
   TCustomMyPDFRender = class(TPersistent)
   private
      FFullFileName        : string;

      procedure ReadDataProp(Stream: TStream);
      procedure WriteDataProp(Stream: TStream);
   protected
      procedure InitEmptyFields(); virtual;

      function GetPagesCount(): integer; virtual; abstract;
      function GetSizeInBytes(): int64; virtual; abstract;

      procedure AssignTo(Dest: TPersistent); override;
      procedure DefineProperties(Filer: TFiler); override;

      procedure RaiseIfPageNumberWrong(APageNumber: integer);
   public
      constructor Create(); virtual;
      destructor Destroy(); override;

      procedure Clear(); virtual; abstract;

      function SavePDFToStream(AStream: TStream): boolean; virtual; abstract;
      function LoadPDFFromStream(AStream: TStream; ALength: int64=0): boolean; virtual; abstract;

      function LoadPDFFromFile(const APDFFile: string): boolean;
      function LoadPDFFromDB(AField: TField): boolean;
      function LoadPDFFromString(const APDFAsStringBuffer: string): boolean;

      function GetPageSizeInCm(APageNumber: integer;
                               var AWidthCm: extended;
                               var AHeightCm: extended): boolean; virtual; abstract;

      function GetPageSizeInPixel(APageNumber: integer;
                                  ADpiX: integer;
                                  ADpiY: integer;
                                  var AWidth: integer;
                                  var AHeight: integer): boolean; virtual; abstract;

      function RenderPDFToDC(ADC: HDC;
                             ARectLeft: integer;
                             ARectTop: integer;
                             ARectWidth: integer;
                             ARectHeight: integer;
                             APageNumber: integer;
                             ADpiX: integer;
                             ADpiY: integer;
                             ADoFitToBounds: boolean;
                             ADoStretchToBounds: boolean;
                             ADoKeepAspectRatio: boolean;
                             ADoCenterInBounds: boolean;
                             ADoAutoRotate: boolean): boolean; virtual; abstract;                                  

      function RenderPDFToCanvas(ACanvas: TCanvas;
                                 ARect: TRect;
                                 APageNumber: integer;
                                 ADpiX: integer;
                                 ADpiY: integer;
                                 ADoAutoRotate: boolean;
                                 ADoCenterInBounds: boolean): boolean; virtual;

      function RenderPDFToBitmap(ABitmap: Graphics.TBitmap;
                                 APageNumber: integer;
                                 ADpiX: integer;
                                 ADpiY: integer;
                                 ADoAutoRotate: boolean;
                                 ADoCenterInBounds: boolean;
                                 ADoAutoSizeBitmap: boolean): boolean; virtual;

      function IsEmpty(): boolean;
   public
      property PagesCount: integer read GetPagesCount;
      property FullFileName: string read FFullFileName;
      property SizeInBytes: int64 read GetSizeInBytes;
   end;

   TCustomMyPDFRenderClass = class of TCustomMyPDFRender;

//uitils   
   function CmToInch(ACm: extended): extended;
   function InchToCm(AInch: extended): extended;
   function CmToPixel(ACm: extended; ADPI: integer): integer;


IMPLEMENTATION

////////////////////////////////////////////////////////////////////////////////
function CmToInch(ACm: extended): extended;
begin
   Result:=ACm/2.54;
end;
//------------------------------------------------------------------------------
function InchToCm(AInch: extended): extended;
begin
   Result:=AInch*2.54;
end;
//------------------------------------------------------------------------------
function CmToPixel(ACm: extended; ADPI: integer): integer;
var
   fInch : extended;
begin
   fInch:=CmToInch(ACm);
   Result:=Round(ADPI*fInch);
end;
//##############################################################################
{ TCustomMyPDFRender }
//##############################################################################
constructor TCustomMyPDFRender.Create();
begin
   InitEmptyFields();
end;
//------------------------------------------------------------------------------
destructor TCustomMyPDFRender.Destroy();
begin
   Clear();
   
   inherited;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TCustomMyPDFRender.InitEmptyFields();
begin
   FFullFileName:='';
end;
//------------------------------------------------------------------------------
function TCustomMyPDFRender.IsEmpty(): boolean;
begin
   Result:=(GetPagesCount() = 0);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TCustomMyPDFRender.DefineProperties(Filer: TFiler);
begin
   inherited;

   Filer.DefineBinaryProperty('Data',
                              ReadDataProp, WriteDataProp,
                              not IsEmpty());
end;
//------------------------------------------------------------------------------
procedure TCustomMyPDFRender.ReadDataProp(Stream: TStream);
begin
   LoadPDFFromStream(Stream);
end;
//------------------------------------------------------------------------------
procedure TCustomMyPDFRender.WriteDataProp(Stream: TStream);
begin
   SavePDFToStream(Stream);
end;
////////////////////////////////////////////////////////////////////////////////
procedure TCustomMyPDFRender.AssignTo(Dest: TPersistent);
var
   DstRender   : TCustomMyPDFRender;
begin
   if Dest is TCustomMyPDFRender then
   begin
      DstRender:=TCustomMyPDFRender(Dest);

      DstRender.Clear();
      DstRender.FFullFileName:=FFullFileName;
   end;
end;
//------------------------------------------------------------------------------
function TCustomMyPDFRender.LoadPDFFromFile(const APDFFile: string): boolean;
var
   F  : TFileStream;
begin
   if Trim(APDFFile)<>'' then
   begin
      F:=TFileStream.Create(APDFFile, fmOpenRead or fmShareDenyNone);
      try
         Result:=LoadPDFFromStream(F);

         if Result then
            FFullFileName:=APDFFile;
      finally
         FreeAndNil(F);
      end;
   end
   else
      Result:=false;
end;
//------------------------------------------------------------------------------
function TCustomMyPDFRender.LoadPDFFromDB(AField: TField): boolean;
var
   BLOBField   : TBLOBField;
   BLOBStream  : TStream;
begin
   if not Assigned(AField) then
      raise EMyPDFRendererError.Create('LoadPDFFromDB(Field=nil)');

   if not (AField is TBLOBField) then
      raise EMyPDFRendererError.Create('LoadPDFFromDB(Field<>TBLOBField)');

   BLOBField:=TBLOBField(AField);

   BLOBStream := AField.DataSet.CreateBlobStream(BLOBField, bmRead);
   try
      Result:=LoadPDFFromStream(BLOBStream);
   finally
      FreeAndNil(BLOBStream);
   end;
end;
//------------------------------------------------------------------------------
function TCustomMyPDFRender.LoadPDFFromString(
   const APDFAsStringBuffer: string): boolean;
var
   mem   : TMemoryStream;
begin
   mem:=TMemoryStream.Create();
   try
      mem.Write(PChar(APDFAsStringBuffer)^, Length(APDFAsStringBuffer));

      mem.Position:=0;
      Result:=LoadPDFFromStream(mem);
   finally
      FreeAndNil(mem);
   end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TCustomMyPDFRender.RaiseIfPageNumberWrong(APageNumber: integer);
var
   iPagesCount   : integer;
begin
   iPagesCount := GetPagesCount();

   if iPagesCount<1 then
      EMyPDFRendererError.Create('There are 0 pageses in document')
   else
   if (APageNumber<1) or (APageNumber>iPagesCount) then
      EMyPDFRendererError.Create('Page-Number "'+IntToStr(APageNumber)+'" '+
                                 'is out of range [1..'+IntToStr(iPagesCount)+']');
end;
//------------------------------------------------------------------------------
function TCustomMyPDFRender.RenderPDFToCanvas(ACanvas: TCanvas; ARect: TRect;
  APageNumber, ADpiX, ADpiY: integer; ADoAutoRotate: boolean;
  ADoCenterInBounds: boolean): boolean;
begin
   Result:=RenderPDFToDC(ACanvas.Handle,           // ADC
                         ARect.Left,               // ARectLeft
                         ARect.Top,                // ARectTop
                         ARect.Right-ARect.Left,   // ARectWidth
                         ARect.Bottom-ARect.Top,   // ARectHeight
                         APageNumber,              // APageNumber
                         ADpiX,                    // ADpiX
                         ADpiY,                    // ADpiY
                         true,                     // ADoFitToBounds
                         false,                    // ADoStretchToBounds
                         true,                     // ADoKeepAspectRatio
                         ADoCenterInBounds,        // ADoCenterInBounds
                         ADoAutoRotate             // ADoAutoRotate
                         );

end;
//------------------------------------------------------------------------------
function TCustomMyPDFRender.RenderPDFToBitmap(ABitmap: Graphics.TBitmap;
  APageNumber, ADpiX, ADpiY: integer; ADoAutoRotate: boolean;
  ADoCenterInBounds: boolean; ADoAutoSizeBitmap: boolean): boolean;
var
   iW       : integer;
   iH       : integer;
begin
   if ADoAutoSizeBitmap then
   begin
      GetPageSizeInPixel(APageNumber, ADpiX, ADpiY, iW, iH);
      ABitmap.Width:=iW;
      ABitmap.Height:=iH;
   end;

   ABitmap.Canvas.Brush.Style:=bsSolid;
   ABitmap.Canvas.Brush.Color:=clWhite;
   ABitmap.Canvas.FillRect(Rect(0,0,iW, iH));

   Result:=RenderPDFToDC(ABitmap.Canvas.Handle,    // ADC
                         0,                        // ARectLeft
                         0,                        // ARectTop
                         ABitmap.Width,            // ARectWidth
                         ABitmap.Height,           // ARectHeight
                         APageNumber,              // APageNumber
                         ADpiX,                    // ADpiX
                         ADpiY,                    // ADpiY
                         not ADoAutoSizeBitmap,    // ADoFitToBounds
                         false,                    // ADoStretchToBounds
                         true,                     // ADoKeepAspectRatio
                         ADoCenterInBounds,        // ADoCenterInBounds
                         ADoAutoRotate             // ADoAutoRotate
                         );


end;
//------------------------------------------------------------------------------

END.
