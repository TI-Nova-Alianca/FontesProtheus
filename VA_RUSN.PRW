// Programa...: VA_RUSN
// Autor......: Robert Koch
// Data.......: 18/01/2010
// Descricao..: Gera contranota de entrada ref. recebimento de uva durante a safra (uso na balanca).
//
// Historico de alteracoes:
// 10/02/2010 - Robert - Nao permite gerar nota em ambiente 'contingencia'
// 15/02/2010 - Robert - Grava campo ze_obs nos dados adicionais da nota.
// 11/01/2011 - Robert - Tratamento para o campo ZE_CADVITI.
// 30/01/2011 - Robert - Backup de campos de filtragem do MBrowse antes de entrar na tela do SPED.
// 21/02/2011 - Robert - Criado tratamento para quando der erro em rotina automatica, mas nao houver arquivo de log gerado.
// 23/01/2012 - Robert - Busca nao conformidades e cargas aglutinadas para os dados adicionais da nota.
// 18/01/2013 - Elaine - Busca classificacao do grau da uva pela funcao VA_CLAUF
// 31/01/2013 - Robert - Puxa clas.uva fina para a descricao somente se tiver todas as classificacoes informadas.
// 04/02/2015 - Robert - Tratamento para desconsiderar classificacao uva fina quando producao propria.
// 12/02/2015 - Robert - Matodo ConsChv() trocado por ConsAutori() na consulta de autorizacao do SPED.
// 28/10/2015 - Robert - Gravacao de dados adicionais no ZZ4 passa a ser feita apenas em campo memo do SF1.
// 04/01/2016 - Robert - Tratamento para parametro VA_SERSAFR.
// 18/02/2016 - Robert - Restaura parametros da rotina MATA103 apos sua execucao.
// 18/01/2017 - Robert - Valida campo ZZC_OK.
// 07/03/2017 - Catia  - Setar o parametro de amarração com fornecedores sempre como NAO
// 04/01/2017 - Robert - Gravacao do campo F1_VASAFRA (criado por que comecamos a safra 2018 ainda dentro no ano de 2017).
// 18/01/2018 - Robert - Passa a bloquear acesso via funcao SoftLock() e nao mais Semaforo().
// 08/01/2019 - Robert - Ajustes na geracao do D1_LOTECTL para tratar nao conformidades.
// 28/01/2019 - Robert - Liberado gerar contranota para fornecedor 012373.
// 05/02/2019 - Robert - Ajustes para receber uva de associados da Coop.Garibaldi.
// 08/04/2019 - Catia  - include TbiConn.ch 
// 13/12/2019 - Robert - Inicio ajustes para safra 2020 (d1_lotefor).
// 03/01/2020 - Robert - Gravacao campo F1_VAFLAG.
// 15/01/2020 - Robert - Gravacao campo ZF_VALFRET.
// 23/01/2020 - Robert - Tratamento para fornecedores nao associados: 012373, 012791, 012792.
// 04/02/2020 - Robert - Ajustada chamada funcao calculo preco quando mais de uma variedade na nota.
// 10/02/2020 - Robert - Desabilitada altercao de parametros para 'contabiliza online=nao'.
// 20/02/2020 - Robert - Desabilitada gravacao do ZF_IDSZ9 no D1_LOTEFOR (cadastros estao desatualizados, nao ajuda em nada. Vai ser passado para NaWeb)
// 01/07/2020 - Robert - Calculo de frete passa a ser em funcao separada, para facilitar posteriores recalculos.
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "rwmake.ch"  // Deixar este include para aparecerem os botoes da tela de acompanhamento do SPED

// --------------------------------------------------------------------------
User Function va_rusN ()
	local _lContinua := .T.
	local _sTES      := ""
	local _sNF       := ""
	local _nTamDesc  := tamsx3 ("D1_DESCRI")[1]
//	local _nTamItem  := tamsx3 ("D1_ITEM")[1]
	local _sMsgContr := ""
//	local _nVlIni    := 0
	local _nVlTot    := 0
	local _sDescri   := ""
	local _nTaraItem := 0
	local _aAutoSD1  := {}
	local _aAutoSF1  := {}
	local _aLinha    := {}
//	local _bFilBrw   := NIL
//	local _aFilBrw   := NIL
	local _sVitic    := ""
	local _sNaoConf  := ""
	local _nNaoConf  := 0
	local _sAlmox    := ""
