UNIT MyFastReportAddonsReg;

INTERFACE
procedure Register;

IMPLEMENTATION
uses MyFrxPDFPage, Classes;

//##############################################################################
procedure Register;
begin
  RegisterComponents('My FastReport Addons',
                     [TMyFrxPDFPageViewObject]);
end;
//------------------------------------------------------------------------------



END.
