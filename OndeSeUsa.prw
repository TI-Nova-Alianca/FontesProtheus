// Autor:     Robert Koch
// Data:      28/08/2008
// Descricao: Verifica (ou pelo menos tenta) se determinado campo eh usado no sistema.
//
// Historico de alteracoes:
// 31/03/2015 - Robert - Busca em objetos (views, functions, etc) do SQL.
// 24/08/2015 - Robert - Adicionada procura no SX1.
// 27/03/2017 - Robert - Adicionada pesquisa nos batches (ZZ6).
// 22/05/2017 - Catia  - alterado display do resultado p/poder copiar p/u_showmemo(_sResult) 
// 02/05/2018 - Robert - Portado para WS_Alianca
// 03/11/2018 - Robert - Portado de volta para user function, para poder chamar do menu.
// 04/05/2021 - Robert - Portado para SQL (R25 nao permite mais acessar dic.dados - GLPI 8784)
// 28/07/2021 - Robert - Ajuste msg quando encontrava no VA_USOROT
//

// --------------------------------------------------------------------------
// Verifica onde determinada string eh usada. Geralmente serve para pesquisar por
// nomes de campos, nicknames de gatilhos, etc.
user function OndeSeUsa (_sCampo)
	private _sResult := ""

	if empty (_sCampo)
		_sCampo := U_Get ("Campo/parametro a procurar", "C", 10, "@!", NIL, space (10), .F., ".T.")
	endif

	if ! empty (_sCampo)
		processa ({|| _Andalogo (_sCampo)})
	endif

	if type ("oMainWnd") == "O"  // Se tem interface com o usuario
		u_showmemo (_sResult)
	endif
Return _sResult



// --------------------------------------------------------------------------
static function _AndaLogo (_sCampo)
	local _oSQL     := NIL
	local _aBatch   := {}
	local _nBatch   := 0
	local _nObjSQL  := 0
	local _sRetSQL  := ''
	_oSQL := ClsSQL ():New ()

	procregua (20)
	// sx3 -> (dbsetorder (2))
	// if sx3 -> (dbseek (upper (_sCampo), .F.))
	// 	_sResult += "Consta no SX3; "
	// else
	// 	_sResult += "Nao consta no SX3; "
	// endif
/*
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT COUNT (*)"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SX3")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND X3_CAMPO = '" + alltrim (upper (_sCampo)) + "'"
	_oSQL:Log ()
	if _oSQL:RetQry (1, .f.) > 0
		_sResult += "Consta como nome de campo no SX3; "
	else
		_sResult += "Nao consta no SX3; "
	endif
*/
	_oSQL:_sQuery := "SELECT STRING_AGG(RTRIM (X3_CAMPO), ',')
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT X3_CAMPO"
	_oSQL:_sQuery +=          " FROM " + RetSQLName ("SX3")
	_oSQL:_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=          " AND (UPPER (X3_CAMPO)   like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_VALID)   like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_VLDUSER) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_RELACAO) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_WHEN)    like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_CONDSQL) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_CBOX)    like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_CBOXSPA) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_CBOXENG) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_INIBRW)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X3_CHKSQL)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=           ")"
	_oSQL:_sQuery +=        ") AS CAMPOS"
	_oSQL:Log ()
	_sRetSQL = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sRetSQL)
		_sResult += "Consta na definicao do(s) campo(s) " +  _sRetSQL + '; '
	endif

	// Verifica se consta em alguma pergunta
	incproc ("Verificando SX1")