//	local _sUvaF     := ""
//	local _nLock     := 0
	local _oSQL      := NIL
	local _sDescNC   := ""
	local _sAglutin  := ""
	local _sClasFina := ''
//	local _cPerg     := ''
//	local _aBkpSX1   := ""
	local _nVlUni    := 0
	local _sLoteCtl  := ""
	local _sMenorVlr := ''
	local _aProdut   := {}
	local _nProdut   := 0
	local _aAux      := {}
//	local _sVarReal  := ''
	//local _sPNaoPrev := ''
	local _aPrevia   := {}
	local _aCols     := {}
	local _nVlFrete  := 0
//	local _nFrtItem  := 0
//	local _sLinkSrv  := ''
	private _oAssoc  := NIL

	u_logIni ()
	
	CursorWait ()

	// Nao permite duas sessoes alterando a mesma carga. Usa a funcao SoftLock para que mostre a mensagem 'registro em uso por fulano'
	if _lContinua
		softlock ("SZE")
	endif

	U_HELP ('EM 2020 nao gravou os campos D1_PRM02 ...99 nem D1_VACLABD. Poderia ser algum gatilho?',, .t.)
	u_help ("Testar a parte de calculo e gravacao de frete, pois foi implementada em 01/07/2020 (depois da safra) e nao foi testada. Ver tb se vai levar a soma para o SF1",, .t.)

	// Testa se jah tem contranota somente depois do softlock para pegar casos em que dois usuarios tentam gerar
	// contranota da mesma carga e o segundo fica aguardando a liberacao do softlock. Quando o primeiro liberar,
	// o segundo vai prosseguir o processo e tentar gerar contranota dessa mesma carga.
	if _lContinua .and. ! empty (sze -> ze_nfger)
		u_help ("Contranota ja foi gerada com o numero " + sze -> ze_nfger)
		_lContinua = .F.
	endif

	if _lContinua .and. sze -> ze_status == "C"
		u_help ("Carga cancelada.")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_status == "D"
		u_help ("Carga redirecionada.")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_status == "1" .and. sze -> ze_aglutin != 'D'
		u_help ("Falta segunda pesagem")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_aglutin == "O"
		u_help ("Carga aglutinada em outra. Geracao de contranota nao sera´ permitida.")
		_lContinua = .F.
	endif
	
	if _lContinua .and. sze -> ze_coop != '000021' .and. !(sze -> ze_coop = '000026' .and. sze -> ze_safra == '2019')
		u_help ("Contranota pode ser gerada apenas para nossos associados ou associados de outras cooperativas.")
		_lContinua = .F.
	endif

	// Deve ser producao propria, associado ou ex-associado (pode ter entregue alguma carga e solicitado desligamento).
	if _lContinua
		if sze -> ze_assoc == '001369' .and. sze -> ze_lojasso == '01'
			//u_log ('eh prod.propria livramento.')
		elseif sze -> ze_assoc == '012373' .and. sze -> ze_lojasso == '01' .and. sze -> ze_safra $ '2019/2020'
			u_log ('Trata-se do Vinhedos da Quinta (negociacao especifica em 2019 E 2020).')
		elseif sze -> ze_assoc $ '012791/012792' .and. sze -> ze_safra $ '2020'
			u_log ('Trata-se de LUIZ PEDRO DUARTE ESCOSTEGUY ou SINVAL CONSTANCIO DE ALMEIDA FERNANDES (negociacao especifica Livramento em 2020).')
		elseif sze -> ze_coop == '000026' .and. sze -> ze_lojasso == '01' .and. sze -> ze_safra == '2019'
			u_log ('Trata-se de recebimento de uva de associados da Garibaldi (negociacao especifica em 2019).')
		else
			_oAssoc := ClsAssoc():New (sze -> ze_assoc, sze -> ze_lojasso)
			if valtype (_oAssoc) != "O" .or. (!_oAssoc:EhSocio (dDataBase) .and. empty (_oAssoc:DtSaida (dDataBase)))  
				u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' nao e' associado e nem ex-associado.")
				_lContinua = .F.
			endif
		endif
	endif
	if _lContinua
		sa2 -> (dbsetorder (1))
		if ! sa2 -> (dbseek (xfilial ("SA2") + sze -> ze_assoc + sze -> ze_lojasso, .F.))
			u_help ("Cadastro do fornecedor '" + sze -> ze_assoc + '/' + sze -> ze_lojasso + "' nao encontrado!")
			_lContinua = .F.
		endif
	endif
	if _lContinua .and. (empty (sa2 -> a2_inscr) .or. alltrim (upper (sa2 -> a2_inscr)) == 'ISENTO')
		u_help ("Fornecedor / associado '" + sa2 -> a2_cod + '/' + sa2 -> a2_loja + "' deve ter inscricao estadual.")
		_lContinua = .F.
	endif

	// Definicao do TES a ser usado.
	if _lContinua .and. ! GetMv("ML_TESCSAF", .T.)
		u_help ("Parametro ML_TESCSAF vazio ou inexistente",, .t.)
		_lContinua = .F.
	endif
	if _lContinua
		_sTES = left (GetMv("ML_TESSAFR"), 3)
		if sze -> ze_coop == '000026' .and. sze -> ze_safra == '2019'
			_sTES = '024'
		elseif sze -> ze_assoc + sze -> ze_lojasso == '01237301'  // Vinhedos da Quinta a partir de 2020: manda a nota como 'venda'.
			_sTES = '192'
		elseif sze -> ze_assoc + sze -> ze_lojasso == '01279101'  // Nao associado que manda como 'remessa para deposito'.
			_sTES = '028'
		elseif sze -> ze_assoc + sze -> ze_lojasso == '01279201'  // Sinval: nao associado que manda como 'remessa para deposito'.
			_sTES = '028'
		endif
	endif
	u_log ('_sTES:', _sTES)
	if _lContinua .and. empty (sze -> ze_placa)
		u_help ("Placa do veiculo nao informada.")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_pesotar == 0
		u_help ("Peso tara nao informado.")
		_lContinua = .F.
	endif
	if _lContinua
		_oAssoc := ClsAssoc():New (sze -> ze_assoc, sze -> ze_lojasso)
		if valtype (_oAssoc) != "O"
			_lContinua = .F.
		endif
		if _lContinua .and. ! empty (_oAssoc:DtFalecim)
			u_help ("Associado consta como falecido em " + dtoc (_oAssoc:DtFalecim))
			_lContinua = .F.
		endif
	endif


	// Atualiza sistema de agendamento/inspecao com status de 'CON' (concluida). Mais para garantir em algum caso que o inspetor de tombadores tenha deixado passar.
	U_VA_RusAI ('INS/AGE/LIB', 'CON')


	// A partir de 2016 teremos uma serie especifica para NF de safra.
	// Fica fixo no programa para nem precisar abrir tela para o usuario.
	if _lContinua
		_sSerie = GetMv ("VA_SERSAFR", .F., '')
		if empty (_sSerie)
			u_help ("Serie a ser usada nas NF de safra nao definida. Verifique se o parametro VA_SERSAFR existe e se contem uma serie de NF valida para esta filial.")
			_lContinua = .F.
		endif
	endif


	// Verifica almoxarifado onde deve ser dada entrada da uva.
	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZX5_09ALM"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZX5") + " ZX5 "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5_TABELA = '09'"
		_oSQL:_sQuery +=    " AND ZX5_09SAFR = '" + sze -> ze_safra + "'"
		_oSQL:_sQuery +=    " AND ZX5_09LOCA = '" + sze -> ze_local + "'"
		_sAlmox = _oSQL:RetQry ()
		if ! empty (_sAlmox)
			sx5 -> (dbsetorder (1))
			if ! sx5 -> (dbseek (xfilial ("SX5") + "AL" + _sAlmox, .F.))
				u_help ("Almoxarifado '" + _sAlmox + "' nao cadastrado neste filial para entrada da uva. Verifique cadastro da balanca '" + sze -> ze_local + "'.")
				_lContinua = .F.
			endif
		endif
	endif


	// Se existe mistura de variedades, precifica pela de menor valor.
	// Para isso, varre os itens, monta uma lista de codigos distintos e busca o preco de cada um
	// considerando um grau medio e classificacoes medias. Neste momento nao interessa a classificacao
	// por que quero saber apenas qual a de menor valor comercial.
	if _lContinua
		u_logIni ('Verificacao de misturas')
		_aProdut = {}
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
		do while _lContinua ;
			.and. ! szf -> (eof ()) ;
			.and. szf -> zf_filial == xfilial ("SZF") ;
			.and. szf -> zf_safra  == sze -> ze_safra ;
			.and. szf -> zf_carga  == sze -> ze_carga

			if ascan (_aProdut, {|_aVal| _aVal [1] == szf -> zf_produto}) == 0
				aadd (_aProdut, {szf -> zf_produto, 0, szf -> zf_conduc})
			endif
			szf -> (dbskip ())
		enddo
		
		// Se tem apenas um produto, nem perde tempo buscando precos.
		if len (_aProdut) > 1
			for _nProdut = 1 to len (_aProdut)
				if sze -> ze_safra == '2019'
					_aProdut [_nProdut, 2] = U_PrcUva19 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3])[1]
				elseif sze -> ze_safra == '2020'
					_aProdut [_nProdut, 2] = U_PrcUva20 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F.)[5]  // pos.5=preco MOC
				else
					u_help ("Sem tratamento de precificacao para mistura de variedades nesta safra.",, .t.)
					_lContinua = .F.
					exit
				endif
			next
			_aProdut = asort (_aProdut,,, {|_x, _y| _x[2] < _y [2]})
			u_log ('_aProdut:', _aProdut)
			
			// Elimina produtos com precos iguais.
			_aAux = {}
			for _nProdut = 1 to len (_aProdut)
				if ascan (_aAux, {|_aVal| _aVal [2] = _aProdut [_nProdut, 2]}) == 0
					aadd (_aAux, aclone (_aProdut [_nProdut]))
				endif
			next
			_aProdut = aclone (_aAux)
			u_log ('_aProdut eliminadas duplicidades:', _aProdut)
			if len (_aProdut) > 1  // Se ainda sobrou mais de um produto com diferentes precos
				_sMenorVlr = _aProdut [1, 1]
				u_log ('produto de menor valor:', _sMenorVlr)
			endif
		endif
		u_logFim ('Verificacao de misturas')
	endif


	// Calcula valor do frete a ser incluido na nota. Roda em funcao separada por que eh comum precisar recalcular depois.
	if _lContinua
		_nVlFrete = 0
		U_VA_RUSCF (.T.)
	endif

	if _lContinua
		_sVitic   = ""
		_sNaoConf = ""

		// Prepara itens da nota
		sb1 -> (dbsetorder (1))
		_aAutoSD1 = {}
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
		do while _lContinua ;
			.and. ! szf -> (eof ()) ;
			.and. szf -> zf_filial == xfilial ("SZF") ;
			.and. szf -> zf_safra  == sze -> ze_safra ;
			.and. szf -> zf_carga  == sze -> ze_carga

			if empty (szf -> zf_cadviti)
				u_help ("Cadastro viticola nao informado no item " + szf -> zf_item)
				_lContinua = .F.
				exit
			else
				sz2 -> (dbsetorder (1))  // Z2_FILIAL+Z2_CADVITI
				if ! sz2 -> (dbseek (xfilial ("SZ2") + szf -> zf_cadviti, .F.))
					u_help ("Cadastro viticola '" + szf -> zf_cadviti + "' nao encontrado na tabela de cadastros viticolas.")
					_lContinua = .F.
					exit
				else
					if sz2 -> z2_safrvit != sze -> ze_safra
						u_help ("Cadastro viticola '" + szf -> zf_cadviti + "' consta como renovado para a safra " + sz2 -> z2_safrvit)
						_lContinua = .F.
						exit
					else
						zzc -> (dbsetorder (1))  // ZZC_FILIAL+ZZC_CADVIT + ZZC_PRODUT
						if ! zzc -> (dbseek (xfilial ("ZZC") + szf -> zf_cadviti + szf -> zf_produto, .F.))
							u_help ("Produto '" + szf -> zf_produto + "' nao encontrado no cadastro viticola '" + szf -> zf_cadviti + "'.")
							_lContinua = .F.
							exit
						else
							if zzc -> zzc_ok != 'S'
								u_help ("Produto '" + szf -> zf_produto + "' nao consta como 'conferido' no cadastro viticola '" + szf -> zf_cadviti + "'. Emissao de contranota nao permitida.")
								_lContinua = .F.
								exit
							endif
						endif
					endif 
				endif
			endif

			if ! sb1 -> (dbseek (xfilial ("SB1") + szf -> zf_produto, .F.))
				u_help ("Produto nao cadastrado: " + szf -> zf_produto)
				_lContinua = .F.
				exit
			endif

			// Verifica classificacao uvas viniferas
			if sb1 -> b1_varuva == 'F'
				if empty (szf -> zf_prm99) .and. empty (szf -> zf_clasABD) 
					u_help ("Produto '" + szf -> zf_produto + "' deve ter classificacao (trata-se de uva vinifera)")
					_lContinua = .F.
					exit
				endif
			endif

			// Em 2019 passamos a guardar a forma de conducao da uva junto com a carga
			if szf -> zf_conduc == 'L'
				_sClasFina = szf -> zf_clasABD
			elseif szf -> zf_conduc == 'E'
				_sClasFina = szf -> zf_prm99
			endif

			//u_log ("Usando classificacao '" + _sClasFina + "' para buscar preco uva fina '" + sb1 -> b1_cod + "'.") 

			// Busca preco unitario.
			if szf -> zf_safra == '2019'
				_nVlUni = U_PrcUva19 (szf -> zf_filial, iif (! empty (_sMenorVlr), _sMenorVlr, szf -> zf_produto), val (szf -> zf_grau), _sClasFina, szf -> zf_conduc)[1]
			elseif szf -> zf_safra == '2020'
				_nVlUni = U_PrcUva20 (szf -> zf_filial, iif (! empty (_sMenorVlr), _sMenorVlr, szf -> zf_produto), val (szf -> zf_grau), _sClasFina, szf -> zf_conduc, .F.)[5]  // pos.5=preco MOC
			else
				u_help ("Sem tratamento para leitura de precos para esta safra.")
				_lContinua = .F.
				exit
			endif

			u_log ('Retornou preco =', _nVlUni)
			
			// Especificamente esse fornecedor mandou como 'venda' e preciso emitir a contranota com valor identico
			if _sTES == '192'
				if sze -> ze_assoc + sze -> ze_lojasso == '01237301'  // Vinhedos da Quinta a partir de 2020: manda a nota como 'venda'.
					do while .T.
						_nVlUni = U_Get ('Caso especifico de COMPRA: informe valor unitario', 'N', 7, '@E 9.9999', '', 0, .f., '.t.')
						if (_nVlUni == NIL .or. _nVlUni == 0)
							if U_MsgYesNo ("Valor unitario precisa ser informado. Cancelar a operacao?")
								_nVlUni = 0
								_lContinua = .F.
								exit
							else
								loop
							endif
						else
							exit
						endif
					enddo
				else
					u_help ("Sem tratamento para preco unitario quanto TES de compra para o fornecedor atual.",, .t.)
					_lContinua = .F.
					exit
				endif
			endif

			if _nVlUni <= 0
				u_help ("Variedade / grau '" + alltrim (szf -> zf_produto) + "/" + szf -> zf_grau + "' sem preco definido.")
				_lContinua = .F.
				exit
			endif

			// Arredonda valor total p/ 2 casas p/ compatibilizar com SFT, SF3, SE2, contabilizacao, SPED, etc...
			_nVlTot = round (szf -> zf_peso * _nVlUni, 2)

			// Monta descricao com grau e classificacao da uva. Inicia com o grau e
			// classificacao, reduzindo o nome da uva caso necessario.
			_sDescri = " Gr:" + alltrim (szf -> zf_grau)

			// Todas as classificacoes devem estar informadas.
			if ! empty (szf -> zf_prm02) .and. ! empty (szf -> zf_prm03) .and. ! empty (szf -> zf_prm04) .and. ! empty (szf -> zf_prm05) .and. ! empty (szf -> zf_prm99)
				_sDescri += " Clas.:" + alltrim (szf -> zf_prm99)
			endif
			// Classificacao A/B/D criada em 2014.
			if ! empty (szf -> zf_clasabd)
				_sDescri += " Cl.:" + alltrim (szf -> zf_clasabd)
			endif
			_sDescri = left (alltrim (sb1 -> b1_desc), _nTamDesc - len (_sDescri)) + _sDescri

			// Pode haver mais de um cadastro viticola, por isso alimenta item a item.
			if ! alltrim (szf -> zf_cadviti) $ _sVitic
				_sVitic += iif (empty (_sVitic), '', ',') + alltrim (szf -> zf_cadviti)
			endif

