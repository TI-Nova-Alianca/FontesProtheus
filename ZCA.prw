// Programa...: ZCA
// Autor......: Cláudia Lionço
// Data.......: 21/07/2023
// Descricao..: Responsaveis CRM X representantes
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #cadastro
// #Descricao         #Responsaveis CRM X representantes
// #PalavasChave      #CRM #CRM_Simples 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Totvs.ch"
#Include "FWMVCDef.ch"

//Variveis Estaticas
Static cTitulo    := "Clientes CRM Simples X Protheus"
Static cCamposChv := "ZCA_CODRES;ZCA_NOMRES;"
Static cTabPai    := "ZCA"

User Function ZCA()
	Local aArea   := FWGetArea()
	Local oBrowse
	Private aRotina := {}

	//Definicao do menu
	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cTabPai)
	oBrowse:SetDescription(cTitulo)
	oBrowse:DisableDetails()

	//Ativa a Browse
	oBrowse:Activate()

	FWRestArea(aArea)
Return Nil
//
// --------------------------------------------------------------------------
// Menu de opcoes na funcao ZCA
Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.ZCA" OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir" ACTION "VIEWDEF.ZCA" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.ZCA" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir" ACTION "VIEWDEF.ZCA" OPERATION 5 ACCESS 0

Return aRotina
//
// --------------------------------------------------------------------------
// Modelo de dados na funcao ZCA
Static Function ModelDef()
	Local oStruPai   := FWFormStruct(1, cTabPai, {|cCampo| Alltrim(cCampo) $ cCamposChv})
	Local oStruFilho := FWFormStruct(1, cTabPai)
	Local aRelation := {}
	Local oModel
	Local bPre := Nil
	Local bPos := Nil
	Local bCancel := Nil

	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("ZCAM", bPre, bPos, /*bCommit*/, bCancel)
	oModel:AddFields("ZCAMASTER", /*cOwner*/, oStruPai)
	oModel:AddGrid("ZCADETAIL","ZCAMASTER",oStruFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
	oModel:SetDescription("Modelo de dados - " + cTitulo)
	oModel:GetModel("ZCAMASTER"):SetDescription( "Dados de - " + cTitulo)
	oModel:GetModel("ZCADETAIL"):SetDescription( "Grid de - " + cTitulo)
	oModel:SetPrimaryKey({})

	//Fazendo o relacionamento
	aAdd(aRelation, {"ZCA_FILIAL", "FWxFilial('ZCA')"} )
	aAdd(aRelation, {"ZCA_CODRES", "ZCA_CODRES"})
	aAdd(aRelation, {"ZCA_NOMRES", "ZCA_NOMRES"})
	oModel:SetRelation("ZCADETAIL", aRelation, ZCA->(IndexKey(1)))
	
	//Definindo campos unicos da linha
	oModel:GetModel("ZCADETAIL"):SetUniqueLine({'ZCA_CODREP'})

Return oModel
//
// --------------------------------------------------------------------------
// Visualizacao de dados na funcao ZCA
Static Function ViewDef()
	Local oModel     := FWLoadModel("ZCA")
	Local oStruPai   := FWFormStruct(2, cTabPai, {|cCampo| Alltrim(cCampo) $ cCamposChv})
	Local oStruFilho := FWFormStruct(2, cTabPai, {|cCampo| ! Alltrim(cCampo) $ cCamposChv})
	Local oView

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZCA", oStruPai, "ZCAMASTER")
	oView:AddGrid("GRID_ZCA",  oStruFilho,  "ZCADETAIL")

	//Partes da tela
	oView:CreateHorizontalBox("CABEC", 30)
	oView:CreateHorizontalBox("GRID", 70)
	oView:SetOwnerView("VIEW_ZCA", "CABEC")
	oView:SetOwnerView("GRID_ZCA", "GRID")

	//Titulos
	oView:EnableTitleView("VIEW_ZCA", "Cabecalho - ZCA")
	oView:EnableTitleView("GRID_ZCA", "Grid - ZCA")

Return oView
