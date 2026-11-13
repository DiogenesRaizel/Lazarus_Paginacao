unit uRealcePesquisaDBGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, DB, DBGrids, Grids, StdCtrls,
  uModelBase;

type

  { TRealcePesquisaDBGrid }

  TRealcePesquisaDBGrid = class
  private
    FGrid: TDBGrid;
    FModel: TModelBase;
    FFiltro: TEdit;
    FEventoOriginal: TDrawColumnCellEvent;

    function CampoPesquisavel(const NomeCampo: string): Boolean;
    function CelulaCorresponde(const Valor: string): Boolean;
    procedure DesenharCelula(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DesenharTextoComRealce(const Texto: string; X, Y: Integer);
  public
    constructor Create(AGrid: TDBGrid; AModel: TModelBase; AFiltro: TEdit);
    destructor Destroy; override;
  end;

implementation

constructor TRealcePesquisaDBGrid.Create(AGrid: TDBGrid; AModel: TModelBase; AFiltro: TEdit);
begin
  inherited Create;

  if AGrid = nil then
    raise Exception.Create('A DBGrid não foi informada.');

  if AModel = nil then
    raise Exception.Create('O Model não foi informado.');

  if AFiltro = nil then
    raise Exception.Create('O campo de pesquisa não foi informado.');

  FGrid := AGrid;
  FModel := AModel;
  FFiltro := AFiltro;

  FEventoOriginal := FGrid.OnDrawColumnCell;
  FGrid.OnDrawColumnCell := @DesenharCelula;
end;

destructor TRealcePesquisaDBGrid.Destroy;
begin
  if FGrid <> nil then
    FGrid.OnDrawColumnCell := FEventoOriginal;

  inherited Destroy;
end;

function TRealcePesquisaDBGrid.CampoPesquisavel(const NomeCampo: string): Boolean;
var
  Campos: TCampoPesquisaArray;
  I: Integer;
begin
  Result := False;
  Campos := FModel.CamposPesquisa;

  for I := Low(Campos) to High(Campos) do
    if SameText(Campos[I].CampoGrid, NomeCampo) then
      Exit(True);
end;

function TRealcePesquisaDBGrid.CelulaCorresponde(const Valor: string): Boolean;
var
  Termos: TStringList;
  I: Integer;
  Termo: string;
begin
  Result := False;

  Termos := TStringList.Create;
  try
    Termos.StrictDelimiter := True;
    Termos.Delimiter := ',';
    Termos.DelimitedText := FFiltro.Text;

    for I := 0 to Termos.Count - 1 do
    begin
      Termo := Trim(Termos[I]);

      if (Termo <> '') and
         (Pos(AnsiUpperCase(Termo), AnsiUpperCase(Valor)) > 0) then
        Exit(True);
    end;
  finally
    Termos.Free;
  end;
end;

procedure TRealcePesquisaDBGrid.DesenharCelula(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  Texto: string;
  X, Y: Integer;
begin
  if Assigned(FEventoOriginal) then
    FEventoOriginal(Sender, Rect, DataCol, Column, State)
  else
    FGrid.DefaultDrawColumnCell(Rect, DataCol, Column, State);

  if (Column = nil) or (Column.Field = nil) then
    Exit;

  if not CampoPesquisavel(Column.Field.FieldName) then
    Exit;

  if Trim(FFiltro.Text) = '' then
    Exit;

  Texto := Column.Field.DisplayText;

  if not CelulaCorresponde(Texto) then
    Exit;

  FGrid.Canvas.Brush.Style := bsClear;
  FGrid.Canvas.Font := Column.Title.Font;

  if Column.Alignment = taRightJustify then
    X := Rect.Right - FGrid.Canvas.TextWidth(Texto) - 4
  else if Column.Alignment = taCenter then
    X := Rect.Left + (Rect.Width - FGrid.Canvas.TextWidth(Texto)) div 2
  else
    X := Rect.Left + 4;

  Y := Rect.Top + (Rect.Height - FGrid.Canvas.TextHeight(Texto)) div 2;

  DesenharTextoComRealce(Texto, X, Y);
end;

procedure TRealcePesquisaDBGrid.DesenharTextoComRealce(const Texto: string; X, Y: Integer);
var
  Termos: TStringList;
  Posicao, Inicio, MelhorPosicao, MelhorTamanho: Integer;
  Termo, Trecho: string;
  EstiloOriginal: TFontStyles;
  I: Integer;
begin
  Termos := TStringList.Create;
  try
    Termos.StrictDelimiter := True;
    Termos.Delimiter := ',';
    Termos.DelimitedText := FFiltro.Text;

    EstiloOriginal := FGrid.Canvas.Font.Style;
    Inicio := 1;

    while Inicio <= Length(Texto) do
    begin
      MelhorPosicao := 0;
      MelhorTamanho := 0;

      for I := 0 to Termos.Count - 1 do
      begin
        Termo := Trim(Termos[I]);

        if Termo = '' then
          Continue;

        Posicao := Pos(AnsiUpperCase(Termo), AnsiUpperCase(Copy(Texto, Inicio, MaxInt)));

        if (Posicao > 0) and
           ((MelhorPosicao = 0) or (Posicao < MelhorPosicao)) then
        begin
          MelhorPosicao := Posicao;
          MelhorTamanho := Length(Termo);
        end;
      end;

      if MelhorPosicao = 0 then
      begin
        FGrid.Canvas.Font.Style := EstiloOriginal;
        Trecho := Copy(Texto, Inicio, MaxInt);
        FGrid.Canvas.TextOut(X, Y, Trecho);
        Break;
      end;

      if MelhorPosicao > 1 then
      begin
        FGrid.Canvas.Font.Style := EstiloOriginal;
        Trecho := Copy(Texto, Inicio, MelhorPosicao - 1);
        FGrid.Canvas.TextOut(X, Y, Trecho);
        Inc(X, FGrid.Canvas.TextWidth(Trecho));
        Inc(Inicio, MelhorPosicao - 1);
      end;

      Trecho := Copy(Texto, Inicio, MelhorTamanho);
      FGrid.Canvas.Font.Style := EstiloOriginal + [fsBold, fsUnderline];
      FGrid.Canvas.TextOut(X, Y, Trecho);
      Inc(X, FGrid.Canvas.TextWidth(Trecho));
      Inc(Inicio, MelhorTamanho);
    end;
  finally
    FGrid.Canvas.Font.Style := EstiloOriginal;
    Termos.Free;
  end;
end;

end.
