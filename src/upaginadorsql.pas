unit uPaginadorSQL;

{ Logica de dados da paginacao (COUNT, LIMIT/OFFSET, pagina atual),
  independente da tabela e do formulario.

  Liga uma TSQLQuery a um TPaginacaoDBGrid (interface) ja existente:
  assume os eventos do TPaginacaoDBGrid, entao o formulario nao precisa
  mais de handlers de navegacao.

  Regras de uso:
  - SQLBase: SELECT sem ORDER BY, LIMIT/OFFSET e sem ';' no final.
  - SQLContagem: SELECT COUNT(*) com o mesmo FROM/WHERE do SQLBase.
  - OrdenarPor: opcional (sem ele a ordem das linhas nao e garantida).
  - Consulta com parametros (WHERE x = :X): use OnPrepararConsulta; o
    evento e chamado para a consulta de contagem e para a principal.
  - Apos incluir/excluir registros, ou mudar um filtro, chame Abrir
    (mantem a pagina) ou Reiniciar (volta para a primeira pagina).
  - Libere o TPaginadorSQL ANTES do TPaginacaoDBGrid.
  - A TSQLQuery principal pertence ao projeto: a classe nao a libera. }

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Dialogs, LCLType, DB, SQLDB,
  uPaginacaoDBGrid;

type

  TPrepararConsultaEvent = procedure(Sender: TObject;
    AQuery: TSQLQuery) of object;

  { TPaginadorSQL }

  TPaginadorSQL = class
  private
    FConsulta: TSQLQuery;
    FContagem: TSQLQuery;
    FPaginacao: TPaginacaoDBGrid;
    FGrade: TWinControl;
    FSQLBase: string;
    FSQLContagem: string;
    FOrdenarPor: string;
    FPaginaAtual: Integer;
    FTotalRegistros: Integer;
    FTotalPaginas: Integer;
    FLimiteAtual: Integer;
    FCampoOrdenacao: string;
    FOrdemAscendente: Boolean;
    FOnPrepararConsulta: TPrepararConsultaEvent;
    FOnAtualizarInterface: TNotifyEvent;
    FCampoIdentificador: string;
    function MontarSQLBase: string;
    function CampoIdentificadorSQL: string;
    function PaginaDoRegistro(AID: Int64): Integer;
    procedure SetCampoIdentificador(const Valor: string);
    procedure Atualizar(ALimite: Integer);
    procedure ExecutarConsulta;
    procedure PrepararConsulta(AQuery: TSQLQuery);
    procedure AtualizarInterface;
    procedure FinalizarNavegacao;
    procedure PrimeiraPaginaEvento(Sender: TObject);
    procedure PaginaAnteriorEvento(Sender: TObject);
    procedure ProximaPaginaEvento(Sender: TObject);
    procedure UltimaPaginaEvento(Sender: TObject);
    procedure AlterarLimiteEvento(Sender: TObject; ALimite: Integer);
    procedure IrParaPaginaEvento(Sender: TObject; APagina: Integer);
    procedure NavegarPaginaNumeroEvento(Sender: TObject; APagina: Integer);
    procedure IrParaPaginaAsync(Data: PtrInt);
  public
    constructor Create(AConsulta: TSQLQuery; APaginacao: TPaginacaoDBGrid;
      AGrade: TWinControl);
    destructor Destroy; override;
    { Chame no OnKeyDown do form (KeyPreview := True).
      Retorna True se a tecla foi tratada. }
    function TratarAtalho(var Key: Word; Shift: TShiftState): Boolean;
    function AbrirNoRegistro(AID: Int64): Boolean;
    function PosicaoRegistroAtual: Integer;
    procedure AbrirAposInclusao(AIDNovo, AIDAnterior: Int64);
    procedure Abrir;
    procedure Reiniciar;
    procedure Fechar;
    procedure Primeiro;
    procedure Anterior;
    procedure Proxima;
    procedure Ultimo;
    procedure IrPara(APagina: Integer);
    procedure OrdenarPorCampo(const ACampo: string);
    procedure AbrirAposExclusao(APosicao: Integer);
    property SQLBase: string read FSQLBase write FSQLBase;
    property SQLContagem: string read FSQLContagem write FSQLContagem;
    property OrdenarPor: string read FOrdenarPor write FOrdenarPor;
    property CampoOrdenacao: string read FCampoOrdenacao;
    property OrdemAscendente: Boolean read FOrdemAscendente;
    property PaginaAtual: Integer read FPaginaAtual;
    property TotalRegistros: Integer read FTotalRegistros;
    property TotalPaginas: Integer read FTotalPaginas;
    property LimiteAtual: Integer read FLimiteAtual;
    property OnPrepararConsulta: TPrepararConsultaEvent
      read FOnPrepararConsulta write FOnPrepararConsulta;
    property OnAtualizarInterface: TNotifyEvent
      read FOnAtualizarInterface write FOnAtualizarInterface;
    property CampoIdentificador: string
      read FCampoIdentificador write SetCampoIdentificador;
  end;

