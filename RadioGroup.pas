unit RadioGroup;

interface

uses Windows, Classes, Graphics, Canvases, Generics.Collections, RootObject;

type
   TRadioGroup = class
   private class var
     Dot: TBitmap;
   private const
     // отступы от краёв ClientRect окна
     HorizMargin = 7;
     VertMargin = 5;
     // отступы для точки первого элемента
     DotLeftMargin = 17;
     DotTopMargin = 26;
     // шаг элементов
     ItemsStep = 23;
     RadioButtonDot = 'RADIODOT'; // идентификатор ресурса битмапа скина:
                                  // точка выбранного элемента
   private
     LastPos: TPoint;   // позиция при последней отрисовске
     Location: TPoint;
     BaseImage: TBitmap;
     ItemIndex: integer;   // индекс текущего выбранного элемента
     Items: TList<TRootClass>;  // итемы - классы потомки TRootObject

     function ItemAtPos(const Point: TPoint): integer;
   public const
     // идентификаторы ресурса битмапов скинов радио-групп
     CanvasRadioGroup = 'CANVASRG';
     WalkerRadioGroup = 'WALKERRG';
   public
     constructor Create(AGroupName: string; RightAnchor: boolean;
       const AItems: array of TRootClass);
     destructor Destroy; override;
     procedure Draw(Canvas: IMyCanvas; const ClientRect: TRect);
     function GetCurrentItem: TRootClass;
     function SwitchedByClick(const Point: TPoint): boolean;
   end;

implementation

{ TRadioGroup }

constructor TRadioGroup.Create(AGroupName: string; RightAnchor: boolean;
  const AItems: array of TRootClass);
var
  c: TRootClass;
begin
  Items := TList<TRootClass>.Create;
  for c in AItems do
    Items.Add(c);

  BaseImage := TBitmap.Create;
  BaseImage.LoadFromResourceName(HInstance, AGroupName);

  Location.Y := VertMargin;
  if not RightAnchor then
    Location.X := HorizMargin
  else
    Location.X := -HorizMargin - BaseImage.Width;
end;

destructor TRadioGroup.Destroy;
begin
  Items.Free;
  BaseImage.Free;
  inherited;
end;

procedure TRadioGroup.Draw(Canvas: IMyCanvas; const ClientRect: TRect);
var
  x, y: integer;
begin
  if Location.X < 0 then
    x := ClientRect.Right + Location.X
  else
    x := Location.X;
  y := Location.Y;
  LastPos := Point(x, y);
  Canvas.DrawBitmap(BaseImage, x, y);
  Inc(x, DotLeftMargin);
  Inc(y, DotTopMargin + ItemIndex * ItemsStep);
  Canvas.DrawBitmap(Dot, x, y);
end;

function TRadioGroup.GetCurrentItem: TRootClass;
begin
  Result := Items[ItemIndex];
end;


function TRadioGroup.SwitchedByClick(const Point: TPoint): boolean;
// обработка клика, возвращает True только если изменён выбранный элемент
var
  item_idx: integer;
begin
  if not PtInRect(Rect(LastPos.X,
                       LastPos.Y,
                       LastPos.X + BaseImage.Width,
                       LastPos.Y + BaseImage.Height),
                  Point)
  then
    Exit(False);

  item_idx := ItemAtPos(Point);
  Result := (item_idx <> -1) and (item_idx <> ItemIndex);
  if Result then
    ItemIndex := item_idx;
end;

function TRadioGroup.ItemAtPos(const Point: TPoint): integer;
// возвращает номер элемента по координате клика, либо -1
const

  ClickMarginX = DotLeftMargin - 2;// ширина некликабельных полей слева и справа
  ItemYBgn = -4;     // смещение начала кликабельной зоны от верхней грани точки
  ItemHeight = 16;   // высота кликабельной зоны элемента
var
  x, y, i: integer;
  y_from, y_to: integer;
begin
  Result := -1;
  x := Point.X - LastPos.X;
  if (x < ClickMarginX) or (x > BaseImage.Width - ClickMarginX) then
    Exit;

  y := Point.Y - LastPos.Y;
  for i := 0 to Items.Count - 1 do
  begin
    y_from := DotTopMargin + i * ItemsStep + ItemYBgn;
    y_to := y_from + ItemHeight;
    if (y_from <= y) and (y < y_to) then
    begin
      Result := i;
      break;
    end;
  end;
end;

initialization
  TRadioGroup.Dot := TBitmap.Create;
  TRadioGroup.Dot.LoadFromResourceName(HInstance, TRadioGroup.RadioButtonDot);

finalization
  TRadioGroup.Dot.Free;


end.
