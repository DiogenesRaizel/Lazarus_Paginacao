unit ufrmnomes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, DBGrids,
  StdCtrls, ComCtrls, DB, LCLType, uDM, uNomesController,
  uRealcePesquisaDBGrid, uTiposPesquisa, uPesquisaEdit,
  uVisualizacaoCadastro, uTiposCadastro;

type
  { TfrmNomes }

  TfrmNomes = class(TForm)
    btnAlterar: TButton;
    btnExcluir: TButton;
    btnNovo: TButton;
    btnSalvar: TButton;
    btnCancelar: TButton;
    btnSalvarNovo: TButton;
    btnTabela: TButton;
    btnAnterior: TButton;
    btnPrimeiro: TButton;
    btnProximo: TButton;
    btnUltimo: TButton;
    dbgNomes: TDBGrid;
    dsNomes: TDataSource;
    edtNome: TEdit;
    edtCidade: TEdit;
    edtFiltro: TEdit;
    Label1: TLabel;
    lblID: TLabel;
    lblNome: TLabel;
    lblCidade: TLabel;
    lblPesquisar: TLabel;
    lbCidadeAutoComplete: TListBox;
    pcNomes: TPageControl;
    pnButtomCadastro: TPanel;
    pnButtomTabela: TPanel;
    pnNavigator: TPanel;
    pnTop: TPanel;
    pnTopCadastro: TPanel;
    StatusBar1: TStatusBar;
    tsTabela: TTabSheet;
    tsCadastro: TTabSheet;
    procedure btnAlterarClick(Sender: TObject);
    procedure btnAnteriorClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnExcluirCadastroClick(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnPrimeiroClick(Sender: TObject);
    procedure btnProximoClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnTabelaClick(Sender: TObject);
    procedure btnUltimoClick(Sender: TObject);
    procedure dbgNomesDblClick(Sender: TObject);
    procedure dbgNomesTitleClick(Column: TColumn);
    procedure dsNomesDataChange(Sender: TObject; Field: TField);
    procedure edtFiltroChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSalvarNovoClick(Sender: TObject);
  private
    FController: TNomesController;
    FRealce: TRealcePesquisaDBGrid;
    FVisualizacao: TVisualizacaoCadastro;
    FPesquisaCidade: TPesquisaEdit;
    FIDRegistroAtual: Int64;
    FCarregandoCadastro: Boolean;
    function ConsultarSugestoesCidade(const Valor: string): TSugestaoPesquisaArray;
    procedure MostrarCadastro;
    procedure LimparCadastro;
    procedure AtualizarBotoesNavegacao;
    procedure VerificarAlteracao(Sender: TObject);
    procedure SalvarRegistro(AContinuarIncluindo: Boolean);
    procedure AtualizarStatus(const Texto: string);
  public
    procedure GarantirConsultaAtiva;
  end;

var
  frmNomes: TfrmNomes;

implementation

{$R *.lfm}

{ TfrmNomes }

procedure TfrmNomes.FormCreate(Sender: TObject);
begin
  // Estado inicial
  FIDRegistroAtual := 0;
  FCarregandoCadastro := False;

  // Configuração do formulário
  Font.Size := 12;
  KeyPreview := True;
  pcNomes.ActivePageIndex := 0;
  pcNomes.ShowTabs := False;

  // Configuração da visualização
  FVisualizacao := TVisualizacaoCadastro.Create(Self, pcNomes, tsTabela,
    tsCadastro, pnTop, pnTopCadastro, pnButtomTabela, pnButtomCadastro);

  pnTopCadastro.Visible := False;
  lbCidadeAutoComplete.Visible := False;

  // Pesquisa de cidades
  FPesquisaCidade := TPesquisaEdit.Create(edtCidade, lbCidadeAutoComplete,
    @ConsultarSugestoesCidade);
  FPesquisaCidade.OnAlteracaoTexto := @VerificarAlteracao;

  // Controller
  FController := TNomesController.Create(DM.NomesModel, DM.CidadesModel,
    pnNavigator, dbgNomes);

  // DataSource e eventos
  dsNomes.OnDataChange := @dsNomesDataChange;
  dsNomes.DataSet := FController.DataSet;
  edtNome.OnChange := @VerificarAlteracao;

  // Realce da pesquisa
  FRealce := TRealcePesquisaDBGrid.Create(dbgNomes, DM.NomesModel, edtFiltro);

  // Inicialização da consulta
  FController.Inicializar;

  // Estado inicial dos botões
  AtualizarBotoesNavegacao;

  // Estado inicial do status bar
  AtualizarStatus('Navegando');

  // Oculta a coluna CidadeID
  if dbgNomes.Columns.ColumnByFieldname('CidadeID') <> nil then
    dbgNomes.Columns.ColumnByFieldname('CidadeID').Visible := False;
end;

procedure TfrmNomes.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPesquisaCidade);
  FreeAndNil(FRealce);
  FreeAndNil(FController);
  FreeAndNil(FVisualizacao);