//			// Calcula valor do frete a ser incluido na nota. Precisa ser nos itens por que pode haver mais de um cadastro viticola.
//			if sze -> ze_safra >= '2020' .and. valtype (_oAssoc) == "O"
//				if ! sze -> ze_assoc $ '001369/003114/012373'  // Producao propria / Vinhedos da Quinta (3os)
//					_nFrtItem = U_FrtSaf20 (_oAssoc:Nucleo, szf -> zf_cadviti, sze -> ze_filial, szf -> zf_peso, sb1 -> b1_vacor)
//					// aval do fiscal em 10/01 por telefone --> _nVlFrete = 0  // ainda nao tenho aval do setor fiscal -> precisaria destacar ICMS !!!
//					if _nFrtItem > 0
//						reclock ("SZF", .F.)
//						szf -> zf_valfret = _nFrtItem
//						msunlock ()
//					endif
//					_nVlFrete += _nFrtItem
//				endif
//			elseif sze -> ze_safra > '2020'
//				u_help ("Sem tratamento de calculo de frete para esta safra",, .T.)
//			endif
			
			// Acumula frete previamente calculado nos itens.
			_nVlFrete += szf -> zf_valfret

			// Lista cada nao conformidade uma unica vez, independente de quantos itens a tenham
			for _nNaoConf = 1 to 4  // Aumentar aqui se forem criados novos campos.
				_sDescNC = alltrim (U_RetZX5 ('11', sze -> ze_safra + szf -> &('zf_nconf' + strzero (_nNaoConf, 2)), 'ZX5_11DESC'))
				if ! empty (_sDescNC)
					u_log ('nao conf', _nnaoconf, ':', szf -> &('zf_nconf' + strzero (_nNaoConf, 2)), _sDescNC)
					if ! _sDescNC $ _sNaoConf
						_sNaoConf += iif (empty (_sNaoConf), '', ',') + _sDescNC
						u_log ('Acrescentei em _sNaoConf e ficou assim:', _sNaoConf)
					endif
				endif
			next

			// Define lote a ser gerado. Se tiver nao conformidades, acrescenta 'NC' ao mesmo.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			if sze -> ze_segreg == 'S'  // Carga segregada: deve gerar lote nao conforme
				_sLoteCtl = right (sze -> ze_safra, 2) + szf -> zf_filial + szf -> zf_carga + 'NC'
			else
				_sLoteCtl = right (sze -> ze_safra, 2) + szf -> zf_filial + szf -> zf_carga + szf -> zf_item
			endif

			// Calcula peso bruto e tara para cada item da nota por regra de 3.
			// A geracao do XML para a NFe depende desses campos, mas creio que na versao 10 jah devem
			// existir campos padrao no SF1 e nao precisaremos mais ficar gravando no SD1.
			_nTaraItem = (szf -> zf_peso * sze -> ze_pesotar) / (sze -> ze_pesobru - sze -> ze_pesotar)

			_aLinha = {}
			AADD(_aLinha , {"D1_COD"     , szf -> zf_produto    , Nil } )
			AADD(_aLinha , {"D1_UM"      , sb1 -> B1_UM         , Nil } )
			AADD(_aLinha , {"D1_TP"      , sb1 -> B1_TIPO       , Nil } )
			AADD(_aLinha , {"D1_LOCAL"   , iif (empty (_sAlmox), sb1 -> B1_LOCPAD, _sAlmox), Nil } )
			AADD(_aLinha , {"D1_GRAU"    , szf -> zf_grau       , Nil } )
			AADD(_aLinha , {"D1_PRM02"   , szf -> zf_prm02      , Nil } )
			AADD(_aLinha , {"D1_PRM03"   , szf -> zf_prm03      , Nil } )
			AADD(_aLinha , {"D1_PRM04"   , szf -> zf_prm04      , Nil } )
			AADD(_aLinha , {"D1_PRM05"   , szf -> zf_prm05      , Nil } )
			AADD(_aLinha , {"D1_PRM99"   , szf -> zf_prm99      , Nil } )
			AADD(_aLinha , {"D1_VACLABD" , szf -> zf_clasabd    , Nil } )
			AADD(_aLinha , {"D1_QUANT"   , szf -> zf_peso       , Nil } )
			AADD(_aLinha , {"D1_VUNIT"   , _nVlUni              , Nil } )
			AADD(_aLinha , {"D1_TOTAL"   , _nVlTot              , Nil } )
			AADD(_aLinha , {"D1_TES"     , _sTES                , Nil } )
			AADD(_aLinha , {"D1_DESCRI"  , _sDescri             , Nil } )
			AADD(_aLinha , {"D1_VAVOLES" , szf -> zf_embalag    , Nil } )
			AADD(_aLinha , {"D1_VAVOLQT" , szf -> zf_qtembal    , Nil } )
			AADD(_aLinha , {"D1_PESBRT"  , _nTaraItem + szf -> zf_peso, Nil } )
			AADD(_aLinha , {"D1_TARA"    , _nTaraItem           , Nil } )
			AADD(_aLinha , {"D1_VAVITIC" , szf -> zf_cadviti    , Nil } )
			if sb1 -> b1_localiz == 'S'
				AADD(_aLinha , {"D1_LOTECTL", _sLoteCtl, Nil } )
	//			AADD(_aLinha , {"D1_LOTEFOR", szf -> zf_idZA8 + szf -> zf_idSZ9, Nil } )
				AADD(_aLinha , {"D1_LOTEFOR", szf -> zf_idZA8, Nil } )
			endif
			u_log (_aLinha)
			AADD(_aAutoSD1, aClone (U_OrdAuto (_aLinha)))

			// Atualiza array de previsao de nota
			aadd (_aPrevia, {szf -> zf_produto, _sDescri, szf -> zf_peso, sb1 -> b1_um, szf -> zf_grau, iif (! empty (szf -> zf_prm99), szf -> zf_prm99, szf -> zf_clasABD), _nVlUni})

			szf -> (dbskip ())
		enddo
	endif

	// Prepara dados adicionais
	if _lContinua
		_sMsgContr = ""
