// Programa:  MT100Agr
// Autor:     Robert Koch
// Data:      05/05/2008
// Descricao: P.E. apos a gravacao (exclusao tambem) da NF de entrada e fora da transacao.
//            Criado inicialmente para tratamento de controles de fretes.
//
// Historico de alteracoes:
// 19/05/2008 - Robert - Incluido tratamento para substituicao tributaria.
// 23/05/2008 - Robert - Removido tratamento para ST por que fica depois da contabilizacao.
// 18/08/2008 - Robert - Exclusao de dados de fretes serah chamada do P.E. SF1100E.
// 26/03/2012 - Robert - Chama gravacao de fretes mesmo nao sendo NF tipo CTR (casos de paletizacao).
// 21/03/2013 - Leandro DWT - Envio de e-mail para responsável pelo pedido de venda, caso exista divergência de valores com o conhecimento de frete.
// 12/04/2013 - Leandro DWT - Gravação de valores na tabela ZZN, quando existe divergência.
// 12/04/2013 - Leandro DWT - Deleta registros da ZZN quando documento de entrada é excluído.
// 08/03/2016 - Robert - Desabilitada montagem de mensagem de valores divergentes pois nao era enviada para ninguem. 
//                     - Soh chama a gravacao de fretes quando especie CTR ou CTE.
//
// 23/01/2018 - Catia  - Geração do titulo de indenizacao de comissoes
// 08/04/2019 - Catia  - include TbiConn.ch 
// 19/02/2021 - Robert - Inclusao de chamadas da funcao U_PerfMon() para metricas de performance (GLPI 9409).
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

User Function MT100Agr ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aSZH 	:= {}
	local _nLin		:= 0

	// Tratamento para controle de fretes
	if inclui  // Este P.E. eh chamado tambem na exclusao da nota.
		
		// Gravacao dos dados do frete e rateio de valores.
		
		if type ("_oClsFrtFr") == "O" //.and. alltrim (cEspecie) $ 'CTR/CTE/NF'
			U_FrtNFE ("I")
		endif
		
		// Se for nota de compra normal - verifica e atualiza ativo fixo
		if sf1 -> f1_tipo = "N" .and. sf1 -> f1_especie != 'SPED' .and. sf1 -> f1_especie != 'CTE' .and. sf1 -> f1_especie != 'CTR'
			_Geraind()
		endif

		// só grava valores na tabela se nota de entrada for de conhecimento de frete
		if alltrim(cEspecie) $  'CTR' .and. cTipo == 'N'

			// se for verdadeiro, é porque existe divergencia de valores no frete
			if _oClsFrtFr:_bvalor

				_sQuery := ''
				_sQuery += " SELECT DISTINCT(ZH_NFSAIDA), ZH_SERNFS, ZH_FORNECE, ZH_LOJA"
				_sQuery += " FROM " + RetSQLName ("SZH") + " SZH "
				_sQuery += " WHERE D_E_L_E_T_ = ''"
				_sQuery += " AND ZH_FILIAL  = '" + xfilial ("SZH") + "'"
				_sQuery += " AND ZH_NFFRETE = '" + cNFiscal + "'"

				_aSZH = aclone (U_Qry2Array (_sQuery))

				if len(_aSZH) == 0
					msgalert ('Nao foi encontrado nenhum registro na tabela de rateio por peso (SZH).')
				else

					// executa uma vez para cada nota de saída referente a este conhecimento de frete
					for _nLin = 1 to len (_aSZH)

						_cliente := POSICIONE('SF2',1,XFILIAL('SF2')+_aSZH[_nLin][1]+_aSZH[_nLin][2],'F2_CLIENTE')
						_loja := POSICIONE('SF2',1,XFILIAL('SF2')+_aSZH[_nLin][1]+_aSZH[_nLin][2],'F2_LOJA')
						_nomcli := POSICIONE('SA1',1,XFILIAL('SA1')+_cliente+_loja,'A1_NOME')
						_nomfor := POSICIONE('SA2',1,XFILIAL('SA2')+ca100for+cLoja,'A2_NOME')

						RecLock('ZZN',.t.)
						Replace ZZN_FILIAL with xFilial('ZZN')
						Replace ZZN_DOCENT with cNFiscal
						Replace ZZN_SERENT with cSerie
						Replace ZZN_FORN with ca100for
						Replace ZZN_LOJFOR with cLoja
						Replace ZZN_DOCSAI with _aSZH[_nLin][1]
						Replace ZZN_SERSAI with _aSZH[_nLin][2]
						Replace ZZN_CLIENT with _cliente
						Replace ZZN_LOJCLI with _loja
						Replace ZZN_STATUS with '1'
						//Replace ZZN_DTLIB with
						Replace ZZN_JUSTIF with ''
						MsUnLock()

						//_vlrsai := POSICIONE('SF2',1,XFILIAL('SF2')+_aSZH[_nLin][1]+_aSZH[_nLin][2],'F2_VALFAT')

						//_sMsg := ' Valores divergentes entre o conhecimento de frete "' + cSerie + ' / ' + cNFiscal + '" ' + chr (13) + chr (10)
						//_sMsg += ' do fornecedor "' + alltrim(_nomfor) + '" ' + chr (13) + chr (10)
						//_sMsg += ' com valor total de R$ ' + cvaltochar(SF1->F1_VALBRUT) + chr (13) + chr (10)
						//_sMsg += ' e a nota de saída "' + _aSZH[_nLin][2] + ' / ' + _aSZH[_nLin][1] + '" ' + chr (13) + chr (10)
						//_sMsg += ' do cliente "' + alltrim(_nomcli)+ '" ' + chr (13) + chr (10)
						//_sMsg += ' com valor de R$ ' + cvaltochar(_vlrsai) + ' !'
						//_sMsg += chr (13) + chr (10)
						//_sMsg += chr (13) + chr (10)
						//_sMsg += ' Favor, verificar estas informações e liberar ou bloquear este registro no controle de fretes !'

						//pegar e-mail do usuário
						//_user := Posicione('ZZ1',3,xFilial('ZZ1') + _aSZH[_nLin][1] + _aSZH[_nLin][2],'ZZ1_USER') // criar campo
						
						//PswOrder(1)
						//PswSeek(_user,.T.)
						//_aRetUser := PswRet(1)
						
						// _mail := upper(alltrim(_aRetUser[1,14]))
						
						// enviar e-mail para o gerente também
						//U_SendMail ('robert.koch@novaalianca.coop.br;'+alltrim(_mail), 'Valores divergentes nos fretes', _sMsg)
					next
				endif
			endif
		endif
	endif

	if !inclui .and. !altera //exclui
		dbselectarea('ZZN')
		dbsetorder(1)
		dbseek(xFilial('ZZN')+cSerie+cNFiscal+ca100for+cLoja)
		if found()
			while ZZN->ZZN_SERENT+ZZN->ZZN_DOCENT+ZZN->ZZN_FORN+ZZN->ZZN_LOJFOR == cSerie+cNFiscal+ca100for+cLoja
				reclock ('ZZN', .F.)
				ZZN -> (dbdelete ())
				msunlock ('ZZN')
				dbselectarea('ZZN')
				dbskip()
			enddo
		endif
	endif

	U_PerfMon ('F', 'GravacaoMATA100')  // Para metricas de performance

	U_ML_SRArea (_aAreaAnt)
