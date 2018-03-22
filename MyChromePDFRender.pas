//Delphi wrapper for Google Chrome's "pdf.dll" with GetPDFPageSizeByIndex()
//Wrote by Simon Kroik, 06.2013-03.2018
//Version 2.0
//Tested with Delphi 6 
UNIT MyChromePDFRender;

INTERFACE
uses MyPDFRender, Windows, Classes, DB, Graphics, Types;

type
   TChromePDFBufferSize  = integer;

   TMyChromePDFRender = class(TCustomMyPDFRender)
   private
      FBuffer              : PChar;
      FBufferSize          : TChromePDFBufferSize;
      FPagesCount          : integer;
      FMaxPageWidthCm      : extended;

   protected
      procedure InitEmptyFields(); override;

      function GetPagesCount(): integer; override;
      function GetSizeInBytes(): int64; override;

      procedure AssignTo(Dest: TPersistent); override;
   public
      procedure Clear(); override;

      function SavePDFToStream(AStream: TStream): boolean; override;
      function LoadPDFFromStream(AStream: TStream; ALength: int64=0): boolean; override;

      function GetPageSizeInCm(APageNumber: integer;
                               var AWidthCm: extended;
                               var AHeightCm: extended): boolean; override;

      function GetPageSizeInPixel(APageNumber: integer;
                                  ADpiX: integer;
                                  ADpiY: integer;
                                  var AWidth: integer;
                                  var AHeight: integer): boolean; override;

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
                             ADoAutoRotate: boolean): boolean; override;

   public
      property MaxPageWidthCm: extended read FMaxPageWidthCm;
   end;
   
IMPLEMENTATION
uses SysUtils;
//##############################################################################
{ Utils }
//##############################################################################
//
// The "pdf.dll" has problems. For excample, LoadLibrary('pdf.dll') returns 0
// with the GetLastError() = 3221225614
//
// Hier found I the solution:
// http://stackoverflow.com/questions/3534572/delphi-loadlibrary-returns-0-lasterrorcde-3221225616-what-does-this-mean
//
// GetLastError() after LoadLibrary('pdf.dll') was "3221225614", not  "3221225616"
// but the solution from StackOverflow.com also works.
//
// The error code, 3221225616, seems, when asking Google, to be the result of an
// invalid floating point operation. Now, this seems very technical; indeed, what
// does loading a library have to do with floating point computations?
// The floating point control word (CW) is a bitfield where the bits specify how
// the processor should handle floating-point errors; it is actually rather
// common that unexpected floating point errors can be dealt with by changing
// one of these bits to 1 (which by the way is the default state). For an other
// example, see this question of mine, in which I get a totally unexpected
// division by zero error, which is dealt with by setting the "div by zero" bit
// of the control word to 1.
//
// var
//    SavedCW: word;
//
// ...
// SavedCW := Get8087CW;
// Set8087CW(SavedCW or $7);
// DLLHandle := LoadLibrary('3rdparty.dll');
// Set8087CW(SavedCW);
//
//------------------------------------------------------------------------------


const
   LibName  = 'pdf.dll';

type
   TGraphicCracker = class(Graphics.TGraphic);

type   
   TGetPDFDocInfoProc = procedure(pdf_buffer       : PChar;
                                  buffer_size      : integer;
                                  page_count       : PInt;
                                  max_page_width   : PDouble
                                 ); cdecl;

   TGetPDFPageSizeByIndexFunc = function(pdf_buffer          : PChar;
                                         buffer_size         : integer;
                                         page_number         : integer;
                                         width               : PDouble;
                                         height              : PDouble): BOOL; cdecl;

   TRenderPDFPageToDCFunc = function(pdf_buffer          : PChar;
                                     buffer_size         : integer;
                                     page_number         : integer;
                                     dc                  : HDC;
                                     dpi_x               : integer;
                                     dpi_y               : integer;
                                     bounds_origin_x     : integer;
                                     bounds_origin_y     : integer;
                                     bounds_width        : integer;
                                     bounds_height       : integer;
                                     fit_to_bounds       : boolean;
                                     stretch_to_bounds   : boolean;
                                     keep_aspect_ratio   : boolean;
                                     center_in_bounds    : boolean;
                                     autorotate          : boolean
                                    ): BOOL; cdecl;