implementation

{ TPaginadorSQL }

constructor TPaginadorSQL.Create(AConsulta: TSQLQuery;
  APaginacao: TPaginacaoDBGrid; AGrade: TWinControl);
begin
  inherited Create;
  if AConsulta = nil then
    raise Exception.Create(
      'TPaginadorSQL: a consulta (TSQLQuery) e obrigatoria.');
  if APaginacao = nil then
    raise Exception.Create(
      'TPaginadorSQL: o TPaginacaoDBGrid e obrigatorio.');
  if (AConsulta.DataBase = nil) or (AConsulta.Transaction = nil) then
    raise Exception.Create(
      'TPaginadorSQL: defina DataBase e Transaction da consulta antes de criar o paginador.');
  FConsulta := AConsulta;
  FPaginacao := APaginacao;
  FGrade := AGrade;
  FCampoOrdenacao := '';
  FOrdemAscendente := True;
  FCampoIdentificador := 'ID';
  FContagem := TSQLQuery.Create(nil);
  FContagem.DataBase := FConsulta.DataBase;
  FContagem.Transaction := FConsulta.Transaction;
  FPaginacao.OnPrimeiraPagina := @PrimeiraPaginaEvento;
  FPaginacao.OnPaginaAnterior := @PaginaAnteriorEvento;
  FPaginacao.OnProximaPagina := @ProximaPaginaEvento;
  FPaginacao.OnUltimaPagina := @UltimaPaginaEvento;
  FPaginacao.OnAlterarLimite := @AlterarLimiteEvento;
  FPaginacao.OnIrParaPagina := @IrParaPaginaEvento;
  FPaginacao.OnNavegarPaginaNumero := @NavegarPaginaNumeroEvento;
end;

destructor TPaginadorSQL.Destroy;
begin
  Application.RemoveAsyncCalls(Self);
  if FPaginacao <> nil then
  begin
    FPaginacao.OnPrimeiraPagina := nil;
    FPaginacao.OnPaginaAnterior := nil;
    FPaginacao.OnProximaPagina := nil;
    FPaginacao.OnUltimaPagina := nil;
    FPaginacao.OnAlterarLimite := nil;
    FPaginacao.OnIrParaPagina := nil;
    FPaginacao.OnNavegarPaginaNumero := nil;
  end;
  FContagem.Free;
  inherited Destroy;
end;

procedure TPaginadorSQL.SetCampoIdentificador(const Valor: string);
begin
  if Trim(Valor) = '' then
    raise Exception.Create(
      'TPaginadorSQL: o campo identificador nao pode ser vazio.');
  FCampoIdentificador := Trim(Valor);
end;

function TPaginadorSQL.CampoIdentificadorSQL: string;
begin
  Result := '"' +
    StringReplace(FCampoIdentificador, '"', '""', [rfReplaceAll]) + '"';
end;

{ ---- Dados ---- }

