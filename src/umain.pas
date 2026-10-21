unit uMain;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, Controls, Dialogs, ComCtrls,
  ufrmnomes, ufrmcidades;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    PageControl1: TPageControl;
    tsNomes: TTabSheet;
    tsCidades: TTabSheet;
    procedure FormCreate(Sender: TObject);
  private
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  frmNomes := TfrmNomes.Create(Self);
  frmNomes.Parent := tsNomes;
  frmNomes.BorderStyle := bsNone;
  frmNomes.Align := alClient;
  frmNomes.Show;

  frmCidades := TfrmCidades.Create(Self);
  frmCidades.Parent := tsCidades;
  frmCidades.BorderStyle := bsNone;
  frmCidades.Align := alClient;
  frmCidades.Show;
end;

end.
