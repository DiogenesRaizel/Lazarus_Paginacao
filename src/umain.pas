unit uMain;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, Controls, Dialogs, ComCtrls,
  ufrmnomes, Classes;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pgMain: TPageControl;
    tsNomes: TTabSheet;
    tsCidades: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure pgMainChange(Sender: TObject);
  private
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Font.Size := 12;
  pgMain.ActivePageIndex:= 0;

  frmNomes := TfrmNomes.Create(Self);
  frmNomes.Parent := tsNomes;
  frmNomes.BorderStyle := bsNone;
  frmNomes.Align := alClient;
  frmNomes.Show;
  {
  frmCidades := TfrmCidades.Create(Self);
  frmCidades.Parent := tsCidades;
  frmCidades.BorderStyle := bsNone;
  frmCidades.Align := alClient;
  frmCidades.Show;
}
end;

procedure TfrmMain.pgMainChange(Sender: TObject);
begin
  if pgMain.ActivePage = tsNomes then
    frmNomes.GarantirConsultaAtiva;
 // else if pgMain.ActivePage = tsCidades then
//    frmCidades.GarantirConsultaAtiva;
end;

end.
