// Programa....: sf1100e
// Autor.......: ?
// Data........: 29/08/06
// Descricao...: PE antes da exclusao da nota fiscal de entrada

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada antes da exclusao de nota fiscal de entrada. Permite gravacoes adicionais.
// #PalavasChave      #ponto_de_entrada
// #TabelasPrincipais #SF1 #SD1
// #Modulos           #EST #COM

// Historico de alteracoes:
// 12/05/2008 - Robert  - Incluida chamada para funcao de tratamento de controle de fretes.
// 20/08/2008 - Robert  - Limpeza do S Z H passa a ser feita pelo FrtNFE.
// 04/09/2008 - Robert  - Limpeza do ZZ4.
// 10/03/2009 - Robert  - Criado tratamento para controle de transferencias para depositos externos.
// 11/08/2011 - Robert  - Tratamento para exclusao do SZI.
// 13/10/2011 - Robert  - Passa a usar a funcao VA_ZZ4E para limpeza do ZZ4.
// 11/05/2012 - Robert  - Passa a considerar especie CTE da mesma forma que CTR.
// 14/09/2012 - Robert  - Nao considerava o D3_COD na busca do registro de transf. entre depositos a ser estornado.
// 30/09/2012 - Robert  - Criados campos D3_VANFRD, D3_VASERRD e D3_VAITNRD para substituir o D3_VACHVEX no controle de armazens externos.
// 24/06/2013 - Robert  - Tratamento de armazem passa a usar a classe ClsAmzGer.
//                      - Cancelamento remessa para armazem geral passa a ser via batch. 
// 15/01/2014 - Leandro DWT - grava evento para histórico de NF
// 11/05/2015 - Robert  - Tratamento para devolucoes/cancelamentos (arquivo ZAB).
// 21/10/2015 - Robert  - Atualiza status na tabela ZZX.
// 28/10/2015 - Robert  - Limpa memos do f1_vacmemc e f1_vacmemf.
// 20/04/2016 - Robert  - Limpava apenas um registro do SZI. Agora faz loop nos registros (NF pode ter gerado mais de uma parcela).
//                      - Valida parametro VA_AMZGER.
// 14/06/2016 - Catia   - excluir os lançamentos contabeis quando excluir o documento de entrada
// 23/01/2018 - Catia   - excluir titulo de indenizacao de comissoes
// 14/02/2018 - Catia   - passar a solicitar o motivo da exclusao do documento de entrada
// 17/04/2018 - Robert  - Deixa de chamar o VA_ZZ4E pois os dados adicionais foram migrados para campos memo no SF1.
// 02/05/2018 - Robert  - Desabilitada rotina de armazem externo (nunca chegamos a usar)
// 03/05/2018 - Robert  - Desabilitados tratamentos do ZAB (devolucoes de clientes).
// 08/04/2019 - Catia   - Include "TbiConn.ch"
// 10/05/2019 - Catia   - tira include protheus #Include "Protheus.ch" pq dava conflito com a "rwmake.ch" - e nao permitia digitar a justificativa
// 14/05/2019 - Catia   - Algumas notas nao estavam excluindo na contabilidade
// 03/06/2020 - Robert  - Criado tratamento para exclusao de contranotas de comprea de uva (atualiza ZZ9 e SZI).
// 28/09/2020 - Robert  - Quando nao informado motivo de exclusao na primeira vez, a variavel ficava com tamanho zero e nao permitia mais digitar.
//                      - Inseridas tags para catalogo de programas.
// 03/02/2021 - Robert  - Soh verificava necessidade de limpar SZE quando serie 30. Agora verifica para qualquer serie.
// 17/11/2022 - Claudia - Incluido estorno de rapel.
// 16/12/2022 - Robert  - Comentariado trecho sem efeito que faria leituras do Mercanet.
//                      - Ajustadas algumas chamadas de log e acrescentado parametro .T. em chamadas de u_help.
// 12/01/2023 - Robert  - Grava na carga de safra um evento de cancelamento de contranota.
// 24/04/2023 - Claudia - Retiradas as notas de formulario próprio e serie 99. GLPI: 13474
// 12/03/2024 - Robert  - Limpar tabela SZH quando contranota de complemento de safra.
//                      - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// -----------------------------------------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"  
//#Include "TbiConn.ch"

