{
unit uControllerBase;

{$mode ObjFPC}{$H+}

interface

{
uses
  Controls, ExtCtrls, Classes, SysUtils, DB, SQLDB, Forms, LCLType,
  uPaginacao, uPaginacaoDBGrid, uModelBase, Dialogs, uTiposCadastro;
}

uses
  Controls, Classes, SysUtils, DB, SQLDB, LCLType,
  uPaginacao, uModelBase, Dialogs, uTiposCadastro;

type

  { TControllerBase }

  TControllerBase = class
  protected
    FModel: TModelBase;

    {
    // Estado e interface da paginação.
    FEstadoPaginacao: TPaginacao;
    FPaginacao: TPaginacaoDBGrid;
    }

    // Estado da paginação.
    FEstadoPaginacao: TPaginacao;

    // Estado do Controller.
    FModoCadastro: TModoCadastro;
    FCampoOrdenacao: string;
    FOrdemAscendente: Boolean;

    function GetDataSet: TDataSet;
    function GetIdentificador: string;

    procedure AbrirPaginaAtual;
    procedure AtualizarInterfacePaginacao;
    procedure ExecutarConsultaSemPaginacao;

    // Eventos da interface de paginação.
    procedure PrimeiraPaginaEvento(Sender: TObject);
    procedure PaginaAnteriorEvento(Sender: TObject);
    procedure ProximaPaginaEvento(Sender: TObject);
    procedure UltimaPaginaEvento(Sender: TObject);
    procedure AlterarLimiteEvento(Sender: TObject; ALimite: Integer);
    procedure IrParaPaginaEvento(Sender: TObject; APagina: Integer);
    procedure NavegarPaginaNumeroEvento(Sender: TObject;
      APagina: Integer);
    procedure NavegarPaginaNumeroAsync(Data: PtrInt);

  public
    constructor Create(AModel: TModelBase; APainel: TPanel);
    destructor Destroy; override;

    function PosicaoRegistroAtual: Int64;

    procedure Inicializar;
    procedure AtualizarConsulta;
    procedure Pesquisar(const Valor: string);
    procedure OrdenarPorCampo(const ACampo: string);
    procedure TratarAtalho(var Key: Word; Shift: TShiftState);

    procedure Primeiro;
    procedure Anterior;
    procedure Proximo;
    procedure Ultimo;

    procedure IniciarInclusao;
    procedure IniciarEdicao;
    procedure ConfirmarOperacao;
    procedure CancelarOperacao;
    procedure NavegarTabela;
    procedure AbrirCadastro;

    procedure RestaurarConsulta(AID: Int64);
    procedure RestaurarAposInclusao(AIDNovo, AIDAnterior: Int64);
    procedure RestaurarAposExclusao(APosicao: Integer);
    procedure GarantirConsultaAtiva(AID: Int64);

    property Paginacao: TPaginacaoDBGrid read FPaginacao;
    property DataSet: TDataSet read GetDataSet;
    property Identificador: string read GetIdentificador;
    property ModoCadastro: TModoCadastro read FModoCadastro;

    property CampoOrdenacao: string read FCampoOrdenacao;
    property OrdemAscendente: Boolean read FOrdemAscendente;
  end;

implementation

{ TControllerBase }

constructor TControllerBase.Create(AModel: TModelBase; APainel: TPanel);
begin
  inherited Create;

  if AModel = nil then
    raise Exception.Create('O Model não foi informado.');

  FModel := AModel;

  FEstadoPaginacao := nil;
  FPaginacao := nil;

  FModoCadastro := mcNavegandoTabela;

  FCampoOrdenacao := FModel.OrdenarPor;
  FOrdemAscendente := True;

  if APainel <> nil then
  begin
    try
      FPaginacao := TPaginacaoDBGrid.Create(APainel);

      FEstadoPaginacao := TPaginacao.Create(
        FPaginacao.LimiteAtual
      );

      // Associar os eventos da interface ao Controller.
      FPaginacao.OnPrimeiraPagina := @PrimeiraPaginaEvento;
      FPaginacao.OnPaginaAnterior := @PaginaAnteriorEvento;
      FPaginacao.OnProximaPagina := @ProximaPaginaEvento;
      FPaginacao.OnUltimaPagina := @UltimaPaginaEvento;
      FPaginacao.OnAlterarLimite := @AlterarLimiteEvento;
      FPaginacao.OnIrParaPagina := @IrParaPaginaEvento;
      FPaginacao.OnNavegarPaginaNumero :=
        @NavegarPaginaNumeroEvento;

    except
      FreeAndNil(FEstadoPaginacao);
      FreeAndNil(FPaginacao);
      raise;
    end;
  end;
end;

destructor TControllerBase.Destroy;
begin
  // Impedir execução de chamadas assíncronas após a destruição.
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

  FreeAndNil(FEstadoPaginacao);
  FreeAndNil(FPaginacao);

  inherited Destroy;
end;

function TControllerBase.GetDataSet: TDataSet;
begin
  Result := FModel.Consulta;
end;

function TControllerBase.GetIdentificador: string;
begin
  Result := FModel.Identificador;
end;

function TControllerBase.PosicaoRegistroAtual: Int64;
var
  IDAtual: Int64;
  PosicaoLocal: Int64;
begin
  Result := -1;

  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  IDAtual := DataSet.FieldByName(
    FModel.Identificador
  ).AsLargeInt;

  PosicaoLocal := 0;

  DataSet.First;

  while not DataSet.EOF do
  begin
    Inc(PosicaoLocal);

    if DataSet.FieldByName(
      FModel.Identificador
    ).AsLargeInt = IDAtual then
      Break;

    DataSet.Next;
  end;

  if not DataSet.EOF then
  begin
    if FEstadoPaginacao <> nil then
      Result := FEstadoPaginacao.Offset + PosicaoLocal
    else
      Result := PosicaoLocal;
  end;

  // Restaurar o registro selecionado.
  DataSet.Locate(FModel.Identificador, IDAtual, []);
end;

procedure TControllerBase.AbrirPaginaAtual;
begin
  if FEstadoPaginacao = nil then
  begin
    ExecutarConsultaSemPaginacao;
    Exit;
  end;

  FModel.AbrirPagina(
    FEstadoPaginacao.LimitePorPagina,
    FEstadoPaginacao.Offset,
    FCampoOrdenacao,
    FOrdemAscendente
  );

  AtualizarInterfacePaginacao;
end;

procedure TControllerBase.AtualizarInterfacePaginacao;
begin
  if FPaginacao = nil then
    Exit;

  FPaginacao.AtualizarPaginas(
    FEstadoPaginacao.PaginaAtual,
    FEstadoPaginacao.TotalPaginas
  );
end;

procedure TControllerBase.ExecutarConsultaSemPaginacao;
var
  SQL: string;
begin
  FModel.Consulta.Close;

  SQL := Trim(FModel.SQLBase);

  while (SQL <> '') and (SQL[Length(SQL)] = ';') do
    Delete(SQL, Length(SQL), 1);

  if Trim(FModel.OrdenarPor) <> '' then
    SQL := SQL + ' ORDER BY ' + FModel.OrdenarPor;

  FModel.Consulta.SQL.Text := SQL;

  FModel.PrepararConsulta(
    Self,
    FModel.Consulta
  );

  FModel.Consulta.Open;
end;

procedure TControllerBase.Inicializar;
begin
  AtualizarConsulta;
end;

procedure TControllerBase.AtualizarConsulta;
begin
  if FEstadoPaginacao = nil then
  begin
    ExecutarConsultaSemPaginacao;
    Exit;
  end;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  AbrirPaginaAtual;
end;

procedure TControllerBase.Pesquisar(const Valor: string);
begin
  FModel.DefinirFiltro(Valor);

  if FEstadoPaginacao <> nil then
    FEstadoPaginacao.Primeira;

  AtualizarConsulta;
end;

procedure TControllerBase.OrdenarPorCampo(const ACampo: string);
var
  IDAtual: Int64;
  Posicao: Int64;
  Pagina: Integer;
begin
  if not FModel.Consulta.Active then
    Exit;

  if FModel.Consulta.IsEmpty then
    IDAtual := 0
  else
    IDAtual := FModel.Consulta.FieldByName(
      FModel.Identificador
    ).AsLargeInt;

  if FModel.Consulta.FindField(ACampo) = nil then
    Exit;

  if SameText(FCampoOrdenacao, ACampo) then
    FOrdemAscendente := not FOrdemAscendente
  else
  begin
    FCampoOrdenacao := ACampo;
    FOrdemAscendente := True;
  end;

  if FEstadoPaginacao = nil then
  begin
    ExecutarConsultaSemPaginacao;

    if IDAtual > 0 then
      DataSet.Locate(FModel.Identificador, IDAtual, []);

    Exit;
  end;

  if IDAtual > 0 then
  begin
    Posicao := FModel.LocalizarPosicao(
      IDAtual,
      FCampoOrdenacao,
      FOrdemAscendente
    );

    Pagina := FEstadoPaginacao.PaginaDaPosicao(Posicao);

    if Pagina >= 0 then
      FEstadoPaginacao.IrPara(Pagina)
    else
      FEstadoPaginacao.Primeira;
  end
  else
    FEstadoPaginacao.Primeira;

  AbrirPaginaAtual;

  if IDAtual > 0 then
    DataSet.Locate(FModel.Identificador, IDAtual, []);
end;

procedure TControllerBase.TratarAtalho(
  var Key: Word; Shift: TShiftState);
begin
  if not (ssCtrl in Shift) or (FEstadoPaginacao = nil) then
    Exit;

  case Key of
    VK_LEFT:
      Anterior;

    VK_RIGHT:
      Proximo;

    VK_HOME:
      begin
        FEstadoPaginacao.Primeira;
        AbrirPaginaAtual;
      end;

    VK_END:
      begin
        FEstadoPaginacao.Ultima;
        AbrirPaginaAtual;
      end;
  else
    Exit;
  end;

  Key := 0;
end;

{ Navegação do registro dentro do DataSet }

procedure TControllerBase.Primeiro;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.First;
end;

procedure TControllerBase.Anterior;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.Prior;
end;

procedure TControllerBase.Proximo;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.Next;
end;

procedure TControllerBase.Ultimo;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.Last;
end;

{ Eventos da interface de paginação }

procedure TControllerBase.PrimeiraPaginaEvento(Sender: TObject);
begin
  FEstadoPaginacao.Primeira;
  AbrirPaginaAtual;
end;

procedure TControllerBase.PaginaAnteriorEvento(Sender: TObject);
begin
  FEstadoPaginacao.Anterior;
  AbrirPaginaAtual;
end;

procedure TControllerBase.ProximaPaginaEvento(Sender: TObject);
begin
  FEstadoPaginacao.Proxima;
  AbrirPaginaAtual;
end;

procedure TControllerBase.UltimaPaginaEvento(Sender: TObject);
begin
  FEstadoPaginacao.Ultima;
  AbrirPaginaAtual;
end;

procedure TControllerBase.AlterarLimiteEvento(
  Sender: TObject; ALimite: Integer);
begin
  FEstadoPaginacao.AlterarLimite(ALimite);
  AtualizarConsulta;
end;

procedure TControllerBase.IrParaPaginaEvento(
  Sender: TObject; APagina: Integer);
begin
  if FEstadoPaginacao.IrPara(APagina) then
    AbrirPaginaAtual;

  FPaginacao.LimparCampoPagina;
end;

procedure TControllerBase.NavegarPaginaNumeroEvento(
  Sender: TObject; APagina: Integer);
begin
  // Adiar a navegação porque a atualização destrói e recria
  // os botões numerados da interface.
  Application.QueueAsyncCall(
    @NavegarPaginaNumeroAsync,
    APagina
  );
end;

procedure TControllerBase.NavegarPaginaNumeroAsync(Data: PtrInt);
begin
  if FEstadoPaginacao = nil then
    Exit;

  if FEstadoPaginacao.IrPara(Data) then
    AbrirPaginaAtual;
end;

{ Modos de cadastro }

procedure TControllerBase.IniciarInclusao;
begin
  case FModoCadastro of
    mcNavegandoTabela:
      FModoCadastro := mcInclusaoTabela;

    mcNavegandoCadastro:
      FModoCadastro := mcInclusaoCadastro;
  end;
end;

procedure TControllerBase.IniciarEdicao;
begin
  case FModoCadastro of
    mcNavegandoTabela:
      FModoCadastro := mcEdicaoTabela;

    mcNavegandoCadastro:
      FModoCadastro := mcEdicaoCadastro;
  end;
end;

procedure TControllerBase.ConfirmarOperacao;
begin
  case FModoCadastro of
    mcInclusaoTabela, mcEdicaoTabela:
      FModoCadastro := mcNavegandoTabela;

    mcInclusaoCadastro, mcEdicaoCadastro:
      FModoCadastro := mcNavegandoCadastro;
  end;
end;

procedure TControllerBase.CancelarOperacao;
begin
  ConfirmarOperacao;
end;

procedure TControllerBase.NavegarTabela;
begin
  FModoCadastro := mcNavegandoTabela;
end;

procedure TControllerBase.AbrirCadastro;
begin
  FModoCadastro := mcNavegandoCadastro;
end;

{ Restauração da consulta }

procedure TControllerBase.RestaurarConsulta(AID: Int64);
var
  Posicao: Int64;
  Pagina: Integer;
begin
  if FEstadoPaginacao = nil then
  begin
    AtualizarConsulta;

    if (AID > 0) and DataSet.Active then
      DataSet.Locate(FModel.Identificador, AID, []);

    Exit;
  end;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  if AID > 0 then
  begin
    Posicao := FModel.LocalizarPosicao(
      AID,
      FCampoOrdenacao,
      FOrdemAscendente
    );

    Pagina := FEstadoPaginacao.PaginaDaPosicao(Posicao);

    if Pagina >= 0 then
      FEstadoPaginacao.IrPara(Pagina)
    else
      FEstadoPaginacao.Primeira;
  end
  else
    FEstadoPaginacao.Primeira;

  AbrirPaginaAtual;

  if (AID > 0) and DataSet.Active then
    DataSet.Locate(FModel.Identificador, AID, []);
end;

procedure TControllerBase.RestaurarAposInclusao(
  AIDNovo, AIDAnterior: Int64);
var
  PaginaAnterior: Integer;
  PaginaNova: Integer;
  Posicao: Int64;
  IDSelecionado: Int64;
begin
  if FEstadoPaginacao = nil then
  begin
    AtualizarConsulta;

    if (AIDNovo > 0) and
      DataSet.Locate(FModel.Identificador, AIDNovo, []) then
      Exit;

    if AIDAnterior > 0 then
      DataSet.Locate(FModel.Identificador, AIDAnterior, []);

    Exit;
  end;

  PaginaAnterior := FEstadoPaginacao.PaginaAtual;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  IDSelecionado := AIDAnterior;

  if AIDNovo > 0 then
  begin
    Posicao := FModel.LocalizarPosicao(
      AIDNovo,
      FCampoOrdenacao,
      FOrdemAscendente
    );

    PaginaNova := FEstadoPaginacao.PaginaDaPosicao(Posicao);

    if PaginaNova = PaginaAnterior then
    begin
      FEstadoPaginacao.IrPara(PaginaNova);
      IDSelecionado := AIDNovo;
    end
    else if AIDAnterior > 0 then
    begin
      Posicao := FModel.LocalizarPosicao(
        AIDAnterior,
        FCampoOrdenacao,
        FOrdemAscendente
      );

      PaginaNova := FEstadoPaginacao.PaginaDaPosicao(Posicao);

      if PaginaNova >= 0 then
        FEstadoPaginacao.IrPara(PaginaNova)
      else
        IDSelecionado := 0;
    end;
  end;

  AbrirPaginaAtual;

  if IDSelecionado > 0 then
    DataSet.Locate(FModel.Identificador, IDSelecionado, []);
end;

procedure TControllerBase.RestaurarAposExclusao(APosicao: Integer);
var
  Posicao: Int64;
  Pagina: Integer;
  PosicaoLocal: Integer;
begin
  if FEstadoPaginacao = nil then
  begin
    AtualizarConsulta;
    Exit;
  end;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  if FEstadoPaginacao.TotalRegistros = 0 then
  begin
    FEstadoPaginacao.Primeira;
    AbrirPaginaAtual;
    Exit;
  end;

  Posicao := APosicao;

  if Posicao < 1 then
    Posicao := 1;

  if Posicao > FEstadoPaginacao.TotalRegistros then
    Posicao := FEstadoPaginacao.TotalRegistros;

  Pagina := FEstadoPaginacao.PaginaDaPosicao(Posicao);

  if Pagina >= 0 then
    FEstadoPaginacao.IrPara(Pagina);

  AbrirPaginaAtual;

  // Selecionar o registro que ocupou a posição excluída.
  PosicaoLocal := (Posicao - 1) mod
    FEstadoPaginacao.LimitePorPagina;

  if DataSet.Active and not DataSet.IsEmpty then
  begin
    DataSet.First;

    if PosicaoLocal > 0 then
      DataSet.MoveBy(PosicaoLocal);
  end;
end;

procedure TControllerBase.GarantirConsultaAtiva(AID: Int64);
begin
  if not DataSet.Active then
    RestaurarConsulta(AID);
end;
}

