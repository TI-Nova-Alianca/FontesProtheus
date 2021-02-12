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
// 07/03/2017 - Catia  - Setar o parametro de amarracao com fornecedores sempre como NAO
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
// 04/01/2021 - Robert - Ajustes diversos safra 2021
// 11/01/2021 - Robert - Ajustes diversos safra 2021
// 15/01/2021 - Robert - Novo parametro metodo :RetFixo da classe ClsSQL().
//                     - Definido TES (028) e preco unitario (1,00) para producao propria Livramento.
// 19/01/2021 - Robert - Producao propria Livramento passa a entrar com mesmo preco de associados (entrava a 1,00)
// 02/02/2021 - Robert - Chamada do VA_RusEn no final para enderecar uva no estoque (GLPI 8779).
// 09/02/2021 - Robert - Finaliza a thread (paliativo) se estiver usando muita memoria (GLPI 9376).
// 10/02/2021 - Robert - Limite memoria (finaliza rotina) aumentado de 250 p/ 300 Mb (GLPI 9376).
//                     - Inseridas chamadas da funcao FreeObj() em alguns casos (GLPI 9376).
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "rwmake.ch"  // Deixar este include para aparecerem os botoes da tela de acompanhamento do SPED
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function va_rusN ()
	local _lContinua := .T.
	local _sTES      := ""
	local _sNF       := ""
	local _nTamDesc  := tamsx3 ("D1_DESCRI")[1]
	local _sMsgContr := ""
	local _nVlTot    := 0
	local _sDescri   := ""
	local _nTaraItem := 0
	local _aAutoSD1  := {}
	local _aAutoSF1  := {}
	local _aLinha    := {}
	local _sVitic    := ""
	local _sSivibe   := ""
	local _sNaoConf  := ""
	local _nNaoConf  := 0
	local _sAlmox    := ""
	local _oSQL      := NIL
	local _sDescNC   := ""
	local _sAglutin  := ""
	local _sClasFina := ''
	local _nVlUni    := 0
	local _sLoteCtl  := ""
	local _sMenorVlr := ''
//	local _aProdut   := {}
//	local _nProdut   := 0
//	local _aAux      := {}
	local _aPrevia   := {}
	local _aCols     := {}
	local _nVlFrete  := 0
	local _nVlrUvas  := 0
	local _aTpForUva := {}
	local _sTpForUva := ""
	local _nVitic    := 0
	local _sGrpPgSaf := ''
	local _sCondPg   := ''
