//Bibliotecas
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
   
//Vari�veis Est�ticas
Static cTitulo := "Produtos de Verbas"
   

User Function ZC2()
    Local aArea   := GetArea()
    Local oBrowse
	Private aRotina := {}

	//Definicao do menu
	aRotina := MenuDef()
       
    //Cria um browse para a ZC2
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("ZC2")
    oBrowse:SetDescription(cTitulo)
    oBrowse:Activate()
       
    RestArea(aArea)
Return Nil
  
Static Function MenuDef()
    Local aRot := {}
       
    //Adicionando op��es
    ADD OPTION aRot TITLE "Visualizar" 			ACTION "VIEWDEF.ZC2" OPERATION 1 ACCESS 0
	ADD OPTION aRot TITLE "Incluir" 				ACTION "VIEWDEF.ZC2" OPERATION 3 ACCESS 0
	ADD OPTION aRot TITLE "Alterar"				ACTION "VIEWDEF.ZC2" OPERATION 4 ACCESS 0
	ADD OPTION aRot TITLE "Excluir" 				ACTION "VIEWDEF.ZC2" OPERATION 5 ACCESS 0
Return aRot
  
Static Function ModelDef()
    //Na montagem da estrutura do Modelo de dados, o cabe�alho filtrar� e exibir� somente 3 campos, j� a grid ir� carregar a estrutura inteira conforme fun��o fModStruct
    Local oModel      := NIL
    Local oStruCab    := FWFormStruct(1, 'ZC2', {|cCampo| AllTRim(cCampo) $ "ZC2_PROD;ZC2_PERC;"})
    Local oStruGrid := fModStruct()
  
    //Monta o modelo de dados, e na P�s Valida��o, informa a fun��o fValidGrid
    //oModel := MPFormModel():New('ZC2', /*bPreValidacao*/, {|oModel| fValidGrid(oModel)}, /*bCommit*/, /*bCancel*/ )
	oModel := MPFormModel():New('ZC2', /*bPreValidacao*/, /*{|oModel| fValidGrid(oModel)}*/, /*bCommit*/, /*bCancel*/ )
  
    //Agora, define no modelo de dados, que ter� um Cabe�alho e uma Grid apontando para estruturas acima
    oModel:AddFields('MdFieldZC2', NIL, oStruCab)
    oModel:AddGrid('MdGridZC2', 'MdFieldZC2', oStruGrid, , )
  
    //Monta o relacionamento entre Grid e Cabe�alho, as express�es da Esquerda representam o campo da Grid e da direita do Cabe�alho
    oModel:SetRelation('MdGridZC2', {;
            {'ZC2_FILIAL', 'xFilial("ZC2")'},;
            {"ZC2_VERBA",  "ZC2_VERBA"},;
            {"ZC2_CLIENT", "ZC2_CLIENT"},;
            {"ZC2_LOJA",  "ZC2_LOJA"};
        }, ZC2->(IndexKey(1)))
      
    //Definindo outras informa��es do Modelo e da Grid
    oModel:GetModel("MdGridZC2"):SetMaxLine(9999)
    oModel:SetDescription("Atualiza��o")
    oModel:SetPrimaryKey({"ZC2_FILIAL", "ZC2_VERBA", "ZC2_CLIENT","ZC2_LOJA"})
  
Return oModel
  
