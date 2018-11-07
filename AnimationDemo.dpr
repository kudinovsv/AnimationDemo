program AnimationDemo;

{$R 'Bitmaps.res' 'Bitmaps.rc'}

uses
  Canvases in 'Canvases.pas',
  RootObject in 'RootObject.pas',
  Walkers in 'Walkers.pas',
  Window in 'Window.pas',
  RadioGroup in 'RadioGroup.pas';

{$R *.res}

begin
  with TWindow.Create(
                      TRadioGroup.Create(TRadioGroup.CanvasRadioGroup,
                                         False, [TVclCanvas, TGdiPlusCanvas]),

                      TRadioGroup.Create(TRadioGroup.WalkerRadioGroup,
                                         True, [TCurveWalker, TStraightWalker]))
  do
  try
    Execute;
  finally
    Free;
  end;

end.
