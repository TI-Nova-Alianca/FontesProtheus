// Programa...: VA_SZA
// Autor......: Robert Koch
// Data.......: 17/01/2009
// Descricao..: Tela de manutencao de listas de precos de uva para a safra.
//
// Historico de alteracoes:
// 27/03/2009 - Robert - Verifica se estah rodando em TOP ou nao.
// 05/11/2009 - Robert - Nao executa se nao estiver rodando em TOP.
// 16/07/2010 - Robert - Importa precos de uma tabela para outra.
// 06/01/2011 - Robert - Verifica existencia da tabela no SZ7 antes de excluir.
// 08/07/2017 - Robert - Implementada replicacao da tabela BASE<ano> para a tabela atual.
// 23/11/2018 - Robert - A partir de 2019 nao pretendo mais usar a tabela SZ7.
// 21/03/2020 - Robert - Nao verifica mais tabela SZ7 para nenhum caso.
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
User Function va_sza()
//	local   _nOpcao    := 0
	local   _sFilTop   := ''
	private aRotina    := {}
	private _nModelTab := 0
	private cCadastro  := "Tabelas de precos uvas safras"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('051', __cUserID, .T.)
		return
	endif

	_nModelTab = aviso ("Modelo de tabela", ;
		"As tabelas de precos de uva foram sendo aprimoradas ao longo do tempo e, por isso, nao ha compatibilidade entre todas.", ;
		{"Versao 1", "Versao 2", "Versao 3"}, 3, "Selecione modelo de tabela de precos")
	
	do case
	
	// Modelo SZA X SZ1
	case _nModelTab == 1
		aadd (aRotina, {"&Pesquisar"        , "AxPesqui",  0,1})
		aadd (aRotina, {"P&recos-atu.man"   , "U_VA_SZAP", 0,4})
		dbselectarea ("SZA")
		dbSetOrder (1)
		_sFilTop = "ZA_MODELO = '1'"
		mBrowse(,,,,"SZA",,,,,,,,,,,,,,_sFilTop)

	// Modelo usando somente ZX5 (tabelas 13 e 14)
	case _nModelTab == 2
		u_help ("ATENCAO: use este modelo apenas para safras ate 2023. A partir de 2024, use o modelo 3.")

		// Monta arquivo temporario a ser apresentado no mBrowse.
		_AtuTrb ()
		
		// Definicoes de cabecalhos de campos para mBrowse
		_aHead = {}
		AAdd( _aHead, { "Tabela"                  ,{|| _trbZX5->codtab}    ,"C",  4, 0, "" } )


//		_nOpcao = aviso ("Selecione cadastro", ;
//			"Seleciona qual cadastro deseja alterar: Precos dos grupos ou Variedades de cada grupo", ;
//			{"Grupos", "Variedades"}, 3, "Selecione modelo")
//		if _nOpcao == 1
//			U_ZX5_13 ()
//		elseif _nOpcao == 2
//			U_ZX5_14 ()
//		endif

		// Botoes para mBrowse
		aadd (aRotina, {"&Alterar grupos",     "U_ZX513 (_trbZX5 -> codtab)", 0, 4})
		aadd (aRotina, {"&Alterar variedades", "U_ZX514 (_trbZX5 -> codtab)", 0, 4})

		dbSelectArea("_trbZX5")
		dbSetOrder(1)
		mBrowse(,,,,"_trbZX5",_aHead)
		_trbZX5->(dbCloseArea())
		dbselectarea ("SB1")

	// Modelo usando SZA x ZX5
	case _nModelTab == 3
		aadd (aRotina, {"&Pesquisar"         , "AxPesqui",  0,1})
		aadd (aRotina, {"&Incluir"           , "AxInclui",  0,3})
		aadd (aRotina, {"&Alterar"           , "AxAltera",  0,4})
		aadd (aRotina, {"&Alterar grupos"    , "U_ZX513 (_trbZX5 -> codtab)", 0, 4})
		aadd (aRotina, {"&Alterar variedades", "U_ZX514 (_trbZX5 -> codtab)", 0, 4})
		aadd (aRotina, {"&Copiar de outra tabela", "U_SZA_RT (_trbZX5 -> codtab)", 0, 4})
		dbselectarea ("SZA")
		dbSetOrder (1)
		_sFilTop = "ZA_MODELO = '3'"
		mBrowse(,,,,"SZA",,,,,,,,,,,,,,_sFilTop)

	otherwise
		u_help ("Modelo de tabela de preco de uva sem tratamento.",, .t.)
	endcase
return