Static Function ViewDef()
    //Na montagem da estrutura da visualiza��o de dados, vamos chamar o modelo criado anteriormente, no cabe�alho vamos mostrar somente 3 campos, e na grid vamos carregar conforme a fun��o fViewStruct
    Local oView        := NIL
    Local oModel    := FWLoadModel('ZC2')
    Local oStruCab  := FWFormStruct(2, "ZC2", {|cCampo| AllTRim(cCampo) $ "ZC2_PROD;ZC2_PERC;"})
    Local oStruGRID := fViewStruct()
  
    //Define que no cabe�alho n�o ter� separa��o de abas (SXA)
    oStruCab:SetNoFolder()
  
    //Cria o View
    oView:= FWFormView():New() 
    oView:SetModel(oModel)              
  
    //Cria uma �rea de Field vinculando a estrutura do cabe�alho com MDFieldZAF, e uma Grid vinculando com MdGridZAF
    oView:AddField('VIEW_ZC2', oStruCab, 'MdFieldZC2')
    oView:AddGrid ('GRID_ZC2', oStruGRID, 'MdGridZC2' )
  
    //O cabe�alho (MAIN) ter� 25% de tamanho, e o restante de 75% ir� para a GRID
    oView:CreateHorizontalBox("MAIN", 25)
    oView:CreateHorizontalBox("GRID", 75)
  
    //Vincula o MAIN com a VIEW_ZAF e a GRID com a GRID_ZAF
    oView:SetOwnerView('VIEW_ZC2', 'MAIN')
    oView:SetOwnerView('GRID_ZC2', 'GRID')
    oView:EnableControlBar(.T.)
  
    //Define o campo incremental da grid como o ZAF_ITEM
    //oView:AddIncrementField('GRID_ZC2', '')
Return oView
  
//Fun��o chamada para montar o modelo de dados da Grid
Static Function fModStruct()
    Local oStruct
    oStruct := FWFormStruct(1, 'ZC2')
Return oStruct
  
//Fun��o chamada para montar a visualiza��o de dados da Grid
Static Function fViewStruct()
    Local cCampoCom := "ZC2_PROD;ZC2_PERC;"
    Local oStruct
  
    //Ir� filtrar, e trazer todos os campos, menos os que tiverem na vari�vel cCampoCom
    oStruct := FWFormStruct(2, "ZC2", {|cCampo| !(Alltrim(cCampo) $ cCampoCom)})
Return oStruct
  
// //Fun��o que faz a valida��o da grid
// Static Function fValidGrid(oModel)
//     Local lRet     := .T.
//     Local nDeletados := 0
//     Local nLinAtual :=0
//     Local oModelGRID := oModel:GetModel('MdGridZC2')
//     Local oModelMain := oModel:GetModel('MdFieldZC2')
//     Local nValorMain := oModelMain:GetValue("ZC2_VALOR")
//     Local nValorGrid := 0
//     Local cPictVlr   := PesqPict('ZC2', 'ZC2_VALOR')
  
//     //Percorrendo todos os itens da grid
//     For nLinAtual := 1 To oModelGRID:Length() 
//         //Posiciona na linha
//         oModelGRID:GoLine(nLinAtual) 
          
//         //Se a linha for excluida, incrementa a vari�vel de deletados, sen�o ir� incrementar o valor digitado em um campo na grid
//         If oModelGRID:IsDeleted()
//             nDeletados++
//         Else
//             nValorGrid += NoRound(oModelGRID:GetValue("ZAF_TCOMB"), 4)
//         EndIf
//     Next nLinAtual
  
//     //Se o tamanho da Grid for igual ao n�mero de itens deletados, acusa uma falha
//     If oModelGRID:Length()==nDeletados
//         lRet :=.F.
//         Help( , , 'Dados Inv�lidos' , , 'A grid precisa ter pelo menos 1 linha sem ser excluida!', 1, 0, , , , , , {"Inclua uma linha v�lida!"})
//     EndIf
  
//     If lRet
//         //Se o valor digitado no cabe�alho (valor da NF), n�o bater com o valor de todos os abastecimentos digitados (valor dos itens da Grid), ir� mostrar uma mensagem alertando, por�m ir� permitir salvar (do contr�rio, seria necess�rio alterar lRet para falso)
//         If nValorMain != nValorGrid
//             //lRet := .F.
//             MsgAlert("O valor do cabe�alho (" + Alltrim(Transform(nValorMain, cPictVlr)) + ") tem que ser igual o valor dos itens (" + Alltrim(Transform(nValorGrid, cPictVlr)) + ")!", "Aten��o")
//         EndIf
//     EndIf
  
// Return lRet
