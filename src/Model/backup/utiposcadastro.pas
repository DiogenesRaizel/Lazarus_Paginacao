unit uTiposCadastro;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Controls, DBGrids, ExtCtrls,
  uControllerBase, uNomesModel, uCidadesModel, uTiposPesquisa,
  uTiposCadastro;

type
  TModoCadastro = (
    mcNavegandoTabela,
    mcNavegandoCadastro,
    mcInclusaoTabela,
    mcEdicaoTabela,
    mcInclusaoCadastro,
    mcEdicaoCadastro
  );

  TModoApresentacao = (maTabela, maCadastro);

implementation

end.
