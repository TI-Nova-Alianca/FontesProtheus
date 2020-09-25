// Programa...: FrtNFE
// Autor......: Robert Koch
// Data.......: 17/04/2008
// Descricao..: Rotina de atualizacao dos fretes referente NF de entrada (conhecimento de frete)
//
// Historico de alteracoes:
// 22/07/2008 - Robert - Leitura de novos campos do ZZ1.
// 19/08/2008 - Robert - Gravacao de NFs de venda previstas e nao previstas.
// 20/08/2008 - Robert - Tratamento do SZH e rateio de fretes refeito, passa a ser 'por item', via SZH.
// 27/08/2008 - Robert - Criado tratamento para redespacho.
// 24/02/2010 - Robert - Criado tratamento para fretes sobre devolucoes de vendas (campo ZH_DEVVD)
// 20/03/2012 - Robert - Criado tratamento para o campo ZH_TPDESP.
// 26/03/2012 - Robert - Na validacao da NF entrada nao exige mais CTR, basta que seja um item do VA_PRODCIF.
// 09/01/2015 - Catia  - tirar comentario das linhas que gravavam o SZH a partir do .FrtNaoPrev
// 01/03/2015 - Catia  - Alterado a gravação da SZH para que grave a data e o tipo do frete
// 21/03/2017 - Robert - Eliminada gravacao de logs.
// 06/06/2019 - Catia  - passar a gravar o ICMS creditado na tabela SZH campo ZH_CREDICM
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function FrtNFE (_sIncExc)
	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lRet      := .T.
	local _nTotSD1   :=0
	local _aDadosZZ1 := {}
	local _nRegZZ1   := 0
	local _nNaoPrev  := 0
	local _sQuery    := ""
	local _sSeqEnt   := ""
	local _nTotFret  := 0
	local _nTotPeso  := 0
	local _nFrtAcum  := 0
	local _aMaiorIt  := {"", 0}
	local _oSQL      := NIL
	local _n		 := 1

	if _sIncExc == "I"  // Inclusao de nota
		if type ("_oClsFrtFr") == "O"

			// Busca o valor do frete para posterior rateio sobre os itens da venda (por peso)
			_sQuery := ""
			//_sQuery += " select SUM (CASE F4_LFICM WHEN 'S' THEN D1_TOTAL - D1_VALICM ELSE D1_TOTAL END)"
			_sQuery += " select SUM (D1_TOTAL)"
			_sQuery += "      , SUM (D1_VALICM)"
			_sQuery += "   from " + RetSQLName ("SD1") + " SD1,"
			_sQuery +=              RetSQLName ("SF4") + " SF4 "
			_sQuery += "  where SD1.D_E_L_E_T_ != '*'"
			_sQuery += "    and D1_FILIAL   = '" + xfilial ("SD1") + "'"
			_sQuery += "    and D1_DOC      = '" + sf1 -> f1_doc + "'"
			_sQuery += "    and D1_SERIE    = '" + sf1 -> f1_serie + "'"
			_sQuery += "    and D1_FORNECE  = '" + sf1 -> f1_fornece + "'"
			_sQuery += "    and D1_LOJA     = '" + sf1 -> f1_loja + "'"
			_sQuery += "    and D1_COD      IN " + FormatIn (alltrim (GetMv ('VA_PRODCIF')), '/')
			_sQuery += "    and SF4.D_E_L_E_T_ != '*'"
			_sQuery += "    and F4_FILIAL   = '" + xfilial ("SF4") + "'"
			_sQuery += "    and F4_CODIGO   = SD1.D1_TES"
			//u_log ('valor frete:', _sQuery)
			//u_showmemo(_sQuery)
			//_nTotFret = U_RetSQL (_sQuery)
			_aDados := U_Qry2Array(_sQuery)
 		
			if len(_aDados) = 1
				_nTotFret := _aDados[1,1] 
				_nTotIcms := _aDados[1,2]
			endif	
		
			// Busca o peso total das notas de venda para posterior rateio.
			// Busca tanTo as que estavam previstas neste frete como as nao previstas.
			for _nRegZZ1 = 1 to len (_oClsFrtFr:_aRegsZZ1)
				zz1 -> (dbgoto (_oClsFrtFr:_aRegsZZ1 [_nRegZZ1]))
				_sQuery := ""
				_sQuery += " select SUM (D2_QUANT * D2_PESO)"
				_sQuery += "   from " + RetSQLName ("SD2") + " SD2 "
				_sQuery += "  where SD2.D_E_L_E_T_ != '*'"
				_sQuery += "    and D2_FILIAL   = '" + xfilial ("SD2") + "'"
				_sQuery += "    and D2_DOC      = '" + zz1 -> zz1_docs + "'"
				_sQuery += "    and D2_SERIE    = '" + zz1 -> zz1_series + "'"
				//u_log ('prev.:', _sQuery)
				//u_showmemo(_sQuery)
				_nTotPeso += U_RetSQL (_sQuery)
			next
			for _nNaoPrev = 1 to len (_oClsFrtFr:_aNaoPrev)
				_sQuery := ""
				_sQuery += " select SUM (D2_QUANT * D2_PESO)"
				_sQuery += "   from " + RetSQLName ("SD2") + " SD2 "
				_sQuery += "  where SD2.D_E_L_E_T_ != '*'"
				_sQuery += "    and D2_FILIAL   = '" + xfilial ("SD2") + "'"
				_sQuery += "    and D2_DOC      = '" + _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevDoc] + "'"
				_sQuery += "    and D2_SERIE    = '" + _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevSerie] + "'"
				//u_log ('nao prev.:', _sQuery)
				//u_showmemo(_sQuery)
				_nTotPeso += U_RetSQL (_sQuery)
			next

			// Grava no SZH as entregas que tinham previsao, fazendo um rateio do frete por peso.
			// Vai acumulando o total de frete 'jah rateado' para posterior ajuste de arredondamentos.
			_nFrtAcum = 0
			sd2 -> (dbsetorder (3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
			for _nRegZZ1 = 1 to len (_oClsFrtFr:_aRegsZZ1)
				zz1 -> (dbgoto (_oClsFrtFr:_aRegsZZ1 [_nRegZZ1]))
				// Grava um registro no SZH para cada item da nota original, para ter rastreabilidade
				// dos rateios de frete, para o caso de ter que excluir algum conhecimento.
				sd2 -> (dbseek (xfilial ("SD2") + zz1 -> zz1_docs + zz1 -> zz1_series, .T.))
				do while ! sd2 -> (eof ()) .and. sd2 -> d2_filial == xfilial ("SD2") .and. sd2 -> d2_doc == zz1 -> zz1_docs .and. sd2 -> d2_serie == zz1 -> zz1_series
					//u_log ('gravando SZH (previstos)')
					_wrateio := round ((sd2 -> d2_peso * sd2 -> d2_quant) * _nTotFret / _nTotPeso, 2)
					if _nTotIcms > 0 
						_wicms   := ROUND(_nTotIcms * _wrateio / _nTotPeso ,2)
					else
						_wicms   := 0
					endif	
					reclock ("SZH", .T.)
						szh -> zh_filial = xfilial ("SZH")
						szh -> zh_fornece = sf1 -> f1_fornece
						szh -> zh_loja    = sf1 -> f1_loja
						szh -> zh_NFFrete = sf1 -> f1_doc
						szh -> zh_SerFret = sf1 -> f1_serie
						szh -> zh_NFSaida = zz1 -> zz1_docs
						szh -> zh_SerNFS  = zz1 -> zz1_series
						szh -> zh_ItNFS   = sd2 -> d2_item
						szh -> zh_SeqEntr = "1"
						szh -> zh_Rateio  = _wrateio
						szh -> zh_credIcm = _wicms
						szh -> zh_TpDesp  = "1"
						szh -> zh_TpFre   = 'S'
						szh -> zh_Data    = sf1 -> f1_dtdigit
					msunlock ()
					
					_nFrtAcum += szh -> zh_Rateio
					
					reclock ("SD2", .F.)
						sd2 -> d2_fretcif += szh -> zh_rateio
					msunlock ()
					
					sd2 -> (dbskip ())
				enddo
			next

			// Grava no SZH as entregas nao previstas / reentregas / redespachos / etc, fazendo um rateio do frete por peso.
			// Vai acumulando o total de frete 'jah rateado' para posterior ajuste de arredondamentos.
			sd2 -> (dbsetorder (3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
			for _nNaoPrev = 1 to len (_oClsFrtFr:_aNaoPrev)
				// Grava um registro no SZH para cada item da nota original, para ter rastreabilidade
				// dos rateios de frete, para o caso de ter que excluir algum conhecimento.
				sd2 -> (dbseek (xfilial ("SD2") + _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevDoc] + _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevSerie], .T.))
				do while ! sd2 -> (eof ()) ;
					.and. sd2 -> d2_filial == xfilial ("SD2") ;
					.and. sd2 -> d2_doc == _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevDoc] ;
					.and. sd2 -> d2_serie == _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevSerie]
					
					// Gera proxima sequencia para este item da NF.
					_sQuery := ""
					_sQuery += " Select isnull (max (ZH_SEQENTR), '')"
					_sQuery += "   From " + RetSQLName ("SZH") + " as SZH "
					_sQuery += "  Where SZH.D_E_L_E_T_ = ''"
					_sQuery += "    And SZH.ZH_FILIAL  = '" + xfilial ("SZH") + "'"
					_sQuery += "    And SZH.ZH_NFSAIDA = '" + sd2 -> d2_doc   + "'"
					_sQuery += "    And SZH.ZH_SERNFS  = '" + sd2 -> d2_serie + "'"
					_sQuery += "    And SZH.ZH_ITNFS   = '" + sd2 -> d2_item  + "'"
					_sSeqEnt = soma1 (U_RetSQL (_sQuery))
					
					//u_log ('gravando SZH (nao previstos)')
					
					_wrateio := round ((sd2 -> d2_peso * sd2 -> d2_quant) * _nTotFret / _nTotPeso, 2)
					if _nTotIcms > 0 
						_wicms   := ROUND(_nTotIcms * _wrateio / _nTotPeso ,2)
					else
						_wicms   := 0
					endif	
					
					reclock ("SZH", .T.)
						szh -> zh_filial = xfilial ("SZH")
						szh -> zh_fornece = sf1 -> f1_fornece
						szh -> zh_loja    = sf1 -> f1_loja
						szh -> zh_NFFrete = sf1 -> f1_doc
						szh -> zh_SerFret = sf1 -> f1_serie
						szh -> zh_NFSaida = sd2 -> d2_doc
						szh -> zh_SerNFS  = sd2 -> d2_serie
						szh -> zh_ItNFS   = sd2 -> d2_item
						szh -> zh_Rateio  = _wrateio
						szh -> zh_credIcm = _wicms
						szh -> zh_SeqEntr = _sSeqEnt
	//					szh -> zh_Redesp  = _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevRedespacho]
	//					szh -> zh_DevVd   = _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevSobreDevolucao]
						szh -> zh_TpDesp  = _oClsFrtFr:_aNaoPrev [_nNaoPrev, .FrtNaoPrevTipoServico]
						szh -> zh_TpFre   = 'S'
						szh -> zh_Data    = sf1 -> f1_dtdigit
					msunlock ()
					_nFrtAcum += szh -> zh_Rateio
					reclock ("SD2", .F.)
					sd2 -> d2_fretcif += szh -> zh_rateio
					msunlock ()
					sd2 -> (dbskip ())
				enddo
			next

			// Feitas as gravacoes, faz um ajuste no item que tiver maior valor, pois, como
			// o rateio do frete eh feito por regra de tres, sempre existe algum arredondamento
			// que impede que a soma dos itens feche com o total.
			if _nFrtAcum != _nTotFret

				// Busca o item que recebeu o maior valor de frete
				_sQuery := ""
				_sQuery += " Select top 1 ZH_NFSAIDA, ZH_SERNFS, ZH_ITNFS "
				_sQuery += "   From " + RetSQLName ("SZH")
				_sQuery += "  where D_E_L_E_T_ = ' '"
				_sQuery += "    and ZH_FILIAL  = '" + xfilial ("SZH")   + "'"
				_sQuery += "    and ZH_NFFRETE = '" + sf1 -> f1_doc     + "'"
				_sQuery += "    and ZH_SERFRET = '" + sf1 -> f1_serie   + "'"
				_sQuery += "    and ZH_FORNECE = '" + sf1 -> f1_fornece + "'"
				_sQuery += "    and ZH_LOJA    = '" + sf1 -> f1_loja    + "'"
				_sQuery += "  Order by ZH_RATEIO desc"
				_aMaiorIt = aclone (u_Qry2Array (_sQuery))
				if len (_aMaiorIt) > 0
					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " Update " + RetSQLName ("SZH")
					_oSQL:_sQuery += "    set ZH_RATEIO  = ZH_RATEIO - " + cValToChar (_nFrtAcum - _nTotFret)
					_oSQL:_sQuery += "  where D_E_L_E_T_ = ' '"
					_oSQL:_sQuery += "    and ZH_FILIAL  = '" + xfilial ("SZH")   + "'"
					_oSQL:_sQuery += "    and ZH_NFFRETE = '" + sf1 -> f1_doc     + "'"
					_oSQL:_sQuery += "    and ZH_SERFRET = '" + sf1 -> f1_serie   + "'"
					_oSQL:_sQuery += "    and ZH_FORNECE = '" + sf1 -> f1_fornece + "'"
					_oSQL:_sQuery += "    and ZH_LOJA    = '" + sf1 -> f1_loja    + "'"
					_oSQL:_sQuery += "    and ZH_NFSAIDA = '" + _aMaiorIt [1, 1]  + "'"
					_oSQL:_sQuery += "    and ZH_SERNFS  = '" + _aMaiorIt [1, 2]  + "'"
					_oSQL:_sQuery += "    and ZH_ITNFS   = '" + _aMaiorIt [1, 3]  + "'"
					_oSQL:Exec ()

					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " Update " + RetSQLName ("SD2")
					_oSQL:_sQuery += "    set D2_FRETCIF = D2_FRETCIF - " + cValToChar (_nFrtAcum - _nTotFret)
					_oSQL:_sQuery += "  where D_E_L_E_T_ = ' '"
					_oSQL:_sQuery += "    and D2_FILIAL  = '" + xfilial ("SD2")   + "'"
					_oSQL:_sQuery += "    and D2_DOC     = '" + _aMaiorIt [1, 1]  + "'"
					_oSQL:_sQuery += "    and D2_SERIE   = '" + _aMaiorIt [1, 2]  + "'"
					_oSQL:_sQuery += "    and D2_ITEM    = '" + _aMaiorIt [1, 3]  + "'"
					_oSQL:Exec ()
				endif
			endif
		endif


	elseif _sIncExc == "E"  // Exclusao de nota de conhecimento de frete.

		// Reduz do SD2 o valor do frete CIF e jah deleta a amarracao.
		sd2 -> (dbsetorder (3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		szh -> (dbsetorder (1))  // ZH_FILIAL+ZH_FORNECE+ZH_LOJA+ZH_NFFRETE+ZH_SERFRET
		szh -> (dbseek (xfilial ("SZH") + sf1 -> f1_fornece + sf1 -> f1_loja + sf1 -> f1_doc + sf1 -> f1_serie, .t.))
		do while ! szh -> (eof ()) ;
			.and. szh -> zh_filial  == xfilial ("SZH") ;
			.and. szh -> zh_fornece == sf1 -> f1_fornece ;
			.and. szh -> zh_loja    == sf1 -> f1_loja ;
			.and. szh -> zh_nffrete == sf1 -> f1_doc ;
			.and. szh -> zh_serfret == sf1 -> f1_serie
			
			sd2 -> (dbseek (xfilial ("SD2") + szh -> zh_nfsaida + szh -> zh_sernfs, .T.))
			do while ! sd2 -> (eof ()) .and. sd2 -> d2_filial == xfilial ("SD2") .and. sd2 -> d2_doc == szh -> zh_nfsaida .and. sd2 -> d2_serie == szh -> zh_sernfs
				if sd2 -> d2_item == szh -> zh_itnfs
					reclock ("SD2", .F.)
					sd2 -> d2_fretcif -= szh -> zh_rateio
					msunlock ()
					exit
				endif
				sd2 -> (dbskip ())
			enddo
			
			reclock ("SZH", .F.)
			szh -> (dbdelete ())
			msunlock ()
			szh -> (dbskip ())
		enddo


	elseif _sIncExc == "V"  // Validacao (Tudo OK) da nota de entrada

		if alltrim (GDFieldGet ("D1_COD")) $ GetMv('VA_PRODCIF')  // Item especifico para frete sobre vendas.
			if type ("_oClsFrtFr") != "O"
				msgalert ("Funcao " + procname () + ": Nao foi feita a selecao de frete. Verifique!")
				_lRet = .F.
			endif
		
			if _lRet
	
				// Verifica se o usuario alterou algo depois de informar o frete.
				if _oClsFrtFr:_sFornece != CA100For .or. _oClsFrtFr:_sLoja != cLoja
				   	msgalert('CA100For = ' + Ca100For)
                 	msgalert('CLoja    = ' + cLoja)
                 	msgalert('_oClsFrtFr:_sFornece = ' + _oClsFrtFr:_sFornece)
                 	msgalert('_oClsFrtFr:_sLoja    = ' + _oClsFrtFr:_sLoja)
                 	msgalert ("Dados de frete incompletos, nao informados ou foi feita alguma alteracao na nota. A selecao de frete deve ser refeita.")
					_lRet = .F.
				endif
			endif

			// Verifica valores
			if _lRet
				sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL
				_aDadosZZ1 = {}
				for _nRegZZ1 = 1 to len (_oClsFrtFr:_aRegsZZ1)
					zz1 -> (dbgoto (_oClsFrtFr:_aRegsZZ1 [_nRegZZ1]))
					if sf2 -> (dbseek (xfilial ("SF2") + zz1 -> zz1_docs + zz1 -> zz1_series, .F.))

						aadd (_aDadosZZ1, array (.FreteQtColunas))
						_aDadosZZ1 [len (_aDadosZZ1), .FreteDocS]            = zz1 -> zz1_docs
						_aDadosZZ1 [len (_aDadosZZ1), .FreteSerieS]          = zz1 -> zz1_series
						_aDadosZZ1 [len (_aDadosZZ1), .FreteVlNegociado]     = zz1 -> zz1_vlnego
						_aDadosZZ1 [len (_aDadosZZ1), .FreteUMPeso]          = zz1 -> zz1_UMPeso
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoMinimo]      = zz1 -> zz1_pesmin
						_aDadosZZ1 [len (_aDadosZZ1), .FreteFreteMinimo]     = zz1 -> zz1_frtmin
						_aDadosZZ1 [len (_aDadosZZ1), .FreteFretePeso]       = zz1 -> zz1_peso
						_aDadosZZ1 [len (_aDadosZZ1), .FretePedagio]         = zz1 -> zz1_pedag
						_aDadosZZ1 [len (_aDadosZZ1), .FreteAdValorem]       = zz1 -> zz1_advalo
						_aDadosZZ1 [len (_aDadosZZ1), .FreteDespacho]        = zz1 -> zz1_despac
						_aDadosZZ1 [len (_aDadosZZ1), .FreteCAT]             = zz1 -> zz1_cat
						_aDadosZZ1 [len (_aDadosZZ1), .FreteGRIS]            = zz1 -> zz1_gris
						_aDadosZZ1 [len (_aDadosZZ1), .FreteTransportadora]  = zz1 -> zz1_transp
						_aDadosZZ1 [len (_aDadosZZ1), .FreteCliente]         = sf2 -> f2_cliente
						_aDadosZZ1 [len (_aDadosZZ1), .FreteLoja]            = sf2 -> f2_loja
						_aDadosZZ1 [len (_aDadosZZ1), .FreteTipoNF]          = sf2 -> f2_tipo
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFatura]     = sf2 -> f2_valfat
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoBruto]       = sf2 -> f2_PBruto
						_aDadosZZ1 [len (_aDadosZZ1), .FreteMinimoAdValorem] = zz1 -> zz1_MinAdV
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo1]       = zz1 -> zz1_PFixo1
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo2]       = zz1 -> zz1_PFixo2
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo3]       = zz1 -> zz1_PFixo3
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo4]       = zz1 -> zz1_PFixo4
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo5]       = zz1 -> zz1_PFixo5
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo6]       = zz1 -> zz1_PFixo6
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo7]       = zz1 -> zz1_PFixo7
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo8]       = zz1 -> zz1_PFixo8
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo9]       = zz1 -> zz1_PFixo9
						_aDadosZZ1 [len (_aDadosZZ1), .FretePesoFixo10]      = zz1 -> zz1_PFix10
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo1]      = zz1 -> zz1_VFixo1
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo2]      = zz1 -> zz1_VFixo2
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo3]      = zz1 -> zz1_VFixo3
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo4]      = zz1 -> zz1_VFixo4
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo5]      = zz1 -> zz1_VFixo5
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo6]      = zz1 -> zz1_VFixo6
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo7]      = zz1 -> zz1_VFixo7
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo8]      = zz1 -> zz1_VFixo8
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo9]      = zz1 -> zz1_VFixo9
						_aDadosZZ1 [len (_aDadosZZ1), .FreteValorFixo10]     = zz1 -> zz1_VFix10
						//if sf2 -> f2_tpfrete = "F"
							//_lRet = .F.
							//msgalert ("Conhecimento de Frete associado a uma NF com frete FOB. Tipo de Frete nao permitido! ")
						//endif	
					endif
				next
				if _lRet
					for _n = 1 to len (aCols)
						N := _n
						if !GDDeleted ()
							_nTotSD1 += GDFieldGet ("D1_TOTAL")
						endif
					next
					_lRet = U_FrtCalc (_aDadosZZ1, .F., .T., _nTotSD1)
				endif	
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
//	u_logFim ()
return _lRet