//	sx1 -> (dbgotop ())
//	do while ! sx1 -> (eof ())
//		if upper (alltrim (_sCampo)) $ upper (sx1 -> x1_valid + sx1 -> x1_def01 + sx1 -> x1_def02 + sx1 -> x1_def03 + sx1 -> x1_def04 + sx1 -> x1_def05 + sx1 -> x1_cnt01 + sx1 -> x1_cnt02 + sx1 -> x1_cnt03 + sx1 -> x1_cnt04 + sx1 -> x1_cnt05 + sx1 -> x1_f3 + sx1 -> x1_help)
//			_sResult += "Consta na pergunta " + sx1 -> x1_grupo + ':' + sx1 -> x1_ordem + '; '
//		endif
//		sx1 -> (dbskip ())
//	enddo
	_oSQL:_sQuery := "SELECT STRING_AGG(RTRIM (X1_GRUPO), ',')
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT X1_GRUPO"
	_oSQL:_sQuery +=          " FROM SX1" + cEmpAnt + "0"  // Funcao RetSQLName() retornou vazia para esta tabela.
	_oSQL:_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=          " AND (UPPER (X1_GRUPO) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_VALID) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_DEF01) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_DEF02) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_DEF03) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_DEF04) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_DEF05) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_CNT01) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_CNT02) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_CNT03) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_CNT04) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_CNT05) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_F3)    like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X1_HELP)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=           ")"
	_oSQL:_sQuery +=        ") AS GRUPOS"
	_oSQL:Log ()
	_sRetSQL = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sRetSQL)
		_sResult += "Consta na(s) pergunta(s) " +  _sRetSQL + '; '
	endif

	// Verifica se consta na inicializacao de algum arquivo
	incproc ("Verificando SX2")
	// sx2 -> (dbgotop ())
	// do while ! sx2 -> (eof ())
	// 	if upper (alltrim (_sCampo)) $ upper (sx2 -> x2_rotina + sx2 -> x2_unico)
	// 		_sResult += "Consta na tabela " + sx2 -> x2_chave + '; '
	// 	endif
	// 	sx2 -> (dbskip ())
	// enddo
	_oSQL:_sQuery := "SELECT STRING_AGG(RTRIM (X2_CHAVE), ',')
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT X2_CHAVE"
	_oSQL:_sQuery +=          " FROM " + RetSQLName ("SX2")
	_oSQL:_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=          " AND (UPPER (X2_ROTINA) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X2_UNICO) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=           ")"
	_oSQL:_sQuery +=        ") AS ARQUIVOS"
	_oSQL:Log ()
	_sRetSQL = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sRetSQL)
		_sResult += "Consta na definicao da(s) tabela(s) " +  _sRetSQL + '; '
	endif
