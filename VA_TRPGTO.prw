// Programa...: VA_TRPGTO
// Autor......: Claudia Lionço
// Data.......: 01/02/2023
// Descricao..: Automatização de transitória filiais - contas a pagar
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Automatização de transitória filiais - contas a pagar
// #PalavasChave      #transitoria #contas_a_pagar
// #TabelasPrincipais #SE2
// #Modulos           #FIN
//
// Historico de alteracoes:
// 28/03/2023 - Claudia - Alterada a gravação da data base, passando por parametro. GLPI: 13355
// 14/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//
// ----------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include 'TBICONN.ch'

User Function VA_TRPGTO(_nValorBaixa, _sHist, _sBenef)
	local _aBanco  := {}
	local _aTitulo := {}
	local _dDtBase := dDataBase

    _aBanco := _BuscaBanco()
	aadd(_aTitulo,{ SE2 -> E2_FILIAL	,;
					SE2 -> E2_PREFIXO	,;
					SE2 -> E2_NUM		,;
					SE2 -> E2_PARCELA	,;
					SE2 -> E2_FORNECE	,;
					SE2 -> E2_LOJA		,;
					_nValorBaixa		,;
					_sHist	            ,;
					_sBenef				})

	If _aBanco[1,1] == .T. // Inclui o mesmo produto na empresa '02'
		STARTJOB("U_VA_TRPG2",getenvserver(),.t.,_aBanco,_aTitulo,_dDtBase)
	else
		u_help(" Processo não executado!")
	EndIf
Return
// 
// ---------------------------------------------------------------------------------------
// Grava movimento bancário na matriz 
User Function VA_TRPG2(_aBanco,_aTitulo,_dDtBase)
	local _aFINA100   := {}
	local lMsErroAuto := .F.

    PREPARE ENVIRONMENT EMPRESA "01" FILIAL '01'

		_sBenef := _aTitulo[1,9] 
		_sHist := 'PG DUPL NR ' + _aTitulo[1,3] + Posicione("SA2",1,xFilial("SA2")+_aTitulo[1,5] + _aTitulo[1,6],"A2_NOME")
		_sCred := _BuscaCC(_aBanco[1, 2])        

		If !empty(_sCred)
			_aFINA100 := { 	{"E5_DATA"  	, _dDtBase 					    , Nil},;
							{"E5_MOEDA" 	, "M1" 					 		, Nil},;
							{"E5_VALOR" 	, _aTitulo[1,7]					, Nil},;
							{"E5_NATUREZ" 	, "120599" 				 		, Nil},;
							{"E5_BANCO" 	, _aBanco[1, 2] 				, Nil},;
							{"E5_AGENCIA" 	, _aBanco[1, 3] 				, Nil},;
							{"E5_CONTA" 	, _aBanco[1, 4] 				, Nil},;
							{"E5_DEBITO" 	, "101010201099" 				, Nil},;
							{"E5_CREDITO" 	, _sCred 						, Nil},;
							{"E5_BENEF" 	, _sBenef     					, Nil},;
							{"E5_HISTOR" 	, alltrim(_sHist)				, Nil}}

			cPerg := "FinA100"
			U_GravaSXK (cPerg, "01", "1", 'G' )
			U_GravaSXK (cPerg, "04", "1", 'G' )

			MSExecAuto({|x,y,z| FinA100(x,y,z)}, 0, _aFINA100, 3)

			If lMsErroAuto
				u_log(memoread (NomeAutoLog ()))
				u_help(alltrim(memoread (NomeAutoLog ())))
			Else
				u_help("Movto. bancario pagar incluído com sucesso!")
			EndIf

			U_GravaSXK (cPerg, "01", "1", 'D' )
			U_GravaSXK (cPerg, "04", "1", 'D' )
		EndIf
		
    RESET ENVIRONMENT
