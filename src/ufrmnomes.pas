unit ufrmnomes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, DBGrids,
  StdCtrls, DB, uDM, uPaginacaoDBGrid, uPaginadorSQL;

type

  { TfrmNomes }

  TfrmNomes = class(TForm)
    btnAlternarTabela: TButton;
    dbgNomes: TDBGrid;
    dsNomes: TDataSource;
    pnBottom: TPanel;
    pnNavigator: TPanel;
    pnTop: TPanel;
    procedure btnAlternarTabelaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FPaginacao: TPaginacaoDBGrid;
    FPaginador: TPaginadorSQL;

  public

  end;

var
  frmNomes: TfrmNomes;

implementation

{$R *.lfm}

{ TfrmNomes }

procedure TfrmNomes.FormCreate(Sender: TObject);
begin
  FPaginacao := TPaginacaoDBGrid.Create(pnNavigator);

  FPaginador := TPaginadorSQL.Create(
    DM.qryNomes,
    FPaginacao,
    dbgNomes
  );

  FPaginador.SQLBase := 'SELECT ID, Nome FROM nomes';
  FPaginador.SQLContagem := 'SELECT COUNT(*) FROM nomes';
  FPaginador.OrdenarPor := 'ID';

  KeyPreview := True;

  FPaginador.Abrir;
end;

procedure TfrmNomes.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPaginador);
  FreeAndNil(FPaginacao);
end;

procedure TfrmNomes.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  FPaginador.TratarAtalho(Key, Shift);
end;

procedure TfrmNomes.btnAlternarTabelaClick(Sender: TObject);
begin
  if not DM.qryNomes.Active then
  begin
    FPaginador.Abrir;
    pnNavigator.Visible := True;
    btnAlternarTabela.Caption := 'Fechar Tabela';
  end
  else
  begin
    FPaginador.Fechar;
    pnNavigator.Visible := False;
    btnAlternarTabela.Caption := 'Abrir Tabela';
  end;
end;

end.
