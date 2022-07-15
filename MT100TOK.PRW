// Programa...: MT100TOk
// Autor......: Jeferson Rech
// Data.......: nov/2004
// Descricao..: P.E. 'Tudo OK' da tela de notas de entrada.

//  #TipoDePrograma    #ponto_de_entrada
//  #Descricao         #P.E. 'Tudo OK' da tela de notas de entrada.
//  #PalavasChave      #notas_de_entrada #tudo_ok 
//  #TabelasPrincipais #SD1 #SF1
//  #Modulos           #COM #EST

// Historico de alteracoes:
// 12/05/2008 - Robert  - Incluidas validacoes para tratamento de controle de fretes.
// 19/05/2008 - Robert  - Ajustada logica de retorno em caso de erros.
// 29/07/2008 - Robert  - Simula chamada da tela de sel. de fretes quando for importacao de conhecimentos de frete.
// 04/12/2008 - Robert  - Exige especie SPED quando usar formulario proprio.
// 07/05/2009 - Robert  - Nao pede senha de liberacao de vencimento quando chamado via geracao de NF de compra de safra.
// 14/01/2010 - Robert  - Verifica emp/filial para compatibilidade com Livramento.
// 18/03/2010 - Robert  - Nao pede senha de liberacao de vencimento quando chamado via importacao de conhecimento de frete.
// 20/04/2010 - Robert  - Verificacao de geracao de NF fora de sequencia.
// 12/01/2011 - Robert  - Desabilitado controle de area por variedade (safra 2011).
// 04/07/2011 - Robert  - Desabilitados controles por patriarca (safra).
// 22/08/2011 - Robert  - Preparada leitura do XML ar arquivo ZZX (quando disponivel) para futuras validacoes.
// 28/11/2011 - Robert  - Desabilitada verificacao de dias para vencimento + exigencia de senha para periodos curtos.
// 02/04/2012 - Robert  - Verificacao da chave da NF-e entrada.
// 11/05/2012 - Robert  - Verificacao da chave da NF-e entrada: Nao exige mais somente numeros por que notas de servico dependem de cada municipio.
//                      - Incrementadas validacoes caso ja tenha o XML importado.
//                      - Passa a aceitar especie CTE como conhecimento de frete, junto com CTR.
// 29/05/2012 - Robert  - Permite (via confirmacao) chave NF-e de CNPJ diferente do cadastro do fornecedor.
// 04/06/2012 - Robert  - Adicionado suporte a versao 1.04 de CT-e.
// 30/08/2012 - Robert  - Implementada consulta da chave na SEFAZ.
// 29/11/2012 - Robert  - Implementada verificacao de preenchimento do numero da nota, considerando opcao 'retornar'.
// 14/02/2013 - Elaine  - Comparar DtEmissao, Valor Total da Nota e Insc Estadual (caso digitada nota que tenha XML do fornecedor) informada com a 
//                       informacao contida no XML.
// 18/02/2013 - Elaine  - Testar parâmetro VA_VALXML - nao permitir a inclusao da nota pelo XML se existir qq inconsistência
// 19/08/2014 - Robert  - Melhorada leitura da chave no ZZX. Caso a chave exista e nao esteja autorizada, chama a funcao ZZXCC.
// 06/10/2014 - Catia   - Alterada a mensagem do "Layout / versao XML", para que não de a mensagem quando usado pelo IMPCONH
// 18/10/2014 - Catia   - Alterada a mensagem do "Layout / versao XML", para que não de a mensagem quando usado pelo EDICONH
// 19/01/2015 - Catia   - Feito teste para que nao critique o CNPJ quando a serie for 890 a 899 (copiei a legislação no programa)
// 19/01/2015 - Catia   - Incluido teste que obriga a existencia do XML já importado no sistema para inclusao de documentos de entrada NF-e/CT-e
// 10/02/2015 - Catia   - Notas de complemento de imposto - não validar o total da nota com o total do icms como fazia.
// 28/09/2015 - Robert  - Verifica se a NF origem (quando transf.filial) tem chave gravada.
// 28/10/2015 - Robert  - Valida o layout do XML antes de validar os dados (ex.: para evitar a validacao de um evento em vez de validar a proprioa nota).
// 09/11/2015 - Catia   - validar itens controlados pela policia federal - obrigando a digitação do transportador na nota
// 02/02/2016 - Catia   - alterar forma de validar itens controlados pela policia federal - obrigando a digitação do transportador na nota
// 23/02/2016 - Robert  - Mensagem "XML da NF-e/CT-e referenciada por esta chave destina-se a documentos do tipo..." passa a bloquear a digitacao em vez de apenas pedir confirmacao.
// 25/02/2016 - Robert  - Desconsiderar os CT-e
// 03/05/2016 - Catia   - Validar campo F4_FRETE - so podem ser usados TES com F4_FRETE = 1(SIM) nas especies CTR e CTe
// 16/07/2016 - Catia   - rotinas de validacao layout xml - desconsiderar quando chamar do ZZX - isincallstack ("U_ZZXG")
// 29/11/2016 - Robert  - Layout de CT-e passa a ter nova tag <procCTe>
// 21/12/2016 - Catia   - estava atribuindo a base ICM para o total da nota e testando no XML com a TAG total da nota - tem que ser total produtos
// 09/01/2016 - Catia   - Voltar a mensagem de validação de total da nota e total da mercadoria calculada no sistema com o que vem no XML
// 16/01/2016 - Catia   - Tirada a validação do valor da mercadoria - katia pediu pq tem muita diferença de centavos (????)
// 07/03/2017 - Catia   - Validações no XML de CTEs  
// 28/03/2018 - Catia   - Erro no JOB do Cupom
// 04/05/2018 - Catia   - Erro no SPED na inutilizacao de notas
// 13/06/2018 - Catia   - desabilitar que seja executado essa rotina quando vem do ZZX e quando for pre nota MATA140
// 03/09/2019 - Claudia - Desabilitada a execução de ponto de entrada para rotina de emissão de nota fiscal manual de saída  
// 26/09/2019 - Andre   - Incluida validacao para condição de pagamento não pode ser diferente da condição do pedido.
// 18/10/2019 - Robert  - Validacao de cond.pag. e parcelas passa a aceitar grupo 091 do ZZU.
// 30/01/2020 - Robert  - Melhorados logs (tentativa verificar bloqueio notas safra).
// 06/03/2020 - Claudia - Ajustado o fonte conforme solicitação da R25 - Uso NÃO PERMITIDO de API em LOOP - Retirada a leitura o getmv do For
// 16/06/2020 - Robert  - Desabilitadas chamadas de logs desnecessarios.
//                      - Eliminadas algumas declaracoes de variaveis nao usadas.
// 06/01/2021 - Robert  - Desabilitada chamada do U_FrtNFe quando estao sendo usadas rotinas de safra.
// 03/02/2021 - Robert  - Para saber se estava gerando contranota de safra, testava rotina U_VA_RUS. Passa a testar U_VA_RUSN.
// 08/10/2021 - Robert  - Desabilitados alguns logs desnecessarios.
// 13/12/2021 - Robert  - Pequena melhoria msg. alter.vlr.unit em relacao ao pedido de compra.
// 23/12/2021 - Claudia - Incluida validação de almox 11. GLPI: 7665
// 14/07/2022 - Robert  - Removidas linhas comentariadas.
// 

