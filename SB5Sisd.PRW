// Programa...: SB5Sisd
// Autor......: Robert Koch
// Data.......: 22/03/2016
// Descricao..: Habilita alteracao da tabela SB5 somente de campos de pasta especifica.
//
// Historico de alteracoes:
// 07/07/2016 - Robert - Nao chamada as 'verificacoes para Sisdeclara'.
// 09/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 -  SX3 e SXA
//
// --------------------------------------------------------------------------
User Function SB5Sisd ()  
	private _sArqLog  := U_NomeLog ()
	Private cCadastro := "Cadastro de produtos X Sisdeclara"
	Private cDelFunc  := ".F."
	Private cString   := "SB5"
	private aRotina   := {}
	
	u_logId ()
	
	aadd (aRotina, {"Pesquisar"	,  "AxPesqui"		, 0, 1})
	aadd (aRotina, {"Visualizar", "AxVisual"		, 0, 2})
	aadd (aRotina, {"Visualizar", "AxVisual"		, 0, 3})
	aadd (aRotina, {"Alterar"   , "U_SB5SisdA ()"	, 0, 4})
		                       
	dbSelectArea(cString)
	dbSetOrder(1)	 
	mBrowse(6,1,22,75,cString)
Return
//
// --------------------------------------------------------------------------
User Function SB5SisdA () 
	local _sPasta  := ""
	local _aCampos := {}
	
	_sPasta := 'B' // Adicionado valor SXA fixo pois não será mais permitida a leitura do SXA na release 25, apenas em telas MVC possuímos funções
	_aCpoSX3 := FwSX3Util():GetAllFields(cString)
		
	For i := 1 To Len(_aCpoSX3)
	    If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .and. (ascan (_aCampos, GetSx3Cache(_aCpoSX3[i],'X3_CAMPO')) > 0  .or. GetSx3Cache(_aCpoSX3[i], 'X3_FOLDER')== _sPasta))
	        aadd (_aCampos, GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'))
	    Endif
	Next i  

	// Cria variaveis M->... para a enchoice. Parece que, como somente os campos da pasta 'sisdeclara' estao habilitados,
	// caso o usuario nao estivesse nessa pasta ao mandar salvar, o sistema travava.
	RegToMemory ("SB5", .F., .F.)
	
	AxAltera (cString, (cString) -> (recno ()), 4, NIL, _aCampos, NIL, NIL, "U_SB5SisdK ()")
Return
////
//// --------------------------------------------------------------------------
//User Function SB5SisdA () 
//	local _sPasta  := ""
//	local _aCampos := {}
//	
//	sxa -> (dbsetorder (1))  // xa_alias + xa_ordem
//	sxa -> (dbseek (cString, .T.))
//	do while ! sxa -> (eof ()) .and. sxa -> xa_alias == cString
//		if upper (alltrim (sxa -> xa_descric)) == "SISDECLARA"
//			_sPasta = sxa -> xa_ordem
//			exit
//		endif
//		sxa -> (dbskip ())
//	enddo
//	
//	if empty (_sPasta)
//		u_help ("Nao foi possivel determinar qual a pasta 'Sisdeclara' no arquivo SB5.")
//	else
//		sx3 -> (DbSetOrder(1))
//		sx3 -> (DbSeek(cString, .T.))
//		While !sx3 -> (Eof ()) .and. SX3->X3_ARQUIVO == cString
//			If X3Uso(SX3->X3_USADO) .and. (ascan (_aCampos, alltrim (sx3 -> x3_campo)) > 0 .or. SX3->X3_FOLDER == _sPasta)
//				aadd(_aCampos, alltrim(SX3->X3_CAMPO))
//			EndIf
//			sx3 -> (DbSkip ())
//		End 
//
//		// Cria variaveis M->... para a enchoice. Parece que, como somente os campos da pasta 'sisdeclara' estao habilitados,
//		// caso o usuario nao estivesse nessa pasta ao mandar salvar, o sistema travava.
//		RegToMemory ("SB5", .F., .F.)
//		
//		AxAltera (cString, (cString) -> (recno ()), 4, NIL, _aCampos, NIL, NIL, "U_SB5SisdK ()")
//	endif
//Return
// --------------------------------------------------------------------------
// Valida 'Tudo OK' da alteracao
User Function SB5SisdK ()
	local _lRet    := .T.
	local _oSisDec := NIL
	local _nErro   := 0

	u_logIni ()

	// Valida dados para Sisdeclara. (Tem outras validacoes acima que deverao ser migradas para ca apos os testes).
	if _lRet
		_oSisDec := ClsSisd ():New (sb5->b5_cod, 'M')
		_oSisDec:ValProd ()
		for _nErro = 1 to len (_oSisDec:Erros)
			u_help ("Verificacao de cadastros para Sisdeclara: " + _oSisDec:Erros [_nErro])
			_lRet = .F.
		next
	endif

	u_logFim ()
Return _lRet
