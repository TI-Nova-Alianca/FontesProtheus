// Programa:  SF1100i
// Autor:     Robert Koch
// Data:      05/06/2008
// Descricao: P.E. apos a gravacao do SF1 na NF de entrada.
//            Criado, inicialmente, para tratamento de titulos de substituicao tributaria.
//
// Historico de alteracoes:
// 04/09/2008 - Robert  - Gravacao de dados adicionais no arquivo ZZ4.
// 18/09/2008 - Robert  - Revisao rotina gravacao titulo NCC ref. ST.
// 13/01/2009 - Robert  - Criada tela para informacao de dados adicionais.
// 15/01/2009 - Robert  - Inclusao cod. viticola nas inf.adic. quando NF entrada safra.
// 28/01/2009 - Robert  - Inclusao peso tara nas inf.adic. quando NF entrada safra.
// 26/02/2009 - Robert  - Desabilitada geracao de titulo NCC ref. ST nas devolucoes.
// 09/03/2009 - Robert  - Criado tratamento para transferencia de armazem geral (cfe. TES)
// 13/03/2009 - Robert  - Passa a gravar insc.ST no ZZ4 para MG.
// 07/05/2009 - Robert  - Criada funcao _GrvCpAdic ().
//                      - Melhorada tela de dados adicionais (criados campos F1_vaPlVei e F1_vaNfPro).
// 24/06/2009 - Robert  - Novo numero de regime especial (16.000178297-01) para o estado de MG.
// 17/09/2009 - Robert  - Novo parametro para a funcao GrvDupST (embora esteja desabilitada neste programa).
// 19/01/2009 - Robert  - Compatibilizado com versao DBF.
// 15/02/2009 - Robert  - Passa a olhar a tabela 03 do ZX5 em vez da tabela 77 do SX5.
// 18/02/2010 - Robert  - Leitura do D1_OBS para dados adicionais implementado em DBF (soh fazia em TOP).
//                      - Gravacao do E2_HIST quando NF de compra de lenha.
// 19/02/2010 - Robert  - Gravacao de dados adicionais para notas de importação.
// 22/02/2010 - Robert  - Na tela de dados adicionais listava nome do fornecedor, mesmo sendo NF do tipo B ou D.
// 06/06/2010 - Robert  - Incluida chamada do A260Comum depois da chamada do A260Processa.
// 15/12/2010 - Robert  - Criado tratamento para campo ZX5_MODO.
// 27/12/2010 - Robert  - Desabilitada leitura do arquivo ZZ2 para impressao de mensagem de S.T.
// 11/01/2010 - Robert  - Desabilitada geracao de dados adicionais para NF de
//                       entrada de safra, pois jah vem pronto da respectiva rotina.
// 17/03/2011 - Robert  - Montagem das mensagens adicionais parra a usar a funcao _SomaMsg ().
//                      - Incluido tratamento para os campos F1_MENPAD e F1_MENNOTA, se existirem.
// 30/11/2011 - Robert  - Gravacao do campo E2_vaLenha.
// 16/02/2012 - Robert  - Gravacao do campo f1_vaSePro.
//                      - Pede confirmacao para deixar NF de produtor em branco.
// 15/03/2012 - Robert  - Verifica se tem NF de produtor rural sem inscricao estadual.
// 22/06/2012 - Robert  - Implementadas verificacoes ref. obra planta nova.
// 04/07/2012 - Robert  - Gravacao do campo E2_VAOBRA.
// 30/09/2012 - Robert  - Criados campos D3_VANFRD, D3_VASERRD e D3_VAITNRD para substituir o D3_VACHVEX no controle de armazens externos.
// 03/10/2012 - Robert  - Movto. retorno armazem externo passa a ser feito via rotina em batch.
// 05/03/2013 - Elaine  - Inclusao de tratamento quando associado, criar conta corrente
// 24/06/2013 - Robert  - Tratamento de armazem passa a usar a classe ClsAmzGer.
// 18/09/2013 - Leandro - Verifica se foram gravados títulos com data anterior à data base
// 27/09/2013 - Leandro - Grava informações adicionais na tabela SF1 e não mais na tabela ZZ4
// 04/12/2013 - Leandro - Envia e-mail para responsáveis caso seja uma devoluçao de uma nota embarcada pelas filiais 04, 14 ou 15
// 15/01/2014 - Leandro - grava evento para histórico de NF
// 17/06/2014 - Robert  - Envia e-mail de aviso ao digitar NF devolucao alm. 91
// 14/01/2015 - Catia   - Gravar o usuário que gerou a NF
// 09/02/2015 - Robert  - Enviar e-mail de aviso "seu pedido chegou" ao solicitante.
// 04/03/2015 - Robert  - Incluida chamada de funcao para impressao de romaneio de entrada.
// 08/05/2015 - Robert  - Gravacao dos campos F1_VADTINC e F1_VAHRINC.
// 09/06/2015 - Catia   - Rotina para enviar email se forem recebidos dispensadoras de suco
// 12/06/2015 - Catia   - geracao de email com data de vencimento menor que data base alterado para que seja menor que a DATA ATUAL (date())
// 30/06/2015 - Robert  - Removido tratamento para inscricao de substituto tributario (vamos usar pelo padrao do sistema)
// 19/08/2015 - Catia   - alterada rotina de geração de emails, que estava relacionando titulos de outros fornecedores
// 11/09/2015 - Catia   - função dispensers - alterado para que nao considere conhecimentos de frete
// 03/10/2015 - Robert  - Melhorado e-mail 'seu pedido chegou' (aviso ao solicitante).
// 21/10/2015 - Robert  - Atualiza status na tabela ZZX.
// 02/02/2016 - Catia   - Ajustes da rotina de geracao de emails de referente a gestao ambiental - produtos controlados policia federal
// 08/02/2016 - Catia   - Desabilitada chamado do _VerSE2 ()
// 02/03/2016 - Robert  - Novo codigo de produto para lenha (2852).
// 19/04/2016 - Robert  - Desabilitado tratamento para armazem externo (nao estamos operando com isso)
// 27/04/2016 - Catia   - Gravar vendedor na nota original na NCC quando nota de devolução
// 14/06/2016 - Catia   - Aviso por email se a condicao de pagamento na nota nao esta igual a condicao da OC
// 15/06/2016 - Catia   - Ativo Fixo - atualizar a descricao do item e o valor de aquisicao
// 23/06/2016 - Catia   - Alterações nos emails validando a condicao de pagamento
// 30/06/2016 - Catia   - Acertada a mascara do campo quantidade nos emails de produtos controlados da policia federal
// 01/07/2016 - Catia   - Ajuste email que valida condição de pagamento
// 21/07/2016 - Catia   - CIAP - atualizar a descricao do item conforme digitado na nota fiscal
// 25/07/2016 - Catia   - CIAP - atualizar a chave na nota referente ao item no CIAP
// 14/09/2016 - Catia   - CIAP - alterado para que passe a gravar o campos f9_funcit = f9_descri
// 28/11/2016 - Robert  - Envia e-mail para compras@... e nao mais para o grupo 017.
// 07/12/2016 - Robert  - Chama exportacao de dados para Mercanet.
//                      - Eliminadas funcoes em desuso: _ARMAZEXT(), _ATUSZI(), _VERDEVFIL().
// 23/06/2017 - Catia   - Desabilitada a rotina de envio de email a partir de uma nota de devolução
// 04/07/2017 - Catia   - Habilitada a opcao de enviar email pra logistica quando entra nota de devolução no almox 91
// 04/07/2017 - Catia   - Habilitada a opcao de enviar email pro comercial quando entra nota de devolução com motivo 66
// 06/07/2017 - Catia   - acertado rotina que mandava email pro comercial se entrar nota com motivo 66
// 11/08/2017 - Catia   - adicionada minha rotinha 025 no email de movimentacao no almox 91 - que os guris dizem que nao estao recebendo
// 21/09/2017 - Catia   - envio de emails referente NF devolução com motivo 66 estava acessando fornecedores ao inves de clientes
// 11/01/2018 - Catia   - devolucao no almox 10 - envia email igual ao almox 91 - mesmas pessoas que recebem inclusive
// 17/01/2018 - Catia   - movimentacao no almox 10 - envia email igual ao almox 91 - mesmas pessoas que recebem inclusive (movimentacao de transferencia tambem)
// 07/02/2018 - Catia   - mensagem do FUNRURAL - tirar o percentual deixar so a mensagem e o valor
// 17/04/2018 - Robert  - Deixa de chamar o VA_ZZ4I pois os dados adicionais foram migrados para campos memo no SF1.
// 15/05/2018 - Catia   - alteração para buscar o vendedor para gerar a NCC conforme o vendedor informado nos dados de devolução do ZZX
// 23/11/2018 - Rober   - tirado teste do bat de transferencias de filiais
// 05/03/2019 - Andre   - Adicionado envio de e-mail quando tiver notas de devolução
// 17/04/2019 - Catia   - se importacao nao atualiza ZZX
// 29/04/2019 - Catia   - alterada a rotina que atualiza o ZZX para gravar por reclock e nao update
// 23/05/2019 - Andre   - Ao digitar notas de Devolucao faz validação de TES que não geram faturamento e não enviam para o Mercanet.
// 27/06/2019 - Andre   - Ajustado query de notas de devolução que vão para Mercanet
// 03/01/2020 - Robert  - Ajuste msg. placa veiculo e NF produtor nos dados adicionais.
// 30/01/2020 - Robert  - Melhorados logs (tentativa verificar bloqueio notas safra).
//
// --------------------------------------------------------------------------
#include "rwmake.ch"

