// Programa...: VA_GLTF1
// Autor......: Elaine Ballico	
// Data.......: 26/02/2013
// Descricao..: Atualiza campo F1_VAGUIA (Numero da Guia de Livre Transito) das Notas de Entrada
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Alteracao
// #Descricao         #Atualiza campo F1_VAGUIA (Numero da Guia de Livre Transito) das Notas de Entrada
// #PalavasChave      #guia_de_livre_transito #F1_VAGUIA
// #TabelasPrincipais #SF1 #SB1 #SD1
// #Modulos           #EST #ESP
//
// Historico de alteracoes:
// 11/07/2013 - Robert  - Passa a aceitar tambem acucar nas guias.
// 17/05/2016 - Robert  - Campos do Sisdeclara migrados da tabela SB1 para SB5.
// 15/03/2019 - Catia   - Passado a solicitar a densidade
// 15/03/2019 - Catia   - Feito filtro via MBROUSE so com as notas de granel ou acuçar/borra
// 22/03/2019 - Catia   - ajustes na opcao de visualizacao que estava dando ero 
// 19/09/2019 - Claudia - Incluido filtro e ajustada a ordem de colunas cforme solicitação do usuário. GLPI 6638
// 01/10/2019 - Cláudia - Alterado campo F1_VAGUIA de 6 para 11 caracteres e ajustada a tela correspondente.      
// 09/06/2020 - Robert  - Aumentados decimais gravacao F1_VADENS.
// 13/10/2020 - Claudia - Ajuste nas consultas para somarquantidade para mesmo produto e mesma nota. GLPI: 8640
// 20/11/2020 - Claudia - Retirado o botão filtro conforme GLPI: 8663
// 27/11/2020 - Sandra  - Incluso grupo de produtos 4000
// 19/02/2021 - Cláudia - Incluida validação para retorno vazio da guia e densidade. GLPI: 9445
//
// ----------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function VA_GLTF1()  
	Local _aCores     := U_GLTF1LG (.T.)
	Local aStruct     := {}
	Local aHead       := {}
	Local _aArqTrb    := {}
	Local I			  := 0
	Private aRotina   := {}
	private cCadastro := "Guia Livre Transito - NF Entradas"
	private _sArqLog  := U_NomeLog ()
    
	_cPerg   := "VA_GLTF1"
	_ValidPerg()
    
    if Pergunte(_cPerg,.T.) 
	
		//Campos que aparecerão na MBrowse, como não é baseado no SX3 deve ser criado.
		AAdd( aHead, { "Emissao"         ,{|| TRB->EMISSAO}   ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Guia"            ,{|| TRB->GUIA}      ,"C", 11 , 0, "@# 999999/9999" } )
		AAdd( aHead, { "Produto"         ,{|| TRB->PRODUTO}   ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Descricao"       ,{|| TRB->DESCRICAO} ,"C", 30 , 0, "" } )
		AAdd( aHead, { "Quantidade"      ,{|| TRB->QUANTIDADE},"N", 10 , 2, "@E 9999999.99" } )
		AAdd( aHead, { "Fornecedor"      ,{|| TRB->FORNECE}   ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Nome"            ,{|| TRB->NOME}      ,"C", 30 , 0, "" } )
		AAdd( aHead, { "Numero"          ,{|| TRB->DOC}       ,"C", 09 , 0, "" } )
		AAdd( aHead, { "Serie"           ,{|| TRB->SERIE}     ,"C", 03 , 0, "" } )
		AAdd( aHead, { "Dt.Digitacao"    ,{|| TRB->DIGITACAO} ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Densidade"       ,{|| TRB->DENSIDADE} ,"N", 05 , 3, "@E 9.999" } )
		
		// define estrutura do arquivo de trabalho	
		AAdd( aStruct, { "EMISSAO"    , "C", 10, 0 } )
		AAdd( aStruct, { "GUIA"       , "C", 11, 0 } )
		AAdd( aStruct, { "PRODUTO"    , "C", 06, 0 } )
		AAdd( aStruct, { "DESCRICAO"  , "C", 30, 0 } )
		AAdd( aStruct, { "QUANTIDADE" , "N", 10, 2 } )
		AAdd( aStruct, { "FORNECE"    , "C", 06, 0 } )
		AAdd( aStruct, { "NOME"       , "C", 30, 0 } )
		AAdd( aStruct, { "DOC"        , "C", 09, 0 } )
		AAdd( aStruct, { "SERIE"      , "C", 03, 0 } )
		AAdd( aStruct, { "DIGITACAO"  , "C", 10, 0 } )
		AAdd( aStruct, { "DENSIDADE"  , "N", 05, 3 } )
		
		U_ArqTrb ("Cria", "TRB", aStruct, {"DOC + SERIE + FORNECE"}, @_aArqTrb)					  

		// gera arquivo dados - carrega arquivo de trabalho
		_sSQL := "" 
		_sSQL += " SELECT "
		_sSQL += " 		 dbo.VA_DTOC(SD1.D1_EMISSAO) AS DT_EMISSAO"
		_sSQL += "		,SF1.F1_VAGUIA AS GUIA"
		_sSQL += "		,SD1.D1_COD AS PRODUTO"
		_sSQL += "		,SB1.B1_DESC AS DESCRICAO"
		_sSQL += "		,SUM(SD1.D1_QUANT) AS QUANTIDADE"
		_sSQL += "		,SD1.D1_FORNECE AS FORNECEDOR"
		_sSQL += "		,IIF(SD1.D1_TIPO = 'N', SA2.A2_NOME, SA1.A1_NOME) AS NOME"
		_sSQL += "		,SD1.D1_DOC AS NOTA"
		_sSQL += "		,SD1.D1_SERIE AS SERIE"
		_sSQL += "		,dbo.VA_DTOC(SD1.D1_DTDIGIT) AS DT_DIGIT"	
		_sSQL += " 		,SF1.F1_VADENS AS DENSIDADE"
	    _sSQL += "   FROM " + RetSqlName( "SD1" ) + " SD1 "
		_sSQL += "		INNER JOIN " + RetSqlName( "SF1" ) + " SF1 "
		_sSQL += "			ON (SF1.D_E_L_E_T_     = ''"
		_sSQL += "				AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
		_sSQL += "				AND SF1.F1_DOC     = SD1.D1_DOC"
		_sSQL += "				AND SF1.F1_SERIE   = SD1.D1_SERIE"
		_sSQL += "				AND SF1.F1_FORNECE = SD1.D1_FORNECE"
		_sSQL += "				AND SF1.F1_LOJA    = SD1.D1_LOJA"
		_sSQL += "				AND SF1.F1_EMISSAO = SD1.D1_EMISSAO "
		if mv_par02 == 2 // guia informada
			_sSQL += "     		AND SF1.F1_VAGUIA <> '' "
	    endif
	    if mv_par02 == 3 //não informada
	    	_sSQL += "     		AND SF1.F1_VAGUIA = '' "
	    endif
		_sSQL += " )"
		_sSQL += "		INNER JOIN " + RetSqlName( "SB1" ) + " SB1 "
		_sSQL += "			ON (SB1.D_E_L_E_T_ = ''"
		_sSQL += "				AND SB1.B1_COD = SD1.D1_COD)"
		_sSQL += "		INNER JOIN " + RetSqlName( "SB5" ) + " SB5 "
		_sSQL += "			ON (SB5.D_E_L_E_T_ = ''"
		_sSQL += "          AND SB5.B5_VASISDE = 'S'" 
		if mv_par01 == 2 // acucar e borra seca
			_sSQL += "           AND SB5.B5_VATPSIS IN ('24','40') " 
		endif
		_sSQL += "				AND SB5.B5_COD = SB1.B1_COD)"
		_sSQL += "		LEFT JOIN SA2010 AS SA2"
		_sSQL += "			ON (SA2.D_E_L_E_T_  = ''"
		_sSQL += "				AND SA2.A2_COD  = SF1.F1_FORNECE"
		_sSQL += "				AND SA2.A2_LOJA = SF1.F1_LOJA)"
		_sSQL += "		LEFT JOIN SA1010 AS SA1"
		_sSQL += "			ON (SA1.D_E_L_E_T_  = ''"
		_sSQL += "				AND SA1.A1_COD  = SF1.F1_FORNECE"
		_sSQL += "				AND SA1.A1_LOJA = SF1.F1_LOJA)"
		_sSQL += "   WHERE SD1.D_E_L_E_T_ = ''"
	    _sSQL += "	   AND SD1.D1_FILIAL  = '" + xFilial ("SD1") + "'"
	    _sSQL += "	   AND SD1.D1_DTDIGIT > '" + dtos (date() - 90 ) + "'"
	    _sSQL += "	   AND SD1.D1_QUANT   > 0"
	    if mv_par01 == 1 // granel
	    	_sSQL += "     AND SD1.D1_GRUPO IN  ('3000','4000')" 
	    else // acucar e borra seca
	    	_sSQL += "     AND SD1.D1_GRUPO IN ('4001','0603')"
	    endif	
		_sSQL += " GROUP BY SD1.D1_EMISSAO"
		_sSQL += " ,SF1.F1_VAGUIA"
		_sSQL += " ,SD1.D1_COD"
		_sSQL += " ,SB1.B1_DESC"
		_sSQL += " ,SD1.D1_FORNECE"
		_sSQL += " ,SD1.D1_TIPO"
		_sSQL += " ,SA2.A2_NOME"
		_sSQL += " ,SA1.A1_NOME"
		_sSQL += " ,SD1.D1_DOC"
		_sSQL += " ,SD1.D1_SERIE"
		_sSQL += " ,SD1.D1_DTDIGIT"
		_sSQL += " ,SF1.F1_VADENS"

		u_log (_sSQL)  
		aDados := U_Qry2Array(_sSQL)
	
		if len (aDados) > 0
			for I=1 to len(aDados)
				DbSelectArea("TRB")
		        RecLock("TRB",.T.)
		        	TRB-> EMISSAO     = aDados[I,1]
		        	TRB-> GUIA        = aDados[I,2]
		        	TRB-> PRODUTO     = substr(aDados[I,3],1,30)
		        	TRB-> DESCRICAO   = aDados[I,4]
		        	TRB-> QUANTIDADE  = aDados[I,5]
		        	TRB-> FORNECE     = aDados[I,6]
		        	TRB-> NOME        = subst(aDados[I,7],1,30)
		        	TRB-> DOC         = aDados[I,8]
		        	TRB-> SERIE       = aDados[I,9]
		        	TRB-> DIGITACAO   = aDados[I,10]
		        	TRB-> DENSIDADE   = aDados[I,11]
		        MsUnLock()
			next
		endif
		
	    aRotina  :=  {  { "Pesquisar"      , "AxPesqui"            , 0, 1},;
	    				{ "Visualizar"     , "U_VerNF()"           , 0, 2},;
	    				{ "Legenda"        , "U_GLTF1LG (.F.)"     , 0, 5},;
	    				{ "Atualiz Guia"   , "U_AtuGuia"           , 0, 4} }
	    					    				   		
	    dbSelectArea("TRB")
		dbSetOrder(1)
	    	
		mBrowse(6,1,22,75,"TRB",aHead,,,,2,_aCores,,,,,.T.)

		TRB->(dbCloseArea())    
		
		u_arqtrb ("FechaTodos",,,, @_aArqTrb)            
	endif	
Return   
//    
// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function GLTF1LG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i	   := 0
	
	aadd (_aCores, {"!empty(TRB -> GUIA)", 'BR_VERMELHO', 'Guia Informada'})
	aadd (_aCores, {"empty(TRB -> GUIA)",  'BR_VERDE',    'Guia nao Informada'})
	
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return
//    
// --------------------------------------------------------------------------
// Funcao que trata a atualizacao do campo da Guia de Livre Transito (GLT) 
// nas notas de entrada
User function AtuGuia()
    local _lRet := .T.
    if _lRet
		_sOldGuia = PADL(TRB -> GUIA,11)
		_sOldDens = TRB -> DENSIDADE
		
		_sNewGuia = U_Get ("Guia de Transito", "C", 11, "@# 999999/9999", "", _sOldGuia, .F., '.T.')
		_sNewDens = U_Get ("Densidade" , "N", 6, '@E 9.9999', "", _sOldDens, .F., '.T.')
		
		If empty(_sNewGuia)
			_sNewGuia := ""
		EndIf

		If empty(_sNewDens)
			_sNewDens := 0
		EndIf

		if _lRet
			DbSelectArea("SF1")                
			DbSetOrder(1)
			if SF1 -> (dbseek (xFilial("SF1") + TRB->DOC + TRB->SERIE + TRB->FORNECE ))
				Reclock("SF1",.F.)
					SF1->F1_VAGUIA  := _sNewGuia
					SF1->F1_VADENS  := _sNewDens
				Msunlock()
				// atualiza arquivo de trabalho
				Reclock("TRB",.F.)
					TRB-> GUIA      := _sNewGuia
					TRB-> DENSIDADE := _sNewDens
				Msunlock()
			endif
	    endif
	endif   	
return
//
// --------------------------------------------------------------------------
// Consulta detalhes da movimentacao.
user function VerNF ()
	// Variaveis para a rotina de visualizacao da nota.
	Private aRotina    := {{ , , 0 , 2 }}
	Private l103Auto   := .F.
	Private aAutoCab   := {}
	Private aAutoItens := {}

	sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	if sf1 -> (dbseek (xfilial ("SF1") + TRB->DOC + TRB->SERIE + TRB->FORNECE  + '01', .F.))
		A103NFiscal ('SF1', recno (), 1)
	else
		u_help ("NF '" + TRB->DOC + "' nao encontrada.")
	endif
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Lista Notas        ?", "N", 1, 0,  "",   "   ", {"Granel/concentrado","Acuçar/Borra"}, ""})
	aadd (_aRegsPerg, {02, "Guia               :", "N", 1, 0,  "",   "   ", {"Ambas","Informada","Não informada"}, ""})
	
	U_ValPerg (_cPerg, _aRegsPerg)  
Return
