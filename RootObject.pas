unit RootObject;

interface

type
   // общий предок всех классов переключаемых в рантайме объектов:
   // TVclCanvas, TGdiPlusCanvas, TStraightWalker, TCurveWalker
   TRootObject = class(TInterfacedObject)
     constructor Create; virtual; abstract;
   end;
   TRootClass = class of TRootObject;

implementation

end.