user function SF1100i ()
	local _aAreaAnt := U_ML_SRArea ()
//	local _oBatch   := NIL

	// Grava campos adicionais enviados para a rotina automatica. Deve ser a
	// primeira rotina executada, pois outras rotinas usam dados gravados por esta.
	_GrvCpAdic ()

	// Verificacoes para notas de importacao.
	_Import ()

	// Grava dados adicionais no ZZ4 para posterior uso na impressao da nota / envio para NF eletronica.
	_DadosAdic ()

	// Ajusta dados no SE2
	_AjSE2 ()
	
	// envia e-mail para responsáveis dispensadoras de suco
	_Dispenser()
	
	// envia e-mail para responsáveis - itens controlados pela policia federal
	_Controle_PF()
	
	// envia e-mail para compras/financeiro - se os vencimentos informados na nota não estao de acordo com a ordem de compra
	//_VerVenc()
	
	// Avisa solicitante que seu pedido chegou.
	if ! sf1 -> f1_tipo $ "BD"
		_AvisaSoli ()
	endif
	
	// Parece que nas notas de uva fica em branco, e a versao 3.10 da NF-e exige...
	if empty (sf1 -> f1_hora)
		reclock ("SF1", .F.)
		sf1 -> f1_hora = left (time (), 5)
		msunlock ()
	endif

	// Atualiza status na tabela ZZX (XML de NF de entrada).
	_AtuZZX ('')
	
	// verifica sempre, pra ver se movimentou um desses almox
	_EmailLog()  			 // email para a logistica avisando entradas no almox 91 e 10
		
	if sf1 -> f1_tipo = "D" 
		_HistNf()  	
		_GrvDadosNCC ()		 // grava dados de vendedor e rapel na NCC
		_VerMot()     		 // verifica motivo de devolucao
		
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery +=   " SELECT COUNT (*) " 
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1, "
		_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery +=   " WHERE SD1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=   " AND SF4.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=   " AND SF4.F4_FILIAL = '" + xfilial('SF4') + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_TES = SF4.F4_CODIGO "
		_oSQL:_sQuery +=   " AND SF4.F4_MARGEM IN ('1','2','3') "
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL  = '" + sf1 -> f1_filial + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_FORNECE = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOJA    = '" + sf1 -> f1_loja + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_DOC     = '" + sf1 -> f1_doc + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_SERIE   = '" + sf1 -> f1_serie + "'"
		if _oSQL:RetQRY() > 0
			U_AtuMerc ('SF1', sf1 -> (recno ()))  // atualiza Mercanet
		endif
	endif
	
	// Se for nota de compra normal - verifica e atualiza ativo fixo
	if sf1 -> f1_tipo = "N"
		_AtuATF()
	endif

	// Imprime romaneio de entrada
    if cEmpAnt + cFilAnt == '0101' .and. ! IsInCallStack ("U_VA_RUS") .and. cEspecie !='CTR' .and. cEspecie !='CTE' .and. ! IsInCallStack ("U_VA_GNF2")
    	if U_MsgYesNo ("Deseja imprimir o romaneio de entrada?")
    		U_RomEntr (sf1 -> f1_fornece, sf1 -> f1_loja, sf1 -> f1_doc, sf1 -> f1_serie)
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return

// --------------------------------------------------------
// verifica motivo de devolução 66 - email para o comercial
// --------------------------------------------------------
static function _VerMot ()
	local _oSQL := NIL

	_sQuery := ""
	_sQuery += " SELECT SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_EMISSAO, SD1.D1_DTDIGIT"
	_sQuery += "      , SA1.A1_NOME, SD1.D1_COD, SD1.D1_DESCRI, SD1.D1_QUANT" 
	_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1 "
	_sQuery += "	  INNER JOIN SA1010 AS SA1"
	_sQuery += "		ON (SA1.D_E_L_E_T_  = ''"
	_sQuery += "			AND SA1.A1_COD  = SD1.D1_FORNECE"
	_sQuery += "			AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''
	_sQuery += "    AND SD1.D1_FILIAL  = '" + sf1 -> f1_filial + "'"
	_sQuery += "    AND SD1.D1_FORNECE = '" + sf1 -> f1_fornece + "'"
	_sQuery += "    AND SD1.D1_LOJA    = '" + sf1 -> f1_loja + "'"
	_sQuery += "    AND SD1.D1_DOC     = '" + sf1 -> f1_doc + "'"
	_sQuery += "    AND SD1.D1_SERIE   = '" + sf1 -> f1_serie + "'"
	_sQuery += "    AND SD1.D1_MOTDEV  = '66'"
	_aDados := U_Qry2Array(_sQuery)
	
    if len(_aDados) > 0
	
		_aCols = {}
		aadd (_aCols, {'Documento'         ,    'left'  ,  ''})
		aadd (_aCols, {'Serie'             ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Emissao'        ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Entrada'        ,    'left'  ,  ''})
		aadd (_aCols, {'Cliente'           ,    'left'  ,  ''})
		aadd (_aCols, {'Produto'           ,    'left'  ,  ''})
		aadd (_aCols, {'Descricao'         ,    'left'  ,  ''})
		aadd (_aCols, {'Quantidade'        ,    'right' ,  '@E 999.99'})
		
//		_oSQL:_sQuery =  aClone(_aDados)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery = _sQuery
		if len (_oSQL:Qry2Array (.T., .F.)) > 0
			_sMens = _oSQL:Qry2HTM ("NF Devolução com Motivo a alterar: " + dtoc(sf1 -> f1_dtdigit), _aCols, "", .F.)
			U_ZZUNU ({'003'}, "NF Devolução com Motivo a alterar:" + dtoc(sf1 -> f1_dtdigit), _sMens, .F., cEmpAnt, cFilAnt, "")  // comercial
			U_ZZUNU ({'078'}, "NF Devolução com Motivo a alterar:" + dtoc(sf1 -> f1_dtdigit), _sMens, .F., cEmpAnt, cFilAnt, "")  // katia fiscal
		endif
	endif