end;

procedure TfrmNomes.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FController <> nil then
    FController.TratarAtalho(Key, Shift);
end;

procedure TfrmNomes.btnSalvarNovoClick(Sender: TObject);
begin
  SalvarRegistro(True);
end;

function TfrmNomes.ConsultarSugestoesCidade(const Valor: string): TSugestaoPesquisaArray;
begin
  Result := FController.ConsultarSugestoesCidade(Valor);
end;

procedure TfrmNomes.MostrarCadastro;
begin
  FCarregandoCadastro := True;
  try
    lblID.Caption := 'ID: ' + IntToStr(
      dsNomes.DataSet.FieldByName(FController.Identificador).AsLargeInt
    );

    edtNome.Text := dsNomes.DataSet.FieldByName('Nome').AsString;

    FPesquisaCidade.DefinirSelecao(
      dsNomes.DataSet.FieldByName('CidadeID').AsInteger,
      dsNomes.DataSet.FieldByName('Cidade').AsString
    );

    lbCidadeAutoComplete.Visible := False;
    AtualizarBotoesNavegacao;
  finally
    FCarregandoCadastro := False;
  end;
end;

procedure TfrmNomes.LimparCadastro;
begin
  FCarregandoCadastro := True;
  try
    lblID.Caption := 'ID: Novo';
    edtNome.Text := '';
    edtCidade.Text := '';
    FPesquisaCidade.LimparSelecao;
  finally
    FCarregandoCadastro := False;
  end;
end;

procedure TfrmNomes.AtualizarBotoesNavegacao;
var
  TemRegistro: Boolean;
begin
  TemRegistro := dsNomes.DataSet.Active and
    not dsNomes.DataSet.IsEmpty;

  btnAlterar.Enabled := TemRegistro;
  btnExcluir.Enabled := TemRegistro;
  btnPrimeiro.Enabled := TemRegistro and not dsNomes.DataSet.BOF;
  btnAnterior.Enabled := TemRegistro and not dsNomes.DataSet.BOF;
  btnProximo.Enabled := TemRegistro and not dsNomes.DataSet.EOF;
  btnUltimo.Enabled := TemRegistro and not dsNomes.DataSet.EOF;
end;

procedure TfrmNomes.VerificarAlteracao(Sender: TObject);
begin
  if FCarregandoCadastro then
    Exit;

  if FController = nil then
    Exit;

  if FController.ModoCadastro = mcNavegandoCadastro then
  begin
    FController.IniciarEdicao;
    FVisualizacao.Configurar(FController.ModoCadastro);
    AtualizarStatus('Alterando registro');
  end;
end;

procedure TfrmNomes.SalvarRegistro(AContinuarIncluindo: Boolean);
var
  IDRegistro: Int64;
begin
  try
    if not FController.Salvar(
      edtNome.Text,
      FPesquisaCidade.SelecionadoID,
      IDRegistro
    ) then
      Exit;

    if AContinuarIncluindo then
    begin
      FController.IniciarInclusao;
      FVisualizacao.Configurar(FController.ModoCadastro);
      LimparCadastro;
      AtualizarStatus('Registro salvo com sucesso. Novo registro.');
    end
    else
    begin
      FVisualizacao.Configurar(FController.ModoCadastro);

      if FController.ModoCadastro = mcNavegandoCadastro then
        MostrarCadastro;

      AtualizarStatus('Registro salvo com sucesso.');
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao salvar registro:' + LineEnding + E.Message);
  end;
end;

procedure TfrmNomes.AtualizarStatus(const Texto: string);
begin
  StatusBar1.SimpleText := '  ' + Texto;
end;

procedure TfrmNomes.GarantirConsultaAtiva;
begin
  FController.GarantirConsultaAtiva(FIDRegistroAtual);
end;

procedure TfrmNomes.edtFiltroChange(Sender: TObject);
begin
  if FController <> nil then
    FController.Pesquisar(edtFiltro.Text);
end;

procedure TfrmNomes.dbgNomesTitleClick(Column: TColumn);
begin
  if FController <> nil then
    FController.OrdenarPorCampo(Column.FieldName);

  // Oculta a coluna CidadeID
  if dbgNomes.Columns.ColumnByFieldname('CidadeID') <> nil then
    dbgNomes.Columns.ColumnByFieldname('CidadeID').Visible := False;
end;

