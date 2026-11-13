program Lazarus_Paginacao;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uMain, uDM, uPaginacaoDBGrid, uPaginadorSQL, ufrmnomes, ufrmcidades,
  uModelBase, uNomesModel, uCidadesModel, uControllerBase, uNomesController,
  uCidadesController, uRealcePesquisaDBGrid, uBancoDados, uTiposPesquisa,
  uPesquisaEdit, uVisualizacaoCadastro, uTiposCadastro, uConfiguracaoApp;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