// -----------------------------------------------------------------------------------------------------------------------
User Function MT100TOK()
	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lRet      := ParamIxb[1]
	local _nLinha	 := 0
	Private _aMatriz := {}
	Public _nRegZZX  := 0  // Deixar como 'public' para ser vista em outros pontos de entrada.
    Public _vVlrTot  := 0
    Public _vVlrMerc := 0

    if ISINCALLSTACK("MATA920") // Nota fiscal manual de saida
    	u_log ('[' + procname () + '] estou em NF manual saida')
		u_logFim ()
		return(.T.)
	endif  
   
	if ISINCALLSTACK("LJCANCNFCE") // esse teste foi feito pq estava dando erro no JOB do CUPOM - não entendi pq o executa este ponto de entrada mas resolveu
    	u_log ('[' + procname () + '] estou em LJCancNFCE')
		u_logFim ()
	   return(.T.)
	endif
	
	if ISINCALLSTACK("SPEDINUT") // esse teste foi feito pq estava dando erro no SPED ao transmitir uma inutilizacao
    	u_log ('[' + procname () + '] estou em SPEDINUT')
		u_logFim ()
	   return(.T.)
	endif	   

	if _lRet = .T.
		_lRet = _ValParc()
	endif
	
	if ISINCALLSTACK("ZZX") // possibilitar abrir a tela de nota e pre nota sem as validacoes - quando for salvar o documento ai ele vai fazer as validacoes
		// preciso testar se eh a pre-nota
		if ISINCALLSTACK("MATA140")
			u_log ('[' + procname () + '] estou em pre-nota')
			u_logFim ()
			return(.T.)
		endif	
	endif	   
	
    // Atribui valor total na variável para comparação posterior
    _vVlrTot  := MaFisRet(,"NF_TOTAL")       
    
	// Se Nao For Devolucao / Beneficiamento
	If _lRet .and. !(cTipo $ "D/B")
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+cA100For+cLoja,.F.)
		If !Found()
			u_help ("Fornecedor nao encontrado: " + cA100For+"/" + cLoja,, .t.)
			_lRet = .F.
		Endif
	Endif
	
	if _lRet .and. ! cTipo $ "BD"
		_mlCfopFre  := GetMv("ML_CFOPFRE")
		For _nLinha := 1 to Len(aCols)
			
			// Valida se a Linha Nao estiver deletada
			If !GDDeleted( _nLinha ) .And. _lRet
				_xCOD     := GDFieldGet( "D1_COD"     , _nLinha )
				_xQUANT   := GDFieldGet( "D1_QUANT"   , _nLinha )
				_xTES     := GDFieldGet( "D1_TES"     , _nLinha )
				_xCF      := GDFieldGet( "D1_CF"      , _nLinha )
				
				// Valida Especie (Fretes)
				If Alltrim(cEspecie) $ "CTR/CTE" .And. _lRet
					If !(Alltrim(_xCF) $ _mlCfopFre)//GetMv("ML_CFOPFRE"))
						_lRet = U_MsgNoYes ("Parametro ML_CFOPFRE: Incoerencia entre a Especie (frete) da NF e o CFOP utilizado na NF. Confirma assim mesmo?")
					Endif
				Endif
				
				// Valida Especie (Fretes)
				If ! Alltrim(cEspecie) $ "CTR/CTE" .And. _lRet
					If (Alltrim(_xCF) $ _mlCfopFre) //GetMv("ML_CFOPFRE"))
						_lRet = U_MsgNoYes ("Parametro ML_CFOPFRE: Incoerencia entre a Especie (nao frete) da NF e o CFOP utilizado na NF. Confirma assim mesmo?")
					Endif
				Endif
				// valida TES de FRETE apenas para documento do tipo CTE ou CTR
				_wfrete = fBuscaCpo ('SF4', 1, xfilial('SF4') + _xTES, "F4_FRETE")
				if alltrim (cEspecie) $ "CTR/CTE"
					if _wfrete != '1'
						u_help ("Tipo de documento é FRETE, porém TES não é de FRETE. Verifique!")
						_lRet = .F.
					endif
				else
					if _wfrete = '1'
						u_help ("Tipo de documento NÃO é FRETE, porém TES é de FRETE. Verifique!")
						_lRet = .F.
					endif
				endif
			Endif
		Next
	endif
	
	// Testes ref. controle de fretes.
	if _lRet .and. ! cTipo $ "BD" .and. cNumEmp == "0101"
		if ! IsInCallStack ("U_VA_RUSN")  // Nao precisa perder tempo com contranotas de safra.
			_lRet = U_FrtNFE ("V")
		endif
	endif
	
	// Verificacoes para NF-e
	if _lRet .and. cFormul == "S" .and. cEspecie != "SPED"
		
		// Testa se passou pela rotina MSGETDAUTO por que este ponto de
		// entrada eh executado tambem no momento que o usuario seleciona a opcao 'Retornar'.
		If ! IsInCallStack ("MSGETDAUTO")
			u_help ("Para notas de entrada com formulario proprio a especie deve ser SPED.")
			_lRet = .F.
		endif
	endif
	
	// Verifica preenchimento da chave da NFe
	if _lRet
		// Testa se estah sendo chamado dentro da rotina 'Retornar'. Nao testa MSGETDAUTO por que esta
		// funcao eh chamada somente para a geracao dos itens.
		If ! IsInCallStack ("A103PROCDV") //MSGETDAUTO")  // A103DEVOL
			_lRet = _ValChvNFe ()
		endif
	endif

	// Validacoes com o XML do fornecedor.
	if _lRet .and. cFormul != "S" // .and. ! IsInCallStack ("ZZX")
		_lRet = _ValXML ()
	endif
	
	// Validacoes itens controlados policia federal
	if _lRet
		_lRet = _ValCtrPF ()
	endif
	
	// Validacoes tamanho do numero da nota. Usa o campo de formulario proprio por que este ponto de entrada
	// eh chamado durante o preenchimento dos dados na opcao 'retornar' e, nesse momento, a variavel cFormul
	// tem conteudo 'S' (o P.E. permite a inclusao). Se, quando o usuario confirmar a tela, ainda estiver
	// com 'S', o numero serah gerado correto automaticamente. Se o usuario tiver mudado para 'N', entao
	// verificarei o preenchimento do campo.
	if _lRet .and. cFormul != 'S'
		if LEN(ALLTRIM(CNFISCAL))!=tamsx3("F1_DOC")[1]
			u_help ("Numero da nota fiscal deve ser totalmente preenchido.")
			_lRet = .F.
		endif
	endif
	
	// Valida NF origiem
	if _lRet 
		_lRet = _ValNfOri ()
	endif

	// valida local de estoque 11
	if _lRet
		_lRet = _ValAlmox11()
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)