/*
	// Verifica se consta na configuracao de algum outro campo.
	incproc ("Verificando SX3")
	sx3 -> (dbgotop ())
	do while ! sx3 -> (eof ())
		if upper (alltrim (_sCampo)) != upper (alltrim (sx3 -> x3_Campo))
			if upper (alltrim (_sCampo)) $ upper (sx3 -> x3_campo + sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_condsql + sx3 -> x3_cbox + sx3 -> x3_cboxspa + sx3 -> x3_cboxeng + sx3 -> x3_inibrw + sx3 -> x3_chksql)
				_sResult += "Consta no campo " + sx3 -> x3_campo + '; '
			endif
		endif
		sx3 -> (dbskip ())
	enddo
*/
	// Verifica se consta em algum indice
	incproc ("Verificando SIX")
	// procregua (six -> (reccount ()))
	// six -> (dbgotop ())
	// do while ! six -> (eof ())
	// 	if upper (alltrim (_sCampo)) $ upper (six -> chave)
	// 		_sResult += "Consta no indice " + six -> ordem + " do arq. " + six -> indice + '; '
	// 	endif
	// 	six -> (dbskip ())
	// enddo
	_oSQL:_sQuery := "SELECT STRING_AGG(RTRIM (CHAVE), ',')
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT CHAVE"
	_oSQL:_sQuery +=          " FROM SIX" + cEmpAnt + "0"  // Funcao RetSQLName() retornou vazia para esta tabela.
	_oSQL:_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=          " AND (UPPER (CHAVE) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=           ")"
	_oSQL:_sQuery +=        ") AS INDICES"
	_oSQL:Log ()
	_sRetSQL = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sRetSQL)
		_sResult += "Consta na definicao do(s) indice(s) " +  _sRetSQL + '; '
	endif

	// Verifica se consta em algum gatilho
	incproc ("Verificando SX7")
	// sx7 -> (dbgotop ())
	// do while ! sx7 -> (eof ())
	// 	if upper (alltrim (_sCampo)) $ upper (sx7 -> x7_campo + sx7 -> x7_regra + sx7 -> x7_cdomin + sx7 -> x7_chave + sx7 -> x7_condic)
	// 		_sResult += "Consta no gatilho " + sx7 -> x7_sequenc + " do campo " + sx7 -> x7_campo + '; '
	// 	endif
	// 	sx7 -> (dbskip ())
	// enddo
	_oSQL:_sQuery := "SELECT STRING_AGG(RTRIM (X7_CAMPO), ',')
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT X7_CAMPO"
	_oSQL:_sQuery +=          " FROM SX7" + cEmpAnt + "0"  // Funcao RetSQLName() retornou vazia para esta tabela.
	_oSQL:_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=          " AND (UPPER (X7_CAMPO)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X7_REGRA)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X7_CDOMIN) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X7_CHAVE)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (X7_CONDIC) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=           ")"
	_oSQL:_sQuery +=        ") AS GATILHOS"
	_oSQL:Log ()
	_sRetSQL = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sRetSQL)
		_sResult += "Consta na definicao do(s) gatilho(s) do(s) campo(s) " +  _sRetSQL + '; '
	endif

	// Verifica se consta em algum lancamento padrao.
	incproc ("Verificando CT5")
	// procregua (ct5 -> (reccount ()))
	// ct5 -> (dbgotop ())
	// do while ! ct5 -> (eof ())
	// 	if upper (alltrim (_sCampo)) $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori)
	// 		_sResult += "Consta no lanc.padrao " + ct5 -> ct5_lanpad + "/" + ct5 -> ct5_sequen + '; '
	// 	endif
	// 	ct5 -> (dbskip ())
	// enddo
	_oSQL:_sQuery := "SELECT STRING_AGG(RTRIM (CT5_LANPAD), ',')
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT CT5_LANPAD"
	_oSQL:_sQuery +=          " FROM " + RetSQLName ("CT5")
	_oSQL:_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=          " AND (UPPER (CT5_DEBITO)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_CREDIT)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_VLR01)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_HIST)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_CCD)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_CCC)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_ORIGEM)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_ITEMD)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_ITEMC)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_CLVLDB)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_CLVLCR)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_ATIVDE)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_ATIVCR)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_TABORI)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (CT5_RECORI)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=           ")"
	_oSQL:_sQuery +=        ") AS LANPAD"
	_oSQL:Log ()
	_sRetSQL = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sRetSQL)
		_sResult += "Consta na definicao do(s) lcto(s) padrao " +  _sRetSQL + '; '
	endif

	// Verifica se consta em alguma consulta padronizada
	incproc ("Verificando SXB")
	// sxb -> (dbgotop ())
	// do while ! sxb -> (eof ())
	// 	if upper (alltrim (_sCampo)) $ upper (sxb -> xb_alias + sxb -> xb_contem)
	// 		_sResult += "Consta na cons.padrao (SXB) " + sxb -> xb_alias + '; '
	// 	endif
	// 	sxb -> (dbskip ())
	// enddo
	_oSQL:_sQuery := "SELECT STRING_AGG(RTRIM (XB_ALIAS), ',')
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT XB_ALIAS"
	_oSQL:_sQuery +=          " FROM SXB" + cEmpAnt + "0"  // Funcao RetSQLName() retornou vazia para esta tabela.
	_oSQL:_sQuery +=          " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=          " AND (UPPER (XB_ALIAS)  like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=            " OR UPPER (XB_CONTEM) like '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=           ")"
	_oSQL:_sQuery +=        ") AS CONSPAD"
	_oSQL:Log ()
	_sRetSQL = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sRetSQL)
		_sResult += "Consta na definicao da(s) consulta(s) padrao " +  _sRetSQL + '; '
	endif
	
	// Verifica se consta em algum objeto do SQL
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT rtrim (OBJECT_NAME(sm.object_id)) AS object_name, rtrim (o.type_desc)"
	_oSQL:_sQuery +=  " FROM sys.sql_modules AS sm"
	_oSQL:_sQuery +=       " JOIN sys.objects AS o ON sm.object_id = o.object_id"
	_oSQL:_sQuery += " where sm.definition like '%" + alltrim (_sCampo) + "%' collate SQL_Latin1_General_CP1_CI_AS"
	_oSQL:_sQuery += " ORDER BY o.type"
	_aObjSQL := aclone (_oSQL:Qry2Array ())
	
	for _nObjSQL = 1 to len (_aObjSQL)
		_sResult += " Encontrado no objeto '" + alltrim (_aObjSQL [_nObjSQL, 1]) + "' do SQL (" + alltrim (_aObjSQL [_nObjSQL, 2]) + "); "
	next

	// Verifica se consta em algum batch
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT ZZ6_SEQ + ' - ' + ZZ6_DADOS"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZ6")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND (UPPER(ZZ6_CMD)   LIKE '%" + alltrim (upper (_sCampo)) + "%'"
	_oSQL:_sQuery +=     " OR UPPER(ZZ6_DADOS) LIKE '%" + alltrim (upper (_sCampo)) + "%')"
	_aBatch := aclone (_oSQL:Qry2Array ())
	for _nBatch = 1 to len (_aBatch)
		_sResult += " Encontrado no batch " + _aBatch [_nBatch, 1] + '; '
	next

	// Verifica se consta no historico
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT COUNT (*)"
	_oSQL:_sQuery +=  " FROM VA_USOROT"
	_oSQL:_sQuery += " WHERE ROTINA LIKE '%" + alltrim (upper (_sCampo)) + "%'"
	if _oSQL:RetQry () > 0
		_sResult += " Encontrado em VA_USOROT; '
	endif

	u_help (_sResult)
	if empty (_sResult)
		_sResult = "Nada encontrado aqui."
	endif
	_sResult += " Lembre-se de verificar, tambem:"
	_sResult += " Fontes AdvPl;"
	_sResult += " Arquivos de configuracao de CNAB; "
	_sResult += " Sistema NaWeb; "
	_sResult += " Reporting Services; "
	_sResult += " Arquivos INI de configuracao de regime de processamento de dados; "
	_sResult += " Rotinas de integracao com outros sistemas;"
	_sResult += " PowerBI"

Return _sResult
