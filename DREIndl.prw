// Programa...:  DREIndl
// Descricao..: Interface para gerar e consultar DREs industriais (parte de um estudo da diretoria em jul/2019)
// Data.......: 18/08/2019
// Autor......: Robert Koch
//
// Historico de alteracoes:
// 04/09/2019 - Robert - Parametros insuficientes chamada funcao FVA_DRE_TETRAS
// 05/09/2019 - Robert - Criada interface usando mBrowse.
// 25/09/2019 - Robert - Criados browses de selecao de grandes redes / marcas proprias, quando for o caso.
// 08/01/2020 - Robert - Liberado para grupo 096 (antes era apenas para Liane e Robert).
// 04/03/2020 - Robert - Exporta tabela auxiliar de conferencia de quais produtos foram considerados em cada coluna (linha coml / linha envase).
//

// --------------------------------------------------------------------------
user function DREindl ()
	local _aHead       := {}
	local _sArqTrb     := ""
	local _sArqInd     := ""
	local _aConsAtu    := {}
	local _nConsAtu    := 0
	Private bFiltraBrw := {|| Nil}
	Private aRotina    := {}
	private cCadastro  := "DREs industriais"

	if ! U_ZZUVL ('096', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

	u_logIni ()

	// Monta arquivo temporario a ser apresentado no mBrowse.
	_AtuTrb ()
	
	// Definicoes de cabecalhos de campos para mBrowse
	_aHead = {}
	AAdd( _aHead, { "Descricao"               ,{|| _trbDRE->descricao} ,"C", 40, 0, "" } )
	AAdd( _aHead, { "ID_analise"              ,{|| _trbDRE->idanalise} ,"N",  4, 0, "" } )
	AAdd( _aHead, { "Data_inicial_NF"         ,{|| _trbDRE->dtininf}   ,"D",  8, 0, "" } )
	AAdd( _aHead, { "Data_final_NF"           ,{|| _trbDRE->dtfimnf}   ,"D",  8, 0, "" } )
	AAdd( _aHead, { "Agrupamento_para_rateio" ,{|| _trbDRE->agrup}     ,"C", 20, 0, "" } )
	AAdd( _aHead, { "Forma_de_rateio"         ,{|| _trbDRE->formarat}  ,"C", 20, 0, "" } )

	// Botoes para mBrowse
	aadd (aRotina, {"&Nova"     , "U_DREIndlN ()", 0, 3})
	aadd (aRotina, {"&Consultar", "U_DREIndlC ()", 0, 2})
	aadd (aRotina, {"&Excluir"  , "U_DREIndlE ()", 0, 5})
		
	dbSelectArea("_trbDRE")
	dbSetOrder(1)
	mBrowse(,,,,"_trbDRE",_aHead)
	_trbDRE->(dbCloseArea())
	dbselectarea ("SB1")
return



// --------------------------------------------------------------------------
// Cria / atualiza arquivo de trabalho para mBrowse.
static function _AtuTrb ()
	local _oSQL         := NIL
	local _aEstrut      := {}
	local _oObj         := NIL
	local _nConsAtu		:= 0
	static _lJahPassou  := .F.

	if ! _lJahPassou

		// define estrutura do arquivo de trabalho	
		AAdd( _aEstrut, { "idanalise" , "N",  4, 0 } )
		AAdd( _aEstrut, { "descricao" , "C", 40, 0 } )
		AAdd( _aEstrut, { "dtininf"   , "D",  8, 0 } )
		AAdd( _aEstrut, { "dtfimnf"   , "D",  8, 0 } )
		AAdd( _aEstrut, { "agrup"     , "C", 20, 0 } )
		AAdd( _aEstrut, { "formarat"  , "C", 20, 0 } )
			
		// Cria arquivo de trabalho com as analises jah existentes
		_sArqTrb := CriaTrab( _aEstrut, .T. )
		dbUseArea( .T., __LocalDriver, _sArqTrb, "_trbDRE", .F., .F. )
		_sArqInd := CriaTrab( _aEstrut, .F. )
		IndRegua( "_trbDRE", _sArqInd, "descricao", , , "Criando i­ndices...")
		dbClearIndex()
		dbSetIndex( _sArqInd + OrdBagExt() )
		_lJahPassou = .T.
	else
		_trbDRE -> (dbgotop ())
		do while ! _trbDRE -> (eof ())
			reclock ("_trbDRE", .F.)
			_trbDRE -> (dbdelete ())
			msunlock ()
			_trbDRE -> (dbskip ())
		enddo
	endif

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT ID_ANALISE, DESCRICAO, DATA_INI_NF, DATA_FIM_NF, AGRUPAMENTO_PARA_RATEIO, FORMA_RATEIO"
	_oSQL:_sQuery +=  " FROM BI_ALIANCA.dbo.DRE_INDL"
	_oSQL:_sQuery += " ORDER BY DESCRICAO"
	_aConsAtu := _oSQL:Qry2Array ()
	for _nConsAtu = 1 to len (_aConsAtu)
		RecLock("_trbDRE",.T.)
		_trbDRE -> idanalise = _aConsAtu [_nConsAtu, 1]
		_trbDRE -> descricao = _aConsAtu [_nConsAtu, 2]
		_trbDRE -> dtininf   = stod (_aConsAtu [_nConsAtu, 3])
		_trbDRE -> dtfimnf   = stod (_aConsAtu [_nConsAtu, 4])
		_trbDRE -> agrup     = _aConsAtu [_nConsAtu, 5] + ' - ' + iif (_aConsAtu [_nConsAtu, 5] = 'C', 'Consolidado', iif (_aConsAtu [_nConsAtu, 5] = 'F', 'Filial a filial', ''))
		_trbDRE -> formarat  = iif (_aConsAtu [_nConsAtu, 6] = 'Q', 'Por quantidade', iif (_aConsAtu [_nConsAtu, 6] = 'V', 'Por valor', ''))
		MsUnLock()
	next
	
	_trbDRE -> (dbgotop ())
	_oObj := GetObjBrow()
	if valtype (_oObj) == 'O'
		_oObj:Default()
		_oObj:Refresh()
	endif
return



// --------------------------------------------------------------------------
// Menu para geracao de nova analise
user function DREIndlN ()
	private cPerg := "DRE_INDL"
	_ValidPerg ()
	if pergunte (cPerg, .T.)
		processa ({|| _Gera (mv_par01, mv_par02, mv_par03, iif (mv_par04 == 1, 'C', 'F'), iif (mv_par05 == 1, 'V', 'Q'))})
	endif
return



// --------------------------------------------------------------------------
// Geracao dos dados para posterior consulta
static function _Gera (_sDescri, _dDataIni, _dDataFim, _sAgrRat, _sFormaRat)
	local _oSQL      := NIL
	local _lContinua := .T.
	local _nIdAnalis := 0
	local _nQtItens  := 0
	local _aFiliais := {}
	local _nFilial := ''

	procregua (10)
	
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT COUNT (*) FROM BI_ALIANCA.dbo.DRE_INDL WHERE DESCRICAO = '" + alltrim (_sDescri) + "'"
		_oSQL:Log ()
		if _oSQL:RetQry () > 0
			u_help ("Ja existe analise com esse nome.")
			_lContinua := .F.
		endif
	endif

	/*
	// Script para criar a tabela de 'capa' caso nao exista.
	IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DRE_INDL'))
	BEGIN
	CREATE TABLE DRE_INDL 
	 (ID_ANALISE INT DEFAULT 0
	 ,DESCRICAO VARCHAR (40) DEFAULT ''
	 ,DATA_INI_NF VARCHAR (8) DEFAULT ''
	 ,DATA_FIM_NF VARCHAR (8) DEFAULT ''
	 ,AGRUPAMENTO_PARA_RATEIO VARCHAR (1) DEFAULT ''
	 ,FORMA_RATEIO VARCHAR (1) DEFAULT '')
	 CREATE INDEX IDX1 ON DRE_INDL (ID_ANALISE)
	END
	*/

	// Cria a 'capa' da analise
	if _lContinua
		_oSQL:_sQuery := "SELECT MAX (ID_ANALISE) + 1 FROM BI_ALIANCA.dbo.DRE_INDL"
		_nIdAnalis = _oSQL:RetQry ()
		u_log ('Criando ID = ', _nIdAnalis)
		_oSQL:_sQuery := "INSERT INTO BI_ALIANCA.dbo.DRE_INDL (ID_ANALISE, DESCRICAO, DATA_INI_NF, DATA_FIM_NF, AGRUPAMENTO_PARA_RATEIO, FORMA_RATEIO)
		_oSQL:_sQuery += " VALUES (" + cvaltochar (_nIdAnalis) + ","
		_oSQL:_sQuery +=          "'" + alltrim (_sDescri) + "',"
		_oSQL:_sQuery +=          "'" + dtos (_dDataIni) + "',"
		_oSQL:_sQuery +=          "'" + dtos (_dDataFim) + "',"
		_oSQL:_sQuery +=          "'" + _sAgrRat + "',"
		_oSQL:_sQuery +=          "'" + _sFormaRat + "')"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			u_help ("Nao foi possivel criar a analise. Erro no SQL: " + _oSQL:_sQuery)
			_lContinua  = .F.
		endif
	endif
	
	// Leitura inicial da movimentacao (vendas)
	if _lContinua
		incproc ('Buscando movimentacao do periodo')
		_oSQL:_sQuery := "EXEC BI_ALIANCA.dbo.SP_DRE_INDL_GERA_DADOS " + cvaltochar (_nIdAnalis)
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			u_help ("Erro ao buscar a movimentacao do periodo: " + _oSQL:UltMsg)
			_lContinua = .F.
		else
			_oSQL:_sQuery := "SELECT COUNT (*) FROM BI_ALIANCA.dbo.DRE_INDL_ITENS WHERE ID_ANALISE = " + cvaltochar (_nIdAnalis)
			_nQtItens = _oSQL:RetQry ()
			u_log (cvaltochar (_nQtItens) + ' itens de NF lidos.')
		endif
	endif
	
	// Gera rateios de valores contabeis
	if _lContinua
		incproc ('Gerando rateios dos valores contabeis')
		u_log ('Vou gerar rateios')
		// Agrupamento consolidado
		if _sAgrRat $ 'C'
			_oSQL:_sQuery := "EXEC BI_ALIANCA.dbo.SP_DRE_INDL_GERA_RATEIOS " + cvaltochar (_nIdAnalis) + ", '', 'zz'"
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				u_help ("Erro ao gerar rateios: " + _oSQL:UltMsg)
				_lContinua = .F.
			endif
		
		// Agrupa por filial: preciso verificar cada filial movimentada e fazer os rateios contabeis
		// dentro de cada filial. Visa analisar determinadas filiais (como as lojas) isoladamente, sem
		// receber custos de outras que representam depositos, por exemplo.
		elseif _sAgrRat == 'F'
			_oSQL:_sQuery := "SELECT DISTINCT FILIAL FROM BI_ALIANCA.dbo.DRE_INDL_ITENS WHERE ID_ANALISE = " + cvaltochar (_nIdAnalis)
			_oSQL:Log ()
			_aFiliais = aclone (_oSQL:Qry2Array ())
			u_log (_aFiliais)
			for _nFilial = 1 to len (_aFiliais)
				_oSQL:_sQuery := "EXEC BI_ALIANCA.dbo.SP_DRE_INDL_GERA_RATEIOS " + cvaltochar (_nIdAnalis) + ", '" + _aFiliais [_nFilial, 1] + "', '" + _aFiliais [_nFilial, 1] + "'"
				_oSQL:Log ()
				if ! _oSQL:Exec ()
					u_help ("Erro ao gerar rateios: " + _oSQL:UltMsg)
					_lContinua = .F.
					exit
				endif
			next
		endif
	endif
	if _lContinua
		u_help ("Analise '" + cvaltochar (_nIdAnalis) + "' gerada com sucesso.")
		_AtuTrb ()
	endif
return _lContinua



// --------------------------------------------------------------------------
// Menu para consulta
user function DREIndlC ()
	local _aOpcoes := {}
	local _nLayout := 0
	if left (_trbDRE->agrup, 1) == 'C'  // Rateio consolidado
		_aOpcoes = {}
		aadd (_aOpcoes, "Lin.envase")
		aadd (_aOpcoes, "Lin.coml.")
		aadd (_aOpcoes, "Lin.Tetra (todas)")
		aadd (_aOpcoes, "Lin.Tetra (por marca de terceiro)")
		aadd (_aOpcoes, "Grandes clientes")
		aadd (_aOpcoes, "Aberto por cliente")
		aadd (_aOpcoes, "Cancelar")
		_nLayout = U_F3Array (_aOpcoes, "Selecione layout",, 400, 300)

		do case
		case _nLayout == 1
			processa ({|| _Cons2 ('LE')})
		case _nLayout == 2
			processa ({|| _Cons2 ('LC')})
		case _nLayout == 3
			processa ({|| _Cons2 ('TT')})
		case _nLayout == 4
			processa ({|| _Cons2 ('TT3')})
		case _nLayout == 5
			processa ({|| _Cons2 ('GC')})
		case _nLayout == 6
			processa ({|| _Cons2 ('AC')})
		endcase

	elseif left (_trbDRE->agrup, 1) == 'F'  // Rateio filial a filial
		_aOpcoes = {}
		aadd (_aOpcoes, "Lin.coml.")
		aadd (_aOpcoes, "Tabela preco lojas")
		aadd (_aOpcoes, "Cancelar")
		_nLayout = U_F3Array (_aOpcoes, "Selecione layout",, 400, 300)
		do case
		case _nLayout == 1
			processa ({|| _Cons2 ('LC')})
		case _nLayout == 2
			processa ({|| _Cons2 ('TL')})
		endcase
	endif
return



// --------------------------------------------------------------------------
// Consulta dados de determinada analise.
static function _Cons2 (_sLayout)
	local _oSQL := NIL
	local _sCliBIni := ''
	local _sLojBIni := ''
	local _sCliBFim := ''
	local _sLojBFim := ''
	local _sMarca3  := ''
	local _nOpcao   := 0

	_oSQL := ClsSQL ():New ()
	do case
	case _sLayout == 'LE'  // por linha de envase
		_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_LINENV ('" + cvaltochar (_trbDRE -> idanalise) + "', '', 'zz') ORDER BY GRUPO"
		_oSQL:Log ()
		_oSQL:Qry2XLS(.F.,.F.,.F.)
		if U_MsgNoYes ("Deseja exportar lista dos produtos considerados em cada linha de envase? Será exportada uma tabela adicional com uma coluna correspondendo a cada linha de envase.")
			_ListaPrd(_trbDRE -> idanalise, 'LE')
		endif

	case _sLayout == 'LC'  // por linha comercial
		_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_LINCOM ('" + cvaltochar (_trbDRE -> idanalise) + "', '', 'zz', '', '', 'Z', 'Z') ORDER BY GRUPO"
		_oSQL:Log ()
		_oSQL:Qry2XLS(.F.,.F.,.F.)
		if U_MsgNoYes ("Deseja exportar lista dos produtos considerados em cada linha comercial? Será exportada uma tabela adicional com uma coluna correspondendo a cada linha comercial.")
			_ListaPrd (_trbDRE -> idanalise, 'LC')
		endif

	case _sLayout == 'GC'  // por grandes clientes

		// Monta browse para o usuario selecionar qual rede deseja imprimir
		_oSQL:_sQuery := "SELECT SA1.A1_NOME AS NOME, A1_COD AS CODIGO, A1_LOJA AS LOJA"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery += " WHERE SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SA1.A1_VACBASE = SA1.A1_COD"
		_oSQL:_sQuery +=   " AND SA1.A1_VALBASE = SA1.A1_LOJA"
		_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SA1") + " FILIAIS "
		_oSQL:_sQuery +=                " WHERE FILIAIS.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                  " AND FILIAIS.A1_FILIAL = SA1.A1_FILIAL"
		_oSQL:_sQuery +=                  " AND FILIAIS.A1_COD + FILIAIS.A1_LOJA != SA1.A1_COD + SA1.A1_LOJA"
		_oSQL:_sQuery +=                  " AND FILIAIS.A1_VACBASE + FILIAIS.A1_VALBASE = SA1.A1_COD + SA1.A1_LOJA)"
		_oSQL:_sQuery += " ORDER BY SA1.A1_NOME"
		_oSQL:Log ()
		_nOpcao = _oSQL:F3Array ("Selecione a rede a consultar", .T.)
		if _nOpcao > 0
			_sCliBIni = _oSQL:_xRetQry [_nOpcao + 1, 2]
			_sLojBIni = _oSQL:_xRetQry [_nOpcao + 1, 3]
			_sCliBFim = _sCliBIni
			_sLojBFim = _sLojBIni
			_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_LINCOM ('" + cvaltochar (_trbDRE -> idanalise) + "', '', 'zz', '" + _sCliBIni + "', '" + _sLojBIni + "', '" + _sCliBFim + "', '" + _sLojBFim + "') ORDER BY GRUPO"
			_oSQL:Log ()
			_oSQL:Qry2XLS(.F.,.F.,.F.)
			if U_MsgNoYes ("Deseja exportar lista dos produtos considerados em cada linha comercial? Será exportada uma tabela adicional com uma coluna correspondendo a cada linha comercial.")
				_ListaPrd (_trbDRE -> idanalise, 'LC')
			endif
		endif

	case _sLayout == 'TT'  // por linha de envase Tetrapak
		_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_TETRAS ('" + cvaltochar (_trbDRE -> idanalise) + "', '', 'zz', '', 'z') ORDER BY GRUPO"
		_oSQL:Log ()
		_oSQL:Qry2XLS(.F.,.F.,.F.)

	case _sLayout == 'TT3'  // por linha de envase Tetrapak, com 'marca propria' (marcas de terceiros)

		// Monta browse para o usuario selecionar qual a marca de terceiro que deseja visualizar
		_oSQL:_sQuery := "SELECT DISTINCT MARCA_TERCEIRO as MARCA_TERCEIRO"
		_oSQL:_sQuery +=  " FROM BI_ALIANCA.dbo.DRE_INDL_ITENS"
		_oSQL:_sQuery += " WHERE ID_ANALISE = " + cvaltochar (_trbDRE -> idanalise)
		_oSQL:_sQuery += " ORDER BY MARCA_TERCEIRO"
		_oSQL:Log ()
		_nOpcao = _oSQL:F3Array ("Selecione a marca a consultar", .T.)
		u_log ('opcao selecionada:', _nOpcao)
		if _nOpcao > 0
			_sMarca3 = _oSQL:_xRetQry [_nOpcao + 1, 1]
			_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_TETRAS ('" + cvaltochar (_trbDRE -> idanalise) + "', '', 'zz', '" + _sMarca3 + "', '" + _sMarca3 + "') ORDER BY GRUPO"
			_oSQL:Log ()
			_oSQL:Qry2XLS(.F.,.F.,.F.)
		endif

	case _sLayout == 'TL'  // por Tabela de precos das Lojas
		_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_TABLOJ ('" + cvaltochar (_trbDRE -> idanalise) + "', '08', '08') ORDER BY GRUPO"
		_oSQL:Log ()
		_oSQL:Qry2XLS(.F.,.F.,.F.)
		_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_TABLOJ ('" + cvaltochar (_trbDRE -> idanalise) + "', '10', '10') ORDER BY GRUPO"
		_oSQL:Log ()
		_oSQL:Qry2XLS(.F.,.F.,.F.)
		_oSQL:_sQuery := "SELECT * FROM BI_ALIANCA.dbo.FDRE_INDL_TABLOJ ('" + cvaltochar (_trbDRE -> idanalise) + "', '13', '13') ORDER BY GRUPO"
		_oSQL:Log ()
		_oSQL:Qry2XLS(.F.,.F.,.F.)

	case _sLayout == 'AC'  // Aberto por Cliente
		_oSQL:_sQuery := " WITH DADOS AS "
		_oSQL:_sQuery += "(SELECT *"
		_oSQL:_sQuery += " FROM BI_ALIANCA.dbo.DRE_INDL_ITENS"
		_oSQL:_sQuery += " WHERE ID_ANALISE = " + cvaltochar (_trbDRE -> idanalise)
		_oSQL:_sQuery += "), TOTAIS1 AS"
		_oSQL:_sQuery += "(SELECT CLIENTE, LOJA, CLIBASE, LOJABASE, LIN_COML"
		_oSQL:_sQuery +=       " ,SUM (CASE WHEN F4_MARGEM = '1' THEN VALORNF ELSE 0 END) AS FAT_BRUTO"
		_oSQL:_sQuery +=       " ,SUM (CASE WHEN F4_MARGEM = '2' THEN VALORNF ELSE 0 END * -1) AS DEVOLUCOES"
		_oSQL:_sQuery +=       " ,SUM ((PIS_NF + COFINS_NF + ICMS_NF + IPI_NF + ST_NF + IMPOSTOS_RATEIO) * CASE WHEN F4_MARGEM = '2' THEN 1 ELSE -1 END) AS IMPOSTOS"
		_oSQL:_sQuery +=       " ,SUM ((CPV + CPV_RATEIO) * CASE WHEN F4_MARGEM = '2' THEN -1 ELSE 1 END) AS CPV"
		_oSQL:_sQuery +=       " ,SUM (CASE WHEN F4_MARGEM = '3' THEN CUSTO + BONIF_RATEIO ELSE 0 END) AS BONIFICACOES"
		_oSQL:_sQuery +=       " ,SUM ((RAPELPREV + RAPEL_RATEIO) * CASE F4_MARGEM WHEN '2' THEN -1 ELSE 1 END) AS RAPEL"
		_oSQL:_sQuery +=       " ,SUM (FRETEPREV + FRETE_RATEIO) AS FRETE"
		_oSQL:_sQuery +=       " ,SUM ((COMISPREV + COMIS_RATEIO) * CASE F4_MARGEM WHEN '2' THEN -1 ELSE 1 END) AS COMISSAO"
		_oSQL:_sQuery +=       " ,SUM (GASTOS_COML_OUTRAS) AS COML_OUTRAS"
		_oSQL:_sQuery +=       " ,SUM (DESP_ADMIN) AS DESP_ADMIN"
		_oSQL:_sQuery +=   " FROM DADOS"
		_oSQL:_sQuery +=  " GROUP BY CLIENTE, LOJA, CLIBASE, LOJABASE, LIN_COML"
		_oSQL:_sQuery += "), TOTAIS2 AS"
		_oSQL:_sQuery += "(SELECT *"
		_oSQL:_sQuery +=       " ,FAT_BRUTO + DEVOLUCOES + IMPOSTOS AS RECEITA_LIQUIDA"
		_oSQL:_sQuery +=       " ,BONIFICACOES + RAPEL + FRETE + COMISSAO + COML_OUTRAS AS DESP_COML"
		_oSQL:_sQuery +=   " FROM TOTAIS1"
		_oSQL:_sQuery += ")"
		_oSQL:_sQuery += " SELECT CLIENTE, LOJA, RTRIM (A1_NOME) AS NOME_CLIENTE, CLIBASE, LOJABASE, ZX5_39.ZX5_39DESC AS LINHA_COML"
		_oSQL:_sQuery +=       " ,SUM (FAT_BRUTO) AS FAT_BRUTO"
		_oSQL:_sQuery +=       " ,SUM (RECEITA_LIQUIDA) AS RECEITA_LIQUIDA"
		_oSQL:_sQuery +=       " ,SUM (BONIFICACOES) AS BONIFICACOES"
		_oSQL:_sQuery +=       " ,SUM (RAPEL) AS RAPEL"
		_oSQL:_sQuery +=       " ,SUM (FRETE) AS FRETE"
		_oSQL:_sQuery +=       " ,SUM (COMISSAO) AS COMISSAO"
		_oSQL:_sQuery +=       " ,SUM (DESP_COML) AS TOT_DESP_COML"
		_oSQL:_sQuery +=       " ,SUM (DESP_ADMIN) AS DESP_ADMIN"
		_oSQL:_sQuery +=       " ,SUM (RECEITA_LIQUIDA - CPV - DESP_COML - DESP_ADMIN) AS RESULT_OPERACIONAL"
		_oSQL:_sQuery +=   " FROM TOTAIS2"
		_oSQL:_sQuery +=       " ,protheus.dbo.SA1010 SA1"
		_oSQL:_sQuery +=       " ,protheus.dbo.ZX5010 ZX5_39"
		_oSQL:_sQuery +=  " WHERE SA1.D_E_L_E_T_    = ''"
		_oSQL:_sQuery +=    " AND SA1.A1_FILIAL     = '  '"
		_oSQL:_sQuery +=    " AND SA1.A1_COD        = CLIENTE"
		_oSQL:_sQuery +=    " AND SA1.A1_LOJA       = LOJA"
		_oSQL:_sQuery +=    " AND ZX5_39.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZX5_39.ZX5_FILIAL = '  '"
		_oSQL:_sQuery +=    " AND ZX5_39.ZX5_39COD  = LIN_COML"
		_oSQL:_sQuery +=  " GROUP BY CLIENTE, LOJA, A1_NOME, CLIBASE, LOJABASE, ZX5_39.ZX5_39DESC"
		_oSQL:Log ()
		_oSQL:Qry2XLS(.F.,.F.,.F.)
	endcase
return



// --------------------------------------------------------------------------
// Menu para exclusao de uma analise
user function DREIndlE ()
	local _oSQL := NIL
	if U_MsgNoYes ("Confirma a exclusao da analise " + cvaltochar (_trbDRE -> idanalise) + "?")
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "DELETE BI_ALIANCA.dbo.DRE_INDL_ITENS WHERE ID_ANALISE = " + cvaltochar (_trbDRE -> idanalise)
		_oSQL:Log ()
		if _oSQL:Exec ()
			_oSQL:_sQuery := "DELETE BI_ALIANCA.dbo.DRE_INDL WHERE ID_ANALISE = " + cvaltochar (_trbDRE -> idanalise)
			_oSQL:Log ()
			if _oSQL:Exec ()
				_AtuTrb ()
			endif
		endif
	endif
return



// --------------------------------------------------------------------------
// Exporta tabela com os produtos considerados em cada linha comercial, para conferencia.
Static Function _ListaPrd (_nIdAn, _sQualTipo)
	local _oSQL    := NIL
	local _nLin    := 0
	local _nCol    := 0
	local _aLstPrd := {}

	_oSQL := ClsSQL ():New ()
	if _sQualTipo == 'LC'
		_oSQL:_sQuery := "WITH C AS ("
		_oSQL:_sQuery += " select DISTINCT CASE WHEN GRP_LIN_COML = 'A' THEN PRODUTO ELSE '' END AS COL01"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'B' THEN PRODUTO ELSE '' END AS COL02"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'C' THEN PRODUTO ELSE '' END AS COL03"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'D' THEN PRODUTO ELSE '' END AS COL04"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'E' THEN PRODUTO ELSE '' END AS COL05"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'F' THEN PRODUTO ELSE '' END AS COL06"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'G' THEN PRODUTO ELSE '' END AS COL07"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'H' THEN PRODUTO ELSE '' END AS COL08"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'I' THEN PRODUTO ELSE '' END AS COL09"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'J' THEN PRODUTO ELSE '' END AS COL10"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'K' THEN PRODUTO ELSE '' END AS COL11"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'L' THEN PRODUTO ELSE '' END AS COL12"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'M' THEN PRODUTO ELSE '' END AS COL13"
		_oSQL:_sQuery +=                " ,CASE WHEN GRP_LIN_COML = 'Z' THEN PRODUTO ELSE '' END AS COL14"
		_oSQL:_sQuery += " FROM BI_ALIANCA.dbo.DRE_INDL_ITENS "
		_oSQL:_sQuery += " WHERE ID_ANALISE = " + cvaltochar (_nIdAn)
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "  ISNULL (RTRIM (C.COL01) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL01), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL02) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL02), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL03) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL03), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL04) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL04), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL05) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL05), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL06) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL06), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL07) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL07), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL08) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL08), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL09) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL09), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL10) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL10), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL11) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL11), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL12) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL12), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL13) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL13), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL14) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL14), '')"
		_oSQL:_sQuery += " FROM C "
	elseif _sQualTipo == 'LE'
		_oSQL:_sQuery := "WITH C AS ("
		_oSQL:_sQuery += " select DISTINCT CASE WHEN CC = '011401' THEN PRODUTO ELSE '' END AS COL01"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = '011402' THEN PRODUTO ELSE '' END AS COL02"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = 'EM_3OS' THEN PRODUTO ELSE '' END AS COL03"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = '011403' THEN PRODUTO ELSE '' END AS COL04"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = '011404' THEN PRODUTO ELSE '' END AS COL05"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = '011405' THEN PRODUTO ELSE '' END AS COL06"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = '011406' THEN PRODUTO ELSE '' END AS COL07"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = 'F09'    THEN PRODUTO ELSE '' END AS COL08"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = 'GRANEL' THEN PRODUTO ELSE '' END AS COL09"
		_oSQL:_sQuery +=                " ,CASE WHEN CC = 'OUTRAS' THEN PRODUTO ELSE '' END AS COL10"
		_oSQL:_sQuery += " FROM BI_ALIANCA.dbo.DRE_INDL_ITENS "
		_oSQL:_sQuery += " WHERE ID_ANALISE = " + cvaltochar (_nIdAn)
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "  ISNULL (RTRIM (C.COL01) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL01), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL02) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL02), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL03) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL03), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL04) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL04), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL05) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL05), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL06) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL06), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL07) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL07), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL08) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL08), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL09) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL09), '')"
		_oSQL:_sQuery += " ,ISNULL (RTRIM (C.COL10) + '-' + (SELECT RTRIM (B1_DESC) FROM protheus.dbo.SB1010 WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '  ' AND B1_COD = C.COL10), '')"
		_oSQL:_sQuery += " FROM C "
	endif
	_oSQL:Log ()
	_aLstPrd := aclone (_oSQL:Qry2Array ())

	// Para serem consideradas vazias no metodo ReduzLin, as pocicoes da array devem conter NIL.
	for _nLin = 1 to len (_aLstPrd)
		for _nCol = 1 to len (_aLstPrd [_nLin])
			if empty (_aLstPrd [_nLin, _nCol])
				_aLstPrd [_nLin, _nCol] = NIL
			endif
		next
	next

	// Instancia um objeto da classe de manipulacao de arrays, para poder reduzir suas linhas.
	_oLstPrd := ClsAUtil ():New (_aLstPrd)
	_oLstPrd:ReduzLin ()
//	u_log (_oLstPrd:_aArray)
	U_AcolsXLS (_oLstPrd:_aArray, .f.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3  Opcoes Help
	aadd (_aRegsPerg, {01, "Nome da analise a gerar       ", "C", 40, 0,  "",   "", {},    ""})
	aadd (_aRegsPerg, {02, "Data inicial                  ", "D", 8,  0,  "",   "", {},    ""})
	aadd (_aRegsPerg, {03, "Data final                    ", "D", 8,  0,  "",   "", {},    ""})
	aadd (_aRegsPerg, {04, "Rateio consolidado/por filial ", "N", 1,  0,  "",   "", {'Consolidado', 'Filial a filial'},        ""})
	aadd (_aRegsPerg, {05, "Base rateio                   ", "N", 1,  0,  "",   "", {'Por valor venda', 'Por litragem venda'}, ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