return
// --------------------------------------------------------------------------
// força gravação do vendedor na NCC gerada pelo nota de devolução
static function _GrvDadosNCC ()
	// grava vendedor na nota de devolucao e na NCC
	_sQuery := ""
	_sQuery += " SELECT TOP 1 D1_NFORI, D1_SERIORI"
	_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1 "
	_sQuery += "  WHERE D_E_L_E_T_ = ''"
	_sQuery += "    AND D1_FILIAL  = '" + sf1 -> f1_filial + "'"
	_sQuery += "    AND D1_FORNECE = '" + sf1 -> f1_fornece + "'"
	_sQuery += "    AND D1_LOJA    = '" + sf1 -> f1_loja + "'"
	_sQuery += "    AND D1_DOC     = '" + sf1 -> f1_doc + "'"
	_sQuery += "    AND D1_SERIE   = '" + sf1 -> f1_serie + "'"
	_aDados := U_Qry2Array(_sQuery)
	if len(_aDados) > 0
    	_wNForig  = _aDados[1,1]
		_wSerOrig = _aDados[1,2]
		_wvendDEV := ""
		_wvendCAD := ""
    	// busca o vendedor informado nos dados de devolucao na manutenção de XML
    	u_help (SF1 -> F1_CHVNFE + "chave"  )
    	///_wvendDEV = fBuscaCpo ('ZAJ', 1, xfilial('ZAJ') + SF1 -> F1_CHVNFE , "ZAJ_VENDDV")
    	_sSQL := "SELECT ZAJ_VENDDV"
    	_sSQL += "   FROM ZAJ010"
    	_sSQL += "  WHERE ZAJ_CHAVE = '" + SF1 -> F1_CHVNFE + "'"
    	_aDados := U_Qry2Array(_sSQL)
    	if len(_aDados) > 0
    		_wvendDEV = _aDados[1,1]
    	endif
    	_wvendCAD = fBuscaCpo ('SA1', 1, xfilial('SA1') + sf1 -> f1_fornece + sf1 -> f1_loja , "A1_VEND")
    	if val(_wvendDEV) = 0
	    	// busca o vendedor da nota original
    		_wvendDEV = fBuscaCpo ('SF2', 1, xfilial('SF2') + _wNForig + _wSerOrig , "F2_VEND1")
    	endif
		// atualiza o vendedor na NCC		    		
		_sSQL := ""
		_sSQL += "UPDATE " + RetSQLName ("SE1")
   		_sSQL += "   SET E1_VEND1   = '" + _wvendDEV + "'"  
 		_sSQL += " WHERE E1_FILIAL  = '" + xfilial('SE1') + "'"
   		_sSQL += "   AND E1_NUM     = '" + sf1 -> f1_doc + "'"
   		_sSQL += "   AND E1_PREFIXO = '" + sf1 -> f1_serie + "'"
   		_sSQL += "   AND E1_CLIENTE = '" + sf1 -> f1_fornece + "'"
   		_sSQL += "   AND E1_LOJA    = '" + sf1 -> f1_loja + "'"
   		TCSQLExec (_sSQL)
   		
   		if val(_wvendDEV) <> val(_wvendCAD)
	       			
	    _aCols = {}
		aadd (_aCols, {'Documento'         ,    'left'  ,  ''})
		aadd (_aCols, {'Serie'             ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Emissao'        ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Digitada'       ,    'left'  ,  ''})
		aadd (_aCols, {'Cliente'		   ,    'left'  ,  ''})
		aadd (_aCols, {'Vendedor Devolucao',    'left'  ,  ''})
		aadd (_aCols, {'Vendedor Cadastro' ,    'left'  ,  ''})
		aadd (_aCols, {'Nota Original'     ,    'left'  ,  ''})
		aadd (_aCols, {'Serie Original'    ,    'left'  ,  ''})
		aadd (_aCols, {'Vendedor Original' ,    'left'  ,  ''})
		
				
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_EMISSAO, SD1.D1_DTDIGIT"
	    _oSQL:_sQuery += "      , SA1.A1_NOME, ZAJ.ZAJ_VENDDV, SA1.A1_VEND, SD1.D1_NFORI, SD1.D1_SERIORI ,SF2.F2_VEND1 "
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1"
		_oSQL:_sQuery += "		INNER JOIN SF1010 AS SF1"
		_oSQL:_sQuery += "			ON (SF1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "				AND SF1.F1_FILIAL = SD1.D1_FILIAL"
		_oSQL:_sQuery += "				AND SF1.F1_FORNECE = SD1.D1_FORNECE"
		_oSQL:_sQuery += "				AND SF1.F1_DOC    = SD1.D1_DOC"
		_oSQL:_sQuery += "				AND SF1.F1_SERIE  = SD1.D1_SERIE"
		_oSQL:_sQuery += "				AND SF1.F1_LOJA   = SD1.D1_LOJA)"
	    _oSQL:_sQuery += " 		INNER JOIN SD2010 AS SD2"
		_oSQL:_sQuery += " 			ON (SD2.D_E_L_E_T_ = '' "	
		_oSQL:_sQuery += " 				AND SD2.D2_FILIAL  = SD1.D1_FILIAL"
		_oSQL:_sQuery += " 				AND SD2.D2_CLIENTE = SD1.D1_FORNECE"
		_oSQL:_sQuery += "				AND SD2.D2_DOC     = SD1.D1_NFORI"
		_oSQL:_sQuery += "				AND SD2.D2_SERIE   = SD1.D1_SERIORI"
		_oSQL:_sQuery += "				AND SD2.D2_ITEM    = SD1.D1_ITEMORI)
		_oSQL:_sQuery += "		INNER JOIN SF2010 AS SF2"
		_oSQL:_sQuery += "			ON (SF2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "				AND SF2.F2_FILIAL = SD2.D2_FILIAL"
		_oSQL:_sQuery += "				AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
		_oSQL:_sQuery += "				AND SF2.F2_DOC    = SD2.D2_DOC"
		_oSQL:_sQuery += "				AND SF2.F2_SERIE  = SD2.D2_SERIE"
		_oSQL:_sQuery += "				AND SF2.F2_LOJA   = SD2.D2_LOJA)"
		_oSQL:_sQuery += "		LEFT JOIN SA1010 AS SA1"
		_oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "				AND SA1.A1_COD    = SD1.D1_FORNECE"
		_oSQL:_sQuery += "				AND SA1.A1_LOJA   = SD1.D1_LOJA)"
		_oSQL:_sQuery += "		LEFT JOIN ZAJ010 AS ZAJ"
		_oSQL:_sQuery += "			ON (ZAJ.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "				AND ZAJ.ZAJ_FILIAL = SD1.D1_FILIAL"
		_oSQL:_sQuery += "				AND ZAJ.ZAJ_NFORIG = SD1.D1_NFORI"
		_oSQL:_sQuery += "				AND ZAJ.ZAJ_SORIG  = SD1.D1_SERIORI"
		_oSQL:_sQuery += "				AND ZAJ.ZAJ_ITORIG = SD1.D1_ITEMORI)"
		_oSQL:_sQuery += "  WHERE SD1.D_E_L_E_T_ != '*' "
		_oSQL:_sQuery += "    AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_oSQL:_sQuery += "    AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery += "    AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery += "    AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery += "    AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
			if len (_oSQL:Qry2Array (.T., .F.)) > 0
				_sMens = _oSQL:Qry2HTM ("NOTAS DE DEVOLUCAO COM DIVERGENCIA DE VENDEDOR: " + dtoc(sf1 -> f1_dtdigit), _aCols, "", .F.)
				U_ZZUNU ({'067'}, "NOTAS DE DEVOLUCAO COM DIVERGENCIA DE VENDEDOR: " + dtoc(sf1 -> f1_dtdigit), _sMens, .F., cEmpAnt, cFilAnt, "")
			endif	
    	endif
	endif
	/*
	// se cliente teve rapel na nota que esta sendo devolvida, grava rapel na NCC - SE1				
	_sQuery := ""
	_sQuery += " SELECT D1_NFORI, D1_SERIORI"
	_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1 "
	_sQuery += "  WHERE D_E_L_E_T_ = ''"
	_sQuery += "    AND D1_FILIAL  = '" + sf1 -> f1_filial + "'"
	_sQuery += "    AND D1_FORNECE = '" + sf1 -> f1_fornece + "'"
	_sQuery += "    AND D1_LOJA    = '" + sf1 -> f1_loja + "'"
	_sQuery += "    AND D1_DOC     = '" + sf1 -> f1_doc + "'"
	_sQuery += "    AND D1_SERIE   = '" + sf1 -> f1_serie + "'"
	_aDados := U_Qry2Array(_sQuery)
    if len(_aDados) > 0
    	_wNForig  = _aDados[1,1]
		_wSerOrig = _aDados[1,2]
    	_wrapel = fBuscaCpo ('SD2', 1, xfilial('SD2') + _wNForig + _wSerOrig , "D2_VARAPEL")
    	// se teve rapel na nota original que esta sendo devolvida, grava valor de rapel na NCC - proporcional a quantidade devolvida
    	if _wrapel > 0
			    	
    	endif
	endif
	*/
	
return	


// --------------------------------------------------------------------------
// Grava campos adicionais do SF1 enviados para a rotina automatica
static function _GrvCpAdic ()
	local _nLinha := 0
	
	// Executa somente quando for rotina automatica.
	if (type ("l100Auto") == "L" .and. l100Auto) .or. (type ("l103Auto") == "L" .and. l103Auto)
		if type ("aAutoCab") == "A"  // Variavel 'clone' da array passada para a rotina automatica
			
			// Varre array de campos do cabecalho procurando por campos customizados
			// Nao grava campos padrao do sistema para evitar inconsistencias com validacoes padrao.
			sx3 -> (dbsetorder (2))
			for _nLinha = 1 to len (aAutoCab)
				if sx3 -> (dbseek (aAutoCab [_nLinha, 1], .F.)) .and. sx3 -> x3_propri == "U"
					reclock ("SF1", .F.)
					sf1 -> &(aAutoCab [_nLinha, 1]) = aAutoCab [_nLinha, 2]
					msunlock ()
				endif
			next
		endif
	endif

	// grava usuario que esta incluindo o documento de entrada
    RecLock("SF1",.F.)
    	SF1->F1_VAUSER   := alltrim(cUserName)
    	sf1 -> f1_vadtinc = date ()
    	sf1 -> f1_vahrinc = time ()
    MsUnLock()
	
return


// --------------------------------------------------------------------------
// Verifica dados para notas de importacao.
static function _Import ()
	local _F1vaDesMI := sf1 -> f1_vaDesMI
	local _F1vaCotMI := sf1 -> f1_vaCotMI
	
	// Abre tela para usuario informar dados adicionais
	if sf1 -> f1_formul == "S" .and. sf1 -> f1_est == "EX"
		@ 0, 0 TO 300, 320 DIALOG oDlg1 TITLE "Dados Adicionais NF de importacao"
		@ 15, 5  say "NF de importacao - dados adicionais:"
		@ 60, 5  say "Moeda estrangeira:"
		@ 75, 5  Say "Cotacao neste dia:"
		@ 60, 65 GET _F1vaDesMI PICTURE "@!"
		@ 75, 65 GET _F1vaCotMI PICTURE "999.9999"
		@ 100, 124 BMPBUTTON TYPE 1 ACTION Close(oDlg1)
		ACTIVATE DIALOG oDlg1 CENTERED
		reclock ("SF1", .F.)
		sf1 -> f1_vaDesMI = _F1vaDesMI
		sf1 -> f1_vaCotMI = _F1vaCotMI
		msunlock ()
		
		// Grava campo verificado pelo programa NFESefaz para geracao do XML. Os valores que conheco sao:
		// #DEFINE  NFE_PRIMEIRA  1
		// #DEFINE  NFE_COMPLEMEN 2
		// #DEFINE  NFE_UNICA     3
		// #DEFINE  CUSTO_REAL    4
		// #DEFINE  NFE_FOB       '5'
		// #DEFINE  NFE_FRETE     '6'
		// #DEFINE  NFE_SEGURO    '7'
		// #DEFINE  NFE_CIF       '8'
		// #DEFINE  NFE_IMPOSTOS  '9'
		// #DEFINE  NFE_DESPESAS  'A'
		// #DEFINE  CUSTO_REAL    'B'
		sd1 -> (dbsetorder (1))  // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
		sd1 -> (dbseek (xfilial ("SD1") + sf1 -> f1_doc + sf1 -> f1_serie + sf1 -> f1_fornece + sf1 -> f1_loja, .T.))
		do while ! sd1 -> (eof ()) ;
			.and. sd1 -> d1_filial  == xfilial ("SD1") ;
			.and. sd1 -> d1_doc     == sf1 -> f1_doc ;
			.and. sd1 -> d1_serie   == sf1 -> f1_serie ;
			.and. sd1 -> d1_fornece == sf1 -> f1_fornece ;
			.and. sd1 -> d1_loja    == sf1 -> f1_loja
			reclock ("SD1", .F.)
				sd1 -> d1_tipo_nf = "1"
			msunlock ()
			sd1 -> (dbskip ())
		enddo
	endif
