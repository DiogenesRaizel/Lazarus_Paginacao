unit uDM;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB;

type

  { TDM }

  TDM = class(TDataModule)
    SQLite3Connection1: TSQLite3Connection;
    qryExec: TSQLQuery;
    qryNomes: TSQLQuery;
    qryCidades: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);

  private

    procedure PopularTabelaNomes;
    procedure PopularTabelaCidades;

  public
  end;

var
  DM: TDM;

implementation

{$R *.lfm}

{ TDM }

procedure TDM.DataModuleCreate(Sender: TObject);
var
  PastaDados: string;
begin
  PastaDados := ExpandFileName(
    ExtractFilePath(ParamStr(0)) + '../dados/'
  );

  if not ForceDirectories(PastaDados) then
    raise Exception.Create('Não foi possível criar o diretório de dados.');

  SQLite3Connection1.DatabaseName := PastaDados + 'dados.db';
  SQLite3Connection1.Transaction := SQLTransaction1;

  if not SQLite3Connection1.Connected then
    SQLite3Connection1.Open;

  qryExec.DataBase := SQLite3Connection1;
  qryExec.Transaction := SQLTransaction1;

  qryNomes.DataBase := SQLite3Connection1;
  qryNomes.Transaction := SQLTransaction1;

  qryCidades.DataBase := SQLite3Connection1;
  qryCidades.Transaction := SQLTransaction1;

  try
    qryExec.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS nomes (' +
      'ID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'Nome VARCHAR(60) NOT NULL' +
      ')';

    qryExec.ExecSQL;

    qryExec.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS cidades (' +
      'ID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'Cidade VARCHAR(100) NOT NULL, ' +
      'UF CHAR(2) NOT NULL' +
      ')';

    qryExec.ExecSQL;

    SQLTransaction1.Commit;
  except
    if SQLTransaction1.Active then
      SQLTransaction1.Rollback;
    raise;
  end;

  qryExec.Close;

  PopularTabelaNomes;
  PopularTabelaCidades;
end;

procedure TDM.PopularTabelaNomes;
const
  NOMES: array[0..99] of string = (
    'Ana Silva',
    'Bruno Santos',
    'Carla Oliveira',
    'Daniel Souza',
    'Eduarda Costa',
    'Felipe Pereira',
    'Gabriela Rodrigues',
    'Henrique Almeida',
    'Isabela Lima',
    'João Carvalho',
    'Karen Ferreira',
    'Lucas Gomes',
    'Mariana Ribeiro',
    'Nicolas Martins',
    'Olivia Barbosa',
    'Pedro Rocha',
    'Quitéria Dias',
    'Rafael Monteiro',
    'Sabrina Cardoso',
    'Thiago Teixeira',
    'Ursula Correia',
    'Vinícius Mendes',
    'Wagner Nunes',
    'Xavier Moreira',
    'Yasmin Fernandes',
    'Zeca Castro',
    'Amanda Azevedo',
    'Bernardo Machado',
    'Camila Freitas',
    'Diego Batista',
    'Elisa Campos',
    'Fábio Pinto',
    'Giovana Moraes',
    'Heitor Ramos',
    'Ingrid Vieira',
    'Júlio Nascimento',
    'Larissa Cunha',
    'Marcelo Peixoto',
    'Natália Tavares',
    'Otávio Correia',
    'Patrícia Andrade',
    'Renato Lopes',
    'Simone Farias',
    'Túlio Rezende',
    'Valéria Borges',
    'William Duarte',
    'Adriana Pires',
    'Caio Xavier',
    'Débora Mendes',
    'Eduardo Neves',
    'Alice Martins',
    'André Carvalho',
    'Beatriz Fernandes',
    'Caetano Ribeiro',
    'Daniela Moreira',
    'Enzo Barbosa',
    'Fernanda Castro',
    'Gustavo Nunes',
    'Helena Rocha',
    'Igor Teixeira',
    'Jéssica Almeida',
    'Kevin Souza',
    'Letícia Pereira',
    'Mateus Costa',
    'Nicole Santos',
    'Oscar Oliveira',
    'Priscila Lima',
    'Rogério Dias',
    'Samuel Ferreira',
    'Tatiane Gomes',
    'Vitor Azevedo',
    'Andressa Campos',
    'Breno Machado',
    'Cecília Freitas',
    'Davi Monteiro',
    'Estela Cardoso',
    'Fernando Vieira',
    'Geovana Cunha',
    'Hugo Peixoto',
    'Irene Tavares',
    'Jonas Andrade',
    'Kelly Lopes',
    'Leonardo Farias',
    'Mônica Rezende',
    'Nelson Borges',
    'Paula Pires',
    'Ricardo Xavier',
    'Sofia Neves',
    'Tomás Batista',
    'Vanessa Mendes',
    'Alexandre Ramos',
    'Bianca Nascimento',
    'Cristiano Duarte',
    'Débora Martins',
    'Emanuel Carvalho',
    'Flávia Fernandes',
    'Guilherme Ribeiro',
    'Lívia Moreira',
    'Murilo Barbosa',
    'Raquel Castro'
  );
var
  I: Integer;
begin
  qryExec.Close;
  qryExec.SQL.Text := 'SELECT COUNT(*) AS Total FROM nomes';
  qryExec.Open;

  try
    if qryExec.FieldByName('Total').AsInteger > 0 then
      Exit;
  finally
    qryExec.Close;
  end;

  try
    if SQLTransaction1.Active then
      SQLTransaction1.Commit;

    SQLTransaction1.StartTransaction;

    qryExec.SQL.Text := 'INSERT INTO nomes (Nome) VALUES (:Nome)';
    qryExec.Prepare;

    for I := Low(NOMES) to High(NOMES) do
    begin
      qryExec.ParamByName('Nome').AsString := NOMES[I];
      qryExec.ExecSQL;
    end;

    SQLTransaction1.Commit;
  except
    if SQLTransaction1.Active then
      SQLTransaction1.Rollback;
    raise;
  end;
end;

procedure TDM.PopularTabelaCidades;
const
  CIDADES: array[0..49, 0..1] of string = (
    ('Rio Branco', 'AC'),
    ('Cruzeiro do Sul', 'AC'),
    ('Manaus', 'AM'),
    ('Parintins', 'AM'),
    ('Macapá', 'AP'),
    ('Santana', 'AP'),
    ('Belém', 'PA'),
    ('Santarém', 'PA'),
    ('Porto Velho', 'RO'),
    ('Ji-Paraná', 'RO'),
    ('Boa Vista', 'RR'),
    ('Palmas', 'TO'),
    ('Araguaína', 'TO'),
    ('Salvador', 'BA'),
    ('Feira de Santana', 'BA'),
    ('Fortaleza', 'CE'),
    ('Juazeiro do Norte', 'CE'),
    ('São Luís', 'MA'),
    ('Imperatriz', 'MA'),
    ('João Pessoa', 'PB'),
    ('Campina Grande', 'PB'),
    ('Recife', 'PE'),
    ('Caruaru', 'PE'),
    ('Teresina', 'PI'),
    ('Natal', 'RN'),
    ('Mossoró', 'RN'),
    ('Aracaju', 'SE'),
    ('Maceió', 'AL'),
    ('Brasília', 'DF'),
    ('Goiânia', 'GO'),
    ('Anápolis', 'GO'),
    ('Cuiabá', 'MT'),
    ('Campo Grande', 'MS'),
    ('Belo Horizonte', 'MG'),
    ('Uberlândia', 'MG'),
    ('Juiz de Fora', 'MG'),
    ('Vitória', 'ES'),
    ('Vila Velha', 'ES'),
    ('Rio de Janeiro', 'RJ'),
    ('Petrópolis', 'RJ'),
    ('São Paulo', 'SP'),
    ('Campinas', 'SP'),
    ('Santos', 'SP'),
    ('Curitiba', 'PR'),
    ('Londrina', 'PR'),
    ('Maringá', 'PR'),
    ('Florianópolis', 'SC'),
    ('Blumenau', 'SC'),
    ('Porto Alegre', 'RS'),
    ('Caxias do Sul', 'RS')
  );
var
  I: Integer;
begin
  qryExec.Close;
  qryExec.SQL.Text := 'SELECT COUNT(*) AS Total FROM cidades';
  qryExec.Open;

  try
    if qryExec.FieldByName('Total').AsInteger > 0 then
      Exit;
  finally
    qryExec.Close;
  end;

  try
    if SQLTransaction1.Active then
      SQLTransaction1.Commit;

    SQLTransaction1.StartTransaction;

    qryExec.SQL.Text :=
      'INSERT INTO cidades (Cidade, UF) VALUES (:Cidade, :UF)';

    qryExec.Prepare;

    for I := Low(CIDADES) to High(CIDADES) do
    begin
      qryExec.ParamByName('Cidade').AsString := CIDADES[I, 0];
      qryExec.ParamByName('UF').AsString := CIDADES[I, 1];
      qryExec.ExecSQL;
    end;

    SQLTransaction1.Commit;
  except
    if SQLTransaction1.Active then
      SQLTransaction1.Rollback;
    raise;
  end;
end;

end.
