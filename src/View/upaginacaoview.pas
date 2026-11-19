unit uPaginacaoView;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Forms, uControllerBase, uPaginacaoDBGrid;

type

  { TPaginacaoView }

  TPaginacaoView = class
  private
    FController: TControllerBase;
    FPaginacaoDBGrid: TPaginacaoDBGrid;

    procedure PrimeiraPagina(Sender: TObject);
    procedure PaginaAnterior(Sender: TObject);
    procedure ProximaPagina(Sender: TObject);
    procedure UltimaPagina(Sender: TObject);
    procedure AlterarLimite(Sender: TObject; ALimite: Integer);
    procedure IrParaPagina(Sender: TObject; APagina: Integer);
    procedure NavegarPaginaNumero(Sender: TObject; APagina: Integer);
    procedure NavegarPaginaNumeroAsync(Data: PtrInt);

  public
    constructor Create(APainel: TPanel; AController: TControllerBase);
    destructor Destroy; override;

    procedure Atualizar;

    property PaginacaoDBGrid: TPaginacaoDBGrid
      read FPaginacaoDBGrid;
  end;

implementation

constructor TPaginacaoView.Create(
  APainel: TPanel;
  AController: TControllerBase);
begin
  inherited Create;

  FController := AController;

  FPaginacaoDBGrid := TPaginacaoDBGrid.Create(APainel);

  FPaginacaoDBGrid.OnPrimeiraPagina := @PrimeiraPagina;
  FPaginacaoDBGrid.OnPaginaAnterior := @PaginaAnterior;
  FPaginacaoDBGrid.OnProximaPagina := @ProximaPagina;
  FPaginacaoDBGrid.OnUltimaPagina := @UltimaPagina;
  FPaginacaoDBGrid.OnAlterarLimite := @AlterarLimite;
  FPaginacaoDBGrid.OnIrParaPagina := @IrParaPagina;
  FPaginacaoDBGrid.OnNavegarPaginaNumero := @NavegarPaginaNumero;

  Atualizar;
end;

destructor TPaginacaoView.Destroy;
begin
  Application.RemoveAsyncCalls(Self);

  FPaginacaoDBGrid.OnPrimeiraPagina := nil;
  FPaginacaoDBGrid.OnPaginaAnterior := nil;
  FPaginacaoDBGrid.OnProximaPagina := nil;
  FPaginacaoDBGrid.OnUltimaPagina := nil;
  FPaginacaoDBGrid.OnAlterarLimite := nil;
  FPaginacaoDBGrid.OnIrParaPagina := nil;
  FPaginacaoDBGrid.OnNavegarPaginaNumero := nil;

  FreeAndNil(FPaginacaoDBGrid);

  FController := nil;

  inherited Destroy;
end;

procedure TPaginacaoView.Atualizar;
begin
  if FController = nil then
    Exit;

  FPaginacaoDBGrid.AtualizarPaginas(
    FController.EstadoPaginacao.PaginaAtual,
    FController.EstadoPaginacao.TotalPaginas);
end;

procedure TPaginacaoView.PrimeiraPagina(Sender: TObject);
begin
  FController.IrParaPrimeiraPagina;
  Atualizar;
end;

procedure TPaginacaoView.PaginaAnterior(Sender: TObject);
begin
  FController.IrParaPaginaAnterior;
  Atualizar;
end;

procedure TPaginacaoView.ProximaPagina(Sender: TObject);
begin
  FController.IrParaProximaPagina;
  Atualizar;
end;

procedure TPaginacaoView.UltimaPagina(Sender: TObject);
begin
  FController.IrParaUltimaPagina;
  Atualizar;
end;

procedure TPaginacaoView.AlterarLimite(
  Sender: TObject;
  ALimite: Integer);
begin
  FController.AlterarLimitePorPagina(ALimite);
  Atualizar;
end;

procedure TPaginacaoView.IrParaPagina(
  Sender: TObject;
  APagina: Integer);
begin
  FController.IrParaPagina(APagina);
  Atualizar;
end;

{
procedure TPaginacaoView.NavegarPaginaNumero(
  Sender: TObject;
  APagina: Integer);
begin
  FController.IrParaPagina(APagina);
  Atualizar;
end;
}

procedure TPaginacaoView.NavegarPaginaNumero(
  Sender: TObject; APagina: Integer);
begin
  Application.QueueAsyncCall(
    @NavegarPaginaNumeroAsync, PtrInt(APagina));
end;

procedure TPaginacaoView.NavegarPaginaNumeroAsync(Data: PtrInt);
begin
  if FController = nil then
    Exit;

  FController.IrParaPagina(Integer(Data));
  Atualizar;
end;

end.
