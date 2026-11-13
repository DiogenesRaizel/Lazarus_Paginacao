unit uControllerBase;

{$mode ObjFPC}{$H+}

interface

uses
  Controls, ExtCtrls, DBGrids, Classes, SysUtils, DB, SQLDB,
  uPaginadorSQL, uPaginacaoDBGrid, uModelBase, Dialogs, uTiposCadastro;

type

  { TControllerBase }

  TControllerBase = class
  protected
    FModel: TModelBase;
    FPaginador: TPaginadorSQL;
    FPaginacao: TPaginacaoDBGrid;
    FGrade: TDBGrid;
    FModoCadastro: TModoCadastro;

    function GetDataSet: TDataSet;
    function GetIdentificador: string;

    procedure ConfigurarPaginador;
    procedure ExecutarConsultaSemPaginacao;
    procedure AtualizarTitulosOrdenacao(Sender: TObject);

  public
    constructor Create(AModel: TModelBase; APainel: TPanel; AGrade: TDBGrid);
    destructor Destroy; override;

    function PosicaoRegistroAtual: Integer;

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
  end;


implementation

constructor TControllerBase.Create(AModel: TModelBase; APainel: TPanel; AGrade: TDBGrid);
begin
  inherited Create;

  if AModel = nil then
    raise Exception.Create('O Model não foi informado.');

  if AGrade = nil then
    raise Exception.Create('A DBGrid não foi informada.');

  FModel := AModel;
  FGrade := AGrade;
  FPaginacao := nil;
  FPaginador := nil;

  FModoCadastro := mcNavegandoTabela;

  if APainel <> nil then
  begin
    FPaginacao := TPaginacaoDBGrid.Create(APainel);

    try
      FPaginador := TPaginadorSQL.Create(FModel.Consulta, FPaginacao, AGrade);
      FPaginador.OnPrepararConsulta := @FModel.PrepararConsulta;
      FPaginador.OnAtualizarInterface := @AtualizarTitulosOrdenacao;
    except
      FreeAndNil(FPaginacao);
      raise;
    end;
  end;
end;

destructor TControllerBase.Destroy;
begin
  FreeAndNil(FPaginador);
  FreeAndNil(FPaginacao);
  inherited Destroy;
end;

function TControllerBase.PosicaoRegistroAtual: Integer;
begin
  Result := -1;

  if FPaginador <> nil then
    Result := FPaginador.PosicaoRegistroAtual;
end;

function TControllerBase.GetDataSet: TDataSet;
begin
  Result := FModel.Consulta;
end;

function TControllerBase.GetIdentificador: string;
begin
  Result := FModel.Identificador;
end;

procedure TControllerBase.ConfigurarPaginador;
begin
  if FPaginador = nil then
    Exit;

  FPaginador.CampoIdentificador := FModel.Identificador;
  FPaginador.SQLBase := FModel.SQLBase;
  FPaginador.SQLContagem := FModel.SQLContagem;

  if Trim(FPaginador.OrdenarPor) = '' then
    FPaginador.OrdenarPor := FModel.OrdenarPor;

  FPaginador.OnPrepararConsulta := @FModel.PrepararConsulta;
  FPaginador.OnAtualizarInterface := @AtualizarTitulosOrdenacao;
end;

procedure TControllerBase.ExecutarConsultaSemPaginacao;
var
  SQL: string;
begin
  FModel.Consulta.Close;

  SQL := Trim(FModel.SQLBase);

  if Trim(FModel.OrdenarPor) <> '' then
    SQL := SQL + ' ORDER BY ' + FModel.OrdenarPor;

  FModel.Consulta.SQL.Text := SQL;
  FModel.PrepararConsulta(Self, FModel.Consulta);
  FModel.Consulta.Open;
end;

procedure TControllerBase.AtualizarTitulosOrdenacao(Sender: TObject);
var
  I: Integer;
  Titulo: string;
  Seta: string;
