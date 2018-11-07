unit Window;

interface

uses Windows, Messages, SysUtils, Classes, Graphics, MMSystem, Math,
  Canvases, Walkers, RadioGroup;

type
  TWindow = class
  private
    Wnd: HWND;
    WndDC: HDC;
    BmpDC: HDC;             // контекст холста битмапа
    ClientRect: TRect;

    Canvas: IMyCanvas;      // холст
    Walker: IWalker;        // инструмент рисования

    CurSecondNum: integer;    // номер текущей секунды
    FramesCounter: integer;   // кол-во кадров отрисованных в текущей секунде
    LastFps: integer;         // кол-во кадров отрисованных в предыдущей секунде
    PerformanceFrequency: int64;
    TimerID: DWORD;

    CanvasRadioGroup: TRadioGroup;
    WalkerRadioGroup: TRadioGroup;

    class function WindowProc(Window: HWnd;
      AMsg, WParam, LParam: LongInt): LongInt; stdcall; static;

    class procedure TimerProc(
      uTimerID, uMessage, dwUser, dw1, dw2: DWORD); stdcall; static;

    procedure WM_Create(var Msg: TMessage); message WM_CREATE;
    procedure WM_Destroy(var Msg: TMessage); message WM_DESTROY;
    procedure WM_Size(var Msg: TMessage); message WM_SIZE;
    procedure WM_Timer(var Msg: TMessage); message WM_TIMER;
    procedure WM_MouseButton(var Msg: TMessage); message WM_LBUTTONDOWN;

    procedure Paint;

  public
    constructor Create(ACanvasRadioGroup: TRadioGroup;
      AWalkerRadioGroup: TRadioGroup);
    function Execute: integer;
    procedure DefaultHandler(var Msg); override;
  end;

implementation

{ TWindow }

constructor TWindow.Create(ACanvasRadioGroup: TRadioGroup;
  AWalkerRadioGroup: TRadioGroup);
const
  WndClassName = 'DemoWndClass';
var
  WndClass: TWndClass;
begin
  CanvasRadioGroup := ACanvasRadioGroup;
  WalkerRadioGroup := AWalkerRadioGroup;

  FillChar(WndClass, SizeOf(WndClass), 0);
  with WndClass do
  begin
    lpfnWndProc := @WindowProc;
    lpszClassName := WndClassName;
    hCursor := LoadCursor(0, IDC_ARROW);
    hbrBackground := GetStockObject(WHITE_BRUSH);
  end;

  if Windows.RegisterClass(WndClass) = 0 then
  begin
    MessageBox(0, 'Cannot register class', 'Error', MB_ICONERROR);
    Halt(255);
  end;

  CreateWindow(
      WndClassName,
      'Demo Application',
      ws_OverlappedWindow,
      Integer(CW_USEDEFAULT),
      Integer(CW_USEDEFAULT),
      Integer(CW_USEDEFAULT),
      Integer(CW_USEDEFAULT),
      0,
      0,
      HInstance,
      Self);     // передаём Self, чтобы поймать его в WindowProc (WM_NCCREATE)


  ShowWindow(Wnd, SW_SHOWNORMAL);
  UpdateWindow(Wnd);
end;

procedure TWindow.WM_Create(var Msg: TMessage);
var
  bm: HBITMAP;
begin
  Canvas := CanvasRadioGroup.GetCurrentItem.Create as IMyCanvas;
  Walker := WalkerRadioGroup.GetCurrentItem.Create as IWalker;

  GetClientRect(Wnd, ClientRect);
  WndDC := GetDC(Wnd);
  BmpDC := CreateCompatibleDC(WndDC);
  bm := CreateCompatibleBitmap(WndDC, ClientRect.Right, ClientRect.Bottom);
  DeleteObject(SelectObject(BmpDC, bm));
  Canvas.SetDC(BmpDC);
  QueryPerformanceFrequency(PerformanceFrequency);
  TimerID := timeSetEvent(1, 1, @TimerProc, Cardinal(Self), TIME_PERIODIC);
end;

class function TWindow.WindowProc(Window: HWnd;
  AMsg, WParam, LParam: LongInt): LongInt;
var
  Instance: TWindow;
  Msg: TMessage;
begin
  if AMsg = WM_NCCREATE then
  begin
    Instance := PCreateStruct(LParam).lpCreateParams;
    // поймали Self, привяжем его на будущее к окну через GWL_USERDATA
    SetWindowLong(Window, GWL_USERDATA, Integer(Instance));
    Instance.Wnd := Window;
  end
  else
  begin
    // получаем Self из GWL_USERDATA
    Instance := Pointer(GetWindowLong(Window, GWL_USERDATA));
    if Instance = nil then
      Exit(DefWindowProc(Window, AMsg, wParam, lParam));
  end;

  Msg.Msg := AMsg;
  Msg.WParam := WParam;
  Msg.LParam := LParam;
  Msg.Result := 0;
  Instance.Dispatch(Msg);
  Result := Msg.Result;
