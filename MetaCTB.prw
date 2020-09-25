// Programa:   MetaCTB
// Autor:      Robert Koch
// Data:       16/11/2015
// Descricao:  Contabilizacao da folha do Metadados.
// 
// Historico de alteracoes:
// 06/01/2016 - Robert - Verifica, antes, se o lcto tem valor zerado.
// 09/04/2016 - Robert - Tratamento para a variavel _sErroAuto.
// 04/05/2016 - Robert - Funcao _NoAcento passa a ser 'user function'.
// 11/10/2017 - Robert - Database do Metadados migrado - alterado nome para acesso.
// 08/04/2019 - Catia  - include TbiConn.ch 
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

user function MetaCTB (_lAuto)
	private _sArqLog := U_NomeLog ()
	private cPerg    := "METACTB"
	u_logId ()
	u_logIni ()

	_ValidPerg ()
	Pergunte (cPerg, .F.)

	if ! AmIIn (34)
		u_help ('Este programa deve ser executado usando uma licenca do modulo 34 (contabilidade).')
		return
	endif

	if _lAuto == NIL .or. ! _lAuto
		if ! Pergunte (cPerg, .T.)
			return
		endif
	endif

	processa ({|| _AndaLogo ()})
	u_logFim ()
return



// --------------------------------------------------------------------------
static function _AndaLogo ()
	local _lContinua := .T.
	local _oSQL      := NIL
	local _aLcto     := {}
	local _aLctos    := {}
	local _nLcto     := 0
	local _aLinhaCT2 := {}
	local _aAutoCT2C := {}
	local _aAutoCT2I := {}
	local _sDoc      := ""
	local _sLoteLcto := '008890'
	local _sOrigLcto := 'U_METACTB'
	local _sLinLcto  := ''
	local _dDataLcto := ctod ('')
	local _sAliasQ   := ""
	local _sCtaD     := ""
	local _sCtaC     := ""
	local _sCCD      := ""
	local _sCCC      := ""
	private _sErros  := ""
	Private CTF_LOCK := 0  // Deixar private para ser usada pelo prog. de lctos contabeis.
	Private lSubLote := .T.  // Deixar private para ser usada pelo prog. de lctos contabeis.
	private _sErroAuto := ""  // Deixar private para ser usada pela funcao U_Help.
	
	procregua (10)

	// Verifica se jah existe contabilizacao. 
	if _lContinua
		incproc ('Verificando se ja existe contabilizacao')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("CT2") + " CT2 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND CT2_FILIAL = '" + xfilial ("CT2") + "'"
		_oSQL:_sQuery +=   " AND CT2_DATA   = '" + dtos (mv_par01) + "'"
		_oSQL:_sQuery +=   " AND CT2_LOTE   = '" + _sLoteLcto      + "'"
		_oSQL:_sQuery +=   " AND CT2_ORIGEM = '" + _sOrigLcto      + "'"
		if _oSQL:RetQry () > 0
			_lContinua = U_MsgNoYes ("Encontrei lancamentos contabeis com lote '" + _sLoteLcto + "' e origem '" + _sOrigLcto + "' nesta data, o que me indica que esta contabilizacao ja' foi feita. Deseja continuar mesmo assim?", .F.)
		endif 
	endif

	// Busca no banco de dados da Metadados os lancamentos de contabilizacao. 
	if _lContinua
		incproc ('Lendo lctos do Metadados')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT dbo.VA_DatetimeToVarchar (DATALANCAMENTO) AS DATA,"
		_oSQL:_sQuery +=       " CONTADEVEDORA AS CTADEB,"
		_oSQL:_sQuery +=       " CONTACREDORA AS CTACRED,"
		_oSQL:_sQuery +=       " CLASSIFICACAOCONTABIL AS CC,"
		_oSQL:_sQuery +=       " DESCRICAO40 AS HIST,"
		_oSQL:_sQuery +=       " SUM (VALOR) AS VALOR"