return


// --------------------------------------------------------------------------
// Ajusta dados no arquivo SE2.
static function _AjSE2 ()
	local _sQuery := ""
	local _lLenha := .F.
	
	// Grava observacoes no historico dos titulos conforme o tipo de nota.
	if sf1 -> f1_tipo == "N" .and. sf1 -> f1_formul == "S"
		_sQuery := ""
		_sQuery += " SELECT COUNT (*)"
		_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1 "
		_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_sQuery +=    " AND D1_FILIAL  = '" + se2 -> e2_filial + "'"
		_sQuery +=    " AND D1_FORNECE = '" + se2 -> e2_fornece + "'"
		_sQuery +=    " AND D1_LOJA    = '" + se2 -> e2_loja + "'"
		_sQuery +=    " AND D1_DOC     = '" + se2 -> e2_num + "'"
		_sQuery +=    " AND D1_SERIE   = '" + se2 -> e2_prefixo + "'"
		_sQuery +=    " AND D1_COD     IN ('9989', '2852')"
		if U_RetSQL (_sQuery) > 0
			_lLenha = .T.
		endif
		if _lLenha
			se2 -> (dbsetorder (6))  // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
			se2 -> (dbseek (xfilial ("SE2") + sf1 -> f1_fornece + sf1 -> f1_loja + sf1 -> f1_serie + sf1 -> f1_doc, .T.))
			do while ! se2 -> (eof ()) ;
				.and. se2 -> e2_filial  == xfilial ("SE2") ;
				.and. se2 -> e2_fornece == sf1 -> f1_fornece ;
				.and. se2 -> e2_loja    == sf1 -> f1_loja ;
				.and. se2 -> e2_prefixo == sf1 -> f1_serie ;
				.and. se2 -> e2_num     == sf1 -> f1_doc
				reclock ("SE2", .F.)
				se2 -> e2_hist    = alltrim (se2 -> e2_hist) + "LENHA"
				se2 -> e2_vaLenha = "S"
				msunlock ()
				se2 -> (dbskip ())
			enddo
		endif
	endif
return


// --------------------------------------------------------------------------
// Grava dados adicionais para posterior uso na impressao da nota / envio para NF eletronica.
static function _DadosAdic ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _sMsgFisco := ""
	local _sMsgContr := ""
	local _sQuery    := ""
	local _aObs      := {}
	local _nObs      := 0
	local _sPLACA    := sf1 -> f1_vaPlVei
	local _sNPRODU   := sf1 -> f1_vaNfPro
	local _sSNPRODU  := sf1 -> f1_vaSePro
//	local _aRetQry   := {}
	local _oSQL      := NIL
	
	// Mensagens do pedido de venda.
	if sf1 -> (fieldpos ("F1_MENPAD")) > 0 .and. ! empty (sf1 -> f1_menpad)
		_SomaMsg (@_sMsgFisco, formula (sf1 -> f1_menpad))
	endif
	if sf1 -> (fieldpos ("F1_MENNOTA")) > 0 .and. ! empty (sf1 -> f1_mennota)
		_SomaMsg (@_sMsgContr, sf1 -> f1_mennota)
	endif
	
	if sf1 -> f1_contsoc > 0
		_SomaMsg (@_sMsgContr, "FUNRURAL ->" + ALLTRIM (transform (sf1 -> f1_contsoc, "@E 999,999.99")))
	endif
	
	// Busca observacoes lancadas nos itens da nota
	_sQuery := ""
	_sQuery += " select distinct D1_OBS "
	_sQuery += " from " + RetSQLName ("SD1") + " SD1"
	_sQuery += " where SD1.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
	_sQuery +=   " AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
	_sQuery +=   " AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
	_sQuery +=   " AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
	_sQuery +=   " AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
	_aObs = aclone (U_Qry2Array (_sQuery))
	for _nObs = 1 to len (_aObs)
		_SomaMsg (@_sMsgContr, _aObs [_nObs, 1])
	next
	
	// Abre tela para usuario informar dados adicionais
//	if sf1 -> f1_formul == "S" .and. funname () != "VA_GNF2" .and. funname () != "VA_RUS" .and. sf1 -> f1_est != "EX"
	if sf1 -> f1_formul == "S" .and. sf1 -> f1_est != "EX" .and. ! IsInCallStack ("U_VA_GNF2") .and. ! IsInCallStack ("U_VA_RUS")
		// Tela em loop para validar dados.
		do while .T.
			@ 0, 0 TO 300, 320 DIALOG oDlg1 TITLE "Dados Adicionais NF"
			@ 15, 5  say "Informe dados adicionais para a seguinte nota:"
			if sf1 -> f1_tipo $ "BD"
				@ 25, 5  say "Cliente: " + sf1 -> f1_fornece + "/" + sf1 -> f1_loja + " - " + fBuscaCpo ("SA1", 1, xfilial ("SA1") + sf1 -> f1_fornece + sf1 -> f1_loja, "A1_NOME")
			else
				@ 25, 5  say "Fornecedor: " + sf1 -> f1_fornece + "/" + sf1 -> f1_loja + " - " + fBuscaCpo ("SA2", 1, xfilial ("SA2") + sf1 -> f1_fornece + sf1 -> f1_loja, "A2_NOME")
			endif
			@ 35, 5  say "NF: " + sf1 -> f1_doc + "  serie: " + sf1 -> f1_serie
			@ 60, 5  Say "Placa Veiculo   :"
			@ 75, 5  Say "N.F Produtor    :"
			@ 90, 5  Say "Serie N.F Prod. :"
			@ 60, 65 GET _sPLACA    PICTURE "@!"
			@ 75, 65 GET _sNPRODU   PICTURE "@!"
			@ 90, 65 GET _sSNPRODU  PICTURE "@!"
			@ 100, 124 BMPBUTTON TYPE 1 ACTION Close(oDlg1)
			ACTIVATE DIALOG oDlg1 CENTERED
			if empty (_sNPRODU) .or. empty (_sSNPRODU)
				if U_msgnoyes ("A informacao de NF/serie de produtor e´ obrigatoria para autorizacao pela SEFAZ. Deseja realmente deixar esses campos em branco?")
					exit
				endif
			else
				// Verifica se esta NF de produtor jah foi apresentada, mesmo em outra filial.
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT F1_FILIAL + '/' + F1_DOC + '/' + F1_SERIE"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SF1")
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND F1_FORMUL  = 'S'"
				_oSQL:_sQuery +=    " AND F1_TIPO    = 'N'"
				_oSQL:_sQuery +=    " AND F1_FORNECE = '" + sf1 -> f1_fornece + "'"
				_oSQL:_sQuery +=    " AND F1_LOJA    = '" + sf1 -> f1_loja + "'"
				_oSQL:_sQuery +=    " AND F1_VANFPRO = '" + _sNPRODU + "'"
				_oSQL:_sQuery +=    " AND F1_VASEPRO = '" + _sSNPRODU + "'"
				if empty (_oSQL:RetQry ())
					exit
				else
					u_help ("NF/serie de produtor ja´ apresentada na filial/contranota/serie '" + _oSQL:_xRetQry + "'")
				endif
			endif
		enddo
		reclock ("SF1", .F.)
		sf1 -> f1_vaNfPro = _sNPRODU
		sf1 -> f1_vaSePro = _sSNPRODU
		sf1 -> f1_vaPlVei = _sPlaca
		msunlock ()
		
		// Nao eh o lugar certo para esta verificacao, mas deve ajudar...
		if ! empty (sf1 -> f1_vaNfPro) .and. alltrim (upper (fBuscaCpo ("SA2", 1, xfilial ("SA2") + sf1 -> f1_fornece + sf1 -> f1_loja, "A2_INSCR"))) $ "ISENTO"
			u_help ("A T E N C A O: Produtor rural deveria ter inscricao estadual. Verifique!")
		endif
	endif
