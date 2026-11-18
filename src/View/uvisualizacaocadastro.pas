unit uVisualizacaoCadastro;

{$mode ObjFPC}{$H+}

interface

uses
  ComCtrls, StdCtrls, DB, ExtCtrls,
  uTiposCadastro;

type

  TBotoesCadastro = record
    Novo: TButton;
    Alterar: TButton;
    Excluir: TButton;
    Salvar: TButton;
    SalvarNovo: TButton;
    Cancelar: TButton;
    Primeiro: TButton;
    Anterior: TButton;
    Proximo: TButton;
    Ultimo: TButton;
    Tabela: TButton;
  end;

  { TVisualizacaoCadastro }

  TVisualizacaoCadastro = class
  private
    FPageControl: TPageControl;
    FPaginaTabela: TTabSheet;
    FPaginaCadastro: TTabSheet;
    FPnRodapeCadastro : TPanel;
    FDataSource: TDataSource;

    FModoApresentacao: TModoApresentacao;
    FModoCadastro: TModoCadastro;

    FBtnNovo: TButton;
    FBtnAlterar: TButton;
    FBtnExcluir: TButton;
    FBtnSalvar: TButton;
    FBtnSalvarNovo: TButton;
    FBtnCancelar: TButton;

    FBtnPrimeiro: TButton;
    FBtnAnterior: TButton;
    FBtnProximo: TButton;
    FBtnUltimo: TButton;

    FBtnTabela: TButton;

  public
    constructor Create(APageControl: TPageControl;
      APaginaTabela, APaginaCadastro: TTabSheet;
      APnRodapeCadastro: TPanel;
      ADataSource: TDataSource;
      const ABotoes: TBotoesCadastro);

    procedure Configurar(AModoCadastro: TModoCadastro);
    procedure AtualizarBotoesNavegacao;


    property ModoApresentacao: TModoApresentacao read FModoApresentacao;
  end;

implementation

constructor TVisualizacaoCadastro.Create(APageControl: TPageControl;
  APaginaTabela, APaginaCadastro: TTabSheet;
  APnRodapeCadastro: TPanel;
  ADataSource: TDataSource;
  const ABotoes: TBotoesCadastro);
begin
  inherited Create;

  FPageControl := APageControl;
  FPaginaTabela := APaginaTabela;
  FPaginaCadastro := APaginaCadastro;
  FPnRodapeCadastro := APnRodapeCadastro;
  FDataSource := ADataSource;

  if FPageControl.ActivePage = FPaginaTabela then
  begin
    FModoApresentacao := maTabela;
    FModoCadastro := mcNavegandoTabela;
  end
  else
  begin
    FModoApresentacao := maCadastro;
    FModoCadastro := mcNavegandoCadastro;
  end;

  FBtnNovo := ABotoes.Novo;
  FBtnAlterar := ABotoes.Alterar;
  FBtnExcluir := ABotoes.Excluir;
  FBtnSalvar := ABotoes.Salvar;
  FBtnSalvarNovo := ABotoes.SalvarNovo;
  FBtnCancelar := ABotoes.Cancelar;

  FBtnPrimeiro := ABotoes.Primeiro;
  FBtnAnterior := ABotoes.Anterior;
  FBtnProximo := ABotoes.Proximo;
  FBtnUltimo := ABotoes.Ultimo;

  FBtnTabela := ABotoes.Tabela;
end;

procedure TVisualizacaoCadastro.AtualizarBotoesNavegacao;
var
  DataSet: TDataSet;
  TemRegistro, Navegando: Boolean;
begin
  DataSet := FDataSource.DataSet;

  TemRegistro := Assigned(DataSet);

  if TemRegistro then
    TemRegistro := DataSet.Active and not DataSet.IsEmpty;

  Navegando := FModoCadastro in [
    mcNavegandoTabela,
    mcNavegandoCadastro
  ];

  FBtnAlterar.Enabled := TemRegistro and Navegando;
  FBtnExcluir.Enabled := TemRegistro and Navegando;

  FBtnPrimeiro.Enabled := False;
  FBtnAnterior.Enabled := False;
  FBtnProximo.Enabled := False;
  FBtnUltimo.Enabled := False;

  if TemRegistro and Navegando then
  begin
    FBtnPrimeiro.Enabled := not DataSet.BOF;
    FBtnAnterior.Enabled := not DataSet.BOF;
    FBtnProximo.Enabled := not DataSet.EOF;
    FBtnUltimo.Enabled := not DataSet.EOF;
  end;
end;

procedure TVisualizacaoCadastro.Configurar(AModoCadastro: TModoCadastro);
begin
  FModoCadastro := AModoCadastro;

  case AModoCadastro of

    mcNavegandoTabela:
      begin
        FPageControl.ActivePage := FPaginaTabela;
        FModoApresentacao := maTabela;
      end;

    mcNavegandoCadastro,
    mcInclusaoTabela, mcEdicaoTabela,
    mcInclusaoCadastro, mcEdicaoCadastro:
      begin
        FPageControl.ActivePage := FPaginaCadastro;
        FModoApresentacao := maCadastro;
      end;
  end;

  case AModoCadastro of

    mcNavegandoTabela, mcNavegandoCadastro:
      begin
        FBtnNovo.Enabled := True;

        FBtnSalvar.Enabled := False;
        FBtnSalvarNovo.Enabled := False;
        FBtnCancelar.Enabled := False;
      end;

    mcInclusaoTabela, mcInclusaoCadastro,
    mcEdicaoTabela, mcEdicaoCadastro:
      begin
        FBtnNovo.Enabled := False;

        FBtnSalvar.Enabled := True;
        FBtnSalvarNovo.Enabled := True;
        FBtnCancelar.Enabled := True;
      end;
  end;

  FPnRodapeCadastro.Visible := not (AModoCadastro in [
    mcInclusaoTabela,
    mcEdicaoTabela
  ]);

  FBtnTabela.Enabled := AModoCadastro = mcNavegandoCadastro;

  AtualizarBotoesNavegacao;
end;

end.
