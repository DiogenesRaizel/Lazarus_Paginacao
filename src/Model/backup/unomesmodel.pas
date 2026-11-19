unit uNomesModel;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, SQLDB, uModelBase;

type

  { TNomesModel }

  TNomesModel = class(TModelBase)
  protected
    function CampoOrdenacaoSQL(const ACampo: string): string; override;

  public
    function SQLBase: string; override;
    function SQLContagem: string; override;
    function OrdenarPor: string; override;
    function CamposPesquisa: TCampoPesquisaArray; override;

    function Inserir(const ANome: string; ACidadeID: Integer): Int64;

    function Atualizar(AID: Int64; const ANome: string;
      ACidadeID: Integer): Integer;

    function Excluir(AID: Int64): Integer;
  end;

implementation

{
function TNomesModel.CampoOrdenacaoSQL(
  const ACampo: string): string;
begin
  if SameText(ACampo, 'ID') then
    Exit('ID');

  if SameText(ACampo, 'Nome') then
    Exit('Nome');

  if SameText(ACampo, 'Cidade') then
    Exit('Cidade');

  raise Exception.Create(
    'Campo não permitido para ordenação: ' + ACampo
  );
end;
}

function TNomesModel.CampoOrdenacaoSQL(
  const ACampo: string): string;
begin
  if SameText(ACampo, 'ID') then
    Exit('ID');

  if SameText(ACampo, 'Nome') then
    Exit('Nome');

  if SameText(ACampo, 'CidadeID') or
     SameText(ACampo, 'ID_Cidade') then
    Exit('CidadeID');

  if SameText(ACampo, 'Cidade') then
    Exit('Cidade');

  raise Exception.Create(
    'Campo não permitido para ordenação: ' + ACampo
  );
end;

function TNomesModel.CamposPesquisa: TCampoPesquisaArray;
begin
  SetLength(Result, 3);

  Result[0].ExpressaoSQL := 'CAST(n.ID AS TEXT)';
  Result[0].CampoGrid := 'ID';

  Result[1].ExpressaoSQL := 'n.Nome';
  Result[1].CampoGrid := 'Nome';

  Result[2].ExpressaoSQL := 'c.Cidade';
  Result[2].CampoGrid := 'Cidade';
end;

function TNomesModel.Inserir(const ANome: string;
  ACidadeID: Integer): Int64;
begin
  Result := ExecutarInsercao(
    'INSERT INTO nomes (Nome, CidadeID) VALUES (:p0, :p1)',
    [ANome, ACidadeID]
  );
end;

function TNomesModel.Atualizar(AID: Int64; const ANome: string;
  ACidadeID: Integer): Integer;
begin
  Result := ExecutarComando(
    'UPDATE nomes SET Nome = :p0, CidadeID = :p1 WHERE ID = :p2',
    [ANome, ACidadeID, AID]
  );
end;

function TNomesModel.Excluir(AID: Int64): Integer;
begin
  Result := ExecutarComando(
    'DELETE FROM nomes WHERE ID = :p0',
    [AID]
  );
end;

function TNomesModel.SQLBase: string;
var
  FiltroSQL: string;
begin
  Result :=
    'SELECT n.ID AS ID, n.Nome AS Nome, ' +
    'c.ID AS CidadeID, c.ID AS ID_Cidade, c.Cidade AS Cidade ' +
    'FROM nomes n ' +
    'INNER JOIN cidades c ON c.ID = n.CidadeID';

  FiltroSQL := MontarWhere;

  if FiltroSQL <> '' then
    Result := Result + ' WHERE ' + FiltroSQL;
end;

function TNomesModel.SQLContagem: string;
var
  FiltroSQL: string;
begin
  Result :=
    'SELECT COUNT(*) ' +
    'FROM nomes n ' +
    'INNER JOIN cidades c ON c.ID = n.CidadeID';

  FiltroSQL := MontarWhere;

  if FiltroSQL <> '' then
    Result := Result + ' WHERE ' + FiltroSQL;
end;

function TNomesModel.OrdenarPor: string;
begin
  Result := 'ID';
end;

end.
