unit Walkers;

interface

uses Canvases, RootObject;

type
  IWalker = interface
  ['{8D1FF79F-4251-4A1D-8214-0ADE721C009B}']
    procedure SetAngle(Val: extended);
    function GetAngle: extended;
    property Angle: extended read GetAngle write SetAngle;
    procedure Turn(AAngle: extended);
    procedure Forward(Canvas: IMyCanvas; Distance: extended);
  end;

  TAngleHolder = class(TRootObject)
  protected
    Angle: extended;

    procedure SetAngle(Val: extended);
    function GetAngle: extended;
    procedure Turn(AAngle: extended);
  public
    constructor Create; override;
  end;

  TStraightWalker = class(TAngleHolder, IWalker)
  public
    procedure Forward(Canvas: IMyCanvas; Distance: extended);
  end;

  TCurveWalker = class(TStraightWalker, IWalker)
  public
    procedure Forward(Canvas: IMyCanvas; Distance: extended);
  end;

implementation

{ TAngleHolder }

constructor TAngleHolder.Create;
begin
end;

procedure TAngleHolder.SetAngle(Val: extended);
begin
  Angle := Val;
end;

function TAngleHolder.GetAngle: extended;
begin
  Result := Angle;
end;

procedure TAngleHolder.Turn(AAngle: extended);
begin
  Angle := Angle + AAngle;
end;

{ TStraightWalker }

procedure TStraightWalker.Forward(Canvas: IMyCanvas; Distance: extended);
var
  p: TPointEx;
begin
  p := Canvas.GetCurPoint;
  p.X := p.X + Distance * cos(Angle);
  p.Y := p.Y + Distance * sin(Angle);
  Canvas.LineTo(p)
end;

{ TCurveWalker }

procedure TCurveWalker.Forward(Canvas: IMyCanvas; Distance: extended);
const
  pcnt = 8; // кол-во сегментов на которое разбиваем дистанцию
  turn = 0.0375 * pi; // угол повората между сегментами
var
  ang: extended;
  dist: extended;
  i: integer;
begin
  ang := Angle;
  dist := Distance / pcnt;
  for i := 1 to pcnt do
  begin
    inherited Forward(Canvas, dist);
    Angle := ang + i * turn;
  end;
  Angle := ang;
end;

end.