end;

class procedure TWindow.TimerProc(uTimerID, uMessage, dwUser, dw1, dw2: DWORD);
begin
  // будем обрабатывать в главном потоке
  SendMessage(TWindow(dwUser).Wnd, Messages.WM_TIMER, 0, 0);
end;

function TWindow.Execute: integer;
var
  Msg: TMsg;
begin
  while GetMessage(Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
  Result := Msg.WParam;
end;

procedure TWindow.WM_Timer(var Msg: TMessage);
begin
  Paint;                     // рисуем на битмапе,
  BitBlt(WndDC,              // копируем на окно
         0,
         0,
         ClientRect.Right,
         ClientRect.Bottom,
         BmpDC,
         0,
         0,
         SRCCOPY);
end;

procedure TWindow.WM_Size(var Msg: TMessage);
var
  bm: HBITMAP;
begin
  ClientRect := Rect(0, 0, Msg.LParamLo, Msg.LParamHi);
  // если размеры битмапа уменьшатся до нуля, потеряется информация о его
  // цвето-типе, чтобы не допустить этого ограничиваем уменьшение:
  bm := CreateCompatibleBitmap(BmpDC,
                               Max(ClientRect.Right, 1),
                               Max(ClientRect.Bottom, 1));

  // при работе с GDI+ нельзя так просто взять и заменить битмэпку в HDC,
  // поэтому приходится предварительно удалить контекст GDI+,
  // заменить битпэпку и создать контекст заново:
  Canvas.SetDC(0);
  DeleteObject(SelectObject(BmpDC, bm));
  Canvas.SetDC(BmpDC);
end;

procedure TWindow.Paint;
const
  top_margin = 18;  // высота поля под вывод строки с fps
var
  i: integer;
  step: extended;
  tick: int64;
  second_num: word;
  pnt: TPointEx;
  str: string;
begin
  QueryPerformanceCounter(tick);
  Walker.Angle := tick / PerformanceFrequency; // начальный угол поворота

  second_num := Trunc(Walker.Angle);  // номер текущей секунды
  if second_num = CurSecondNum  then
    Inc(FramesCounter)
  else
  begin
    CurSecondNum := second_num;
    LastFps := FramesCounter;
    FramesCounter := 1;
  end;

  Canvas.SetBrushColor(clWhite);
  Canvas.FillRect(ClientRect);
  Canvas.SetPen(clBlue, 2);

  // центр области рисования
  pnt.X := ClientRect.Right / 2;
  pnt.Y := ClientRect.Bottom / 2 + top_margin div 2 - 1;
  Canvas.MoveTo(pnt);

  // рисуем фигуру
  step := Min(ClientRect.Right, ClientRect.Bottom - top_margin) * 0.47;
  for i := 1 to 12 do
  begin
    Walker.Forward(Canvas, step);
    Walker.Turn(5 / 6 * pi);
  end;

  CanvasRadioGroup.Draw(Canvas, ClientRect);
  WalkerRadioGroup.Draw(Canvas, ClientRect);

  str := IntToStr(LastFps) + ' fps';
  Canvas.TextOut(Point((ClientRect.Right - Canvas.TextWidth(str)) shr 1, 4),
                 str);
end;

procedure TWindow.WM_MouseButton(var Msg: TMessage);
begin
  if CanvasRadioGroup.SwitchedByClick(Point(Msg.LParamLo, Msg.LParamHi)) then
  begin
    Canvas := CanvasRadioGroup.GetCurrentItem.Create as IMyCanvas;
    Canvas.SetDC(BmpDC);
    Exit;
  end;

  if WalkerRadioGroup.SwitchedByClick(Point(Msg.LParamLo, Msg.LParamHi)) then
    Walker := WalkerRadioGroup.GetCurrentItem.Create as IWalker;
end;

procedure TWindow.WM_Destroy(var Msg: TMessage);
begin
  CanvasRadioGroup.Free;
  WalkerRadioGroup.Free;
  timeKillEvent(TimerID);
  ReleaseDC(Wnd, WndDc);
  PostQuitMessage(0);
end;

procedure TWindow.DefaultHandler(var Msg);
begin
  with TMessage(Msg) do
    Result := DefWindowProc(Wnd, Msg, WParam, LParam);
end;


end.