//	private _oAssoc  := NIL
	local _oAssocN   := NIL
	local _nRetMem   := 0
	private _aParPgSaf := {}  // Parcelas pre calculadas. Deixar PRIVATE para ser lida pelo ponto de entrada MTCOLSE2().

	u_Log2 ('info', 'Iniciando ' + procname ())
	
	// Nao permite duas sessoes alterando a mesma carga. Usa a funcao SoftLock para que mostre a mensagem 'registro em uso por fulano'
	if _lContinua
		softlock ("SZE")
	endif

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
		u_help ("Carga aglutinada em outra. Geracao de contranota nao sera� permitida.")
		_lContinua = .F.
	endif
	
	if _lContinua .and. sze -> ze_coop != '000021' .and. !(sze -> ze_coop = '000026' .and. sze -> ze_safra == '2019')
		u_help ("Contranota pode ser gerada apenas para nossos associados ou associados de outras cooperativas.")
		_lContinua = .F.
	endif

	// Verifica qual o tipo de fornecedor de uva (associado / nao associado)
	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT distinct GX0001_TIPO_FORNECEDOR_UVA"
		_oSQL:_sQuery +=  " FROM GX0001_AGENDA_SAFRA V"
		_oSQL:_sQuery += " WHERE GX0001_ASSOCIADO_CODIGO = '" + sze -> ze_assoc + "'"
		_oSQL:_sQuery +=   " AND GX0001_ASSOCIADO_LOJA   = '" + sze -> ze_lojasso   + "'"
		_oSQL:Log ()
		_aTpForUva = _oSQL:RetFixo (1, "ao consultar o 'tipo de fornecedor de uva' cod. '" + sze -> ze_assoc + "/" + sze -> ze_lojasso + "'. Verifique cadastro no NaWeb.", .T.)
		if len (_aTpForUva) == 1
			_sTpForUva = _aTpForUva [1, 1]
		else
			u_log2 ('erro', "Sem definicao para 'tipo de fornecedor de uva'.")
			_lContinua = .F.
		endif
		FreeObj (_oSQL)
	endif

	// Algumas validacoes adicionais quando associado.
	if _lContinua .and. _sTpForUva == 'A'
		_oAssocN := ClsAssoc():New (sze -> ze_assoc, sze -> ze_lojasso)
		if valtype (_oAssocN) != "O" .or. (!_oAssocN:EhSocio (dDataBase) .and. empty (_oAssocN:DtSaida (dDataBase)))  
			u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' nao e' associado e nem ex-associado.")
		else
			if ! empty (_oAssocN:DtFalecim)
				u_help ("Associado consta como falecido em " + dtoc (_oAssocN:DtFalecim))
				_lContinua = .F.
			endif
		endif
		FreeObj (_oAssocN)
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
	if _lContinua .and. empty (sze -> ze_placa)
		u_help ("Placa do veiculo nao informada.")
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_pesotar == 0
		u_help ("Peso tara nao informado.")
		_lContinua = .F.
	endif

/*
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
*/
	// Definicao do TES a ser usado.
	if _lContinua
		do case
		case sze -> ze_assoc == '001369'  // Producao propria Livramento
			_sTES = '028'
		case _sTpForUva + sa2 -> a2_tipo == 'AF'
			_sTES = GetMv ("VA_TSAFAF")  // Associado pessoa fisica
		case _sTpForUva + sa2 -> a2_tipo == 'AJ'
			_sTES = GetMv ("VA_TSAFAJ")  // Associado pessoa juridica
		case _sTpForUva + sa2 -> a2_tipo == 'NF'
			_sTES = GetMv ("VA_TSAFNF")  // Nao associado pessoa fisica
// ainda nao sei se dev gerar contranota nesta caso		case _sTpForUva + sa2 -> a2_tipo == 'NJ'
// ainda nao sei se dev gerar contranota nesta caso			_sTES = GetMv ("VA_TSAFNJ")  // Nao associado pessoa juridica
		otherwise
			u_help ("Nao foi possivel definir o TES a ser usado para gerar contranota. Verifique o cadastro do fornecedor (pessoa fisica/juridica) e tipo de fornecedor no NaWeb.",, .T.)
			_lContinua = .F.
		endcase
	endif
	u_log2 ('info', '_sTES:' + _sTES)


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
		FreeObj (_oSQL)
	endif

	// Se existe mistura de variedades, precifica pela de menor valor.
	// Para isso, varre os itens, monta uma lista de codigos distintos e busca o preco de cada um
	// considerando um grau medio e classificacoes medias. Neste momento nao interessa a classificacao
	// por que quero saber apenas qual a de menor valor comercial.
	if _lContinua
		_sMenorVlr = U_VA_RusMV ()
	endif

	// Calcula valor do frete a ser incluido na nota. Roda em funcao separada por que eh comum precisar recalcular depois da safra.
	if _lContinua
		U_VA_RUSCF (.T.)
	endif

	// Define qual o grupo para pagamento ao qual esta nota deve ser vinculada.
	// Posso definir isso agora por que, se tiver mistura de variedades, jah terei
	// definicao de uma com menor valor, que vai ser o criterio de desempate.
	if _lContinua
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
		do while ! szf -> (eof ()) ;
			.and. szf -> zf_filial == xfilial ("SZF") ;
			.and. szf -> zf_safra  == sze -> ze_safra ;
			.and. szf -> zf_carga  == sze -> ze_carga
			
			// Se tem produto de menor valor definido, usa-o (carga com mistura). Senao, eh por que tem apenas 1 item na carga.
			U_Log2 ('info', 'zf_produto: ' + szf -> zf_produto)
			U_Log2 ('info', '_sMenorVlr: ' + _sMenorVlr)
			if szf -> zf_produto == _sMenorVlr .or. empty (_sMenorVlr)
				_sGrpPgSaf = U_VA_RusGP (szf -> zf_produto, szf -> zf_conduc)
				exit
			endif
			szf -> (dbskip ())
		enddo
		if empty (_sGrpPgSaf)
			u_help ("Nao ha definicao de grupo para pagamento.",, .T.)
			_lContinua = .F.
		else
			// if _sGrpPgSaf == 'A'
			// 	_sCondPg = "815"
			// elseif _sGrpPgSaf == 'B'
			// 	_sCondPg = "816"
			// elseif _sGrpPgSaf == 'C'
			// 	_sCondPg = "817"
			// endif
			_sCondPg = "801"
		endif
	endif
	U_Log2 ('info', 'Grupo para pagamento: ' + _sGrpPgSaf)

	// Confere se a condicao de pagamento a ser usada compoe o mesmo parcelamento definido no grupo de pagamento