unit uControllerBase;

{$mode ObjFPC}{$H+}

interface

uses
  Controls, Classes, SysUtils, DB, SQLDB, LCLType,
  uPaginacao, uModelBase, Dialogs, uTiposCadastro;

type

  { TControllerBase }

  TControllerBase = class
  protected
    FModel: TModelBase;

    // Estado da paginação.
    FEstadoPaginacao: TPaginacao;

    // Estado do Controller.
    FModoCadastro: TModoCadastro;
    FCampoOrdenacao: string;
    FOrdemAscendente: Boolean;

    function GetDataSet: TDataSet;
    function GetIdentificador: string;

    procedure AbrirPaginaAtual;
    procedure ExecutarConsultaSemPaginacao;

  public
    constructor Create(AModel: TModelBase);
    destructor Destroy; override;

    function PosicaoRegistroAtual: Int64;

    procedure Inicializar;
    procedure AtualizarConsulta;
    procedure Pesquisar(const Valor: string);
    procedure OrdenarPorCampo(const ACampo: string);
    procedure TratarAtalho(var Key: Word; Shift: TShiftState);

    // Navegação da paginação.
    procedure IrParaPrimeiraPagina;
    procedure IrParaPaginaAnterior;
    procedure IrParaProximaPagina;
    procedure IrParaUltimaPagina;
    procedure AlterarLimitePorPagina(ALimite: Integer);
    procedure IrParaPagina(APagina: Integer);

    // Navegação do registro no DataSet.
    procedure Primeiro;
    procedure Anterior;
    procedure Proximo;
    procedure Ultimo;

    // Modos de cadastro.
    procedure IniciarInclusao;
    procedure IniciarEdicao;
    procedure ConfirmarOperacao;
    procedure CancelarOperacao;
    procedure NavegarTabela;
    procedure AbrirCadastro;

    // Restauração da consulta.
    procedure RestaurarConsulta(AID: Int64);
    procedure RestaurarAposInclusao(AIDNovo, AIDAnterior: Int64);
    procedure RestaurarAposExclusao(APosicao: Integer);
    procedure GarantirConsultaAtiva(AID: Int64);

    property EstadoPaginacao: TPaginacao read FEstadoPaginacao;
    property DataSet: TDataSet read GetDataSet;
    property Identificador: string read GetIdentificador;
    property ModoCadastro: TModoCadastro read FModoCadastro;

    property CampoOrdenacao: string read FCampoOrdenacao;
    property OrdemAscendente: Boolean read FOrdemAscendente;
  end;

