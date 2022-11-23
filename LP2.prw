// Programa:  LP2
// Autor:     Robert Koch
// Data:      01/10/2015
// Descricao: Execblock generico para lancamentos padronizados.
//
// Historico de alteracoes:
// 06/11/2015 - Robert - Nao tinha tipo de retorno definido quando nao encontrava algum dado (mostrava msg, mas retornava NIL).
// 26/01/2016 - Robert - Nao mostra mais mensagem em tela quando tipo de produto sem tratamento.
// 27/01/2016 - Robert - Criado parametro _sLPad para depuracao.
// 26/04/2016 - Robert - Funcao U_Help alterada para U_AvisaTI para nao parar processos grandes como a contabilizacao do custo medio, por exemplo.
// 14/11/2016 - Robert - Tratamentos para novos tipos no CTA_TP_EST
// 22/12/2016 - Catia  - Tratamentos tipo PP no CTA_TP_EST e alterado US para UC que eh uso e consumo
// 13/04/2018 - Catia  - Tratamentos tipo MM no CTA_TP_EST
// 18/09/2019 - Robert - Quando CC coml.externo inativo, migra para coml.interno no CC debito (GLPI 6696)
// 21/11/2019 - Robert - Criados retornos de informacoes do SN4 (transf.ativo imob.)
// 08/12/2021 - Robert - Alterado envio de avisos para TI (passa a usar classe ClsAviso).
//                     - Ao buscar repres.da NF orig. de venda, queria que esta fosse tipo D. Alterado para tipo N.
// 01/09/2022 - Robert - Melhorias ClsAviso.
// 09/09/2022 - Robert - Melhorias avisos.
// 02/10/2022 - Robert - Trocado grpTI por grupo 122 no envio de avisos.
// 07/10/2022 - Robert - Envia copia dos avisos de erro para grupo 144 (coord.contabil)
// 27/10/2022 - Robert - Declaracao da variavel local _oAviso
// 10/11/2022 - Robert - Pequena melhoria nos avisos.
// 22/11/2022 - Robert - Para tipo CTA_TP_VEND, retornar sempre CC=164006 quando filial 16 (Sara via Spark)
//

// --------------------------------------------------------------------------
User Function LP2 (_sQueRet, _sTipoProd, _sRepres, _nRecnoSD1, _sLPad, _sTpAtivo)
	local _aAreaAnt  := U_ML_SRArea ()
	local _xRet      := NIL
	local _sWhere    := ''
	local _oSQL      := NIL
	local _oAviso    := NIL

