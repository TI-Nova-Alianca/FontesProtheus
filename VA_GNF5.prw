// Programa:   VA_GNF5
// Autor:      Robert Koch
// Data:       27/09/2012
// Descricao:  Gera notas de devolucao das notas de compra de safra.
//
// Historico de alteracoes:
// 09/06/2015 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
// 30/06/2015 - Robert - Desabilitado campo C5_CALCST.
// 12/09/2015 - Robert - Removidos tratamentos (jah desabilitados) de ST customizada.
// 30/05/2016 - Robert - Ajustes para novos campos obrigatorios do SC5.
// 01/03/2017 - Robert - Chamada da funcao ConfirmSXC8() apos o MATA410 para tentar eliminar perda se sequencia de numero de pedidos.
//

// --------------------------------------------------------------------------
user function VA_GNF5 ()
	local _lContinua   := .T.
	local _nLock       := 0
	private cPerg      := "VA_GNF5"
	private _sArqLog   := U_NomeLog ()
	u_logIni ()

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	if ! alltrim(upper(cusername)) $ 'ROBERT.KOCH/ADMINISTRADOR'
		alert ('Rotina especial (na verdade, eu gostaria que ela nem existisse). Acesso apenas p/ Robert ou administrador.', procname ())
		return
	endif

	// Controla acesso exclusivo via semaforo.
	if _lContinua
		_nLock := U_Semaforo (procname () + cNumEmp, .F.)
		if _nLock == 0
			u_help ("Bloqueio de semaforo. Processo jah estah sendo executado.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_validperg ()
		_lContinua = pergunte (cPerg, .T.)
	endif

	if _lContinua
		if mv_par01 == '2015'
// Tivemos 2 casos em 2015...   :(			processa ({|| _Gera2015 ()})
			processa ({|| _Gera2015B ()})
		else
			processa ({|| _Gera ()})
		endif
	endif

	// Libera semaforo.
	if _lContinua .and. _nLock > 0
		U_Semaforo (_nLock)
	endif

return



// --------------------------------------------------------------------------
static function _Gera ()
	local _oSQL      := NIL
	local _sItem     := ""
	local _aLinha    := {}
	local _aAutoSC5  := {}
	local _aAutoSC6  := {}
	local _sPedGer   := ""
	local _sAliasQ   := ""
	local _sPedIni   := ""
	local _sPedFim   := ""
	local _sTESDevol := mv_par08

	procregua (10)
	incproc ("Buscando dados...")

	// Busca notas pendentes de devolucao
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM, D1_DESCRI, D1_QUANT"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1 "
	_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_FORNECE BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_DOC     BETWEEN '" + mv_par02 + "' AND '" + mv_par03 + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_SERIE   = '" + mv_par04 + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_DTDIGIT = '" + dtos (mv_par05) + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_TES     = '077'"
	_oSQL:_sQuery +=    " AND SUBSTRING (SD1.D1_DTDIGIT, 1, 4) = '" + mv_par01 + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_FORMUL  = 'S'"
	_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SC5") + " SC5_DEV,"
	_oSQL:_sQuery +=                                 RetSQLName ("SC6") + " SC6_DEV"
	_oSQL:_sQuery +=                      " WHERE SC5_DEV.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                        " AND SC5_DEV.C5_FILIAL   = SD1.D1_FILIAL"
	_oSQL:_sQuery +=                        " AND SC6_DEV.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                        " AND SC6_DEV.C6_FILIAL   = SC5_DEV.C5_FILIAL"
	_oSQL:_sQuery +=                        " AND SC6_DEV.C6_NUM      = SC5_DEV.C5_NUM"
	_oSQL:_sQuery +=                        " AND SC6_DEV.C6_PRODUTO  = SD1.D1_COD"
	_oSQL:_sQuery +=                        " AND SC6_DEV.C6_NFORI    = SD1.D1_DOC"
	_oSQL:_sQuery +=                        " AND SC6_DEV.C6_SERIORI  = SD1.D1_SERIE"
	_oSQL:_sQuery +=                        " AND SC6_DEV.C6_ITEMORI  = SD1.D1_ITEM"
	_oSQL:_sQuery +=                   " )"
	_oSQL:_sQuery += " ORDER BY D1_FORNECE, D1_LOJA, D1_DOC, D1_SERIE, D1_ITEM"
	u_log (_oSQL:_sQuery)
	_sAliasQ := _oSQL:Qry2Trb ()
	count to _nRecCount
	procregua (_nRecCount)
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		// Gera um pedido de devolucao para cada associado.
		_sAssoc = (_sAliasQ) -> d1_fornece
		_sLoja  = (_sAliasQ) -> d1_loja

		// Prepara campos do cabecalho do pedido
		_aAutoSC5 = {}
		aadd (_aAutoSC5, {"C5_EMISSAO", dDataBase, NIL})
		aadd (_aAutoSC5, {"C5_CLIENTE", _sAssoc, NIL})
		aadd (_aAutoSC5, {"C5_LOJACLI", _sLoja, NIL})
		aadd (_aAutoSC5, {"C5_TRANSP",  "032", NIL})
		aadd (_aAutoSC5, {"C5_TPFRETE", "F", NIL})
		if cFilAnt $ '01/03'
			//aadd (_aAutoSC5, {"C5_TABELA",  "094", NIL})
			aadd (_aAutoSC5, {"C5_CONDPAG", "097", NIL})
		elseif cFilAnt $ '07/08/09/11'
			//aadd (_aAutoSC5, {"C5_TABELA",  "001", NIL})
			aadd (_aAutoSC5, {"C5_CONDPAG", "97", NIL})
		elseif cFilAnt $ '10'
			//aadd (_aAutoSC5, {"C5_TABELA",  "002", NIL})
			aadd (_aAutoSC5, {"C5_CONDPAG", "097", NIL})
		elseif cFilAnt $ '12'
			//aadd (_aAutoSC5, {"C5_TABELA",  "004", NIL})
			aadd (_aAutoSC5, {"C5_CONDPAG", "035", NIL})
		endif
		aadd (_aAutoSC5, {"C5_TIPO",    "D", NIL})
		aadd (_aAutoSC5, {"C5_VAUSER",  cUserName, NIL})
		aadd (_aAutoSC5, {"C5_BANCO",   "CX1", NIL})
		aadd (_aAutoSC5, {"C5_VEND1",   "001", NIL})
		aadd (_aAutoSC5, {"C5_VEND2",   "", NIL})
		aadd (_aAutoSC5, {"C5_VEND3",   "", NIL})
		aadd (_aAutoSC5, {"C5_VEND4",   "", NIL})
		aadd (_aAutoSC5, {"C5_VEND5",   "", NIL})
		aadd (_aAutoSC5, {"C5_TPCARGA", '2', NIL})  // 1=Utiliza;2=Nao utiliza
		//aadd (_aAutoSC5, {"C5_MENNOTA", 'DEV.COMPRA SAFRA', NIL})
		if cFilAnt == '01'
			aadd (_aAutoSC5, {"C5_VAFEMB", '01', NIL})
		endif

		// Ordena campos cfe. dicionario de dados.
		_aAutoSC5 = aclone (U_OrdAuto (_aAutoSC5))
		u_log (_aAutoSC5)

		// Monta itens do pedido.
		_sItem = strzero (1, tamsx3 ("C6_ITEM")[1])
		_aAutoSC6 = {}
		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> d1_fornece == _sAssoc .and. (_sAliasQ) -> d1_loja == _sLoja
			incproc ()
			_aLinha = {}
			aadd (_aLinha, {"C6_ITEM",    _sItem,                  NIL})
			aadd (_aLinha, {"C6_PRODUTO", (_sAliasQ) -> d1_cod,    NIL})
			aadd (_aLinha, {"C6_DESCRI",  (_sAliasQ) -> d1_descri, NIL})
			aadd (_aLinha, {"C6_TES",     _sTESDevol,              NIL})
			aadd (_aLinha, {"C6_QTDVEN",  (_sAliasQ) -> d1_quant,  NIL})
			aadd (_aLinha, {"C6_QTDLIB",  (_sAliasQ) -> d1_quant,  NIL})
			aadd (_aLinha, {"C6_ENTREG",  dDataBase,               NIL})
			aadd (_aLinha, {"C6_NFORI",   (_sAliasQ) -> d1_doc,    NIL})
			aadd (_aLinha, {"C6_SERIORI", (_sAliasQ) -> d1_serie,  NIL})
			aadd (_aLinha, {"C6_ITEMORI", (_sAliasQ) -> d1_item,   NIL})
			_aLinha := aClone (U_OrdAuto (_aLinha))
			u_log (_alinha)
			AADD(_aAutoSC6, aClone (_aLinha))
			_sItem = soma1 (_sItem)
			(_sAliasQ) -> (dbskip ())
		enddo

		// Executa rotina automatica.
		if len (_aAutoSC6) > 0
			lMsHelpAuto := .F.  // se .T. direciona as mensagens de help
			lMsErroAuto := .F.  // necessario a criacao
			sc5 -> (dbsetorder (1))
			DbSelectArea("SC5")
			MATA410(_aAutoSC5,_aAutoSc6,3)

			// Confirma sequenciais, se houver.
			do while __lSX8
				ConfirmSX8 ()
			enddo

			If lMsErroAuto
				if ! empty (NomeAutoLog ())
					_sMsg = memoread (NomeAutoLog ())
					u_log (_sMsg)
					u_help (_sMsg)
				else
					u_help ("Nao foi possivel ler o log de erros.")
				endif
			else
				reclock ("SC5", .F.)
				sc5 -> c5_especi1 = 'KG'
				sc5 -> c5_vaBloq  = 'S'  // Bloqueio gerencial ateh estar tudo pronto.
				msunlock ()
				if empty (_sPedIni)
					_sPedIni = sc5 -> c5_num
				endif
				_sPedFim = sc5 -> c5_num
			endif
		endif
	enddo
	u_help ("Pedidos gerados: de " + _sPedIni + ' a ' + _sPedFim)

	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SD1")
return



// --------------------------------------------------------------------------
static function _Gera2015 ()
	local _oSQL      := NIL
	local _sItem     := ""
	local _aLinha    := {}
	local _aAutoSC5  := {}
	local _aAutoSC6  := {}
	local _sPedGer   := ""
	local _sAliasQ1  := ""
	local _sAliasQ2  := ""
	local _sPedIni   := ""
	local _sPedFim   := ""

	procregua (10)
	incproc ("Buscando dados...")

	// Busca notas pendentes de devolucao
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT ANT.ZZ9_FORNEC AS FORNECE, ANT.ZZ9_LOJA AS LOJA, ANT.ZZ9_NFCOMP AS DOC, ANT.ZZ9_SERCOM AS SERIE"
	_oSQL:_sQuery +=   " FROM (SELECT * FROM ZZ9010 WHERE D_E_L_E_T_ = '' AND ZZ9_SAFRA = '2015' AND ZZ9_FILIAL != '03' AND ZZ9_PARCEL in ('1','2')) AS ANT,"
	_oSQL:_sQuery +=        " (SELECT * FROM ZZ9010 WHERE D_E_L_E_T_ = '' AND ZZ9_SAFRA = '2015' AND ZZ9_FILIAL != '03' AND ZZ9_PARCEL = '3') AS NOVO"
	_oSQL:_sQuery +=  " WHERE NOVO.ZZ9_FILIAL = ANT.ZZ9_FILIAL"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_FORNEC = ANT.ZZ9_FORNEC"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_LOJA   = ANT.ZZ9_LOJA"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_PRE_NF = ANT.ZZ9_PRE_NF"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_PRODUT = ANT.ZZ9_PRODUT"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_GRAU   = ANT.ZZ9_GRAU"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_CLASSE = ANT.ZZ9_CLASSE"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_CLABD  = ANT.ZZ9_CLABD"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_NFPROD = ANT.ZZ9_NFPROD"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_NFENTR = ANT.ZZ9_NFENTR"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_QUANT  = ANT.ZZ9_QUANT"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_VUNIT != ANT.ZZ9_VUNIT"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_FILIAL = '" + xfilial ("ZZ9") + "'"
	_oSQL:_sQuery +=  " ORDER BY ANT.ZZ9_FORNEC, ANT.ZZ9_LOJA, ANT.ZZ9_NFCOMP, ANT.ZZ9_SERCOM"
	u_log (_oSQL:_sQuery)
	_sAliasQ1 := _oSQL:Qry2Trb ()
	count to _nRecCount
	procregua (_nRecCount)
	(_sAliasQ1) -> (dbgotop ())
	do while ! (_sAliasQ1) -> (eof ())
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM, D1_DESCRI, D1_QUANT"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1 "
		_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_FORNECE = '" + (_sAliasQ1) -> fornece + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_LOJA    = '" + (_sAliasQ1) -> loja + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_DOC     = '" + (_sAliasQ1) -> doc + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_SERIE   = '" + (_sAliasQ1) -> serie + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_FORMUL  = 'S'"  // soh pra garantir...
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SC5") + " SC5_DEV,"
		_oSQL:_sQuery +=                                 RetSQLName ("SC6") + " SC6_DEV"
		_oSQL:_sQuery +=                      " WHERE SC5_DEV.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                        " AND SC5_DEV.C5_FILIAL   = SD1.D1_FILIAL"
		_oSQL:_sQuery +=                        " AND SC6_DEV.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_FILIAL   = SC5_DEV.C5_FILIAL"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_NUM      = SC5_DEV.C5_NUM"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_PRODUTO  = SD1.D1_COD"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_NFORI    = SD1.D1_DOC"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_SERIORI  = SD1.D1_SERIE"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_ITEMORI  = SD1.D1_ITEM"
		_oSQL:_sQuery +=                   " )"
		_oSQL:_sQuery += " ORDER BY D1_FORNECE, D1_LOJA, D1_DOC, D1_SERIE, D1_ITEM"
		u_log (_oSQL:_sQuery)
		_sAliasQ2 := _oSQL:Qry2Trb ()
		(_sAliasQ2) -> (dbgotop ())
		if ! (_sAliasQ2) -> (eof ())
		
			// Prepara campos do cabecalho do pedido
			_aAutoSC5 = {}
			aadd (_aAutoSC5, {"C5_EMISSAO", dDataBase, NIL})
			aadd (_aAutoSC5, {"C5_CLIENTE", (_sAliasQ2) -> d1_fornece, NIL})
			aadd (_aAutoSC5, {"C5_LOJACLI", (_sAliasQ2) -> d1_loja, NIL})
			aadd (_aAutoSC5, {"C5_TRANSP",  "032", NIL})
			aadd (_aAutoSC5, {"C5_TPFRETE", "F", NIL})
			if cFilAnt $ '01/03'
				aadd (_aAutoSC5, {"C5_TABELA",  "322", NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", "097", NIL})
			elseif cFilAnt $ '07/08/09/11'
				//aadd (_aAutoSC5, {"C5_TABELA",  "035", NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", "035", NIL})
			elseif cFilAnt $ '10'
				aadd (_aAutoSC5, {"C5_TABELA",  "002", NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", "097", NIL})
			elseif cFilAnt $ '12'
				aadd (_aAutoSC5, {"C5_TABELA",  "003", NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", "035", NIL})
			endif
			aadd (_aAutoSC5, {"C5_TIPO",    "D", NIL})
			aadd (_aAutoSC5, {"C5_VAUSER",  cUserName, NIL})
			aadd (_aAutoSC5, {"C5_BANCO",   "CX1", NIL})
			aadd (_aAutoSC5, {"C5_VEND1",   "001", NIL})
			aadd (_aAutoSC5, {"C5_VEND2",   "", NIL})
			aadd (_aAutoSC5, {"C5_VEND3",   "", NIL})
			aadd (_aAutoSC5, {"C5_VEND4",   "", NIL})
			aadd (_aAutoSC5, {"C5_VEND5",   "", NIL})
			aadd (_aAutoSC5, {"C5_TPCARGA", '2', NIL})
			//aadd (_aAutoSC5, {"C5_MENNOTA", 'DEV.COMPRA SAFRA', NIL})
	//		if cFilAnt == '01'
	//			aadd (_aAutoSC5, {"C5_VAFEMB", '01', NIL})
	//		endif
	
			// Ordena campos cfe. dicionario de dados.
			_aAutoSC5 = aclone (U_OrdAuto (_aAutoSC5))
			u_log (_aAutoSC5)
	
			// Monta itens do pedido.
			_sItem = strzero (1, tamsx3 ("C6_ITEM")[1])
			_aAutoSC6 = {}
			do while ! (_sAliasQ2) -> (eof ())
				_aLinha = {}
				aadd (_aLinha, {"C6_ITEM",    _sItem, NIL})
				aadd (_aLinha, {"C6_PRODUTO", (_sAliasQ2) -> d1_cod, NIL})
				aadd (_aLinha, {"C6_DESCRI",  (_sAliasQ2) -> d1_descri, NIL})
				aadd (_aLinha, {"C6_TES",     "692", NIL})
				aadd (_aLinha, {"C6_QTDVEN",  (_sAliasQ2) -> d1_quant, NIL})
				aadd (_aLinha, {"C6_QTDLIB",  (_sAliasQ2) -> d1_quant, NIL})
				aadd (_aLinha, {"C6_ENTREG",  dDataBase, NIL})
				aadd (_aLinha, {"C6_NFORI",   (_sAliasQ2) -> d1_doc, NIL})
				aadd (_aLinha, {"C6_SERIORI", (_sAliasQ2) -> d1_serie, NIL})
				aadd (_aLinha, {"C6_ITEMORI", (_sAliasQ2) -> d1_item, NIL})
				_aLinha := aClone (U_OrdAuto (_aLinha))
				u_log (_alinha)
				AADD(_aAutoSC6, aClone (_aLinha))
				_sItem = soma1 (_sItem)
				(_sAliasQ2) -> (dbskip ())
			enddo

			// Executa rotina automatica.
			if len (_aAutoSC6) > 0
				lMsHelpAuto := .F.  // se .T. direciona as mensagens de help
				lMsErroAuto := .F.  // necessario a criacao
				sc5 -> (dbsetorder (1))
				DbSelectArea("SC5")
				MATA410(_aAutoSC5,_aAutoSc6,3)

				// Confirma sequenciais, se houver.
				do while __lSX8
					ConfirmSX8 ()
				enddo

				If lMsErroAuto
					if ! empty (NomeAutoLog ())
						_sMsg = memoread (NomeAutoLog ())
						u_log (_sMsg)
						u_help (_sMsg)
					else
						u_help ("Nao foi possivel ler o log de erros.")
					endif
				else
					reclock ("SC5", .F.)
					sc5 -> c5_especi1 = 'KG'
					sc5 -> c5_vaBloq  = 'S'  // Bloqueio gerencial ateh estar tudo pronto.
					msunlock ()
					if empty (_sPedIni)
						_sPedIni = sc5 -> c5_num
					endif
					_sPedFim = sc5 -> c5_num
				endif
			endif
			(_sAliasQ2) -> (dbskip ())
		endif
		(_sAliasQ1) -> (dbskip ())
	enddo
	u_help ("Pedidos gerados: de " + _sPedIni + ' a ' + _sPedFim)

	(_sAliasQ1) -> (dbclosearea ())
	dbselectarea ("SD1")
return



// --------------------------------------------------------------------------
// Uvas finas tipo SC que foram precificadas como 'bcas abaixo de 12 e ttas abaixo de 14'
// quando deveriam ter sido precificadas como 'preco de niagra e de isabel'.
static function _Gera2015B ()
	local _oSQL      := NIL
	local _sItem     := ""
	local _aLinha    := {}
	local _aAutoSC5  := {}
	local _aAutoSC6  := {}
	local _sPedGer   := ""
	local _sAliasQ1  := ""
	local _sAliasQ2  := ""
	local _sPedIni   := ""
	local _sPedFim   := ""

	procregua (10)
	incproc ("Buscando dados...")

	// Busca notas pendentes de devolucao
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT ANT.ZZ9_FORNEC AS FORNECE, ANT.ZZ9_LOJA AS LOJA, ANT.ZZ9_NFCOMP AS DOC, ANT.ZZ9_SERCOM AS SERIE,"
	_oSQL:_sQuery +=        " ISNULL ((SELECT DISTINCT ZZ9.ZZ9_NFCOMP"
	_oSQL:_sQuery +=        "            FROM ZZ9010 ZZ9"
	_oSQL:_sQuery +=        "           WHERE ZZ9.D_E_L_E_T_ = '' AND ZZ9.ZZ9_SAFRA = ANT.ZZ9_SAFRA AND ZZ9.ZZ9_PARCEL = '5' AND ZZ9.ZZ9_PRE_NF = ANT.ZZ9_PRE_NF"
	_oSQL:_sQuery +=        "             AND ZZ9.ZZ9_FORNEC = ANT.ZZ9_FORNEC AND ZZ9.ZZ9_LOJA = ANT.ZZ9_LOJA AND ZZ9.ZZ9_PRODUT = ANT.ZZ9_PRODUT AND ZZ9.ZZ9_GRAU = ANT.ZZ9_GRAU"
	_oSQL:_sQuery +=        "             AND ZZ9.ZZ9_CLASSE = ANT.ZZ9_CLASSE AND ZZ9.ZZ9_CLABD = ANT.ZZ9_CLABD), '') AS DOC_ANT"
	_oSQL:_sQuery +=   " FROM (SELECT * FROM ZZ9010 WHERE D_E_L_E_T_ = '' AND ZZ9_SAFRA = '2015' AND ZZ9_FILIAL != '03' AND ZZ9_PARCEL IN ('1', '2') AND ZZ9_PRODUT LIKE '%A') AS ANT,"
	_oSQL:_sQuery +=        " (SELECT * FROM ZZ9010 WHERE D_E_L_E_T_ = '' AND ZZ9_SAFRA = '2015' AND ZZ9_FILIAL != '03' AND ZZ9_PARCEL = '6' AND ZZ9_PRODUT LIKE '%A') AS NOVO"
	_oSQL:_sQuery +=  " WHERE NOVO.ZZ9_FILIAL = ANT.ZZ9_FILIAL"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_FORNEC = ANT.ZZ9_FORNEC"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_LOJA   = ANT.ZZ9_LOJA"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_PRE_NF = ANT.ZZ9_PRE_NF"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_PRODUT = ANT.ZZ9_PRODUT"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_GRAU   = ANT.ZZ9_GRAU"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_CLASSE = ANT.ZZ9_CLASSE"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_CLABD  = ANT.ZZ9_CLABD"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_NFPROD = ANT.ZZ9_NFPROD"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_NFENTR = ANT.ZZ9_NFENTR"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_QUANT  = ANT.ZZ9_QUANT"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_VUNIT != ANT.ZZ9_VUNIT"
	_oSQL:_sQuery +=    " AND NOVO.ZZ9_FILIAL = '" + xfilial ("ZZ9") + "'"
	_oSQL:_sQuery +=  " ORDER BY ANT.ZZ9_FORNEC, ANT.ZZ9_LOJA, ANT.ZZ9_NFCOMP, ANT.ZZ9_SERCOM"
	u_log (_oSQL:_sQuery)
	_sAliasQ1 := _oSQL:Qry2Trb ()
	count to _nRecCount
	procregua (_nRecCount)
	(_sAliasQ1) -> (dbgotop ())
	do while ! (_sAliasQ1) -> (eof ())
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_COD, D1_ITEM, D1_DESCRI, D1_QUANT"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1 "
		_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_FORNECE = '" + (_sAliasQ1) -> fornece + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_LOJA    = '" + (_sAliasQ1) -> loja + "'"
		if empty ((_sAliasQ1) -> doc_ant)  // Eh a primeira recompra
			_oSQL:_sQuery +=    " AND SD1.D1_DOC     = '" + (_sAliasQ1) -> doc + "'"
			_oSQL:_sQuery +=    " AND SD1.D1_SERIE   = '" + (_sAliasQ1) -> serie + "'"
		else
			_oSQL:_sQuery +=    " AND SD1.D1_DOC     = '" + (_sAliasQ1) -> doc_ant + "'"
			_oSQL:_sQuery +=    " AND SD1.D1_SERIE   = '" + (_sAliasQ1) -> serie + "'"
		endif
		_oSQL:_sQuery +=    " AND SD1.D1_FORMUL  = 'S'"  // soh pra garantir...
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SC5") + " SC5_DEV,"
		_oSQL:_sQuery +=                                 RetSQLName ("SC6") + " SC6_DEV"
		_oSQL:_sQuery +=                      " WHERE SC5_DEV.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                        " AND SC5_DEV.C5_FILIAL   = SD1.D1_FILIAL"
		_oSQL:_sQuery +=                        " AND SC6_DEV.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_FILIAL   = SC5_DEV.C5_FILIAL"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_NUM      = SC5_DEV.C5_NUM"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_PRODUTO  = SD1.D1_COD"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_NFORI    = SD1.D1_DOC"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_SERIORI  = SD1.D1_SERIE"
		_oSQL:_sQuery +=                        " AND SC6_DEV.C6_ITEMORI  = SD1.D1_ITEM"
		_oSQL:_sQuery +=                   " )"
		_oSQL:_sQuery += " ORDER BY D1_FORNECE, D1_LOJA, D1_DOC, D1_SERIE, D1_ITEM"
		u_log (_oSQL:_sQuery)
		_sAliasQ2 := _oSQL:Qry2Trb ()
		(_sAliasQ2) -> (dbgotop ())
		if ! (_sAliasQ2) -> (eof ())
		
			// Prepara campos do cabecalho do pedido
			_aAutoSC5 = {}
			aadd (_aAutoSC5, {"C5_EMISSAO", dDataBase, NIL})
			aadd (_aAutoSC5, {"C5_CLIENTE", (_sAliasQ2) -> d1_fornece, NIL})
			aadd (_aAutoSC5, {"C5_LOJACLI", (_sAliasQ2) -> d1_loja, NIL})
			aadd (_aAutoSC5, {"C5_TRANSP",  "032", NIL})
			aadd (_aAutoSC5, {"C5_TPFRETE", "F", NIL})
			if cFilAnt $ '01/03'
				aadd (_aAutoSC5, {"C5_TABELA",  "322", NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", "097", NIL})
			elseif cFilAnt $ '07/08/09/11'
				aadd (_aAutoSC5, {"C5_CONDPAG", "035", NIL})
			elseif cFilAnt $ '10'
				aadd (_aAutoSC5, {"C5_TABELA",  "002", NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", "097", NIL})
			elseif cFilAnt $ '12'
				aadd (_aAutoSC5, {"C5_TABELA",  "003", NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", "035", NIL})
			endif
			aadd (_aAutoSC5, {"C5_TIPO",    "D", NIL})
			aadd (_aAutoSC5, {"C5_VAUSER",  cUserName, NIL})
			aadd (_aAutoSC5, {"C5_BANCO",   "CX1", NIL})
			aadd (_aAutoSC5, {"C5_VEND1",   "001", NIL})
			aadd (_aAutoSC5, {"C5_VEND2",   "", NIL})
			aadd (_aAutoSC5, {"C5_VEND3",   "", NIL})
			aadd (_aAutoSC5, {"C5_VEND4",   "", NIL})
			aadd (_aAutoSC5, {"C5_VEND5",   "", NIL})
			aadd (_aAutoSC5, {"C5_TPCARGA", '2', NIL})
	
			// Ordena campos cfe. dicionario de dados.
			_aAutoSC5 = aclone (U_OrdAuto (_aAutoSC5))
			u_log (_aAutoSC5)
	
			// Monta itens do pedido.
			_sItem = strzero (1, tamsx3 ("C6_ITEM")[1])
			_aAutoSC6 = {}
			do while ! (_sAliasQ2) -> (eof ())
				_aLinha = {}
				aadd (_aLinha, {"C6_ITEM",    _sItem, NIL})
				aadd (_aLinha, {"C6_PRODUTO", (_sAliasQ2) -> d1_cod, NIL})
				aadd (_aLinha, {"C6_DESCRI",  (_sAliasQ2) -> d1_descri, NIL})
				aadd (_aLinha, {"C6_TES",     "692", NIL})
				aadd (_aLinha, {"C6_QTDVEN",  (_sAliasQ2) -> d1_quant, NIL})
				aadd (_aLinha, {"C6_QTDLIB",  0, NIL})  // Quero que seja criado bloqueado, para conferencia.
				aadd (_aLinha, {"C6_ENTREG",  dDataBase, NIL})
				aadd (_aLinha, {"C6_NFORI",   (_sAliasQ2) -> d1_doc, NIL})
				aadd (_aLinha, {"C6_SERIORI", (_sAliasQ2) -> d1_serie, NIL})
				aadd (_aLinha, {"C6_ITEMORI", (_sAliasQ2) -> d1_item, NIL})
				_aLinha := aClone (U_OrdAuto (_aLinha))
				u_log (_alinha)
				AADD(_aAutoSC6, aClone (_aLinha))
				_sItem = soma1 (_sItem)
				(_sAliasQ2) -> (dbskip ())
			enddo

			// Executa rotina automatica.
			if len (_aAutoSC6) > 0
				lMsHelpAuto := .F.  // se .T. direciona as mensagens de help
				lMsErroAuto := .F.  // necessario a criacao
				sc5 -> (dbsetorder (1))
				DbSelectArea("SC5")
				MATA410(_aAutoSC5,_aAutoSc6,3)

				// Confirma sequenciais, se houver.
				do while __lSX8
					ConfirmSX8 ()
				enddo

				If lMsErroAuto
					if ! empty (NomeAutoLog ())
						_sMsg = memoread (NomeAutoLog ())
						u_log (_sMsg)
						u_help (_sMsg)
					else
						u_help ("Nao foi possivel ler o log de erros.")
					endif
				else
					reclock ("SC5", .F.)
					sc5 -> c5_especi1 = 'KG'
					sc5 -> c5_vaBloq  = 'S'  // Bloqueio gerencial ateh estar tudo pronto.
					msunlock ()
					if empty (_sPedIni)
						_sPedIni = sc5 -> c5_num
					endif
					_sPedFim = sc5 -> c5_num
				endif
			endif
			(_sAliasQ2) -> (dbskip ())
		endif
		(_sAliasQ1) -> (dbskip ())
	enddo
	u_help ("Pedidos gerados: de " + _sPedIni + ' a ' + _sPedFim)

	(_sAliasQ1) -> (dbclosearea ())
	dbselectarea ("SD1")
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM                     DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Safra a devolver              ", "C", 4,                      0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "NF inicial a devolver         ", "C", tamsx3 ("D1_DOC")[1],   0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "NF final a devolver           ", "C", tamsx3 ("D1_DOC")[1],   0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Serie notas a devolver        ", "C", tamsx3 ("D1_SERIE")[1], 0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Dt.digitacao notas a devolver ", "D", 8,                      0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {06, "Cod.associado inicial         ", "C", 6,                      0,  "",   "SA2", {},    ""})
	aadd (_aRegsPerg, {07, "Cod.associado final           ", "C", 6,                      0,  "",   "SA2", {},    ""})
	aadd (_aRegsPerg, {08, "TES para devolucao            ", "C", 3,                      0,  "",   "SF4", {},    ""})

	aadd (_aDefaults, {"08", "692"})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