implementation

{ TControllerBase }

constructor TControllerBase.Create(AModel: TModelBase);
begin
  inherited Create;

  if AModel = nil then
    raise Exception.Create('O Model não foi informado.');

  FModel := AModel;

  FEstadoPaginacao := TPaginacao.Create;

  FModoCadastro := mcNavegandoTabela;

  FCampoOrdenacao := FModel.OrdenarPor;
  FOrdemAscendente := True;
end;

destructor TControllerBase.Destroy;
begin
  FreeAndNil(FEstadoPaginacao);

  inherited Destroy;
end;

function TControllerBase.GetDataSet: TDataSet;
begin
  Result := FModel.Consulta;
end;

function TControllerBase.GetIdentificador: string;
begin
  Result := FModel.Identificador;
end;

function TControllerBase.PosicaoRegistroAtual: Int64;
var
  IDAtual: Int64;
  PosicaoLocal: Int64;
begin
  Result := -1;

  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  IDAtual := DataSet.FieldByName(
    FModel.Identificador
  ).AsLargeInt;

  PosicaoLocal := 0;

  DataSet.First;

  while not DataSet.EOF do
  begin
    Inc(PosicaoLocal);

    if DataSet.FieldByName(
      FModel.Identificador
    ).AsLargeInt = IDAtual then
      Break;

    DataSet.Next;
  end;

  if not DataSet.EOF then
  begin
    if FEstadoPaginacao <> nil then
      Result := FEstadoPaginacao.Offset + PosicaoLocal
    else
      Result := PosicaoLocal;
  end;

  // Restaurar o registro selecionado.
  DataSet.Locate(FModel.Identificador, IDAtual, []);
