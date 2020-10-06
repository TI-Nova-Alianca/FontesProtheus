// Programa:  AJ_Comis
// Autor:     Robert Koch
// Data:      27/07/2013
// Descricao: Ajustes manuais em comissoes, pois o comercial vive fazendo pedidos errados...
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Alteracao
// #Descricao         #Ajustes manuais em comissoes
// #PalavasChave      #comissoes #ajuste
// #TabelasPrincipais #SF2 #SD2 #SE1 #SE3
// #Modulos           #FAT
//
// Historico de alteracoes:
// 10/07/2015 - Robert  - Valida usuarios do grup 048 (antes era apenas Robert/Administrador).
//                      - Envia evento tambem para a controladoria.
// 28/07/2017 - Robert  - Bloqueava quando a NF tinha diferentes % de comissao. Agora apenas pede confirmacao.
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop 
//
// -----------------------------------------------------------------------------------------------------------------
User Function AJ_Comis ()
	Private cPerg1  := "AJ_COMIS1"
	Private cPerg2  := "AJ_COMIS2"

	// Verifica se o usuario tem liberacao para uso desta rotina.

	//if ! U_ZZUVL ('048', __cUserID, .T., cEmpAnt, cFilAnt)
	if ! U_ZZUVL ('048', __cUserID, .T.)
		return
	endif

	_ValidPerg()
	pergunte (cPerg1, .T.)
	
	processa ({||_AndaLogo ()})
	