//	u_log ('Parametros recebidos:', _sQueRet, _sTipoProd, _sRepres, _nRecnoSD1, _sLPad, _sTpAtivo)

 	_sQueRet = alltrim (upper (iif (_sQueRet == NIL, '', _sQueRet)))

	do case
	case _sQueRet = "CTA_TP_EST"
		do case
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "BN" ; _xRet = "101030101023"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "CL" ; _xRet = "101030301008"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "EP" ; _xRet = "101030301005"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "II" ; _xRet = "101030301004"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "MA" ; _xRet = "101030301004"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "MB" ; _xRet = "101030301006"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "ME" ; _xRet = "101030101016"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "MM" ; _xRet = "101030301002"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "MP" ; _xRet = "101030101014"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "MR" ; _xRet = "101030101025"  // MERCADORIAS P/ REVENDA
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "MT" ; _xRet = "101030301007"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "PA" ; _xRet = "101030101011"  // ENTRADA PRODUCAO - PROD ACABADOS    
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "PI" ; _xRet = "101030101012"  // PRODUTOS SEMI ACABADOS EM ELABORACAO    
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "PP" ; _xRet = "101030101013"  // PRODUTO EM PROCESSO
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "PS" ; _xRet = "101030101015"  // MATERIAL SECUNDARIO
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "UC" ; _xRet = "101030301001"
			case valtype (_sTipoProd) == "C" .and. _sTipoProd == "VD" ; _xRet = "101030101013"  // VINHOS E DERIVADOS
			otherwise

			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = "Tipo produto " + cvaltochar (_sTipoProd) + " sem tratamento LPAD " + _sLPad
			_oAviso:Texto     := "LPAD " + cvaltochar (_sLPad)
			_oAviso:Texto     += " Tipo prod:" + cvaltochar (_sTipoProd)
			_oAviso:Texto     += " Retorno solicitado:" + _sQueRet
			_oAviso:Texto     += " Pilha de chamadas: " + U_LogPCham (.f.)
			_oAviso:InfoSessao = .T.
			_oAviso:Grava ()

			// Copia do aviso para responsavel contabilidade.
			_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
			_oAviso:Grava ()

			_xRet = ''
		endcase


	case _sQueRet = "CTA_TP_VEND"
		if valtype (_sRepres) == 'C'
			sa3 -> (dbsetorder (1))
			if ! sa3 -> (dbseek (xfilial ("SA3") + _sRepres, .F.))

				_oAviso := ClsAviso ():New ()
				_oAviso:Tipo       = 'E'
				_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
				_oAviso:Titulo     = "Vendedor nao encontrado LPAD " + _sLPad
				_oAviso:Texto     := "Vendedor nao encontrado na tabela SA3 - LPAD " + cvaltochar (_sLPad)
				_oAviso:Texto     += " Repres:" + cvaltochar (_sRepres)
				_oAviso:Texto     += " Retorno solicitado:" + _sQueRet
				_oAviso:Texto     += " Pilha de chamadas: " + U_LogPCham (.f.)
				_oAviso:InfoSessao = .T.
				_oAviso:Grava ()

				// Copia do aviso para responsavel contabilidade.
				_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
				_oAviso:Grava ()

				_xRet = ''
			else
				do case
					case cFilAnt == '16'
						_xRet = '164006'
					case sa3 -> a3_vaTpCon == "1"
						_xRet = cFilAnt + "4001"
					case sa3 -> a3_vaTpCon == "2"
						_xRet = cFilAnt + "4006"
					case sa3 -> a3_vaTpCon == "3"
						_xRet = cFilAnt + "4003"
					otherwise

						_oAviso := ClsAviso ():New ()
						_oAviso:Tipo       = 'E'
						_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
						_oAviso:Titulo     = "Campo A3_VATPCON nao informado no representante - LPAD " + _sLPad
						_oAviso:Texto     := "LPAD " + cvaltochar (_sLPad)
						_oAviso:Texto     += " Campo A3_VATPCON (" + alltrim (RetTitle ("A3_VATPCON")) + ") nao informado no cadastro do vendedor."
						_oAviso:Texto     += " Repres:" + sa3 -> a3_cod
						_oAviso:Texto     += " Retorno solicitado:" + _sQueRet
						_oAviso:Texto     += " Pilha de chamadas: " + U_LogPCham (.f.)
						_oAviso:InfoSessao = .T.
						_oAviso:Grava ()

						// Copia do aviso para responsavel contabilidade.
						_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
						_oAviso:Grava ()

						_xRet = ''
				endcase

				// CC deve estar ativo. Caso contrario, assume coml.interno.
				ctt -> (dbsetorder (1))  // CTT_FILIAL, CTT_CUSTO
				if ctt -> (dbseek (xfilial ("CTT") + _xRet, .F.)) .and. ctt -> ctt_bloq == '1'
					_xRet = cFilAnt + "4001"
				endif
			endif
		else

			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = "LPAD " + cvaltochar (_sLPad) + ": Codigo de vendedor nao informado."
			_oAviso:Texto     := "LPAD " + cvaltochar (_sLPad)
			_oAviso:Texto     += " Recebi parametro _sRepres do tipo " + valtype (_sRepres)
			_oAviso:Texto     += " Retorno solicitado:" + _sQueRet
			_oAviso:Texto     += " Pilha de chamadas: " + U_LogPCham (.f.)
			_oAviso:InfoSessao = .T.
			_oAviso:Grava ()

			// Copia do aviso para responsavel contabilidade.
			_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
			_oAviso:Grava ()

			_xRet = ''
		endif

	case _sQueRet = "VEND_NF_ORI"
		if valtype (_nRecnoSD1) == 'N'
			sd1 -> (dbgoto (_nRecnoSD1))
			if sd1 -> d1_tipo == 'N'  //'D'
				sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL
				if sf2 -> (dbseek (xfilial ("SF2") + sd1 -> d1_nfori + sd1 -> d1_seriori, .F.))
					_xRet = sf2 -> f2_vend1
				else

					_oAviso := ClsAviso ():New ()
					_oAviso:Tipo       = 'E'
					_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
					_oAviso:Titulo     = "Inconsistencia lcto padrao " + _sLPad
					_oAviso:Texto      = "LPAD '" + cvaltochar (_sLPad) + "': NF orig. venda '" + sd1 -> d1_nfori + "/" + sd1 -> d1_seriori + "' nao encontrada'
					_oAviso:InfoSessao = .T.
					_oAviso:Grava ()

					// Copia do aviso para responsavel contabilidade.
					_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
					_oAviso:Grava ()

					_xRet = ''
				endif
			else
				_xRet = ''
			endif
		else
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = "Inconsistencia lcto padrao " + _sLPad
			_oAviso:Texto      = "LPAD '" + cvaltochar (_sLPad) + "': Numero do RECNO da tabela SD1 nao informado na rotina " + procname ()
			_oAviso:InfoSessao = .T.
			_oAviso:Grava ()

			// Copia do aviso para responsavel contabilidade.
			_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
			_oAviso:Grava ()

			_xRet = ''
		endif


	// Buscar dados da tabela SN4 (quando entrada por transf. ativo imob. entre filiais)
	case left (_sQueRet, 4) = "SN4_"
		_oSQL := ClsSQL ():New ()

		_sWhere := ''
		_sWhere += " FROM " + RetSQLName ("SD1") + " SD1,"
		_sWhere +=            RetSQLName ("SN4") + " SN4 "
		_sWhere += " WHERE SD1.R_E_C_N_O_ = " + cvaltochar (_nRecnoSD1)
		_sWhere +=   " AND SN4.D_E_L_E_T_ = ''"
		_sWhere +=   " AND N4_FILIAL      = SD1.D1_FILIAL"
		_sWhere +=   " AND SN4.N4_NOTA    = SD1.D1_DOC"
		_sWhere +=   " AND SN4.N4_SERIE   = SD1.D1_SERIE"
		_sWhere +=   " AND SN4.N4_TIPO    = '" + _sTpAtivo + "'"
		_sWhere +=   " and SN4.N4_OCORR = '04'"  // 04 = entrada

		do case
		case _sQueRet = "SN4_DPR_ACUM"  // Buscar valor da depreciacao acumulada do ativo imob. quando entrada por transf. entre filiais
			_xRet = 0
			_oSQL:_sQuery := "SELECT N4_VLROC1"
			_oSQL:_sQuery += _sWhere
			_oSQL:_sQuery += " AND SN4.N4_TIPOCNT = '4'"

		case _sQueRet = "SN4_VLR_AQ"  // Buscar valor de aquisicao do ativo imob. quando entrada por transf. entre filiais
			_xRet = 0
			_oSQL:_sQuery := "SELECT N4_VLROC1"
			_oSQL:_sQuery += _sWhere
			_oSQL:_sQuery += " AND SN4.N4_TIPOCNT = '1'"

		case _sQueRet = "SN4_CONTA_DEPR"  // Buscar a conta contabil de depreciacao do bem
			_xRet = ''
			_oSQL:_sQuery := "SELECT N4_CONTA"
			_oSQL:_sQuery += _sWhere
			_oSQL:_sQuery += " AND SN4.N4_TIPOCNT = '4'"

		case _sQueRet = "SN4_CONTA_AQUIS"  // Buscar a conta contabil de aquisicao do bem
			_xRet = ''
			_oSQL:_sQuery := "SELECT N4_CONTA"
			_oSQL:_sQuery += _sWhere
			_oSQL:_sQuery += " AND SN4.N4_TIPOCNT = '1'"

		otherwise

			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = "Inconsistencia lcto padrao " + _sLPad
			_oAviso:Texto      = "LPAD '" + cvaltochar (_sLPad) + "': Sem tratamento para requisicao do tipo '" + _sQueRet + "' no programa " + procname ()
			_oAviso:InfoSessao = .T.
			_oAviso:Grava ()

			// Copia do aviso para responsavel contabilidade.
			_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
			_oAviso:Grava ()

		endcase
//		_oSQL:Log ()
		_xRet := _oSQL:RetQry()

	otherwise

		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Titulo     = "Inconsistencia lcto padrao " + _sLPad
		_oAviso:Texto      = "LPAD '" + cvaltochar (_sLPad) + "': Tipo de retorno '" + _sQueRet + "' sem tratamento no programa " + procname ()
		_oAviso:InfoSessao = .T.
		_oAviso:Grava ()

		// Copia do aviso para responsavel contabilidade.
		_oAviso:DestinZZU  = {'144'}  // 144 = grupo de coordenacao contabil
		_oAviso:Grava ()

	endcase

	U_ML_SRArea (_aAreaAnt)
//	u_log ("Retornando:", _xRet)
return _xRet
