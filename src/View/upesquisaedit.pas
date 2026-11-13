unit uPesquisaEdit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, StdCtrls, LCLType, Types, Math,
  uTiposPesquisa;

type
  TConsultarSugestoesEvent = function(const Valor: string): TSugestaoPesquisaArray of object;
  TAlteracaoTextoEvent = procedure(Sender: TObject) of object;

  { TPesquisaEdit }

  TPesquisaEdit = class
  private
    FEdit: TEdit;
    FLista: TListBox;
    FConsultarSugestoes: TConsultarSugestoesEvent;
    FOnAlteracaoTexto: TAlteracaoTextoEvent;
    FSugestoes: TSugestaoPesquisaArray;
    FSelecionando: Boolean;
    FSelecionadoID: Integer;
    FTextoSelecionado: string;

    procedure EditChange(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditExit(Sender: TObject);
    procedure ListaClick(Sender: TObject);
    procedure ListaDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure SelecionarItem;

  public
    constructor Create(AEdit: TEdit; ALista: TListBox;
      AConsultarSugestoes: TConsultarSugestoesEvent);

    procedure LimparSelecao;
    procedure DefinirSelecao(AID: Integer; const ATexto: string);

    property SelecionadoID: Integer read FSelecionadoID;
    property TextoSelecionado: string read FTextoSelecionado;
    property OnAlteracaoTexto: TAlteracaoTextoEvent
      read FOnAlteracaoTexto write FOnAlteracaoTexto;
  end;

implementation

constructor TPesquisaEdit.Create(AEdit: TEdit; ALista: TListBox;
  AConsultarSugestoes: TConsultarSugestoesEvent);
begin
  inherited Create;

  if AEdit = nil then
    raise Exception.Create('O campo de pesquisa não foi informado.');

  if ALista = nil then
    raise Exception.Create('A lista de sugestões não foi informada.');

  if not Assigned(AConsultarSugestoes) then
    raise Exception.Create('A função de consulta não foi informada.');

  FEdit := AEdit;
  FLista := ALista;
  FConsultarSugestoes := AConsultarSugestoes;

  FSelecionadoID := 0;
  FTextoSelecionado := '';
  FSelecionando := False;
  FOnAlteracaoTexto := nil;
  FSugestoes := nil;

  FLista.Visible := False;
  FLista.ItemHeight := 20;
  FLista.Style := lbOwnerDrawFixed;

  FEdit.OnChange := @EditChange;
  FEdit.OnKeyDown := @EditKeyDown;
  FEdit.OnExit := @EditExit;

  FLista.OnClick := @ListaClick;
  FLista.OnDrawItem := @ListaDrawItem;
end;

procedure TPesquisaEdit.LimparSelecao;
begin
  FSelecionadoID := 0;
  FTextoSelecionado := '';
end;

procedure TPesquisaEdit.DefinirSelecao(AID: Integer; const ATexto: string);
begin
  FSelecionando := True;
  try
    FSelecionadoID := AID;
    FTextoSelecionado := ATexto;
    FEdit.Text := ATexto;
    FEdit.SelStart := Length(FEdit.Text);
    FEdit.SelLength := 0;
    FLista.Visible := False;
  finally
    FSelecionando := False;
  end;
end;

procedure TPesquisaEdit.EditChange(Sender: TObject);
var
  I: Integer;
begin
  if FSelecionando then
    Exit;

  if Assigned(FOnAlteracaoTexto) then
    FOnAlteracaoTexto(Sender);

  LimparSelecao;

  FLista.Visible := False;
  FLista.Items.Clear;
  SetLength(FSugestoes, 0);

  if Trim(FEdit.Text) = '' then
    Exit;

  FSugestoes := FConsultarSugestoes(FEdit.Text);

  for I := 0 to High(FSugestoes) do
    FLista.Items.Add(FSugestoes[I].Texto);

  FLista.Visible := FLista.Count > 0;

  if FLista.Visible then
  begin
    FLista.ItemIndex := 0;

    FLista.Left := FEdit.Left;
    FLista.Top := FEdit.Top + FEdit.Height;
    FLista.Width := FEdit.Width;
    FLista.Height := FLista.ItemHeight * Min(FLista.Count, 5) + 8;
  end;
end;

procedure TPesquisaEdit.EditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Indice: Integer;
begin
  if (Key = Ord('L')) and (ssCtrl in Shift) then
  begin
    FEdit.Clear;
    LimparSelecao;
    Key := 0;
    Exit;
  end;

  if not FLista.Visible then
  begin
    if (Key = VK_DOWN) and (Trim(FEdit.Text) <> '') then
      EditChange(Sender);

    if Key = VK_DOWN then
      Key := 0;

    Exit;
  end;

  case Key of
    VK_DOWN:
      begin
        Indice := FLista.ItemIndex + 1;

        if Indice >= FLista.Count then
          Indice := 0;

        FLista.ItemIndex := Indice;
        Key := 0;
      end;

    VK_UP:
      begin
        Indice := FLista.ItemIndex - 1;

        if Indice < 0 then
          Indice := FLista.Count - 1;

        FLista.ItemIndex := Indice;
        Key := 0;
      end;

    VK_RETURN:
      begin
        if FLista.ItemIndex >= 0 then
        begin
          SelecionarItem;
          Key := 0;
        end;
      end;

    VK_ESCAPE:
      begin
        FLista.Visible := False;
        Key := 0;
      end;
  end;
end;

procedure TPesquisaEdit.EditExit(Sender: TObject);
begin
  FLista.Visible := False;
end;

procedure TPesquisaEdit.ListaClick(Sender: TObject);
begin
  SelecionarItem;
end;

procedure TPesquisaEdit.SelecionarItem;
var
  Indice: Integer;
begin
  Indice := FLista.ItemIndex;

  if (Indice < 0) or (Indice > High(FSugestoes)) then
    Exit;

  FSelecionando := True;
  try
    FSelecionadoID := FSugestoes[Indice].ID;
    FTextoSelecionado := FSugestoes[Indice].Texto;

    FEdit.Text := FTextoSelecionado;
    FEdit.SelStart := Length(FEdit.Text);
    FEdit.SelLength := 0;

    FLista.Visible := False;
  finally
    FSelecionando := False;
  end;
end;

procedure TPesquisaEdit.ListaDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  Texto, Busca: string;
  Posicao, X, Y: Integer;
  TextoAntes, TextoEncontrado, TextoDepois: string;
  CorTexto: TColor;
  EstiloOriginal: TFontStyles;
begin
  if Index < 0 then
    Exit;

  Texto := FLista.Items[Index];
  Busca := Trim(FEdit.Text);

  with FLista.Canvas do
  begin
    if odSelected in State then
    begin
      Brush.Color := clHighlight;
      CorTexto := clHighlightText;
    end
    else
    begin
      Brush.Color := FLista.Color;
      CorTexto := FLista.Font.Color;
    end;

    FillRect(ARect);

    Font.Assign(FLista.Font);
    Font.Color := CorTexto;

    EstiloOriginal := Font.Style;

    Y := ARect.Top + (ARect.Bottom - ARect.Top - TextHeight(Texto)) div 2;
    X := ARect.Left + 4;

    Posicao := 0;

    if Busca <> '' then
      Posicao := Pos(AnsiLowerCase(Busca), AnsiLowerCase(Texto));

    if Posicao = 0 then
    begin
      TextOut(X, Y, Texto);
      Exit;
    end;

    TextoAntes := Copy(Texto, 1, Posicao - 1);
    TextoEncontrado := Copy(Texto, Posicao, Length(Busca));
    TextoDepois := Copy(Texto, Posicao + Length(Busca), Length(Texto));

    TextOut(X, Y, TextoAntes);
    Inc(X, TextWidth(TextoAntes));

    Font.Style := EstiloOriginal + [fsBold, fsUnderline];
    TextOut(X, Y, TextoEncontrado);
    Inc(X, TextWidth(TextoEncontrado));

    Font.Style := EstiloOriginal;
    TextOut(X, Y, TextoDepois);
  end;
end;

end.
