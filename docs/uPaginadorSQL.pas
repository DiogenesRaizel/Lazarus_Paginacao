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
    FConsulta: TSQLQuery;            // query exibida na grade (nao e dona)
    FContagem: TSQLQuery;            // query interna para COUNT(*)
    FPaginacao: TPaginacaoDBGrid;    // interface (botoes, combo, campo)
    FGrade: TWinControl;             // recebe o foco apos navegar (pode ser nil)

    FSQLBase: string;
    FSQLContagem: string;
    FOrdenarPor: string;

    FPaginaAtual: Integer;
    FTotalRegistros: Integer;
    FTotalPaginas: Integer;
    FLimiteAtual: Integer;

    FOnPrepararConsulta: TPrepararConsultaEvent;

    procedure Atualizar(ALimite: Integer);
    procedure ExecutarConsulta;
    function MontarSQLBase: string;
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

    { Abre/recarrega a consulta usando o limite escolhido no combo. }
    procedure Abrir;
    { Volta para a primeira pagina e recarrega (ex.: filtro alterado). }
    procedure Reiniciar;
    procedure Fechar;

    procedure Primeiro;
    procedure Anterior;
    procedure Proxima;
    procedure Ultimo;
    procedure IrPara(APagina: Integer);   // base zero

    { Chame no OnKeyDown do form (KeyPreview := True).
      Retorna True se a tecla foi tratada. }
    function TratarAtalho(var Key: Word; Shift: TShiftState): Boolean;

    property SQLBase: string read FSQLBase write FSQLBase;
    property SQLContagem: string read FSQLContagem write FSQLContagem;
    property OrdenarPor: string read FOrdenarPor write FOrdenarPor;

    property PaginaAtual: Integer read FPaginaAtual;
    property TotalRegistros: Integer read FTotalRegistros;
    property TotalPaginas: Integer read FTotalPaginas;
    property LimiteAtual: Integer read FLimiteAtual;

    property OnPrepararConsulta: TPrepararConsultaEvent
      read FOnPrepararConsulta write FOnPrepararConsulta;
  end;

implementation

{ TPaginadorSQL }

constructor TPaginadorSQL.Create(AConsulta: TSQLQuery;
  APaginacao: TPaginacaoDBGrid; AGrade: TWinControl);
begin
  inherited Create;

  // Valida antes de guardar as referencias: se falhar, o destrutor
  // encontra os campos nil e nao toca em nada.
  if AConsulta = nil then
    raise Exception.Create('TPaginadorSQL: a consulta (TSQLQuery) é obrigatória.');

  if APaginacao = nil then
    raise Exception.Create('TPaginadorSQL: o TPaginacaoDBGrid é obrigatório.');

  if (AConsulta.DataBase = nil) or (AConsulta.Transaction = nil) then
    raise Exception.Create(
      'TPaginadorSQL: defina DataBase e Transaction da consulta antes de criar o paginador.');

  FConsulta := AConsulta;
  FPaginacao := APaginacao;
  FGrade := AGrade;

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

  // Solta os eventos para a interface nao chamar um objeto destruido.
  // A interface precisa ainda existir (libere o paginador antes dela).
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

{ ---- Dados (mesma logica do TDM.AtualizarConsulta) ---- }

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
    Result := Result + ' ORDER BY ' + Trim(FOrdenarPor);
end;

procedure TPaginadorSQL.PrepararConsulta(AQuery: TSQLQuery);
begin
  if Assigned(FOnPrepararConsulta) then
    FOnPrepararConsulta(Self, AQuery);
end;

procedure TPaginadorSQL.ExecutarConsulta;
begin
  if FLimiteAtual <= 0 then
    raise Exception.Create('Limite não definido: chame Abrir antes de navegar.');

  if Trim(FSQLBase) = '' then
    raise Exception.Create('TPaginadorSQL: SQLBase não foi definido.');

  if Trim(FSQLContagem) = '' then
    raise Exception.Create('TPaginadorSQL: SQLContagem não foi definido.');

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
  FConsulta.ParamByName('Offset').AsInteger := FPaginaAtual * FLimiteAtual;

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
    ShowMessage('Informe uma página entre 1 e ' +
      IntToStr(FTotalPaginas) + '.');
    Exit;
  end;

  IrPara(APagina);
  FinalizarNavegacao;
end;

procedure TPaginadorSQL.NavegarPaginaNumeroEvento(Sender: TObject;
  APagina: Integer);
begin
  // Assincrono: o botao clicado e destruido ao reconstruir a barra.
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
    VK_UP:    Primeiro;       // Ctrl + seta para cima: primeira pagina
    VK_DOWN:                  // Ctrl + seta para baixo: ultimo registro
      begin
        Ultimo;
        FConsulta.Last;
      end;
    VK_LEFT:  Anterior;       // Ctrl + seta para a esquerda: pagina anterior
    VK_RIGHT: Proxima;        // Ctrl + seta para a direita: proxima pagina
  else
    Exit;
  end;

  FinalizarNavegacao;
  Key := 0;
  Result := True;
end;

end.
