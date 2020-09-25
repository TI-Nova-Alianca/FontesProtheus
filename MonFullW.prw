// Programa...: MonFullW
// Autor......: Robert Koch
// Data.......: 28/06/2016
// Descricao..: Tela de monitoramento de integracoes entre Protheus e FullWMS.
//
// Historico de alteracoes:
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop e SX3
//
// --------------------------------------------------------------------------
#include "rwmake.ch"

User Function MonFullW (_sFilial, _sProduto, _sOP, _sEtiq, _dDataIni, _dDataFim)
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private cPerg     := "MONFULLW"
	u_logIni ()

	//_ValidPerg ()

	// Se receber algum parametro, grava-o para uso nos parametros.
	if _sProduto != NIL
		U_GravaSX1 (cPerg, '01', _sProduto)
	endif
	if _sOP != NIL
		U_GravaSX1 (cPerg, '02', _sOP)
	endif
	if _sEtiq != NIL
		U_GravaSX1 (cPerg, '03', _sEtiq)
	endif
	if _dDataIni != NIL
		U_GravaSX1 (cPerg, '04', _dDataIni)
	endif
	if _dDataFim != NIL
		U_GravaSX1 (cPerg, '05', _dDataFim)
	endif

	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	processa ({|| _Tela (cFilAnt, mv_par01, mv_par02, mv_par03, mv_par04, mv_par05)})
