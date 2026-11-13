unit uCidadesController;

{$mode ObjFPC}{$H+}

interface

uses
  Controls, DBGrids, ExtCtrls,
  uControllerBase, uCidadesModel, uTiposPesquisa;

type

  { TCidadesController }

  TCidadesController = class(TControllerBase)
  private
    FCidadesModel: TCidadesModel;
  public
    constructor Create(AModel: TCidadesModel; APainel: TPanel; AGrade: TDBGrid);

    function ConsultarSugestoes(const Valor: string): TSugestaoPesquisaArray;

    procedure RestaurarConsulta(AID: Int64);
  end;

implementation

constructor TCidadesController.Create(AModel: TCidadesModel; APainel: TPanel; AGrade: TDBGrid);
begin
  inherited Create(AModel, APainel, AGrade);
  FCidadesModel := AModel;
end;

function TCidadesController.ConsultarSugestoes(const Valor: string): TSugestaoPesquisaArray;
begin
  Result := FCidadesModel.ConsultarSugestoes(Valor);
end;

procedure TCidadesController.RestaurarConsulta(AID: Int64);
begin
  if FPaginador <> nil then
  begin
    ConfigurarPaginador;

    if AID > 0 then
      FPaginador.AbrirNoRegistro(AID)
    else
      FPaginador.Abrir;
  end
  else
  begin
    AtualizarConsulta;

    if (AID > 0) and DataSet.Active then
      DataSet.Locate('ID', AID, []);
  end;
end;

end.