User Function sf1100e()
	local _aAreaAnt := U_ML_SRArea ()
	local _sMotExc  := ''

	// solicita motivo de exclusao do documento - obrigatorio
	_sMotExc = "  "
	do while empty (_sMotExc)
		_sMotExc = "  "
		_sMotExc = U_Get ("Motivo Exclusao Documento Entrada", "C", 2, "@!", "ZX548" , _sMotExc, .F., '.T.')
		if empty (_sMotExc)
			loop
		endif
		_sQuery  = ""
		_sQuery += " SELECT ZX5_48DESC"
		_sQuery += "   FROM ZX5010"
		_sQuery += "  WHERE ZX5_TABELA  = '48'"
		_sQuery += "    AND ZX5_48ATIV != 'N'"
		_sQuery += "    AND ZX5_48MOT   = '" + _sMotExc + "'" 
		
		_aDados := U_Qry2Array(_sQuery)
		
		if len (_aDados) = 0
			u_help ("Motivo de Exclusao de documento de entrada não cadastrado ou inativo",, .t.)
			loop
		else
			_sJustif = ""
			do while empty (_sJustif)
				_sJustif := space (250)
				define MSDialog _oDlgJust from 0, 0 to 150, 500 of oMainWnd pixel title "Justificativa"
				@ 10, 10 say "Justifique a exclusao da nota " + sf1 -> f1_doc
				@ 30, 10 get _sJustif size 200, 11
				@ 45, 10 bmpbutton type 1 action (_oDlgJust:End ())
				activate MSDialog _oDlgJust centered
			enddo
		endif
	enddo
	
	// grava tabela de documentos excluidos
	DbSelectArea("ZBA")
	DbSetOrder(1)
	RecLock("ZBA", .T.)
		ZBA->ZBA_FILIAL  = SF1 -> F1_FILIAL
		ZBA->ZBA_DATA    = date()
        ZBA->ZBA_HORA    = time()
        ZBA->ZBA_USER    = cusername
        ZBA->ZBA_MOT     = _sMotExc 
        ZBA->ZBA_JUSTIF  = alltrim(_sJustif)
		ZBA->ZBA_CHAVE   = SF1 -> F1_CHVNFE
		ZBA->ZBA_DOC     = SF1 -> F1_DOC
		ZBA->ZBA_SERIE   = SF1 -> F1_SERIE
		ZBA->ZBA_ESPEC   = SF1 -> F1_ESPECIE
		ZBA->ZBA_FORNECE = SF1 -> F1_FORNECE
		ZBA->ZBA_LOJA    = SF1 -> F1_LOJA
	MsUnLock()

	// Tratamento de controle de fretes.
	if alltrim (sf1 -> f1_especie) $ "CTR/CTE/NF"
		U_FrtNFE ("E")
	endif

	// Elimina dados adicionais da nota.
	if ! empty (sf1 -> f1_vacmemc)
		msmm (sf1 -> f1_vacmemc,,,, 2,,, "SF1", "F1_VACMEMC")
	endif
	if ! empty (sf1 -> f1_vacmemf)
		msmm (sf1 -> f1_vacmemf,,,, 2,,, "SF1", "F1_VACMEMF")
	endif

	// Tratamento para NF de entrada de safra.
	_NFSafra ()

	// Tratamento para conta corrente de associados.
	_AtuSZI ()
	
	// grava evento para histórico de NF, caso seja devolução
	if sf1 -> f1_tipo $ "D/B"
		_HistNf ()
	endif

	// Atualiza status na tabela ZZX (XML de NF de entrada).
	_AtuZZX ()
	
	// verifica titulos de indenização
	if sf1 -> f1_tipo = "N" .and. sf1 -> f1_especie != 'SPED' .and. sf1 -> f1_especie != 'CTE' .and. sf1 -> f1_especie != 'CTR'
		_VerInd()
	endif		
	
	// Exclui lcto contabil
	_ExcCTB ()

	// Tratamento para conta corrente rapel
	If GetMV('VA_RAPEL')
		_AtuZC0() 			 
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Controles referentes a NF de entrada de safra.
static function _NFSafra ()
	local _oSQL    := NIL
	local _oCarSaf := NIL

	if sf1 -> f1_formul == "S" .and. sf1 -> f1_vasafra != ''

		// Se encontrar este docto como uma contranota de entrada...
		sze -> (dbsetorder (3))  // ZE_FILIAL+ZE_NFGER+ZE_SERIE
		if sze -> (dbseek (xfilial ("SZE") + sf1 -> f1_doc + sf1 -> f1_serie, .F.))
			// ... limpa o numero da contranota do arquivo de recebimentos de safra.
			reclock ("SZE", .F.)
			sze -> ze_nfger = ""
			sze -> ze_serie = ""
			sze -> ze_status = "2"
			msunlock ()

			// Instancia e grava evento na carga
			_oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
			_oCarSaf:GrvEvt ('SZE005', 'Exclusao contranota ' + sf1 -> f1_doc)
		endif

		// Se encontrar este docto como uma contranota de compra, 
		// limpa o numero da contranota do arquivo de pre-notas
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "UPDATE " + RetSQLName ("ZZ9")
		_oSQL:_sQuery +=   " SET ZZ9_NFCOMP   = '', ZZ9_SERCOM = ''"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZZ9_FILIAL   = '" + sf1 -> f1_filial  + "'"
		_oSQL:_sQuery +=   " AND ZZ9_SAFRA    = '" + sf1 -> f1_vasafra + "'"
		_oSQL:_sQuery +=   " AND ZZ9_NFCOMP   = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery +=   " AND ZZ9_SERCOM   = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery +=   " AND ZZ9_FORNEC   = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND ZZ9_LOJA     = '" + sf1 -> f1_loja    + "'"
		if ! _oSQL:Exec ()
			u_help ("Erro ao atualizar a tabela ZZ9 (pre-notas de compra de safra). Verifique!", _oSQL:_sQuery, .t.)
		endif

		// Limpa este docto dos rateios de NF entrada (usado para relacionar
		// as notas de complemento com as notas originais)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "UPDATE " + RetSQLName ("SZH")
		_oSQL:_sQuery +=   " SET D_E_L_E_T_ = '*'
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''
		_oSQL:_sQuery +=   " AND ZH_FILIAL  = '" + xfilial ("SZH") + "'"
		_oSQL:_sQuery +=   " AND ZH_NFSAIDA = 'SAFRA" + sf1 -> f1_vasafra + "'"
		_oSQL:_sQuery +=   " AND ZH_NFFRETE = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery +=   " AND ZH_SERFRET = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery +=   " AND ZH_FORNECE = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND ZH_LOJA    = '" + sf1 -> f1_loja    + "'"
		_oSQL:_sQuery +=   " AND ZH_TPDESP  = 'S'"  // 'S' = rateio de safra
		if ! _oSQL:Exec ()
			u_help ("Erro ao atualizar a tabela SZH (NF complem X NF orig. de safra). Verifique!", _oSQL:_sQuery, .t.)
		endif

	endif
