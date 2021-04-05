// Programa...: VerEstq
// Autor......: Robert Koch
// Data.......: 25/10/2010
// Descricao..: Chamado por outros programas para verificacoes diversas de estoques.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Chamado por outros programas para verificacoes diversas de estoques.
// #PalavasChave      #liberacao #estoque
// #TabelasPrincipais #SBF #SB8 #SC9
// #Modulos           #FAT
//
// Historico de alteracoes:
// 16/12/2011 - Robert  - Passa a verificar estoque por localizacao.
// 10/07/2013 - Leandro - Alteração para que a filial de depósito não seja fixo '04', 
//				          pegando da tebala ZS da SX5
// 11/12/2013 - Robert  - Quando embarque na propria filial, somava as reservas ao saldo disponivel.
// 01/02/2014 - Robert  - Passa a mostrar (mas nao usar no calculo) o B2_QTNP.
// 03/04/2014 - Marcelo - Verifica produtos não enderecados na filial 13.
// 11/06/2014 - Robert  - Enderecos com bloqueio passam a ser considerados como indisponiveis para estoque.
// 13/06/2014 - Robert  - Validacao de enderecos bloqueados foi removida
// 10/07/2014 - Robert  - Passa a considerar campo BE_VADPPED.
// 15/07/2014 - Robert  - Aplica validacao do campo BE_VADPPED apenas para produtos que controlem 
//                        enderecamento.
// 28/11/2014 - Robert  - Quando informado endereco, nao validava corretamente o estoque por localizacao.
// 09/02/2015 - Robert  - Volta a validar o estoque do produto 9999.
// 26/08/2015 - Robert  - Desabilitadas verificacoes de 'usa localizacao', pois nao usamos 
//                        mais rastreabilidade.
// 09/12/2016 - Robert  - Quando F4_PODER3=='D' considera o B2_QTNP como parte do estoque disponivel.
//                      - Desabilitados tratamentos para empresa 02.
// 15/12/2016 - Robert  - Removidos tratamentos para 'filial de embarque'
//                      - Nao considera mais o B2_QTNP como parte do estoque disponivel 
//                        quando F4_PODER3=='D'
// 11/01/2016 - Robert  - Ajustes nos testes de estoque por localizacao.
// 16/02/2017 - Robert  - Desconsidera B2_QEMP.
// 05/04/2021 - Claudia - Declaração da variável _nMyReserv e inclusão de tags de pesquisa.
//
// -----------------------------------------------------------------------------------------------------------
user function VerEstq (_sOnde, _sProduto, _sFilEmb, _sLocal, _nQtdVen, _sTES, _sLocaliz, _sLote, _sPedido)
	local _sQuery    := ""
	local _aAreaAnt  := U_ML_SRArea ()
	local _sRet      := ""
	local _lContinua := .T.
	local _nSldDisp  := 0
	local _oSQL      := NIL
	local _nMyReserv := 0
	//local _nSaldo    := 0
	//local _nReserva  := 0
	//local _nEnder    := 0
	//local _aSldEnder := {}
	
	//u_logIni ()
	//U_LOG (_sOnde, _sProduto, _sFilEmb, _sLocal, _nQtdVen, _sTES, _sLocaliz, _sLote, _sPedido)

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			_sRet := "Produto '" + alltrim (_sProduto) + "' nao encontrado no cadastro!"
			u_help (_sRet)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		sf4 -> (dbsetorder (1))  // F4_FILIAL+F4_CODIGO
		if ! sf4 -> (dbseek (xfilial ("SF4") + _sTES, .F.))
			_sRet := "TES '" + _sTES + "' nao cadastrado!"
			u_help (_sRet)
			_lContinua = .F.
		endif
	endif
	
	if _lContinua
		sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
		if ! sb2 -> (dbseek (xfilial ("SB2") + _sProduto + _sLocal, .F.))
			_sRet := "Produto '" + alltrim (_sProduto) + "' nao encontrado no almox. '" + _sLocal + "'!"
			u_help (_sRet)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. sf4 -> f4_estoque == "S"
		
		// Verifica quanto da reserva refere-se a este mesmo pedido de venda.
		if sb2 -> b2_reserva > 0 .and. ! empty (_sPedido)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT SUM (C9_QTDLIB)"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC9") + " SC9 "
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND C9_FILIAL  = '" + xfilial ("SC9") + "'"
			_oSQL:_sQuery +=   " AND C9_PRODUTO = '" + _sProduto + "'"
			_oSQL:_sQuery +=   " AND C9_PEDIDO  = '" + _sPedido + "'"
			_oSQL:_sQuery +=   " AND C9_NFISCAL = ''"
			_oSQL:_sQuery +=   " AND C9_QTDLIB  > 0"
			_oSQL:_sQuery +=   " AND C9_BLCRED  = ''"
			//_oSQL:Log ()
			_nMyReserv = _oSQL:RetQry (1, .F.)
			//u_log ('MyReserv:', _nMyReserv)
		endif

		_nSldDisp = sb2 -> b2_qatu - (_nQtdVen + (sb2 -> b2_reserva - _nMyReserv) + sb2 -> b2_qaclass)

		// Se estiver verificando dentro da tela de preparacao de notas de saida, para embarque nesta
		// mesma filial (nao deposito), desconsidera o pedido atual, pois jah encontra-se somado nas reservas.
		if _sOnde == '3' .and. sf4 -> f4_vaFDep != "S"
			_nSldDisp += _nQtdVen
		endif
		
		// Verifica inicialmente pelo total de estoque (SB2)
		If _nSldDisp < 0
			_sRet = "Saldo insuficiente produto '" + alltrim (_sProduto) + "'." + chr (13) + chr (10) + ;
			        "Saldo atual: " + cvaltochar (sb2 -> b2_qatu) + chr (13) + chr (10) + ;
			        "Reservado: " + cvaltochar (sb2 -> b2_reserva) + chr (13) + chr (10) + ;
			        "De terceiros: " + cvaltochar (sb2 -> b2_qtnp) + chr (13) + chr (10) + ;
			        "A enderecar: " + cvaltochar (sb2 -> b2_qaclass) + chr (13) + chr (10) + ;
			        "Empenhado em OP: " + cvaltochar (sb2 -> b2_qemp) //"Bloqueado: " + cvaltochar (_aRetQry [1, 5])
		endif

		// Se tem estoque pelo total, mas foi informado endereco, verifica saldo por localizacao
		if empty (_sRet) .and. ! empty (_sLocaliz)
			_sQuery := ""
			_sQuery += " select sum (BF_QUANT) AS BF_QUANT, SUM (BF_EMPENHO) AS BF_EMPENHO "
			_sQuery +=   " from " + RetSQLName ("SBF") + " SBF, "
			_sQuery +=              RetSQLName ("SBE") + " SBE"
			_sQuery +=  " where SBF.BF_FILIAL  = '" + xfilial ("SBF") + "'"
			_sQuery +=    " and SBF.D_E_L_E_T_ = ''"
			_sQuery +=    " and SBF.BF_PRODUTO = '" + _sProduto + "'"
			_sQuery +=    " and SBF.BF_LOCAL   = '" + _sLocal   + "'"
			_sQuery +=    " and SBF.BF_LOCALIZ = '" + _sLocaliz + "'"
			_sQuery +=    " AND SBE.D_E_L_E_T_ = ''"  
			_sQuery +=    " AND SBE.BE_FILIAL  = SBF.BF_FILIAL"  
			_sQuery +=    " AND SBE.BE_LOCAL   = SBF.BF_LOCAL"  
			_sQuery +=    " AND SBE.BE_LOCALIZ = SBF.BF_LOCALIZ"
			//u_log (_sQuery)
			_aRetQry := aclone (U_Qry2Array (_sQuery))
			if len (_aRetQry) > 0
				if _nQtdVen > (_aRetQry [1, 1] - (_aRetQry [1, 2] - _nQtdVen))
					_sRet = "Saldo insuficiente produto '" + alltrim (_sProduto) + "' no endereco '" + _sLocaliz + "'. Saldo Atual: " + cvaltochar (_aRetQry [1, 1]) + "  Reservado: " + cvaltochar (_aRetQry [1, 2])
				endif
			else
				_sRet = "Produto '" + alltrim (_sProduto) + "' nao existe no endereco '" + _sLocaliz + "'."
			endif
		endif

		if empty (_sRet) .and. ! empty (_sLote)
			_sQuery := ""
			_sQuery += " select B8_SALDO, B8_EMPENHO"
			_sQuery +=   " from " + RetSQLName ("SB8") + " SB8 "
			_sQuery +=  " where SB8.B8_FILIAL  = '" + xfilial ("SB8") + "'"
			_sQuery +=    " and SB8.D_E_L_E_T_ = ''"
			_sQuery +=    " and SB8.B8_PRODUTO = '" + _sProduto + "'"
			_sQuery +=    " and SB8.B8_LOCAL   = '" + _sLocal   + "'"
			_sQuery +=    " and SB8.B8_LOTECTL = '" + _sLote    + "'"
			//u_log (_sQuery)
			_aRetQry := aclone (U_Qry2Array (_sQuery))
			if len (_aRetQry) == 0
				_sRet = "Lote '" + _sLote + "' nao encontrado para o produto/almox solicitado."
			else
				if _nQtdVen > (_aRetQry [1, 1] - (_aRetQry [1, 2] - _nQtdVen))
					_sRet = "Saldo insuficiente no lote '" + _sLote + "' do produto '" + alltrim (_sProduto)
				endif
			endif
		endif
	endif      

	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
return _sRet
