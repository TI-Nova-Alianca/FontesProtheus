// Programa...: VA_GLTF2
// Autor......: Andre Alves	
// Data.......: 15/01/2019
// Descricao..: Atualiza campo F2_VAGUIA (Numero da Guia de Livre Transito) das Notas de saida
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Alteracao
// #Descricao         #Atualiza campo F2_VAGUIA (Numero da Guia de Livre Transito) das Notas de saida
// #PalavasChave      #guia_de_livre_transito #F2_VAGUIA
// #TabelasPrincipais #SF2 #SB1 #SD2
// #Modulos           #EST #ESP
//
// Historico de alteracoes:
// 23/01/2019 - Andre   - Ajustado para botão visualizar levar notas de saída.
// 19/09/2019 - Cláudia - Alterada tela para ler itens da nota e colunas conforme solicitação. GLPI: 6639
// 01/10/2019 - Cláudia - Alterado campo F2_VAGUIA de 6 para 11 caracteres e ajustada a tela correspondente. 
// 
// -------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function VA_GLTF2()  
	Local _aCores     := U_GLTF2LG (.T.)
	//Local cArqTRB     := ""
	Local aStruct     := {}
	Local aHead       := {}
	Local _aArqTrb    := {}
	Local I			  := 0
	Private aRotina   := {}
	private cCadastro := "Guia Livre Transito - NF Saida"
	private _sArqLog  := U_NomeLog ()
    
	_cPerg   := "VA_GLTF2"
	_ValidPerg()
    
    if Pergunte(_cPerg,.T.) 
	
		//Campos que aparecerão na MBrowse, como não é baseado no SX3 deve ser criado.
		AAdd( aHead, { "Emissao"         ,{|| TRB->EMISSAO}   ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Guia"            ,{|| TRB->GUIA}      ,"C", 11 , 0, "@# 999999/9999"  } )
		AAdd( aHead, { "Produto"         ,{|| TRB->PRODUTO}   ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Descricao"       ,{|| TRB->DESCRICAO} ,"C", 30 , 0, "" } )
		AAdd( aHead, { "Quantidade"      ,{|| TRB->QUANTIDADE},"N", 10 , 2, "@E 9999999.99" } )
		AAdd( aHead, { "Cliente"      	 ,{|| TRB->CLIENTE}   ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Loja"      		 ,{|| TRB->LOJA}      ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Nome"            ,{|| TRB->NOME}      ,"C", 30 , 0, "" } )
		AAdd( aHead, { "Numero"          ,{|| TRB->DOC}       ,"C", 09 , 0, "" } )
		AAdd( aHead, { "Serie"           ,{|| TRB->SERIE}     ,"C", 03 , 0, "" } )
		AAdd( aHead, { "Dt.Digitacao"    ,{|| TRB->DIGITACAO} ,"C", 10 , 0, "" } )
		
		// define estrutura do arquivo de trabalho	
		AAdd( aStruct, { "EMISSAO"    , "C", 10, 0 } )
		AAdd( aStruct, { "GUIA"       , "C", 11, 0 } )
		AAdd( aStruct, { "PRODUTO"    , "C", 06, 0 } )
		AAdd( aStruct, { "DESCRICAO"  , "C", 30, 0 } )
		AAdd( aStruct, { "QUANTIDADE" , "N", 10, 2 } )
		AAdd( aStruct, { "CLIENTE"    , "C", 06, 0 } )
		AAdd( aStruct, { "LOJA"       , "C", 02, 0 } )
		AAdd( aStruct, { "NOME"       , "C", 30, 0 } )
		AAdd( aStruct, { "DOC"        , "C", 09, 0 } )
		AAdd( aStruct, { "SERIE"      , "C", 03, 0 } )
		AAdd( aStruct, { "DIGITACAO"  , "C", 10, 0 } )
		U_ArqTrb ("Cria", "TRB", aStruct, {"DOC + SERIE + CLIENTE"}, @_aArqTrb)
						  
		// cria arquivo de trabalho
//		cArqTRB := CriaTrab( aStruct, .T. )
//		dbUseArea( .T., __LocalDriver, cArqTRB, "TRB", .F., .F. )
//		cInd1 := Left( cArqTRB, 1 ) + Left( cArqTRB, 2 ) + Left( cArqTRB, 3 ) + "1"
//		IndRegua( "TRB", cInd1, "DOC + SERIE + CLIENTE", , , "Criando índices...")
//		cInd2 :=  Left( cArqTRB, 3 ) + Left( cArqTRB, 1 ) + Left( cArqTRB, 2 ) + "2"
//		IndRegua( "TRB", cInd2, "CLIENTE + DOC + SERIE", , , "Criando índices...")
		
//		dbClearIndex()
//		dbSetIndex( cInd1 + OrdBagExt() )
//		//dbSetIndex( cInd2 + OrdBagExt() )

		// gera arquivo dados - carrega arquivo de trabalho
		_sSQL := " " 
		_sSQL += " SELECT DISTINCT"
		_sSQL += " 	dbo.VA_DTOC(SD2.D2_EMISSAO) AS DT_EMISSAO"
		_sSQL += "    ,SF2.F2_VAGUIA AS GUIA"
		_sSQL += "    ,SD2.D2_COD AS PRODUTO"
		_sSQL += "    ,SB1.B1_DESC AS DESCRICAO"
		_sSQL += "    ,SD2.D2_QUANT AS QUANTIDADE"
		_sSQL += "    ,SD2.D2_CLIENTE AS CLIENTE"
		_sSQL += "    ,SF2.F2_LOJA AS LOJA"
		_sSQL += "    ,IIF(SD2.D2_TIPO = 'N', SA1.A1_NOME, SA2.A2_NOME) AS NOME"
		_sSQL += "    ,SD2.D2_DOC AS NOTA"
		_sSQL += "    ,SD2.D2_SERIE AS SERIE"
		_sSQL += "    ,dbo.VA_DTOC(SD2.D2_DTDIGIT) AS DT_DIGIT"
		_sSQL += " FROM SD2010 AS SD2"
		_sSQL += " INNER JOIN SF2010 AS SF2"
		_sSQL += " 	ON (SF2.D_E_L_E_T_ = ''"
		_sSQL += " 			AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
		_sSQL += " 			AND SF2.F2_DOC     = SD2.D2_DOC"
		_sSQL += " 			AND SF2.F2_SERIE   = SD2.D2_SERIE"
		_sSQL += " 			AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
		_sSQL += " 			AND SF2.F2_LOJA    = SD2.D2_LOJA"
		_sSQL += " 			AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
		if mv_par02 == 2 // guia informada
			_sSQL += "     		AND SF2.F2_VAGUIA <> '' "
		endif
		if mv_par02 == 3 //não informada
			_sSQL += "     		AND SF2.F2_VAGUIA = '' "
		endif
		_sSQL += " INNER JOIN SB1010 AS SB1"
		_sSQL += " 	ON (SB1.D_E_L_E_T_ = ''"
		_sSQL += " 			AND SB1.B1_COD = SD2.D2_COD)"
		_sSQL += " INNER JOIN SB5010 AS SB5"
		_sSQL += " 	ON (SB5.D_E_L_E_T_ = ''"
		if mv_par01 == 2 // acucar e borra seca
			_sSQL += " 			AND SB5.B5_VATPSIS IN ('24', '40')"
		endif
		_sSQL += " 			AND SB5.B5_COD = SB1.B1_COD)"
		_sSQL += " LEFT JOIN SA2010 AS SA2"
		_sSQL += " 	ON (SA2.D_E_L_E_T_ = ''"
		_sSQL += " 			AND SA2.A2_COD = SF2.F2_CLIENTE"
		_sSQL += " 			AND SA2.A2_LOJA = SF2.F2_LOJA)"
		_sSQL += " LEFT JOIN SA1010 AS SA1"
		_sSQL += " 	ON (SA1.D_E_L_E_T_ = ''"
		_sSQL += " 			AND SA1.A1_COD = SF2.F2_CLIENTE"
		_sSQL += " 			AND SA1.A1_LOJA = SF2.F2_LOJA)"
		_sSQL += " WHERE SD2.D_E_L_E_T_ = ''"
		_sSQL += " AND SD2.D2_FILIAL = '" + xFilial ("SD2") + "'"
		_sSQL += " AND SD2.D2_EMISSAO > '" + dtos (date() - 90 ) + "'"
		_sSQL += " AND SD2.D2_QUANT > 0"
		if mv_par01 == 1 // granel
			_sSQL += "     AND SD2.D2_GRUPO = '3000'"
		else // acucar e borra seca
			_sSQL += "     AND SD2.D2_GRUPO IN ('4001', '0603')"
		endif	
		
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
		        	TRB-> CLIENTE     = aDados[I,6]
		        	TRB-> LOJA        = aDados[I,7]
		        	TRB-> NOME        = subst(aDados[I,8],1,30)
		        	TRB-> DOC         = aDados[I,9]
		        	TRB-> SERIE       = aDados[I,10]
		        	TRB-> DIGITACAO   = aDados[I,11]
		        MsUnLock()
			next
		endif
		
	    aRotina  := { { "Pesquisar"      , "AxPesqui"            , 0, 1},;
	    			  { "Visualizar"     , "U_VerNFSaida()"      , 0, 2},;
	                  { "Legenda"        , "U_GLTF2LG (.F.)"     , 0, 5},;
	                  { "Atualiz Guia"   , "U_AtuGuia2"          , 0, 4} }
	                  	                  //{ "Visualizar"     , "MC090Visual"         , 0, 2},
	
	    dbSelectArea("TRB")
		dbSetOrder(1)
	    	
		//mBrowse(,,,,"TRB",aHead,,,,,_aCores)
		mBrowse(6,1,22,75,"TRB",aHead,,,,2,_aCores)
			
		TRB->(dbCloseArea())   
		
		u_arqtrb ("FechaTodos",,,, @_aArqTrb)           
	endif	
Return   
//                
//-------------------------------------------------------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function GLTF2LG (_lRetCores)
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
//-------------------------------------------------------------------------------------------------------------------------
// Funcao que trata a atualizacao do campo da Guia de Livre Transito (GLT) nas notas de saida
User function AtuGuia2()       
    Local _sQuery := ""	                
    Local _lRet   := .T.
    
	_Nota    := TRB->DOC
	_Serie   := TRB->SERIE 
	_Cliente := TRB->CLIENTE
	_Loja    := TRB->LOJA
	_Guia    := TRB->GUIA 
	
	// Verifica se na nota informada tem algum produto do tipo granel para permitir informar a Guia
	_sQuery := ""	
	_sQuery += " SELECT count(D2_DOC)   "
	_sQuery += " FROM " + RetSQLName ("SD2") + " SD2,  "
	_sQuery +=          + RetSQLName ("SB1") + " SB1,  "
	_sQuery +=          + RetSQLName ("SB5") + " SB5  "
	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
	_sQuery += " AND SB1.D_E_L_E_T_ = ''"
	_sQuery += " AND SB5.D_E_L_E_T_ = ''"
	_sQuery += " AND D2_FILIAL  = '" + xFilial ("SD2") + "'"
	_sQuery += " AND B1_FILIAL  = '" + xFilial ("SB1") + "'"
	_sQuery += " AND B5_FILIAL  = '" + xFilial ("SB5") + "'"
	_sQuery += " AND D2_DOC  = '" + _Nota + "'"
	_sQuery += " AND D2_SERIE  = '" + _Serie + "'"
	_sQuery += " AND D2_CLIENTE  = '" + _Cliente + "'"
	_sQuery += " AND D2_LOJA  = '" + _Loja + "'"
	_sQuery += " AND D2_COD  = B1_COD "
	_sQuery += " AND B5_COD  = B1_COD "
	_sQuery += " AND (B1_GRPEMB  = '18' OR B5_VATPSIS IN ('24', '40'))"  // Borra ou acucar.
	u_log (_squery)  
	
	if U_RetSQL (_sQuery) > 0
        _sOldGuia = PADL(TRB -> GUIA,11)
		_sNewGuia = U_Get ("Guia de Transito", "C", 11, "@# 999999/9999", "", _sOldGuia, .F., '.T.')
		
		if _lRet
			DbSelectArea("SF2")                
			DbSetOrder(1)
			if SF2 -> (dbseek (xFilial("SF2") + _Nota + _Serie + _Cliente + _Loja))
					Reclock("SF2",.F.)
					SF2->F2_VAGUIA  := _sNewGuia
					Msunlock()
	        endif
			u_help("Guia da nota "+Alltrim(_Nota)+" serie " +Alltrim(_Serie) + " foi alterada para "+_sNewGuia)
	    endif
	else 
		u_help ("Esta nota nao tem produtos do tipo Granel / Açúcar. Não será permitido informar a Guia!")
	endif                                                                                     
return
//           
// --------------------------------------------------------------------------
// Consulta detalhes da movimentacao.
user function VerNFSaida ()
	// Variaveis para a rotina de visualizacao da nota.
	Private aRotina    := {{ , , 0 , 2 }}
	Private l103Auto   := .F.
	Private aAutoCab   := {}
	Private aAutoItens := {}

	sf2 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	if sf2 -> (dbseek (xfilial ("SF2") + TRB->DOC + TRB->SERIE + TRB->CLIENTE  + '01', .F.))
		Mc090Visual ("SF2", recno (), 1)
	else
		u_help ("NF '" + TRB->DOC + "' nao encontrada.")
	endif
return 
//       
//-------------------------------------------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Lista Notas        ?", "N", 1, 0,  "",   "   ", {"Granel","Acuçar/Borra"}, ""})
	aadd (_aRegsPerg, {02, "Guia               :", "N", 1, 0,  "",   "   ", {"Ambas","Informada","Não informada"}, ""})
	
	U_ValPerg (_cPerg, _aRegsPerg)
    
Return