end;

procedure TControllerBase.AbrirPaginaAtual;
begin
  if FEstadoPaginacao = nil then
  begin
    ExecutarConsultaSemPaginacao;
    Exit;
  end;

  FModel.AbrirPagina(
    FEstadoPaginacao.LimitePorPagina,
    FEstadoPaginacao.Offset,
    FCampoOrdenacao,
    FOrdemAscendente
  );
end;

procedure TControllerBase.ExecutarConsultaSemPaginacao;
var
  SQL: string;
begin
  FModel.Consulta.Close;

  SQL := Trim(FModel.SQLBase);

  while (SQL <> '') and (SQL[Length(SQL)] = ';') do
    Delete(SQL, Length(SQL), 1);

  if Trim(FModel.OrdenarPor) <> '' then
    SQL := SQL + ' ORDER BY ' + FModel.OrdenarPor;

  FModel.Consulta.SQL.Text := SQL;

  FModel.PrepararConsulta(
    Self,
    FModel.Consulta
  );

  FModel.Consulta.Open;
end;

procedure TControllerBase.Inicializar;
begin
  AtualizarConsulta;
end;

procedure TControllerBase.AtualizarConsulta;
begin
  if FEstadoPaginacao = nil then
  begin
    ExecutarConsultaSemPaginacao;
    Exit;
  end;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  AbrirPaginaAtual;
