// Programa: M110STTS
// Autor:    Robert Koch
// Data:     30/12/2008
// Funcao:   PE apos gravacao / exclusao da solicitacao de compra.
//           Criado inicialmente para envio de e-mail.
//
// Historico de alteracoes:
// 18/04/2012 - Fabiano - Incluso o email do alexandre.nunes, removido mateus.martins 
// 27/02/2014 - Robert  - Incluidos campos de quantidade e unidade de medida.
//                      - Passa a notificar usuarios com base na tabela ZZU.
// 05/08/2014 - Catia   - Incluir o codigo do produto no email das solicitacoes 
// 11/08/2014 - Robert  - Melhorada mensagem quando alteracao de solicitacao.
//                      - Envia copia do e-mail para o usuario atual.
// 29/08/2014 - Catia   - Incluir o codigo do fornecedor no email das solicitacoes
// 28/09/2015 - Robert  - Incluida coluna com a quantidade por embalagem.
// 22/06/2016 - Robert  - Seleciona indice 1 do arquivo de usuarios antes de buscar o usuario atual.
// 27/06/2016 - Catia   - alterado envio para a rotina padrao usando ZZU, e opção de enviar solicitacoes excluidas tambem 
// 11/11/2016 - Robert  - Passa a enviar e-mail para compras@nova... e nao mais para o grupo 017 do ZZU.
// 05/07/2019 - Andre   - Removido notificações aos usuários por emails.
// 11/07/2019 - Andre   - Adicionado notificação aos usuários por e-mail somente em casos de alteração de solicitacao.
// 02/09/2019 - Andre   - Solicitações para itens da manutenção, TIPO = MM, e-mail é enviado para todos os participantes do grupo da manutenção.
// 06/04/2020 - Robert  - Tratamento para opcao M no campo C1_VAPROSE.
// 13/05/2020 - Sandra  - Retirado e-mail de compras@... Para não receber mais e-mail conforme chamado GLPI 7867.
// 26/06/2020 - Cláudia - Retirado o envio de e-mail conforme solicitação GLPI:8105
//
// ----------------------------------------------------------------------------------------------------------------------
user function M110STTS ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _sMsg      := ""
	local _sNumPed   := ParamIXB [1]
	local _sSolicit  := ""
	local _sComCopia := ""
	local _aUser     := {}
	local _sTo       := ""
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SC1.C1_ITEM, SC1.C1_PRODUTO, SC1.C1_DESCRI, SC1.C1_QUANT, SC1.C1_UM"
	_oSQL:_sQuery += "      , B1_QE, B1_TIPO"