//	if ! empty (sf1 -> f1_vaPlVei) .and. funname () != "VA_RUS"
	if ! empty (sf1 -> f1_vaPlVei)
		_SomaMsg (@_sMsgContr, "Placa veic:" + sf1 -> f1_vaPlVei)
	endif

//	Jah busca por padrao no NFESEFAZ --> if ! empty (sf1 -> f1_vaNfPro) .and. funname () != "VA_RUS"
//	Jah busca por padrao no NFESEFAZ --> 	_SomaMsg (@_sMsgContr, "NF produtor:" + sf1 -> f1_vaNfPro)
//	Jah busca por padrao no NFESEFAZ --> endif
	
	// Verifica se a empresa tem inscricao estadual na UF informada (MG, por exemplo)
	if sf1 -> f1_formul == "S" .and. sf1 -> f1_est == "MG"
		_SomaMsg (@_sMsgFisco, "Regime especial/PTA 16.000178297-01")
	endif
	
	// Aqui nao preciso testar se jah tem memo, pois trata-se de inclusao.
	msmm(,,,_sMsgFisco,1,,,"SF1","F1_VACMEMF")
	msmm(,,,_sMsgContr,1,,,"SF1","F1_VACMEMC")
	
	U_ML_SRArea (_aAreaAnt)
return

// --------------------------------------------------------------------------
// Acrescenta texto `a mensagem.
static function _SomaMsg (_sVariav, _sTexto)
	_sVariav += iif (! empty (_sVariav), "; ", "") + alltrim (_sTexto)
return



// --------------------------------------------------------------------------
Static Function _Dispenser()
	if sf1 -> f1_especie ='SPED' .or. sf1 -> f1_especie ='NF' // não manda emails a partir de conhecimentos
	
		_aCols = {}
		aadd (_aCols, {'Documento'         ,    'left'  ,  ''})
		aadd (_aCols, {'Serie'             ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Emissao'        ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Entrada'        ,    'left'  ,  ''})
		aadd (_aCols, {'Fornecedor/Cliente',    'left'  ,  ''})
		aadd (_aCols, {'Produto'           ,    'left'  ,  ''})
		aadd (_aCols, {'Descricao'         ,    'left'  ,  ''})
		aadd (_aCols, {'Quantidade'        ,    'right' ,  '@E 999.99'})
		
		// Avisa comercial - chegada de dispensers
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_EMISSAO, SD1.D1_DTDIGIT"
	    _oSQL:_sQuery += "      , CASE SD1.D1_TIPO WHEN 'N' THEN SA2.A2_NOME ELSE SA1.A1_NOME END AS CLI_FOR"
		_oSQL:_sQuery += "      , SD1.D1_COD, SD1.D1_DESCRI, SD1.D1_QUANT" 
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1"
	    _oSQL:_sQuery += " 		INNER JOIN SB1010 AS SB1"
		_oSQL:_sQuery += " 			ON (SB1.D_E_L_E_T_ = ''"	
		_oSQL:_sQuery += " 				AND SB1.B1_COD    = SD1.D1_COD"
		_oSQL:_sQuery += " 				AND SB1.B1_CODLIN = '90')" 
		_oSQL:_sQuery += "		LEFT JOIN SA2010 AS SA2"
		_oSQL:_sQuery += "			ON (SA2.D_E_L_E_T_ = ''	"
		_oSQL:_sQuery += "				AND SA2.A2_COD  = SD1.D1_FORNECE"
		_oSQL:_sQuery += "				AND SA2.A2_LOJA = SD1.D1_LOJA)"
		_oSQL:_sQuery += "		LEFT JOIN SA1010 AS SA1"
		_oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = ''	"
		_oSQL:_sQuery += "				AND SA1.A1_COD  = SD1.D1_FORNECE"
		_oSQL:_sQuery += "				AND SA1.A1_LOJA = SD1.D1_LOJA)"
	    _oSQL:_sQuery += "  WHERE SD1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "    AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_oSQL:_sQuery += "    AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery += "    AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery += "    AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery += "    AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
		if len (_oSQL:Qry2Array (.T., .F.)) > 0
			_sMens = _oSQL:Qry2HTM ("DISPENSERS MOVIMENTADOS - Entrada: " + dtoc(sf1 -> f1_dtdigit), _aCols, "", .F.)
			U_ZZUNU ({'044'}, "DISPENSERS MOVIMENTADOS - Entrada: " + dtoc(sf1 -> f1_dtdigit), _sMens, .F., cEmpAnt, cFilAnt, "") // Responsavel dispensadoras
		endif
		
	endif				
return