//		_oSQL:_sQuery +=  ' FROM SIRH.dbo.RHLANCTOSCONTABCONTR'
		_oSQL:_sQuery +=  ' FROM LKSRV_SIRH.SIRH.dbo.RHLANCTOSCONTABCONTR'
		_oSQL:_sQuery += " WHERE EMPRESA         = '00" + cEmpAnt + "'"
		_oSQL:_sQuery +=   " AND ESTABELECIMENTO = '00" + cFilAnt + "'"
		_oSQL:_sQuery +=   " AND TIPOITEM        = '1'"
		_oSQL:_sQuery +=   " AND dbo.VA_DatetimeToVarchar (DATALANCAMENTO) = '" + dtos (mv_par01) + "'"
		_oSQL:_sQuery += " GROUP BY dbo.VA_DatetimeToVarchar (DATALANCAMENTO), CONTADEVEDORA, CONTACREDORA, CLASSIFICACAOCONTABIL, DESCRICAO40"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb ()
		(_sAliasQ) -> (dbgotop ())
		if (_sAliasQ) -> (eof ())
			u_help ("Nao foram encontrados lancamentos no Metadados para esta filial na data de " + dtoc (mv_par01))
			_lContinua = .F.
		endif
	endif

	if _lContinua
		incproc ('Verificando contas e CC')
		ct1 -> (dbsetorder (1))
		ctt -> (dbsetorder (1))  // CTT_FILIAL+CTT_CUSTO
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())

			_sCtaD = alltrim ((_sAliasQ) -> CtaDeb)
			_sCtaC = alltrim ((_sAliasQ) -> CtaCred)

			if ! empty (_sCtaD) .and. ! ct1 -> (dbseek (xfilial ("CT1") + _sCtaD, .F.))
				_Erro ("Conta contabil '" + _sCtaD + "' (deb) nao cadastrada.")
			endif
			if ! empty (_sCtaC) .and. ! ct1 -> (dbseek (xfilial ("CT1") + _sCtaC, .F.))
				_Erro ("Conta contabil '" + _sCtaC + "' (cred) nao cadastrada.")
			endif
			
			// Soh utiliza centro de custo em determinados tipos de conta.
			_sCCD = iif (left (_sCtaD, 1) $ '4/7', (_sAliasQ) -> CC, '')
			_sCCC = iif (left (_sCtaC, 1) $ '4/7', (_sAliasQ) -> CC, '')
			if ! empty (_sCCD) .and. ! ctt -> (dbseek (xfilial ("CTT") + _sCCD, .F.))
				_Erro ("Centro de custo '" + _sCCD + "' nao cadastrado.")
			endif
			if ! empty (_sCCC) .and. ! ctt -> (dbseek (xfilial ("CTT") + _sCCC, .F.))
				_Erro ("Centro de custo '" + _sCCC + "' nao cadastrado.")
			endif



			if dtos (mv_par01) == '20151031'  // No primeiro mes, CC antigos... eliminar este bloco depois.
				if cFilAnt == '01'
					// Adriano foi transf. para 13 este mes
					if alltrim (_sCCD) == '131410'  
						u_log ('Alterando CCD de 131410 para 014004')
						_sCCD = '014004'
						if left (_sCtaD, 4) == '7010'
							if _sCtaD = '701010202002' ; _sCtaD = '403010102002'  // FGTS
							elseif _sCtaD = '701010202001' ; _sCtaD = '403010102001'  // INSS
							elseif _sCtaD = '701010203004' ; _sCtaD = '403010103004'  // Encargos 13o
							elseif _sCtaD = '701010203003' ; _sCtaD = '403010103003'  // Provisao 13o
							elseif _sCtaD = '701010202003' ; _sCtaD = '403010102003'  // PIS sobre folha
							elseif _sCtaD = '701010204004' ; _sCtaD = '403010104004'  // Vale transporte
							elseif _sCtaD = '701010204003' ; _sCtaD = '403010104003'  // Alimentacao
							else
								u_log ('Alterando CtaD de 7010 para 4030')
								_sCtaD = '4030' + substr (_sCtaD, 5)
							endif
						endif
					endif
					if alltrim (_sCCC) == '131410'  // Adriano foi transf. para 13 este mes
						u_log ('Alterando CCC de 131410 para 014004')
						_sCCC = '014004'
						if left (_sCtaC, 4) == '7010'
							if _sCtaC = '701010202002' ; _sCtaC = '403010102002'  // FGTS
							elseif _sCtaC = '701010202001' ; _sCtaC = '403010102001'  // INSS
							elseif _sCtaC = '701010203004' ; _sCtaC = '403010103004'  // Encargos 13o
							elseif _sCtaC = '701010203003' ; _sCtaC = '403010103003'  // Provisao 13o
							elseif _sCtaC = '701010202003' ; _sCtaC = '403010102003'  // PIS sobre folha
							elseif _sCtaC = '701010204004' ; _sCtaC = '403010104004'  // Vale transporte
							elseif _sCtaC = '701010204003' ; _sCtaC = '403010104003'  // Alimentacao
							else   
								u_log ('Alterando CtaC de 7010 para 4030')
								_sCtaC = '4030' + substr (_sCtaC, 5)
							endif
						endif
					endif
				endif
				_sCCD = _CCAntigo (alltrim (_sCCD))
				_sCCC = _CCAntigo (alltrim (_sCCC))
			endif


			if abs (round ((_sAliasQ) -> Valor, 2)) < 0.01
				u_log ('Valor zerado')
			else
				aadd (_aLctos, {stod ((_sAliasQ) -> data), ;
					            iif (! empty (_sCtaD) .and. ! empty (_sCtaC), '3', iif (! empty (_sCtaD), '1', '2')), ;
					            iif ((_sAliasQ) -> Valor > 0, _sCtaD, _sCtaC), ;  // Se vlr.negativo, inverte contas
					            iif ((_sAliasQ) -> Valor > 0, _sCtaC, _sCtaD), ;  // Se vlr.negativo, inverte contas
					            abs ((_sAliasQ) -> Valor), ;
					            AllTrim(EnCodeUtf8(U_NoAcento((_sAliasQ) -> Hist))), ;
					            iif ((_sAliasQ) -> Valor > 0, _sCCD, _sCCC), ;  // Se vlr.negativo, inverte CC
					            iif ((_sAliasQ) -> Valor > 0, _sCCC, _SCCD)})  // Se vlr.negativo, inverte CC
				if (_sAliasQ) -> Valor < 0
					u_log ('Invertendo contas do lcto de valor ' + cvaltochar ((_sAliasQ) -> Valor))
				endif
			endif
				            
			(_sAliasQ) -> (dbskip ())
		enddo
	endif

	if _lContinua .and. ! empty (_sErros)
		u_showmemo ("Encontrados erros que impedem o processo:" + chr (13) + chr (10) + chr (13) + chr (10) + _sErros)
		_lContinua = .F.
	endif

	if _lContinua
		incproc ('Gerando lancamentos')
		
		// Ordena por data para contemplar a possibilidade de mais de um dia
		_aLctos = asort (_aLctos,,, {|_x, _y| _x [1] < _y [1]})
		
		_nLcto = 1
		do while _nLcto <= len (_aLctos)
			_dDataLcto = _aLctos [_nLcto, 1]
			_sLinLcto = '001'

			// Gera numero para documento.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "select isnull ((select max (CT2_DOC)"
			_oSQL:_sQuery +=                  " FROM " + RetSQLName ("CT2")
			_oSQL:_sQuery +=                 " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                   " AND CT2_FILIAL = '" + xfilial ("CT2") + "'"
			_oSQL:_sQuery +=                   " AND CT2_LOTE   = '" + _sLoteLcto + "'"
			_oSQL:_sQuery +=                   " AND CT2_DATA   = '" + dtos (_dDataLcto) + "'), '000001')"
			u_log (_oSQL:_sQuery)
			_sDoc = soma1 (_oSQL:RetQry ())
			_aAutoCT2C := {}
			_aAutoCT2I := {}
		    aAdd (_aAutoCT2C,  {'DDATALANC'     ,_dDataLcto    ,NIL} )
		    aAdd (_aAutoCT2C,  {'CLOTE'         ,_sLoteLcto    ,NIL} )
		    aAdd (_aAutoCT2C,  {'CSUBLOTE'      ,'001'         ,NIL} )
		    aAdd (_aAutoCT2C,  {'CDOC'          ,_sDoc         ,NIL} )
		    aAdd (_aAutoCT2C,  {'CPADRAO'       ,''            ,NIL} )
		    aAdd (_aAutoCT2C,  {'NTOTINF'       ,0             ,NIL} )
		    aAdd (_aAutoCT2C,  {'NTOTINFLOT'    ,0             ,NIL} )

			// Gera todas as linhas deste dia.
			do while _nLcto <= len (_aLctos) .and. _aLctos [_nLcto, 1] == _dDataLcto 
				_aLinhaCT2 := {}
			    aAdd (_aLinhaCT2,  {'CT2_LINHA'     ,_sLinLcto          , NIL})
			    aAdd (_aLinhaCT2,  {'CT2_MOEDLC'    ,'01'               , NIL})
			    aAdd (_aLinhaCT2,  {'CT2_DC'        ,_aLctos [_nLcto, 2], NIL})
			    aAdd (_aLinhaCT2,  {'CT2_DEBITO'    ,_aLctos [_nLcto, 3], NIL})
			    aAdd (_aLinhaCT2,  {'CT2_CREDIT'    ,_aLctos [_nLcto, 4], NIL})
			    aAdd (_aLinhaCT2,  {'CT2_VALOR'     ,_aLctos [_nLcto, 5], NIL})
			    aAdd (_aLinhaCT2,  {'CT2_CCD'       ,_aLctos [_nLcto, 7], NIL})
			    aAdd (_aLinhaCT2,  {'CT2_CCC'       ,_aLctos [_nLcto, 8], NIL})
			    aAdd (_aLinhaCT2,  {'CT2_ORIGEM'    ,_sOrigLcto         , NIL})
			    aAdd (_aLinhaCT2,  {'CT2_HIST'      ,_aLctos [_nLcto, 6], NIL})
			    u_log ('aLinhaCT2:', _aLinhaCT2)
			    aAdd (_aAutoCT2I, aclone (_aLinhaCT2))
			    _nLcto ++
			    _sLinLcto = soma1 (_sLinLcto)
			enddo
			u_log ('Gerando lancamentos')
			dbselectarea ("CT2")
			_sErroAuto  := ""
			lMSErroAuto := .F.
		    MSExecAuto({|x, y,z| CTBA102(x,y,z)}, _aAutoCT2C ,_aAutoCT2I, 3)
			if lMSErroAuto
				_sErro := memoread (NomeAutoLog ()) + chr (13) + chr (10) + _sErroAuto
				u_help (_sErro)
			else
				u_help ('Contabilizacao concluida. Lote: ' + _sLoteLcto + '  Docto: ' + _sDoc)
			endif
		enddo
	endif
	
	u_logFim ()
