unit uOrdenacaoDBGrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DBGrids;

type

  { TOrdenacaoDBGrid }

  TOrdenacaoDBGrid = class
  private
    FGrid: TDBGrid;

  public
    constructor Create(AGrid: TDBGrid);

    procedure Atualizar(const ACampoOrdenado: string;
      AOrdemAscendente: Boolean);
  end;

implementation

constructor TOrdenacaoDBGrid.Create(AGrid: TDBGrid);
begin
  inherited Create;

  if AGrid = nil then
    raise Exception.Create('A DBGrid não foi informada.');

  FGrid := AGrid;

  Atualizar('', True);
end;

procedure TOrdenacaoDBGrid.Atualizar(
  const ACampoOrdenado: string; AOrdemAscendente: Boolean);
var
  I: Integer;
  Titulo, Seta: string;
begin
  if FGrid = nil then
    Exit;

  if AOrdemAscendente then
    Seta := '↓ '
  else
    Seta := '↑ ';

  for I := 0 to FGrid.Columns.Count - 1 do
  begin
    Titulo := StringReplace(
      FGrid.Columns[I].FieldName, '_', ' ', [rfReplaceAll]);

    if SameText(FGrid.Columns[I].FieldName, ACampoOrdenado) then
      Titulo := Seta + Titulo;

    FGrid.Columns[I].Title.Caption := Titulo;
  end;
end;

end.