//	do while Pergunte (cPerg, .T.)
//		processa ({|| _Tela (cFilAnt, mv_par01, mv_par02, mv_par03, mv_par04, mv_par05)})
//	enddo

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
//
// --------------------------------------------------------------------------
static function _Tela (_sFilial, _sProduto, _sOP, _sEtiq, _dDataIni, _dDataFim)
	local _sAliasQ     := ""
	local _oSQL        := NIL
	local _lContinua   := .T.
	local _bBotaoOK    := {|| NIL}
	local _bBotaoCan   := {|| NIL}
	local _aBotAdic    := {}
	local _aSize       := {}  // Para posicionamento de objetos em tela
	local _oCour24     := TFont():New("Courier New",,24,,.T.,,,,,.F.)
	local _oCour18     := TFont():New("Courier New",,18,,.T.,,,,,.F.)
	local _aHead1      := {}
	local _aCols1      := {}
	local _oDlg        := NIL
	local _aCampos     := {}
	local i			   := 0
	private _oTxtBrw1  := NIL
	private _oTxtBrw2  := NIL
	private aHeader    := {}
	private aCols      := {}
	private N          := 1

	procregua (3)
	incproc ('Lendo dados...')

	if empty (_sProduto) .and. empty (_sOP) .and. empty (_sEtiq) .and. (empty (_dDataIni) .or. empty (_dDataFim))
		u_help ('Informe produto, OP, etiqueta ou intervalo de datas a consultar.')
		_lContinua = .F.
	endif

	// Leitura de dados para a tela.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SD3.D3_COD, SD3.D3_OP, SD3.D3_DOC, dbo.VA_DTOC (SD3.D3_EMISSAO) as EMISSAO, SD3.D3_VAETIQ, SD3.D3_QUANT, SD3.D3_PERDA,"
		_oSQL:_sQuery +=        " CASE t.status WHEN '3' THEN t.qtde_exec ELSE 0 END AS QGUARDA,"
		_oSQL:_sQuery +=        " t.status + '-' + CASE t.status"
		_oSQL:_sQuery +=                         " WHEN '1' THEN 'Ja visualizado'"
		_oSQL:_sQuery +=                         " WHEN '2' THEN 'Recebto autorizado'"
		_oSQL:_sQuery +=                         " WHEN '3' THEN 'Recebto finalizado'"
		_oSQL:_sQuery +=                         " WHEN '9' THEN 'Recebto excluido'"
		_oSQL:_sQuery +=                         " ELSE ''"
		_oSQL:_sQuery +=                         " END AS STATUSFULL,"
		_oSQL:_sQuery +=        " 'Alm. ' + TRANSF_ORI.D3_LOCAL + ' P/ ' + TRANSF_DEST.D3_LOCAL AS ALMTRAN, "
		_oSQL:_sQuery +=        " TRANSF_ORI.D3_QUANT AS QTTRAN, "
		_oSQL:_sQuery +=        " SD3.D3_VADTINC + ' ' + SD3.D3_VAHRINC AS HRAPONT, "
		_oSQL:_sQuery +=        " cast (t.dthr as varchar) AS HRFULL, "
		_oSQL:_sQuery +=        " DATEDIFF(MINUTE, CAST(SD3.D3_VADTINC + ' ' + SD3.D3_VAHRINC AS DATETIME), t.dthr) AS TMPGUARDA, "
		_oSQL:_sQuery +=        " TRANSF_ORI.D3_VADTINC + ' ' + TRANSF_ORI.D3_VAHRINC AS HRTRANS, "
		_oSQL:_sQuery +=        " DATEDIFF(MINUTE, t.dthr, CAST(TRANSF_ORI.D3_VADTINC + ' ' + TRANSF_ORI.D3_VAHRINC AS DATETIME)) AS TMPTRANS"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQL:_sQuery +=      " LEFT JOIN tb_wms_entrada t"
		_oSQL:_sQuery +=            " ON (t.entrada_id = 'SD3' + D3_FILIAL + D3_DOC + D3_OP + D3_COD + D3_NUMSEQ)"
		_oSQL:_sQuery +=      " LEFT JOIN " + RetSQLName ("SD3") + " TRANSF_ORI"
		_oSQL:_sQuery +=         " INNER JOIN " + RetSQLName ("SD3") + " TRANSF_DEST"
		_oSQL:_sQuery +=            " ON (TRANSF_DEST.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=            " AND TRANSF_DEST.D3_FILIAL = TRANSF_ORI.D3_FILIAL"
		_oSQL:_sQuery +=            " AND TRANSF_DEST.D3_NUMSEQ = TRANSF_ORI.D3_NUMSEQ"
		_oSQL:_sQuery +=            " AND TRANSF_DEST.D3_CF = 'DE4')"
		_oSQL:_sQuery +=         " ON (TRANSF_ORI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=         " AND TRANSF_ORI.D3_FILIAL = SD3.D3_FILIAL"
		_oSQL:_sQuery +=         " AND TRANSF_ORI.D3_VAETIQ = SD3.D3_VAETIQ"
		_oSQL:_sQuery +=         " AND TRANSF_ORI.D3_CF = 'RE4'"
		_oSQL:_sQuery +=         " AND SD3.D3_ESTORNO != 'S')"
		_oSQL:_sQuery +=  " WHERE SD3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SD3.D3_FILIAL  = '" + _sFilial + "'"
		_oSQL:_sQuery +=    " AND SD3.D3_VAETIQ != ''"  // Todas as integracoes com FullWMS sao via etiqueta.
		if ! empty (_sOP)
			_oSQL:_sQuery +=    " AND SD3.D3_OP = '" + _sOP + "'"
		endif
		if ! empty (_sEtiq)
			_oSQL:_sQuery +=    " AND SD3.D3_VAETIQ = '" + _sEtiq + "'"
		endif
		_oSQL:_sQuery +=    " AND SD3.D3_CF LIKE 'PR%'"
		_oSQL:_sQuery +=    " AND SD3.D3_ESTORNO != 'S'"
		_oSQL:_sQuery +=    " AND SD3.D3_EMISSAO BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb ()
		if (_sAliasQ) -> (eof ())
			u_help ("Nao ha dados.")
			_lContinua = .f.
		endif
	endif

	if _lContinua

