// Autor:     Robert Koch
// Data:      08/05/2009
// Descricao: Gera notas fiscais de compra/complemento de uva da safra cfe. previsao do arquivo ZZ9.
//            Criado com base no ML_GNFS de Jeferson Rech.
//
// Historico de alteracoes:
// 06/07/2009 - Robert - Arredonda valor total p/ 2 casas p/ compatibilizar com SFT, SF3, SE2, contabilizacao, SPED, etc...
// 15/07/2009 - Robert - Tinha um dbskip indevido e perdia o primeiro registro de uma pre-nota quando nao houvesse sido
//                       gerada nenhuma nota para o fornecedor anterior.
// 30/07/2010 - Robert - Ajustes finos para safra 2010.
// 28/07/2011 - Robert - Ajustes para safra 2011.
//                     - Nao gravava campo ZZ9_NFCOMP apos a geracao das notas.
// 07/10/2012 - Robert - Ajustes particularidades safra 2012.
// 23/04/2015 - Robert - Melhorias safra 2015.
// 09/06/2015 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 04/01/2016 - Robert - Tratamento para parametro VA_SERSAFR.
// 19/02/2016 - Robert - Criado tratamento para o atributo 'PARCELA' da classe ClsCtaCorr.
// 16/12/2016 - Robert - Revisada rotina de complemento de preco.
// 21/03/2017 - Robert - Ignora pre-notas zeradas sem mostrar mensagem (gera apenas log)
//                     - Melhoria regua processamento; eliminados alguns logs.
// 22/04/2017 - Robert - Gravava a serie no D1_NFORI para notas de complemento.
//                     - Nao concatena mais as duas classificacoes (Livram/Serra) na descricao. Agora verifica a filial.
// 27/03/2018 - Robert - Tratamento gravacao campo F1_VASAFRA, leitura de mensagens do ZZ9_MSGNF
// 25/05/2018 - Robert - Nao acumula mais de uma NF origem quando nota de complemento (SEFAZ nao autoriza mais).
// 23/03/2019 - Robert - Ajustes para compra 2019. Filtro pelo ZZ9_GRUPO, melhora mensagens.
// 18/04/2019 - Robert - Ajustes compl.preco uva propria Livramento 2019
// 25/06/2019 - Robert - Array de itens passa a usar nomes (XTranslate) para identificar posicoes.
//                     - Tratamento para o campo ZZ9_TES.
//

#include "tbiconn.ch"

#XTranslate .ItensProduto    => 1
#XTranslate .ItensDescricao  => 2
#XTranslate .ItensGrau       => 3
#XTranslate .ItensClasEspald => 4
#XTranslate .ItensClasLatada => 5
#XTranslate .ItensQuantidade => 6
#XTranslate .ItensValorTotal => 7
#XTranslate .ItensNFOri      => 8
#XTranslate .ItensSerieOri   => 9
#XTranslate .ItensItemOri    => 10
#XTranslate .ItensConducao   => 11
#XTranslate .ItensTES        => 12
#XTranslate .ItensQtColunas  => 12

// --------------------------------------------------------------------------
User Function VA_GNF2 (_lAutomat)
	Local cCadastro    := "Geracao NF compra / complemento de Uva"
	Local aSays        := {}
	Local aButtons     := {}
	Local nOpca        := 0
	Local lPerg        := .F.
	local _nLock       := 0
	local _lContinua   := .T.
	local _lAuto       := iif (_lAutomat == NIL, .F., _lAutomat)
	Private cPerg      := "VAGNF2"
//	private _sArqLog   := "Geracao_NF_compra_safra_Emp_" + cEmpAnt + '_Fil' + cFilAnt + '_' + dtos (date ()) + '_' + strtran (time (), ':', '') + ".log"
	private _sArqLog   := "Geracao_NF_compra_safra_Emp_" + cEmpAnt + '_Fil' + cFilAnt + '_' + dtos (date ()) + ".log"
	private _sOrigSZI  := "VA_GNF2"
	private _sErroAuto := ""  // Deixar private para ser vista pela funcao U_Help ()

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
	endif

	// Controle de semaforo.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
			_lContinua = .F.
		endif
	endif
	if _lContinua
		u_logId ()
		_ValidPerg()
		Pergunte(cPerg,.F.)      // Pergunta no SX1
		
		AADD(aSays,"  Este programa tem como objetivo gerar as NFs de Compra de Uva,    ")
		AADD(aSays,"  com base no arquivo de pre-notas de compra de safra.              ")
		AADD(aSays,"")
		AADD(aSays,"")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		if _lAuto
			Processa( { |lEnd| _Gera03() } )
		else
			FormBatch( cCadastro, aSays, aButtons )
			If nOpca == 1
				Processa( { |lEnd| _Gera03() } )
			Endif
		endif
	
		// Libera semaforo
		U_Semaforo (_nLock)
	endif
return
	
	
	
// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	RestArea(_aArea)
Return(_lRet)



// --------------------------------------------------------------------------
Static Function _Gera03 ()
	local _lContinua := .T.
	local _sSerie    := ""
	local _sSafra    := ""
	local _sParcelas := ""
	local _sFornIni  := ""
	local _sFornFim  := ""
	local _sLojaIni  := ""
	local _sLojaFim  := ""
	local _sDCO      := ""
	local _sVarUva   := ""
	local _sPreNF    := ""
	local _sMsgContr := ""
	local _aItens    := {}
	local _sNfEntr   := {}
	local _sNfOri    := ""
	local _sNfProd   := {}
	local _lPreNFOk  := .F.
	local _lFornOk   := .F.
	local _nPorDCO   := 0
	local _aPreNF    := {}
	local _aNfCprOri := {}
	local _sCondPag  := ""
	local _sParcela  := ""
	local _aFornec   := {}
	local _nFornec   := 0
	local _sCadVitic := ""
	local _sVitOrig  := ""
//	local _sObsZZ9   := ""
	local _sMsgNfZZ9 := ""
	local _sZZ9NFOri := ""
//	local _sTESCSAF  := ''
	private _sGrpZZ9   := ''
	private _sNFIni  := ""
	private _sNFFim  := ""

	u_logSX1 ()
	