end;

procedure TControllerBase.Pesquisar(const Valor: string);
begin
  FModel.DefinirFiltro(Valor);

  if FEstadoPaginacao <> nil then
    FEstadoPaginacao.Primeira;

  AtualizarConsulta;
end;

procedure TControllerBase.OrdenarPorCampo(const ACampo: string);
var
  IDAtual: Int64;
  Posicao: Int64;
  Pagina: Integer;
begin
  if not FModel.Consulta.Active then
    Exit;

  if FModel.Consulta.IsEmpty then
    IDAtual := 0
  else
    IDAtual := FModel.Consulta.FieldByName(
      FModel.Identificador
    ).AsLargeInt;

  if FModel.Consulta.FindField(ACampo) = nil then
    Exit;

  if SameText(FCampoOrdenacao, ACampo) then
    FOrdemAscendente := not FOrdemAscendente
  else
  begin
    FCampoOrdenacao := ACampo;
    FOrdemAscendente := True;
  end;

  if FEstadoPaginacao = nil then
  begin
    ExecutarConsultaSemPaginacao;

    if IDAtual > 0 then
      DataSet.Locate(FModel.Identificador, IDAtual, []);

    Exit;
  end;

  if IDAtual > 0 then
  begin
    Posicao := FModel.LocalizarPosicao(
      IDAtual,
      FCampoOrdenacao,
      FOrdemAscendente
    );

    Pagina := FEstadoPaginacao.PaginaDaPosicao(Posicao);

    if Pagina >= 0 then
      FEstadoPaginacao.IrPara(Pagina)
    else
      FEstadoPaginacao.Primeira;
  end
  else
    FEstadoPaginacao.Primeira;

  AbrirPaginaAtual;

  if IDAtual > 0 then
    DataSet.Locate(FModel.Identificador, IDAtual, []);
