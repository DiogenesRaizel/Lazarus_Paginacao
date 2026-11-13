unit uCidadesModel;

{$mode ObjFPC}{$H+}

interface

uses
  uModelBase, SQLDB, SysUtils, uTiposPesquisa;

type

  { TCidadesModel }

  TCidadesModel = class(TModelBase)
  public
    function SQLBase: string; override;
    function SQLContagem: string; override;
    function OrdenarPor: string; override;
    function CamposPesquisa: TCampoPesquisaArray; override;

    function ConsultarSugestoes(const Valor: string): TSugestaoPesquisaArray;
  end;

implementation

function TCidadesModel.CamposPesquisa: TCampoPesquisaArray;
begin
  SetLength(Result, 3);

  Result[0].ExpressaoSQL := 'CAST(ID AS TEXT)';
  Result[0].CampoGrid := 'ID';

  Result[1].ExpressaoSQL := 'Cidade';
  Result[1].CampoGrid := 'Cidade';

  Result[2].ExpressaoSQL := 'UF';
  Result[2].CampoGrid := 'UF';
end;

function TCidadesModel.ConsultarSugestoes(const Valor: string): TSugestaoPesquisaArray;
var
  Q: TSQLQuery;
begin
  Result := nil;

  if Trim(Valor) = '' then
    Exit;

  Q := CriarConsultaAuxiliar;

  try
    Q.SQL.Text :=
      'SELECT ID, Cidade ' +
      'FROM cidades ' +
      'WHERE Cidade LIKE :Valor ' +
      'ORDER BY Cidade ' +
      'LIMIT 10';

    Q.ParamByName('Valor').AsString := '%' + Trim(Valor) + '%';
    Q.Open;

    while not Q.EOF do
    begin
      SetLength(Result, Length(Result) + 1);

      Result[High(Result)].ID := Q.FieldByName('ID').AsInteger;
      Result[High(Result)].Texto := Q.FieldByName('Cidade').AsString;

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TCidadesModel.SQLBase: string;
var
  FiltroSQL: string;
begin
  Result := 'SELECT ID, Cidade, UF FROM cidades';

  FiltroSQL := MontarWhere;

  if FiltroSQL <> '' then
    Result := Result + ' WHERE ' + FiltroSQL;
end;

function TCidadesModel.SQLContagem: string;
var
  FiltroSQL: string;
begin
  Result := 'SELECT COUNT(*) FROM cidades';

  FiltroSQL := MontarWhere;

  if FiltroSQL <> '' then
    Result := Result + ' WHERE ' + FiltroSQL;
end;

function TCidadesModel.OrdenarPor: string;
begin
  Result := 'ID';
end;

end.