//	do while pergunte (cPerg1, .T.)
//		processa ({||_AndaLogo ()})
//	enddo
return
//
// --------------------------------------------------------------------------
Static Function _AndaLogo ()
	local _oSQL      := NIL
	local _aNF       := {}
	local _nNF       := 0
	local _sWhereSE1 := ""
	local _sWhereSE3 := ""
	local _aPed      := {}
	local _nPed      := 0
	local _sVend1Ant := ""
	local _sVend2Ant := ""
	local _nCom1Ant  := 0
	local _nCom2Ant  := 0
	local _lContinua := .T.
	local _oEvento   := NIL
	//local _sMsg      := ""
	local _aPagas    := {}
	//local _nPaga     := 0
	local _aEventos  := {}
	local _nEvento   := 0
	
	// Apenas para ter regua de processamento.
	procregua (1)
	
	if _lContinua .and. empty (mv_par01) .and. empty (mv_par02)
		u_help ("Informe pedido ou NF")
		_lContinua = .F.
	endif
	
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA,"
		_oSQL:_sQuery +=        " COUNT (DISTINCT D2_COMIS1), COUNT (DISTINCT D2_COMIS2),"
		_oSQL:_sQuery +=        " MAX (D2_COMIS1), MAX (D2_COMIS2), "
		_oSQL:_sQuery +=        " F2_VEND1, F2_VEND2"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SF2") + " SF2, "
		_oSQL:_sQuery +=              RetSQLName ("SD2") + " SD2 "
		_oSQL:_sQuery +=  " WHERE SF2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SD2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SF2.F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_oSQL:_sQuery +=    " AND SD2.D2_FILIAL  = SF2.F2_FILIAL"
		_oSQL:_sQuery +=    " AND SD2.D2_DOC     = SF2.F2_DOC"
		_oSQL:_sQuery +=    " AND SD2.D2_SERIE   = SF2.F2_SERIE"
		_oSQL:_sQuery +=    " AND SD2.D2_TIPO    = 'N'"
		if ! empty (mv_par01)
			_oSQL:_sQuery +=    " AND SD2.D2_PEDIDO  = '" + mv_par01 + "'"
		endif
		if ! empty (mv_par02)
			_oSQL:_sQuery +=    " AND SD2.D2_DOC     = '" + mv_par02 + "'"
		endif
		if ! empty (mv_par03)
			_oSQL:_sQuery +=    " AND SD2.D2_SERIE   = '" + mv_par03 + "'"
		endif
		_oSQL:_sQuery += " GROUP BY SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA, F2_VEND1, F2_VEND2"
		u_log (_oSQL:_sQuery)
		_aNF = aclone (_oSQL:Qry2Array ())
		u_log (_anf)
		if empty (_aNF)
			u_help ("Nao foram encontradas notas fiscais. Sugestao: informar apenas o pedido ou apenas a nota.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		for _nNF = 1 to len (_aNF)
			
			if _aNF [_nNF, 5] > 1
				_lContinua = u_msgnoyes ("Encontrei notas com diferentes percentuais de comissao. Contirma a regravacao de todas com o mesmo percentual?")
			endif

			if _lContinua
				_sWhereSE3 := ""
				_sWhereSE3 +=  " WHERE D_E_L_E_T_ = ''"
				_sWhereSE3 +=    " AND E3_FILIAL  = '" + xfilial ("SE3") + "'"
				_sWhereSE3 +=    " AND E3_NUM     = '" + _aNF [_nNF, 1] + "'"
				_sWhereSE3 +=    " AND E3_PREFIXO = '" + _aNF [_nNF, 2] + "'"
				_sWhereSE3 +=    " AND E3_CODCLI  = '" + _aNF [_nNF, 3] + "'"
				_sWhereSE3 +=    " AND E3_LOJA    = '" + _aNF [_nNF, 4] + "'"
	
				_sWhereSE1 := ""
				_sWhereSE1 +=  " WHERE D_E_L_E_T_ = ''"
				_sWhereSE1 +=    " AND E1_FILIAL  = '" + xfilial ("SE1") + "'"
				_sWhereSE1 +=    " AND E1_NUM     = '" + _aNF [_nNF, 1] + "'"
				_sWhereSE1 +=    " AND E1_PREFIXO = '" + _aNF [_nNF, 2] + "'"
				_sWhereSE1 +=    " AND E1_CLIENTE = '" + _aNF [_nNF, 3] + "'"
				_sWhereSE1 +=    " AND E1_LOJA    = '" + _aNF [_nNF, 4] + "'"
	
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT SE3.E3_VEND, SE3.E3_COMIS, SE3.E3_DATA"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE3") + " SE3 "
				_oSQL:_sQuery += _sWhereSE3
				_oSQL:_sQuery +=    " AND SE3.E3_DATA   != ''"
				u_log (_oSQL:_sQuery)
				_aPagas = aclone (_oSQL:Qry2Array ())
				if !empty (_aPagas)
					//if ! msgnoyes ("Existe comissao ja paga para a NF '" + _aNF [_nNF, 1] + "'. Deseja continuar mesmo assim?")
					u_help ("Existe comissao ja paga para a NF '" + _aNF [_nNF, 1] + "'. Providencie o estorno desse pagamento antes de continuar.")
					_lContinua = .F.
					//endif
				endif
			endif

			// Inicializa parametros com os dados atuais da nota.
			if _lContinua
				U_GravaSX1 (cPerg2, '01', _aNF [_nNF, 9])
				U_GravaSX1 (cPerg2, '02', _aNF [_nNF, 10])
				U_GravaSX1 (cPerg2, '03', _aNF [_nNF, 7])
				U_GravaSX1 (cPerg2, '04', _aNF [_nNF, 8])
				u_log ('gravei sx1')
				pergunte (cPerg2, .F.)
				_lContinua = pergunte (cPerg2, .T.)
			endif

			// Abre uma transacao para tentar fazer todas as alteracoes, ou nenhuma.
			u_log ('begin tran')
			begin transaction

			// Altera dados de comissao na nota e demais tabelas associadas.
			if _lContinua
				sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
				if sf2 -> (dbseek (xfilial ("SF2") + _aNF [_nNF, 1] + _aNF [_nNF, 2], .F.))
					_sVend1Ant = sf2 -> f2_vend1
					_sVend2Ant = sf2 -> f2_vend2
					u_log ('alterando sf2', sf2 -> f2_doc)
					reclock ("SF2", .F.)
					sf2 -> f2_vend1 = mv_par01
					sf2 -> f2_vend2 = mv_par02
					msunlock ()
				endif
			endif

			if _lContinua
				_aPed = {}
				sd2 -> (dbsetorder (3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
				sd2 -> (dbseek (xfilial ("SD2") + _aNF [_nNF, 1] + _aNF [_nNF, 2], .F.))
				do while ! sd2 -> (eof ()) ;
					.and. sd2 -> d2_filial == xfilial ("SD2") ;
					.and. sd2 -> d2_doc    == _aNF [_nNF, 1] ;
					.and. sd2 -> d2_serie  == _aNF [_nNF, 2]
	
					// Este programa NAO TRATA diferentes percentuais de comissao na mesma nota.
					_nCom1Ant = sd2 -> d2_comis1
					_nCom2Ant = sd2 -> d2_comis2
					u_log ('alterando sd2', sd2 -> d2_doc)
					reclock ("SD2", .F.)
					sd2 -> d2_comis1 = mv_par03
					sd2 -> d2_comis2 = mv_par04
					msunlock ()
					
					// Guarda lista dos pedidos de venda.
					if ascan (_aPed, sd2 -> d2_pedido) == 0
						aadd (_aPed, sd2 -> d2_pedido)
					endif

					// Cria evento em array para gravacao apenas no final do processo.
					_oEvento := ClsEvent():New ()
					_oEvento:Alias     = 'SF2'
					_oEvento:Texto     = "Alteracao manual repres/comissao" + iif (len (_aPagas) > 0, " (JA´ PAGA)", "") + chr (13) + chr (10) + ;
					                     "Vend1 de '" + _sVend1Ant + "' para '" + mv_par01 + "'" + chr (13) + chr (10) + ;
					                     "Vend2 de '" + _sVend2Ant + "' para '" + mv_par02 + "'" + chr (13) + chr (10) + ;
					                     "Comis1 de " + cvaltochar (_nCom1Ant) + " para " + cvaltochar (mv_par03) + chr (13) + chr (10) + ;
					                     "Comis2 de " + cvaltochar (_nCom2Ant) + " para " + cvaltochar (mv_par04)
					_oEvento:NFSaida   = sf2 -> f2_doc
					_oEvento:SerieSaid = sf2 -> f2_serie
					_oEvento:CodEven   = "SF2013"
					_oEvento:Produto   = sd2 -> d2_cod
					_oEvento:PedVenda  = sd2 -> d2_pedido
					_oEvento:Cliente   = sf2 -> f2_cliente
					_oEvento:LojaCli   = sf2 -> f2_loja
					_oEvento:MailTo    = "andressa.brugnera@novaalianca.coop.br"
					_oEvento:MailToZZU = {"006", '015'}
					aadd (_aEventos, _oEvento)					

					sd2 -> (dbskip ())
				enddo
			endif

			if _lContinua
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE1")
				_oSQL:_sQuery += " SET E1_VEND1  = '" + mv_par01 + "',"
				_oSQL:_sQuery +=     " E1_VEND2  = '" + mv_par02 + "',"
				_oSQL:_sQuery +=     " E1_COMIS1 = " + cvaltochar (mv_par03) + ","
				_oSQL:_sQuery +=     " E1_COMIS2 = " + cvaltochar (mv_par04)
				_oSQL:_sQuery += _sWhereSE1
				if ! _oSQL:Exec ()
					_lContinua = .F.
				endif
			endif

			if _lContinua
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE3")
				_oSQL:_sQuery += " SET E3_VEND  = '" + mv_par01 + "',"
				_oSQL:_sQuery +=     " E3_PORC  = " + cvaltochar (mv_par03) + ","
				_oSQL:_sQuery +=     " E3_COMIS = E3_BASE * " + cvaltochar (mv_par04) + " / 100"
				_oSQL:_sQuery += _sWhereSE3
				_oSQL:_sQuery +=    " AND E3_DATA  = ''"
				_oSQL:_sQuery +=    " AND E3_VEND  = '" + _sVend1Ant + "'"
				if ! _oSQL:Exec ()
					_lContinua = .F.
				endif
			endif

			if _lContinua
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE3")
				_oSQL:_sQuery += " SET E3_VEND  = '" + mv_par02 + "',"
				_oSQL:_sQuery +=     " E3_PORC  = " + cvaltochar (mv_par04) + ","
				_oSQL:_sQuery +=     " E3_COMIS = E3_BASE * " + cvaltochar (mv_par04) + " / 100"
				_oSQL:_sQuery += _sWhereSE3
				_oSQL:_sQuery +=    " AND E3_DATA  = ''"
				_oSQL:_sQuery +=    " AND E3_VEND  = '" + _sVend2Ant + "'"
				if ! _oSQL:Exec ()
					_lContinua = .F.
				endif
			endif

			if _lContinua
				for _nPed = 1 to len (_aPed)
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " UPDATE " + RetSQLName ("SC5")
					_oSQL:_sQuery += " SET C5_VEND1  = '" + mv_par01 + "',"
					_oSQL:_sQuery +=     " C5_VEND2  = '" + mv_par02 + "',"
					_oSQL:_sQuery +=     " C5_COMIS1 = " + cvaltochar (mv_par03) + ","
					_oSQL:_sQuery +=     " C5_COMIS2 = " + cvaltochar (mv_par04)
					_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND C5_FILIAL = '" + xfilial ("SC5") + "'"
					_oSQL:_sQuery +=   " AND C5_NUM    = '" + _aPed [_nPed] + "'"
					if ! _oSQL:Exec ()
						_lContinua = .F.
						exit
					endif
				next
			endif

			if _lContinua
				for _nPed = 1 to len (_aPed)
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " UPDATE " + RetSQLName ("SC6")
					_oSQL:_sQuery += " SET C6_COMIS1 = " + cvaltochar (mv_par03) + ","
					_oSQL:_sQuery +=     " C6_COMIS2 = " + cvaltochar (mv_par04)
					_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND C6_FILIAL = '" + xfilial ("SC6") + "'"
					_oSQL:_sQuery +=   " AND C6_NUM    = '" + _aPed [_nPed] + "'"
					if ! _oSQL:Exec ()
						_lContinua = .F.
						exit
					endif
				next
			endif

			// Grava eventos
			if _lContinua
				for _nEvento = 1 to len (_aEventos)
					u_log ('Gravando evento', _nEvento)
					_aEventos [_nEvento]:Grava ()
				next
			endif
/*
			// Manda e-mail de aviso.
			if _lContinua
				_sMsg := ""
				if len (_aPagas) > 0
					_sMsg += "Alteracao manual de repres./comissao de NF com comissao ja´ paga:" + chr (13) + chr (10)
					_sMsg += "Verifique necessidade de ajuste no pagto. da comissao." + chr (13) + chr (10)
				else
					_sMsg += "Alteracao manual de repres./comissao de NF:" + chr (13) + chr (10)
				endif
				_sMsg += "NF/serie: '" + sf2 -> f2_doc + "/" + sf2 -> f2_serie + "'" + chr (13) + chr (10)
				_sMsg += "Cliente/loja: '" + sf2 -> f2_cliente + "/" + sf2 -> f2_loja + "' - " + alltrim (fbuscacpo ("SA1", 1, xfilial ("SA1") + sf2 -> f2_cliente + sf2 -> f2_loja, "A1_NOME")) + chr (13) + chr (10)
				if len (_aPagas) > 0
					_sMsg += "Ja existem os seguintes pagamentos de comissao efetuados:" + chr (13) + chr (10)
					for _nPaga = 1 to len (_aPagas)
						_sMsg += '  Pago em ' + dtoc (_aPagas [_nPaga, 3])
						_sMsg += '  Valor: ' + transform (_aPagas [_nPaga, 2], "@E 999,999.99")
						_sMsg += '  Rep. ' + _aPagas [_nPaga, 1] + ' - ' + alltrim (fbuscacpo ("SA3", 1, xfilial ("SA3") + _aPagas [_nPaga, 1], "A3_NOME")) + chr (13) + chr (10) 
					next
				endif
				_sMsg += "Novo vendedor 1: '" + mv_par01 + "'" + chr (13) + chr (10)  
				_sMsg += "Novo vendedor 2: '" + mv_par02 + "'" + chr (13) + chr (10)
				_sMsg += "Novo % comis1: " + cvaltochar (mv_par03) + chr (13) + chr (10)
				_sMsg += "Novo % comis1: " + cvaltochar (mv_par04) + chr (13) + chr (10)
				_sDestMail := ""
				_sDestMail += "robert.koch@novaalianca.coop.br;"
				if len (_aPagas) > 0
					// Se jah tem comissao paga, manda e-mail para mais pessoas.
					_sDestMail += "robert.koch@novaalianca.coop.br;"
				endif
				U_SendMail (_sDestMail, ;
				            "Alteracao de vend/comissao NF " + sf2 -> f2_doc + iif (len (_aPagas) > 0, " (COMISSAO JA PAGA)", ""), ;
				            _sMsg)
			endif
*/
			end transaction
		next
	endif
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	// Grupo de perguntas 1 - identificacao do pedido / notas fiscais
	//                     PERGUNT                           TIPO TAM                      DEC VALID F3       Opcoes Help
	aadd (_aRegsPerg, {01, "Pedido                        ", "C", tamsx3 ("D2_PEDIDO")[1], 0,  "",   "     ", {},    ""})
	aadd (_aRegsPerg, {02, "NF saida - Numero             ", "C", tamsx3 ("D2_DOC")[1],    0,  "",   "     ", {},    ""})
	aadd (_aRegsPerg, {03, "NF saida - Serie              ", "C", 3,                       0,  "",   "     ", {},    ""})
	U_ValPerg (cPerg1, _aRegsPerg)

	// Grupo de perguntas 2 - dados de comissao.
	//                     PERGUNT                           TIPO TAM                      DEC VALID F3       Opcoes Help
	_aRegsPerg = {}
	aadd (_aRegsPerg, {01, "Novo vendedor 1               ", "C", tamsx3 ("F2_VEND1")[1],  0,  "",   "SA3  ", {},    ""})
	aadd (_aRegsPerg, {02, "Novo vendedor 2               ", "C", tamsx3 ("F2_VEND1")[1],  0,  "",   "SA3  ", {},    ""})
	aadd (_aRegsPerg, {03, "Nova comissao 1 (%)           ", "N", 6,                       2,  "",   "     ", {},    ""})
	aadd (_aRegsPerg, {04, "Nova comissao 2 (%)           ", "N", 6,                       2,  "",   "     ", {},    ""})
	U_ValPerg (cPerg2, _aRegsPerg)
return
