// Programa...: SF2520E
// Autor......: ?
// Data.......: ?
// Descricao..: Ponto de entrada antes da exclusao de notas fiscais.
//
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada antes da exclusao de notas fiscais.
// #PalavasChave      #ponto_de_entrada #exclusao_de_nota #nota_de_saida 
// #TabelasPrincipais #SD2 #SF2
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 07/03/2008 - Robert  - Empresa 02 foi desativada. Nao precisa mais movimentar.
// 30/05/2008 - Robert  - Reabilitado tratamento empresa 02.
//                      - Criado tratamento para versao em SQL.
// 04/06/2008 - Robert  - Envia e-mail avisando do cancelamento.
// 16/06/2008 - Robert  - Deleta registro do SF3 (sistema padrao guarda como 'NF cancelada').
// 19/06/2008 - Robert  - Pede justificativa para exclusao da nota e grava evento.
// 04/07/2008 - Robert  - Nao deleta mais o registro do SF3.
// 10/07/2008 - Robert  - Geracao de evento em formato 'Objeto'.
// 16/07/2008 - Robert  - Avisa usuario caso a ordem de embarque jah tenha sido impressa.
// 30/07/2008 - Robert  - Exclusao do registro na tabela ZZ4.
// 13/08/2008 - Robert  - Estorno ajuste estoques na empresa 01.
// 21/08/2008 - Robert  - Rotina de ajuste de estoques na empresa 01 passa a usar o campo D3_vaDoc02.
// 07/10/2008 - Robert  - SQL que deleta PVCond no SE1020 passa a setar campo R_E_C_D_E_L_.
// 24/02/2009 - Robert  - Envia e-mail de aviso ao financeiro.
// 26/02/2009 - Robert  - Ajuste de estoque na empresa 01 passa a trabalhar com processos batch (ZZ6)
// 11/03/2009 - Robert  - Criados tratamentos para que o armazem geral possa ser representado
//                        tambem por fornecedor e nao somente por cliente.
// 12/04/2010 - Robert  - Melhorada mensagem do e-mail de aviso aos interessados (financeiro)
// 16/04/2010 - Robert  - Gravacao de evento tambem envia e-mail de aviso ao pessoal da expedicao.
// 01/10/2010 - Fabiano - Excluido email da alexandra da notificacao de exclusao
// 06/10/2010 - Robert  - Incluidos novos destinatarios no e-mail de aviso de exclusao de NF.
// 04/11/2010 - Robert  - Tratamento para exclusao de notas de venda via deposito.
// 06/01/2011 - Robert  - Grava data do embarque da nota no evento, caso jah esteja embarcada.
// 17/01/2011 - Robert  - Avisa quando a nota jah havia sido exportada para EDI com cliente.
// 11/08/2011 - Robert  - Atualiza SZI quando NF de venda para associado.
// 13/10/2011 - Robert  - Passa a usar a funcao VA_ZZ4E para limpeza do ZZ4.
// 30/09/2012 - Robert  - Criados campos D3_VANFRD, D3_VASERRD e D3_VAITNRD para substituir o D3_VACHVEX 
//                        no controle de armazens externos.
// 21/05/2013 - Robert  - Melhorada query de verificacao se a NF saiu via deposito 04.
// 24/06/2013 - Robert  - Tratamento de armazem passa a usar a classe ClsAmzGer.
//                      - Cancelamento remessa para armazem geral passa a ser via batch.
// 15/01/2014 - Leandro - grava evento para histórico de NF
// 11/05/2015 - Robert  - Tratamento para devolucoes/cancelamentos (arquivo ZAB).
// 02/06/2015 - Robert  - Grava atributos Cliente e Loja no objeto _oDevol.
// 28/10/2015 - Robert  - Limpa memos do f2_vacmemc e f2_vacmemf.
// 24/05/2016 - Robert  - Eliminado tratamento para PVCOND.
// 01/06/2016 - Robert  - Nao chama mais a exclusao da tabela ZZ4 (dados adicionais NF).
// 19/02/2018 - Robert  - Desabilitado tratamento para deposito fechado (nao usamos mais ha tempo)
// 02/05/2018 - Robert  - Desabilitado tratamento para armazem geral (nao usamos mais ha tempo)
// 03/05/2018 - Robert  - Desabilitados tratamentos do ZAB (devolucoes de clientes).
// 06/11/2020 - Claudia - Incluida a exclusão de titulos de NF's de cartões. GLPI: 8749
// 24/05/2022 - Claudia - Incluido o estorno de rapel. GLPI: 8916
// 07/10/2022 - Claudia - Atualização de rapel apenas para serie 10. GLPI: 8916
// 01/11/2022 - Claudia - Incluido o tipo PX para validação de exclusão de títulos. GLPI: 12713
// 04/12/2023 - Claudia - Alterada a busca de lcto. conta associado, para exclusão de NF's. GLPI: 14388
//
// ------------------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function SF2520E() 
	local _sJustif   := ""
	local _oEvento   := NIL
	local _sEmbarque := ""
	local _aAreaAnt  := U_ML_SRArea ()

	u_logIni ()

	// Elimina dados adicionais.
	if ! empty (sf2 -> f2_vacmemc)
		msmm (sf2 -> f2_vacmemc,,,, 2,,, "SF2", "F2_VACMEMC")
	endif
	if ! empty (sf2 -> f2_vacmemf)
		msmm (sf2 -> f2_vacmemf,,,, 2,,, "SF2", "F2_VACMEMF")
	endif

	// Verifica se a nota pertence a alguma ordem de embarque
	if ! empty (sf2 -> f2_ordemb)
		szo -> (dbsetorder (1))  // ZO_FILIAL+ZO_NUMERO
		if szo -> (dbseek (xfilial ("SZO") + sf2 -> f2_ordemb, .F.)) // .and. szo -> zo_impres == "S"
			u_help ("Lembre-se de reimprimir a ordem de embarque " + sf2 -> f2_ordemb)
			if ! empty (szo -> zo_dataemb)
				_sEmbarque = " - NF embarcada em " + dtoc (szo -> zo_dataemb)
			endif
		endif
	endif

	// Verifica se a nota jah foi exportada para EDI.
	if sf2 -> f2_vaEDIM == "S"
		U_ZZUNU ({"003"}, "Cancelada NF ja enviada para EDI com clientes", "NF '" + sf2 -> f2_doc + "' foi cancelada, mas ja havia sido enviada para EDI com cliente. Verifique necessidade de avisar o cliente.", .F., cEmpAnt, cFilAnt)
	endif

	// Grava evento com justificativa
	_sJustif = ""
	do while empty (_sJustif)
		_sJustif := space (255)  // Mais que isso eh pra matar...
		define MSDialog _oDlgJust from 0, 0 to 150, 500 of oMainWnd pixel title "Justificativa"
		@ 10, 10 say "Justifique a exclusao da nota " + sf2 -> f2_doc
		@ 30, 10 get _sJustif size 200, 11
		@ 45, 10 bmpbutton type 1 action (_oDlgJust:End ())
		activate MSDialog _oDlgJust centered
	enddo

	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SF2001"
	_oEvento:Texto     = "Cancelamento da NF " + alltrim (sf2 -> f2_doc) + " Motivo: " + alltrim(_sJustif) + _sEmbarque
	_oEvento:NFSaida   = sf2 -> f2_doc
	_oEvento:SerieSaid = sf2 -> f2_serie
	_oEvento:PedVenda  = ""
	_oEvento:Cliente   = sf2 -> f2_cliente
	_oEvento:LojaCli   = sf2 -> f2_loja
	_oEvento:Hist      = "1"
	_oEvento:Status    = "8"
	_oEvento:Sub       = ""
	_oEvento:Prazo     = 0
	_oEvento:Flag      = .T.
	_oEvento:MailToZZU = {'012'}
	_oEvento:Grava ()

	// Envia e-mail de aviso especifico com dados de titulos, para o pessoal do financeiro.
	_MailFin ()

	// Tratamento para conta corrente de associados.
	_AtuSZI ()

	// Envia e-mail de aviso especifico para o pessoal de logistica.
	_MailLog ()

	// Verifica se é NF de cartão CC/CD e exclui seus títulos 
	_ExcTitCartao()

	// Tratamento conta corrente rapel
	If GetMV('VA_RAPEL')
		_AtuZC0()
	EndIf

	// Alimenta lista de notas excluidas.
	if type ("_aNfExcl") == "A"
		aadd (_aNfExcl, {sf2 -> f2_doc, sf2 -> f2_serie})
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
Return()
//
// --------------------------------------------------------------------------
// Envia e-mail de aviso ao financeiro.
static function _MailFin ()
	local _sQuery  := ""
	local _aTit    := {}
	local _nTit    := 0
	local _sMsg    := ""

	_sMsg := "Exclusao NF '" + sf2 -> f2_doc + "' serie '" + sf2 -> f2_serie + chr (13) + chr (10)
	_sMsg += "Cliente: '" + sf2 -> f2_cliente + "' loja: '" + sf2 -> f2_loja + chr (13) + chr (10) + chr (13) + chr (10)
	_sMsg += "Titulo(s) relacionado(s):" + chr (13) + chr (10) + chr (13) + chr (10)

	_sQuery := ""
	_sQuery += " select E1_PREFIXO, E1_NUM, E1_PARCELA, E1_NUMBCO, E1_PORT2"
	_sQuery +=   " from " + RetSQLName ("SE1") + " SE1 "
	_sQuery +=  " where SE1.D_E_L_E_T_ = ''"
	_sQuery +=    " and SE1.E1_FILIAL  = '" + sf2 -> f2_filial + "'"
	_sQuery +=    " and SE1.E1_NUM     = '" + sf2 -> f2_doc + "'"
	_sQuery +=    " and SE1.E1_PREFIXO = '" + sf2 -> f2_serie + "'"
	_aTit = aclone (U_Qry2Array (_sQuery))
	for _nTit = 1 to len (_aTit)
		_sMsg += "Prefixo: " + _aTit [_nTit, 1] + "   Numero: " + _aTit [_nTit, 2] + "   Parcela: " + _aTit [_nTit, 3] + "   Numero bco: " + _aTit [_nTit, 4] + "   Banco: " + _aTit [_nTit, 5] + chr (13) + chr (10)
	next
	U_ZZUNU ({'008','011'}, "Exclusao NF " + sf2 -> f2_doc, _sMsg)
