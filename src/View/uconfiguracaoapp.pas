unit uConfiguracaoApp;

{$mode ObjFPC}{$H+}

interface

function ArquivoConfiguracao: string;

procedure SalvarLarguraColuna(
  const NomeFormulario, NomeCampo: string;
  Largura: Integer
);

function CarregarLarguraColuna(
  const NomeFormulario, NomeCampo: string;
  LarguraPadrao: Integer
): Integer;

procedure SalvarTamanhoPrincipal(const Largura, Altura: Integer);
procedure CarregarTamanhoPrincipal(out Largura, Altura: Integer);

implementation

uses
  SysUtils,
  IniFiles,
  LazFileUtils;

function ArquivoConfiguracao: string;
begin
  Result := IncludeTrailingPathDelimiter(
    GetAppConfigDirUTF8(False, True)
  ) + 'Lazarus_Paginacao.ini';
end;

procedure SalvarLarguraColuna(
  const NomeFormulario, NomeCampo: string;
  Largura: Integer
);
var
  Config: TIniFile;
begin
  Config := TIniFile.Create(ArquivoConfiguracao);
  try
    Config.WriteInteger(
      NomeFormulario + '.Grid',
      NomeCampo,
      Largura
    );
  finally
    Config.Free;
  end;
end;

function CarregarLarguraColuna(
  const NomeFormulario, NomeCampo: string;
  LarguraPadrao: Integer
): Integer;
var
  Config: TIniFile;
begin
  Config := TIniFile.Create(ArquivoConfiguracao);
  try
    Result := Config.ReadInteger(
      NomeFormulario + '.Grid',
      NomeCampo,
      LarguraPadrao
    );
  finally
    Config.Free;
  end;
end;

procedure SalvarTamanhoPrincipal(const Largura, Altura: Integer);
var
  Config: TIniFile;
begin
  Config := TIniFile.Create(ArquivoConfiguracao);
  try
    Config.WriteInteger('Principal', 'Largura', Largura);
    Config.WriteInteger('Principal', 'Altura', Altura);
  finally
    Config.Free;
  end;
end;

procedure CarregarTamanhoPrincipal(out Largura, Altura: Integer);
var
  Config: TIniFile;
begin
  Config := TIniFile.Create(ArquivoConfiguracao);
  try
    Largura := Config.ReadInteger('Principal', 'Largura', 800);
    Altura := Config.ReadInteger('Principal', 'Altura', 600);
  finally
    Config.Free;
  end;
end;

end.