VAR
   internal_hLib                       : THandle;
   internal_procGetPDFDocInfo          : TGetPDFDocInfoProc;
   internal_funcGetPDFPageSizeByIndex  : TGetPDFPageSizeByIndexFunc;
   internal_funcRenderPDFPageToDC      : TRenderPDFPageToDCFunc;
//------------------------------------------------------------------------------
procedure BeforeCallDLL(out ASavedCW: word);
begin
   ASavedCW:=Get8087CW();
   Set8087CW(ASavedCW or $7); //see infos after "IMPLEMENTATION"
end;
//------------------------------------------------------------------------------
procedure AfterCallDLL(const ASavedCW: word);
begin
   Set8087CW(ASavedCW);
end;
//------------------------------------------------------------------------------
procedure FreeLib();
var
   iSavedCW  : word;
begin
   if internal_hLib<>0 then
   begin
      BeforeCallDLL(iSavedCW);
      try
         try
            FreeLibrary(internal_hLib);
         finally
            internal_hLib:=0;
         end;
      finally
         AfterCallDLL(iSavedCW);
      end;
   end; //if internal_hLib<>0
end;
//------------------------------------------------------------------------------
procedure RaiseLibLoadingException(const AMessage: string);
begin
   try
      FreeLib();
   finally
      raise EMyPDFRendererError.Create(
         'Library "'+LibName+'" is not correct loaded.'#13#10+AMessage
         );
   end;
end;
//------------------------------------------------------------------------------
function LoadLibIfNeed(): boolean;
var
   iSavedCW  : word;
   iLastErr : DWORD;
begin
   if internal_hLib=0 then
   begin
      BeforeCallDLL(iSavedCW);
      try
         internal_hLib:=LoadLibrary(LibName);
         iLastErr:=GetLastError();
      finally
         AfterCallDLL(iSavedCW);
      end;

      if internal_hLib=0 then
         RaiseLibLoadingException(SysErrorMessage(iLastErr))
      else
      begin
         //-- GetPDFDocInfo --
         @internal_procGetPDFDocInfo :=
            GetProcAddress(internal_hLib, 'GetPDFDocInfo');

         if not Assigned(@internal_procGetPDFDocInfo) then
            RaiseLibLoadingException('function "GetPDFDocInfo" is not found.');

         //-- GetPDFPageSizeByIndex --
         @internal_funcGetPDFPageSizeByIndex :=
            GetProcAddress(internal_hLib, 'GetPDFPageSizeByIndex');

         if not Assigned(@internal_funcGetPDFPageSizeByIndex) then
            RaiseLibLoadingException('function "GetPDFPageSizeByIndex" is not found.');

         //-- RenderPDFPageToDC --
         @internal_funcRenderPDFPageToDC :=
            GetProcAddress(internal_hLib, 'RenderPDFPageToDC');

         if not Assigned(@internal_funcRenderPDFPageToDC) then
            RaiseLibLoadingException('function "RenderPDFPageToDC" is not found.');

         // >>> not used Function from DLL: RenderPDFPageToBitmap() 
                     
      end; //if internal_hLib<>0
   end;

   Result:=(internal_hLib<>0);
end;
//##############################################################################
{ TMyChromePDFRender }
//##############################################################################
function TMyChromePDFRender.GetPagesCount(): integer;
begin
   Result:=FPagesCount;
end;
//------------------------------------------------------------------------------
function TMyChromePDFRender.GetSizeInBytes(): int64;
begin
   Result:=FBufferSize;
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMyChromePDFRender.InitEmptyFields();
begin
   inherited;

   FBuffer:=nil;
   FBufferSize:=0;
   FPagesCount:=0;
   FMaxPageWidthCm:=0;
end;
//------------------------------------------------------------------------------
procedure TMyChromePDFRender.Clear();
begin
   inherited;

   FreeMem(FBuffer);
   InitEmptyFields();
end;
//------------------------------------------------------------------------------
procedure TMyChromePDFRender.AssignTo(Dest: TPersistent);
var
   DstRender   : TMyChromePDFRender;
