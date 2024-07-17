// Programa...: VA_RAPCAD
// Autor......: Cláudia Lionço
// Data.......: 22/08/2023
// Descricao..: Tela de manutenção de contratos e valores de rapel
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de manutenção de contratos e valores de rapel
// #PalavasChave      #rapel #contratos_de_rapel 
// #TabelasPrincipais #ZA7 #ZAX
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 12/09/2023 - Claudia - Incluida a ligação de cabeçalho e itens pelo código matriz. GLPI: 14186
// 14/09/2023 - Claudia - Alterada validações de codigo matriz para codigo cliente. GLPI: 14215
// 17/07/2024 - Claudia - Validação de rapel. GLPI: 15375
//
// ------------------------------------------------------------------------------------------------
#Include "Totvs.ch"
#Include "FWMVCDef.ch"

//Variveis Estaticas
Static cTitulo := "Rapel - Contratos e valores"
Static cTabPai := "ZA7"
Static cTabFilho := "ZAX"

User Function VA_RAPCAD()
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
// ------------------------------------------------------------------------------------------------
// Menu de opcoes na funcao VA_RAP
Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar" 			ACTION "VIEWDEF.VA_RAPCAD" OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir" 				ACTION "VIEWDEF.VA_RAPCAD" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar" 				ACTION "VIEWDEF.VA_RAPCAD" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir" 				ACTION "VIEWDEF.VA_RAPCAD" OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Composição contrato"  ACTION "U_VA_RAPCTR()"  OPERATION 6 ACCESS 0 