procedure TPaginadorSQL.Atualizar(ALimite: Integer);
begin
  if ALimite <= 0 then
    raise Exception.Create('O limite deve ser maior que zero.');
  if ALimite <> FLimiteAtual then
  begin
    FPaginaAtual := 0;
    FLimiteAtual := ALimite;
  end;
  ExecutarConsulta;
end;

function TPaginadorSQL.MontarSQLBase: string;
begin
  Result := Trim(FSQLBase);
  while (Result <> '') and (Result[Length(Result)] = ';') do
    Delete(Result, Length(Result), 1);
  if Trim(FOrdenarPor) <> '' then
    Result := 'SELECT * FROM (' + Result + ') AS Dados ORDER BY ' +
      Trim(FOrdenarPor);
end;

function TPaginadorSQL.PaginaDoRegistro(AID: Int64): Integer;
var
  QPosicao: TSQLQuery;
  SQLBaseSemPontoEVirgula: string;
  Ordenacao: string;
begin
  Result := -1;
  SQLBaseSemPontoEVirgula := Trim(FSQLBase);
  while (SQLBaseSemPontoEVirgula <> '') and
    (SQLBaseSemPontoEVirgula[Length(SQLBaseSemPontoEVirgula)] = ';') do
    Delete(SQLBaseSemPontoEVirgula,
      Length(SQLBaseSemPontoEVirgula), 1);
  Ordenacao := Trim(FOrdenarPor);
  if Ordenacao = '' then
    Ordenacao := CampoIdentificadorSQL + ' ASC';
  QPosicao := TSQLQuery.Create(nil);
  try
    QPosicao.DataBase := FConsulta.DataBase;
    QPosicao.Transaction := FConsulta.Transaction;
    QPosicao.SQL.Text :=
      'SELECT IDReferencia, Posicao FROM (' +
      'SELECT Dados.' + CampoIdentificadorSQL + ' AS IDReferencia, ' +
      'ROW_NUMBER() OVER (ORDER BY ' + Ordenacao +
      ') AS Posicao FROM (' + SQLBaseSemPontoEVirgula +
      ') AS Dados) AS Ordenados WHERE IDReferencia = :IDReferencia';
    PrepararConsulta(QPosicao);
    QPosicao.ParamByName('IDReferencia').AsLargeInt := AID;
    QPosicao.Open;
    if not QPosicao.EOF then
      Result := (QPosicao.FieldByName('Posicao').AsLargeInt - 1) div
        FLimiteAtual;
  finally
    QPosicao.Free;
  end;
end;

procedure TPaginadorSQL.PrepararConsulta(AQuery: TSQLQuery);
begin
  if Assigned(FOnPrepararConsulta) then
    FOnPrepararConsulta(Self, AQuery);
end;

procedure TPaginadorSQL.ExecutarConsulta;
begin
  if FLimiteAtual <= 0 then
    raise Exception.Create(
      'Limite nao definido: chame Abrir antes de navegar.');
  if Trim(FSQLBase) = '' then
    raise Exception.Create(
      'TPaginadorSQL: SQLBase nao foi definido.');
  if Trim(FSQLContagem) = '' then
    raise Exception.Create(
      'TPaginadorSQL: SQLContagem nao foi definido.');
  FConsulta.Close;
  FContagem.Close;
  FContagem.SQL.Text := FSQLContagem;
  PrepararConsulta(FContagem);
  FContagem.Open;
  try
    FTotalRegistros := FContagem.Fields[0].AsInteger;
  finally
    FContagem.Close;
  end;
  FTotalPaginas := (FTotalRegistros + FLimiteAtual - 1) div FLimiteAtual;
  if FPaginaAtual >= FTotalPaginas then
    FPaginaAtual := FTotalPaginas - 1;
  if FPaginaAtual < 0 then
    FPaginaAtual := 0;
  FConsulta.SQL.Text :=
    MontarSQLBase + ' LIMIT :Limite OFFSET :Offset';
  PrepararConsulta(FConsulta);
  FConsulta.ParamByName('Limite').AsInteger := FLimiteAtual;
  FConsulta.ParamByName('Offset').AsInteger :=
    FPaginaAtual * FLimiteAtual;
  FConsulta.Open;