begin
   inherited;

   if Dest is TMyChromePDFRender then
   begin
      DstRender:=TMyChromePDFRender(Dest);

      DstRender.FBufferSize:=FBufferSize;
      DstRender.FPagesCount:=FPagesCount;
      DstRender.FMaxPageWidthCm:=FMaxPageWidthCm;

      GetMem(DstRender.FBuffer, DstRender.FBufferSize);
      Move(FBuffer^, DstRender.FBuffer^, DstRender.FBufferSize);
   end;
end;
//------------------------------------------------------------------------------
function TMyChromePDFRender.SavePDFToStream(AStream: TStream): boolean;
begin
   if FBufferSize>0 then
   begin
      AStream.Write(FBuffer^, FBufferSize);
      Result:=true;
   end
   else
      Result:=false;
end;
//------------------------------------------------------------------------------
function TMyChromePDFRender.LoadPDFFromStream(AStream: TStream;
   ALength: int64): boolean;
var
   iPDFSize                : int64;
   fMaxPageWidthPix72dpi   : double; //for WEB
   iSavedCW                : word;
begin
   if ALength>0 then
   begin
      iPDFSize:=ALength;

      if AStream.Position+iPDFSize > AStream.Size then
         raise EMyPDFRendererError.Create(
            'Length-Parameter is over the stream size'
            );
   end
   else
   begin
      iPDFSize:=AStream.Size - AStream.Position;
   end;

   if iPDFSize>High(TChromePDFBufferSize) then
      raise EMyPDFRendererError.Create(
         'PDF is too big: '+IntToStr(iPDFSize div (1024*1024))+' MB'
         );

   LoadLibIfNeed();

   Clear();

   FBufferSize:=iPDFSize;

   GetMem(FBuffer, FBufferSize);
   AStream.ReadBuffer(FBuffer^, FBufferSize);

   BeforeCallDLL(iSavedCW);
   try
      internal_procGetPDFDocInfo(FBuffer,
                                 FBufferSize,
                                 @FPagesCount,
                                 @fMaxPageWidthPix72dpi);
   finally
      AfterCallDLL(iSavedCW);
   end;

   FMaxPageWidthCm:=InchToCm(fMaxPageWidthPix72dpi/72.0);

   Result:=true;
end;
////////////////////////////////////////////////////////////////////////////////
function TMyChromePDFRender.GetPageSizeInCm(APageNumber: integer;
  var AWidthCm: extended; var AHeightCm: extended): boolean;
var
   iSavedCW                : word;
   fWidthPix72dpi          : double; //for WEB
   fHeightPix72dpi         : double; //for WEB
begin
   LoadLibIfNeed();

   RaiseIfPageNumberWrong(APageNumber);

   BeforeCallDLL(iSavedCW);
   try
      // From: https://chromium.googlesource.com/chromium/src/+/master/pdf/pdf.h
      //
      // Gets the dimensions of a specific page in a document.
      // |pdf_buffer| is the buffer that contains the entire PDF document to be
      //     rendered.
      // |pdf_buffer_size| is the size of |pdf_buffer| in bytes.
      // |page_number| is the page number that the function will get the dimensions
      //     of.
      // |width| is the output for the width of the page in points.
      // |height| is the output for the height of the page in points.
      // Returns false if the document or the page number are not valid.

      Result:=internal_funcGetPDFPageSizeByIndex(FBuffer,          // pdf_buffer
                                                 FBufferSize,      // buffer_size
                                                 APageNumber-1,    // page_number
                                                 @fWidthPix72dpi,  // width
                                                 @fHeightPix72dpi);// height

      AWidthCm:=InchToCm(fWidthPix72dpi/72.0);
      AHeightCm:=InchToCm(fHeightPix72dpi/72.0);
   finally
      AfterCallDLL(iSavedCW);
   end;
end;
//------------------------------------------------------------------------------
function TMyChromePDFRender.GetPageSizeInPixel(APageNumber: integer;
  ADpiX: integer; ADpiY: integer; var AWidth: integer;
  var AHeight: integer): boolean;
