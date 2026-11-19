unit uNomesController;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils,
  uControllerBase, uNomesModel, uCidadesModel, uTiposPesquisa, uTiposCadastro;

type

  { TNomesController }

  TNomesController = class(TControllerBase)
  private
    FNomesModel: TNomesModel;
    FCidadesModel: TCidadesModel;

  public
    constructor Create(AModel: TNomesModel; ACidadesModel: TCidadesModel);

    function ConsultarSugestoesCidade(const Valor: string): TSugestaoPesquisaArray;
    function Inserir(const ANome: string; ACidadeID: Integer): Int64;
    function Atualizar(AID: Int64; const ANome: string; ACidadeID: Integer): Integer;
    function Excluir(AID: Int64): Integer;
    function Salvar(const ANome: string; ACidadeID: Integer; out AIDRegistro: Int64): Boolean;
  end;

implementation

constructor TNomesController.Create(AModel: TNomesModel;
  ACidadesModel: TCidadesModel);
begin
  if AModel = nil then
    raise Exception.Create('O Model de nomes não foi informado.');

  if ACidadesModel = nil then
    raise Exception.Create('O Model de cidades não foi informado.');

  inherited Create(AModel);

  FNomesModel := AModel;
  FCidadesModel := ACidadesModel;
end;

function TNomesController.ConsultarSugestoesCidade(
  const Valor: string): TSugestaoPesquisaArray;
begin
  Result := FCidadesModel.ConsultarSugestoes(Valor);
end;

function TNomesController.Inserir(const ANome: string;
  ACidadeID: Integer): Int64;
begin
  if Trim(ANome) = '' then
    raise Exception.Create('Informe o nome.');

  if ACidadeID <= 0 then
    raise Exception.Create('Selecione uma cidade válida.');

  Result := FNomesModel.Inserir(Trim(ANome), ACidadeID);

  if Result <= 0 then
    raise Exception.Create('Não foi possível obter o ID do registro inserido.');
end;

function TNomesController.Atualizar(AID: Int64; const ANome: string;
  ACidadeID: Integer): Integer;
begin
  if AID <= 0 then
    raise Exception.Create('Registro inválido.');

  if Trim(ANome) = '' then
    raise Exception.Create('Informe o nome.');

  if ACidadeID <= 0 then
    raise Exception.Create('Selecione uma cidade válida.');

  Result := FNomesModel.Atualizar(AID, Trim(ANome), ACidadeID);

  if Result = 0 then
    raise Exception.Create('Nenhum registro foi atualizado.');
end;

function TNomesController.Excluir(AID: Int64): Integer;
begin
  if AID <= 0 then
    raise Exception.Create('Registro inválido.');

  Result := FNomesModel.Excluir(AID);

  if Result = 0 then
    raise Exception.Create('Nenhum registro foi excluído.');
end;

function TNomesController.Salvar(const ANome: string;
  ACidadeID: Integer; out AIDRegistro: Int64): Boolean;
var
  IDAnterior: Int64;
  Modo: TModoCadastro;
begin
  Result := False;
  AIDRegistro := 0;

  Modo := ModoCadastro;

  if not (Modo in [
    mcInclusaoCadastro, mcInclusaoTabela,
    mcEdicaoCadastro, mcEdicaoTabela
  ]) then
    Exit;

  if Modo in [mcInclusaoCadastro, mcInclusaoTabela] then
  begin
    IDAnterior := 0;

    if DataSet.Active and not DataSet.IsEmpty then
      IDAnterior := DataSet.FieldByName(Identificador).AsLargeInt;

    AIDRegistro := Inserir(ANome, ACidadeID);

    ConfirmarOperacao;
    RestaurarAposInclusao(AIDRegistro, IDAnterior);
  end
  else
  begin
    if not DataSet.Active or DataSet.IsEmpty then
      raise Exception.Create('Não há registro selecionado.');

    AIDRegistro := DataSet.FieldByName(Identificador).AsLargeInt;

    Atualizar(AIDRegistro, ANome, ACidadeID);

    ConfirmarOperacao;
    RestaurarConsulta(AIDRegistro);
  end;

  Result := True;
end;

end.
