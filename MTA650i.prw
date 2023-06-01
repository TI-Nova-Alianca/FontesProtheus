// Programa...: MTA650I
// Autor......: Robert Koch
// Data.......: 26/06/2014
// Descricao..: P.E. apos inclusao de ordem de producao.
//              Criado inicialmente para gerar etiquetas para pallets.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos inclusao de ordem de producao
// #PalavasChave      #OP #ordem_producao
// #TabelasPrincipais #SC2
// #Modulos           #EST #PCP

// Historico de alteracoes:
// 27/01/2015 - Robert - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT
// 27/04/2015 - Robert - Funcao de alteracao de almox. dos empenhos passada do MTA710OPSC para ca.
// 14/08/2015 - Robert - Removida chamada duplicada da impressao de etiquetas.
// 15/10/2015 - Robert - Nao pergunta mais se o usuario deseja imprimir as etiquetas apos gera-las.
// 05/10/2016 - Robert - Passa a verificar campo B1_APROPRI antes de alterar o almox. dos empenhos.
// 11/05/2017 - Robert - Funcao de ajuste de almox. dos empenhos passa a ser externa.
// 24/08/2017 - Robert - Tratamento para diferenciar ordens de manutencao.
// 17/01/2023 - Robert - Atualiza FullWMS e gera etiquetas somente na filial 01.
// 23/03/2023 - Robert - Alteracao do C2_LOCAL desabilitada pois os gatilhos e
//                       o P.E. MA650TOK jah devem garantir isso.
//                     - Pede confirmacao antes de gerar etiquetas, quando OP 'em terceiros'.
//                     - Chama rotina de impressao das etiquetas geradas.
// 31/05/2023 - Robert - Removidas linhas comentariadas.
//

// --------------------------------------------------------------------------
User Function MTA650I ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _lGeraEtq := .T.

	// Verifica necessidade de alterar empenhos.
	if sc2 -> c2_item != 'OS'
		_AtuEmp ()
	endif

	// Gera etiquetas para pallets (somente na filial 01)
	if cFilAnt == '01' .and. sc2 -> c2_item != 'OS' .and. sc2 -> c2_tpop == 'F'
		if sc2 -> c2_vaopesp == 'E'
			_lGeraEtq = U_MsgYesNo ("OP para envase 'em terceiros': confirme se deseja gerar etiquetas neste momento.")
		endif
		if _lGeraEtq
			processa ({||_GeraEtq ()},"Gerando etiquetas...")
		endif
	endif

	// Se o produto ainda nao existe no almoxarifado destino, cria-o, para nao bloquear a transferencia de estoque.
	sb2 -> (dbsetorder (1))
	if ! sb2 -> (dbseek (xfilial ("SB2") + sc2 -> c2_Produto + sc2 -> c2_local))
		u_log2 ('info', 'Criando SB9 para ' + sc2 -> c2_Produto + '/' + sc2 -> c2_local)
		CriaSB2 (sc2 -> c2_Produto, sc2 -> c2_local)
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return


// ----------------------------------------------------------------------
static function _AtuEmp ()
	local cQuery    := ""

	// Seleciona empenhos das OPs geradas pelo MRP.
	cQuery := " SELECT R_E_C_N_O_, D4_LOCAL, dbo.VA_FLOC_EMP_OP ('" + cFilAnt + "', D4_COD) AS LOCEMP"
	cQuery +=   " FROM " + RetSqlName ("SD4") + " SD4 "
	cQuery +=  " WHERE SD4.D_E_L_E_T_ = '' "
	cQuery +=    " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
	cQuery +=    " AND SD4.D4_OP      = '" + sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd + "'"
	cQuery +=    " AND EXISTS (SELECT *"
	cQuery +=                  " FROM " + RetSqlName ("SB1") + " SB1 "
	cQuery +=                 " WHERE SB1.D_E_L_E_T_  = '' "
	cQuery +=                   " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
	cQuery +=                   " AND SB1.B1_COD      = SD4.D4_COD"
	cQuery +=                   " AND SB1.B1_APROPRI != 'I')"
	DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRB", .F., .T.)
	dbselectarea("TRB")
	dbgotop()
	While !EoF()
		if trb -> d4_local != trb -> locemp
			sd4 -> (dbgoto (trb -> R_E_C_N_O_))
			U_AjLocEmp (trb -> locemp)
		endif
		trb -> (dbskip())
	EndDo
	trb -> (dbclosearea())
	dbselectarea ("SC2")
return


// ------------------------------------------------------------------------------------
// Gera etiquetas para pallets.
static function _GeraEtq ()
	local _nQtEtqGer := 0
	_nQtEtqGer = U_EtqPllGO (sc2 -> c2_produto, sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd, sc2 -> c2_quant, sc2 -> c2_datprf)
	if _nQtEtqGer > 0
		if U_MsgYesNo ("Deseja imprimir agora as " + cvaltochar (_nQtEtqGer) + " etiquetas geradas?")
			U_EtqPlltG (sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd, '', '', '', '', 'I')
		endif
	endif
return