begin
  if (FGrade = nil) or (FPaginador = nil) then
    Exit;

  for I := 0 to FGrade.Columns.Count - 1 do
  begin
    if FGrade.Columns[I].Visible then
    begin
      Titulo := FGrade.Columns[I].Title.Caption;

      if Copy(Titulo, 1, 2) = '↓ ' then
        Delete(Titulo, 1, 2)
      else if Copy(Titulo, 1, 2) = '↑ ' then
        Delete(Titulo, 1, 2);

      if SameText(FGrade.Columns[I].FieldName, FPaginador.CampoOrdenacao) then
      begin
        if FPaginador.OrdemAscendente then
          Seta := '↓ '
        else
          Seta := '↑ ';

        Titulo := Seta + Titulo;
      end;

      FGrade.Columns[I].Title.Caption := Titulo;
    end;

  end;
end;

procedure TControllerBase.Inicializar;
begin
  if FPaginador <> nil then
  begin
    ConfigurarPaginador;
    FPaginador.Abrir;
  end
  else
    ExecutarConsultaSemPaginacao;
end;

procedure TControllerBase.AtualizarConsulta;
begin
  if FPaginador <> nil then
  begin
    ConfigurarPaginador;
    FPaginador.Abrir;
  end
  else
    ExecutarConsultaSemPaginacao;
end;

procedure TControllerBase.Pesquisar(const Valor: string);
begin
  FModel.DefinirFiltro(Valor);

  if FPaginador <> nil then
  begin
    ConfigurarPaginador;
    FPaginador.Reiniciar;
  end
  else
    ExecutarConsultaSemPaginacao;
end;

procedure TControllerBase.OrdenarPorCampo(const ACampo: string);
begin
  if (FPaginador = nil) or not FModel.Consulta.Active then
    Exit;

  if FModel.Consulta.FindField(ACampo) = nil then
    Exit;

  FPaginador.OrdenarPorCampo(ACampo);
end;

procedure TControllerBase.TratarAtalho(var Key: Word; Shift: TShiftState);
begin
  if FPaginador <> nil then
    FPaginador.TratarAtalho(Key, Shift);
end;

procedure TControllerBase.Primeiro;
begin
  if not FModel.Consulta.Active or FModel.Consulta.IsEmpty then
    Exit;

  FModel.Consulta.First;
end;

procedure TControllerBase.Anterior;
begin
  if not FModel.Consulta.Active or FModel.Consulta.IsEmpty then
    Exit;

  FModel.Consulta.Prior;
end;

procedure TControllerBase.Proximo;
begin
  if not FModel.Consulta.Active or FModel.Consulta.IsEmpty then
    Exit;

  FModel.Consulta.Next;
end;

procedure TControllerBase.Ultimo;
begin
  if not FModel.Consulta.Active or FModel.Consulta.IsEmpty then
    Exit;

  FModel.Consulta.Last;
end;

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

procedure TControllerBase.RestaurarConsulta(AID: Int64);
begin
  if FPaginador <> nil then
  begin
    ConfigurarPaginador;

    if AID > 0 then
      FPaginador.AbrirNoRegistro(AID)
    else
      FPaginador.Abrir;
  end
  else
  begin
    AtualizarConsulta;

    if (AID > 0) and DataSet.Active then
      DataSet.Locate(FModel.Identificador, AID, []);
  end;
end;

procedure TControllerBase.RestaurarAposInclusao(AIDNovo, AIDAnterior: Int64);
begin
  if FPaginador <> nil then
  begin
    ConfigurarPaginador;
    FPaginador.AbrirAposInclusao(AIDNovo, AIDAnterior);
    Exit;
  end;

  AtualizarConsulta;

  if (AIDNovo > 0) and DataSet.Active and
    DataSet.Locate(FModel.Identificador, AIDNovo, []) then
    Exit;

  if (AIDAnterior > 0) and DataSet.Active then
    DataSet.Locate(FModel.Identificador, AIDAnterior, []);
end;

procedure TControllerBase.RestaurarAposExclusao(APosicao: Integer);
begin
  if FPaginador <> nil then
  begin
    ConfigurarPaginador;
    FPaginador.AbrirAposExclusao(APosicao);
    Exit;
  end;

  AtualizarConsulta;
end;

procedure TControllerBase.GarantirConsultaAtiva(AID: Int64);
begin
  if not DataSet.Active then
    RestaurarConsulta(AID);
end;

end.