return
//
// --------------------------------------------------------------------------
// Envia e-mail de aviso para a logistica
static function _MailLog ()
	local _oSQL := NIL
	local _sMsg := ""

	_sMsg := "Exclusao NF '" + sf2 -> f2_doc + "' serie '" + sf2 -> f2_serie + "'" + chr (13) + chr (10)
	_sMsg += "Cliente: " + sf2 -> f2_cliente + "/" + sf2 -> f2_loja
	if sf2 -> f2_tipo $ "B/D"
		_sMsg += ' - ' + alltrim (fBuscaCpo ("SA2", 1, xfilial ("SA2") + sf2 -> f2_cliente + sf2 -> f2_loja, "A2_NOME")) + chr (13) + chr (10) + chr (13) + chr (10)
	else
		_sMsg += ' - ' + alltrim (fBuscaCpo ("SA1", 1, xfilial ("SA1") + sf2 -> f2_cliente + sf2 -> f2_loja, "A1_NOME")) + chr (13) + chr (10) + chr (13) + chr (10)
	endif
	
	// Verifica carga em que a nota se encontra
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT TOP 1 C9_CARGA"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SC9")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND C9_FILIAL  = '" + xfilial ("SC9") + "'"
	_oSQL:_sQuery +=   " AND C9_NFISCAL = '" + sf2 -> f2_doc + "'"
	_sMsg += " Carga: '" + _oSQL:RetQry () + "'" + chr (13) + chr (10) + chr (13) + chr (10)
	U_ZZUNU ({'030'}, "Cancelamento NF " + sf2 -> f2_doc, _sMsg)