end;

procedure TControllerBase.TratarAtalho(
  var Key: Word; Shift: TShiftState);
begin
  if not (ssCtrl in Shift) or (FEstadoPaginacao = nil) then
    Exit;

  case Key of
    VK_LEFT:
      Anterior;

    VK_RIGHT:
      Proximo;

    VK_HOME:
      IrParaPrimeiraPagina;

    VK_END:
      IrParaUltimaPagina;
  else
    Exit;
  end;

  Key := 0;
end;

{ Navegação da paginação }

procedure TControllerBase.IrParaPrimeiraPagina;
begin
  if FEstadoPaginacao = nil then
    Exit;

  FEstadoPaginacao.Primeira;
  AbrirPaginaAtual;
end;

procedure TControllerBase.IrParaPaginaAnterior;
begin
  if FEstadoPaginacao = nil then
    Exit;

  FEstadoPaginacao.Anterior;
  AbrirPaginaAtual;
end;

procedure TControllerBase.IrParaProximaPagina;
begin
  if FEstadoPaginacao = nil then
    Exit;

  FEstadoPaginacao.Proxima;
  AbrirPaginaAtual;
end;

procedure TControllerBase.IrParaUltimaPagina;
begin
  if FEstadoPaginacao = nil then
    Exit;

  FEstadoPaginacao.Ultima;
  AbrirPaginaAtual;