//	_oSQL:_sQuery += "      , CASE WHEN SC1.C1_VAPROSE = 'P' THEN 'Produto' ELSE 'Servico' END AS PROD_SER"
	_oSQL:_sQuery += "      , CASE SC1.C1_VAPROSE WHEN 'P' THEN 'Produto' WHEN 'S' THEN 'Servico' WHEN 'M' THEN 'Mensalidade' ELSE SC1.C1_VAPROSE END AS PROD_SER"
	_oSQL:_sQuery += "      , SC1.C1_DATPRF, SC1.C1_VAENCAM"
	_oSQL:_sQuery += "      , SC1.C1_VACODM1, SC1.C1_FORNECE"
	_oSQL:_sQuery += "   FROM SC1010 AS SC1"
	_oSQL:_sQuery += "   		INNER JOIN SB1010 AS SB1"
	_oSQL:_sQuery += "   			ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "   				AND SB1.B1_COD = SC1.C1_PRODUTO)"
	_oSQL:_sQuery += "  WHERE SC1.C1_FILIAL  = '" + xfilial ("SC1")   + "'"
	_oSQL:_sQuery += "    AND SC1.C1_NUM     = '" + _sNumPed + "'"
	if inclui .or. altera
		_oSQL:_sQuery += "    AND SC1.D_E_L_E_T_ = ''"
	else
		_oSQL:_sQuery += "    AND SC1.D_E_L_E_T_ = '*'"
	endif   			 
   		
	if len (_oSQL:Qry2Array (.T., .F.)) > 0
	
		_sSolicit = alltrim (sc1 -> c1_Solicit)
	
		// Se possivel, gera copia para o usuario atual.
		PswOrder(1)
		if PswSeek (__cUserID, .T.)
			_aUser := PswRet ()
			_sComCopia = _aUser [1, 14]
		endif
	
		_sMsg += "Numero solicitacao: " + _sNumPed + chr (13) + chr (10)
		_sMsg += "Usuario: " + _sSolicit + chr (13) + chr (10)
		
		// manda email avisando que existem condiçoes de pagamento diferentes nas OC atendidas para essa nota
		_aCols = {}
		aadd (_aCols, {'Item' 		  ,    'left'  ,  ''})
		aadd (_aCols, {'Codigo'       ,    'left'  ,  ''})
		aadd (_aCols, {'Descricao'    ,    'left'  ,  ''})
		aadd (_aCols, {'Quant'        ,    'left'  ,  ''})
		aadd (_aCols, {'Un.med'       ,    'left'  ,  ''})
		aadd (_aCols, {'Qt.por embal' ,    'left'  ,  ''})
		aadd (_aCols, {'Tipo        ' ,    'left'  ,  ''})
		aadd (_aCols, {'Prod/serv.'   ,    'left'  ,  ''})
		aadd (_aCols, {'Previsao'     ,    'left'  ,  ''})
		aadd (_aCols, {'Encaminhado'  ,    'left'  ,  ''})
		aadd (_aCols, {'Detalhes'     ,    'left'  ,  ''})
		aadd (_aCols, {'Fornecedor'   ,    'left'  ,  ''})
		
		//_sTo = 'compras@novaalianca.coop.br' + iif (! empty (_sComCopia), ';' + _sComCopia, '')
		//u_log (_sTo)

		do case // Notifica usuarios.
			case inclui
				if (SB1->B1_TIPO) == 'MM' 
					_sMsg += _oSQL:Qry2HTM ("Nova solicitacao de compras cadastrada: ", _aCols, "", .F.)
					U_ZZUNU ({'042'}, "Nova solic. compras incluida por " + _sSolicit, _sMsg, .F., cEmpAnt, cFilAnt, "") // MANUTENCAO
					//U_SendMail (_sTo, "Solic. compras '" + alltrim (_sNumPed) + "' INCLUIDA por " + _sSolicit, _sMsg, {})
				else	 
					_sMsg += _oSQL:Qry2HTM ("Nova solicitacao de compras cadastrada: ", _aCols, "", .F.)
					//U_SendMail (_sTo, "Solic. compras '" + alltrim (_sNumPed) + "' INCLUIDA por " + _sSolicit, _sMsg, {})
					//U_SendMail (_sTo, "Nova solic. compras incluida por " + _sSolicit, _sMsg, {})
				endif
		    case altera
		    	if (SB1->B1_TIPO) == 'MM' 
					_sMsg += _oSQL:Qry2HTM ("Solicitacao compras ALTERADA:", _aCols, "", .F.)
					U_ZZUNU ({'042'}, "Nova solic. compras incluida por " + _sSolicit, _sMsg, .F., cEmpAnt, cFilAnt, "") // MANUTENCAO
					//U_SendMail (_sTo, "Solic. compras '" + alltrim (_sNumPed) + "' ALTERADA por " + _sSolicit, _sMsg, {})
				else
					_sMsg += _oSQL:Qry2HTM ("Solicitacao compras ALTERADA:", _aCols, "", .F.)
					//U_SendMail (_sTo, "Solic. compras '" + alltrim (_sNumPed) + "' ALTERADA por " + _sSolicit, _sMsg, {})
				endif
			OtherWise
				if (SB1->B1_TIPO) == 'MM' 
					_sMsg += _oSQL:Qry2HTM ("Solicitacao compras EXCLUIDA:", _aCols, "", .F.)
					U_ZZUNU ({'042'}, "Nova solic. compras incluida por " + _sSolicit, _sMsg, .F., cEmpAnt, cFilAnt, "") // MANUTENCAO
					//U_SendMail (_sTo, "Solic. compras '" + alltrim (_sNumPed) + "' EXCLUIDA por " + _sSolicit, _sMsg, {})
				else
					_sMsg += _oSQL:Qry2HTM ("Solicitacao compras EXCLUIDA:", _aCols, "", .F.)
					//U_SendMail (_sTo, "Solic. compras '" + alltrim (_sNumPed) + "' EXCLUIDA por " + _sSolicit, _sMsg, {})
				endif
		endcase
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)	
										
return