unit ufrmcidades;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, ExtCtrls, DBGrids,
  StdCtrls, DB, uDM, uPaginacaoDBGrid, uPaginadorSQL;

type

  { TfrmCidades }

  TfrmCidades = class(TForm)
    btnAlternarTabela: TButton;
    dsCidades: TDataSource;
    dbgCidades: TDBGrid;
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
  frmCidades: TfrmCidades;

implementation

{$R *.lfm}

{ TfrmCidades }

procedure TfrmCidades.FormCreate(Sender: TObject);
begin
  FPaginacao := TPaginacaoDBGrid.Create(pnNavigator);

  FPaginador := TPaginadorSQL.Create(
    DM.qryCidades,
    FPaginacao,
    dbgCidades
  );

  FPaginador.SQLBase := 'SELECT ID, Cidade, UF FROM cidades';
  FPaginador.SQLContagem := 'SELECT COUNT(*) FROM cidades';
  FPaginador.OrdenarPor := 'ID';

  KeyPreview := True;

  FPaginador.Abrir;
end;

procedure TfrmCidades.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPaginador);
  FreeAndNil(FPaginacao);
end;

procedure TfrmCidades.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  FPaginador.TratarAtalho(Key, Shift);
end;

procedure TfrmCidades.btnAlternarTabelaClick(Sender: TObject);
begin
  if not DM.qryCidades.Active then
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