return
//
// --------------------------------------------------------------------------
// Atualiza arquivo de conta corrente de associados, quando for o caso.
static function _AtuSZI ()
	local _oCtaCorr   := NIL
	local _oSQL       := NIL
	local _aRecnos    := {}
	local _nRecno     := 0

	// Se for nota de compra de safra, gerou movimento na conta corrente de associados.
	if sf1 -> f1_formul == 'S'
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT R_E_C_N_O_"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZI_FILIAL  = '" + xfilial ("SZI") + "'"
		_oSQL:_sQuery +=   " AND ZI_TM      = '13'"
		_oSQL:_sQuery +=   " AND ZI_DATA    = '" + dtos (sf1 -> f1_emissao) + "'"
		_oSQL:_sQuery +=   " AND ZI_ASSOC   = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND ZI_LOJASSO = '" + sf1 -> f1_loja + "'"
		_oSQL:_sQuery +=   " AND ZI_DOC     = '" + sf1 -> f1_doc + "'"
		_oSQL:_sQuery +=   " AND ZI_SERIE   = '" + sf1 -> f1_serie + "'"
		_aRecnos := aclone (_oSQL:Qry2Array (.f., .f.))
		for _nRecno = 1 to len (_aRecnos)
			_oCtaCorr = ClsCtaCorr():New (_aRecnos [_nRecno, 1])
			if ! _oCtaCorr:Exclui ()
				u_help ("Nao foi possivel excluir da conta corrente de associados a movimentacao gerada por esta nota fiscal. Revise a conta corrente do associado '" + sf1 -> f1_fornece + "'.",, .t.)
			endif
		next
	endif
