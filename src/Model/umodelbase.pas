unit uModelBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, DB, Variants;

type
  TCampoPesquisa = record
    ExpressaoSQL: string;
    CampoGrid: string;
  end;

  TCampoPesquisaArray = array of TCampoPesquisa;

  { TModelBase }

  TModelBase = class
  private
    FConsulta: TSQLQuery;
    FTransacao: TSQLTransaction;
    FFiltro: string;
    function SepararTermos: TStringList;
    procedure ConsultaAfterOpen(DataSet: TDataSet);

  protected
    function MontarWhere: string;
    function CriarQueryAuxiliar: TSQLQuery;
    function ExecutarComando(const ASQL: string; const AParametros: array of Variant): Integer;
    function ExecutarInsercao(const ASQL: string; const AParametros: array of Variant): Int64;
    function CampoIdentificador: string; virtual;

  public
    constructor Create(AConexao: TSQLConnection; ATransacao: TSQLTransaction);
    destructor Destroy; override;

    function SQLBase: string; virtual; abstract;
    function SQLContagem: string; virtual; abstract;
    function OrdenarPor: string; virtual; abstract;
    function CamposPesquisa: TCampoPesquisaArray; virtual; abstract;

    procedure DefinirFiltro(const Valor: string); virtual;
    procedure PrepararConsulta(Sender: TObject; AQuery: TSQLQuery); virtual;

    property Consulta: TSQLQuery read FConsulta;
    property Identificador: string read CampoIdentificador;
  end;

procedure ExecutarDDL(AConexao: TSQLConnection; ATransacao: TSQLTransaction; const ASQL: string);
function TabelaVazia(AConexao: TSQLConnection; ATransacao: TSQLTransaction; const ATabela: string): Boolean;

implementation

constructor TModelBase.Create(AConexao: TSQLConnection; ATransacao: TSQLTransaction);
begin
  inherited Create;

  if AConexao = nil then
    raise Exception.Create('A conexão não foi informada.');

  if ATransacao = nil then
    raise Exception.Create('A transação não foi informada.');

  FTransacao := ATransacao;

  FConsulta := TSQLQuery.Create(nil);
  FConsulta.DataBase := AConexao;
  FConsulta.Transaction := FTransacao;
  FConsulta.AfterOpen := @ConsultaAfterOpen;
  FFiltro := '';
end;

destructor TModelBase.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited Destroy;
end;

procedure TModelBase.DefinirFiltro(const Valor: string);
begin
  FFiltro := Valor;
end;

function TModelBase.SepararTermos: TStringList;
var
  I: Integer;
begin
  Result := TStringList.Create;
  Result.StrictDelimiter := True;
  Result.Delimiter := ',';
  Result.DelimitedText := FFiltro;

  for I := Result.Count - 1 downto 0 do
  begin
    Result[I] := Trim(Result[I]);

    if Result[I] = '' then
      Result.Delete(I);
  end;
end;

procedure TModelBase.ConsultaAfterOpen(DataSet: TDataSet);
var
  Campo: TField;
begin
  Campo := DataSet.FindField(CampoIdentificador);

  if (Campo = nil) or not (Campo is TNumericField) then
    Exit;

  Campo.Alignment := taLeftJustify;
  TNumericField(Campo).DisplayFormat := '0000';
end;

function TModelBase.MontarWhere: string;
var
  Termos: TStringList;
  Campos: TCampoPesquisaArray;
  I, J: Integer;
  Grupo: string;
begin
  Result := '';
  Termos := SepararTermos;

  try
    if Termos.Count = 0 then
      Exit;

    Campos := CamposPesquisa;

    for I := 0 to Termos.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ' OR ';

      Grupo := '';

      for J := Low(Campos) to High(Campos) do
      begin
        if Grupo <> '' then
          Grupo := Grupo + ' OR ';

        Grupo := Grupo + Campos[J].ExpressaoSQL +
          ' LIKE :p' + IntToStr(I);
      end;

      Result := Result + '(' + Grupo + ')';
    end;
  finally
    Termos.Free;
  end;
end;

function TModelBase.CriarQueryAuxiliar: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);

  try
    Result.DataBase := FConsulta.DataBase;
    Result.Transaction := FTransacao;
  except
    Result.Free;
    raise;
  end;
end;

function TModelBase.ExecutarComando(const ASQL: string; const AParametros: array of Variant): Integer;
var
  Q: TSQLQuery;
  I: Integer;
begin
  Q := CriarQueryAuxiliar;

  try
    if not FTransacao.Active then
      FTransacao.StartTransaction;

    try
      Q.SQL.Text := ASQL;

      for I := Low(AParametros) to High(AParametros) do
        Q.ParamByName('p' + IntToStr(I)).Value := AParametros[I];

      Q.ExecSQL;

      Result := Q.RowsAffected;

      FTransacao.Commit;
    except
      if FTransacao.Active then
        FTransacao.Rollback;

      raise;
    end;
  finally
    Q.Free;
  end;
end;

function TModelBase.ExecutarInsercao(const ASQL: string;
  const AParametros: array of Variant): Int64;
var
  Q: TSQLQuery;
  I: Integer;
begin
  Q := CriarQueryAuxiliar;

  try
    if not FTransacao.Active then
      FTransacao.StartTransaction;

    try
      Q.SQL.Text := ASQL;

      for I := Low(AParametros) to High(AParametros) do
        Q.ParamByName('p' + IntToStr(I)).Value := AParametros[I];

      Q.ExecSQL;

      Q.SQL.Text := 'SELECT last_insert_rowid()';
      Q.Open;

      Result := Q.Fields[0].AsLargeInt;

      Q.Close;

      FTransacao.Commit;
    except
      if FTransacao.Active then
        FTransacao.Rollback;

      raise;
    end;
  finally
    Q.Free;
  end;
end;

function TModelBase.CampoIdentificador: string;
begin
  Result := 'ID';
end;

procedure TModelBase.PrepararConsulta(Sender: TObject; AQuery: TSQLQuery);
var
  Termos: TStringList;
  I: Integer;
begin
  if AQuery = nil then
    Exit;

  Termos := SepararTermos;
  try
    for I := 0 to Termos.Count - 1 do
      AQuery.ParamByName('p' + IntToStr(I)).AsString := '%' + Termos[I] + '%';
  finally
    Termos.Free;
  end;
end;

procedure ExecutarDDL(AConexao: TSQLConnection; ATransacao: TSQLTransaction; const ASQL: string);
var
  Q: TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := AConexao;
    Q.Transaction := ATransacao;
    Q.SQL.Text := ASQL;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TabelaVazia(AConexao: TSQLConnection; ATransacao: TSQLTransaction; const ATabela: string): Boolean;
var
  Q: TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := AConexao;
    Q.Transaction := ATransacao;
    Q.SQL.Text := 'SELECT COUNT(*) FROM ' + ATabela;
    Q.Open;
    Result := Q.Fields[0].AsInteger = 0;
    Q.Close;
  finally
    Q.Free;
  end;
end;

end.