Return(_lRet)
//
// --------------------------------------------------------------------------
//validacao da condicao de pagamento
static function _ValParc ()
	local _lRet 	:= .T.
	local _sMsg 	:= ""
	local _nLinha	:= 0
				
	For _nLinha := 1 to Len(aCols)
		// Valida se a Linha Nao estiver deletada
		If !GDDeleted( _nLinha ) .And. _lRet
			if ! empty (GDFIELDGET('D1_PEDIDO',_nLinha))
				SC7->(DBSETORDER(1))
				if SC7->(DBSEEK(xfilial('SC7') + GDFIELDGET('D1_PEDIDO',_nLinha) + GDFIELDGET('D1_ITEMPC',_nLinha)))
					if ! alltrim (cCondicao) = alltrim(SC7->C7_COND)
						_sMsg = "Linha " + cvaltochar (_nLinha) + ": condicao de pagamento nao pode ser diferente da condicao do pedido de compra (" + sc7 -> c7_cond + ")."
						exit
					endif
					//Permite ajustar diferenca de valor unitário
					if ABS ((GDFIELDGET('D1_VUNIT',_nLinha) - SC7->C7_PRECO) * 100 / SC7->C7_PRECO) > 5
						_sMsg = "Alteração de valor unitario (em relacao ao pedido de compra) acima do percentual permitido."
						exit
					endif
				endif
			endif
		endif
	next
	if ! empty (_sMsg)
		if U_ZZUVL ('091', __cUserId, .F.)
			_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
		else
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verifica preenchimento da chave NFe.
static function _ValCtrPF ()
	local _lRet      := .T.
	local _cTransp   := iif (type ("aNFeDANFe") == "A", aNFeDANFe [1], "")
	local _wi		 := 0
	
	if _lRet .and. val(_cTransp) = 0
		_wexigetransp = ''
		For _wi := 1 to Len(aCols)
			// Valida se a Linha Nao estiver deletada
			If !GDDeleted( _wi)
				_xCOD  := GDFieldGet( "D1_COD" , _wi )
				_wexigetransp = fBuscaCpo ('SB1', 1, xfilial('SB1') + _xCOD, "B1_CTRPF")
				if _wexigetransp = '1'
					exit
				endif
			endif
		Next				
    	
    	if _wexigetransp = '1'
			u_help ("Existem itens controlados pela Policia Federal. É obrigatorio informar o TRANSPORTADOR.")
			_lRet = .F.
		endif
	endif 

