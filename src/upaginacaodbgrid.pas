unit uPaginacaoDBGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls;

type

  TNavegarPaginaEvent = procedure(Sender: TObject) of object;
  TAlterarLimiteEvent = procedure(Sender: TObject; ALimite: Integer) of object;
  TIrParaPaginaEvent = procedure(Sender: TObject; APagina: Integer) of object;
  TNavegarPaginaNumeroEvent = procedure(Sender: TObject; APagina: Integer) of object;

  { TPaginacaoDBGrid }

  TPaginacaoDBGrid = class
  private
    FLblPaginas: TLabel;
    FLblLimite: TLabel;
    FCbLimite: TComboBox;
    FEdtIrParaPagina: TEdit;

    FOnPaginaAnterior: TNavegarPaginaEvent;
    FOnAlterarLimite: TAlterarLimiteEvent;

    FOnPrimeiraPagina: TNavegarPaginaEvent;
    FOnProximaPagina: TNavegarPaginaEvent;
    FOnUltimaPagina: TNavegarPaginaEvent;
    FOnIrParaPagina: TIrParaPaginaEvent;
    FOnNavegarPaginaNumero: TNavegarPaginaNumeroEvent;

    FBtnPaginas: array of TButton;
    FLabelsReticencias: array of TLabel;


    FPNavigator: TPanel;
    FPaginaAtual: Integer;
    FTotalPaginas: Integer;

    FBtnPrimeiro: TButton;
    FBtnAnterior: TButton;
    FBtnProxima: TButton;
    FBtnUltimo: TButton;

    function GetLimiteAtual: Integer;

    procedure BtnPaginaClick(Sender: TObject);
    procedure LimparBotoesPaginas;
    procedure AdicionarPagina(APagina: Integer; var AX: Integer);
    procedure AdicionarReticencias(var AX: Integer);


    procedure CriarControles;
    procedure BtnPrimeiroClick(Sender: TObject);
    procedure BtnAnteriorClick(Sender: TObject);
    procedure BtnProximaClick(Sender: TObject);
    procedure BtnUltimoClick(Sender: TObject);

    procedure CbLimiteChange(Sender: TObject);
    procedure EdtIrParaPaginaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Atualizar(APaginaAtual, ATotalPaginas, AXFinal: Integer);

  public
    constructor Create(APainel: TPanel);


    procedure AtualizarPaginas(APaginaAtual, ATotalPaginas: Integer);
    procedure LimparCampoPagina;

    property PaginaAtual: Integer read FPaginaAtual;
    property TotalPaginas: Integer read FTotalPaginas;

    property LimiteAtual: Integer read GetLimiteAtual;

    property OnPrimeiraPagina: TNavegarPaginaEvent read FOnPrimeiraPagina write FOnPrimeiraPagina;
    property OnPaginaAnterior: TNavegarPaginaEvent read FOnPaginaAnterior write FOnPaginaAnterior;
    property OnProximaPagina: TNavegarPaginaEvent read FOnProximaPagina write FOnProximaPagina;
    property OnUltimaPagina: TNavegarPaginaEvent read FOnUltimaPagina write FOnUltimaPagina;


    property OnAlterarLimite: TAlterarLimiteEvent read FOnAlterarLimite write FOnAlterarLimite;
    property OnIrParaPagina: TIrParaPaginaEvent read FOnIrParaPagina write FOnIrParaPagina;
    property OnNavegarPaginaNumero: TNavegarPaginaNumeroEvent read FOnNavegarPaginaNumero write FOnNavegarPaginaNumero;

  end;

implementation

constructor TPaginacaoDBGrid.Create(APainel: TPanel);
begin
  inherited Create;

  FPNavigator := APainel;
  FPaginaAtual := 0;
  FTotalPaginas := 0;

  CriarControles;
end;

function TPaginacaoDBGrid.GetLimiteAtual: Integer;
begin
  Result := StrToInt(FCbLimite.Text);
end;

procedure TPaginacaoDBGrid.BtnPaginaClick(Sender: TObject);
begin
  if Assigned(FOnNavegarPaginaNumero) then
    FOnNavegarPaginaNumero(Sender, TButton(Sender).Tag);
end;

procedure TPaginacaoDBGrid.LimparBotoesPaginas;
var
  I: Integer;