return
//
// --------------------------------------------------------------------------
// Verifica se existem titulos de indenizacao
Static Function _Verind()
	_sSQL := ""
	_sSQL += " SELECT A3_COD"
	_sSQL += " from " + RetSQLName ("SA3") + " SA3"
	_sSQL += " where SA3.D_E_L_E_T_ != '*'"
	_sSQL +=   " AND SA3.A3_FILIAL   = '" + xfilial ("SA3") + "'"
	_sSQL +=   " AND SA3.A3_FORNECE  = '" + sf1 -> f1_fornece + "'"
	_sSQL +=   " AND SA3.A3_LOJA     = '" + sf1 -> f1_loja + "'"
	_sSQL +=   " AND SA3.A3_MSBLQL != '1'"
	_sSQL +=   " AND SA3.A3_ATIVO  != 'N'"
	_sVend = U_Qry2Array(_sSQL)
	
	if len (_sVend) > 0
		// Encontra titulo ref a indenizacao
		_sSQL := ""
		_sSQL +=    "  SELECT R_E_C_N_O_"
		_sSQL +=    "    FROM SE2010"
		_sSQL +=    "   WHERE D_E_L_E_T_ = ''"
		_sSQL +=    "     AND E2_FILIAL  = '" + xfilial ("SE2")   + "'"
		_sSQL +=    "     AND E2_FORNECE = '" + sf1 -> f1_fornece + "'"
		_sSQL +=    "     AND E2_LOJA    = '" + sf1 -> f1_loja    + "'"
		_sSQL +=    "     AND E2_NUM     = '" + sf1 -> f1_doc     + "'"
		_sSQL +=    "     AND E2_PREFIXO = 'IND'"
		_sSQL +=    "     AND E2_ORIGEM  = 'CUST'"
		_sSQL +=    "     AND E2_NATUREZ = '120312'"
		_sSQL +=    "     AND E2_CODRET  = '9385'"
		_sTitInd = U_Qry2Array(_sSQL)
		
		if len (_sTitInd) > 0
			_sSQL := ""
			_sSQL +=   " UPDATE SE2010"
			_sSQL +=   "    SET D_E_L_E_T_ = '*'
			_sSQL +=   "      , R_E_C_D_E_L_ = R_E_C_N_O_" 
			_sSQL +=   "  WHERE D_E_L_E_T_ = ''"
			_sSQL +=    "   AND E2_FILIAL  = '" + xfilial ("SE2")   + "'"
			_sSQL +=    "   AND E2_FORNECE = '" + sf1 -> f1_fornece + "'"
			_sSQL +=    "   AND E2_LOJA    = '" + sf1 -> f1_loja    + "'"
			_sSQL +=    "   AND E2_NUM     = '" + sf1 -> f1_doc     + "'"
			_sSQL +=    "   AND E2_PREFIXO = 'IND'"
			_sSQL +=    "   AND E2_ORIGEM  = 'CUST'"
			_sSQL +=    "   AND E2_NATUREZ = '120312'"
			_sSQL +=    "   AND E2_CODRET  = '9385'"
			if TCSQLExec (_sSQL) < 0
	            u_showmemo(_sSQL)
	            return
	        endif
		endif
		
		// busca titulo filho referente ao IR no fornecedor 00796
		_sSQL := ""
		_sSQL +=    "  SELECT R_E_C_N_O_"
		_sSQL +=    "    FROM SE2010"
		_sSQL +=    "   WHERE D_E_L_E_T_ = ''"
		_sSQL +=    "     AND E2_FILIAL  = '" + xfilial ("SE2")   + "'"
		_sSQL +=    "     AND E2_FORNECE = '000796'
		_sSQL +=    "     AND E2_LOJA    = '00'
		_sSQL +=    "     AND E2_NUM     = '" + sf1 -> f1_doc     + "'"
		_sSQL +=    "     AND E2_PREFIXO = 'IND'"
		_sSQL +=    "     AND E2_TIPO    = 'TX'"
		_sSQL +=    "     AND E2_ORIGEM  = 'CUST'"
		_sSQL +=    "     AND E2_NATUREZ = 'IRF'"
		_sSQL +=    "     AND E2_CODRET  = '9385'"
		_sTitIRInd = U_Qry2Array(_sSQL)
		
		if len (_sTitIRInd) > 0
			_sSQL := ""
			_sSQL +=   " UPDATE SE2010"
			_sSQL +=   "    SET D_E_L_E_T_ = '*'
			_sSQL +=   "      , R_E_C_D_E_L_ = R_E_C_N_O_" 
			_sSQL +=  "   WHERE D_E_L_E_T_ = ''"
			_sSQL +=    "   AND E2_FILIAL  = '" + xfilial ("SE2")   + "'"
			_sSQL +=    "     AND E2_FORNECE = '000796'
			_sSQL +=    "     AND E2_LOJA    = '00'
			_sSQL +=    "     AND E2_NUM     = '" + sf1 -> f1_doc     + "'"
			_sSQL +=    "     AND E2_PREFIXO = 'IND'"
			_sSQL +=    "     AND E2_TIPO    = 'TX'"
			_sSQL +=    "     AND E2_ORIGEM  = 'CUST'"
			_sSQL +=    "     AND E2_NATUREZ = 'IRF'"
			_sSQL +=    "     AND E2_CODRET  = '9385'"
		
			if TCSQLExec (_sSQL) < 0
	            u_showmemo(_sSQL)
	            return
	        endif
		endif				        		
	endif	
