// Programa...: VA_BPCOB
// Autor......: Catia Cardoso
// Data.......: 05/10/2015
// Descricao..: Altera Bancos Preferencias de Cobrança por Cliente
//
// Historico de alteracoes:
// 06/10/2015 - Catia   - Incluido maior saldo e media de atraso - para facilitar a analise
// 10/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Arquivo de trabalho
// 22/03/2021 - Robert  - Eliminada redefinicao da variavel _sArqLog.
//

#include "rwmake.ch"

// -----------------------------------------------------------------------------------------------------
User Function VA_BPCOB()
	
	//local _aCores  := ""
	//Local cArqTRB  := ""
	//Local cInd1    := ""
	//Local nI       := 0
	Local aStruct  := {}
	Local aHead    := {}
	Local I		   := 0
	
	cPerg   := "VA_PBCOB"
	
	if ! u_zzuvl ('036', __cUserId, .T.)
		return
	endif
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 

		//Campos que aparecerão na MBrowse, como não é baseado no SX3 deve ser criado.
		AAdd( aHead, { "Cliente"         ,{|| TRB->CODIGO}  ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Loja"            ,{|| TRB->LOJA}    ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Nome_Cli"        ,{|| TRB->NOME}    ,"C", 30 , 0, "" } )
		AAdd( aHead, { "Bloqueado"       ,{|| TRB->BLOQ}    ,"C", 04 , 0, "" } )
		AAdd( aHead, { "Municipio"       ,{|| TRB->MUNIC}   ,"C", 25 , 0, "" } )
		AAdd( aHead, { "Estado   "       ,{|| TRB->EST}     ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Risco"           ,{|| TRB->RISCO}   ,"C", 01 , 0, "" } )
		AAdd( aHead, { "MED Atraso"      ,{|| TRB->METR}    ,"N", 03 , 0, "" } )
		AAdd( aHead, { "Maior Saldo"     ,{|| TRB->MSALDO}  ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Banco 1"         ,{|| TRB->BCO1}    ,"C", 03 , 0, "" } )
		AAdd( aHead, { "Banco 2"         ,{|| TRB->BCO2}    ,"C", 03 , 0, "" } )
		AAdd( aHead, { "Banco 3"         ,{|| TRB->BCO3}    ,"C", 03 , 0, "" } )
		AAdd( aHead, { "Banco 4"         ,{|| TRB->BCO4}    ,"C", 03 , 0, "" } )
		AAdd( aHead, { "Banco 5"         ,{|| TRB->BCO5}    ,"C", 03 , 0, "" } )
		

		// define estrutura do arquivo de trabalho	
		AAdd( aStruct, { "CODIGO"  , "C", 06, 0 } )
		AAdd( aStruct, { "LOJA"    , "C", 02, 0 } )
		AAdd( aStruct, { "NOME"    , "C", 30, 0 } )
		AAdd( aStruct, { "BLOQ"    , "C", 04, 0 } )
		AAdd( aStruct, { "MUNIC"   , "C", 25, 0 } )
		AAdd( aStruct, { "EST"     , "C", 02, 0 } )
		AAdd( aStruct, { "RISCO"   , "C", 01, 0 } )
		AAdd( aStruct, { "METR"    , "N", 04, 0 } )
		AAdd( aStruct, { "MSALDO"  , "N", 12, 2 } )
		AAdd( aStruct, { "BCO1"    , "C", 03, 0 } )
		AAdd( aStruct, { "BCO2"    , "C", 03, 0 } )
		AAdd( aStruct, { "BCO3"    , "C", 03, 0 } )
		AAdd( aStruct, { "BCO4"    , "C", 03, 0 } )
		AAdd( aStruct, { "BCO5"    , "C", 03, 0 } )
		

//		// cria arquivo de trabalho
//		cArqTRB := CriaTrab( aStruct, .T. )
//		dbUseArea( .T., __LocalDriver, cArqTRB, "TRB", .F., .F. )
//		cInd1 := Left( cArqTRB, 7 ) + "1"
//		IndRegua( "TRB", cInd1, "CODIGO + LOJA", , , "Criando índices...")
//		cInd2 := Left( cArqTRB, 7 ) + "2"
//		IndRegua( "TRB", cInd2, "NOME", , , "Criando índices...")
//		
//		dbClearIndex()
//		dbSetIndex( cInd1 + OrdBagExt() )
//		dbSetIndex( cInd2 + OrdBagExt() )

		// cria arquivo de trabalho
		_aArqTrb  := {}
		U_ArqTrb ("Cria", "TRB", aStruct, {"CODIGO + LOJA","NOME"}, @_aArqTrb)
	
		// gera arquivo dados - carrega arquivo de trabalho
		_sSQL := "" 
		_sSQL += " SELECT A1_COD"						// --- 1
		_sSQL += "      , A1_LOJA"						// --- 2
		_sSQL += "      , A1_NOME"						// --- 3
		_sSQL += " 	    , CASE WHEN A1_MSBLQL='1'  THEN 'Sim'"
		_sSQL += " 	           WHEN A1_MSBLQL='2'  THEN 'Nao' END" // --- 4
		_sSQL += " 	    , A1_MUN"						// --- 5
	 	_sSQL += " 	    , A1_EST"						// --- 6
	 	_sSQL += "      , A1_RISCO"						// --- 9
	 	_sSQL += "      , A1_METR"						// --- 7
		_sSQL += "      , ROUND(A1_MSALDO,2)"			// --- 8
		_sSQL += " 	    , A1_BCO1"						// --- 10
	 	_sSQL += " 	    , A1_BCO2"						// --- 11
	 	_sSQL += " 	    , A1_BCO3"						// --- 12
	 	_sSQL += " 	    , A1_BCO4"						// --- 13
	 	_sSQL += " 	    , A1_BCO5"						// --- 14
	 	_sSQL += "   FROM " + RetSqlname ("SA1") + " AS SA1 "
		_sSQL += "  WHERE D_E_L_E_T_ = ''"
		_sSQL += "    AND A1_COD != '000000'" // desprezar cliente de consumidor final
		_sSQL += "	  AND A1_COD  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sSQL += "	  AND A1_EST  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sSQL += "	  AND A1_BCO1 BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
		_sSQL += "	  AND A1_CGC NOT LIKE '%88612486%'" // desprezar as transferencias
		if mv_par03 == 2
			_sSQL += "    AND A1_MSBLQL = '2'"
		endif
		if mv_par04 != 4
			if mv_par04 = 1
				_sSQL += "    AND A1_RISCO = 'A'"
			elseif mv_par04 = 2				
				_sSQL += "    AND A1_RISCO = 'D'"
			elseif mv_par04 = 3
				_sSQL += "    AND A1_RISCO = 'E'"
			endif				
		endif
		
		//u_showmemo (_sSQL)
		
		aDados := U_Qry2Array(_sSQL)

		if len (aDados) > 0
			for I=1 to len(aDados)
				DbSelectArea("TRB")
		        RecLock("TRB",.T.)
		        	TRB->CODIGO = aDados[I,1]
		        	TRB->LOJA   = aDados[I,2]
		        	TRB->NOME   = aDados[I,3]
		        	TRB->BLOQ   = aDados[I,4]
					TRB->MUNIC  = aDados[I,5]
					TRB->EST    = aDados[I,6]
					TRB->RISCO  = aDados[I,7]
					TRB->METR   = aDados[I,8]
		        	TRB->MSALDO = aDados[I,9]
		        	TRB->BCO1   = aDados[I,10]
					TRB->BCO2   = aDados[I,11]
					TRB->BCO3   = aDados[I,12]
					TRB->BCO4   = aDados[I,13]
					TRB->BCO5   = aDados[I,14]
		        MsUnLock()
			next
		endif

		Private aRotina   := {}
		private cCadastro := "Manutenção Bancos Preferencias da Cobrança p/Clientes"
//		private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
			
		aadd (aRotina, {"&Pesquisar"             ,"AxPesqui"       , 0, 1})
		aadd (aRotina, {"&Visualizar"            ,"U_VIS_CLI"      , 0, 2})
		aadd (aRotina, {"&Alterar"               ,"U_ALT_BANC()"   , 0, 3})
		
//		private _sArqLog := U_NomeLog ()
//		u_logId ()
		
		dbSelectArea("TRB")
		dbSetOrder(1)
		    
		mBrowse(,,,,"TRB",aHead,,,,3)
		
		TRB->(dbCloseArea())
		u_arqtrb ("FechaTodos",,,, @_aArqTrb) 
	endif		
Return
//
// ----------------------------------------------------------------------------
User Function VIS_CLI()
	// posiciona o SA1 e chama função visualizar
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial()+ TRB->CODIGO + TRB->LOJA)
	A030Visual('SA1',1,2)
Return	
//
// ----------------------------------------------------------------------------
User Function ALT_BANC()
	local _lRet := .T.
	// solicita novos bancos
	_wbanco1 = TRB->BCO1
	_wbanco2 = TRB->BCO2
	_wbanco3 = TRB->BCO3
	_wbanco4 = TRB->BCO4
	_wbanco5 = TRB->BCO5
	
	//define msdialog _oDlg title "Composicao do desconto" from 0, 0 to 380, 500 of oMainWnd pixel
	define msdialog _oDlg title "Composicao do desconto" from 0, 0 to 280, 400 of oMainWnd pixel
	@ 10, 20  say "Alteração Bancos Preferenciais Cobrança"
	@ 25, 20  say "Banco 1"
	@ 40, 20  say "Banco 2"
	@ 55, 20  say "Banco 3"
	@ 70, 20  say "Banco 4"
	@ 85, 20  say "Banco 5"
	@ 25, 100 get _wbanco1 picture "@!" size 03, 11 F3 'A62'"
	@ 40, 100 get _wbanco2 picture "@!" size 03, 11 F3 'A62'"
	@ 55, 100 get _wbanco3 picture "@!" size 03, 11 F3 'A62'"
	@ 70, 100 get _wbanco4 picture "@!" size 03, 11 F3 'A62'"
	@ 85, 100 get _wbanco5 picture "@!" size 03, 11 F3 'A62'"
	@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 90 bmpbutton type 1 action ( iif(u_valida_bco() = .T. , _oDlg:End (), u_help("Altera Bancos Prefenciais Cobrança") )) 
	@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 40 bmpbutton type 2 action (_lRet := .F., _oDlg:End ())
	activate dialog _oDlg centered
	
Return     
// ----------------------------------------------------------------------------
// valida valores x verbas utilizadas
User Function valida_bco()
	local _valida := .T.
	
	if !empty(_wbanco1)
		DbSelectArea("SA6")
		DbSetOrder(1)
		DbSeek(xFilial()+ _wbanco1)
		if !found ()
			u_help ("Banco 1 não encontrado na tabela de bancos")
			_valida = .F.
		endif
		// verifica se o banco eh cadastrado
		if _wbanco1 = _wbanco2
			u_help ("Banco 1 igual ao Banco 2")
			_valida = .F.
		endif
		if _valida .and. _wbanco1 = _wbanco3
			u_help ("Banco 1 igual ao Banco 3")
			_valida = .F.
		endif
		if _valida .and. _wbanco1 = _wbanco4
			u_help ("Banco 1 igual ao Banco 4")
			_valida = .F.
		endif
		if _valida .and. _wbanco1 = _wbanco5
			u_help ("Banco 1 igual ao Banco 5")
			_valida = .F.
		endif
	endif		
	
	if _valida .and. !empty(_wbanco2)
		DbSelectArea("SA6")
		DbSetOrder(1)
		DbSeek(xFilial()+ _wbanco2)
		if !found ()
			u_help ("Banco 2 não encontrado na tabela de bancos")
			_valida = .F.
		endif
		if _wbanco2 = _wbanco1
			u_help ("Banco 2 igual ao Banco 1")
			_valida = .F.
		endif
		if _valida .and. _wbanco2 = _wbanco3
			u_help ("Banco 2 igual ao Banco 3")
			_valida = .F.
		endif
		if _valida .and. _wbanco2 = _wbanco4
			u_help ("Banco 2 igual ao Banco 4")
			_valida = .F.
		endif
		if _valida .and. _wbanco2 = _wbanco5
			u_help ("Banco 2 igual ao Banco 5")
			_valida = .F.
		endif
	endif	
	
	if _valida .and. !empty(_wbanco3)
		DbSelectArea("SA6")
		DbSetOrder(1)
		DbSeek(xFilial()+ _wbanco3)
		if !found ()
			u_help ("Banco 3 não encontrado na tabela de bancos")
			_valida = .F.
		endif
		if _wbanco3 = _wbanco2
			u_help ("Banco 3 igual ao Banco 2")
			_valida = .F.
		endif
		if _valida .and. _wbanco3 = _wbanco1
			u_help ("Banco 3 igual ao Banco 1")
			_valida = .F.
		endif
		if _valida .and. _wbanco3 = _wbanco4
			u_help ("Banco 3 igual ao Banco 4")
			_valida = .F.
		endif
		if _valida .and. _wbanco3 = _wbanco5
			u_help ("Banco 3 igual ao Banco 5")
			_valida = .F.
		endif
	endif
	
	if _valida .and. !empty(_wbanco4)
		DbSelectArea("SA6")
		DbSetOrder(1)
		DbSeek(xFilial()+ _wbanco4)
		if !found ()
			u_help ("Banco 4 não encontrado na tabela de bancos")
			_valida = .F.
		endif
		if _wbanco4 = _wbanco3
			u_help ("Banco 4 igual ao Banco 3")
			_valida = .F.
		endif
		if _valida .and. _wbanco4 = _wbanco2
			u_help ("Banco 4 igual ao Banco 2")
			_valida = .F.
		endif
		if _valida .and. _wbanco4 = _wbanco1
			u_help ("Banco 4 igual ao Banco 1")
			_valida = .F.
		endif
		if _valida .and. _wbanco4 = _wbanco5
			u_help ("Banco 4 igual ao Banco 5")
			_valida = .F.
		endif
	endif
	
	if _valida .and. !empty(_wbanco5)
		DbSelectArea("SA6")
		DbSetOrder(1)
		DbSeek(xFilial()+ _wbanco5)
		if !found ()
			u_help ("Banco 5 não encontrado na tabela de bancos")
			_valida = .F.
		endif
		if _wbanco5 = _wbanco4
			u_help ("Banco 5 igual ao Banco 4")
			_valida = .F.
		endif
		if _valida .and. _wbanco5 = _wbanco3
			u_help ("Banco 5 igual ao Banco 3")
			_valida = .F.
		endif
		if _valida .and. _wbanco5 = _wbanco2
			u_help ("Banco 5 igual ao Banco 2")
			_valida = .F.
		endif
		if _valida .and. _wbanco5 = _wbanco1
			u_help ("Banco 5 igual ao Banco 1")
			_valida = .F.
		endif
	endif
	
	if _valida		
		// atualiza arquivo de trabalho
		DbSelectArea("TRB")
		DbSetOrder(1)
		DbSeek(TRB->CODIGO + TRB->LOJA)
		reclock("TRB", .F.)
			TRB->BCO1 = _wbanco1
			TRB->BCO2 = _wbanco2
			TRB->BCO3 = _wbanco3
			TRB->BCO4 = _wbanco4
			TRB->BCO5 = _wbanco5
		MsUnLock()
		
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial()+ TRB->CODIGO + TRB->LOJA)
		If Found()
			reclock("SA1", .F.)
				SA1->A1_BCO1   = _wbanco1 
				SA1->A1_BCO2   = _wbanco2
				SA1->A1_BCO3   = _wbanco3
				SA1->A1_BCO4   = _wbanco4
				SA1->A1_BCO5   = _wbanco5
    		MsUnLock()
		endif
			
	endif		
Return _valida
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Cliente de            ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {02, "Cliente ate           ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {03, "Considera Bloqueados  ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {04, "Risco                 ?", "N", 1, 0,  "",   "   ", {"A","D","E","Ambos"},   ""})
	aadd (_aRegsPerg, {05, "UF de                 ?", "C", 2, 0,  "",   "12 ", {},"UF do Cliente"})
	aadd (_aRegsPerg, {06, "UF até                ?", "C", 2, 0,  "",   "12 ", {},"UF do Cliente"})
	aadd (_aRegsPerg, {07, "Banco Principal de    ?", "C", 3, 0,  "",   "A62", {},"Banco Preferencial do Cliente"})
	aadd (_aRegsPerg, {08, "Banco Principal até   ?", "C", 3, 0,  "",   "A62", {},"Banco Preferencial do Cliente"})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return