Return 
// 
// ---------------------------------------------------------------------------------------
// Busca bancos da matriz
Static Function _BuscaBanco ()
	local _aBco      := {}
	local _nBco      := 0
	local _oSQL      := NIL
	local _aCols     := {}
	local _aRet      := {}
	local _nQtdBanco := 0
	local _lContinua := .T.

    _oSQL := ClsSQl ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += "       ' ' 		AS OK "
    _oSQL:_sQuery += "	    ,A6_COD 	AS BANCO"
    _oSQL:_sQuery += "      ,A6_AGENCIA AS AGENCIA "
    _oSQL:_sQuery += "      ,A6_NUMCON 	AS CONTA "
    _oSQL:_sQuery += "      ,A6_DVCTA 	AS DIGITO "
    _oSQL:_sQuery += "      ,A6_NOME 	AS NOME "
    _oSQL:_sQuery += " FROM SA6010 "
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND A6_FILIAL = '01' "
    _oSQL:_sQuery += " AND A6_BLOCKED = '2' "
    _oSQL:_sQuery += " ORDER BY A6_COD, A6_AGENCIA, A6_NUMCON "

    _oSQL:Log ()
    
    _aBco = aclone(_oSQL:Qry2Array(.t., .f.))
    if len (_aBco) == 0
        u_help ("Nao encontrei banco", _oSQL:_sQuery, .t.)
        _lContinua := .F.
    endif

	if _lContinua
		
		// Inicializa coluna de selecao com .F. ('nao selecionada').
		for _nBco:= 1 to len(_aBco)
			_aBco[_nBco, 1] := .F.
		next

		_aCols = {}
		aadd(_aCols, { 2	,'Banco'		,  3, ''})
		aadd(_aCols, { 3	,'Agencia'		,  5, ''})
		aadd(_aCols, { 4	,'Conta'		, 10, ''})
		aadd(_aCols, { 5	,'Digito'		,  1, ''})
		aadd(_aCols, { 6	,'Descrição'	, 40, ''})
		U_MBArray (@_aBco, 'Selecione o banco', _aCols, 1)
		
		for _nBco := 1 to len(_aBco)
			if _aBco[_nBco, 1]
				_nQtdBanco ++
			endif
		next
		
		do case
			case _nQtdBanco == 1
				for _nBco := 1 to len(_aBco)
					if _aBco[_nBco, 1]
						_sBanco   := _aBco[_nBco, 2]
						_sAgencia := _aBco[_nBco, 3]
						_sConta   := _aBco[_nBco, 4]
						_sDigito  := _aBco[_nBco, 5]

						if empty(_sBanco)
							_lContinua := .F.
						else
							_lContinua := .T.
						endif
					endif
				next
			case _nQtdBanco == 0
				u_help("Nenhum banco selecionado")
				_lContinua := .F.
			
			case _nQtdBanco > 1
				u_help("Mais que um banco selecionado. Verifique")
				_lContinua := .F.
		endcase
	endif

	aadd(_aRet, { _lContinua, _sBanco, _sAgencia, _sConta, _sDigito })

Return _aRet
// 
// ---------------------------------------------------------------------------------------
// Busca conta credito  
Static Function _BuscaCC(_sBanco) 
	local _sCC := ""

	Do Case
		Case _sBanco == '001'
			_sCC := "101010201001"
		Case _sBanco == '033'
			_sCC := "101010201007"
		Case _sBanco == '041'
			_sCC := "101010201003"
		Case _sBanco == '104'
			_sCC := "101010201010"
		Case _sBanco == '237'
			_sCC := "101010201011"
		Case _sBanco == '341'
			_sCC := "101010201013"
		Case _sBanco == '422'
			_sCC := "101010201006"
		Case _sBanco == '748'
			_sCC := "101010201004"
		Case _sBanco == 'CX1'
			_sCC := "101010101001"
		Otherwise
			_sCC := ""
	EndCase

	If empty(_sCC)
		u_help("Banco informado sem conta cadastrada. Não será possível fazer a transferência!")
	EndIf 
Return _sCC
