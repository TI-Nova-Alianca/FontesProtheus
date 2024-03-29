// Programa...: SD3250I
// Autor......: Leandro Perondi
// Data.......: 11/12/2013
// Descricao..: Ponto de entrada ap�s a confirma��o da produ��o (apontamento de OP)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada ap�s a confirma��o da produ��o (apontamento de OP)
// #PalavasChave      #ponto_de_entrada #apontamento_de_OP 
// #TabelasPrincipais #ZA1 #SD3
// #Modulos           
//
// Historico de alteracoes:
// 03/09/2015 - Robert  - Nao endereca mais automaticamente os produtos.
//                      - Transfere produtos para almox. de integracao com FullWMS quando OP de reprocesso.
// 01/08/2017 - Robert  - Passa a gravar a tabela tb_wms_etiquetas (era feito logo apos a impressao das etiquetas).
// 18/08/2017 - Robert  - Valid.produto na gravacao de etiquetas para FullWMS (tb_wms_etiquetas) - GLPI 2981
//                      - Quando OP de reprocesso assume dt valid do lote original (C2_VADVORI), cfe informada pelo usuario.
//                      - Quando OP normal, calculava dt.valid.=ZA1_DATA+B1_PRVALID. Alterado para C2_DATPRI+B1_PRVALID 
//                        para manter consistencia com a impressao da OP.
// 25/08/2017 - Robert  - Passa a gravar a data de validade como C2_DATPRF+B1_PRVALID nas etiquetas.
// 20/07/2018 - Robert  - Passa a gravar a etiqueta em funcao externa.
//                      - Geracao de laudo do produto acabado com base nos laudos dos produtos consumidos.
// 04/09/2018 - Robert  - Grava za1_apont=S (estava no EnvEtFul.prw)
// 04/08/2021 - Robert  - Removidas chamadas de logs desnecessarias.
// 04/10/2021 - Claudia - Alterada a rotina _AtuReproc. GLPI: 9674
// 01/04/2022 - Robert  - Passa a usar a classe ClsEtiq() para envio da etiqueta para o FullWMS - GLPI 11825.
// 18/04/2022 - Robert  - Incluida chamada para funcao PerfMon().
// 23/03/2023 - Robert  - Deixa de ler parametro VA_ALMFULP (agora fica fixo no programa).
// 20/04/2023 - Robert  - Gravar codigo de motivo de transferencia do ax de reprocesso para 11 (disponibilizar pallet para FullMS)
//                      - Grava evento quando nao conseguir gerar transf.estq.do ax de reprocesso.
// 21/03/2024 - Robert  - Melhoria logs (GLPI 15121)
//

// -----------------------------------------------------------------------------------------------------------------------------------
User Function SD3250I()
	Local _aAreaAnt := U_ML_SRArea ()
	local _oEtiq    := NIL
	
	// Atualiza etiqueta e envia para FullWMS
	if ! empty (M->D3_VAETIQ)
		za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
		if za1 -> (dbseek (xfilial ("ZA1") + m->d3_vaetiq, .F.))
			reclock ("ZA1", .F.)
			za1 -> za1_apont = 'S'
			msunlock ()
			
			// Envia etiqueta para o FullWMS
			_oEtiq := ClsEtiq ():New (m->d3_vaetiq)
			_oEtiq:EnviaFull (.f.)
		endif
	endif

	// Atualizacoes especificas para OP de reprocessamento.
	_AtuReproc ()
	
	// Atualiza laudos/ensaios de laboratorio
//	U_Log2 ('debug', '[' + procname () + ']Vou chamar _AtuLaudo')
	processa ({|| _AtuLaudo ()})
//	U_Log2 ('debug', '[' + procname () + ']Retornou de _AtuLaudo')

	U_ML_SRArea (_aAreaAnt)
Return