//		if ! empty (_sPNaoPrev)
//			_sMsgContr += "Varied.nao prevista no cad.vitic: '" + alltrim (_sPNaoPrev) + "';"
//		endif
		if ! empty (_sMenorVlr)
			_sMsgContr += "Mist.varied:precificando por '" + alltrim (_sMenorVlr) + "';"
		endif
		// Jah gera no SF1100I --> _sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Pl.veic:" + alltrim (sze -> ze_placa)
		// Jah busca no NfeSefaz  ---> _sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Ref.NF produtor:" + alltrim (sze -> ze_snfprod) + "/" + alltrim (sze -> ze_nfprod)
		_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Peso tara:" + cvaltochar (sze -> ze_pesotar) + 'Kg'
		_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Cad.vitic:" + _sVitic
		if ! empty (_sNaoConf)
			_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "N.conform:" + _sNaoConf
		endif
		if ! empty (sze -> ze_obs)
			_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Obs:" + alltrim (sze -> ze_obs)
		endif

		// Verifica se ha cargas aglutinadas
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT ZZD_CARORI"
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZZD") + " ZZD "
		_oSQL:_sQuery += " WHERE ZZD.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZZD.ZZD_FILIAL = '" + xfilial ("ZZD") + "'"
		_oSQL:_sQuery +=   " AND ZZD.ZZD_SAFRA  = '" + sze->ze_safra + "'"
		_oSQL:_sQuery +=   " AND ZZD.ZZD_CARDES = '" + sze->ze_carga + "'"
		_sAglutin = _oSQL:Qry2Str (1, ',')
		if ! empty (_sAglutin)
			_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Cargas:" + _sAglutin
		endif
	endif
	
	// Mostra tela com valores previstos, para que a filial de Livramento possa saber qual valor vai ficar
	// e, assim, emitir a NF-e de produtos já com o valor igual.
	if _lContinua .and. .F.  // No final nem precisou, pois conseguimos emitir sem preço no site da SEFAZ
		if sze -> ze_filial == '03' .and. sze -> ze_assoc == '001369'  // Soh mostra quando producao propria

			// Monta colunas para mostrar na tela.
			_aCols = {}
			aadd (_aCols, {1,  'Variedade',  45, ''})
			aadd (_aCols, {2,  'Descricao', 100, ''})
			aadd (_aCols, {3,  'Peso',       30, '@E 999,999.99'})
			aadd (_aCols, {4,  'UM',         20, ''})
			aadd (_aCols, {5,  'Grau',       30, ''})
			aadd (_aCols, {6,  'Classif',    20, ''})
			aadd (_aCols, {7,  'Vlr.unit.',  45, '@E 999.9999'})
			u_F3Array (_aPrevia, "Previa NF", _aCols,,, "Previa NF", "", .T., 'C', TFont():New ("Courier New", 6, 14))
		endif
	endif

	if _lContinua
		if empty (sze -> ze_nfprod) .or. empty (sze -> ze_snfprod)
			u_help ("NF/serie de produtor deve ser informada para gerar a contranota.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Apresenta Tela para Confirmar o Numero da Primeira NF a Ser Gerada
		_lContinua = Sx5NumNota (@_sSerie)
		if _lContinua
			u_log ('confirmou proxima nota para a serie', @_sSerie)
		else
			u_log ('Nao confirmou proxima nota')
		endif
	endif
	
	// Gera a NF
	if _lContinua

		// Busca a Proxima NF da serie informada.
		_sNF = NxtSX5Nota (_sSerie)
		u_log ('_sNF:', _sNF)

		// Prepara campos do cabecalho da nota
		_aAutoSF1 := {}
		AADD( _aAutoSF1, { "F1_DOC"      , _sNF,            Nil})
		AADD( _aAutoSF1, { "F1_SERIE"    , _sSerie,         Nil})
		AADD( _aAutoSF1, { "F1_TIPO"     , "N",             Nil})
		AADD( _aAutoSF1, { "F1_FORMUL"   , "S",             Nil})
		AADD( _aAutoSF1, { "F1_EMISSAO"  , dDataBase,       Nil})
		AADD( _aAutoSF1, { "F1_FORNECE"  , sa2 -> a2_cod,   Nil})
		AADD( _aAutoSF1, { "F1_LOJA"     , sa2 -> a2_loja,  Nil})
		AADD( _aAutoSF1, { "F1_EST"      , sa2 -> a2_est,   Nil})
		AADD( _aAutoSF1, { "F1_ESPECIE"  , "SPED",          Nil})
		AADD( _aAutoSF1, { "F1_COND"     , "019",           Nil})  // 90 dias, para os raros e problematicos casos de usar um TES de compra.
		AADD( _aAutoSF1, { "F1_VANFPRO"  , sze->ze_NFProd,  Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASEPRO"  , sze->ze_SNFProd, Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VAPLVEI"  , sze->ze_Placa,   Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASAFRA"  , sze->ze_safra,   Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_FRETE"    , _nVlFrete,       Nil})
		AADD( _aAutoSF1, { "F1_VAFLAG"   , 'G',             Nil})  // 'Gerada' (Campo customizado, serah tratado pelo P.E. SF1100I)

		// Ordena campos cfe. SX3.
		_aAutoSF1 = aClone (U_OrdAuto (_aAutoSF1))
		//u_log (_aAutoSF1)

		// Altera parametro "Contabiliza on-line" para "Nao" na tela de NF de entrada
//		_cPerg = 'MTA103'
		// estou setando este parametro antes do backup pq esse nao eh pra voltar mesmo, é pra ficar sempre NAO
	//	U_GravaSX1 (_cPerg, "05", 2)
//		_aBkpSX1 = U_SalvaSX1 (_cPerg)
//		U_GravaSX1 (_cPerg, "06", 2)

		lMsHelpAuto := .F.  // se .t. direciona as mensagens de help
		lMsErroAuto := .F.  // necessario a criacao
		DbSelectArea ("SF1")
		//u_log ('chamando MATA103')

		CursorWait ()
		begin transaction
		MsExecAuto({|x,y,z|MATA103(x,y,z)},_aAutoSF1,_aAutoSD1,3)

		// Volta parametros da rotina de notas de entrada.
//		U_SalvaSX1 (_cPerg, _aBkpSX1)

		If lMsErroAuto
			DisarmTransaction()
			u_log ('lMsErroAuto')
			if ! empty (NomeAutoLog ())
				u_log (memoread (NomeAutoLog ()))
				MostraErro()
			else
				u_help ("Nao foi possivel ler o arquivo de log de erros.")
			endif
		else
			u_log ('carga', sze -> ze_carga, '  NF gerada:', sf1 -> f1_doc)

			// Grava dados adicionais na nota.
			if ! empty (_sMsgContr)
				if empty (sf1 -> f1_vacmemc)
					msmm(,,,_sMsgContr,1,,,"SF1","F1_VACMEMC")
				else
					_sMemoAnt = alltrim (MSMM (sf1->f1_vacmemc,,,,3))
					msmm (sf1 -> f1_vacmemc,,, _sMemoAnt + '; ' + _sMsgContr, 1,,,"SF1","F1_VACMEMC")
				endif
			endif
	
			// Grava no SZE o numero da nota gerada, para evitar geracao em duplicidade.
			reclock ("SZE", .F.)
			sze -> ze_nfger  = sf1 -> f1_doc
			sze -> ze_serie  = sf1 -> f1_serie
			sze -> ze_status = "N"
			msunlock ()
		endif
		end transaction
		CursorArrow ()

		// Faz a transmissao da NF para a SEFAZ
		if ! empty (sze -> ze_nfger)
			//U_SpedAut ('E', sf1 -> f1_serie, sf1 -> f1_doc, sf1 -> f1_doc)
			//dbselectarea ("SZE")
			U_VA_RUSTX ()
		endif
	endif

	CursorArrow ()
	u_logFim ()
return