/*
// --------------------------------------------------------------------------
Static Function _VerVenc()
	local i := 0
	
	if sf1 -> f1_especie !='CTE' .and. sf1 -> f1_especie !='CTR' .and. sf1 -> f1_tipo = 'N'
		// verifica se tem condicao de pagamento diferentes nas solicitacoes diferentes atendidas na NF
		_sQuery := ""
		_sQuery += " SELECT DISTINCT SC7.C7_COND"
  		_sQuery += "   FROM SD1010 AS SD1"
		_sQuery += " 	INNER JOIN SC7010 AS SC7"
		_sQuery += " 		ON (SC7.D_E_L_E_T_ = ''"
		_sQuery += " 			AND SC7.C7_FILIAL  = SD1.D1_FILIAL"
		_sQuery += " 			AND SC7.C7_FORNECE = SD1.D1_FORNECE"
		_sQuery += " 			AND SC7.C7_NUM     = SD1.D1_PEDIDO)"
		_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''"
 		_sQuery += "    AND SD1.D1_FILIAL  = '" + xfilial ("SD1")   + "'"
   		_sQuery += "    AND SD1.D1_DOC     = '" + sf1 -> f1_doc     + "'"
   		_sQuery += "    AND SD1.D1_SERIE   = '" + sf1 -> f1_serie   + "'"
   		_sQuery += "    AND SD1.D1_FORNECE = '" + sf1 -> f1_fornece + "'"
   		_sQuery += "    AND SD1.D1_LOJA    = '" + sf1 -> f1_loja    + "'"
   		
   		_aDados := U_Qry2Array(_sQuery)
   		if len(_aDados) > 0
   			_sQuery += " SELECT DISTINCT SC7.C7_COND, SC7.C7_NUM"
  			_sQuery += "   FROM SD1010 AS SD1"
			_sQuery += " 	INNER JOIN SC7010 AS SC7"
			_sQuery += " 		ON (SC7.D_E_L_E_T_ = ''"
			_sQuery += " 			AND SC7.C7_FILIAL  = SD1.D1_FILIAL"
			_sQuery += " 			AND SC7.C7_FORNECE = SD1.D1_FORNECE"
			_sQuery += " 			AND SC7.C7_NUM     = SD1.D1_PEDIDO)"
			_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''"
 			_sQuery += "    AND SD1.D1_FILIAL  = '" + xfilial ("SD1")   + "'"
   			_sQuery += "    AND SD1.D1_DOC     = '" + sf1 -> f1_doc     + "'"
   			_sQuery += "    AND SD1.D1_SERIE   = '" + sf1 -> f1_serie   + "'"
   			_sQuery += "    AND SD1.D1_FORNECE = '" + sf1 -> f1_fornece + "'"
   			_sQuery += "    AND SD1.D1_LOJA    = '" + sf1 -> f1_loja    + "'"
   			_aDados := U_Qry2Array(_sQuery)
   			
			// manda email avisando que existem condiçoes de pagamento diferentes nas OC atendidas para essa nota
			_aCols = {}
			aadd (_aCols, {'Documento Entrada' ,    'left'  ,  ''})
			aadd (_aCols, {'Serie'             ,    'left'  ,  ''})
			aadd (_aCols, {'Fornecedor'        ,    'left'  ,  ''})
			aadd (_aCols, {'Nome'              ,    'left'  ,  ''})
			aadd (_aCols, {'Pedido'            ,    'left'  ,  ''})
			aadd (_aCols, {'Condição'          ,    'left'  ,  ''})
			aadd (_aCols, {'Descricao Condicao',    'left'  ,  ''})
			
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT DISTINCT SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_FORNECE, SA2.A2_NOME, SD1.D1_PEDIDO, SC7.C7_COND, SE4.E4_DESCRI"
			_oSQL:_sQuery += "   FROM SD1010 AS SD1"
			_oSQL:_sQuery += " 		INNER JOIN SC7010 AS SC7"
			_oSQL:_sQuery += " 			ON (SC7.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " 				AND C7_FILIAL  = SD1.D1_FILIAL"
			_oSQL:_sQuery += " 				AND C7_FORNECE = SD1.D1_FORNECE"
			_oSQL:_sQuery += " 				AND C7_NUM     = SD1.D1_PEDIDO)"
			_oSQL:_sQuery += " 		INNER JOIN SA2010 AS SA2"
			_oSQL:_sQuery += " 			ON (SA2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " 				AND SA2.A2_COD  = SD1.D1_FORNECE"
			_oSQL:_sQuery += " 				AND SA2.A2_LOJA = SD1.D1_LOJA)"
			_oSQL:_sQuery += " 		INNER JOIN SE4010 AS SE4"
			_oSQL:_sQuery += " 			ON (SE4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " 				AND SE4.E4_CODIGO = SC7.C7_COND)"
			_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
	 		_oSQL:_sQuery += "   AND SD1.D1_FILIAL  = '" + xfilial ("SD1")   + "'"
	   		_oSQL:_sQuery += "   AND SD1.D1_DOC     = '" + sf1 -> f1_doc     + "'"
	   		_oSQL:_sQuery += "   AND SD1.D1_SERIE   = '" + sf1 -> f1_serie   + "'"
	   		_oSQL:_sQuery += "   AND SD1.D1_FORNECE = '" + sf1 -> f1_fornece + "'"
	   		_oSQL:_sQuery += "   AND SD1.D1_LOJA    = '" + sf1 -> f1_loja    + "'"
	   		
	   		_wfornece = fBuscaCpo ('SA2', 1, xfilial('SA2') + sf1 -> f1_fornece, "A2_NOME")
    		_wpedido  = _aDados[1,2]
			_wcond    = _aDados[1,1]
			_wdcond   = fBuscaCpo ('SE4', 1, xfilial('SE4') + _wcond, "E4_DESCRI")
			_cCond   := Condicao(10000,_wcond,,sf1 -> f1_emissao)
				
	   		if len (_oSQL:Qry2Array (.T., .F.)) > 0
	   			// monta email
			   	_sMens  = "Fornecedor.....: " + sf1 -> f1_fornece + ' - ' + _wfornece + chr(13) + chr(10)
			   	_sMens += "Numero/Serie NF: " + sf1 -> f1_doc + ' - ' + sf1 -> f1_serie +  chr(13) + chr(10)
			   	_sMens += "Emissao NF.....: " + dtoc(sf1 -> f1_emissao) + chr(13) + chr(10)
			   	_sMens += "Vlr.Total NF...: " + cValToChar (sf1 -> f1_valbrut) + chr(13) + chr(10)
			   	_sMens += "Pedido/O.C.....: " + _wpedido + chr(13) + chr(10)
			   	_sMens += "Condicao na O.C: " + _wcond + ' - ' + _wdcond + chr(13) + chr(10)
				_sMens = _oSQL:Qry2HTM ("NF CONTEM ORDENS DE COMPRA COM CONDICAO DE PAGAMENTO DIFERENTES", _aCols, "", .F.)
				U_SendMail ('compras@novaalianca.coop.br', "NF NÃO CONFORME COM A ORDEM DE COMPRA", _sMens, {})
			endif	   
		else
			// busca parcelas geradas no contas a pagar
			_sQuery := ""
			_sQuery += " SELECT E2_VENCTO, E2_NUM, E2_PARCELA"
  			_sQuery += "   FROM SE2010"
 			_sQuery += "  WHERE D_E_L_E_T_ = ''"
   			_sQuery += "    AND E2_FILIAL  = '" + xfilial ("SD1")   + "'"
   			_sQuery += "    AND E2_FORNECE = '" + sf1 -> f1_fornece + "'"
   			_sQuery += "    AND E2_LOJA    = '" + sf1 -> f1_loja    + "'"
   			_sQuery += "    AND E2_NUM     = '" + sf1 -> f1_doc     + "'"
   			_sQuery += " ORDER BY E2_NUM, E2_PARCELA"
   			_aDados1 := U_Qry2Array(_sQuery)
   			_werro := 0
   			if len(_aDados1) > 0
    			// guarda dados para enviar no email
    			_wfornece = fBuscaCpo ('SA2', 1, xfilial('SA2') + sf1 -> f1_fornece, "A2_NOME")
    			//_wpedido  = _aDados[1,2]
				_wcond    = _aDados[1,1]
				_wdcond   = fBuscaCpo ('SE4', 1, xfilial('SE4') + _wcond, "E4_DESCRI")
				_cCond   := Condicao(10000,_wcond,,sf1 -> f1_emissao)
				if len(_aDados1) = 1
					_xPARCELA := ""	
				else 
					_xPARCELA := "A"
				endif
				if len(_aDados1) = len(_cCond)
					// verifica se os vencimentos do financeiro estao MENORES que da ordem de compra
					For i=1 To Len(_cCond)
						if _aDados1[i,1] < _cCond[i,1] .or. _werro=2 
							_sSQL := ""
							_sSQL += " INSERT INTO AUX_ENTNF ( FORNECE, DOC, EMISSAO, PARCELA, VENCTO)" 
		                    _sSQL += " VALUES ( '" + sf1 -> f1_fornece + "'"
		                    _sSQL += "        , '" + sf1 -> f1_doc     + "'"
		                    _sSQL += "        , '" + dtos(sf1 -> f1_emissao) + "'"
		                    _sSQL += "        , '" + _xPARCELA + "'"
		                    _sSQL += "        , '" + dtos(_cCond[i,1]) + "')"
		                    if TCSQLExec (_sSQL) < 0
				                u_showmemo(_sSQL)
				                return
				            endif
				            _werro = 2
						endif					 
						_xPARCELA := Soma1(_xPARCELA)               
					next
        		else
					_werro = 1  // nro de parcelas não eh igual									
				endif	
												
				if _werro > 0
					_aCols = {}
					aadd (_aCols, {'Parcela'                  ,  'left'  ,  ''})
					aadd (_aCols, {'Vencimento pela O.C.'     ,  'left'  ,  ''})
					aadd (_aCols, {'Vencimento no Financeiro' ,  'left'  ,  ''})
					
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT SE2.E2_PARCELA AS PARCELA"
					_oSQL:_sQuery += "      , (SELECT dbo.VA_DTOC(AUX.VENCTO)"
	 				_oSQL:_sQuery += "   		 FROM AUX_ENTNF AS AUX"
	 				_oSQL:_sQuery += "  		WHERE AUX.DOC     = SE2.E2_NUM"
			   		_oSQL:_sQuery += "    		  AND AUX.FORNECE = SE2.E2_FORNECE"
			   		_oSQL:_sQuery += "    		  AND AUX.PARCELA = SE2.E2_PARCELA) AS OC_VENCTO"
	 				_oSQL:_sQuery += "      , dbo.VA_DTOC(SE2.E2_VENCTO) AS FIN_VENCTO"
	 				_oSQL:_sQuery += "   FROM SE2010 AS SE2"
					_oSQL:_sQuery += "  WHERE SE2.D_E_L_E_T_ = ''"
			 		_oSQL:_sQuery += "    AND SE2.E2_FILIAL  = '" + xfilial ("SD1")   + "'"
			   		_oSQL:_sQuery += "    AND SE2.E2_NUM     = '" + sf1 -> f1_doc     + "'"
			   		_oSQL:_sQuery += "    AND SE2.E2_PREFIXO = '" + sf1 -> f1_serie   + "'"
			   		_oSQL:_sQuery += "    AND SE2.E2_FORNECE = '" + sf1 -> f1_fornece + "'"
			   		_oSQL:_sQuery += "    AND SE2.E2_LOJA    = '" + sf1 -> f1_loja    + "'"
			   						   		
			   		if len (_oSQL:Qry2Array (.T., .F.)) > 0
			   			// monta email
			   			_sMens  = "Fornecedor.....: " + sf1 -> f1_fornece + ' - ' + _wfornece + chr(13) + chr(10)
			   			_sMens += "Numero/Serie NF: " + sf1 -> f1_doc + ' - ' + sf1 -> f1_serie +  chr(13) + chr(10)
			   			_sMens += "Emissao NF.....: " + dtoc(sf1 -> f1_emissao) + chr(13) + chr(10)
			   			_sMens += "Vlr.Total NF...: " + cValToChar (sf1 -> f1_valbrut) + chr(13) + chr(10)
			   			//_sMens += "Pedido/O.C.....: " + _wpedido + chr(13) + chr(10)
			   			_sMens += "Condicao na O.C: " + _wcond + ' - ' + _wdcond + chr(13) + chr(10)
						if _werro = 1
			   				_sMens += _oSQL:Qry2HTM ("QUANTIDADE DE PARCELAS DA NF DIFERENTES DA O.C.", _aCols, "", .F.)
			   			else
			   				// monta email
			   				_sMens += _oSQL:Qry2HTM ("VENCIMENTOS DA OC DIFERENTES NF", _aCols, "", .F.)
							// deleta arquivo auxiliar
							_sSQL := ""
    						_sSQL += " DELETE AUX_ENTNF" 
							_sSQL += "  WHERE FORNECE = '" + sf1 -> f1_fornece + "'"
							_sSQL += "    AND DOC     = '" + sf1 -> f1_doc     + "'"
							if TCSQLExec (_sSQL) < 0
         						return
   							endif
						endif	
						U_SendMail ('compras@novaalianca.coop.br', "NF NÃO CONFORME COM A ORDEM DE COMPRA", _sMens, {})
					endif
				endif			     			
			endif
		endif				
	endif						
return
*/