procedure TfrmNomes.dsNomesDataChange(Sender: TObject; Field: TField);
begin
  AtualizarBotoesNavegacao;

  if not dsNomes.DataSet.Active then
  begin
    FIDRegistroAtual := 0;
    Exit;
  end;

  if dsNomes.DataSet.IsEmpty then
  begin
    FIDRegistroAtual := 0;
    Exit;
  end;

  FIDRegistroAtual := dsNomes.DataSet.FieldByName(
    FController.Identificador
  ).AsLargeInt;

  if FController.ModoCadastro in [mcNavegandoTabela, mcNavegandoCadastro] then
    AtualizarStatus('Navegando');
end;

procedure TfrmNomes.btnSalvarClick(Sender: TObject);
begin
  SalvarRegistro(False);
end;

procedure TfrmNomes.btnTabelaClick(Sender: TObject);
begin
  FController.NavegarTabela;
  FVisualizacao.Configurar(FController.ModoCadastro);
  AtualizarStatus('Navegando');
end;

procedure TfrmNomes.btnUltimoClick(Sender: TObject);
begin
  FController.Ultimo;
  MostrarCadastro;
  AtualizarStatus('Navegando');
end;

procedure TfrmNomes.dbgNomesDblClick(Sender: TObject);
begin
  if not dsNomes.DataSet.Active then
    Exit;

  if dsNomes.DataSet.IsEmpty then
    Exit;

  FController.AbrirCadastro;
  FVisualizacao.Configurar(FController.ModoCadastro);
  MostrarCadastro;
  AtualizarStatus('Navegando');
end;

procedure TfrmNomes.btnCancelarClick(Sender: TObject);
begin
  FController.CancelarOperacao;
  LimparCadastro;
  FVisualizacao.Configurar(FController.ModoCadastro);

  if FController.ModoCadastro = mcNavegandoCadastro then
    MostrarCadastro;

  AtualizarStatus('Navegando');
end;

procedure TfrmNomes.btnAlterarClick(Sender: TObject);
begin
  if not dsNomes.DataSet.Active then
    Exit;

  if dsNomes.DataSet.IsEmpty then
    Exit;

  FController.IniciarEdicao;

  if not (FController.ModoCadastro in [
    mcEdicaoTabela, mcEdicaoCadastro
  ]) then
    Exit;

  FVisualizacao.Configurar(FController.ModoCadastro);
  MostrarCadastro;
  AtualizarStatus('Alterando registro');
end;

procedure TfrmNomes.btnAnteriorClick(Sender: TObject);
begin
  FController.Anterior;
  MostrarCadastro;
  AtualizarStatus('Navegando');
end;

procedure TfrmNomes.btnExcluirCadastroClick(Sender: TObject);
var
  IDAtual: Int64;
  PosicaoAtual: Integer;
begin
  if not (FController.ModoCadastro in [
    mcNavegandoTabela, mcNavegandoCadastro
  ]) then
    Exit;

  if not dsNomes.DataSet.Active then
    Exit;

  if dsNomes.DataSet.IsEmpty then
    Exit;

  IDAtual := dsNomes.DataSet.FieldByName(
    FController.Identificador
  ).AsLargeInt;

  if IDAtual <= 0 then
    Exit;

  if MessageDlg(
    'Confirma a exclusão deste registro?',
    mtConfirmation,
    [mbYes, mbNo],
    0
  ) <> mrYes then
    Exit;

  try
    PosicaoAtual := FController.PosicaoRegistroAtual;
    FController.Excluir(IDAtual);

    FController.RestaurarAposExclusao(PosicaoAtual);
    AtualizarStatus('Registro excluído com sucesso.');

    if dsNomes.DataSet.Active and not dsNomes.DataSet.IsEmpty then
    begin
      FIDRegistroAtual := dsNomes.DataSet.FieldByName(
        FController.Identificador
      ).AsLargeInt;

      MostrarCadastro;
    end
    else
    begin
      FIDRegistroAtual := 0;
      LimparCadastro;
      AtualizarBotoesNavegacao;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao excluir registro:' + LineEnding + E.Message);
  end;
end;

procedure TfrmNomes.btnNovoClick(Sender: TObject);
begin
  FController.IniciarInclusao;
  FVisualizacao.Configurar(FController.ModoCadastro);
  LimparCadastro;
  AtualizarStatus('Novo registro');
end;

procedure TfrmNomes.btnPrimeiroClick(Sender: TObject);
begin
  FController.Primeiro;
  MostrarCadastro;
  AtualizarStatus('Navegando');
end;

procedure TfrmNomes.btnProximoClick(Sender: TObject);
begin
  FController.Proximo;
  MostrarCadastro;
  AtualizarStatus('Navegando');
end;

end.