//	if _lContinua
//		_lContinua = _ValRegraP (_sGrpPgSaf, _sCondPg, sze -> ze_safra)
//	endif

	// Gera array com cadastro viticola.
	if _lContinua
		if type ('_aCadVitic') != 'A'
			_aCadVitic = aclone (U_VA_RusCV (sze -> ze_assoc, sze -> ze_lojasso))
		endif
		if len (_aCadVitic) == 0
			u_help ("Cadastro viticola vazio!",, .T.)
			_lContinua = .F.
		endif
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
				_nVitic = ascan (_aCadVitic, {|_aVal| alltrim (_aVal [.CadVitCodigo]) == alltrim (szf -> zf_cadviti) .and. alltrim (_aVal [.CadVitProduto]) == alltrim (szf -> zf_produto)})
				if _nVitic == 0
					u_help ("Variedade '" + szf -> zf_produto + "' nao encontrada no cadastro viticola '" + szf -> zf_cadviti + "'.",, .T.)
					_lContinua = .F.
					exit
				else
					if val (_aCadVitic [_nVitic, .CadVitSafrVit]) < val (sze -> ze_safra) - 1
						u_help ("Cadastro viticola consta como renovado para a safra " + _aCadVitic [_nVitic, .CadVitSafrVit])
						_lContinua = .F.
						exit
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

			// Busca preco unitario.
			if szf -> zf_safra == '2019'
				_nVlUni = U_PrcUva19 (szf -> zf_filial, iif (! empty (_sMenorVlr), _sMenorVlr, szf -> zf_produto), val (szf -> zf_grau), _sClasFina, szf -> zf_conduc)[1]
			elseif szf -> zf_safra == '2020'
				_nVlUni = U_PrcUva20 (szf -> zf_filial, iif (! empty (_sMenorVlr), _sMenorVlr, szf -> zf_produto), val (szf -> zf_grau), _sClasFina, szf -> zf_conduc, .F.)[5]  // pos.5=preco MOC
			elseif szf -> zf_safra == '2021'
//				if sze -> ze_assoc == '001369'  // Producao propria Livramento
//					_nVlUni = 1
//				else
				_nVlUni = U_PrcUva21 (szf -> zf_filial, iif (! empty (_sMenorVlr), _sMenorVlr, szf -> zf_produto), val (szf -> zf_grau), _sClasFina, szf -> zf_conduc, .F., .T.)[2]  // pos.2 = preco de compra