begin
  for I := High(FBtnPaginas) downto Low(FBtnPaginas) do
    FBtnPaginas[I].Free;

  SetLength(FBtnPaginas, 0);

  for I := High(FLabelsReticencias) downto Low(FLabelsReticencias) do
    FLabelsReticencias[I].Free;

  SetLength(FLabelsReticencias, 0);
end;

procedure TPaginacaoDBGrid.AdicionarPagina(
  APagina: Integer; var AX: Integer);
var
  N: Integer;
begin
  N := Length(FBtnPaginas);
  SetLength(FBtnPaginas, N + 1);

  FBtnPaginas[N] := TButton.Create(FPNavigator);
  FBtnPaginas[N].Parent := FPNavigator;
  FBtnPaginas[N].SetBounds(AX, 9, 32, 32);
  FBtnPaginas[N].Caption := IntToStr(APagina + 1);
  FBtnPaginas[N].Tag := APagina;
  FBtnPaginas[N].OnClick := @BtnPaginaClick;
  FBtnPaginas[N].Anchors := [akLeft, akTop];

  FBtnPaginas[N].Enabled := APagina <> FPaginaAtual;

  Inc(AX, 36);
end;

procedure TPaginacaoDBGrid.AdicionarReticencias(var AX: Integer);
var
  N: Integer;
begin
  N := Length(FLabelsReticencias);
  SetLength(FLabelsReticencias, N + 1);

  FLabelsReticencias[N] := TLabel.Create(FPNavigator);
  FLabelsReticencias[N].Parent := FPNavigator;
  FLabelsReticencias[N].Caption := '...';
  FLabelsReticencias[N].SetBounds(AX, 18, 24, 17);
  FLabelsReticencias[N].Anchors := [akLeft, akTop];

  Inc(AX, 28);
end;

procedure TPaginacaoDBGrid.CriarControles;
begin
  FLblLimite := TLabel.Create(FPNavigator);
  FLblLimite.Parent := FPNavigator;
  FLblLimite.Caption := '&Linhas:';
  FLblLimite.SetBounds(11, 18, 49, 17);

  FCbLimite := TComboBox.Create(FPNavigator);
  FCbLimite.Parent := FPNavigator;
  FCbLimite.SetBounds(68, 8, 72, 34);
  FCbLimite.Style := csDropDownList;
  FCbLimite.Items.Add('10');
  FCbLimite.Items.Add('20');
  FCbLimite.Items.Add('50');
  FCbLimite.Items.Add('100');
  FCbLimite.ItemIndex := 0;
  FCbLimite.OnChange := @CbLimiteChange;

  FLblPaginas := TLabel.Create(FPNavigator);
  FLblPaginas.Parent := FPNavigator;
  FLblPaginas.Caption := '&Páginas:';
  FLblPaginas.SetBounds(150, 18, 55, 17);

  FBtnPrimeiro := TButton.Create(FPNavigator);
  FBtnPrimeiro.Parent := FPNavigator;
  FBtnPrimeiro.Caption := '«';
  FBtnPrimeiro.SetBounds(216, 9, 32, 32);
  FBtnPrimeiro.OnClick := @BtnPrimeiroClick;

  FBtnAnterior := TButton.Create(FPNavigator);
  FBtnAnterior.Parent := FPNavigator;
  FBtnAnterior.Caption := '‹';
  FBtnAnterior.SetBounds(252, 9, 32, 32);
  FBtnAnterior.OnClick := @BtnAnteriorClick;

  FBtnProxima := TButton.Create(FPNavigator);
  FBtnProxima.Parent := FPNavigator;
  FBtnProxima.Caption := '›';
  FBtnProxima.SetBounds(0, 9, 32, 32);
  FBtnProxima.OnClick := @BtnProximaClick;

  FBtnUltimo := TButton.Create(FPNavigator);
  FBtnUltimo.Parent := FPNavigator;
  FBtnUltimo.Caption := '»';
  FBtnUltimo.SetBounds(0, 9, 32, 32);
  FBtnUltimo.OnClick := @BtnUltimoClick;

  FEdtIrParaPagina := TEdit.Create(FPNavigator);
  FEdtIrParaPagina.Parent := FPNavigator;
  FEdtIrParaPagina.SetBounds(1163, 9, 45, 34);
  FEdtIrParaPagina.NumbersOnly := True;
  FEdtIrParaPagina.OnKeyDown := @EdtIrParaPaginaKeyDown;

  FLblLimite.FocusControl := FCbLimite;
  FLblPaginas.FocusControl := FEdtIrParaPagina;
end;

