unit ufrmcidades;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, ExtCtrls, DBGrids,
  StdCtrls, DB, uDM, uCidadesController, uRealcePesquisaDBGrid;

type

  { TfrmCidades }

  TfrmCidades = class(TForm)
    dsCidades: TDataSource;
    dbgCidades: TDBGrid;
    edtFiltro: TEdit;
    pnBottom: TPanel;
    pnNavigator: TPanel;
    pnTop: TPanel;
    procedure dbgCidadesTitleClick(Column: TColumn);
    procedure edtFiltroChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure dsCidadesDataChange(Sender: TObject; Field: TField);
  private
    FController: TCidadesController;
    FRealce: TRealcePesquisaDBGrid;
    FIDRegistroAtual: Int64;

  public
    procedure GarantirConsultaAtiva;

  end;

var
  frmCidades: TfrmCidades;

implementation

{$R *.lfm}

{ TfrmCidades }

procedure TfrmCidades.FormCreate(Sender: TObject);
begin
  FController := TCidadesController.Create(DM.CidadesModel, pnNavigator, dbgCidades);

  dsCidades.DataSet := FController.DataSet;

  FRealce := TRealcePesquisaDBGrid.Create(dbgCidades, DM.CidadesModel, edtFiltro);

  KeyPreview := True;
  FController.Inicializar;

  FIDRegistroAtual := 0;
  dsCidades.OnDataChange := @dsCidadesDataChange;
end;

procedure TfrmCidades.edtFiltroChange(Sender: TObject);
begin
  if FController <> nil then
    FController.Pesquisar(edtFiltro.Text);
end;

procedure TfrmCidades.dbgCidadesTitleClick(Column: TColumn);
begin
  if FController <> nil then
    FController.OrdenarPorCampo(Column.FieldName);
end;

procedure TfrmCidades.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FRealce);
  FreeAndNil(FController);
end;

procedure TfrmCidades.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FController <> nil then
    FController.TratarAtalho(Key, Shift);
end;

procedure TfrmCidades.dsCidadesDataChange(Sender: TObject; Field: TField);
begin
  if not dsCidades.DataSet.Active then
    Exit;

  if dsCidades.DataSet.IsEmpty then
    Exit;

  FIDRegistroAtual := dsCidades.DataSet.FieldByName('ID').AsLargeInt;
end;

procedure TfrmCidades.GarantirConsultaAtiva;
begin
  if not dsCidades.DataSet.Active then
    FController.RestaurarConsulta(FIDRegistroAtual);
end;

end.