return _lRet
//
// --------------------------------------------------------------------------
// Verifica preenchimento da chave NFe.
static function _ValChvNFe ()
	local _lRet      := .T.
	local _oSQL      := NIL
	local _sChvNFe   := iif (type ("aNFeDANFe") == "A", aNFeDANFe [13], "")
	local _sCNPJ     := ""
	local _nTamDoc   := tamsx3 ("F1_DOC")[1]
	local _sNumNF    := ""
	local _lDeveTer  := .F.
	local _sCGCEmit  := ''

	// Verifica se esta nota deve ou nao ter a chave informada.
	if _lRet
		if cFormul == "S" .or. ! alltrim (cEspecie) $ "SPED/CTE"
			_lDeveTer = .F.
		else
			_lDeveTer = .T.
		endif
	endif
	
	if ! _lDeveTer .and. ! empty (_sChvNFe)
		u_help ("Chave NF-e NAO deve ser informada para esta especie de documento")
		_lRet = .F.
		return _lRet
	endif

	if _lDeveTer .and. len (alltrim (_sChvNFe)) != 44
		u_help ("Chave da NF-e incompleta ou nao informada")
		_lRet = .F.
		return _lRet
	endif

	if _lDeveTer .and. substr (_sChvNFe, 3, 4) != substr (dtos (dDEmissao), 3, 4)
		u_help ("Ano e mes (AAMM) de emissao nao conferem com a chave da NFe (" + substr (_sChvNFe, 3, 4) + ").")
		_lRet = .F.
		return _lRet
	endif
	
	if _lDeveTer 
		if cTipo $ "D/B"
			_sCNPJ = fBuscaCpo ("SA1", 1, xfilial ("SA1") + cA100For + cLoja, "A1_CGC")
		else
			_sCNPJ = fBuscaCpo ("SA2", 1, xfilial ("SA2") + cA100For + cLoja, "A2_CGC")
		endif
		
		if _sCNPJ != substr (_sChvNFe, 7, 14)
			// so testa a inconsistencia de CNPJ se nao for a excecao das notas avulsas
			if !cSerie $ "890#891#892#893#894#895#896#897#898#899"
				// Exceção 7: Escrituração de documentos emitidos por terceiros: os casos de escrituração de documentos fiscais 
				//            emitidos por terceiros, inclusive NF-e, como por ex. o consórcio constituído nos termos do 
				//            disposto nos Art. 278 e 279 da Lei nº 6.404, de 15 de dezembro de 1976, e das NF-e “avulsas” 
				//            emitidas pelas UF (séries 890 a 899) devem ser informados como emissão de terceiros, com o 
				//            código de situação do documento igual a “08 - Documento Fiscal emitido com base em Regime Especial ou Norma Específica”.  
				if aviso ("Inconsistencia chave x CNPJ", ;
		              "O CNPJ do cliente/fornecedor (" + _sCNPJ + ") nao confere com o que consta na chave da NFe (" + substr (_sChvNFe, 7, 14) + "). Isso ocorre raramente, por exemplo em casos de NF avulsa. Confirma a digitacao?", ;
		              {"Confirma", "Cancela"}, ;
		              3, ;
		              "Verificacao chave NF-e/CT-e") == 2
					_lRet = .F.
					return _lRet
				endif
			endif				
		endif
	endif
	
	if _lDeveTer .and. cvaltochar (val (substr (_sChvNFe, 23, 3))) != cvaltochar (val (cSerie))
		u_help ("Serie da NF nao confere com a chave da NFe (" + cvaltochar (val (substr (_sChvNFe, 23, 3))) + ")")
		_lRet = .F.
		return _lRet
	endif
	
	if _lDeveTer 
		_sNumNF = substr (_sChvNFe, 26 + (9 - _nTamDoc), _nTamDoc)
		if _sNumNF != cNFiscal
			u_help ("Numero da NF nao confere com o que consta na chave da NFe (" + _sNumNF + ")")
			_lRet = .F.
			return _lRet
		endif
	endif
	
	if _lDeveTer
		// Verifica existencia da chave em qualquer outra filial.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT 'Filial:' + F1_FILIAL + ' Forn/loja:' + F1_FORNECE + '/' + F1_LOJA + ' NF/serie:' + F1_DOC + '/' + F1_SERIE"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SF1")
		_oSQL:_sQuery +=  " WHERE F1_CHVNFE  = '" + _sChvNFe + "'"
		_oSQL:_sQuery +=    " AND D_E_L_E_T_ = ''"

		// Se estiver classificando pre-nota, deve desconsiderar a propria pre-nota.
		if l103Class
			_oSQL:_sQuery +=  " AND NOT (F1_FILIAL  = '" + cFilAnt  + "'"
			_oSQL:_sQuery +=       " AND F1_DOC     = '" + cNFiscal + "'"
			_oSQL:_sQuery +=       " AND F1_SERIE   = '" + cSerie   + "'"
			_oSQL:_sQuery +=       " AND F1_FORNECE = '" + cA100For + "'"
			_oSQL:_sQuery +=       " AND F1_LOJA    = '" + cLoja    + "')"
		endif
		if ! empty (_oSQL:RetQry ())
			u_help ("Chave NF-e ja existe no banco de dados. Verifique a seguinte NF:" + chr (13) + chr (10) + _oSQL:_xRetQry)
			_lRet = .F.
			return _lRet
		endif
	endif

	// Se for transferencia de filial, exige que a NF tenha chave na filial origem (pode estar nao autorizada ou DANFe nao impresso).
	if ! "TESTE" $ upper (alltrim (getenvserver ()))
		if _lDeveTer .and. ! empty (_sChvNFe)
			if cTipo $ 'B/D'
				_sCGCEmit = fBuscaCpo ("SA1", 1, xfilial ("SA1") + ca100For + cLoja, "A1_CGC")
			else
				_sCGCEmit = fBuscaCpo ("SA2", 1, xfilial ("SA2") + ca100For + cLoja, "A2_CGC")
			endif
			if left (_sCGCEmit, 8) == left (sm0 -> m0_cgc, 8)
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT F2_CHVNFE "
				_oSQL:_sQuery +=   " FROM VA_SM0 SM0,"
				_oSQL:_sQuery +=          RetSQLName ("SF2") + " SF2 "
				_oSQL:_sQuery +=  " WHERE SM0.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND SF2.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND SF2.F2_FILIAL  = SM0.M0_CODFIL"
				_oSQL:_sQuery +=    " AND SF2.F2_DOC     = '" + cNFiscal  + "'"
				_oSQL:_sQuery +=    " AND SF2.F2_SERIE   = '" + cSerie    + "'"
				_oSQL:_sQuery +=    " AND SM0.M0_CODIGO  = '" + cEmpAnt   + "'"
				_oSQL:_sQuery +=    " AND SM0.M0_CGC     = '" + _sCGCEmit + "'"
				_oSQL:Log ()
				if empty (_oSQL:RetQry ())
					u_help ("Nota fiscal nao tem chave gravada na filial de origem. Verifique se a mesma encontra-se autorizada junto a SEFAZ e se o DANFe foi impresso.")
					_lRet = .F.
				endif
			endif
		endif 
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verifica dados no XML do fornecedor, caso esteja disponivel.
static function _ValXML ()
	local _sXML      := ""
	local cError     := ""
	local cWarning   := ""
	local _oXml      := NIL
	local _oXmlOri   := NIL
	local _sQuery    := ""
	local _nRetQry   := 0
	local _lRet      := .T.
	local _lContinua := .T.
	local _aUF       := {}
    local _IEFor     := ''     
    local _lRet2     := .T.  
    local _nNota	 := 0      

	// Tenta buscar pela chave da NF-e, em qualquer filial.
	if _lRet .and. type ("aNFeDANFe") == "A" .and. ! empty (aNFeDANFe [13])
		_sQuery := ""
		_sQuery += " SELECT R_E_C_N_O_"
		_sQuery +=   " FROM " + RetSQLName ("ZZX") + " ZZX "
		_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
		_sQuery +=    " AND ZZX_CHAVE  = '" + alltrim (aNFeDANFe [13]) + "'"
		_sQuery +=    " AND ZZX_LAYOUT IN ('CTe', 'NFe', 'enviNFe', 'procCTe', 'procNFe')"      

		_nRetQry = U_RetSQL (_sQuery)

		// se nao encontrar o XML, nao permite continuar obriga que exista o XML na ZZX para dar entrada no documento 
		if _nRetQry = 0
			u_help ("XML da NF-e/CT-e referenciada NAO ENCONTRADA na nossa base de dados (tabela ZZX). Não é permitido incluir NF-e/CT-e sem XML. Providencie o XML")
			_lRet = .F.
			_lContinua = .F.
		endif
		// Se encontrou pela chave da NF-e, verifica os demais dados.
		if _nRetQry > 0
			_nRegZZX = _nRetQry
			zzx -> (dbgoto (_nRetQry))
			if _lContinua .and. zzx -> zzx_filial != xfilial ("ZZX")
				u_help ("XML da NF-e/CT-e referenciada por esta chave destina-se `a filial '" + zzx -> zzx_filial + "'")
				_lRet = .F.
				_lContinua = .F.
			endif
			if _lContinua .and. (zzx -> zzx_TipoNF != cTipo) .and. ! alltrim (cEspecie) $ "CTR/CTE"
				// Teste desabilitado para notas de retorno do deposito - Coop. Alianca.
				if ! (sm0 -> m0_cgc == '88612486000160' .and. zzx -> zzx_clifor == '011863' .and. zzx -> zzx_loja == '01')
					u_help ("XML da NF-e/CT-e referenciada por esta chave destina-se a documentos do tipo '" + zzx -> zzx_tiponf + "'.")
					_lRet = .F.
					_lContinua = .F.
				endif
			endif
			if _lContinua .and. (zzx -> zzx_clifor != ca100for .or. zzx -> zzx_loja != cLoja)
				u_help ("XML da NF-e/CT-e referenciada por esta chave destina-se ao cliente/fornecedor '" + zzx -> zzx_clifor + '/' + zzx -> zzx_loja + "' e deve ser digitada com tipo '" + zzx -> zzx_tiponf + "'.")
				_lRet = .F.
				_lContinua = .F.
			endif
			if _lContinua .and. (right (zzx -> zzx_doc, len (cNFiscal)) != cNFiscal .or. zzx -> zzx_serie != cSerie)
				u_help ("XML da NF-e/CT-e referenciada por esta chave destina-se `a NF/serie '" + right (zzx -> zzx_doc, len (cNFiscal)) + '/' + zzx -> zzx_serie + "'")
				_lRet = .F.
				_lContinua = .F.
			endif
		// Se nao encontrou pela chave da NF-e, tenta buscar pelo numero da nota, fornecedor, etc.
		else
			_sQuery := ""
			_sQuery += " SELECT R_E_C_N_O_"
			_sQuery +=   " FROM " + RetSQLName ("ZZX") + " ZZX "
			_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
			_sQuery +=    " AND ZZX_FILIAL  = '" + xfilial ("ZZX") + "'"
			_sQuery +=    " AND ZZX_CLIFOR  = '" + ca100For + "'"
			_sQuery +=    " AND ZZX_LOJA    = '" + cLoja   + "'"
			_sQuery +=    " AND ZZX_DOC    like '%" + cNFiscal + "'"  // Usa 'like' para casos onde o campo F1_DOC estiver menor que o ZZX_DOC
			_sQuery +=    " AND ZZX_SERIE   = '" + cSerie  + "'"
			_sQuery +=    " AND ZZX_TIPONF  = '" + cTipo + "'"
			_nRetQry = U_RetSQL (_sQuery)
		endif
	endif

	if _nRetQry > 0 .and. _lContinua
		_nRegZZX = _nRetQry
		zzx -> (dbgoto (_nRetQry))

		// Cria objeto XML para leitura dos dados.
		_sXML = MSMM (zzx -> zzx_CodMem,,,,3)
		if empty (_sXML)
			u_help ("Encontrei a chave, mas o conteudo do XML desta nota encontra-se vazio na tabela ZZX. Verifique possibilidade de reimportar o XML dessa nota.")
			_lRet = .F.
			_lContinua = .F.
		endif
		if _lContinua
			_oXmlOri := XmlParser(_sXML, "_", @cError, @cWarning)
			If !Empty (cError)
				u_help (cError)
				_lRet = .F.
				_lContinua = .F.
			EndIf
			If !Empty (cWarning)
				u_help (cWarning)
				_lRet = .F.
				_lContinua = .F.
			EndIf
			If XMLError () != 0
				u_help ("Erro na geracao do objeto XML. As validacoes do XML nao poderao ser feitas.")
				_lRet = .F.
				_lContinua = .F.
			endif
		endif
	else
		_lContinua = .F.
	endif

	// Verifica a especie digitada com o Layout do arquivo (tipo de documento XML).
	//if _lContinua .and. upper (alltrim (zzx -> zzx_layout)) == "PROCNFE/NFE/ENVINFE" .and. alltrim (cEspecie) != "SPED"
	if _lContinua .and. upper (alltrim (zzx -> zzx_layout)) == "PROCNFE/NFE/ENVINFE" .and. alltrim (cEspecie) != "SPED"
		u_help ("Layout do XML referente a esta nota ('" + alltrim (zzx -> zzx_layout) + "') exige que seja usada especie 'SPED'.")
		_lRet = .F.
		_lContinua = .F.
	endif
	
	if _lContinua .and. upper (alltrim (zzx -> zzx_layout)) == "PROCCTE/CTE" .and. alltrim (cEspecie) != "CTE"
		u_help ("Layout do XML referente a esta nota ('" + alltrim (zzx -> zzx_layout) + "') exige que seja usada especie 'CTE'.")
		_lRet = .F.
		_lContinua = .F.
	endif

	// Verifica o Layout (tipo de documento XML) e separa a parte do XML que interessa.
	
	if _lContinua
		do case
		case upper (alltrim (zzx -> zzx_layout)) == "PROCNFE"
			_oXml = _oXmlOri:_nfeProc:_NFe:_infNfe
		case upper (alltrim (zzx -> zzx_layout)) == "NFE"
			_oXml = _oXmlOri:_NFe:_infNfe
		case upper (alltrim (zzx -> zzx_layout)) == "PROCCTE"
			_oXml = _oXmlOri:_cteProc:_CTe:_infCte
		case upper (alltrim (zzx -> zzx_layout)) == "CTE"
			_oXml = _oXmlOri:_CTe:_infCte
		case upper (alltrim (zzx -> zzx_layout)) == "ENVINFE"

			// Como este tipo de documento pode ter mais de uma nota, percorre os elementos
			// ateh encontrar a nota correta (para cada nota do XML foi gerado um registro
			// no ZZX e, agora, estah sendo processado apenas um desses registros do ZZX).
			if valtype (_oXmlOri:_enviNFe:_NFe) != "A"  // Havia apenas uma nota
				// Transforma o nodo em array
				XmlNode2Arr (_oXmlOri:_enviNFe, "_enviNFe")
			endif
			for _nNota = 1 to len (_oXmlOri:_enviNFe:_NFe)
				if _oXmlOri:_enviNFe:_NFe[_nNota]:_ide:_serie:TEXT     == zzx -> zzx_serie ;
					.and. _oXml:_enviNFe:_NFe[_nNota]:_emit:_CNPJ:TEXT == zzx -> zzx_clifor ;
					.and. _oXml:_enviNFe:_NFe[_nNota]:_ide:_cNF:TEXT   == zzx -> zz_doc ;
					.and. _oXml:_enviNFe:_NFe[_nNota]:_dest:_CNPJ:TEXT == sm0 -> m0_cgc
					_oXml = _oXmlOri:_enviNFe:_NFe[_nNota]:_infNFe
					exit
				endif
			next

		otherwise
			u_help ("Layout de XML desconhecido na rotina " + procname () + ". As validacoes do XML nao poderao ser feitas.")
			_lContinua = .F.
		endcase
	endif

	if _lContinua .and. valtype (_oXml) == NIL
		_lContinua = .F.
	endif

	if _lContinua .and. zzx -> zzx_TipoNF == "D"
		_lContinua = .F.
	endif

	if _lContinua
		aadd (_aUF, {"RO","11"})
		aadd (_aUF, {"AC","12"})
		aadd (_aUF, {"AM","13"})
		aadd (_aUF, {"RR","14"})
		aadd (_aUF, {"PA","15"})
		aadd (_aUF, {"AP","16"})
		aadd (_aUF, {"TO","17"})
		aadd (_aUF, {"MA","21"})
		aadd (_aUF, {"PI","22"})
		aadd (_aUF, {"CE","23"})
		aadd (_aUF, {"RN","24"})
		aadd (_aUF, {"PB","25"})
		aadd (_aUF, {"PE","26"})
		aadd (_aUF, {"AL","27"})
		aadd (_aUF, {"MG","31"})
		aadd (_aUF, {"ES","32"})
		aadd (_aUF, {"RJ","33"})
		aadd (_aUF, {"SP","35"})
		aadd (_aUF, {"PR","41"})
		aadd (_aUF, {"SC","42"})
		aadd (_aUF, {"RS","43"})
		aadd (_aUF, {"MS","50"})
		aadd (_aUF, {"MT","51"})
		aadd (_aUF, {"GO","52"})
		aadd (_aUF, {"DF","53"})
		aadd (_aUF, {"SE","28"})
		aadd (_aUF, {"BA","29"})
		aadd (_aUF, {"EX","99"})
	endif
    
	if _lContinua .and. upper (alltrim (zzx -> zzx_Layout)) $ 'PROCNFE/NFE/ENVINFE' //.and. zzx -> zzx_versao $ '1.10/2.00'

		// Fazer as validacoes de NFe aqui
		if XmlChildEx (_oXML:_ide, "_DEMI") != NIL .and. dDEmissao != stod (strtran (_oXml:_ide:_dEmi:TEXT, '-', ''))
			u_help ("Data de emissao: no XML consta " + _oXml:_ide:_dEmi:TEXT)
			_lRet = .F.
		elseif XmlChildEx (_oXML:_ide, "_DHEMI") != NIL .and. dDEmissao != stod (strtran (left (_oXml:_ide:_dhEmi:TEXT, 10), '-', ''))
			u_help ("Data de emissao: no XML consta " + left (_oXml:_ide:_dhEmi:TEXT, 10))
			_lRet = .F.
		endif
               
        _IEFor := ''       
        If !(cTipo $ "D/B")
           DbSelectArea("SA2")
           DbSetOrder(1)
           DbSeek(xFilial("SA2")+cA100For+cLoja,.F.)
           _IEFor := SA2->A2_INSCR          
        else
           DbSelectArea("SA1")
           DbSetOrder(1)
           DbSeek(xFilial("SA1")+cA100For+cLoja,.F.)
           _IEFor := SA1->A1_INSCR          
        Endif

		if !cSerie $ "890#891#892#893#894#895#896#897#898#899"
    		if _IEFor != _oXml:_emit:_IE:TEXT
		   		u_help ("Inscricao Estadual do Fornecedor: no XML consta " + _oXml:_emit:_IE:TEXT + " Verifique!!")
           		if GetMv("VA_VALXML")
  	          		_lRet := .F.		
  	       		endif   
        	endif
		endif     
		
		if !cTipo $ "I/P"
           // valida total da nota 
           if _vVlrTot != val (_oXml:_total:_ICMSTot:_vNF:TEXT) 
           		if ! GetMv("VA_VALXML")
              		_lRet2 = msgnoyes ("Total da Nota: no XML consta " + cvaltochar (val (_oXml:_total:_ICMSTot:_vNF:TEXT)) + ". Deseja continuar assim mesmo?","AVISO")
			  		if _lRet .AND. !_lRet2 
			     		_lRet := .F.		
			  		endif
		   		else
               		u_help ("Total da Nota: no XML consta " + cvaltochar (val (_oXml:_total:_ICMSTot:_vNF:TEXT)) + ". Verifique!")
 		      		u_help ("Total da Nota: no sistema    " + cvaltochar (_vVlrTot))
 		      		_lRet := .F.		
		   		endif
			endif		   			
		endif
		
	elseif _lContinua .and. upper (alltrim (zzx -> zzx_Layout)) $ 'PROCCTE/CTE'
	
		// Fazer as validacoes de CT-e aqui
		if XmlChildEx (_oXML:_ide, "_DEMI") != NIL .and. dDEmissao != stod (strtran (_oXml:_ide:_dEmi:TEXT, '-', ''))
			u_help ("Data de emissao: no XML consta " + _oXml:_ide:_dEmi:TEXT)
			_lRet = .F.
		elseif XmlChildEx (_oXML:_ide, "_DHEMI") != NIL .and. dDEmissao != stod (strtran (left (_oXml:_ide:_dhEmi:TEXT, 10), '-', ''))
			u_help ("Data de emissao: no XML consta " + left (_oXml:_ide:_dhEmi:TEXT, 10))
			_lRet = .F.
		endif
      
        // valida total da nota 
        if _vVlrTot != val (_oXml:_vPrest:_vTPrest:TEXT)
   			u_help ("Total do CTE: no XML consta " + cvaltochar (val (_oXml:_vPrest:_vTPrest:TEXT)) + ". Verifique!")
      		u_help ("Total do CTE: no sistema    " + cvaltochar (_vVlrTot))
      		_lRet := .F.		
   		endif		   				
	endif
                                                            
    if ! GetMv("VA_VALXML")
       if _lContinua .and. ! _lRet
	      if aviso ("Inconsistencias com o XML", ;
		            "Foram encontradas inconsistencias entre os dados digitados e o XML enviado pelo emitente deste documento. Deseja inclui-lo mesmo assim?", ;
		           {"Incluir", "Corrigir"}, ;
		             3, ;
		            "Inconsistencias com o XML") == 1
			 _lRet = .T.
		  endif
	   endif
    else 
       if _lContinua .and. ! _lRet
  	      u_help ("Parametro que nao permite inclusao de NF com XML com inconsistencias esta ativo. Corrija os problemas para prosseguir.")
		  _lContinua = .F.    
  	      _lRet = .F. 
  	   endif   
    endif