procedure TPaginacaoDBGrid.BtnPrimeiroClick(Sender: TObject);
begin
  if Assigned(OnPrimeiraPagina) then
    OnPrimeiraPagina(Sender);
end;

procedure TPaginacaoDBGrid.BtnAnteriorClick(Sender: TObject);
begin
  if Assigned(OnPaginaAnterior) then
    OnPaginaAnterior(Sender);
end;

procedure TPaginacaoDBGrid.BtnProximaClick(Sender: TObject);
begin
  if Assigned(OnProximaPagina) then
    OnProximaPagina(Sender);
end;

procedure TPaginacaoDBGrid.BtnUltimoClick(Sender: TObject);
begin
  if Assigned(OnUltimaPagina) then
    OnUltimaPagina(Sender);
end;

procedure TPaginacaoDBGrid.CbLimiteChange(Sender: TObject);
begin
  if Assigned(FOnAlterarLimite) then
    FOnAlterarLimite(Sender, StrToInt(FCbLimite.Text));
end;

procedure TPaginacaoDBGrid.EdtIrParaPaginaKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
var
  NumeroPagina: Integer;
begin
  if (Key = 13) and (FEdtIrParaPagina.Text <> '') then
  begin
    if not TryStrToInt(FEdtIrParaPagina.Text, NumeroPagina) then
    begin
      FEdtIrParaPagina.Clear;
      Key := 0;
      Exit;
    end;

    if Assigned(FOnIrParaPagina) then
      FOnIrParaPagina(Sender, NumeroPagina - 1);

    Key := 0;
  end;
end;

procedure TPaginacaoDBGrid.Atualizar(
  APaginaAtual, ATotalPaginas, AXFinal: Integer);
begin
  FPaginaAtual := APaginaAtual;
  FTotalPaginas := ATotalPaginas;

  FBtnProxima.SetBounds(AXFinal, 9, 32, 32);
  FBtnUltimo.SetBounds(AXFinal + 36, 9, 32, 32);
  FEdtIrParaPagina.SetBounds(AXFinal + 76, 9, 55, 34);

  FBtnPrimeiro.Enabled := APaginaAtual > 0;
  FBtnAnterior.Enabled := APaginaAtual > 0;
  FBtnProxima.Enabled := APaginaAtual < ATotalPaginas - 1;
  FBtnUltimo.Enabled := APaginaAtual < ATotalPaginas - 1;

  // Com 0 ou 1 página não há para onde ir: desativa "Páginas:" e o campo.
  FLblPaginas.Enabled := ATotalPaginas > 1;
  FEdtIrParaPagina.Enabled := ATotalPaginas > 1;

  if ATotalPaginas <= 1 then
    FEdtIrParaPagina.Clear;
end;

procedure TPaginacaoDBGrid.AtualizarPaginas(
  APaginaAtual, ATotalPaginas: Integer);
var
  I: Integer;
  X: Integer;
  Inicio: Integer;
  Fim: Integer;
begin
  LimparBotoesPaginas;

  FPaginaAtual := APaginaAtual;
  FTotalPaginas := ATotalPaginas;

  X := 288;

  if ATotalPaginas > 0 then
  begin
    if ATotalPaginas <= 7 then
    begin
      for I := 0 to ATotalPaginas - 1 do
        AdicionarPagina(I, X);
    end
    else
    begin
      if APaginaAtual <= 2 then
      begin
        for I := 0 to 4 do
          AdicionarPagina(I, X);

        AdicionarReticencias(X);
        AdicionarPagina(ATotalPaginas - 1, X);
      end
      else if APaginaAtual >= ATotalPaginas - 3 then
      begin
        AdicionarPagina(0, X);
        AdicionarReticencias(X);

        for I := ATotalPaginas - 5 to ATotalPaginas - 1 do
          AdicionarPagina(I, X);
      end
      else
      begin
        AdicionarPagina(0, X);
        AdicionarReticencias(X);

        Inicio := APaginaAtual - 2;
        Fim := APaginaAtual + 2;

        for I := Inicio to Fim do
          AdicionarPagina(I, X);

        AdicionarReticencias(X);
        AdicionarPagina(ATotalPaginas - 1, X);
      end;
    end;
  end;

  Atualizar(APaginaAtual, ATotalPaginas, X);
end;

procedure TPaginacaoDBGrid.LimparCampoPagina;
begin
  FEdtIrParaPagina.Clear;
end;

end.