// --------------------------------------------------------------------------
// Cria / atualiza arquivo de trabalho para mBrowse.
static function _AtuTrb ()
	local _oSQL         := NIL
	local _aEstrut      := {}
	local _oObj         := NIL
	local _aConsAtu     := {}
	local _nConsAtu     := 0
	static _lJahPassou  := .F.

	if ! _lJahPassou

		// define estrutura do arquivo de trabalho	
		AAdd( _aEstrut, { "codtab" , "N",  4, 0 } )

		// Cria arquivo de trabalho com as analises jah existentes
		_sArqTrb := CriaTrab( _aEstrut, .T. )
		dbUseArea( .T., __LocalDriver, _sArqTrb, "_trbZX5", .F., .F. )
		_sArqInd := CriaTrab( _aEstrut, .F. )
		IndRegua( "_trbZX5", _sArqInd, "codtab", , , "Criando i­ndices...")
		dbClearIndex()
		dbSetIndex( _sArqInd + OrdBagExt() )
		_lJahPassou = .T.
	else
		_trbZX5 -> (dbgotop ())
		do while ! _trbZX5 -> (eof ())
			reclock ("_trbZX5", .F.)
			_trbZX5 -> (dbdelete ())
			msunlock ()
			_trbZX5 -> (dbskip ())
		enddo
	endif

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DISTINCT ZX3_13SAFR"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5 "
	_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                     " FROM " + RetSQLName ("SZA") + " SZA "
	_oSQL:_sQuery +=                    " WHERE SZA.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                      " AND SZA.ZA_COD     = ZX5.ZX5_13SAFR)"
	_oSQL:_sQuery += " ORDER BY ZX3_13SAFR"
	_aConsAtu := _oSQL:Qry2Array ()
	for _nConsAtu = 1 to len (_aConsAtu)
		RecLock("_trbZX5",.T.)
		_trbZX5 -> codtab = _aConsAtu [_nConsAtu, 1]
		MsUnLock()
	next
	
	_trbZX5 -> (dbgotop ())
	_oObj := GetObjBrow()
	if valtype (_oObj) == 'O'
		_oObj:Default()
		_oObj:Refresh()
	endif
return


// --------------------------------------------------------------------------
// Manutencao dos precos dos produtos.
User Function VA_SZAP ()

	// Os precos ficam na tabela SZ1. Para que nao aparecam todas as tabelas, filtra
	// o SZ1 e chama programa original de manutencao do SZ1.
	dbselectarea ("SZ1")
	set filter to &("Z1_TABELA == '" + sza -> za_cod + "'")
	U_ML_SZ1 ()
	dbselectarea ("SZ1")
	set filter to
return


