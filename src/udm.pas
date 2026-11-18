unit uDM;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB,
  uBancoDados, uNomesModel, uCidadesModel;

type
  { TDM }

  TDM = class(TDataModule)
    SQLite3Connection1: TSQLite3Connection;
    qryExec: TSQLQuery;
    qryCidades: TSQLQuery;
    qryNomes: TSQLQuery;
    SQLQuery1: TSQLQuery;
    SQLQuery1ID: TLongintField;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
  public
    NomesModel: TNomesModel;
    CidadesModel: TCidadesModel;
    destructor Destroy; override;
  end;

var
  DM: TDM;

implementation

{$R *.lfm}

procedure TDM.DataModuleCreate(Sender: TObject);
var
  PastaDados: string;
begin
  PastaDados := ExpandFileName(ExtractFilePath(ParamStr(0)) + '../dados/');

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

  PrepararBanco(SQLite3Connection1, SQLTransaction1);

  NomesModel := TNomesModel.Create(SQLite3Connection1, SQLTransaction1);
  CidadesModel := TCidadesModel.Create(SQLite3Connection1, SQLTransaction1);
end;

destructor TDM.Destroy;
begin
  FreeAndNil(CidadesModel);
  FreeAndNil(NomesModel);
  inherited Destroy;
end;

end.