end;

procedure TControllerBase.AlterarLimitePorPagina(ALimite: Integer);
begin
  if FEstadoPaginacao = nil then
    Exit;

  FEstadoPaginacao.AlterarLimite(ALimite);
  AtualizarConsulta;
end;

procedure TControllerBase.IrParaPagina(APagina: Integer);
begin
  if FEstadoPaginacao = nil then
    Exit;

  if FEstadoPaginacao.IrPara(APagina) then
    AbrirPaginaAtual;
end;

{ Navegação do registro dentro do DataSet }

procedure TControllerBase.Primeiro;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.First;
end;

procedure TControllerBase.Anterior;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.Prior;
end;

procedure TControllerBase.Proximo;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.Next;
end;

procedure TControllerBase.Ultimo;
begin
  if not DataSet.Active or DataSet.IsEmpty then
    Exit;

  DataSet.Last;
end;

{ Modos de cadastro }

procedure TControllerBase.IniciarInclusao;
begin
  case FModoCadastro of
    mcNavegandoTabela:
      FModoCadastro := mcInclusaoTabela;

    mcNavegandoCadastro:
      FModoCadastro := mcInclusaoCadastro;
  end;
end;

procedure TControllerBase.IniciarEdicao;
begin
  case FModoCadastro of
    mcNavegandoTabela:
      FModoCadastro := mcEdicaoTabela;

    mcNavegandoCadastro:
      FModoCadastro := mcEdicaoCadastro;
  end;
end;

procedure TControllerBase.ConfirmarOperacao;
begin
  case FModoCadastro of
    mcInclusaoTabela, mcEdicaoTabela:
      FModoCadastro := mcNavegandoTabela;

    mcInclusaoCadastro, mcEdicaoCadastro:
      FModoCadastro := mcNavegandoCadastro;
  end;
end;

procedure TControllerBase.CancelarOperacao;
begin
  ConfirmarOperacao;
end;

procedure TControllerBase.NavegarTabela;
begin
  FModoCadastro := mcNavegandoTabela;
end;

procedure TControllerBase.AbrirCadastro;
begin
  FModoCadastro := mcNavegandoCadastro;
end;

{ Restauração da consulta }

procedure TControllerBase.RestaurarConsulta(AID: Int64);
var
  Posicao: Int64;
  Pagina: Integer;