Return

// --------------------------------------------------------------------------
// Gera titulo de indenizacao de comissoes com base em NF de compra de servico de comissoes.
static function _GeraInd ()
	
	//local _oSQL      := NIL
	//local _sVend     := ''
	local _aAutoSE2  := {}
	//local _aRetQry   := {}
	//local _dVencto   := ctod ('')
	local _aBkpSX1   := {}
	local _aAreaAnt  := U_ML_SRArea ()
	private lMsErroAuto	:= .f.
	private lMsHelpAuto	:= .f.
	private _sErroAuto  := ""
		
	// verifica se nos itens da NF tem oga item 7192 que eh o item pra comissao
	// e verifica se o vendedor esta ATIVO
	
	_sSQL := ""
	_sSQL += " SELECT A3_COD, A3_INDENIZ"
	_sSQL += "   FROM " + RetSQLName ("SA3") + " SA3"
	_sSQL += "  WHERE SA3.D_E_L_E_T_ != '*'"
	_sSQL += "    AND SA3.A3_FILIAL   = '" + xfilial ("SA3") + "'"
	_sSQL += "    AND SA3.A3_FORNECE  = '" + sf1 -> f1_fornece + "'"
	_sSQL += "    AND SA3.A3_LOJA     = '" + sf1 -> f1_loja + "'"
	_sSQL += "    AND SA3.A3_MSBLQL != '1'"
	_sSQL += "    AND SA3.A3_ATIVO  != 'N'"
	_sSQL += "    AND EXISTS (SELECT *"
	_sSQL += "                  FROM " + RetSQLName ("SD1") + " SD1 "
	_sSQL +=                 " WHERE SD1.D_E_L_E_T_ != '*'"
	_sSQL +=                  "  AND SD1.D1_FILIAL   = '" + xfilial ("SD1")   + "'"
	_sSQL +=                  "  AND SD1.D1_DOC      = '" + sf1 -> f1_doc     + "'"
	_sSQL +=                  "  AND SD1.D1_SERIE    = '" + sf1 -> f1_serie   + "'"
	_sSQL +=                  "  AND SD1.D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
	_sSQL +=                  "  AND SD1.D1_LOJA     = '" + sf1 -> f1_loja    + "'"
	_sSQL +=                  "  AND SD1.D1_COD      = '7192')"  // Produto 'comissao'
	_aVend = U_Qry2Array(_sSQL)
	
	if len (_aVend) > 0
		_windeniz = _aVend [1,2]
		// Encontra vencimento do titulo original.
		_sSQL := ""                                                                                            
		_sSQL += " SELECT E2_VENCTO"
		_sSQL += "   FROM " + RetSQLName ("SE2") + " SE2 "
		_sSQL += "  WHERE SE2.D_E_L_E_T_ != '*'"
		_sSQL += "    AND SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
		_sSQL += "    AND SE2.E2_FORNECE  = '" + sf1 -> f1_fornece + "'"
		_sSQL += "    AND SE2.E2_LOJA     = '" + sf1 -> f1_loja    + "'"
		_sSQL += "    AND SE2.E2_NUM      = '" + sf1 -> f1_doc     + "'"
		_sSQL += "    AND SE2.E2_PREFIXO  = '" + sf1 -> f1_serie   + "'"
		_aVencto = U_Qry2Array(_sSQL)
		
		if len(_aVencto) > 0 
			_wvencto  = _aVencto[1,1]
			_wsimples = fbuscacpo ("SA2", 1, xfilial ("SA2") + sf1 -> f1_fornece + sf1 -> f1_loja , "A2_SIMPNAC")
			
			// monta valor da indenizacao a partir do titulo de comissao
			_wvalor = sf1 -> f1_valbrut /12
			_wvlrir = 0
			// valida valor do IR do titulo de indenizacao
			if _windeniz = "S" .and. _wsimples != '1'
				_wvlrir   = ROUND(_wvalor * 0.15 , 2)
				if _wvlrir < 10
					_wvlrir = 0 	
				endif
			endif		
					
			// Gera titulo no contas a pagar.
			_aAutoSE2 := {}
			aadd (_aAutoSE2, {"E2_PREFIXO", 'IND'							, NIL})
			if _windeniz = "N"
				aadd (_aAutoSE2, {"E2_TIPO"   , "PRI"						, Nil})
			else
				// a indenização eh paga mensalmente gera titulo normal tipo RC (recibo)
				aadd (_aAutoSE2, {"E2_TIPO"   , "RC"						, Nil})	
			endif		
			aadd (_aAutoSE2, {"E2_NUM"    , sf1 -> f1_doc					, Nil})
			aadd (_aAutoSE2, {"E2_FORNECE", sf1 -> f1_fornece				, Nil})
			aadd (_aAutoSE2, {"E2_LOJA"   , sf1 -> f1_loja					, Nil})
			aadd (_aAutoSE2, {"E2_EMISSAO", sf1 -> f1_emissao				, Nil})
			aadd (_aAutoSE2, {"E2_NATUREZ", '120312'						, Nil})
			aadd (_aAutoSE2, {"E2_CODRET",  '9385'							, Nil})
			aadd (_aAutoSE2, {"E2_VENCTO" , _wvencto						, Nil})
			// nao pode ser dessa forma tem que fazer o calculo do valor do IRRF de 15 % fixo - ver depois ainda
			aadd (_aAutoSE2, {"E2_HIST"   , 'INDENIZACAO 1/12 COMISSAO'	    , Nil})
			aadd (_aAutoSE2, {"E2_PARCELA", ''								, Nil})
			aadd (_aAutoSE2, {"E2_VACHVEX", 'INDENIZ 1/12'					, Nil})
			aadd (_aAutoSE2, {"E2_ORIGEM" , 'CUST'							, Nil})
			aadd (_aAutoSE2, {"E2_VALOR"  , _wvalor 				        , Nil})
			aadd (_aAutoSE2, {"E2_IRRF"   , _wvlrir						    , Nil})
			aadd (_aAutoSE2, {"E2_VLIR"   , _wvlrir						    , Nil})
			aadd (_aAutoSE2, {"E2_VRETIR" , _wvlrir						    , Nil})
			if _wvlrir > 0
				aadd (_aAutoSE2, {"E2_DIRF"   , '1'					 		 , Nil})
			endif
			_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
			
			// salva parametros do documento de entrada
			//_aBkpSX1 = U_SalvaSX1 ('FIN050')  // Salva parametros da rotina.
			U_GravaSX1 ('FIN050', "01", 1)
			U_GravaSX1 ('FIN050', "04", 1)
			
			lMsErroAuto	:= .f.
			lMsHelpAuto	:= .f.
			_sErroAuto  := ""
			dbselectarea ("SE2")
			dbsetorder (1)
			MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 3)
			if lMsErroAuto
				u_help ("Erro na rotina automatica de titulo de indenizacao 1/12: no contas a pagar:" + U_LeErro (memoread (NomeAutoLog ())) + _sErroAuto)
				_lContinua = .F.
				MostraErro()
			endif
			
			// Restaura backup dos parametros da rotina.
			U_SalvaSX1 ('FIN050' , _aBkpSX1)
			
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
	
	//private lMsErroAuto	:= .f.
	//private lMsHelpAuto	:= .f.
	//private _sErroAuto  := ""
	//private aFlagCTB := {}
			
return
