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

procedure TRealcePesquisaDBGrid.DesenharCelula(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  Texto: string;
  X, Y: Integer;
begin
  if (Column.Field = nil) or not CampoPesquisavel(Column.Field.FieldName) or
     not CelulaCorresponde(Column.Field.DisplayText) then
  begin
    if Assigned(FEventoOriginal) then
      FEventoOriginal(Sender, Rect, DataCol, Column, State)
    else
      FGrid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
    Exit;
  end;

  Texto := Column.Field.DisplayText;

  FGrid.Canvas.FillRect(Rect);

  Y := Rect.Top + ((Rect.Bottom - Rect.Top) -
    FGrid.Canvas.TextHeight('Ag')) div 2;

  X := Rect.Left + 4;

  DesenharTextoComRealce(Texto, X, Y);
end;

procedure TRealcePesquisaDBGrid.DesenharTextoComRealce(const Texto: string; X, Y: Integer);
var
  Termos: TStringList;
  Termo, Restante, Antes, Coincidente: string;
  Posicao, I: Integer;
  EstiloOriginal: TFontStyles;
begin
  EstiloOriginal := FGrid.Canvas.Font.Style;
  Termos := TStringList.Create;
  try
    Termos.Delimiter := ',';
    Termos.StrictDelimiter := True;
    Termos.DelimitedText := FFiltro.Text;

    for I := Termos.Count - 1 downto 0 do
    begin
      Termos[I] := Trim(Termos[I]);

      if Termos[I] = '' then
        Termos.Delete(I);
    end;

    EstiloOriginal := FGrid.Canvas.Font.Style;
    Restante := Texto;

    while Restante <> '' do
    begin
      Posicao := 0;
      Termo := '';

      for I := 0 to Termos.Count - 1 do
      begin
        if Pos(AnsiUpperCase(Termos[I]), AnsiUpperCase(Restante)) > 0 then
        begin
          if (Posicao = 0) or
             (Pos(AnsiUpperCase(Termos[I]), AnsiUpperCase(Restante)) < Posicao) then
          begin
            Posicao := Pos(AnsiUpperCase(Termos[I]), AnsiUpperCase(Restante));
            Termo := Termos[I];
          end;
        end;
      end;

      if Posicao = 0 then
      begin
        FGrid.Canvas.Font.Style := EstiloOriginal;
        FGrid.Canvas.TextOut(X, Y, Restante);
        Break;
      end;

      Antes := Copy(Restante, 1, Posicao - 1);

      FGrid.Canvas.Font.Style := EstiloOriginal;
      FGrid.Canvas.TextOut(X, Y, Antes);
      Inc(X, FGrid.Canvas.TextWidth(Antes));

      Coincidente := Copy(Restante, Posicao, Length(Termo));

      FGrid.Canvas.Font.Style := EstiloOriginal + [fsBold, fsUnderline];
      FGrid.Canvas.TextOut(X, Y, Coincidente);
      Inc(X, FGrid.Canvas.TextWidth(Coincidente));

      Restante := Copy(Restante, Posicao + Length(Termo), MaxInt);
    end;
  finally
    FGrid.Canvas.Font.Style := EstiloOriginal;
    Termos.Free;
  end;
end;

end.