Return aRotina
//
// ------------------------------------------------------------------------------------------------
// Modelo de dados na funcao VA_RAP
Static Function ModelDef()
	Local oStruPai := FWFormStruct(1, cTabPai)
	Local oStruFilho := FWFormStruct(1, cTabFilho)
	Local aRelation := {}
	Local oModel
	Local bPre := Nil
	Local bPos := Nil
	Local bCancel := Nil

    bPre := {|oModel| _VldPre()}

    bPos := {|oModel| _VldPos()}

	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("VA_RAPM", bPre, bPos, /*bCommit*/, bCancel)
	oModel:AddFields("ZA7MASTER", /*cOwner*/, oStruPai)
	oModel:AddGrid("ZAXDETAIL","ZA7MASTER",oStruFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
	oModel:SetDescription("Modelo de dados - " + cTitulo)
	oModel:GetModel("ZA7MASTER"):SetDescription( "Dados de - " + cTitulo)
	oModel:GetModel("ZAXDETAIL"):SetDescription( "Grid de - " + cTitulo)
	oModel:SetPrimaryKey({})

	//Fazendo o relacionamento
	aAdd(aRelation, {"ZAX_FILIAL", "FWxFilial('ZAX')"} )
	// aAdd(aRelation, {"ZAX_CLIENT", "ZA7_CLI   "})
	// aAdd(aRelation, {"ZAX_LOJA", "ZA7_LOJA"})
	aAdd(aRelation, {"ZAX_CODMAT", "ZA7_CLI   "})
	aAdd(aRelation, {"ZAX_LOJMAT", "ZA7_LOJA"})
	oModel:SetRelation("ZAXDETAIL", aRelation, ZAX->(IndexKey(1)))

Return oModel
//
// ------------------------------------------------------------------------------------------------
// Visualizacao de dados na funcao VA_RAP
Static Function ViewDef()
	Local oModel := FWLoadModel("VA_RAPCAD")
	Local oStruPai := FWFormStruct(2, cTabPai)
	Local oStruFilho := FWFormStruct(2, cTabFilho)
	Local oView

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZA7", oStruPai, "ZA7MASTER")
	oView:AddGrid("VIEW_ZAX",  oStruFilho,  "ZAXDETAIL")

	//Partes da tela
	oView:CreateHorizontalBox("CABEC", 30)
	oView:CreateHorizontalBox("GRID", 70)
	oView:SetOwnerView("VIEW_ZA7", "CABEC")
	oView:SetOwnerView("VIEW_ZAX", "GRID")

	//Titulos
	oView:EnableTitleView("VIEW_ZA7", "Cabecalho - ZA7")
	oView:EnableTitleView("VIEW_ZAX", "Grid - ZAX")

	//Removendo campos
	//oStruFilho:RemoveField("ZAX_CLIENT")
	//oStruFilho:RemoveField("ZAX_LOJA")

Return oView
//
// ------------------------------------------------------------------------------------------------
// Validação antes de abrir a tela de manutenção
Static Function _VldPre()

Return .T.
//
// ------------------------------------------------------------------------------------------------
// Validação tudo ok
Static Function _VldPos()
	Local _oSQL  := ClsSQL ():New ()
	Local nLinha := 0
	Local _lRet  := .T.

	oModelPad  := FWModelActive()
	oModelCab  := oModelPad:GetModel('ZA7MASTER')
    oModelGrid := oModelPad:GetModel('ZAXDETAIL')

	_sCliMat  :=  oModelCab:GetValue("ZA7_CLI")
	_sLojaMat :=  oModelCab:GetValue("ZA7_LOJA")
	_sCliente :=  oModelGrid:GetValue("ZAX_CLIENT")
	_sLoja    :=  oModelGrid:GetValue("ZAX_LOJA")
	_sCont    :=  oModelCab:GetValue("ZA7_CONT")
	_sSeq     :=  oModelCab:GetValue("ZA7_SEQ")
	_dDtBase  :=  oModelCab:GetValue("ZA7_DBASE")
	_dDtVini  :=  oModelCab:GetValue("ZA7_VINI")
	_dDtVfim  :=  oModelCab:GetValue("ZA7_VFIM")
	_dDtPini  :=  oModelCab:GetValue("ZA7_PINI")
	_dDtPfim  :=  oModelCab:GetValue("ZA7_PFIM")
	_sVigencia:=  oModelCab:GetValue("ZA7_VIGENT")

	_sOper := oModelCab:GetOperation()

	// ***********************************************************************************************
	// Validações de cabeçalho

	if fbuscacpo("SA1", 1, xfilial ("SA1") + _sCliente + _sLoja,  "A1_VERBA") != '1'
		u_help("Cliente não controla verbas. Inclusao não permitida.")    
		_lRet = .F. 
	endif

	// // Vailida se Cliente tem Rapel
	// if fBuscaCpo("SA1", 1, xfilial ("SA1") + _sCliente + _sLoja, "A1_VABARAP") = "0"
	// 	u_help("Não tem Rapel no Cadastro de Cliente!")
	// 	_lRet = .F.
	// endif
	
	// verifica cliente bloqueado
	if fBuscaCpo("SA1", 1, xfilial ("SA1") + _sCliente + _sLoja, "A1_MSBLQL") != "2"
		u_help("Cliente Bloqueado")
		_lRet = .F.
	endif
    
    if _sOper == 3 .and. DbSeek(xFilial("ZA7") + _sLojaMat + _sLojaMat + _sCont + _sSeq, .F.)
       u_help ("Sequência ja informada para este contrato.")    
       _lRet = .F. 
    endif
    
    if dtos(_dDtBase) > dtos(_dDtVini) 
         u_help ("Data base não deve ser maior que data inicial da vigência.")    
         _lRet = .F.
    endif
    
    if dtos(_dDtVini) > dtos(_dDtVfim) 
         u_help ("Data final da vigência não deve ser maior que a data inicial da vigência.")    
         _lRet = .F.
    endif
    
    if dtos(_dDtPini) > dtos(_dDtVfim) 
         u_help ("Data inicial do perido de apuracao deve ser menor que a data final da vigência do contrato.")    
         _lRet = .F.
    endif
    
    if dtos(_dDtPini) > dtos(_dDtPfim) 
         u_help ("Data final do periodo de apuração não deve ser maior que a data final do periodo de apuração..")    
         _lRet = .F.
    endif
    
    // valida se ja existe validade vigente para o cliente
    if _sOper == 3 .and. _sVigencia == '1'
        // buscando contrato conforme cliente e vigencia informada
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT(*) AS JA_TEM "
        _oSQL:_sQuery += " FROM " + RetSQLName ("ZA7") + " ZA7 "
        _oSQL:_sQuery += " WHERE ZA7.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND ZA7_CLI    = '" + _sCliMat  + "' "
        _oSQL:_sQuery += " AND ZA7_LOJA   = '" + _sLojaMat + "' "
        _oSQL:_sQuery += " AND ZA7_VIGENT = '1'"
		_aDados := aclone(_oSQL:Qry2Array ())

        if _aDados[1,1] > 0
            u_help("Já existe Contrato vigente para este cliente.")    
            _lRet = .F.    
        endif
    endif

	// ***********************************************************************************************
	// Validações de grid

	DbSelectArea("ZAX")
	ZAX->(DbSetOrder(3)) // ZAX_FILIAL+ZAX_CLIENT+ZAX_LOJA+ZAX_LINHA+ZAX_ITEM                                                                                                               

	For nLinha := 1 To oModelGrid:Length()
		//Posicionando na linha atual
		oModelGrid:GoLine(nLinha)
			
		_sItem  := oModelGrid:GetValue("ZAX_ITEM") 
		_sLinha := oModelGrid:GetValue("ZAX_LINHA") 

		If oModelGRID:IsDeleted() 		//Se a linha tiver deletada, grava log
			_oEvento := ClsEvent():new ()
			_oEvento:Texto     =  'Excluindo registro.' + 'Chave:' +_sCliente + _sLoja + _sLinha + _sItem
			_oEvento:Cliente   = _sCliente
			_oEvento:LojaCli   = _sLoja
			_oEvento:CodEven   = "ZAX001"
			_oEvento:Chave     = _sCliente + _sLoja + _sLinha + _sItem
			_oEvento:Grava()
		
		ElseIf oModelGRID:IsInserted() 	// Se for inserção

			if ZAX -> (dbseek(xfilial("ZAX") + _sCliente + _sLoja + _sLinha + _sItem, .F.))
				u_help ("Já existe registro de rapel para este cliente/linha e/ou item. Verifique! ")
				_lRet = .F.
			endif
			
			if _lRet
				_oEvento := ClsEvent():new ()
				_oEvento:Texto     =  'Incluindo registro.' + 'Chave:' +_sCliente + _sLoja + _sLinha + _sItem
				_oEvento:Cliente   = _sCliente
				_oEvento:LojaCli   = _sLoja
				_oEvento:CodEven   = "ZAX001"
				_oEvento:Chave     = _sCliente + _sLoja + _sLinha + _sItem
				_oEvento:Grava()
			endif

		ElseIf oModelGRID:IsUpdated() 	// Se for alteração
			_oEvento := ClsEvent():new ()
			_oEvento:Texto     =  'Alterando registro.' + 'Chave:' +_sCliente + _sLoja + _sLinha + _sItem
			_oEvento:Cliente   = _sCliente
			_oEvento:LojaCli   = _sLoja
			_oEvento:CodEven   = "ZAX001"
			_oEvento:Chave     = _sCliente + _sLoja + _sLinha + _sItem
			_oEvento:Grava()
		EndIf
	Next
Return _lRet