//				endif
			else
				u_help ("Sem tratamento para leitura de precos para esta safra.")
				_lContinua = .F.
				exit
			endif

			u_log2 ('info', 'Retornou preco = ' + cvaltochar (_nVlUni))
			
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
			_sDescri = " GR:" + alltrim (szf -> zf_grau)

			// Todas as classificacoes devem estar informadas.
			if ! empty (szf -> zf_prm02) .and. ! empty (szf -> zf_prm03) .and. ! empty (szf -> zf_prm04) .and. ! empty (szf -> zf_prm05) .and. ! empty (szf -> zf_prm99)
				_sDescri += " CL:" + alltrim (szf -> zf_prm99)
			endif
			// Classificacao A/B/D criada em 2014.
			if ! empty (szf -> zf_clasabd)
				_sDescri += " CL:" + alltrim (szf -> zf_clasabd)
			endif
			_sDescri = left (alltrim (sb1 -> b1_desc), _nTamDesc - len (_sDescri)) + _sDescri

			// Pode haver mais de um cadastro viticola, por isso alimenta item a item.
			if ! alltrim (szf -> zf_cadviti) $ _sVitic
				_sVitic += iif (empty (_sVitic), '', ',') + alltrim (szf -> zf_cadviti)
			endif

			// Pode haver mais de um codigo SIVIBE, por isso alimenta item a item.
			if ! alltrim (szf -> zf_cadviti) $ _sSivibe
				_sSivibe += iif (empty (_sSivibe), '', ',') + alltrim (szf -> zf_sivibe)
			endif

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
//			_oSQL := ClsSQL():New ()
//			_oSQL:_sQuery := ""
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
				AADD(_aLinha , {"D1_LOTEFOR", szf -> zf_idZA8, Nil } )
			endif
			AADD(_aLinha , {"D1_VACONDU" , szf -> zf_conduc   , Nil } )
			AADD(_aLinha , {"D1_DESPESA" , szf -> zf_valfret  , Nil } )
			u_log2 ('info', _aLinha)
			AADD(_aAutoSD1, aClone (U_OrdAuto (_aLinha)))

			// Atualiza array de previsao de nota
			aadd (_aPrevia, {szf -> zf_produto, _sDescri, szf -> zf_peso, sb1 -> b1_um, szf -> zf_grau, iif (! empty (szf -> zf_prm99), szf -> zf_prm99, szf -> zf_clasABD), _nVlUni})

			// Acumula valores das uvas e do frete, para calcular distribuicao de parcelas.
			_nVlFrete += szf -> zf_valfret
			_nVlrUvas += _nVlTot

			szf -> (dbskip ())
		enddo
	endif

	// Prepara valores e datas das parcelas do financeiro, para ser lida pelo P.E. MTColSE2
	_aParPgSaf := aclone (U_VA_RusPP (sze -> ze_safra, _sGrpPgSaf, _nVlrUvas, _nVlFrete))
	if len (_aParPgSaf) == 0
		_lContinua = .F.
	endif

	// Prepara dados adicionais
	if _lContinua
		_sMsgContr = ""
		if ! empty (_sMenorVlr)
			_sMsgContr += "Mist.varied:precificando por '" + alltrim (_sMenorVlr) + "';"
		endif
		_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Peso tara:" + cvaltochar (sze -> ze_pesotar) + 'Kg'


	//	_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Cad.vitic:" + _sVitic
		if empty (_sSivibe)  // Se tiver codigo SIVIBE, eu prefiro.
			_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Cad.vitic:" + _sVitic
		else
			_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "SIVIBE:" + _sSivibe
		endif


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
		FreeObj (_oSQL)
	endif
	
	// Mostra tela com valores previstos, para que a filial de Livramento possa saber qual valor vai ficar
	// e, assim, emitir a NF-e de produtos ja com o valor igual.
	if _lContinua .and. .F.  // No final nem precisou, pois conseguimos emitir sem preco no site da SEFAZ
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
			u_log2 ('info', 'confirmou proxima nota para a serie ' + _sSerie)
		else
			u_log2 ('aviso', 'Nao confirmou proxima nota')
		endif
	endif
	
	// Gera a NF
	if _lContinua

		// Busca a Proxima NF da serie informada.
		_sNF = NxtSX5Nota (_sSerie)
		u_log2 ('info', '_sNF: ' + _sNF)

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
		AADD( _aAutoSF1, { "F1_VANFPRO"  , sze->ze_NFProd,  Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASEPRO"  , sze->ze_SNFProd, Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VAPLVEI"  , sze->ze_Placa,   Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASAFRA"  , sze->ze_safra,   Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
//		AADD( _aAutoSF1, { "F1_FRETE"    , _nVlFrete,       Nil})
		AADD( _aAutoSF1, { "F1_VAFLAG"   , 'G',             Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I. Indica 'nota ja gerada' para a rotina de manut. XML
		AADD( _aAutoSF1, { "F1_VAGPSAF"  , _sGrpPgSaf,      Nil})  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_COND"     , _sCondPg,        Nil})

		// Ordena campos cfe. SX3.
		_aAutoSF1 = aClone (U_OrdAuto (_aAutoSF1))
		u_log2 ('info', _aAutoSF1)

		lMsHelpAuto := .F.  // se .t. direciona as mensagens de help
		lMsErroAuto := .F.  // necessario a criacao
		DbSelectArea ("SF1")
		u_log2 ('debug', 'chamando MATA103')

		begin transaction
		MsExecAuto({|x,y,z|MATA103(x,y,z)},_aAutoSF1,_aAutoSD1,3)

		If lMsErroAuto
			_lContinua = .F.
			DisarmTransaction()
			u_log2 ('erro', 'lMsErroAuto')
			if ! empty (NomeAutoLog ())
				u_log2 ('erro', memoread (NomeAutoLog ()))
				MostraErro()
			else
				u_help ("Nao foi possivel ler o arquivo de log de erros.")
			endif
		else
			u_log2 ('info', 'Carga ' + sze -> ze_carga + ' gerou NF ' + sf1 -> f1_doc)

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
		U_Log2 ('info', 'Fim da transacao de geracao da contranota.')

		// Faz a transmissao da NF para a SEFAZ e posterior impressao.
		if ! empty (sze -> ze_nfger)
			U_VA_RUSTX ()
		endif

		// Endereca (saldos a distribuir) o lote de uva recebido por esta contranota.
		if ! empty (sze -> ze_nfger)
			U_VA_RusEn (sze -> ze_nfger, sze -> ze_serie, sze -> ze_assoc, sze -> ze_Lojasso)
		endif

		// Atualiza conta corrente associados
		// Acho que vou fazer em batch, pois nao tem pressa e eh muito lento.
		if ! empty (sze -> ze_nfger) .and. _sTpForUva == 'A'
			// ainda nao 100%			processa ({|| _GravaSZI ()})
		endif

	endif

	_nRetMem := U_UsoMem ()
	u_log2 ('info', 'Achei minha thread usando ' + transform (_nRetMem, "@E 999,999,999,999,999") + ' bytes de memoria')
	if _nRetMem > 300000000
		u_help ("ATENCAO: Esta sessao esta usando muita memoria e vai ser finalizada. Por favor acesse novamente para continuar seu trabalho.",, .T.)
		Final ("Termino proposital para alivio de memoria")
	endif
return


/*
// --------------------------------------------------------------------------
// Gera entrada na conta corrente do associado, com base nos titulos gerados no financeiro.
static function _GravaSZI ()
	local _sAliasQ   := ''
	local _oCtaCorr  := NIL

	procregua (10)
	incproc ('Gravando conta corrente associado')
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCREA, E2_NUM, E2_PREFIXO, E2_TIPO, E2_VALOR, E2_SALDO, E2_HIST, R_E_C_N_O_, E2_LA, E2_PARCELA,"
	_oSQL:_sQuery +=        " ROW_NUMBER () OVER (ORDER BY E2_PARCELA) AS NUM_PARC"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2")
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND E2_TIPO    = 'NF'"
	_oSQL:_sQuery +=    " AND E2_FORNECE = '" + sf1 -> f1_fornece + "'"
	_oSQL:_sQuery +=    " AND E2_LOJA    = '" + sf1 -> f1_loja + "'"
	_oSQL:_sQuery +=    " AND E2_PREFIXO = '" + sf1 -> f1_serie + "'"
	_oSQL:_sQuery +=    " AND E2_NUM     = '" + sf1 -> f1_doc + "'"
	_oSQL:_sQuery +=    " AND E2_VACHVEX = ''"
	_oSQL:_sQuery +=    " AND E2_FILIAL  = '" + xfilial ("SE2") + "'"
	_oSQL:_sQuery +=  " ORDER BY E2_PARCELA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.T.)
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		incproc ('Gravando cta.corr.assoc.')
		//u_log ('Filial:' + (_sAliasQ) -> e2_filial, 'Forn:' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' ' + (_sAliasQ) -> e2_nomfor, 'Emis:', (_sAliasQ) -> e2_emissao, 'Vcto:', (_sAliasQ) -> e2_vencrea, 'Doc:', (_sAliasQ) -> e2_num+'/'+(_sAliasQ) -> e2_prefixo, 'Tipo:', (_sAliasQ) -> e2_tipo, 'Valor: ' + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99"), 'Saldo: ' + transform ((_sAliasQ) -> e2_saldo, "@E 999,999,999.99"), (_sAliasQ) -> e2_hist)

		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:Assoc    = (_sAliasQ) -> e2_fornece
		_oCtaCorr:Loja     = (_sAliasQ) -> e2_loja
		_oCtaCorr:TM       = '13'
		_oCtaCorr:DtMovto  = (_sAliasQ) -> e2_EMISSAO
		_oCtaCorr:Valor    = (_sAliasQ) -> e2_valor
		_oCtaCorr:SaldoAtu = (_sAliasQ) -> e2_saldo
		_oCtaCorr:Usuario  = cUserName
		_oCtaCorr:Histor   = 'COMPRA SAFRA ' + sf1 -> f1_vasafra + " GRP." + sf1 -> f1_vagpsaf
		_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
		_oCtaCorr:Doc      = (_sAliasQ) -> e2_num
		_oCtaCorr:Serie    = (_sAliasQ) -> e2_prefixo
		_oCtaCorr:Parcela  = (_sAliasQ) -> e2_parcela
		_oCtaCorr:Origem   = 'VA_RUS'
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

				// Se gerei conta corrente numa filial, preciso transferir esse lcto para a matriz, pois todos os pagamentos sao centralizados.
				if sf1 -> f1_filial != '01' //.and. 'TESTE' $ upper (getenvserver ())  // por enqto apenas na base teste
					_oCtaCorr:FilDest = '01'
					_oCtaCorr:Origem  = FunName ()
					if ! _oCtaCorr:TransFil (_oCtaCorr:Valor)
						u_help ("A transferencia para outra filial nao foi possivel. " + _oCtaCorrT:UltMsg,, .T.)
					endif
				endif
			endif

		else
			U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
			_lContinua = .F.
		endif

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SZE")
return
*/

/*
// --------------------------------------------------------------------------
// Consiste regra de pagamento com a condicao a ser usada na geracao da nota.
static function _ValRegraP (_sGrpPgSaf, _sCondPg, _sSafPag)
	local _sError     := ''
	local _sWarning   := ''
	local _sXMLFech   := ''
	local _nRegraPag  := 0
	local _oAssocCP   := NIL
	local _lRetRegPg  := .T.
	local _oSQL       := NIL
	local _nParcPg    := 0
	local _aRegraPag  := {}
	static _aRegraA   := {}
	static _aRegraB   := {}
	static _aRegraC   := {}
	private _oXMLFech := NIL  // Precisa ser do tipo PRIVATE senao a funcao XmlParser() nao funciona... vai entender.

	// Vou usar uma variavel estatica para nao ficar lendorepetidamente, pois, em tese, essas
	// regras de pagamento nao devem ser alteradas durante a safra.
	if len (_aRegraA) == 0 .or. len (_aRegraB) == 0 .or. len (_aRegraC) == 0
		_aRegraA = {0,0,0,0,0,0,0,0,0,0,0}
		_aRegraB = {0,0,0,0,0,0,0,0,0,0,0}
		_aRegraC = {0,0,0,0,0,0,0,0,0,0,0}
		_oAssocCP = ClsAssoc():New ('000161', '01')  // Aqui nao preciso de um associado especifico... preciso apenas ler as regras de pagamento.
		_sXmlFech = _oAssocCP:FechSafra (_sSafPag)
		U_Log2 ('debug', _sXmlFech)
		// Converte de texto para XML
		_oXMLFech := XmlParser (_sXmlFech, "_", @_sError, @_sWarning)
		if ! empty (_sError) .or. ! empty (_sWarning)
			u_help ("Erro ao decodificar retorno: " + _sError + _sWarning,, .t.)
		endif
		// Verifica se tem este tipo de tag no XML
		if Type('_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem') != 'A'
			u_help ('Nao foi possivel ler as regras de pagamento para esta safra.',, .T.)
			_lRetRegPg = .F.
		else
			for _nRegraPag = 1 to len (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem)
				if _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_grupo:TEXT == 'A'
					_aRegraA [1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc01:TEXT)
					_aRegraA [2]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc02:TEXT)
					_aRegraA [3]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc03:TEXT)
					_aRegraA [4]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc04:TEXT)
					_aRegraA [5]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc05:TEXT)
					_aRegraA [6]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc06:TEXT)
					_aRegraA [7]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc07:TEXT)
					_aRegraA [8]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc08:TEXT)
					_aRegraA [9]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc09:TEXT)
					_aRegraA [10] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc10:TEXT)
					_aRegraA [11] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc11:TEXT)
				endif
				if _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_grupo:TEXT == 'B'
					_aRegraB [1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc01:TEXT)
					_aRegraB [2]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc02:TEXT)
					_aRegraB [3]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc03:TEXT)
					_aRegraB [4]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc04:TEXT)
					_aRegraB [5]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc05:TEXT)
					_aRegraB [6]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc06:TEXT)
					_aRegraB [7]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc07:TEXT)
					_aRegraB [8]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc08:TEXT)
					_aRegraB [9]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc09:TEXT)
					_aRegraB [10] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc10:TEXT)
					_aRegraB [11] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc11:TEXT)
				endif
				if _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_grupo:TEXT == 'C'
					_aRegraC [1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc01:TEXT)
					_aRegraC [2]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc02:TEXT)
					_aRegraC [3]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc03:TEXT)
					_aRegraC [4]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc04:TEXT)
					_aRegraC [5]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc05:TEXT)
					_aRegraC [6]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc06:TEXT)
					_aRegraC [7]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc07:TEXT)
					_aRegraC [8]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc08:TEXT)
					_aRegraC [9]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc09:TEXT)
					_aRegraC [10] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc10:TEXT)
					_aRegraC [11] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc11:TEXT)
				endif
			next
		endif
	endif
	if _lRetRegPg
		if _sGrpPgSaf == 'A'
			_aRegraPag = aclone (_aRegraA)
		elseif _sGrpPgSaf == 'B'
			_aRegraPag = aclone (_aRegraB)
		elseif _sGrpPgSaf == 'C'
			_aRegraPag = aclone (_aRegraC)
		endif
	endif

	// Compara com o cadastro da condicao de pagamento
	if _lRetRegPg .and. len (_aRegraPag) > 0
		U_Log2 ('debug', _aRegraPag)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE4") + " SE4"
		_oSQL:_sQuery += " WHERE SE4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SE4.E4_FILIAL  = '" + xfilial ("SE4") + "'"
		_oSQL:_sQuery +=   " AND SE4.E4_CODIGO  = '" + _sCondPg + "'"
		_oSQL:_sQuery +=   " AND SE4.E4_TIPO    = 'B'"
		for _nParcPg = 1 to len (_aRegraPag)
			if _aRegraPag [_nParcPg] != 0
				_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
				_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SEC") + " SEC"
				_oSQL:_sQuery +=                " WHERE SEC.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=                  " AND SEC.EC_FILIAL  = '" + xfilial ("SE4") + "'"
				_oSQL:_sQuery +=                  " AND SEC.EC_CODIGO  = SE4.E4_CODIGO"
				_oSQL:_sQuery +=                  " AND SEC.EC_ITEM    = '" + strzero (_nParcPg, 2) + "'"
				_oSQL:_sQuery +=                  " AND SEC.EC_RATEIO  = "  + cvaltochar (_aRegraPag [_nParcPg])
				_oSQL:_sQuery +=               ")"
			endif
		next
		_oSQL:Log ()
		if _oSQL:RetQry (1, .F.) != 1
			u_help ("Configuracao da condicao de pagamento '" + _sCondPg + ;
			        "' incompativel com a regra de pagamento para uvas do grupo '" + _sGrpPgSaf + ;
					"'. A condicao deve ser do tipo B e as parcelas devem ser distribuidas de forma a compor os mesmos percentuais a serem usados no pagamento da safra. As datas de vencimento serao recalculadas via ponto de entrada SF1100I.",, .t.)
			_lRetRegPg = .F.
		endif
	endif
return _lRetRegPg
*/

/*
// --------------------------------------------------------------------------
// Monta variaveis com as regras de pagamento, a serem usadas no P.E. MTCOLSE2.
static function _RegrasPG (_sGrpPgSaf, _nVlUva, _nVlFrete)
	local _sError     := ''
	local _sWarning   := ''
	local _sXMLFech   := ''
	local _nRegraPag  := 0
	local _oAssocCP   := NIL
	local _aRetParPg  := {
	local _nParcPg    := 0
	local _aRegraPag  := {}
	private _oXMLFech := NIL  // Precisa ser do tipo PRIVATE senao a funcao XmlParser() nao funciona... vai entender.

	// Aqui nao preciso de um associado especifico... preciso apenas ler as regras de pagamento.
	_oAssocCP = ClsAssoc():New ('000161', '01')
	_sXmlFech = _oAssocCP:FechSafra (_sSafPag)
	U_Log2 ('debug', _sXmlFech)
	
	// Converte de texto para XML
	_oXMLFech := XmlParser (_sXmlFech, "_", @_sError, @_sWarning)
	if ! empty (_sError) .or. ! empty (_sWarning)
		u_help ("Erro ao decodificar retorno do XML de regras de pagamento para esta safra: " + _sError + _sWarning,, .t.)
	else
		// Verifica se tem este tipo de tag no XML
		if Type('_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem') != 'A'
			u_help ('Nao encontrei regras de pagamento para esta safra.',, .T.)
		else
			for _nRegraPag = 1 to len (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem)
				if _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_grupo:TEXT == _sGrpPgSaf
					_aRetParPg [1, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc01:TEXT)
					_aRetParPg [2, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc02:TEXT)
					_aRetParPg [3, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc03:TEXT)
					_aRetParPg [4, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc04:TEXT)
					_aRetParPg [5, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc05:TEXT)
					_aRetParPg [6, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc06:TEXT)
					_aRetParPg [7, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc07:TEXT)
					_aRetParPg [8, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc08:TEXT)
					_aRetParPg [9, 1]  = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc09:TEXT)
					_aRetParPg [10, 1] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc10:TEXT)
					_aRetParPg [11, 1] = val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc11:TEXT)
				endif
			next
		endif
	endif
return _aRetParPg
*/