begin
  if FEstadoPaginacao = nil then
  begin
    AtualizarConsulta;

    if (AID > 0) and DataSet.Active then
      DataSet.Locate(FModel.Identificador, AID, []);

    Exit;
  end;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  if AID > 0 then
  begin
    Posicao := FModel.LocalizarPosicao(
      AID,
      FCampoOrdenacao,
      FOrdemAscendente
    );

    Pagina := FEstadoPaginacao.PaginaDaPosicao(Posicao);

    if Pagina >= 0 then
      FEstadoPaginacao.IrPara(Pagina)
    else
      FEstadoPaginacao.Primeira;
  end
  else
    FEstadoPaginacao.Primeira;

  AbrirPaginaAtual;

  if (AID > 0) and DataSet.Active then
    DataSet.Locate(FModel.Identificador, AID, []);
end;

procedure TControllerBase.RestaurarAposInclusao(
  AIDNovo, AIDAnterior: Int64);
var
  PaginaAnterior: Integer;
  PaginaNova: Integer;
  Posicao: Int64;
  IDSelecionado: Int64;
begin
  if FEstadoPaginacao = nil then
  begin
    AtualizarConsulta;

    if (AIDNovo > 0) and
      DataSet.Locate(FModel.Identificador, AIDNovo, []) then
      Exit;

    if AIDAnterior > 0 then
      DataSet.Locate(FModel.Identificador, AIDAnterior, []);

    Exit;
  end;

  PaginaAnterior := FEstadoPaginacao.PaginaAtual;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  IDSelecionado := AIDAnterior;

  if AIDNovo > 0 then
  begin
    Posicao := FModel.LocalizarPosicao(
      AIDNovo,
      FCampoOrdenacao,
      FOrdemAscendente
    );

    PaginaNova := FEstadoPaginacao.PaginaDaPosicao(Posicao);

    if PaginaNova = PaginaAnterior then
    begin
      FEstadoPaginacao.IrPara(PaginaNova);
      IDSelecionado := AIDNovo;
    end
    else if AIDAnterior > 0 then
    begin
      Posicao := FModel.LocalizarPosicao(
        AIDAnterior,
        FCampoOrdenacao,
        FOrdemAscendente
      );

      PaginaNova := FEstadoPaginacao.PaginaDaPosicao(Posicao);

      if PaginaNova >= 0 then
        FEstadoPaginacao.IrPara(PaginaNova)
      else
        IDSelecionado := 0;
    end;
  end;

  AbrirPaginaAtual;

  if IDSelecionado > 0 then
    DataSet.Locate(FModel.Identificador, IDSelecionado, []);
end;

procedure TControllerBase.RestaurarAposExclusao(APosicao: Integer);
var
  Posicao: Int64;
  Pagina: Integer;
  PosicaoLocal: Integer;
begin
  if FEstadoPaginacao = nil then
  begin
    AtualizarConsulta;
    Exit;
  end;

  FEstadoPaginacao.DefinirTotalRegistros(
    FModel.ContarRegistros
  );

  if FEstadoPaginacao.TotalRegistros = 0 then
  begin
    FEstadoPaginacao.Primeira;
    AbrirPaginaAtual;
    Exit;
  end;

  Posicao := APosicao;

  if Posicao < 1 then
    Posicao := 1;

  if Posicao > FEstadoPaginacao.TotalRegistros then
    Posicao := FEstadoPaginacao.TotalRegistros;

  Pagina := FEstadoPaginacao.PaginaDaPosicao(Posicao);

  if Pagina >= 0 then
    FEstadoPaginacao.IrPara(Pagina);

  AbrirPaginaAtual;

  // Selecionar o registro que ocupou a posição excluída.
  PosicaoLocal := (Posicao - 1) mod
    FEstadoPaginacao.LimitePorPagina;

  if DataSet.Active and not DataSet.IsEmpty then
  begin
    DataSet.First;

    if PosicaoLocal > 0 then
      DataSet.MoveBy(PosicaoLocal);
  end;
end;

procedure TControllerBase.GarantirConsultaAtiva(AID: Int64);
begin
  if not DataSet.Active then
    RestaurarConsulta(AID);
end;

end.end.