return
//
// --------------------------------------------------------------------------
// Atualiza arquivo de conta corrente de associados, quando for o caso.
static function _AtuSZI ()
	local _oCtaCorr   := NIL
	local _sQuery     := ""
	local _nRetQry    := 0
	local _lContinua  := .T.
	local _oAssoc     := NIL

	// Verifica se o cliente eh um associado
	if _lContinua
		if sf2 -> f2_tipo $ 'NPI'
			sa1 -> (dbsetorder (1))
			if ! sa1 -> (dbseek (xfilial ("SA1") + sf2 -> f2_cliente + sf2 -> f2_loja, .F.))
				_lContinua = .F.
			else
				sa2 -> (dbsetorder (3))  // A2_FILIAL+A2_CGC
				if ! sa2 -> (dbseek (xfilial ("SA2") + sa1 -> a1_cgc, .F.))
					_oAssoc := ClsAssoc():New (sa2 -> a2_cod, sa2 -> a2_loja, .T.)
					if valtype (_oAssoc) != "O" .or. ! _oAssoc:EhSocio ()
						_lContinua = .F.
					endif
				endif
			endif
		elseif sf2 -> f2_tipo $ 'B'  // Utiliza fornecedor
			sa2 -> (dbsetorder (1))
			if ! sa2 -> (dbseek (xfilial ("SA2") + sf2 -> f2_cliente + sf2 -> f2_loja, .F.))
				_oAssoc := ClsAssoc():New (sa2 -> a2_cod, sa2 -> a2_loja)
				if valtype (_oAssoc) != "O" .or. ! _oAssoc:EhSocio ()
					_lContinua = .F.
				endif
			endif
		endif
	endif

	// Se gerou movimento na conta corrente de associados...
	if _lContinua
		_sQuery := ""
		_sQuery += " SELECT R_E_C_N_O_"
		_sQuery += " 	FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery += " AND ZI_FILIAL    = '" + xfilial ("SZI") + "'"
		_sQuery += " AND ZI_ORIGEM IN ('SF2460I','BATCOMPASS') "  //_sQUery +=   " AND ZI_TM      = '04'"
		_sQuery += " AND ZI_DATA      = '" + dtos (sf2 -> f2_emissao) + "'"
		_sQuery += " AND ZI_ASSOC     = '" + sa2 -> a2_cod   + "'"
		_sQuery += " AND ZI_LOJASSO   = '" + sa2 -> a2_loja  + "'"
		_sQuery += " AND ZI_DOC       = '" + sf2 -> f2_doc   + "'"
		_sQuery += " AND ZI_SERIE     = '" + sf2 -> f2_serie + "'"
		_nRetQry = U_RetSQL (_sQuery)

		if _nRetQry > 0
			_oCtaCorr = ClsCtaCorr():New (_nRetQry)
			if ! _oCtaCorr:Exclui ()
				u_help ("Nao foi possivel excluir da conta corrente de associados a movimentacao gerada por esta nota fiscal. Revise a conta corrente do associado '" + sf1 -> f1_fornece + "'.")
			endif
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Exclui títulos de NF's de cartões cartões CC/CD
Static Function _ExcTitCartao()
	local _aDados := {}
	local _oSQL   := ClsSQL ():New ()

	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT * "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
	_oSQL:_sQuery += " WHERE E1_FILIAL = '" + sf2 -> f2_filial + "'"
	_oSQL:_sQuery += " AND E1_NUM      = '" + sf2 -> f2_doc    + "'"
	_oSQL:_sQuery += " AND E1_PREFIXO  = '" + sf2 -> f2_serie  + "'"
	_oSQL:_sQuery += " AND E1_TIPO IN('CC','CD','PX') "
    _oSQL:_sQuery += " AND E1_ADM   <> '' "
	_oSQL:_sQuery += " AND E1_BAIXA = '' "
	_aDados := aclone (_oSQL:Qry2Array ())

	if len(_aDados) > 0

		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE SE1010 SET D_E_L_E_T_ = '*' "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
		_oSQL:_sQuery += " WHERE E1_FILIAL = '" + sf2 -> f2_filial + "'"
		_oSQL:_sQuery += " AND E1_NUM      = '" + sf2 -> f2_doc    + "'"
		_oSQL:_sQuery += " AND E1_PREFIXO  = '" + sf2 -> f2_serie  + "'"
		_oSQL:_sQuery += " AND E1_TIPO IN('CC','CD','PX') "
		_oSQL:_sQuery += " AND E1_ADM   <> '' "
		_oSQL:_sQuery += " AND E1_BAIXA = '' "
		_oSQL:Log ()
		_oSQL:Exec ()
	endif