return



// --------------------------------------------------------------------------
static function _CCAntigo (_sCCNovo)
	local _sRet := ""
	if empty (_sCCNovo)
		return ''
	endif
	if cFilAnt == '03'
		do case
		case _sCCNovo == '031101' ; _sRet = '50231002'
		case _sCCNovo == '031102' ; _sRet = '50231002'
		case _sCCNovo == '031310' ; _sRet = '50231002'
		case _sCCNovo == '031901' ; _sRet = '50241001'
		case _sCCNovo == '032006' ; _sRet = '50231001'
		case _sCCNovo == '033002' ; _sRet = '50211001'
		case _sCCNovo == '034001' ; _sRet = '50221002'
		case _sCCNovo == '034006' ; _sRet = '50221002'
		otherwise
			_Erro ('CC novo sem classificacao de-para: ' + _sCCNovo)
		endcase
	else
		do case
		case substr (_sCCNovo, 3) == '1101' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1102' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1201' ; _sRet = '50121002'
		case substr (_sCCNovo, 3) == '1202' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1301' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1302' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1303' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1304' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1310' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '1401' ; _sRet = '50131003'
		case substr (_sCCNovo, 3) == '1402' ; _sRet = '50131003'
		case substr (_sCCNovo, 3) == '1403' ; _sRet = '50131003'
		case substr (_sCCNovo, 3) == '1404' ; _sRet = '50131003'
		case substr (_sCCNovo, 3) == '1405' ; _sRet = '50131003'
		case substr (_sCCNovo, 3) == '1406' ; _sRet = '50131003'
		case substr (_sCCNovo, 3) == '1410' ; _sRet = '50131003'
		case substr (_sCCNovo, 3) == '2001' ; _sRet = '50132002'
		case substr (_sCCNovo, 3) == '2002' ; _sRet = '50132002'
		case substr (_sCCNovo, 3) == '2003' ; _sRet = '50132002'
		case substr (_sCCNovo, 3) == '2004' ; _sRet = '50131001'
		case substr (_sCCNovo, 3) == '2005' ; _sRet = '50131001'
		case substr (_sCCNovo, 3) == '2006' ; _sRet = '50131001'
		case substr (_sCCNovo, 3) == '2007' ; _sRet = '50141004'
		case substr (_sCCNovo, 3) == '2008' ; _sRet = '50132006'
		case substr (_sCCNovo, 3) == '2009' ; _sRet = '50132001'
		case substr (_sCCNovo, 3) == '2010' ; _sRet = '50132002'
		case substr (_sCCNovo, 3) == '2011' ; _sRet = '50132003'
		case substr (_sCCNovo, 3) == '2015' ; _sRet = '50132007'
		case substr (_sCCNovo, 3) == '2016' ; _sRet = '50132007'
		case substr (_sCCNovo, 3) == '2017' ; _sRet = '50132007'
		case substr (_sCCNovo, 3) == '2018' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '2019' ; _sRet = '50131002'
		case substr (_sCCNovo, 3) == '3001' ; _sRet = '50111001'
		case substr (_sCCNovo, 3) == '3002' ; _sRet = '50111002'
		case substr (_sCCNovo, 3) == '4001' ; _sRet = '50121002'
		case substr (_sCCNovo, 3) == '4002' ; _sRet = '50123001'
		case substr (_sCCNovo, 3) == '4003' ; _sRet = '50121003'
		case substr (_sCCNovo, 3) == '4004' ; _sRet = '50121004'
		case substr (_sCCNovo, 3) == '4005' ; _sRet = '50121002'
		case substr (_sCCNovo, 3) == '4006' ; _sRet = '50121001'
		case substr (_sCCNovo, 3) == '4007' ; _sRet = '50121050'
		case substr (_sCCNovo, 3) == '4008' ; _sRet = '50121051'
		otherwise
			_Erro ('CC novo sem classificacao de-para: ' + _sCCNovo)
		endcase
	endif
return _sRet


/*
// --------------------------------------------------------------------------
static FUNCTION NoAcento(cString)
	Local cChar  := ""
	Local nX     := 0 
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÏÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ" 
	Local cTio   := "ãõÃÕ"
	Local cCecid := "çÇ"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"
	
	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf		
			nY:= At(cChar,cTio)
			If nY > 0          
				cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
			EndIf		
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf
		Endif
	Next
	If cMaior$ cString 
		cString := strTran( cString, cMaior, "" ) 
	EndIf
	If cMenor$ cString 
		cString := strTran( cString, cMenor, "" )
	EndIf
	cString := StrTran( cString, chr (13) + chr (10), " " )
	For nX:=1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		If (Asc(cChar) < 32 .Or. Asc(cChar) > 123) .and. !cChar $ '|' 
			cString:=StrTran(cString,cChar,".")
		Endif
	Next nX
Return cString
*/


// --------------------------------------------------------------------------
static function _Erro (_sMsg)
	if at (_sMsg, _sErros) == 0
		_sErros += chr (13) + chr (10) + _sMsg
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
	aadd (_aRegsPerg, {01, "Data para contabilizacao      ", "D", 8,  0,  "",   "      ", {},                                  ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