// --------------------------------------------------------------------------
// Replica grupos e variedades de outra tabela.
user function SZA_RT (_sTabDest)
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nCopiado  := 0
	local _aDados    := {}
	local _lContinua := .T.
	local _sTabOrig  := ''
	local _aCampos13 := {}
	local _aCampos14 := {}
	local _nCampo    := 0

	if _lContinua .and. len (alltrim (_sTabDest)) > TamSX3 ("ZX5_13SAFR")[2]
		u_help ("Rotina liberada somente para tabelas com tamanho menor ou igual ao campo ZX5_13SAFR.",, .t.)
		_lContinua = .F.
	endif

	if _lContinua
		_sTabDest = U_TamFixo (_sCodTab, 4, ' ')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5 "
		_oSQL:_sQuery +=  " WHERE ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_TABELA  = '13'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_13SAFR  = '" + _sTabDest + "'"
		_oSQL:Log ('[' + procname () + ']')
		if _oSQL:RetQry (1, .f.) > 0
			if U_MsgNoYes ("Esta tabela ja contem dados. Deseja sobrepor?")
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " UPDATE " + RetSqlName ("ZX5")
				_oSQL:_sQuery +=    " SET D_E_L_E_T_ = '*'"
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
				_oSQL:_sQuery +=    " AND ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
				_oSQL:_sQuery +=    " AND ((ZX5_TABELA  = '13' AND ZX5_13SAFR  = '" + _sTabDest + "')"
				_oSQL:_sQuery +=     " OR  (ZX5_TABELA  = '14' AND ZX5_14SAFR  = '" + _sTabDest + "'))"
				if ! _oSQL:Exec ()
					u_help ("Erro na exclusao dos dados anteriores.")
					_lContinua = .F.
				endif
			else
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		do while .t.
			_sTabOrig = U_Get ('Tabela de origem', 'C', 4, '', '', space (4), .f., '.t.')
			if _sTabOrig == NIL
				u_help ("Processo cancelado.",, .t.)
				_lContinua = .F.
			endif
			if empty (U_RetZX5 ('13', _sTabOrig, 'ZX5_SAFR'))
				u_help ("Tabela invalida.",, .t.)
				loop
			endif
		enddo
	endif

	if _lContinua
		CursorWait ()

		// Gera lista dos campos das tabelas (toda safra tem algum campo novo)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT X3_CAMPO"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SX3")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND X3_CAMPO   like 'ZX5_13%'"
		_aCampos13 := aclone (_oSQL:Qry2Array (.f., .f.))

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT X3_CAMPO"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SX3")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND X3_CAMPO   like 'ZX5_14%'"
		_aCampos14 := aclone (_oSQL:Qry2Array (.f., .f.))

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		for _nCampo = 1 to len (_aCampos13)
			_oSQL:_sQuery += "ZX5_13." + _aCampos13 [_nCampo, 1] + ", "
		next
		for _nCampo = 1 to len (_aCampos14)
			_oSQL:_sQuery += "ISNULL (ZX5_14." + _aCampos14 [_nCampo, 1] + ", '') as " + _aCampos14 [_nCampo, 1] + ", "
		next
		_oSQL:_sQuery += " , B1_DESC"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5_13 "
		_oSQL:_sQuery +=   " LEFT JOIN " + RetSqlName ("ZX5") + " ZX5_14 "
		_oSQL:_sQuery +=        " JOIN " + RetSqlName ("SB1") + " SB1 "
		_oSQL:_sQuery +=               " ON (SB1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=               " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=               " AND SB1.B1_COD     = ZX5_14.ZX5_14PROD"
		_oSQL:_sQuery +=               " AND SB1.B1_GRUPO   = '0400')"
		_oSQL:_sQuery +=          " ON (ZX5_14.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_FILIAL = ZX5_13.ZX5_FILIAL"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_TABELA = '14'"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_14SAFR = ZX5_13.ZX5_13SAFR"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_14GRUP = ZX5_13.ZX5_13GRUP)"
		_oSQL:_sQuery +=  " WHERE ZX5_13.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND ZX5_13.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5_13.ZX5_TABELA  = '13'"
		_oSQL:_sQuery +=    " AND ZX5_13.ZX5_13SAFR  = '" + _sTabOrig + "'"
		_oSQL:_sQuery +=  " ORDER BY ZX5_13.ZX5_13GRUP, SB1.B1_DESC"
		_oSQL:Log ('[' + procname () + ']')
		_sAliasQ := _oSQL:Qry2Trb ()
		do while ! (_sAliasQ) -> (eof ())
			_sGrupo = (_sAliasQ) -> zx5_13grup
			U_Log2 ('debug', '[' + procname () + ']Grupo ' + (_sAliasQ) -> zx5_13grup + (_sAliasQ) -> zx5_13desc + (_sAliasQ) -> zx5_14GRUP + (_sAliasQ) -> zx5_14prod + (_sAliasQ) -> b1_desc)

			// Insere o grupo, se ainda nao existir.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5_13 "
			_oSQL:_sQuery +=  " WHERE ZX5_13.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_TABELA  = '13'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_13SAFR  = '" + _sTabDest + "'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_13GRUP  = '" + (_sAliasQ) -> zx5_13grup + "'"
			if _oSQL:RetQry () == 0
				U_Log2 ('debug', '[' + procname () + ']inserindo grupo na tabela 13')
				_aDados = {}
				aadd (_aDados, {'ZX5_13SAFR', _sTabDest})
				for _nCampo = 1 to len (_aCampos13)
					aadd (_aDados, {_aCampos13 [_nCampo, 1], (_sAliasQ) -> &(_aCampos13 [_nCampo, 1])})
				next
				U_Log2 ('debug', '[' + procname () + ']Dados para tabela 13:')
				U_Log2 ('debug', _aDados)
				_oTab := ClsTabGen ():New ('13')
				if ! _oTab:Insere (_aDados)
					u_help (_oTab:UltMsg)
					return
				endif
			else
				U_Log2 ('debug', '[' + procname () + ']Grupo ja existe')
			endif
	
			// Insere os itens do grupo
			do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> zx5_13grup == _sGrupo
				U_Log2 ('debug', '[' + procname () + ']' + (_sAliasQ) -> zx5_13grup + (_sAliasQ) -> zx5_13desc + (_sAliasQ) -> zx5_14GRUP + (_sAliasQ) -> zx5_14prod + (_sAliasQ) -> b1_desc)
				
				// Pode haver grupo (sinteticas, por exemplo) sem item relacionado.
				if ! empty ((_sAliasQ) -> zx5_14prod) .and. ! empty ((_sAliasQ) -> zx5_14grup)
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT COUNT (*)"
					_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5_14 "
					_oSQL:_sQuery +=  " WHERE ZX5_14.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_TABELA  = '14'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_14SAFR  = '" + _sTabDest + "'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_14GRUP  = '" + (_sAliasQ) -> zx5_14grup + "'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_14PROD  = '" + (_sAliasQ) -> zx5_14prod + "'"
					if _oSQL:RetQry () == 0
						U_Log2 ('debug', '[' + procname () + ']inserindo produto na tabela 14')
						_aDados = {}
						aadd (_aDados, {'ZX5_14SAFR', _sTabDest})
						for _nCampo = 1 to len (_aCampos14)
							aadd (_aDados, {_aCampos14 [_nCampo, 1], (_sAliasQ) -> &(_aCampos14 [_nCampo, 1])})
						next
						U_Log2 ('debug', '[' + procname () + ']Dados para tabela 14:')
						U_Log2 ('debug', _aDados)
						_oTab := ClsTabGen ():New ('14')
						if ! _oTab:Insere (_aDados)
							u_help (_oTab:UltMsg,, .t.)
							return
						endif
					else
						U_Log2 ('debug', '[' + procname () + ']Item ja existe')
					endif
				endif
				(_sAliasQ) -> (dbskip ())
				_nCopiado ++
			enddo
		enddo
	
		CursorArrow ()
		u_help ("Processo concluido. " + cvaltochar (_nCopiado) + " registro(s) copiado(s).")
		dbselectarea ("SB1")
	endif
return
