unit uCidadesController;

{$mode ObjFPC}{$H+}

interface

uses
  Controls, DBGrids, ExtCtrls,
  uControllerBase, uCidadesModel, uTiposPesquisa;

type
  TCidadesController = class(TControllerBase)
  private
    FCidadesModel: TCidadesModel;
  public
    constructor Create(AModel: TCidadesModel; APainel: TPanel; AGrade: TDBGrid);

    function ConsultarSugestoes(const Valor: string): TSugestaoPesquisaArray;
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

end.