end;

procedure TPaginadorSQL.Abrir;
begin
  Atualizar(FPaginacao.LimiteAtual);
  AtualizarInterface;
end;

procedure TPaginadorSQL.Reiniciar;
begin
  FPaginaAtual := 0;
  Abrir;
end;

procedure TPaginadorSQL.Fechar;
begin
  FConsulta.Close;
end;

procedure TPaginadorSQL.IrPara(APagina: Integer);
begin
  if (APagina < 0) or (APagina >= FTotalPaginas) then
    Exit;
  FPaginaAtual := APagina;
  ExecutarConsulta;
end;

procedure TPaginadorSQL.OrdenarPorCampo(const ACampo: string);
var
  IDReferencia: Int64;
  NovaPagina: Integer;
  TemReferencia: Boolean;
  CampoSQL: string;
begin
  if Trim(ACampo) = '' then
    Exit;
  if FConsulta.FindField(ACampo) = nil then
    Exit;
  if not SameText(ACampo, FCampoIdentificador) then
    if FConsulta.FindField(FCampoIdentificador) = nil then
      Exit;
  TemReferencia := FConsulta.Active and not FConsulta.IsEmpty;
  if TemReferencia then
    IDReferencia := FConsulta.FieldByName(FCampoIdentificador).AsLargeInt;
  if SameText(FCampoOrdenacao, ACampo) then
    FOrdemAscendente := not FOrdemAscendente
  else
  begin
    FCampoOrdenacao := ACampo;
    FOrdemAscendente := True;
  end;
  CampoSQL := '"' +
    StringReplace(ACampo, '"', '""', [rfReplaceAll]) + '"';
  if FOrdemAscendente then
    FOrdenarPor := CampoSQL + ' ASC'
  else
    FOrdenarPor := CampoSQL + ' DESC';
  if not SameText(ACampo, FCampoIdentificador) then
    FOrdenarPor := FOrdenarPor + ', ' + CampoIdentificadorSQL + ' ASC';
  if TemReferencia then
  begin
    FConsulta.Close;
    NovaPagina := PaginaDoRegistro(IDReferencia);
    if NovaPagina >= 0 then
      FPaginaAtual := NovaPagina;
  end;
  Abrir;
  if TemReferencia and FConsulta.Active then
    FConsulta.Locate(FCampoIdentificador, IDReferencia, []);
end;

procedure TPaginadorSQL.AbrirAposExclusao(APosicao: Integer);
begin
  Abrir;
  if not FConsulta.Active or FConsulta.IsEmpty then
    Exit;
  if APosicao < 0 then
    APosicao := 0;
  FConsulta.First;
  while (APosicao > 0) and not FConsulta.EOF do
  begin
    FConsulta.Next;
    Dec(APosicao);
  end;
  if FConsulta.EOF then
    FConsulta.Last;
end;

procedure TPaginadorSQL.Primeiro;
begin
  IrPara(0);
end;

procedure TPaginadorSQL.Anterior;
begin
  IrPara(FPaginaAtual - 1);
end;

procedure TPaginadorSQL.Proxima;
begin
  IrPara(FPaginaAtual + 1);
end;

procedure TPaginadorSQL.Ultimo;
begin
  IrPara(FTotalPaginas - 1);
end;

{ ---- Interface ---- }

procedure TPaginadorSQL.AtualizarInterface;
begin
  FPaginacao.AtualizarPaginas(FPaginaAtual, FTotalPaginas);
  if Assigned(FOnAtualizarInterface) then
    FOnAtualizarInterface(Self);
end;

procedure TPaginadorSQL.FinalizarNavegacao;
begin
  FPaginacao.LimparCampoPagina;
  AtualizarInterface;
  if (FGrade <> nil) and FGrade.CanFocus then
    FGrade.SetFocus;
end;

procedure TPaginadorSQL.PrimeiraPaginaEvento(Sender: TObject);
begin
  Primeiro;
  FinalizarNavegacao;
end;