return
//
// --------------------------------------------------------------------------
// Histórico 
Static Function _HistNf()
	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SZN001"
	_oEvento:Texto	  = "Exclusão de Devolucao de Nota Fiscal"
	_oEvento:NFSaida	  = sd1 -> d1_nfori
	_oEvento:SerieSaid = sd1 -> d1_seriori
	_oEvento:NFEntrada = sf1 -> f1_doc
	_oEvento:SerieEntr = sf1 -> f1_serie
	_oEvento:PedVenda  = ""
	_oEvento:Cliente   = sf1 -> f1_fornece
	_oEvento:LojaCli   = sf1 -> f1_loja
	_oEvento:Hist	  = "1"
	_oEvento:Status	  = "9"
	_oEvento:Sub	  	  = ""
	_oEvento:Prazo	  = 0
	_oEvento:Flag	  = .T.
	_oEvento:Grava ()
Return
//
// --------------------------------------------------------------------------
// Atualiza status na tabela ZZX.
static function _AtuZZX ()
	local _oSQL      := NIL

	if ! empty (sf1 -> f1_chvnfe)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZZX")
		_oSQL:_sQuery +=    " SET ZZX_STATUS = '3'"  // 1=NF gerada no SF1;2=Pre-NF gerada no SF1;3=NF excluida no SF1
		_oSQL:_sQuery +=  " WHERE ZZX_CHAVE  = '" + sf1 -> f1_chvnfe + "'"
		_oSQL:_sQuery +=    " AND D_E_L_E_T_ = ''"
		_oSQL:Log ('[' + procname () + ']')
		_oSQL:Exec ()
	endif