// --------------------------------------------------------------------------
Static Function _Controle_PF()
	if sf1 -> f1_especie !='CTE' .and. sf1 -> f1_especie !='CTR' // não manda emails a partir de conhecimentos
		
		_aCols = {}
		aadd (_aCols, {'Documento'         ,    'left'  ,  ''})
		aadd (_aCols, {'Serie'             ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Emissao'        ,    'left'  ,  ''})
		aadd (_aCols, {'Dt.Entrada'        ,    'left'  ,  ''})
		aadd (_aCols, {'Fornecedor/Cliente',    'left'  ,  ''})
		aadd (_aCols, {'Transportador'     ,    'left'  ,  ''})
		aadd (_aCols, {'Produto'           ,    'left'  ,  ''})
		aadd (_aCols, {'Descricao'         ,    'left'  ,  ''})
		aadd (_aCols, {'Quantidade'        ,    'right' ,  '@E 999,999,999.99'})
		
		// Avisa Ambiental - Produtos Controlados pela Policia Federal
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_EMISSAO, SD1.D1_DTDIGIT"
		_oSQL:_sQuery += "      , SA2.A2_NOME"   // FORNECEDOR
	    _oSQL:_sQuery += "      , SA4.A4_NOME"  // TRANSPORTADOR
		_oSQL:_sQuery += "      , SD1.D1_COD, SD1.D1_DESCRI, SD1.D1_QUANT"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1"
	    _oSQL:_sQuery += " 		INNER JOIN SB1010 AS SB1"
		_oSQL:_sQuery += " 			ON (SB1.D_E_L_E_T_ = ''"	
		_oSQL:_sQuery += " 				AND SB1.B1_COD    = SD1.D1_COD"
		_oSQL:_sQuery += " 		        AND SB1.B1_CTRPF = '1')"
		_oSQL:_sQuery += "		INNER JOIN SF1010 AS SF1"
		_oSQL:_sQuery += "			ON (SF1.D_E_L_E_T_ = ''	"
		_oSQL:_sQuery += "    			AND SF1.F1_FILIAL   = SD1.D1_FILIAL"
		_oSQL:_sQuery += "    			AND SF1.F1_DOC      = SD1.D1_DOC"
		_oSQL:_sQuery += "    			AND SF1.F1_SERIE    = SD1.D1_SERIE"
		_oSQL:_sQuery += "    			AND SF1.F1_FORNECE  = SD1.D1_FORNECE"
		_oSQL:_sQuery += "    			AND SF1.F1_LOJA     = SD1.D1_LOJA)"
		_oSQL:_sQuery += "		INNER JOIN SA2010 AS SA2"
		_oSQL:_sQuery += "			ON (SA2.D_E_L_E_T_ = ''	"
		_oSQL:_sQuery += "				AND SA2.A2_COD  = SD1.D1_FORNECE"
		_oSQL:_sQuery += "				AND SA2.A2_LOJA = SD1.D1_LOJA)"
		_oSQL:_sQuery += "		INNER JOIN SA4010 AS SA4"
		_oSQL:_sQuery += "			ON (SA4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "				AND SA4.A4_COD = SF1.F1_TRANSP)"
		_oSQL:_sQuery += "  WHERE SD1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "    AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_oSQL:_sQuery += "    AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery += "    AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery += "    AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery += "    AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
		
		if len (_oSQL:Qry2Array (.T., .F.)) > 0
			_sMens = _oSQL:Qry2HTM ("PRODUTOS CONTROLADOS POLICIA FEDERAL - Entrada: " + dtoc(sf1 -> f1_dtdigit), _aCols, "", .F.)
			U_ZZUNU ({'053'}, "PRODUTOS CONTROLADOS POLICIA FEDERAL - Entrada: " + dtoc(sf1 -> f1_dtdigit), _sMens, .F., cEmpAnt, cFilAnt, "") // gestao ambiental
		endif
		
	endif				
return


Static Function _AtuATF()
	local i := 0
	
	if sf1 -> f1_especie !='CTE' .and. sf1 -> f1_especie !='CTR'
		// verifica se existe registro no ativo e atualiza a descricao
		_sQuery := ""
		_sQuery += " SELECT SD1.D1_ITEM, SD1.D1_COD, SD1.D1_DESCRI, SD1.D1_TOTAL"
		_sQuery += "      , SN1.N1_CBASE, SN1.N1_ITEM"
  		_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1"
  		_sQuery += "   		INNER JOIN SF4010 AS SF4"
		_sQuery += "   			ON (SF4.D_E_L_E_T_ = ''"
		_sQuery += "   				AND SF4.F4_CODIGO = SD1.D1_TES"
		_sQuery += "   				AND SF4.F4_ATUATF = 'S')"
		_sQuery += " 		INNER JOIN SN1010 AS SN1"
		_sQuery += " 			ON (SN1.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SN1.N1_FILIAL  = SD1.D1_FILIAL"
		_sQuery += " 				AND SN1.N1_FORNEC  = SD1.D1_FORNECE"
		_sQuery += " 				AND SN1.N1_LOJA    = SD1.D1_LOJA"
		_sQuery += " 				AND SN1.N1_NFISCAL = SD1.D1_DOC"
		_sQuery += " 				AND SN1.N1_NSERIE  = SD1.D1_SERIE"
		_sQuery += " 				AND SN1.N1_NFITEM  = SD1.D1_ITEM"
		_sQuery += " 				AND SN1.N1_CHAPA   = '')"
  		_sQuery += "  WHERE SD1.D_E_L_E_T_  = ''"
		_sQuery += "    AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_sQuery += "    AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_sQuery += "    AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_sQuery += "    AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_sQuery += "    AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
		_aAtivo := U_Qry2Array(_sQuery)
 		
 		if len(_aAtivo) > 0
 			// atualiza valor de aquisicao e descricao do item no ativo
 			for i=1 to len(_aAtivo)
 				sn1 -> (dbsetorder (1))
				sn1 -> (dbseek (xfilial ("SN1") + _aAtivo[i,5] + _aAtivo[i,6], .T.))
				reclock ("SN1", .F.)
					sn1 -> n1_descric = substr(_aAtivo[i,3],1,60)
					sn1 -> n1_vlaquis  = _aAtivo[i,4]
				msunlock ()		 
 			next
	    endif	
	    // verifica se existe o registro na tabela do CIAP e atualiza
	    _sQuery := ""
		_sQuery += " SELECT SD1.D1_FORNECE, SD1.D1_DTDIGIT, SD1.D1_DOC, SD1.D1_ITEM, SD1.D1_COD, SD1.D1_DESCRI"
     	_sQuery += "      , SF9.F9_CODIGO, SF9.F9_DESCRI"
     	_sQuery += "   FROM SD1010 AS SD1"
   		_sQuery += " 		INNER JOIN SF4010 AS SF4"
		_sQuery += " 			ON (SF4.D_E_L_E_T_ = ''"
	   	_sQuery += " 				AND SF4.F4_CODIGO = SD1.D1_TES"
   		_sQuery += " 				AND SF4.F4_ATUATF = 'S')"
		_sQuery += " 		INNER JOIN SF9010 AS SF9"
		_sQuery += " 			ON (SF9.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SF9.F9_FILIAL  = SD1.D1_FILIAL"
		_sQuery += " 				AND SF9.F9_FORNECE = SD1.D1_FORNECE"
		_sQuery += " 				AND SF9.F9_LOJAFOR = SD1.D1_LOJA"
		_sQuery += " 				AND SF9.F9_DOCNFE  = SD1.D1_DOC"
		_sQuery += " 				AND SF9.F9_SERNFE  = SD1.D1_SERIE"
		_sQuery += " 				AND SF9.F9_ITEMNFE = SD1.D1_ITEM)"
  		_sQuery += "  WHERE SD1.D_E_L_E_T_  = ''"
		_sQuery += "    AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_sQuery += "    AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_sQuery += "    AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_sQuery += "    AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_sQuery += "    AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
		_aCiap := U_Qry2Array(_sQuery)
 		
 		if len(_aCiap) > 0
 			// atualiza a descricao do item no CIAP
 			for i=1 to len(_aCiap)
 				sf9 -> (dbsetorder (1))
				sf9 -> (dbseek (xfilial ("SF9") + _aCiap[i,7], .T.))
				reclock ("SF9", .F.)
					sf9 -> f9_descri = substr(_aCiap[i,6],1,60)
					sf9 -> f9_funcit = substr(_aCiap[i,6],1,60)
					sf9 -> f9_chvnfe = fBuscaCpo ('SF1', 1, xfilial('SF1') + sf1 -> f1_doc + sf1 -> f1_serie + sf1 -> f1_fornece + sf1 -> f1_loja, "F1_CHVNFE")
				msunlock ()		 
 			next
 		endif
	    	
	endif		
return

// --------------------------------------------------------------------------
Static Function _HistNf()
//	local _sMsg := ""
	
	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SZN001"
	_oEvento:Texto	  = "Devolucao de Nota Fiscal. Motivo: " + alltrim(Posicione("SX5",1 ,xFilial("SX5")+"02"+alltrim(sd1 -> d1_motdev),"X5_DESCRI")) 
	_oEvento:NFSaida	  = sd1 -> d1_nfori
	_oEvento:SerieSaid = sd1 -> d1_seriori
	_oEvento:NFEntrada = sf1 -> f1_doc
	_oEvento:SerieEntr = sf1 -> f1_serie
	_oEvento:PedVenda  = ""
	_oEvento:Cliente   = sf1 -> f1_fornece
	_oEvento:LojaCli   = sf1 -> f1_loja
	_oEvento:Hist	  = "1"
	_oEvento:Status	  = "5"
	_oEvento:Sub	  	  = ""
	_oEvento:Prazo	  = 0
	_oEvento:Flag	  = .T.
	_oEvento:Grava ()
	
return
// --------------------------------------------------------------------------
Static Function _EmailLog()
		
	if sf1 -> f1_filial = '01'  // verifica so na matriz
		
		// Avisa interessados sobre entradas no alm. de devolucoes. - ALMOX 91
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select distinct D1_COD, D1_DESCRI, D1_QUANT, D1_UM"
		_oSQL:_sQuery += " from " + RetSQLName ("SD1") + " SD1"
		_oSQL:_sQuery += " where SD1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOCAL    = '91'"
		if sf1 -> f1_tipo = 'D'
			_sMsg = _oSQL:Qry2HTM ("NF devolucao '" + sf1 -> f1_doc + "' do cliente '" + sf1 -> f1_fornece + "' lançada no alm.91", NIL, "", .F.)
			if ! empty (_sMsg)
				U_ZZUNU ({"077"}, "NF devolucao alm.91", _sMsg, .F., cEmpAnt, cFilAnt)
			endif
		else
			_sMsg = _oSQL:Qry2HTM ("Movimentação de Entrada por NF: '" + sf1 -> f1_doc + "' do cliente '" + sf1 -> f1_fornece + "' lançada no alm.91", NIL, "", .F.)
			if ! empty (_sMsg)
				U_ZZUNU ({"077"}, "Movimentação de Entrada por NF no almox 91", _sMsg, .F., cEmpAnt, cFilAnt)
			endif			
		endif	
		
		// verifica almox 10
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select distinct D1_COD, D1_DESCRI, D1_QUANT, D1_UM"
		_oSQL:_sQuery += " from " + RetSQLName ("SD1") + " SD1"
		_oSQL:_sQuery += " where SD1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOCAL    = '10'"
		if sf1 -> f1_tipo = 'D'
			_sMsg = _oSQL:Qry2HTM ("NF devolucao '" + sf1 -> f1_doc + "' do cliente '" + sf1 -> f1_fornece + "' lançada no alm.10", NIL, "", .F.)
			if ! empty (_sMsg)
				U_ZZUNU ({"077"}, "NF devolucao alm.10", _sMsg, .F., cEmpAnt, cFilAnt)
			endif
		else
			_sMsg = _oSQL:Qry2HTM ("Movimentação de Entrada por NF: '" + sf1 -> f1_doc + "' do cliente '" + sf1 -> f1_fornece + "' lançada no alm.10", NIL, "", .F.)
			if ! empty (_sMsg)
				U_ZZUNU ({"077"}, "Movimentação de Entrada por NF no almox 10", _sMsg, .F., cEmpAnt, cFilAnt)
			endif			
		endif
	endif	
	
		// Avisa interessados sobre devolucoes de vendas.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select distinct D1_COD, D1_DESCRI, D1_QUANT, D1_UM, D1_DTDIGIT, D1_NFORI"
		_oSQL:_sQuery += " from " + RetSQLName ("SD1") + " SD1"
		_oSQL:_sQuery += " where SD1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
		if sf1 -> f1_tipo = 'D'
			_sMsg = _oSQL:Qry2HTM ("NF devolucao '" + sf1 -> f1_doc + "' do cliente '" + sf1 -> f1_fornece , NIL, "", .F.)
			if ! empty (_sMsg)
				U_ZZUNU ({"089"}, "NF devolucao de venda", _sMsg, .F., cEmpAnt, cFilAnt)
			endif
		endif	
		
return

// --------------------------------------------------------------------------
// Avisa o solicitante, quando for o caso, que seu pedido chegou.
Static Function _AvisaSoli ()
	local _sMsg     := ""
	local _oSQL     := NIL
	local _aItens   := {}
	local _nItem    := 0
	local _sUser    := ""
	local _aUser    := {}
	local _sDestin  := ""
	local _aAreaAnt := U_ML_SRArea ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT SC1.C1_USER, RTRIM (D1_COD), RTRIM (D1_DESCRI), D1_QUANT,"
	_oSQL:_sQuery +=        " D1_UM, SD1.D1_DOC, RTRIM (A2_NOME), SD1.D1_PEDIDO,"
	_oSQL:_sQuery +=        " SC1.C1_NUM, RTRIM(C1_DESCRI)"
	_oSQL:_sQuery += " from " + RetSQLName ("SD1") + " SD1,"
	_oSQL:_sQuery +=            RetSQLName ("SA2") + " SA2,"
	_oSQL:_sQuery +=            RetSQLName ("SC7") + " SC7,"
	_oSQL:_sQuery +=            RetSQLName ("SC1") + " SC1"
	_oSQL:_sQuery += " where SA2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=   " AND SA2.A2_COD      = SD1.D1_FORNECE"
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = SD1.D1_LOJA"
	_oSQL:_sQuery +=   " AND SC1.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SC1.C1_FILIAL   = SC7.C7_FILIAL"
	_oSQL:_sQuery +=   " AND SC1.C1_NUM      = SC7.C7_NUMSC"
	_oSQL:_sQuery +=   " AND SC1.C1_ITEM     = SC7.C7_ITEMSC"
	_oSQL:_sQuery +=   " AND SC1.C1_USER    != ''"
	_oSQL:_sQuery +=   " AND SC1.C1_DESCRI  != ''"
	_oSQL:_sQuery +=   " AND SC7.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SC7.C7_FILIAL   = SD1.D1_FILIAL"
	_oSQL:_sQuery +=   " AND SC7.C7_NUM      = SD1.D1_PEDIDO"
	_oSQL:_sQuery +=   " AND SC7.C7_ITEM     = SD1.D1_ITEMPC"
	_oSQL:_sQuery +=   " AND SD1.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_PEDIDO  != ''"
	_oSQL:_sQuery +=   " AND SD1.D1_ITEMPC  != ''"
	_oSQL:_sQuery += " ORDER BY C1_USER, RTRIM (C1_DESCRI)"
	_aItens = aclone (_oSQL:Qry2Array ())

	_nItem = 1
	do while _nItem <= len (_aItens)
		_sUser = _aItens [_nItem, 1]
		_sMsg = ''
		_sMsg += "NF '" + sf1 -> f1_doc + "' do fornecedor '" + sf1 -> f1_fornece + "' incluida no sistema:" + chr (13) + char (10) + chr (13) + char (10)
		do while _nItem <= len (_aItens) .and. _aItens [_nItem, 1] == _sUser
			_sMsg += 'Produto....: ' + _aItens [_nItem, 2] + ' - ' + _aItens [_nItem, 3] + chr (13) + chr (10)
			_sMsg += 'Quantidade.: ' + cvaltochar (_aItens [_nItem, 4]) + ' ' + _aItens [_nItem, 5] + chr (13) + chr (10)
			_sMsg += 'NF.........: ' + _aItens [_nItem, 6] + ' de ' + _aItens [_nItem, 7] + chr (13) + chr (10)
			_sMsg += 'Ped.compra.: ' + _aItens [_nItem, 8] + chr (13) + chr (10)
			_sMsg += 'Solicitacao: ' + _aItens [_nItem, 9] + ' - Descr.orig.: ' + _aItens [_nItem, 10] + chr (13) + chr (10)
			_sMsg += '------------------------------------------------------------------' + chr (13) + chr (10)
			_nItem ++
		enddo
		if ! empty (_sMsg)
			// Busca e-mail do solicitante
			psworder (1)  // Ordena arquivo de senhas por ID do usuario
			if PswSeek (_sUser, .T.)
				_aUser := PswRet ()
				_sDestin = _aUser [1, 14]
				if empty (_sDestin)
					U_AvisaTI ('Usuario sem e-mail no cadastro:' + _sUser + ' - ' + _aUser [1, 2])
				endif
			endif
			if ! empty (_sDestin)
				U_SendMail (_sDestin, 'Seu pedido chegou', _sMsg)
			endif
		endif
	enddo

	U_ML_SRArea (_aAreaAnt)
return

// --------------------------------------------------------------------------
// Atualiza status na tabela ZZX  --- essa rotina é usada pelo SF1140I
static function _AtuZZX (_zzxstatus)
//	local _oSQL      := NIL
	if sf1->f1_est != 'EX'
		if sf1->f1_especie = 'SPED' .or.  sf1->f1_especie = 'CTE' // Doc.Lançado
			DbSelectArea("ZZX")
			DbSetOrder(1)
			///F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_
			if dbseek (sf1 -> f1_filial + sf1 -> f1_doc + sf1 -> f1_serie + sf1 -> f1_fornece + sf1 -> f1_loja + sf1 -> f1_tipo, .F.)
				reclock ("ZZX", .F.)
					if ! empty (sf1 -> f1_chvnfe)
						ZZX -> ZZX_STATUS = '1'
					else
						ZZX -> ZZX_STATUS = '2'
					endif	
					ZZX -> ZZX_CSTAT = dtoc(sf1 -> f1_VADTINC) + ' - ' + sf1 -> f1_VAHRINC + ' - ' + sf1 -> f1_VAUSER
				msunlock ()
			endif
		endif	
	endif	 
return

	