procedure TPaginadorSQL.PaginaAnteriorEvento(Sender: TObject);
begin
  Anterior;
  FinalizarNavegacao;
end;

procedure TPaginadorSQL.ProximaPaginaEvento(Sender: TObject);
begin
  Proxima;
  FinalizarNavegacao;
end;

procedure TPaginadorSQL.UltimaPaginaEvento(Sender: TObject);
begin
  Ultimo;
  FinalizarNavegacao;
end;

procedure TPaginadorSQL.AlterarLimiteEvento(Sender: TObject; ALimite: Integer);
begin
  Atualizar(ALimite);
  AtualizarInterface;
end;

procedure TPaginadorSQL.IrParaPaginaEvento(Sender: TObject; APagina: Integer);
begin
  if (APagina < 0) or (APagina >= FTotalPaginas) then
  begin
    ShowMessage('Informe uma pagina entre 1 e ' +
      IntToStr(FTotalPaginas) + '.');
    Exit;
  end;
  IrPara(APagina);
  FinalizarNavegacao;
end;

procedure TPaginadorSQL.NavegarPaginaNumeroEvento(Sender: TObject;
  APagina: Integer);
begin
  Application.QueueAsyncCall(@IrParaPaginaAsync, PtrInt(APagina));
end;

procedure TPaginadorSQL.IrParaPaginaAsync(Data: PtrInt);
begin
  IrPara(Integer(Data));
  FinalizarNavegacao;
end;

function TPaginadorSQL.TratarAtalho(var Key: Word;
  Shift: TShiftState): Boolean;
begin
  Result := False;
  if (not FConsulta.Active) or (FTotalPaginas <= 0) or
     (Shift <> [ssCtrl]) then
    Exit;
  case Key of
    VK_UP: Primeiro;
    VK_DOWN:
      begin
        Ultimo;
        FConsulta.Last;
      end;
    VK_LEFT: Anterior;
    VK_RIGHT: Proxima;
  else
    Exit;
  end;
  FinalizarNavegacao;
  Key := 0;
  Result := True;
end;

function TPaginadorSQL.AbrirNoRegistro(AID: Int64): Boolean;
var
  NovaPagina: Integer;
begin
  Result := False;
  if AID > 0 then
  begin
    NovaPagina := PaginaDoRegistro(AID);
    if NovaPagina >= 0 then
      FPaginaAtual := NovaPagina;
  end;
  Abrir;
  if (AID > 0) and FConsulta.Active then
    Result := FConsulta.Locate(FCampoIdentificador, AID, []);
end;

function TPaginadorSQL.PosicaoRegistroAtual: Integer;
var
  IDAtual: Int64;
begin
  Result := -1;
  if not FConsulta.Active or FConsulta.IsEmpty then
    Exit;
  IDAtual := FConsulta.FieldByName(FCampoIdentificador).AsLargeInt;
  FConsulta.DisableControls;
  try
    FConsulta.First;
    Result := 0;
    while not FConsulta.EOF do
    begin
      if FConsulta.FieldByName(FCampoIdentificador).AsLargeInt = IDAtual then
        Break;
      Inc(Result);
      FConsulta.Next;
    end;
    if FConsulta.EOF then
      Result := -1;
    FConsulta.Locate(FCampoIdentificador, IDAtual, []);
  finally
    FConsulta.EnableControls;
  end;
end;

procedure TPaginadorSQL.AbrirAposInclusao(AIDNovo, AIDAnterior: Int64);
var
  PaginaNovoRegistro: Integer;
begin
  Abrir;
  if not FConsulta.Active or FConsulta.IsEmpty then
    Exit;
  PaginaNovoRegistro := -1;
  if AIDNovo > 0 then
    PaginaNovoRegistro := PaginaDoRegistro(AIDNovo);
  if PaginaNovoRegistro = FPaginaAtual then
  begin
    FConsulta.Locate(FCampoIdentificador, AIDNovo, []);
    Exit;
  end;
  if AIDAnterior > 0 then
    FConsulta.Locate(FCampoIdentificador, AIDAnterior, []);
end;

end.