var
   iSavedCW                : word;
   fWidthPix72dpi          : double; //for WEB
   fHeightPix72dpi         : double; //for WEB
begin
   LoadLibIfNeed();

   RaiseIfPageNumberWrong(APageNumber);

   BeforeCallDLL(iSavedCW);
   try
      Result:=internal_funcGetPDFPageSizeByIndex(FBuffer,          // pdf_buffer
                                                 FBufferSize,      // buffer_size
                                                 APageNumber-1,    // page_number
                                                 @fWidthPix72dpi,  // width
                                                 @fHeightPix72dpi);// height

      AWidth:=Round(fWidthPix72dpi/72.0*ADpiX);
      AHeight:=Round(fHeightPix72dpi/72.0*ADpiY);
   finally
      AfterCallDLL(iSavedCW);
   end;
end;
//------------------------------------------------------------------------------
function TMyChromePDFRender.RenderPDFToDC(ADC: HDC;
  ARectLeft, ARectTop, ARectWidth, ARectHeight: integer; APageNumber: integer;
  ADpiX, ADpiY: integer; ADoFitToBounds: boolean; ADoStretchToBounds: boolean;
  ADoKeepAspectRatio: boolean; ADoCenterInBounds: boolean;
  ADoAutoRotate: boolean): boolean;
var
   iSavedCW : word;
begin
   LoadLibIfNeed();

   RaiseIfPageNumberWrong(APageNumber);

   BeforeCallDLL(iSavedCW);
   try
      // From: https://chromium.googlesource.com/chromium/src/+/master/pdf/pdf.h
      //
      // |pdf_buffer| is the buffer that contains the entire PDF document to be
      //     rendered.
      // |buffer_size| is the size of |pdf_buffer| in bytes.
      // |page_number| is the 0-based index of the page to be rendered.
      // |dc| is the device context to render into.
      // |dpi_x| and |dpi_y| are the x and y resolutions respectively. If either
      //     value is -1, the dpi from the DC will be used.
      // |bounds_origin_x|, |bounds_origin_y|, |bounds_width| and |bounds_height|
      //     specify a bounds rectangle within the DC in which to render the PDF
      //     page.
      // |fit_to_bounds| specifies whether the output should be shrunk to fit the
      //     supplied bounds if the page size is larger than the bounds in any
      //     dimension. If this is false, parts of the PDF page that lie outside
      //     the bounds will be clipped.
      // |stretch_to_bounds| specifies whether the output should be stretched to fit
      //     the supplied bounds if the page size is smaller than the bounds in any
      //     dimension.
      // If both |fit_to_bounds| and |stretch_to_bounds| are true, then
      //     |fit_to_bounds| is honored first.
      // |keep_aspect_ratio| If any scaling is to be done is true, this flag
      //     specifies whether the original aspect ratio of the page should be
      //     preserved while scaling.
      // |center_in_bounds| specifies whether the final image (after any scaling is
      //     done) should be centered within the given bounds.
      // |autorotate| specifies whether the final image should be rotated to match
      //     the output bound.
      // Returns false if the document or the page number are not valid.   


      Result:=internal_funcRenderPDFPageToDC(FBuffer,               // pdf_buffer
                                             FBufferSize,           // buffer_size
                                             APageNumber-1,         // page_number
                                             ADC,                   // dc
                                             ADpiX,                 // dpi_x
                                             ADpiY,                 // dpi_y
                                             ARectLeft,             // bounds_origin_x
                                             ARectTop,              // bounds_origin_y
                                             ARectWidth,            // bounds_width
                                             ARectHeight,           // bounds_height
                                             ADoFitToBounds,        // fit_to_bounds
                                             ADoStretchToBounds,    // stretch_to_bounds
                                             ADoKeepAspectRatio,    // keep_aspect_ratio
                                             ADoCenterInBounds,     // center_in_bounds
                                             ADoAutoRotate);        // autorotate
   finally
      AfterCallDLL(iSavedCW);
   end;

end;
////////////////////////////////////////////////////////////////////////////////

INITIALIZATION
   internal_hLib:=0;
FINALIZATION
   FreeLib();

END.
 