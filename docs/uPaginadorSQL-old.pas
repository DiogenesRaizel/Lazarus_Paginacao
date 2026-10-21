unit uPaginadorSQL;

{ Logica de dados da paginacao (COUNT, LIMIT/OFFSET, pagina atual),
  independente da tabela e do formulario.

  Liga uma TSQLQuery a um TPaginacaoDBGrid (interface) ja existente:
  assume os eventos do TPaginacaoDBGrid, entao o formulario nao precisa
  mais de handlers de navegacao. }

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Dialogs, LCLType, DB, SQLDB,
  uPaginacaoDBGrid;

type

  { TPaginadorSQL }

  TPaginadorSQL = class
  private
    FConsulta: TSQLQuery;            // query exibida na grade
    FContagem: TSQLQuery;            // query interna para COUNT(*)
    FPaginacao: TPaginacaoDBGrid;    // interface (botoes, combo, campo)
    FGrade: TWinControl;             // recebe o foco apos navegar

    FSQLBase: string;
    FSQLContagem: string;
    FOrdenarPor: string;

    FPaginaAtual: Integer;
    FTotalRegistros: Integer;
    FTotalPaginas: Integer;
    FLimiteAtual: Integer;

    procedure Atualizar(ALimite: Integer);
    procedure ExecutarConsulta;
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

    { Abre a consulta usando o limite escolhido no combo. }
    procedure Abrir;
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
  end;

implementation

{ TPaginadorSQL }

constructor TPaginadorSQL.Create(AConsulta: TSQLQuery;
  APaginacao: TPaginacaoDBGrid; AGrade: TWinControl);
begin
  inherited Create;

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

procedure TPaginadorSQL.ExecutarConsulta;
begin
  FConsulta.Close;

  FContagem.Close;
  FContagem.SQL.Text := FSQLContagem;
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
    FSQLBase + ' ORDER BY ' + FOrdenarPor +
    ' LIMIT :Limite OFFSET :Offset';

  FConsulta.ParamByName('Limite').AsInteger := FLimiteAtual;
  FConsulta.ParamByName('Offset').AsInteger := FPaginaAtual * FLimiteAtual;

  FConsulta.Open;
end;

procedure TPaginadorSQL.Abrir;
begin
  Atualizar(FPaginacao.LimiteAtual);
  AtualizarInterface;
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