//	if ! GetMv("ML_TESCSAF", .T.)
//		_lContinua = .F.
//	else
//		_sTESCSAF = GetMv("ML_TESCSAF")
//	endif

	// Pega-ratao (no caso, eu mesmo). Jah gerei notas usando a cond.pagto. errada mais de uma vez... provavelmente precise ajustar em cada safra.
	_lContinua = _ValCond ()

	// A partir de 2016 teremos uma serie especifica para NF de safra.
	// Fica fixo no programa para nem precisar abrir tela para o usuario.
	if _lContinua
		_sSerie = GetMv ("VA_SERSAFR", .F., '')
		if empty (_sSerie)
			u_help ("Serie a ser usada nas NF de safra nao definida. Verifique se o parametro VA_SERSAFR existe e se contem uma serie de NF valida para esta filial.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_lOK := Sx5NumNota (@_sSerie)   // Apresenta Tela para Confirmar o Numero da Primeira NF a Ser Gerada
		if ! _lOK .or. empty (_sSerie)  // Usuario cancelou ou nao confirmou em tempo habil
			_lContinua = .F.
		endif
	endif

	if _lContinua
	
		// Altera parametro "Mostra lctos contabeis" para "Nao" 
		// e 'Contabiliza online' para 'sim' na tela de NF de entrada
		U_GravaSX1 ("MTA103", "01", "2")
		U_GravaSX1 ("MTA103", "06", "1")

		// Guarda parametros em variaveis especificas por que as chamadas de rotinas automaticas vai sobregrava-los.
		_sFornIni = mv_par01
		_sLojaIni = mv_par02
		_sFornFim = mv_par03
		_sLojaFim = mv_par04
		_sSafra   = mv_par05
		_sParcelas = mv_par06
		_sGrpZZ9  = mv_par07
		_nPorDCO  = mv_par08
		_sVarUva  = mv_par09
		_sTipoNF  = iif (mv_par10 == 1, "N", "C")
		_sCondPag = mv_par11
		_nTamDesc = tamsx3 ("D1_DESCRI")[1]
		_nTamItem = tamsx3 ("D1_ITEM")[1]
	endif

	if _lContinua .and. _sTipoNF == "N"  // Notas normais

		// Soh para me obrigar a revisar anualmente...
		if _sSafra > '2019'
			u_help ("revisar rotina de geracao de NF compra para esta safra")
			return
		endif

		// Monta array com os fornecedores ordenados por nome, para facilitar a posterior separacao das notas,
		// e simula varias execucoes da rotina com associado inicial = associado final.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT ZZ9_FORNEC, ZZ9_LOJA, A2_NOME, A2_VACORIG"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9, "
		_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SA2.A2_COD     = ZZ9_FORNEC"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = ZZ9_LOJA"
		_oSQL:_sQuery +=    " AND ZZ9.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZZ9_FILIAL     = '" + xfilial ("ZZ9") + "'"
		_oSQL:_sQuery +=    " AND ZZ9_SAFRA      = '" + _sSafra + "'"
		if ! empty (_sParcelas)
			_oSQL:_sQuery +=    " AND ZZ9_PARCEL     IN " + FormatIn (_sParcelas, '/')
		endif
		_oSQL:_sQuery +=    " AND ZZ9_GRUPO      = '" + _sGrpZZ9 + "'"
		_oSQL:_sQuery +=    " AND ZZ9_FORNEC + ZZ9_LOJA BETWEEN '" + _sFornIni + _sLojaIni + "' AND '" + _sFornFim + _sLojaFim + "'"
		_oSQL:_sQuery +=    " AND ZZ9_NFCOMP     = ''"
		_oSQL:_sQuery +=  " ORDER BY A2_VACORIG, A2_NOME, ZZ9_FORNEC, ZZ9_LOJA"
		_oSQL:Log ()
		_aFornec = aclone (_oSQL:Qry2Array (.F., .F.))
		u_log (_aFornec)
		procregua (len (_aFornec))
		for _nFornec = 1 to len (_aFornec)
			_sFornIni := _sFornFim := _aFornec [_nFornec, 1]
			_sLojaIni := _sLojaFim := _aFornec [_nFornec, 2]

			u_log ('Iniciando fornecedor ' + zz9 -> zz9_fornec + '/' + zz9 -> zz9_loja)
			incproc ('Associado ' + _sFornIni + '/' + _sLojaIni + '(' + cvaltochar (_nFornec) + ' de ' + cvaltochar (len (_aFornec)) + ')')

			// Busca pre-notas para geracao das nf de compra da uva.
			zz9 -> (dbsetorder (3))  // ZZ9_FILIAL+ZZ9_FORNEC+ZZ9_LOJA+ZZ9_SAFRA+ZZ9_PARCEL+ZZ9_PRE_NF
			zz9 -> (dbseek (xfilial ("ZZ9") + _sFornIni, .T.))
			do while _lContinua .and. !zz9 -> (eof ()) .and.  zz9 -> zz9_filial == xfilial ("ZZ9")

				// Poderia verificar alguns dados a mais no do...while, mas prefiro manter assim para poder usar
				// diferentes indices no while caso necessario (parcelas, DCO, etc...).
				if zz9 -> zz9_fornec + zz9 -> zz9_loja < _sFornIni + _sLojaIni .or. zz9 -> zz9_fornec + zz9 -> zz9_loja > _sFornFim + _sLojaFim
					zz9 -> (dbskip ())
					loop
				endif
				if zz9 -> zz9_safra != _sSafra
					zz9 -> (dbskip ())
					loop
				endif
				if ! empty (_sParcelas) .and. ! zz9 -> zz9_parcel $ _sParcelas
					zz9 -> (dbskip ())
					loop
				endif
				if zz9 -> zz9_grupo != _sGrpZZ9
					zz9 -> (dbskip ())
					loop
				endif
				if ! empty (zz9 -> zz9_nfcomp)  // Nota de compra jah gerada.
					zz9 -> (dbskip ())
					loop
				endif
	
				// Verifica fornecedor.
				sa2 -> (dbsetorder (1))
				if ! sa2 -> (dbseek (xfilial ("SA2") + zz9 -> zz9_fornec + zz9 -> zz9_loja, .F.))
					u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' nao cadastrado.")
					_lContinua = .F.
					zz9 -> (dbskip ())
					loop
				endif
	
//				_oAssoc := ClsAssoc():New (zz9 -> zz9_fornec, zz9 -> zz9_loja)
//				if valtype (_oAssoc) != "O" .or. (!_oAssoc:EhSocio (dDataBase) .and. empty (_oAssoc:DtSaida (dDataBase)))  // Ex-associado pode ainda ter a safra para receber.
//					if empty (zz9_tes)
//						u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' nao e' associado e nem ex-associado. TES deve ser informado nesse caso.")
//						_lContinua = .F.
//						zz9 -> (dbskip ())
//						loop
//					else
//						if ! U_MsgNoYes ("Confirma uso do TES '" + zz9 -> zz9_tes + "' para o fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "'?")
//							_lContinua = .F.
//							zz9 -> (dbskip ())
//							loop
//						endif
//					endif
//				endif
				if empty (zz9 -> zz9_tes)
					u_help ("TES para geracao da nota deve ser informado.")
					_lContinua = .F.
					zz9 -> (dbskip ())
					loop
				endif
				if empty (sa2 -> a2_conta)
					u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' sem conta contabil.")
					_lContinua = .F.
					zz9 -> (dbskip ())
					loop
				endif
	
				// Controla quebra por pre-nf, pois cada registro do ZZ9 equivale a um registro
				// de NF de entrada de uva do SD1, mas agora devo somar as quantidades das uvas
				// de mesmo grau e classificacao.
				_sFornece  = zz9 -> zz9_fornec
				_sLoja     = zz9 -> zz9_loja
				_sPreNF    = zz9 -> zz9_pre_nf
				_sNfProd   = zz9 -> zz9_nfProd
				_sNfEntr   = ""
				_sCadVitic = ""
				_sDCO      = zz9 -> zz9_dco
				_sParcela  = zz9 -> zz9_parcel
				_aItens    = {}
				_lPreNFOk  = .T.
				_sMsgNfZZ9 = ''
				do while _lContinua .and. !zz9 -> (eof ()) ;
					.and.  zz9 -> zz9_filial == xfilial ("ZZ9") ;
					.and.  zz9 -> zz9_fornec == _sFornece ;  //_oAssoc:Codigo ;
					.and.  zz9 -> zz9_loja   == _sLoja ;  //_oAssoc:Loja ;
					.and.  zz9 -> zz9_safra  == _sSafra ;
					.and.  zz9 -> zz9_parcel == _sParcela

//					u_log ('dentro do loop:')
//					u_logtrb ('zz9')
					if ! empty (zz9 -> zz9_nfcomp)  // Nota de compra jah gerada.
						u_log ('Jah tem NF de compra')
						// Era usado no sentido "todos os itens desta pre-nota tem que estar OK, senao eu ignoro toda a pre-nota". --> _lPreNFOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
					if zz9 -> zz9_tiponf != _sTipoNF
						zz9 -> (dbskip ())
						loop
					endif
					if zz9 -> zz9_grupo != _sGrpZZ9
						zz9 -> (dbskip ())
						loop
					endif
					if empty (zz9 -> zz9_grau)
						u_help ("Grau nao informado na pre-nf '" + zz9 -> zz9_pre_nf + "'.")
						_lPreNFOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
					if zz9 -> zz9_vunit <= 0
						u_log ("Pre-nf '" + zz9 -> zz9_pre_nf + "' sem valor unitario. A mesma vai ser ignorada.")
						_lPreNFOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
		
					// Verifica produto
					sb1 -> (dbsetorder (1))
					if ! sb1 -> (dbseek (xfilial ("SB1") + zz9 -> zz9_produt, .F.))
						u_help ("Produto '" + zz9 -> zz9_produt + "' nao cadastrado.")
						_lPreNFOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
					if _sVarUva == 1 .and. sb1 -> b1_varuva != "C"
						zz9 -> (dbskip ())
						loop
					endif
					if _sVarUva == 2 .and. sb1 -> b1_varuva != "F"
						zz9 -> (dbskip ())
						loop
					endif
					if sb1 -> b1_varuva == "F" .and. sb1 -> b1_vafcuva == 'F' .and. empty (zz9 -> zz9_classe) .and. empty (zz9 -> zz9_clabd)
						u_help ("Classificacao da uva nao informada na pre-nf '" + zz9 -> zz9_pre_nf + "'.")
						_lPreNFOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
					if sb1 -> b1_varuva == 'C' .and. (sb1 -> b1_varuva == "F" .and. sb1 -> b1_vafcuva == 'C') .and. (! empty (zz9 -> zz9_classe) .or. ! empty (zz9 -> zz9_clabd))
						u_help ("Classificacao da uva nao deve ser informada na pre-nf '" + zz9 -> zz9_pre_nf + "'.")
						_lPreNFOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
	
					// Verificacoes ref. DCO
					if (_nPorDCO == 1 .and. empty (zz9 -> zz9_dco)) .or. (_nPorDCO == 2 .and. !empty (zz9 -> zz9_dco))
						zz9 -> (dbskip ())
						loop
					endif
					if ! empty (zz9 -> zz9_dco) .and. empty (zz9 -> zz9_nfprod) .and. zz9 -> zz9_tipoNF != "C"
						if zz9 -> zz9_safra != '2012'  // Em 2012 usamos o campo para outras coisas...
							u_help ("NF de produtor deve ser informada quando houver DCO (pre-nf '" + zz9 -> zz9_pre_nf + "' / fornecedor '" + zz9 -> zz9_fornec + "').")
							_lPreNFOk = .F.
							zz9 -> (dbskip ())
							loop
						endif
					endif
						
					// Existe a possibilidade de diferentes registros de uma mesma
					// variedade/grau/classificacao terem precos unitarios diferentes,
					// seja por mistura, multa, etc... entao preciso
					// acumular tudo em uma array para, depois, calcular o preco medio.
//					_nItem = ascan (_aItens, {|_aVal| _aVal [1]  == zz9 -> zz9_produt ;
//					                            .and. _aVal [3]  == zz9 -> zz9_grau ;
//					                            .and. _aVal [4]  == zz9 -> zz9_classe ;
//					                            .and. _aVal [5]  == zz9 -> zz9_clabd ;
//					                            .and. _aVal [11] == zz9 -> zz9_conduc})
//					if _nItem == 0
//						aadd (_aItens, {zz9 -> zz9_produt, sb1 -> b1_desc, zz9 -> zz9_grau, zz9 -> zz9_classe, zz9 -> zz9_clabd, 0, 0, NIL, NIL, NIL, zz9 -> zz9_conduc})
//						_nItem = len (_aItens)
//					endif
//					_aItens [_nItem, 6] += zz9 -> zz9_quant
//					_aItens [_nItem, 7] += zz9 -> zz9_quant * zz9 -> zz9_vunit
					_nItem = ascan (_aItens, {|_aVal| _aVal [.ItensProduto]    == zz9 -> zz9_produt ;
					                            .and. _aVal [.ItensGrau]       == zz9 -> zz9_grau ;
					                            .and. _aVal [.ItensClasEspald] == zz9 -> zz9_classe ;
					                            .and. _aVal [.ItensClasLatada] == zz9 -> zz9_clabd ;
					                            .and. _aVal [.ItensConducao]   == zz9 -> zz9_conduc})
					if _nItem == 0
						aadd (_aItens, array (.ItensQtColunas))
						_nItem = len (_aItens)
						_aItens [_nItem, .ItensProduto] = zz9 -> zz9_produt
						_aItens [_nItem, .ItensDescricao] = sb1 -> b1_desc
						_aItens [_nItem, .ItensGrau]      = zz9 -> zz9_grau
						_aItens [_nItem, .ItensClasEspald] = zz9 -> zz9_classe
						_aItens [_nItem, .ItensClasLatada] = zz9 -> zz9_clabd
						_aItens [_nItem, .ItensQuantidade] = 0
						_aItens [_nItem, .ItensValorTotal] = 0
						_aItens [_nItem, .ItensNFOri]      = ''
						_aItens [_nItem, .ItensSerieOri]   = ''
						_aItens [_nItem, .ItensItemOri]    = ''
						_aItens [_nItem, .ItensConducao]   = zz9 -> zz9_conduc
						_aItens [_nItem, .ItensTES]        = zz9 -> zz9_tes
					endif
					_aItens [_nItem, .ItensQuantidade] += zz9 -> zz9_quant
					_aItens [_nItem, .ItensValorTotal] += zz9 -> zz9_quant * zz9 -> zz9_vunit


					// Alimenta lista das notas de entrada
					if ! empty (zz9 -> zz9_nfentr) .and. ! alltrim (zz9 -> zz9_nfentr) $ _sNFEntr
						_sNFEntr += alltrim (zz9 -> zz9_nfentr) + ","
					endif
					
					// Alimenta lista de cadastros viticolas das notas de entrada.
					if ! empty (zz9 -> zz9_nfentr)
						_oSQL := ClsSQL ():New ()
						_oSQL:_sQuery := ""
						_oSQL:_sQuery += " SELECT DISTINCT CAD_VITIC"
						_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
						_oSQL:_sQuery +=  " WHERE FILIAL        = '" + zz9 -> zz9_filial + "'"
						_oSQL:_sQuery +=    " AND SAFRA         = '" + zz9 -> zz9_safra  + "'"
						_oSQL:_sQuery +=    " AND ASSOCIADO     = '" + zz9 -> zz9_fornec + "'"
						_oSQL:_sQuery +=    " AND LOJA_ASSOC    = '" + zz9 -> zz9_loja   + "'"
						_oSQL:_sQuery +=    " AND DOC           = '" + zz9 -> zz9_nfentr + "'"
						_oSQL:_sQuery +=    " AND PRODUTO       = '" + zz9 -> zz9_produt + "'"
						_oSQL:_sQuery +=    " AND GRAU          = '" + zz9 -> zz9_grau   + "'"
						_oSQL:_sQuery +=    " AND CLAS_FINAL    = '" + zz9 -> zz9_classe + "'"
						_oSQL:_sQuery +=    " AND CLAS_ABD      = '" + zz9 -> zz9_clabd  + "'"
						_oSQL:_sQuery +=    " AND SIST_CONDUCAO = '" + zz9 -> zz9_conduc + "'"
						//u_log (_oSQL:_sQuery)
						_sVitOrig = _oSQL:Qry2Str ()
						//u_log ('_sVitOrig:',_sVitOrig)
						if ! empty (_sVitOrig) .and. ! alltrim (_sVitOrig) $ _sCadVitic
							_sCadVitic += alltrim (_sVitOrig) + ","
						endif
					endif
					//u_log ('_sCadVitic:', _sCadVitic)
	
					// Alimenta lista de mensagens para a nota.
					if ! empty (zz9 -> zz9_msgNF) .and. ! alltrim (zz9 -> zz9_msgNF) $ _sMsgNfZZ9
						_sMsgNFZZ9 += ' ' + alltrim (zz9 -> zz9_msgNF)
					endif

					// Mantem lista de pre-notas atendidas
					if ascan (_aPreNF, zz9 -> zz9_pre_NF) == 0
						aadd (_aPreNF, zz9 -> zz9_pre_NF)
					endif
	
					zz9 -> (dbskip ())
				enddo

				//u_log ("Itens da pre-nf " + _sPreNF + ": ",_aitens)
				
				// A nota pode jah ter sido gerada em processamento anterior ou pode ter sido detectado algum erro na pre-nf.
				if len (_aItens) == 0 .or. ! _lPreNFOk
					loop
				endif
	
				// Prepara dados adicionais
				_sMsgContr = ""
				if ! empty (_sNfProd)
					_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Ref.NF produtor " + alltrim (_sNfProd) + " de " + dtoc (dDataBase)
				endif

				if ! empty (_sNfEntr)
					_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Ref.NNF entrada " + substr (_sNfEntr, 1, len (_sNfEntr) - 1)
				endif
				if ! empty (_sCadVitic)
					_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Cad.vitic:" + substr (_sCadVitic, 1, len (_sCadVitic) - 1)
				endif
				if ! empty (_sMsgNfZZ9)
					_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + _sMsgNfZZ9
				endif
	
				_lContinua = _GeraNota ("N", sa2 -> a2_cod, sa2 -> a2_loja, _aItens, _sMsgContr, _sSerie, sa2 -> a2_est, _sDCO, _aPreNF, _sSafra, _sCondPag, _sParcela, _sGrpZZ9)

			enddo
		next



	elseif _lContinua .and. _sTipoNF == "C"  // Complementos de preco.



		//u_help ('nao funcionou gravacao D1_VACONDU para nota tipo C em 13/11/2017')

		// Soh para me obrigar a revisar anualmente...
		if _sSafra > '2019'
			u_help ("revisar rotina de compl. preco para esta safra")
			return
		endif


		// Monta array com os fornecedores ordenados por nome, para facilitar a posterior separacao das notas.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT ZZ9_FORNEC, ZZ9_LOJA, A2_NOME, A2_VACORIG"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9, "
		_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SA2.A2_COD     = ZZ9_FORNEC"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = ZZ9_LOJA"
		_oSQL:_sQuery +=    " AND ZZ9.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZZ9_FILIAL     = '" + xfilial ("ZZ9") + "'"
		_oSQL:_sQuery +=    " AND ZZ9_SAFRA      = '" + _sSafra + "'"
		if ! empty (_sParcelas)
			_oSQL:_sQuery +=    " AND ZZ9_PARCEL     IN " + FormatIn (_sParcelas, '/')
		endif
		_oSQL:_sQuery +=    " AND ZZ9_FORNEC + ZZ9_LOJA BETWEEN '" + _sFornIni + _sLojaIni + "' AND '" + _sFornFim + _sLojaFim + "'"
		_oSQL:_sQuery +=    " AND ZZ9_NFCOMP     = ''"
		_oSQL:_sQuery +=  " ORDER BY A2_VACORIG, A2_NOME, ZZ9_FORNEC, ZZ9_LOJA"
		_oSQL:Log ()
		_aFornec = aclone (_oSQL:Qry2Array (.F., .F.))
		u_log (_aFornec)
		procregua (len (_aFornec))
		for _nFornec = 1 to len (_aFornec)
			_sFornIni := _sFornFim := _aFornec [_nFornec, 1]
			_sLojaIni := _sLojaFim := _aFornec [_nFornec, 2]

			zz9 -> (dbsetorder (3))  // ZZ9_FILIAL+ZZ9_FORNEC+ZZ9_LOJA+ZZ9_SAFRA+ZZ9_PARCEL+ZZ9_PRE_NF
			zz9 -> (dbseek (xfilial ("ZZ9") + _sFornIni + _sLojaIni, .T.))
			do while _lContinua ;
				.and. !zz9 -> (eof ()) ;
				.and.  zz9 -> zz9_filial == xfilial ("ZZ9") ;
				.and.  zz9 -> zz9_fornec + zz9 -> zz9_loja <= _sFornFim + _sLojaFim

				if zz9 -> zz9_safra != _sSafra
					zz9 -> (dbskip ())
					loop
				endif
				if ! empty (_sParcelas) .and. ! zz9 -> zz9_parcel $ _sParcelas
					zz9 -> (dbskip ())
					loop
				endif

				// Verifica fornecedor.
				sa2 -> (dbsetorder (1))
				if ! sa2 -> (dbseek (xfilial ("SA2") + zz9 -> zz9_fornec + zz9 -> zz9_loja, .F.))
					u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' nao cadastrado.")
					_lContinua = .F.
					zz9 -> (dbskip ())
					loop
				endif

//				_oAssoc := ClsAssoc():New (zz9 -> zz9_fornec, zz9 -> zz9_loja)
//				if zz9 -> zz9_fornec + zz9 -> zz9_loja != '00136901'  // Livramento
//					if valtype (_oAssoc) != "O" .or. (!_oAssoc:EhSocio (dDataBase) .and. empty (_oAssoc:DtSaida (dDataBase)))  // Ex-associado pode ainda ter a safra para receber.
//						u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' nao e' associado e nem ex-associado.")
//						_lContinua = .F.
//						zz9 -> (dbskip ())
//						loop
//					endif
//				endif

				if empty (zz9 -> zz9_tes)
					u_help ("TES para geracao da nota deve ser informado.")
					_lContinua = .F.
					zz9 -> (dbskip ())
					loop
				endif

				if empty (sa2 -> a2_conta)
					u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' sem conta contabil.")
					_lContinua = .F.
					zz9 -> (dbskip ())
					loop
				endif
	
				u_log ('Iniciando fornecedor ' + zz9 -> zz9_fornec + '/' + zz9 -> zz9_loja)
	
				// Controla quebra por fornecedor, pois cada registro do ZZ9 equivale a um registro
				// de NF de entrada de uva do SD1, mas agora devo somar os valores por fornecedor.
				_sFornece  = zz9 -> zz9_fornec
				_sLoja     = zz9 -> zz9_loja
				_sParcela  = zz9 -> zz9_parcel
				_sZZ9NFOri = zz9 -> zz9_nfori
				_aItens    = {}
				_lFornOk   = .T.
				_aPreNF    = {}
				_sNfOri    = ""
				_sMsgNfZZ9    = ''
				do while _lContinua ;
					.and. !zz9 -> (eof ()) ;
					.and.  zz9 -> zz9_filial == xfilial ("ZZ9") ;
					.and.  zz9 -> zz9_fornec == _sFornece ;
					.and.  zz9 -> zz9_loja   == _sLoja ;
					.and.  zz9 -> zz9_safra  == _sSafra ;
					.and.  zz9 -> zz9_parcel == _sParcela ;
					.and.  zz9 -> zz9_nfori  == _sZZ9NFOri  // Em 25/05/18 a SEFAZ jah nao aceitou mais notas referenciando mais de uma NF origem
	
					u_log ('pre-nf:', zz9 -> zz9_pre_nf, 'parcela:', zz9 -> zz9_parcel)
	
					if ! empty (zz9 -> zz9_nfcomp)  // Nota de compra jah gerada.
						u_log ('nf jah gerada')
						zz9 -> (dbskip ())
						loop
					endif
					if zz9 -> zz9_tiponf != _sTipoNF
						u_log ('tipo nf diferente')
						zz9 -> (dbskip ())
						loop
					endif
					if empty (zz9 -> zz9_grau) .and. zz9 -> zz9_fornec != '001369'
						u_help ("Grau nao informado na pre-nf '" + zz9 -> zz9_pre_nf + "'.")
						_lFornOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
					if zz9 -> zz9_vunit <= 0
						u_help ("Problemas no(s) valor(es) unitario(s) da pre-nf '" + zz9 -> zz9_pre_nf + "'.")
						_lFornOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
		
					// Verifica produto
					sb1 -> (dbsetorder (1))
					if ! sb1 -> (dbseek (xfilial ("SB1") + zz9 -> zz9_produt, .F.))
						u_help ("Produto '" + zz9 -> zz9_produt + "' nao cadastrado.")
						_lFornOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
					if _sVarUva == 1 .and. sb1 -> b1_varuva != "C"
						u_log ('varuva')
						zz9 -> (dbskip ())
						loop
					endif
					if _sVarUva == 2 .and. sb1 -> b1_varuva != "F"
						u_log ('varuva')
						zz9 -> (dbskip ())
						loop
					endif
					if zz9 -> zz9_fornec + zz9 -> zz9_loja != '00136901'  // Livramento
						if sb1 -> b1_varuva == "F" .and. sb1 -> b1_vafcuva == 'F' .and. empty (zz9 -> zz9_classe) .and. empty (zz9 -> zz9_clabd)
							u_help ("Classificacao da uva nao informada na pre-nf '" + zz9 -> zz9_pre_nf + "'.")
							_lFornOk = .F.
							zz9 -> (dbskip ())
							loop
						endif
					endif
	
					// Verificacoes ref. DCO
					if (_nPorDCO == 1 .and. empty (zz9 -> zz9_dco)) .or. (_nPorDCO == 2 .and. !empty (zz9 -> zz9_dco))
						u_log ('dco')
						zz9 -> (dbskip ())
						loop
					endif
					if zz9 -> zz9_tiponf == "C"
						if empty (zz9 -> zz9_preori) .and. empty (zz9 -> zz9_nfori)
							u_help ("NF de complemento sem NF origem ou pre-nota original informada (pre-nf '" + zz9 -> zz9_pre_nf + "').")
							_lFornOk = .F.
							zz9 -> (dbskip ())
							loop
						endif
					endif
						
					// Alimenta lista de mensagens para a nota.
					if ! empty (zz9 -> zz9_msgNF) .and. ! alltrim (zz9 -> zz9_msgNF) $ _sMsgNfZZ9
						_sMsgNFZZ9 += ' ' + alltrim (zz9 -> zz9_msgNF)
					endif

					// Mantem lista de pre-notas atendidas
					if ascan (_aPreNF, zz9 -> zz9_pre_NF) == 0
						aadd (_aPreNF, zz9 -> zz9_pre_NF)
					endif
	
					// Busca uma nota original valida, para uso no D1_NFORI. Jah alimenta lista das notas
					// originais para o campo de dados adicionais.
					if ! empty (zz9 -> zz9_preori)
						_aNfCprOri = aclone (_NfCprOri ())
					else
						_aNfCprOri = {zz9 -> zz9_nfori, zz9 -> zz9_serior, zz9 -> zz9_itemor}
					endif
					if len (_aNFCprOri) == 0
						u_help ("Nao encontrei NF/serie/item de compra para usar como NF/serie/item original na nota de complemento.")
						_lFornOk = .F.
						zz9 -> (dbskip ())
						loop
					endif
					if ! empty (_aNfCprOri [1]) .and. ! alltrim (_aNfCprOri [1]) $ _sNFOri
						_sNFOri += alltrim (_aNfCprOri [1]) + ","
					endif

					// Acumula os valores por produto.
//					_nItem = ascan (_aItens, {|_aVal| _aVal [1] == zz9 -> zz9_produt ;
//					                            .and. _aVal [3] == zz9 -> zz9_grau ;
//					                            .and. _aVal [4] == zz9 -> zz9_classe})
//					if _nItem == 0
//						aadd (_aItens, {zz9 -> zz9_produt, sb1 -> b1_desc, zz9 -> zz9_grau, zz9 -> zz9_classe, zz9 -> zz9_clabd, 0, 0, _aNfCprOri [1], _aNfCprOri [2], _aNfCprOri [3], zz9 -> zz9_conduc})
//						_nItem = len (_aItens)
//					endif
//					_aItens [_nItem, 6] += zz9 -> zz9_vunit
//					if (empty (_aItens [_nItem, 7]) .or. empty (_aItens [_nItem, 9])) .and. ! empty (_aNfCprOri [1])  // Caso pre-nf a anterior tenha ficado sem NF original
//						_aItens [_nItem,  8] = _aNfCprOri [1]  // NF
//						_aItens [_nItem,  9] = _aNfCprOri [2]  // Serie
//						_aItens [_nItem, 10] = right (alltrim (_aNfCprOri [3]), 2)  // Item
//					endif
					_nItem = ascan (_aItens, {|_aVal| _aVal [.ItensProduto]    == zz9 -> zz9_produt ;
					                            .and. _aVal [.ItensGrau]       == zz9 -> zz9_grau ;
					                            .and. _aVal [.ItensClasEspald] == zz9 -> zz9_classe})
					if _nItem == 0
						aadd (_aItens, array (.ItensQtColunas))
						_nItem = len (_aItens)
						_aItens [_nItem, .ItensProduto] = zz9 -> zz9_produt
						_aItens [_nItem, .ItensDescricao] = sb1 -> b1_desc
						_aItens [_nItem, .ItensGrau]      = zz9 -> zz9_grau
						_aItens [_nItem, .ItensClasEspald] = zz9 -> zz9_classe
						_aItens [_nItem, .ItensClasLatada] = zz9 -> zz9_clabd
						_aItens [_nItem, .ItensQuantidade] = 0
						_aItens [_nItem, .ItensValorTotal] = 0
						_aItens [_nItem, .ItensNFOri]      = _aNfCprOri [1]
						_aItens [_nItem, .ItensSerieOri]   = _aNfCprOri [2]
						_aItens [_nItem, .ItensItemOri]    = _aNfCprOri [3]
						_aItens [_nItem, .ItensConducao]   = zz9 -> zz9_conduc
						_aItens [_nItem, .ItensTES]        = zz9 -> zz9_tes
					endif
					_aItens [_nItem, .ItensValorTotal] += zz9 -> zz9_vunit  // Complemento nao tem quantidade, entao grava o valor total.
					if (empty (_aItens [_nItem, .ItensNFOri]) .or. empty (_aItens [_nItem, .ItensSerieOri])) .and. ! empty (_aNfCprOri [1])  // Caso pre-nf a anterior tenha ficado sem NF original
						_aItens [_nItem, .ItensNFOri]    = _aNfCprOri [1]  // NF
						_aItens [_nItem, .ItensSerieOri] = _aNfCprOri [2]  // Serie
						_aItens [_nItem, .ItensItemOri]  = _aNfCprOri [3]  // Item
					endif

					zz9 -> (dbskip ())
				enddo
	
				u_log ("_lFornOk:", _lFornOk)
	
				// A nota pode jah ter sido gerada em processamento anterior ou pode ter sido detectado algum erro no fornecedor.
				if len (_aItens) == 0 .or. ! _lFornOk
					u_log ('sem itens')
					loop
				endif
	
				// Prepara dados adicionais
				_sMsgContr = ""
				_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Complem.valor ref.NNF entrada " + substr (_sNFOri, 1, len (_sNFOri) - 1)
				if ! empty (_sMsgNfZZ9)
					_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + _sMsgNfZZ9
				endif
	
				_lContinua = _GeraNota ("C", _sFornece, _sLoja, _aItens, _sMsgContr, _sSerie, sa2 -> a2_est, "", _aPreNF, _sSafra, _sCondPag, _sParcela, _sGrpZZ9)
				
			enddo
		next
	endif


	if ! _lContinua
		u_help ("PROCESSO CANCELADO. Notas ja' geradas: de '" + _sNFIni + "' a '" + _sNFFim + "'")
	else
		u_help ("Notas geradas: de '" + _sNFIni + "' a '" + _sNFFim + "'")
	endif
		
	// Notifica setor de RH (nao lembro agora para que precisam ficar sabendo, acho que tem a ver com FUNRURAL) e custos.
	if _sNFIni != _sNFFim
		U_ZZUNU ({'019', '023', '069'}, ;  // Fiscal, RH e custos.
		          "Geracao nota(s) de compra / complemento preco safra", ;
		         "Aviso do sistema: foram geradas notas de compra / complemento de preco de safra na filial " + cFilAnt + chr (13) + chr (10) + ;
		         "Notas geradas: de '" + _sNFIni + "' a '" + _sNFFim + "'")
	endif
Return



// --------------------------------------------------------------------------
// Busca a NF de compra que deverah ser considerada como NF original para a nota de complemento de preco.
Static Function _NfCprOri ()
	local _aRet := {"","",""}
	local _oSQL := ClsSQL():New ()
//	u_logIni ()
//	u_log ('Vou procurar nota de origem considerando o seguinte registro do ZZ9:')
//	u_logtrb ('ZZ9')
	
	// Busca a contranota gerada para a pre-nota de origem.
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT D1_DOC, D1_SERIE, D1_ITEM"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1, "
	_oSQL:_sQuery +=              RetSQLName ("ZZ9") + " ZZ9 "
	_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  = ZZ9_FILIAL"
	_oSQL:_sQuery +=    " AND SD1.D1_FORNECE = ZZ9_FORNEC"
	_oSQL:_sQuery +=    " AND SD1.D1_LOJA    = ZZ9_LOJA"
	_oSQL:_sQuery +=    " AND SD1.D1_DOC     = ZZ9_NFCOMP"
	_oSQL:_sQuery +=    " AND SD1.D1_SERIE   = ZZ9_SERCOM"
	_oSQL:_sQuery +=    " AND SD1.D1_COD     = ZZ9_PRODUT"
	_oSQL:_sQuery +=    " AND SD1.D1_GRAU    = ZZ9_GRAU"
	_oSQL:_sQuery +=    " AND SD1.D1_PRM99   = ZZ9_CLASSE"
	_oSQL:_sQuery +=    " AND ZZ9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_FILIAL = '" + zz9 -> zz9_filial + "'"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_SAFRA  = '" + zz9 -> zz9_safra  + "'"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_FORNEC = '" + zz9 -> zz9_fornec + "'"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_LOJA   = '" + zz9 -> zz9_loja   + "'"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_PRODUT = '" + zz9 -> zz9_produt + "'"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_GRAU   = '" + zz9 -> zz9_grau   + "'"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_CLASSE = '" + zz9 -> zz9_classe + "'"
	_oSQL:_sQuery +=    " AND ZZ9.ZZ9_PRE_NF = '" + zz9 -> zz9_PreOri + "'"
	//_oSQL:Log ()
	_aRet = aclone (_oSQL:Qry2Array (.f., .f.))
	if len (_aRet) == 0
		u_help ("Nao foi possivel definir NF original")
		_aRet = {}
	else
		_aRet = aclone (_aRet[1])
	endif
	//u_logFim ()
return _aRet



// --------------------------------------------------------------------------
// Gera a nota de entrada com os dados informados.
Static Function _GeraNota (_sTipoNota, _sFornece, _sLoja, _aItens, _sMsgContr, _sSerie, _sUF, _sDCO, _aPreNF, _sSafra, _sCondPag, _sParcela, _sGrpPagto)
	local _sNF       := ""
	local _nItem     := 0
	local _nQuant    := 0
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _lContinua := .T.
	local _oCtaCorr  := NIL
	local _sNFPRur   := ""
	local _oSQL      := NIL
	local _sMemoAnt  := ""

	u_logIni ()

	// A partir de 2012 preciso informar uma NF de produtor rural referenciada. Como aqui sao misturadas
	// diversas notas, pegarei uma das notas de entrada de safra deste associado.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT TOP 1 NF_PRODUTOR"
	_oSQL:_sQuery +=   " FROM dbo.VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE V.SAFRA      = '" + _sSafra + "'"
	_oSQL:_sQuery +=    " AND V.FILIAL     = '" + cFilAnt + "'"
	_oSQL:_sQuery +=    " AND V.ASSOCIADO  = '" + _sFornece + "'"
	_oSQL:_sQuery +=    " AND V.LOJA_ASSOC = '" + _sLoja + "'"
	_oSQL:_sQuery +=    " AND V.TIPO_NF    = 'E'"
	_oSQL:_sQuery +=    " AND V.PRODUTO    = '" + _aItens [1, .ItensProduto] + "'"
	_sNFPRur = _oSQL:RetQry (1, .F.)

	// Busca a Proxima NF da Sequencia
	_sNF = NxtSX5Nota (_sSerie)

	// Prepara campos do cabecalho da nota
	_aAutoSF1 := {}
	AADD( _aAutoSF1, { "F1_DOC"      , _sNF,           Nil } )
	AADD( _aAutoSF1, { "F1_SERIE"    , _sSerie,        Nil } )
	AADD( _aAutoSF1, { "F1_TIPO"     , _sTipoNota,     Nil } )
	AADD( _aAutoSF1, { "F1_FORMUL"   , "S",            Nil } )
	AADD( _aAutoSF1, { "F1_EMISSAO"  , dDataBase,      Nil } )
	AADD( _aAutoSF1, { "F1_FORNECE"  , _sFornece,      Nil } )
	AADD( _aAutoSF1, { "F1_LOJA"     , _sLoja,         Nil } )
	AADD( _aAutoSF1, { "F1_EST"      , _sUF,           Nil } )
	AADD( _aAutoSF1, { "F1_ESPECIE"  , "SPED",         Nil } )
	AADD( _aAutoSF1, { "F1_COND"     , _sCondPag,      Nil } )
	AADD( _aAutoSF1, { "F1_VADCO"    , _sDCO,          Nil } )  // Cpo customizado: serah tratado no P.E. SF1100I
	AADD( _aAutoSF1, { "F1_VANFPRO"  , _sNFPRur,       Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
	AADD( _aAutoSF1, { "F1_VASAFRA"  , _sSafra,        Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
	AADD( _aAutoSF1, { "F1_VAGPSAF"  , _sGrpPagto,     Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
	AADD( _aAutoSF1, { "F1_VAFLAG"   , 'G',            Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I. Indica 'nota ja gerada' para a rotina de manut. XML


//	u_log ("Fornecedor:", _sFornece, _sLoja)
//	u_log ("Msg.:", _sMsgContr)
//	u_log ("Pre-notas:", _aPreNF)
//	u_log ("Cabecalho:", _aAutoSF1)
//	if _sTipoNota == "C"
//		u_log ("Itens:", _aitens)
//	endif

	// Prepara itens da nota
	_aAutoSD1 = {}
	for _nItem = 1 to len (_aItens)

		sb1 -> (dbsetorder (1))
		sb1 -> (dbseek (xfilial ("SB1") + _aItens [_nItem, .ItensProduto], .F.))
		
		// Monta descricao com grau e classificacao da uva. Inicia com o grau e classificacao, reduzindo o nome da uva caso necessario.
		_sDescri = " Gr:" + alltrim (_aItens [_nItem, .ItensGrau])
		if ! empty (_aItens [_nItem, 4])  // Classificacao espaldeira (DS/D/C/B/A/AA)
			_sDescri += " Clas.:" + alltrim (_aItens [_nItem, .ItensClasEspald])
		elseif ! empty (_aItens [_nItem, 5])  // Classificacao latada (A/B/D)
			_sDescri += " Clas.:" + alltrim (_aItens [_nItem, .ItensClasLatada])
		endif
		_sDescri = left (alltrim (_aItens [_nItem, .ItensDescricao]), _nTamDesc - len (_sDescri)) + _sDescri

		// Arredonda valor total p/ 2 casas p/ compatibilizar com SFT, SF3, SE2, contabilizacao, SPED, etc...
		if _sTipoNota == "N"
			_nQuant = round (_aItens [_nItem, .ItensQuantidade], TamSX3 ("D1_QUANT")[2])
			_nVlUni = _aItens [_nItem, .ItensValorTotal] / _nQuant
			_nVlTot = round (_nQuant * _nVlUni, 2)
		else
			_nQuant = 0
			_nVlUni = 0
			_nVlTot = round (_aItens [_nItem, .ItensValorTotal], 2)
		endif

		// Prepara array com o item para a nota
		_aLinha = {}
		AADD(_aLinha , {"D1_COD"     , _aItens [_nItem, .ItensProduto]  , Nil } )
		AADD(_aLinha , {"D1_TES"     , _aItens [_nItem, .ItensTES]    , Nil } )
		AADD(_aLinha , {"D1_LOCAL"   , sb1 -> B1_LOCPAD     , Nil } )
		AADD(_aLinha , {"D1_DESCRI"  , _sDescri             , Nil } )
		AADD(_aLinha , {"D1_GRAU"    , _aItens [_nItem, .ItensGrau]  , Nil } )
		AADD(_aLinha , {"D1_PRM99"   , _aItens [_nItem, .ItensClasEspald]  , Nil } )
		AADD(_aLinha , {"D1_VACLABD" , _aItens [_nItem, .ItensClasLatada]  , Nil } )
		AADD(_aLinha , {"D1_TOTAL"   , _nVlTot              , Nil } )
		AADD(_aLinha , {"D1_VAVOLES" , "KG"                 , Nil } )
		AADD(_aLinha , {"D1_VACONDU" , _aItens [_nItem, .ItensConducao] , Nil } )
		if _sTipoNota == "N"
			AADD(_aLinha , {"D1_UM"      , sb1 -> B1_UM         , Nil } )
			AADD(_aLinha , {"D1_TP"      , sb1 -> B1_TIPO       , Nil } )
			AADD(_aLinha , {"D1_QUANT"   , _nQuant              , Nil } )
			AADD(_aLinha , {"D1_VUNIT"   , _nVlUni              , Nil } )
			AADD(_aLinha , {"D1_PESBRT"  , _nQuant              , Nil } )
			AADD(_aLinha , {"D1_VAVOLQT" , _nQuant              , Nil } )
		else
			AADD(_aLinha , {"D1_VAVOLQT", 1                    , Nil } )
			AADD(_aLinha , {"D1_NFORI",   _aItens [_nItem, .ItensNFOri]  , Nil } )
			AADD(_aLinha , {"D1_SERIORI", _aItens [_nItem, .ItensSerieOri]  , Nil } )
			// Essa RONHA desse sistema nao aceita por que precisa 4 digitos, mas a mascara do campo tem 2... o jeito foi passar por cima da validacao padrao. -->  AADD(_aLinha , {"D1_ITEMORI", right (_aItens [_nItem, 9], tamsx3 ("D1_ITEMORI")[1]) , Nil } )
			AADD(_aLinha , {"D1_ITEMORI", right (_aItens [_nItem, .ItensItemOri], tamsx3 ("D1_ITEMORI")[1]) , '.t.' } )
		endif
		U_LOG (aClone (U_OrdAuto (_aLinha)))
		AADD(_aAutoSD1, aClone (U_OrdAuto (_aLinha)))
	next

	// Gera a NF de Compra
	_sErroAuto = ""
	lMsHelpAuto := .F.  // se .t. direciona as mensagens de help
	lMsErroAuto := .F.  // necessario a criacao
	DbSelectArea("SF1")
	dbsetorder (1)
	MsExecAuto({|x,y,z|MATA103(x,y,z)},_aAutoSF1,_aAutoSD1,3)
	If lMsErroAuto
		u_help (_sErroAuto + chr (13) + chr (10) + U_LeErro (memoread (NomeAutoLog ())))
		_lContinua = .F.
	else
		U_LOG ("NF " + sf1 -> f1_doc + " gerada")

		// Grava dados adicionais na nota.
		if ! empty (_sMsgContr)
			if empty (sf1 -> f1_vacmemc)
				//u_log ('Incluindo memo no SF1:', _sMsgContr)
				msmm(,,,_sMsgContr,1,,,"SF1","F1_VACMEMC")
			else
				_sMemoAnt = alltrim (MSMM (sf1->f1_vacmemc,,,,3))
				//u_log ("Acrescentando '" + _sMsgContr + "' ao memo do SF1, que continha '" + _sMemoAnt + "'")
				msmm (sf1 -> f1_vacmemc,,, _sMemoAnt + '; ' + _sMsgContr, 1,,,"SF1","F1_VACMEMC")
			endif
		endif
		u_log ('dados adicionais gravados')

		// Grava no ZZ9 o numero da nota gerada, para evitar geracao em duplicidade.
		dbselectarea ("ZZ9")
		_aAreaZZ9 := GetArea ()
		zz9 -> (dbsetorder (3))  // ZZ9_FILIAL+ZZ9_FORNEC+ZZ9_LOJA+ZZ9_SAFRA+ZZ9_PARCEL
		zz9 -> (dbseek (xfilial ("ZZ9") + sf1 -> f1_fornece + sf1 -> f1_loja + _sSafra, .T.))
		do while  !zz9 -> (eof ()) ;
			.and.  zz9 -> zz9_filial == xfilial ("ZZ9") ;
			.and.  zz9 -> zz9_fornec == sf1 -> f1_fornece ;
			.and.  zz9 -> zz9_loja   == sf1 -> f1_loja ;
			.and.  zz9 -> zz9_safra  == _sSafra
			
//			if zz9 -> zz9_parcel != _sParcela
			if zz9 -> zz9_parcel != _sParcela .or. zz9 -> zz9_grupo != _sGrpZZ9
				zz9 -> (dbskip ())
				loop
			endif

			if ascan (_aPreNF, zz9 -> zz9_pre_nf) > 0 .and. empty (zz9 -> zz9_nfcomp)
				//u_log ('Atualizando ZZ9')
				reclock ("ZZ9", .F.)
				zz9 -> zz9_nfComp = sf1 -> f1_doc
				zz9 -> zz9_serCom = sf1 -> f1_serie
				msunlock ()
			endif
			zz9 -> (dbskip ())
		enddo
		RestArea (_aAreaZZ9)
		u_log ('ZZ9 atualizado')

		// Guarda intervalo de numeracao para mostrar em mensagem no final do processo.
		if empty (_sNFIni)
			_sNFIni = sf1 -> f1_doc
		endif
		_sNFFim = sf1 -> f1_doc
	endif

	// Gera entrada na conta corrente do associado, com base nos titulos gerados no financeiro.
//	if _lContinua
	if _lContinua .and. sf1 -> f1_fornece != '001369'
		_sQuery := ""
		_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCREA, E2_NUM, E2_PREFIXO, E2_TIPO, E2_VALOR, E2_SALDO, E2_HIST, R_E_C_N_O_, E2_LA, E2_PARCELA,"
		_sQuery +=        " ROW_NUMBER () OVER (ORDER BY E2_PARCELA) AS NUM_PARC"
		_sQuery +=   " FROM " + RetSQLName ("SE2")
		_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_sQuery +=    " AND E2_TIPO    = 'NF'"
		_sQuery +=    " AND E2_FORNECE = '" + sf1 -> f1_fornece + "'"
		_sQuery +=    " AND E2_LOJA    = '" + sf1 -> f1_loja + "'"
		_sQuery +=    " AND E2_PREFIXO = '" + sf1 -> f1_serie + "'"
		_sQuery +=    " AND E2_NUM     = '" + sf1 -> f1_doc + "'"
		_sQuery +=    " AND E2_VACHVEX = ''"
		_sQuery +=    " AND E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_sQuery +=  " ORDER BY E2_PARCELA"
		//u_log (_sQuery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		U_TCSetFld (alias ())
		do while ! (_sAliasQ) -> (eof ())
	  		//u_log ('Filial:' + (_sAliasQ) -> e2_filial, 'Forn:' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' ' + (_sAliasQ) -> e2_nomfor, 'Emis:', (_sAliasQ) -> e2_emissao, 'Vcto:', (_sAliasQ) -> e2_vencrea, 'Doc:', (_sAliasQ) -> e2_num+'/'+(_sAliasQ) -> e2_prefixo, 'Tipo:', (_sAliasQ) -> e2_tipo, 'Valor: ' + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99"), 'Saldo: ' + transform ((_sAliasQ) -> e2_saldo, "@E 999,999,999.99"), (_sAliasQ) -> e2_hist)
	
			_oCtaCorr := ClsCtaCorr():New ()
			_oCtaCorr:Assoc    = (_sAliasQ) -> e2_fornece
			_oCtaCorr:Loja     = (_sAliasQ) -> e2_loja
			_oCtaCorr:TM       = '13'
			_oCtaCorr:DtMovto  = (_sAliasQ) -> e2_EMISSAO
			_oCtaCorr:Valor    = (_sAliasQ) -> e2_valor
			_oCtaCorr:SaldoAtu = (_sAliasQ) -> e2_saldo
			_oCtaCorr:Usuario  = cUserName
			_oCtaCorr:Histor   = iif (_sTipoNota == "C", 'COMPL.', '') + 'COMPRA SAFRA ' + _sSafra + " GRP." + _sGrpPagto
			_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
			_oCtaCorr:Doc      = (_sAliasQ) -> e2_num
			_oCtaCorr:Serie    = (_sAliasQ) -> e2_prefixo
			_oCtaCorr:Parcela  = (_sAliasQ) -> e2_parcela
			_oCtaCorr:Origem   = _sOrigSZI
			if _oCtaCorr:PodeIncl ()
				if ! _oCtaCorr:Grava (.F., .F.)
					U_help ("Erro na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
					_lContinua = .F.
				else
					se2 -> (dbgoto ((_sAliasQ) -> r_e_c_n_o_))
					if empty (se2 -> e2_vachvex)  // Soh pra garantir...
						reclock ("SE2", .F.)
						se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
						msunlock ()
					endif
				endif
			else
				U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
				_lContinua = .F.
			endif

			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif

	u_logFim ()
return _lContinua



// --------------------------------------------------------------------------
// Valida condicao de pagamento
static function _ValCond ()
	local _lRet      := .T.
	local _nLinha    := 1
	local _sMsgVcto  := ''
	local _nVcto	 := 0
	local _aTestCond := condicao (100, mv_par11,, date ())

	// Provavelmente precise ajustar isto para cada nova safra...
	u_log (_aTestCond)
	if _lRet
		if mv_par05 == '2019' .and. left (dtos (date ()), 6) == '201904'  // Em abril estamos gerando a 'safrinha' por que a compra inicial jah foi feita.
			if (mv_par07 == 'A' .and. len (_aTestCond) != 4) .or. (mv_par07 == 'B' .and. len (_aTestCond) != 8) .or. (mv_par07 == 'C' .and. len (_aTestCond) != 10)
				_lRet = u_MsgNoYes ('Quantidade de parcelas (' + cvaltochar (len (_aTestCond)) + ') da condicao de pagamento incompativel com o grupo ZZ9 a gerar. Confirma?')
			endif
		else
			if (mv_par07 == 'A' .and. len (_aTestCond) != 5) .or. (mv_par07 == 'B' .and. len (_aTestCond) != 9) .or. (mv_par07 == 'C' .and. len (_aTestCond) != 11)
				_lRet = u_MsgNoYes ('Quantidade de parcelas (' + cvaltochar (len (_aTestCond)) + ') da condicao de pagamento incompativel com o grupo ZZ9 a gerar. Confirma?')
			endif
		endif
	endif
	if _lRet
		for _nLinha = 2 to len (_aTestCond)
			//u_log (year (_aTestCond [_nLinha, 1]), month (_aTestCond [_nLinha, 1]), year (_aTestCond [_nLinha - 1, 1]) , month (_aTestCond [_nLinha - 1, 1]))
			if left (dtos (_aTestCond [_nLinha, 1]), 6) <= left (dtos (_aTestCond [_nLinha - 1, 1]), 6)
				//u_log (_aTestCond)
				u_help ("Condicao de pagamento vai gerar mais de um vencimento no mesmo mes.")
				_lRet = .F.
			endif
		next
	endif
	if _lRet
		// Valida com o usuario os vencimentos a serem gerados.
		_sMsgVcto = ''
		for _nVcto = 1 to len (_aTestCond)
			_sMsgVcto += dtoc (_aTestCond [_nVcto, 1]) + '  -  '
		next
		_lRet = U_MsgYesNo ("As notas serao geradas com a(s) seguinte(s) data(s) de vencimento:" + chr (10) + chr (13) + _sMsgVcto + chr (10) + chr (13) + "Confirma?")
	endif
return _lRet



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                               Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",   "SA2", {},                                  "Codigo do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",   "SA2", {},                                  "Loja do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",   "SA2", {},                                  "Codigo do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",   "SA2", {},                                  "Loja do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,  0,  "",   "   ", {},                                  "Safra (ano) para a qual serao geradas as notas de compra."})
	aadd (_aRegsPerg, {06, "Parcelas sep.barras(bco=todas)", "C", 30, 0,  "",   "   ", {},                                  "Parcelas. Ex.: A/B/F"})
	aadd (_aRegsPerg, {07, "Grupo ZZ9                     ", "C", 1,  0,  "",   "   ", {},                                  "Grupo de produtso (geralmente para identificar parcelamento)"})
	aadd (_aRegsPerg, {08, "Geracao por DCO               ", "C", 1,  0,  "",   "   ", {"Com DCO", "Sem DCO", "Todos"},     "Permite gerar separadamente as notas envolvidas em leilao da CONAB."})
	aadd (_aRegsPerg, {09, "Variedade de uva              ", "N", 1,  0,  "",   "   ", {"Comum", "Fina", "Todas"},          "Permite gerar separadamente as notas por tipo de uva."})
	aadd (_aRegsPerg, {10, "Tipo de nota a gerar          ", "N", 1,  0,  "",   "   ", {"Normais", "Compl.preco"},          "Compl.preco eh sobre as compras feitas a preco minimo do governo."})
	aadd (_aRegsPerg, {11, "Cond.pagto a usar             ", "C", 3,  0,  "",   "SE4", {},                                  ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
return
