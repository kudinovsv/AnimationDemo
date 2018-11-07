unit Canvases;

interface

uses Windows, Graphics, GDIPAPI, GDIPOBJ, SysUtils, RootObject;

type
  TPointEx = record
    X : Extended;
    Y : Extended;
  end;

  IMyCanvas = interface
  ['{E3D5A3FD-FE49-414F-AF6C-92A5AF2C4630}']
    procedure SetDC(DC: HDC);
    procedure SetBrushColor(Color: TColor);
    procedure FillRect(const Rect: TRect);
    procedure SetPen(Color: TColor; Width: integer);
    procedure MoveTo(const Point: TPointEx);
    procedure LineTo(const Point: TPointEx);
    function GetCurPoint: TPointEx;
    function TextWidth(const Text: string): integer;
    procedure TextOut(const Pos: TPoint; const Text: string);
    procedure DrawBitmap(Bmp: TBitmap; x, y: integer);
  end;

  TCurPointHolder = class(TRootObject)
  protected
    CurPoint: TPointEx;
  public
    function GetCurPoint: TPointEx;
  end;

  TVclCanvas = class(TCurPointHolder, IMyCanvas)
  private
    Canvas: TCanvas;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure SetDC(DC: HDC);
    procedure SetBrushColor(Color: TColor);
    procedure FillRect(const Rect: TRect);
    procedure SetPen(Color: TColor; Width: integer);
    procedure MoveTo(const Point: TPointEx);
    procedure LineTo(const Point: TPointEx);
    function TextWidth(const Text: string): integer;
    procedure TextOut(const Pos: TPoint; const Text: string);
    procedure DrawBitmap(Bmp: TBitmap; x, y: integer);
  end;

  TGdiPlusCanvas = class(TCurPointHolder, IMyCanvas)
  private
    Context: TGPGraphics;
    Brush: TGPSolidBrush;
    Font: HFont;
    Pen: TGPPen;
    DC: HDC;

    procedure CreateFont;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure SetDC(ADC: HDC);
    procedure SetBrushColor(Color: TColor);
    procedure FillRect(const Rect: TRect);
    procedure SetPen(Color: TColor; Width: integer);
    procedure MoveTo(const Point: TPointEx);
    procedure LineTo(const Point: TPointEx);
    function TextWidth(const Text: string): integer;
    procedure TextOut(const Pos: TPoint; const Text: string);
    procedure DrawBitmap(Bmp: TBitmap; x, y: integer);
  end;

implementation

{ TCurPointHolding }

function TCurPointHolder.GetCurPoint: TPointEx;
begin
  Result := CurPoint;
end;

{ TVclCanvas }

constructor TVclCanvas.Create;
begin
  Canvas := TCanvas.Create;
end;

destructor TVclCanvas.Destroy;
begin
  Canvas.Free;
  inherited;
end;

procedure TVclCanvas.SetDC(DC: HDC);
begin
  if DC <> 0 then
    Canvas.Handle := DC;
end;

procedure TVclCanvas.DrawBitmap(Bmp: TBitmap; x, y: integer);
begin
  Canvas.Draw(x, y, Bmp);
end;

procedure TVclCanvas.SetPen(Color: TColor; Width: integer);
begin
  Canvas.Pen.Color := Color;
  Canvas.Pen.Width := Width;
end;

function TVclCanvas.TextWidth(const Text: string): integer;
begin
  Result := Canvas.TextWidth(Text);
end;

procedure TVclCanvas.TextOut(const Pos: TPoint; const Text: string);
begin
  Canvas.TextOut(Pos.X, Pos.Y, Text);
end;

procedure TVclCanvas.MoveTo(const Point: TPointEx);
begin
  CurPoint := Point;
  Canvas.MoveTo(round(Point.x), round(Point.y));
end;

procedure TVclCanvas.LineTo(const Point: TPointEx);
begin
  CurPoint := Point;
  Canvas.LineTo(round(Point.x), round(Point.y));
end;

procedure TVclCanvas.FillRect(const Rect: TRect);
begin
  Canvas.FillRect(Rect);
end;

procedure TVclCanvas.SetBrushColor(Color: TColor);
begin
  Canvas.Brush.Color := Color;
end;

{ TGdiPlusCanvas }

constructor TGdiPlusCanvas.Create;
begin
  Brush := TGPSolidBrush.Create(aclBlack);
  Pen := TGPPen.Create(aclBlack);
end;

procedure TGdiPlusCanvas.CreateFont;
var
  f: TLogFont;
begin
  FillChar(f, sizeof(f), 0);
  f.lfFaceName := 'Tahoma';
  f.lfHeight := -11;
  Font := CreateFontIndirect(f);
  DeleteObject(SelectObject(DC, Font));
end;

destructor TGdiPlusCanvas.Destroy;
begin
  Pen.Free;
  Brush.Free;
  Context.Free;
  inherited;
end;

procedure TGdiPlusCanvas.SetDC(ADC: HDC);
begin
  DC := ADC;
  FreeAndNil(Context);
  if DC = 0 then
    Exit;
  Context := TGPGraphics.Create(DC);
  Context.SetSmoothingMode(SmoothingModeAntiAlias);
  if Font = 0 then
    CreateFont;
end;

procedure TGdiPlusCanvas.SetPen(Color: TColor; Width: integer);
begin
  Pen.SetColor(ColorRefToARGB(Color));
  Pen.SetWidth(Width);
end;

function TGdiPlusCanvas.TextWidth(const Text: string): integer;
var
  size: TSize;
begin
  GetTextExtentPoint32(DC, Text, Length(Text), size);
  Result := size.cx;
end;

procedure TGdiPlusCanvas.TextOut(const Pos: TPoint; const Text: string);
begin
  Windows.TextOut(DC, Pos.X, Pos.Y, PChar(Text), Length(Text));
end;

procedure TGdiPlusCanvas.DrawBitmap(Bmp: TBitmap; x, y: integer);
begin
  BitBlt(DC, x, y, Bmp.Width, Bmp.Height, Bmp.Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure TGdiPlusCanvas.MoveTo(const Point: TPointEx);
begin
  CurPoint := Point;
end;

procedure TGdiPlusCanvas.LineTo(const Point: TPointEx);
begin
  Context.DrawLine(Pen, CurPoint.X, CurPoint.Y, Point.X, Point.Y);
  CurPoint := Point;
end;

procedure TGdiPlusCanvas.FillRect(const Rect: TRect);
begin
  Context.FillRectangle(Brush, MakeRect(Rect));
end;

procedure TGdiPlusCanvas.SetBrushColor(Color: TColor);
begin
  Brush.SetColor(ColorRefToARGB(Color));
end;

end.
