//##############################################################################
{ TfrxPictureView }
//##############################################################################

type

{$IFDEF FR_COM}
  TfrxPictureView = class(TfrxView, IfrxPictureView)
{$ELSE}
  TfrxPictureView = class(TfrxView)
{$ENDIF}
  private
    FAutoSize: Boolean;
    FCenter: Boolean;
    FFileLink: String;
    FImageIndex: Integer;
    FIsImageIndexStored: Boolean;
    FIsPictureStored: Boolean;
    FKeepAspectRatio: Boolean;
    FPicture: TPicture;
    FPictureChanged: Boolean;
    FStretched: Boolean;
    FHightQuality: Boolean;
    procedure SetPicture(const Value: TPicture);
    procedure PictureChanged(Sender: TObject);
    procedure SetAutoSize(const Value: Boolean);
{$IFDEF FR_COM}
  protected
    function Get_Picture(out Value: OLE_HANDLE): HResult; stdcall;
    function Set_Picture(Value: OLE_HANDLE): HResult; stdcall;
    function Get_Metafile(out Value: OLE_HANDLE): HResult; stdcall;
    function Set_Metafile(Value: OLE_HANDLE): HResult; stdcall;
    function LoadViewFromStream(const Stream: IUnknown): HResult; stdcall;
    function SaveViewToStream(const Stream: IUnknown): HResult; stdcall;
{$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function GetDescription: String; override;
    function Diff(AComponent: TfrxComponent): String; override;
    function LoadPictureFromStream(s: TStream): HResult;
    procedure Draw(Canvas: TCanvas; ScaleX, ScaleY, OffsetX, OffsetY: Extended); override;
    procedure GetData; override;
    property IsImageIndexStored: Boolean read FIsImageIndexStored write FIsImageIndexStored;
    property IsPictureStored: Boolean read FIsPictureStored write FIsPictureStored;
  published
    property Cursor;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default False;
    property Center: Boolean read FCenter write FCenter default False;
    property DataField;
    property DataSet;
    property DataSetName;
    property Frame;
    property FileLink: String read FFileLink write FFileLink;
    property ImageIndex: Integer read FImageIndex write FImageIndex stored FIsImageIndexStored;
    property KeepAspectRatio: Boolean read FKeepAspectRatio write FKeepAspectRatio default True;
    property Picture: TPicture read FPicture write SetPicture stored FIsPictureStored;
    property Stretched: Boolean read FStretched write FStretched default True;
    property TagStr;
    property URL;
    property HightQuality: Boolean read FHightQuality write FHightQuality;
  end;
//------------------------------------------------------------------------------
constructor TfrxPictureView.Create(AOwner: TComponent);
begin
  inherited;
  frComponentStyle := frComponentStyle - [csDefaultDiff];
  FPicture := TPicture.Create;
  FPicture.OnChange := PictureChanged;
  FKeepAspectRatio := True;
  FStretched := True;
  FColor := clWhite;
  FIsPictureStored := True;
end;
//------------------------------------------------------------------------------
destructor TfrxPictureView.Destroy;
begin
  FPicture.Free;
  inherited;
end;
//------------------------------------------------------------------------------
class function TfrxPictureView.GetDescription: String;
begin
  Result := frxResources.Get('obPicture');
end;
//------------------------------------------------------------------------------
procedure TfrxPictureView.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
end;
//------------------------------------------------------------------------------
procedure TfrxPictureView.SetAutoSize(const Value: Boolean);
begin
  FAutoSize := Value;
  if FAutoSize and not (FPicture.Graphic = nil) then
  begin
    FWidth := FPicture.Width;
    FHeight := FPicture.Height;
  end;
end;
//------------------------------------------------------------------------------
procedure TfrxPictureView.PictureChanged(Sender: TObject);
begin
  AutoSize := FAutoSize;
  FPictureChanged := True;
end;
//------------------------------------------------------------------------------
procedure TfrxPictureView.Draw(Canvas: TCanvas; ScaleX, ScaleY, OffsetX, OffsetY: Extended);
var
  r: TRect;
  kx, ky: Extended;
  rgn: HRGN;

  procedure PrintGraphic(Canvas: TCanvas; DestRect: TRect; aGraph: TGraphic);
  begin
    frxDrawGraphic(Canvas, DestRect, aGraph, (IsPrinting or FHightQuality));
  end;

begin
  BeginDraw(Canvas, ScaleX, ScaleY, OffsetX, OffsetY);

  with Canvas do
  begin
    DrawBackground;
    r := Rect(FX, FY, FX1, FY1);

    if (FPicture.Graphic = nil) or FPicture.Graphic.Empty then
    begin
      if IsDesigning then
        frxResources.ObjectImages.Draw(Canvas, FX + 1, FY + 2, 3);
    end
    else
    begin
      if FStretched then
      begin
        if FKeepAspectRatio then
        begin
          kx := FDX / FPicture.Width;
          ky := FDY / FPicture.Height;
          if kx < ky then
            r.Bottom := r.Top + Round(FPicture.Height * kx) else
            r.Right := r.Left + Round(FPicture.Width * ky);

          if FCenter then
            OffsetRect(r, (FDX - (r.Right - r.Left)) div 2,
                          (FDY - (r.Bottom - r.Top)) div 2);
        end;

        PrintGraphic(Canvas, r, FPicture.Graphic);
      end
      else
      begin
        rgn := CreateRectRgn(0, 0, 10000, 10000);
        GetClipRgn(Canvas.Handle, rgn);
        IntersectClipRect(Canvas.Handle,
          Round(FX),
          Round(FY),
          Round(FX1),
          Round(FY1));

        if FCenter then
          OffsetRect(r, (FDX - Round(ScaleX * FPicture.Width)) div 2,
                        (FDY - Round(ScaleY * FPicture.Height)) div 2);
        r.Right := r.Left + Round(FPicture.Width * ScaleX);
        r.Bottom := r.Top + Round(FPicture.Height * ScaleY);
        PrintGraphic(Canvas, r, Picture.Graphic);

        SelectClipRgn(Canvas.Handle, rgn);
        DeleteObject(rgn);
      end;
    end;

    DrawFrame;
  end;
end;
//------------------------------------------------------------------------------
function TfrxPictureView.Diff(AComponent: TfrxComponent): String;
begin
  if FPictureChanged then
  begin
    Report.PreviewPages.AddPicture(Self);
    FPictureChanged := False;
  end;

  Result := ' ' + inherited Diff(AComponent) + ' ImageIndex="' +
    IntToStr(FImageIndex) + '"';
end;
//------------------------------------------------------------------------------
{$IFDEF FR_COM}
function TfrxPictureView.Get_Picture(out Value: OLE_HANDLE): HResult; stdcall;
begin
  Value := FPicture.Bitmap.Handle;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TfrxPictureView.Set_Picture(Value: OLE_HANDLE): HResult; stdcall;
begin
  FPicture.Bitmap.Handle := Value;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TfrxPictureView.Get_Metafile(out Value: OLE_HANDLE): HResult; stdcall;
begin
  Value := FPicture.Metafile.Handle;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TfrxPictureView.Set_Metafile(Value: OLE_HANDLE): HResult; stdcall;
begin
  FPicture.Metafile.Handle := Value;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TfrxPictureView.LoadViewFromStream(const Stream: IUnknown): HResult; stdcall;
var
  ComStream: IStream;
  OleStream: TOleStream;

  NetStream:  _Stream;
  ClrStream: TClrStream;
begin
  try
    Result := Stream.QueryInterface(IStream, ComStream);
    if Result = S_OK then
    begin
      OleStream := TOleStream.Create(ComStream);
      LoadPictureFromStream(OleStream);
      OleStream.Free;
      ComStream := nil;
    end
    else
    begin
      Result := Stream.QueryInterface(_Stream, NetStream);
      if Result = S_OK then
      begin
        ClrStream := TClrStream.Create(NetStream);
        LoadPictureFromStream(ClrStream);
        ClrStream.Free;
        NetStream._Release();
      end;
    end;
  except
    Result := E_FAIL;
  end;
end;
//------------------------------------------------------------------------------
function TfrxPictureView.SaveViewToStream(const Stream: IUnknown): HResult; stdcall;
var
  ComStream:  IStream;
  OleStream: TOleStream;

  NetStream:  _Stream;
  ClrStream: TClrStream;
begin
  try
    Result := Stream.QueryInterface(IStream, ComStream);
    if Result = S_OK then
    begin
      OleStream := TOleStream.Create(ComStream);
      FPicture.Bitmap.SaveToStream(OleStream);
      OleStream.Free;
      ComStream._Release();
    end
    else
    begin
      Result := Stream.QueryInterface(_Stream, NetStream);
      if Result = S_OK then
      begin
        ClrStream := TClrStream.Create(NetStream);
        FPicture.Bitmap.SaveToStream(ClrStream);
        ClrStream.Free;
        NetStream._Release();
      end;
    end;
  except
    Result := E_FAIL;
  end;
end;
{$ENDIF}

const
  WMFKey = Integer($9AC6CDD7);
  WMFWord = $CDD7;
  rc3_StockIcon = 0;
  rc3_Icon = 1;
  rc3_Cursor = 2;

type
  TGraphicHeader = record
    Count: Word;
    HType: Word;
    Size: Longint;
  end;

  TMetafileHeader = packed record
    Key: Longint;
    Handle: SmallInt;
    Box: TSmallRect;
    Inch: Word;
    Reserved: Longint;
    CheckSum: Word;
  end;

  TCursorOrIcon = packed record
    Reserved: Word;
    wType: Word;
    Count: Word;
  end;
//------------------------------------------------------------------------------
const
  OriginalPngHeader: array[0..7] of Char = (#137, #80, #78, #71, #13, #10, #26, #10);
//------------------------------------------------------------------------------
function TfrxPictureView.LoadPictureFromStream(s: TStream): Hresult;
var
  pos: Integer;
  Header: TGraphicHeader;
  BMPHeader: TBitmapFileHeader;
{$IFDEF JPEG}
  JPEGHeader: array[0..1] of Byte;
{$ENDIF}
{$IFDEF PNG}
  PNGHeader: array[0..7] of Char;
{$ENDIF}
  EMFHeader: TEnhMetaHeader;
  WMFHeader: TMetafileHeader;
  ICOHeader: TCursorOrIcon;
  NewGraphic: TGraphic;
  bOK : Boolean;
begin
  NewGraphic := nil;

  if s.Size > 0 then
  begin
    // skip Delphi blob-image header
    if s.Size >= SizeOf(TGraphicHeader) then
    begin
      s.Read(Header, SizeOf(Header));
      if (Header.Count <> 1) or (Header.HType <> $0100) or
        (Header.Size <> s.Size - SizeOf(Header)) then
          s.Position := 0;
    end;
    pos := s.Position;

    bOK := False;

    if (s.Size-pos) >= SizeOf(BMPHeader) then
    begin
      // try bmp header
      s.ReadBuffer(BMPHeader, SizeOf(BMPHeader));
      s.Position := pos;
      if BMPHeader.bfType = $4D42 then
      begin
        NewGraphic := TBitmap.Create;
        bOK := True;
      end;
    end;

    {$IFDEF JPEG}
    if not bOK then
    begin
      if (s.Size-pos) >= SizeOf(JPEGHeader) then
      begin
        // try jpeg header
        s.ReadBuffer(JPEGHeader, SizeOf(JPEGHeader));
        s.Position := pos;
        if (JPEGHeader[0] = $FF) and (JPEGHeader[1] = $D8) then
        begin
          NewGraphic := TJPEGImage.Create;
          bOK := True;
        end;
      end;
    end;
    {$ENDIF}

    {$IFDEF PNG}
    if not bOK then
    begin
      if (s.Size-pos) >= SizeOf(PNGHeader) then
      begin
        // try png header
        s.ReadBuffer(PNGHeader, SizeOf(PNGHeader));
        s.Position := pos;
        if PNGHeader = OriginalPngHeader then
        begin
          NewGraphic := TPngObject.Create;
          bOK := True;
        end;
      end;
    end;
    {$ENDIF}

    if not bOK then
    begin
      if (s.Size-pos) >= SizeOf(WMFHeader) then
      begin
        // try wmf header
        s.ReadBuffer(WMFHeader, SizeOf(WMFHeader));
        s.Position := pos;
        if WMFHeader.Key = WMFKEY then
        begin
          NewGraphic := TMetafile.Create;
          bOK := True;
        end;
      end;
    end;

    if not bOK then
    begin
      if (s.Size-pos) >= SizeOf(EMFHeader) then
      begin
        // try emf header
        s.ReadBuffer(EMFHeader, SizeOf(EMFHeader));
        s.Position := pos;
        if EMFHeader.dSignature = ENHMETA_SIGNATURE then
        begin
          NewGraphic := TMetafile.Create;
          bOK := True;
        end;
      end;
    end;

    if not bOK then
    begin
      if (s.Size-pos) >= SizeOf(ICOHeader) then
      begin
        // try icon header
        s.ReadBuffer(ICOHeader, SizeOf(ICOHeader));
        s.Position := pos;
        if ICOHeader.wType in [RC3_STOCKICON, RC3_ICON] then
          NewGraphic := TIcon.Create;
      end;
    end;
  end;

  if NewGraphic <> nil then
  begin
    FPicture.Graphic := NewGraphic;
    NewGraphic.Free;
    FPicture.Graphic.LoadFromStream(s);
    Result := S_OK;
  end
  else
  begin
    FPicture.Assign(nil);
    Result := E_INVALIDARG;
  end;
// workaround pngimage bug
{$IFDEF PNG}
  if FPicture.Graphic is TPngObject then
    PictureChanged(nil);
{$ENDIF}
end;
//------------------------------------------------------------------------------
procedure TfrxPictureView.GetData;
var
  m: TMemoryStream;
  s: String;
begin
  inherited;
  if FFileLink <> '' then
  begin
    s := FFileLink;
    if Pos('[', s) <> 0 then
      ExpandVariables(s);
    if FileExists(s) then
      FPicture.LoadFromFile(s)
    else
      FPicture.Assign(nil);
  end
  else if IsDataField and DataSet.IsBlobField(DataField) then
  begin
    m := TMemoryStream.Create;
    try
      DataSet.AssignBlobTo(DataField, m);
      LoadPictureFromStream(m);
    finally
      m.Free;
    end;
  end;
end;

//############################################################################## 
{ TfrxPictureEditor }
//############################################################################## 
type
  TfrxPictureEditor = class(TfrxViewEditor)
  public
    function Edit: Boolean; override;
    function HasEditor: Boolean; override;
    procedure GetMenuItems; override;
    function Execute(Tag: Integer; Checked: Boolean): Boolean; override;
  end;
//------------------------------------------------------------------------------  
function TfrxPictureEditor.Edit: Boolean;
begin
  with TfrxPictureEditorForm.Create(Designer) do
  begin
    Image.Picture.Assign(TfrxPictureView(Component).Picture);
    Result := ShowModal = mrOk;
    if Result then
    begin
      TfrxPictureView(Component).Picture.Assign(Image.Picture);
      TfrxDesignerForm(Self.Designer).PictureCache.AddPicture(
         TfrxPictureView(Component)
         );
    end;
    Free;
  end;
end;
//------------------------------------------------------------------------------  
function TfrxPictureEditor.HasEditor: Boolean;
begin
  Result := True;
end;
//------------------------------------------------------------------------------  
function TfrxPictureEditor.Execute(Tag: Integer; Checked: Boolean): Boolean;
var
  i: Integer;
  c: TfrxComponent;
  p: TfrxPictureView;
begin
  Result := inherited Execute(Tag, Checked);

  for i := 0 to Designer.SelectedObjects.Count - 1 do
  begin
    c := Designer.SelectedObjects[i];
    if (c is TfrxPictureView) and not (rfDontModify in c.Restrictions) then
    begin
      p := TfrxPictureView(c);
      case Tag of
        0: p.AutoSize := Checked;
        1: p.Stretched := Checked;
        2: p.Center := Checked;
        3: p.KeepAspectRatio := Checked;
      end;

      Result := True;
    end;
  end;
end;
//------------------------------------------------------------------------------  
procedure TfrxPictureEditor.GetMenuItems;
var
  p: TfrxPictureView;
begin
  p := TfrxPictureView(Component);

  AddItem(frxResources.Get('pvAutoSize'), 0, p.AutoSize);
  AddItem(frxResources.Get('mvStretch'), 1, p.Stretched);
  AddItem(frxResources.Get('pvCenter'), 2, p.Center);
  AddItem(frxResources.Get('pvAspect'), 3, p.KeepAspectRatio);
  AddItem('-', -1);

  inherited;
end;
//############################################################################## 
{ TfrxPictureProperty }
//############################################################################## 
type
  TfrxPictureProperty = class(TfrxClassProperty)
  public
    function GetValue: String; override;
    function GetAttributes: TfrxPropertyAttributes; override;
    function Edit: Boolean; override;
  end;
//------------------------------------------------------------------------------  
function TfrxPictureProperty.GetAttributes: TfrxPropertyAttributes;
begin
  Result := [paDialog, paReadOnly];
end;
//------------------------------------------------------------------------------  
function TfrxPictureProperty.Edit: Boolean;
var
  Pict: TPicture;
begin
  with TfrxPictureEditorForm.Create(Designer) do
  begin
    Pict := TPicture(GetOrdValue);
    Image.Picture.Assign(Pict);
    Result := ShowModal = mrOk;
    if Result then
      Pict.Assign(Image.Picture);
    Free;
  end;
end;
//------------------------------------------------------------------------------  
function TfrxPictureProperty.GetValue: String;
var
  Pict: TPicture;
begin
  Pict := TPicture(GetOrdValue);
  if Pict.Graphic = nil then
    Result := frxResources.Get('prNotAssigned') else
    Result := frxResources.Get('prPict');
end;
//##############################################################################
frxObjects.RegisterObject1(TfrxPictureView, nil, '', '', 0, 3); 
frxComponentEditors.Register(TfrxPictureView, TfrxPictureEditor);
frxPropertyEditors.Register(TypeInfo(TPicture), nil, '', TfrxPictureProperty);
frxHideProperties(TfrxPictureView, 'ImageIndex');  
//##############################################################################