//		// Cria aHeader somente com os campos necessarios
//		_aCampos = {}
//		sx3 -> (DbSetOrder (2))
//		sx3 -> (dbseek ("ZZZ_11", .T.))
//		do while ! sx3 -> (eof ()) .and. left (sx3 -> x3_campo, 6) == 'ZZZ_11'
//			If X3USO (sx3 -> X3_USADO) .And. cNivel >= sx3 -> X3_NIVEL
//				aadd (_aCampos, sx3 -> x3_campo)
//			Endif
//			sx3 -> (dbskip ())
//		enddo
//		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, _aCampos, .T.))

		// Cria aHeader somente com os campos necessarios
		_aCampos := {}
		_aCpoSX3 := FwSX3Util():GetAllFields('ZZZ')
		
		For i := 1 To Len(_aCpoSX3)
		     If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .And. cNivel >= GetSx3Cache(_aCpoSX3[i], 'X3_NIVEL') .and. left(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'),6) == 'ZZZ_11')
		        aadd (_aCampos, GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'))
		    Endif
		Next i   
		
		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, _aCampos, .T.))
		
		// Passa os dados para o aCols
		_aLinVazia := aclone (U_LinVazia (aHeader))
		aCols = {}
		(_sAliasQ) -> (dbgotop ())
		do while !(_sAliasQ) -> (Eof())
			aadd (aCols, aclone (_aLinVazia))
			N = len (aCols)
			GDFieldPut ("ZZZ_11COD",  (_sAliasQ) -> D3_COD)
			GDFieldPut ("ZZZ_11OP",   (_sAliasQ) -> D3_OP)
			GDFieldPut ("ZZZ_11DOC",  (_sAliasQ) -> D3_DOC)
			GDFieldPut ("ZZZ_11DATA", (_sAliasQ) -> EMISSAO)
			GDFieldPut ("ZZZ_11ETIQ", (_sAliasQ) -> D3_VAETIQ)
			GDFieldPut ("ZZZ_11QTAP", (_sAliasQ) -> D3_QUANT)
			GDFieldPut ("ZZZ_11QTPE", (_sAliasQ) -> D3_PERDA)
			GDFieldPut ("ZZZ_11QTGU", (_sAliasQ) -> QGUARDA)
			GDFieldPut ("ZZZ_11STFU", (_sAliasQ) -> STATUSFULL)
			GDFieldPut ("ZZZ_11TRAN", (_sAliasQ) -> ALMTRAN)
			GDFieldPut ("ZZZ_11QTTR", (_sAliasQ) -> QTTRAN)
			GDFieldPut ("ZZZ_11HRAP", (_sAliasQ) -> HRAPONT)
			GDFieldPut ("ZZZ_11HRFU", (_sAliasQ) -> HRFULL)
			GDFieldPut ("ZZZ_11TGUA", (_sAliasQ) -> TMPGUARDA)
			GDFieldPut ("ZZZ_11HRTR", (_sAliasQ) -> HRTRANS)
			GDFieldPut ("ZZZ_11TTRA", (_sAliasQ) -> TMPTRANS)
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif

	if _lContinua
		_aHead1 := aclone (aHeader)
		_aCols1 := aclone (aCols)

		// Define tamanho da tela
		_aSize := MsAdvSize()
		define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Integracao producao Protheus x FullWMS"

		_oGetD1 := MsNewGetDados ():New (55, ;                       // Limite superior
	                                5, ;                             // Limite esquerdo
	                                _oDlg:nClientHeight / 2 - 50, ;  // Limite inferior
	                                _oDlg:nClientWidth / 2 - 10, ;   // Limite direito    // _oDlg:nClientWidth / 5 - 5, ;                     // Limite direito
                                    2, ; //GD_INSERT + GD_UPDATE, ;         // [ nStyle ]
                                    "AllwaysTrue ()", ;              // [ uLinhaOk ]
                                    "AllwaysTrue ()", ;              // [ uTudoOk ]
                                    NIL, ; //[cIniCpos]
                                    NIL,; //[ aAlter ]
                                    NIL,; // [ nFreeze ]
                                    NIL,; // [ nMax ]
                                    NIL,; // [ cFieldOk ]
                                    NIL,; // [ uSuperDel ]
                                    NIL,; // [ uDelOk ]
                                    _oDlg,; // [ oWnd ]
                                    _aHead1,; // [ ParHeader ]
                                    _aCols1) // [ aParCols ]

		_oGetD1:oBrowse:bLDblClick := {|| processa ({|| _ConsMov (_oGetD1, _sFilial, _sProduto, _sAlmox)})}

		// Define botoes para a barra de ferramentas
		_bBotaoOK  = {|| _oDlg:End ()}
		_bBotaoCan = {|| _oDlg:End ()}
		_aBotAdic  = {}
		aadd (_aBotAdic, {"", {|| aHeader := aclone (_oGetD1:aHeader), aCols := aclone (_oGetD1:aCols), U_aColsXLS ()}, "Exp.plan."})
		activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic), ALLWAYSTRUE (.F.))
	endif
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Produto                       ", "C", 15, 0,  "",   "SB1", {},    ""})
	aadd (_aRegsPerg, {02, "OP                            ", "C", 13, 0,  "",   "SC2", {},    ""})
	aadd (_aRegsPerg, {03, "Etiqueta                      ", "C", 10, 0,  "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {04, "Data inicial apontamento      ", "D", 8,  0,  "",   "",    {},    ""})
	aadd (_aRegsPerg, {05, "Data final apontamento        ", "D", 8,  0,  "",   "",    {},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