return _lRet
//
// --------------------------------------------------------------------------
// Valida NF Origem
static function _ValNfOri ()
	local _lRet   := .T.
	local _nLinha := 0
	local _sNfOri := ""

	// SEFAZ (nao permite mais de uma NF-e referenciada (msg percebida em 25/05/18)
	if cTipo == 'C' .and. cFormul == "S" .and. cEspecie == "SPED"
		for _nLinha = 1 to len (aCols)
			if ! GDDeleted (_nLinha) .And. ! empty (GDFieldGet ("D1_NFORI", _nLinha))
				if ! empty (_sNfOri) .and. GDFieldGet ("D1_NFORI", _nLinha) != _sNfOri
					u_help ("SEFAZ nao autoriza mais de uma NF-e referenciada para NF-e complementar. Informe apenas uma NF de origem.")
					_lRet = .F.
					exit
				endif
				_sNfOri = GDFieldGet ("D1_NFORI", _nLinha)
			endif
		next
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Valida Almox 11
static function _ValAlmox11()
	Local _x    := 0
	Local _lRet := .T.

	for _x := 1 to Len(aCols)
		// Valida se a Linha Nao estiver deletada
		if !GDDeleted(_x) .and. _lRet 
			if alltrim(GDFIELDGET('D1_LOCAL',_x)) == '11'
				u_help("Não é permitida a utilização do almoxarifado 11!")
				_lRet := .F.
			endif
		endif
	next
return _lRet