return
//
// -----------------------------------------------------
// Exclui Lançamento contabil referente a contabilização
static function _ExcCTB ()
	local i := 0
	
	_wkey = '%' + xfilial ("SF1") + sf1 -> f1_doc + sf1 -> f1_serie +  sf1 -> f1_fornece + sf1 -> f1_loja + '%'
	// busca lactos contabeis referentes a NF
	_sSQL := ""
    _sSQL += " SELECT CT2_LOTE, CT2_SBLOTE, CT2_DOC, CT2_KEY, CT2_LINHA, CT2_DC, CT2_DEBITO, CT2_CREDIT, CT2_VALOR, CT2_CCD, CT2_CCC, CT2_ORIGEM, CT2_DATA"
	_sSQL += "   FROM CT2010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''" 
 	_sSQL += "    AND CT2_FILIAL = '" + xfilial ("SF1") + "'"
   	_sSQL += "    AND CT2_DATA   = '" + dtos (sf1 -> f1_dtdigit) + "'"
   	_sSQL += "    AND CT2_ROTINA = 'MATA103'"
   	_sSQL += "    AND CT2_KEY  LIKE '" + _wkey + "'"
  
    _aExcluir := U_Qry2Array(_sSQL)
	// le cada um dos lctos e monta _aAutoCT2
	if len(_aExcluir) > 0
		_aAutoCT2C := {}
		_aAutoCT2I := {}
	    aAdd (_aAutoCT2C,  {'DDATALANC'     ,  _aExcluir[1,13]   ,NIL} )
	    aAdd (_aAutoCT2C,  {'CLOTE'         ,  _aExcluir[1,1]    ,NIL} )
	    aAdd (_aAutoCT2C,  {'CSUBLOTE'      ,  _aExcluir[1,2]    ,NIL} )
	    aAdd (_aAutoCT2C,  {'CDOC'          ,  _aExcluir[1,3]    ,NIL} )
	    // le cada um dos lctos e monta _aAutoCT2
	    for i=1 to len(_aExcluir)
			_aLinhaCT2 := {}
		    aAdd (_aLinhaCT2,  {'CT2_LINHA'     , _aExcluir[1,5]    , NIL})
		    aAdd (_aLinhaCT2,  {'CT2_DC'        , _aExcluir[1,6]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_DEBITO'    , _aExcluir[1,7]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_CREDIT'    , _aExcluir[1,8]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_VALOR'     , _aExcluir[1,9]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_CCD'       , _aExcluir[1,10]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_CCC'       , _aExcluir[1,11]  	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_ORIGEM'    , _aExcluir[1,12]  	, NIL})
		    aAdd (_aAutoCT2I, aclone (_aLinhaCT2))
		next
		_sErroAuto  := ""
		lMSErroAuto := .F.
		MSExecAuto({|x, y,z| CTBA102(x,y,z)}, _aAutoCT2C ,_aAutoCT2I, 5)
		
		if lMSErroAuto
			_sErro := memoread (NomeAutoLog ()) + chr (13) + chr (10) + _sErroAuto
			u_help (_sErro,, .t.)
		endif
	endif
	_wkey = '%' + xfilial ("SF1") + "IND"+ sf1 -> f1_doc+ '%'
	// busca lactos contabeis referentes a 1/12 - titulos de indenizacao comissoes
	_sSQL := ""
    _sSQL += " SELECT CT2_LOTE, CT2_SBLOTE, CT2_DOC, CT2_KEY, CT2_LINHA, CT2_DC, CT2_DEBITO, CT2_CREDIT, CT2_VALOR, CT2_CCD, CT2_CCC, CT2_ORIGEM, CT2_DATA"
	_sSQL += "   FROM CT2010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''" 
 	_sSQL += "    AND CT2_FILIAL = '" + xfilial ("SF1") + "'"
   	_sSQL += "    AND CT2_DATA   = '" + dtos (sf1 -> f1_dtdigit) + "'"
   	_sSQL += "    AND CT2_ROTINA = 'FINA050'"
   	_sSQL += "    AND CT2_KEY  LIKE '" + _wkey + "'"
   
    _aExcluir := U_Qry2Array(_sSQL)
	// le cada um dos lctos e monta _aAutoCT2
	if len(_aExcluir) > 0
		_aAutoCT2C := {}
		_aAutoCT2I := {}
	    aAdd (_aAutoCT2C,  {'DDATALANC'     ,  _aExcluir[1,13]    ,NIL} )
	    aAdd (_aAutoCT2C,  {'CLOTE'         ,  _aExcluir[1,1]     ,NIL} )
	    aAdd (_aAutoCT2C,  {'CSUBLOTE'      ,  _aExcluir[1,2]     ,NIL} )
	    aAdd (_aAutoCT2C,  {'CDOC'          ,  _aExcluir[1,3]     ,NIL} )
	    // le cada um dos lctos e monta _aAutoCT2
	    for i=1 to len(_aExcluir)
			_aLinhaCT2 := {}
		    aAdd (_aLinhaCT2,  {'CT2_LINHA'     , _aExcluir[1,5]    , NIL})
		    aAdd (_aLinhaCT2,  {'CT2_DC'        , _aExcluir[1,6]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_DEBITO'    , _aExcluir[1,7]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_CREDIT'    , _aExcluir[1,8]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_VALOR'     , _aExcluir[1,9]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_CCD'       , _aExcluir[1,10]	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_CCC'       , _aExcluir[1,11]  	, NIL})
		    aAdd (_aLinhaCT2,  {'CT2_ORIGEM'    , _aExcluir[1,12]  	, NIL})
		    aAdd (_aAutoCT2I, aclone (_aLinhaCT2))
		next
		_sErroAuto  := ""
		lMSErroAuto := .F.
		MSExecAuto({|x, y,z| CTBA102(x,y,z)}, _aAutoCT2C ,_aAutoCT2I, 5)
		
		if lMSErroAuto
			_sErro := memoread (NomeAutoLog ()) + chr (13) + chr (10) + _sErroAuto
			u_help (_sErro,, .t.)
		endif
	endif		
return


// --------------------------------------------------------------------------
// Debita rapel da NF de devolução
Static Function _AtuZC0()
	Local _x := 0
	Local _i := 0

	If alltrim(sf1 -> f1_serie) == '99' .and. alltrim(sf1 -> f1_formul) == 'S'
		// Notas de acerto de estoque
	Else
		_oSQL:= ClsSQL():New()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery +=   " SELECT "
		_oSQL:_sQuery +=   "     D1_FILIAL "
		_oSQL:_sQuery +=   "    ,D1_NFORI "
		_oSQL:_sQuery +=   "    ,D1_SERIORI "
		_oSQL:_sQuery +=   "    ,D1_ITEMORI "
		_oSQL:_sQuery +=   " 	,D1_COD "
		_oSQL:_sQuery +=   "    ,D1_QUANT "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1 "
		_oSQL:_sQuery +=   " WHERE D_E_L_E_T_   = '' "
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL  = '" + sf1 -> f1_filial  + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_FORNECE = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOJA    = '" + sf1 -> f1_loja    + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_DOC     = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_SERIE   = '" + sf1 -> f1_serie   + "'"
		_aNfDev := aclone (_oSQL:Qry2Array (.f., .f.))

		For _x:=1 to Len(_aNfDev)
			_oSQL:= ClsSQL():New()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery +=   " SELECT "
			_oSQL:_sQuery +=   " 	 D2_ITEM "
			_oSQL:_sQuery +=   "    ,D2_COD "
			_oSQL:_sQuery +=   "    ,D2_QUANT "
			_oSQL:_sQuery +=   "    ,D2_RAPEL "
			_oSQL:_sQuery +=   "    ,D2_VRAPEL "
			_oSQL:_sQuery +=   "    ,D2_CLIENTE "
			_oSQL:_sQuery +=   "    ,D2_LOJA"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD2") 
			_oSQL:_sQuery +=   " WHERE D_E_L_E_T_= '' "
			_oSQL:_sQuery +=   " AND D2_FILIAL   = '"+ _aNfDev[_x, 1] + "' "
			_oSQL:_sQuery +=   " AND D2_DOC      = '"+ _aNfDev[_x, 2] + "' "
			_oSQL:_sQuery +=   " AND D2_SERIE    = '"+ _aNfDev[_x, 3] + "' "
			_oSQL:_sQuery +=   " AND D2_COD      = '"+ _aNfDev[_x, 5] + "' "
			_aNfVen := aclone (_oSQL:Qry2Array (.f., .f.))

			For _i:=1 to Len(_aNfVen)
				_oCtaRapel := ClsCtaRap():New ()
				_sRede     := _oCtaRapel:RetCodRede(_aNfVen[_i, 6], _aNfVen[_i, 7])
				_sTpRapel  := _oCtaRapel:TipoRapel(_aNfVen[_i, 6], _aNfVen[_i, 7])

				If alltrim(_sTpRapel) <> '0' // Se o cliente tem configuração de rapel
					_nRapVen := _aNfVen[_i, 5]
					_nQtdVen := _aNfVen[_i, 3]
					_nQtdDev := _aNfDev[_x, 6] 
					_sProd   := _aNfVen[_i, 2]

					If _nQtdDev == _nQtdVen // Se as quantidades de venda e devolução for igual, desconta 100% do valor	
						_nRapel := _nRapVen
						_sHist  := 'Estorno de rapel por devolução de NF 100%' 
					else					// Rapel proporcional
						_nRapelDev := _nRapVen * _nQtdDev / _nQtdVen
						_nRapel    := _nRapelDev
						_sHist     := 'Estorno de rapel por devolução de NF parcial' 
					EndIf					

					_oCtaRapel:Filial  	 = sf1 -> f1_filial
					_oCtaRapel:Rede      = _sRede	
					_oCtaRapel:LojaRed   = sf1 -> f1_loja
					_oCtaRapel:Cliente 	 = sf1 -> f1_fornece 
					_oCtaRapel:LojaCli	 = sf1 -> f1_loja
					_oCtaRapel:TM      	 = '07' 	
					_oCtaRapel:Data    	 = ddatabase//date()
					_oCtaRapel:Hora    	 = time()
					_oCtaRapel:Usuario 	 = cusername 
					_oCtaRapel:Histor  	 = _sHist
					_oCtaRapel:Documento = sf1 -> f1_doc
					_oCtaRapel:Serie 	 = sf1 -> f1_serie
					_oCtaRapel:Parcela	 = ''
					_oCtaRapel:Produto	 = _sProd
					_oCtaRapel:Rapel	 = _nRapel
					_oCtaRapel:Origem	 = 'SF1100E'
					_oCtaRapel:NfEmissao = sf1 -> f1_emissao

					If _oCtaRapel:Grava (.F.)
						_oEvento := ClsEvent():New ()
						_oEvento:Alias     = 'ZC0'
						_oEvento:Texto     = "Estorno rapel "+ sf1 -> f1_doc + "/" + sf1 -> f1_serie
						_oEvento:CodEven   = 'ZC0001'
						_oEvento:Cliente   = sf1 -> f1_fornece 
						_oEvento:LojaCli   = sf1 -> f1_loja
						_oEvento:NFSaida   = sf1 -> f1_doc
						_oEvento:SerieSaid = sf1 -> f1_serie
						_oEvento:Grava()
					EndIf
				EndIf
			Next
		Next
	EndIf
Return