// ------------------------------------------------------------------------------------
// Atualizacoes para OP de reprocessamento.
Static Function _AtuReproc ()
	local _sAlmRetr := GetMv ("VA_ALMREPR")
	local _oEvento  := NIL
	
	if fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d3_op, "C2_VAOPESP") == 'R'
		U_Log2 ('info', '[' + procname (1) + '.' + procname () + ']Criando transf.estq. para disponibilizar pallet reprocessado p/ Full')
		_oTrEstq := ClsTrEstq ():New ()
		_oTrEstq:FilOrig   := cFilAnt
		_oTrEstq:FilDest   := cFilAnt
		_oTrEstq:ProdOrig  := m->d3_cod
		_oTrEstq:ProdDest  := m->d3_cod
		_oTrEstq:AlmOrig   := _sAlmRetr
		_oTrEstq:AlmDest   := '11'  //'01'  //_sAlmFull
		_oTrEstq:LoteOrig  := ""
		_oTrEstq:LoteDest  := ""
		_oTrEstq:EndOrig   := ""
		_oTrEstq:EndDest   := ""
		_oTrEstq:OP        := m->d3_op
		_oTrEstq:QtdSolic  := m->d3_perda
		_oTrEstq:CodMotivo := '04'
		// _oTrEstq:Motivo    := "Disponibilizar pallet reprocessado p/ Full"
		_oTrEstq:ImprEtq   := ""
		_oTrEstq:UsrIncl   := cUserName
		_oTrEstq:DtEmis    := m->d3_emissao
		_oTrEstq:Etiqueta  := alltrim(m->d3_vaetiq)
		if ! _oTrEstq:Grava ()
			u_log2 ('erro', '[' + procname (1) + '.' + procname () + ']Nao gravou ZAG. Ultima msg: ' + _oTrEstq:UltMsg)

			// Grava evento para posterior rastreamento.
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven    = 'ZAG001'
			_oEvento:Texto      = _oTrEstq:UltMsg
			_oEvento:Produto    = m->d3_cod
			_oEvento:OP         = m->d3_op
			_oEvento:Etiqueta   = m->d3_vaetiq
			_oEvento:DiasValid  = 180
			_oEvento:Grava ()
		endif
	endif
return


// ------------------------------------------------------------------------------------
// Atualiza laudos/ensaios de laboratorio
static function _AtuLaudo ()
	Local _aAreaAnt := U_ML_SRArea ()
	local _oSQL := NIL
	local _aLotes := {}
	local _nLotes := 0
	local _aLaudos := {}
	local _sLaudo := ""

	procregua (100)
	incproc ("Atualizando laudos laboratoriais.")
	 
	// Busca os laudos dos itens consumidos na OP e gera lista de laudos para depois gerar o laudo do item produzido.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SD3.D3_COD, DB_LOTECTL AS LOTE, SUM (DB_QUANT) AS QUANT"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3") + " SD3,"
	_oSQL:_sQuery +=              RetSQLName ("SDB") + " SDB "
	_oSQL:_sQuery +=  " WHERE SD3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
	_oSQL:_sQuery +=    " AND SD3.D3_OP      = '" + sd3 -> d3_op + "'"
	_oSQL:_sQuery +=    " AND SD3.D3_NUMSEQ  = '" + sd3 -> d3_numseq + "'"  // Para evitar ler outros apontamentos parciais desta mesma OP
	_oSQL:_sQuery +=    " AND SD3.D3_CF      LIKE 'RE%'"
	_oSQL:_sQuery +=    " AND SD3.D3_TIPO    = 'VD'"
	_oSQL:_sQuery +=    " AND SDB.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SDB.DB_FILIAL  = SD3.D3_FILIAL"
	_oSQL:_sQuery +=    " AND SDB.DB_PRODUTO = SD3.D3_COD"
	_oSQL:_sQuery +=    " AND SDB.DB_NUMSEQ  = SD3.D3_NUMSEQ"
	_oSQL:_sQuery +=    " AND SDB.DB_ORIGEM  = 'SC2'"
	_oSQL:_sQuery +=  " GROUP BY SD3.D3_COD, DB_LOTECTL"
	//_oSQL:Log ('[' + procname () + ']')
	_aLotes :=  aclone (_oSQL:Qry2Array (.F., .F.))
	_aLaudos = {}
	for _nLotes = 1 to len (_aLotes)
		_sLaudo = U_LaudoEm (_aLotes [_nLotes, 1], _aLotes [_nLotes, 2], sd3 -> d3_emissao)
		if ! empty (_sLaudo)
			aadd (_aLaudos, {_sLaudo, _aLotes [_nLotes, 3]})
		endif
	next
	//u_log ('Laudos encontrados:', _alaudos)

	// Varre laudos consumidos e gera o laudo do item produzido pela OP
	U_ZAFM (_aLaudos, sd3 -> d3_cod, sd3 -> d3_op, sd3 -> d3_lotectl, sd3 -> d3_local, 'Ensaio gerado pelo apontamento da OP ' + sd3 -> d3_op)

	U_ML_SRArea (_aAreaAnt)
return
