unit uPaginacao;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils;

type

  { TPaginacao }

  TPaginacao = class
  private
    FPaginaAtual: Integer;
    FTotalRegistros: Int64;
    FTotalPaginas: Integer;
    FLimitePorPagina: Integer;

    procedure RecalcularTotalPaginas;
    function GetOffset: Int64;

  public
    constructor Create(ALimitePorPagina: Integer = 10);

    procedure DefinirTotalRegistros(ATotal: Int64);
    procedure AlterarLimite(ALimite: Integer);

    function IrPara(APagina: Integer): Boolean;
    function PaginaDaPosicao(APosicao: Int64): Integer;

    procedure Primeira;
    procedure Anterior;
    procedure Proxima;
    procedure Ultima;

    property PaginaAtual: Integer read FPaginaAtual;
    property TotalRegistros: Int64 read FTotalRegistros;
    property TotalPaginas: Integer read FTotalPaginas;
    property LimitePorPagina: Integer read FLimitePorPagina;
    property Offset: Int64 read GetOffset;
  end;

implementation

constructor TPaginacao.Create(ALimitePorPagina: Integer);
begin
  inherited Create;

  if ALimitePorPagina <= 0 then
    raise Exception.Create('O limite deve ser maior que zero.');

  FPaginaAtual := 0;
  FTotalRegistros := 0;
  FTotalPaginas := 0;
  FLimitePorPagina := ALimitePorPagina;
end;

procedure TPaginacao.RecalcularTotalPaginas;
var
  QuantidadePaginas: Int64;
begin
  QuantidadePaginas := FTotalRegistros div FLimitePorPagina;

  if (FTotalRegistros mod FLimitePorPagina) <> 0 then
    Inc(QuantidadePaginas);

  if QuantidadePaginas > High(Integer) then
    raise Exception.Create(
      'A quantidade de páginas excede o limite suportado.');

  FTotalPaginas := Integer(QuantidadePaginas);

  if FTotalPaginas = 0 then
    FPaginaAtual := 0
  else if FPaginaAtual >= FTotalPaginas then
    FPaginaAtual := FTotalPaginas - 1;
end;

function TPaginacao.GetOffset: Int64;
begin
  Result := Int64(FPaginaAtual) * FLimitePorPagina;
end;

procedure TPaginacao.DefinirTotalRegistros(ATotal: Int64);
begin
  if ATotal < 0 then
    raise Exception.Create(
      'O total de registros não pode ser negativo.');

  FTotalRegistros := ATotal;
  RecalcularTotalPaginas;
end;

procedure TPaginacao.AlterarLimite(ALimite: Integer);
begin
  if ALimite <= 0 then
    raise Exception.Create('O limite deve ser maior que zero.');

  if FLimitePorPagina = ALimite then
    Exit;

  FLimitePorPagina := ALimite;
  FPaginaAtual := 0;

  RecalcularTotalPaginas;
end;

function TPaginacao.IrPara(APagina: Integer): Boolean;
begin
  Result := False;

  if (APagina < 0) or (APagina >= FTotalPaginas) then
    Exit;

  FPaginaAtual := APagina;
  Result := True;
end;

function TPaginacao.PaginaDaPosicao(APosicao: Int64): Integer;
begin
  Result := -1;

  if (APosicao < 1) or (APosicao > FTotalRegistros) then
    Exit;

  Result := Integer((APosicao - 1) div FLimitePorPagina);
end;

procedure TPaginacao.Primeira;
begin
  IrPara(0);
end;

procedure TPaginacao.Anterior;
begin
  IrPara(FPaginaAtual - 1);
end;

procedure TPaginacao.Proxima;
begin
  IrPara(FPaginaAtual + 1);
end;

procedure TPaginacao.Ultima;
begin
  IrPara(FTotalPaginas - 1);
end;

end.
