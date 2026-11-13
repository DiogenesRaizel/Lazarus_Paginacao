unit uVisualizacaoCadastro;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, ExtCtrls, ComCtrls, Controls,
  uTiposCadastro;

type

  { TVisualizacaoCadastro }

  TVisualizacaoCadastro = class
  private
    FFormulario: TCustomForm;
    FPageControl: TPageControl;
    FPaginaTabela: TTabSheet;
    FPaginaCadastro: TTabSheet;
    FPainelTopoTabela: TPanel;
    FPainelTopoCadastro: TPanel;
    FPainelBotoesTabela: TPanel;
    FPainelBotoesCadastro: TPanel;
    FModoApresentacao: TModoApresentacao;

  public
    constructor Create(AFormulario: TCustomForm;
      APageControl: TPageControl;
      APaginaTabela, APaginaCadastro: TTabSheet;
      APainelTopoTabela, APainelTopoCadastro: TPanel;
      APainelBotoesTabela, APainelBotoesCadastro: TPanel);

    procedure Configurar(AModoCadastro: TModoCadastro);

    property ModoApresentacao: TModoApresentacao read FModoApresentacao;
  end;

implementation

constructor TVisualizacaoCadastro.Create(AFormulario: TCustomForm;
  APageControl: TPageControl;
  APaginaTabela, APaginaCadastro: TTabSheet;
  APainelTopoTabela, APainelTopoCadastro: TPanel;
  APainelBotoesTabela, APainelBotoesCadastro: TPanel);
begin
  inherited Create;

  FFormulario := AFormulario;
  FPageControl := APageControl;
  FPaginaTabela := APaginaTabela;
  FPaginaCadastro := APaginaCadastro;
  FPainelTopoTabela := APainelTopoTabela;
  FPainelTopoCadastro := APainelTopoCadastro;
  FPainelBotoesTabela := APainelBotoesTabela;
  FPainelBotoesCadastro := APainelBotoesCadastro;

  if FPageControl.ActivePage = FPaginaCadastro then
    FModoApresentacao := maCadastro
  else
    FModoApresentacao := maTabela;
end;

procedure TVisualizacaoCadastro.Configurar(AModoCadastro: TModoCadastro);
begin
  FPageControl.BorderSpacing.Top := 0;

  case AModoCadastro of
    mcInclusaoTabela, mcEdicaoTabela,
    mcInclusaoCadastro, mcEdicaoCadastro:
      begin
        FPainelTopoTabela.Visible := False;
        FPainelTopoCadastro.Visible := False;
        FPainelBotoesTabela.Visible := False;
        FPainelBotoesCadastro.Visible := True;

        FPageControl.BorderSpacing.Top := 11;
        FPageControl.ActivePage := FPaginaCadastro;
      end;

    mcNavegandoTabela:
      begin
        FPainelTopoTabela.Visible := True;
        FPainelTopoCadastro.Visible := False;
        FPainelBotoesCadastro.Visible := False;
        FPainelBotoesTabela.Visible := True;

        FPageControl.ActivePage := FPaginaTabela;
      end;

    mcNavegandoCadastro:
      begin
        FPainelTopoTabela.Visible := False;
        FPainelTopoCadastro.Visible := True;
        FPainelBotoesCadastro.Visible := False;
        FPainelBotoesTabela.Visible := True;

        FPageControl.ActivePage := FPaginaCadastro;
        FPageControl.Align := alNone;
        FPageControl.Align := alClient;
      end;
  end;

  if AModoCadastro = mcNavegandoTabela then
    FModoApresentacao := maTabela
  else
    FModoApresentacao := maCadastro;

  FFormulario.Repaint;
end;

end.