Return
//
// --------------------------------------------------------------------------
// Estorna rapel da NF
Static Function _AtuZC0()

	If  alltrim(sf2->f2_serie) == '10'
		// Cancela rapel	
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	ZC0_RAPEL "
		_oSQL:_sQuery += " FROM ZC0010 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND ZC0_FILIAL = '"+ sf2 -> f2_filial  +"' "
		_oSQL:_sQuery += " AND ZC0_CODCLI = '"+ sf2 -> f2_cliente +"' "
		_oSQL:_sQuery += " AND ZC0_LOJCLI = '"+ sf2 -> f2_loja    +"' "
		_oSQL:_sQuery += " AND ZC0_DOC    = '"+ sf2 -> f2_doc     +"' "
		_oSQL:_sQuery += " AND ZC0_SERIE  = '"+ sf2 -> f2_serie   +"' "
		_oSQL:Log ()
		_aRapel := aclone (_oSQL:Qry2Array ())

		If len(_aRapel) > 0
			_oCtaRapel := ClsCtaRap():New ()

			_sRede := _oCtaRapel:RetCodRede(sf2 -> f2_cliente, sf2 -> f2_loja)

			_oCtaRapel:Filial  	 = sf2 -> f2_filial
			_oCtaRapel:Rede      = _sRede	
			_oCtaRapel:LojaRed   = sf2 -> f2_loja
			_oCtaRapel:Cliente 	 = sf2 -> f2_cliente
			_oCtaRapel:LojaCli	 = sf2 -> f2_loja
			_oCtaRapel:TM      	 = '03' 	
			_oCtaRapel:Data    	 = ddatabase//date()
			_oCtaRapel:Hora    	 = time()
			_oCtaRapel:Usuario 	 = cusername 
			_oCtaRapel:Histor  	 = 'Estorno de rapel por cancelamento de NF' 
			_oCtaRapel:Documento = sf2 -> f2_doc
			_oCtaRapel:Serie 	 = sf2 -> f2_serie
			_oCtaRapel:Parcela	 = ''
			_oCtaRapel:Rapel	 = _aRapel[1,1]
			_oCtaRapel:Origem	 = 'SF2520E'
			_oCtaRapel:NfEmissao = sf2 -> f2_emissao

			If _oCtaRapel:Grava (.F.)
				_oEvento := ClsEvent():New ()
				_oEvento:Alias     = 'ZC0'
				_oEvento:Texto     = "Estorno rapel "+ sf2 -> f2_doc + "/" + sf2 -> f2_serie
				_oEvento:CodEven   = 'ZC0001'
				_oEvento:Cliente   = sf2 -> f2_cliente
				_oEvento:LojaCli   = sf2 -> f2_loja
				_oEvento:NFSaida   = sf2 -> f2_doc
				_oEvento:SerieSaid = sf2 -> f2_serie
				_oEvento:Grava()
			EndIf
		EndIf
	EndIf
Return
