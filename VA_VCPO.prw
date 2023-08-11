// Programa..: VA_VCpo
// Autor.....: Robert Koch
// Data......: 23/07/2008
// Descricao.: Validacoes diversas para campos do sistema.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #validacao_de_campo
// #Descricao         #Velidacoes de campos diversas
// #PalavasChave      #validacao
// #TabelasPrincipais 
// #Modulos           
//
// Historico de alteracoes:
// 28/07/2008 - Robert - Incluidas validacoes para os campos do DA1.
// 27/08/2008 - Robert - Incluida validacao para o campo C5_PEDCLI.
// 29/08/2008 - Robert - Incluida validacao para o campo B1_vaEANUn
// 16/09/2008 - Robert - Incluida validacao para acl_valipr, acl_codpro, c5_vaverba, cj_vaverba.
// 18/09/2008 - Robert - Incluida validacao para duplicidade do b1_vaeanun e b1_vaduncx.
// 08/10/2008 - Robert - Validava codigo EAN e DUN do produto mesmo quando estavam vazios.
// 22/10/2008 - Robert - Validacao campo(s) A1_VAEAN
// 19/02/2009 - Robert - Validacao campo(s) ZZ5_CODLOJ e ZZ5_QTLOJA.
// 07/04/2009 - Robert - Validacao campo(s) D3_TM.
// 22/04/2009 - Robert - Validacao campo(s) ZZ3_ITEM.
// 15/05/2009 - Robert - Validacao campo(s) C5_VADCO.
// 24/06/2009 - Robert - Validacao campo(s) B1_CODPAI.
// 07/07/2009 - Robert - Validacao campo(s) D3_COD e D1_MOTDEV.
// 08/07/2009 - Robert - Validacao campo(s) ZZZ_07SIMI.
// 16/07/2009 - Robert - Criado campo ZX5_02ATIV.
//                     - Removida validacao campo(s) ZZZ_07SIMI.
// 22/07/2009 - Robert - Passa a usar a funcao U_Help para as mensagens.
// 23/07/2009 - Robert - Validacao campo(s) ZV_PRODUTO, ZU_VEND.
// 16/12/2009 - Robert - Validacao campo(s) D1_COD e L2_PRODUTO migrada de outros programas para este.
// 05/02/2009 - Robert - Validacao campo(s) ZD_CPF, ZD_COD, ZD_LOJA.
// 22/02/2010 - Robert - Campo B1_VAFILHO excluido da base de dados.
// 12/03/2010 - Robert - Validacao campo(s) ZE_NFPROD.
// 17/06/2010 - Robert - Validacao campo(s) B1_VAEANUN.
// 05/08/2010 - Robert - Melhoradas validacoes do B1_VAEANUN e B1_VADUNCX ref. 'kits'.
// 15/12/2010 - Robert - Validacao campo(s) B1_MARPR.
//                     - Criado tratamento para campo ZX5_MODO.
// 30/12/2010 - Robert - Validacao campo(s) ZZ2_COD, ZZ2FILI, C5_VAFEMB.
// 04/01/2011 - Robert - Validacao campo(s) da tabela SZ7.
// 06/01/2011 - Robert - Validacao campo(s) ZE_LOCAL.
// 04/02/2011 - Robert - Validacao dos locais de entrega de uva portada para DBF.
// 28/02/2011 - Robert - Validacao para campos de endereco de e-mail.
// 28/02/2011 - Robert - Validacao para campos do arquivo SZI.
// 25/03/2011 - Robert - Validacao de campos de telefone e celular.
// 29/06/2011 - Robert - Validacao do camp ZI_ASSOC deixa de exigir o campo A2_ASSOC='S' (passa a ser feita no prog. SZI).
// 05/07/2011 - Robert - Removida validacao do campo B1_MARPR.
// 06/07/2011 - Robert - Validacao campo C5_CLIENTE.
// 07/07/2011 - Robert - Desabilitada validacao do campo ZI_TM.
// 22/08/2011 - Robert - Verifica existencia do XML do documento de entrada.
// 10/10/2011 - Robert - Validacao dos campos ADB_TES e ADB_TESCOB.
// 26/01/2012 - Robert - Ajuste validacao campo Z2_INCRA.
// 07/05/2012 - Robert - Validacoes codigos produtos Sisdeclara no ZX5.
// 24/05/2012 - Robert - Criada validacao para uso de produtos sem estrutura.
// 28/05/2012 - Robert - Aviso na inclusao de pedido de compra para fornecedor que tem contrato(s) de parceria.
// 07/08/2012 - Robert - Criadas validacoes para campos C3_VANUM, C3_VAZZG e C7_VAZZG.
// 09/08/2012 - Robert - Criadas validacoes para campos A2_vaCBase e A2_vaLBase.
// 13/12/2012 - Elaine - Incluir tratamento para que vendedor nao seja inativo
// 28/12/2012 - Robert - Incluida validacao campos zzk_assoc e zzk_loja.
// 17/01/2013 - Elaine - Incluido tratamento para campo ZX5_17PROD
// 19/02/2013 - Elaine - Incluido tratamento para campo F4_VASISDE - Operacoes Sisdeclara Granel
// 12/03/2013 - Elaine - Incluido tratamento para campo F4_VASISEN - Operacoes Sisdeclara Engarrafados
// 12/07/2013 - Leandro - Validacao para que somente as filiais 04/14/15 possam ser utilizadas no campo C5_VAFEMB
// 03/04/2014 - Leandro - Campo DB_LOCALIZ - não permite enderecar dois produtos no mesmo lugar
// 22/07/2014 - Catia   - Campo ZA4_CLI
// 20/08/2014 - Catia   - Campo ZA6_CLI
// 27/01/2015 - Robert  - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT
// 27/04/2015 - Robert  - Desabilitada verificacao do campo B1_UENPROD na validacao do ZZ5_CODLOJ.
// 14/01/2016 - Catia   - Validacoes campo A2_AGENCIA e A2_NUMCON
// 18/03/2016 - Robert  - Mensagem sugerindo quantidade da OP cfe. lote multiplo do produto.
// 14/04/2016 - Robert  - Validacoes campos C2_VAOPESP e B1_VAMAXOP e C6_VAOPT.
// 09/05/2016 - Robert  - Valida duplicidade do campo A1_CGC.
// 19/05/2016 - Robert  - Valida campo A2_VASUBNU.
// 01/09/2016 - Robert  - Valida campo ZX5_08ATIV.
// 11/11/2016 - Robert  - Msg.sugestao qt.OP cfe. lt. mult. do produto passa a verif. 
//                        tambem lote da revisao componente, quando for o caso.
// 14/11/2016 - Catia   - Validacao com E4_CODIGO - nao pode conter letras
// 16/11/2016 - Catia   - Validacao com E4_CODIGO - tem que ter sempre 3 digitos
// 25/11/2016 - Robert  - Msg.sugestao qt.OP melhorada e migrada para funcao especifica.
//                      - Criada validacao campo C2_VAREVVD.
// 05/12/2016 - Robert  - Ajustes sugestao de quantidade OP cfe. lote componente principal.
// 07/12/2016 - Robert  - Validacoes diversas SC5 e SC6 para integracao com Mercanet.
// 12/12/2016 - Robert  - Valida campos M->BE_LOCALIZ/M->BE_LOCAL para nao repetir tanques em outro almox.
// 08/02/2017 - Robert  - Validacao campo C5_TABELA.
// 14/02/2017 - Julio   - Validacao campo A4_CGC.
// 03/03/2017 - Robert  - Aumentados decimais da mensagem de quant.sugerida para a OP de acordo com o tamanho do lote.
// 22/03/2017 - Julio   - Validacao campo ZAH_BEMCOD.
// 05/04/2017 - Robert  - Validacoes A2_VALATIT e A2_VALONGI.
// 14/04/2017 - Robert  - Nao permite mais reapontar etiqueta (D3_VAETIQ)
// 27/04/2017 - Julio   - Validacao campo NG_INDUSTR.
// 23/06/2017 - Robert  - Permite duplicar C5_PEDCLI quando via rot.automatica pois vai gerar evento 
//                        posteriormente (GLPI 2728)
// 31/07/2017 - Robert  - Permite alterar C5_CONDPAG quando pedido importado do Mercanet 
//                        (pelo menos no inicio da implantacao).
// 17/08/2017 - Robert  - Nao permite mais alterar o campo C2_VAOPESP quando OP ja liberada para producao.
// 02/09/2017 - Robert  - Validacao campos A2_VACAVIS e A2_VALAVIS
// 05/09/2017 - Robert  - Validacao campos C6_VAPBRUT, C6_VAPLIQ, C6_VAQTVOL.
// 11/09/2017 - Robert  - Ajuste validacao campos C6_VAPBRUT, C6_VAPLIQ, C6_VAQTVOL.
// 09/10/2017 - Robert  - Validacao DA261DATA
// 30/11/2017 - Robert  - Permite alterar C5_TPFRETE quando pedido importado do Mercanet 
//                        (pelo menos no inicio da implantacao).
// 06/12/2017 - Robert  - Validacao desconto venda assistida: 5% para associados ateh 31/12/17.
// 21/12/2017 - Robert  - Passa a aceitar movimento 560 para itens do tipo MM (solic. Fernanda Rosa)
// 31/01/2018 - Robert  - Desconsiderava o campo ze_snfprod no teste de duplicidade do ze_nfprod.
// 13/04/2018 - Catia   - liberado o grupo de produtos MR nos movimentos internos movimento 560
// 25/04/2018 - Catia   - Incluida validações no M->ZA4_CLI sobre o codigo e a loja do codigo matriz
// 04/05/2018 - Robert  - Validacao desconto venda assistida: 10% para semana dia das maes 2018.
// 20/06/2018 - Robert  - Validacao desconto venda assistida: 40% para promocao Pipa Store 2018.
// 03/07/2018 - Robert  - Validacao B1_VAEANUN: apenas avisa se jah tiver outro produto com mesmo codigo.
// 28/08/2018 - Catia   - Validacao A5_CODPRF - não pode ser vazio ou em branco
// 30/11/2018 - Catia   - Tirada validacao do A 4 _EMAIL e do A 4 _VAMDANF
// 07/12/2018 - Andre   - Apenas usuarios dos grupos 069 e 015 podem alterar o campo B9_QINI (Saldo inicial)
// 12/12/2018 - Robert  - Validacao do B1_CODPAI passa a apenas avisar quando jah tem vinculo com outro item.
// 08/01/2019 - Andre   - Validacao dos campos TL_DTINICI e TL_DTFIM
// 21/01/2019 - Robert  - Permite alterar o campo C5_BANCO quando o campo C5_CONDPAG contiver '097'.
// 05/02/2019 - Andre   - Removido o produto MANUTENCAO da validacao de estrutura. 
//                        Necessario para O.S de manutencao.
// 01/03/2019 - Robert  - Campo ZF_PRREAL nao pode ser igual ao ZF_PRODUTO
// 31/05/2019 - Robert  - Valida C2_PRODUTO, D4_COD e D4_OP (GLPI 5690).
// 04/07/2019 - Catia   - tirado o tratamento do campo B1 _ SITUACA
// 26/07/2019 - Robert  - Desabilitadas verificacoes B1_VAEANUN e B1_VADUNCX 
//                        (vamos usar campos padrao do sistema) - GLPI 6335.
// 27/08/2019 - Cláudia - Incluida validação de produto na desmontagem (MATA242) (GLPI 4931)
// 17/09/2019 - Robert  - Liberado movimento 020 na validacao do D3_TM ateh termos definicao 
//                        de geracao de estoque 
//                        de borra seca (GLPI 6688).
// 03/10/2019 - Robert  - Bloqueado novamente o TM 020 no D3_TM cfe. resolucao final do chamado 6688.
// 12/11/2019 - Robert  - Tratamento para casos de 'For variable is not Local'
//                      - Validacao campo C5_VAPDFAT
// 03/01/2020 - Robert  - Pega o nome do campo a validar via parametro, caso seja informado.
//                      - Novo parametro na funcao U_Help () que permite identificar se eh erro ou aviso 
//                        (usado inicialmente nas cargas de safra - arquivos SZE e SZF).
// 11/03/2020 - Andre   - Validacao do campo C7_DATPRF
// 12/03/2020 - Robert  - Corta decimais da sugestao de quantidade da OP com base no lote do VD (GLPI 7649).
// 21/03/2020 - Robert  - Removidos tratamentos tabela SZ7.
// 27/03/2020 - Andre   - Alterada validação para requisicao de movimento 560. Incluida pergunta se 
//                        deseja ou não movimentar.
// 14/04/2020 - Robert  - Desfeita alteracao de 12/03 (decimais C2_QUANT)
// 06/05/2020 - Claudia - Incluída validação de desmontagem de componentes. GLPI 7883
// 13/06/2020 - Robert  - Ajustes validacao desmontagem: permite pelo B1_CODPAI somente quando ambos 
//                        itens forem tipo PA.
// 19/06/2020 - Robert  - Validacao desmontagem: criado grupo 098 do ZZU para validar quem pode 
//                        desmontar itens nao relacionados.
// 20/07/2020 - Robert  - Verificacao de acesso para saldos iniciais COM QUANTIDADE: passa a validar 
//                        acesso 108 e nao mais 069.
//                      - Verificacao de acesso de req. para CC de produtos que nao sao de consumo: passa a 
//                        validar acesso 109 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
// 21/07/2020 - Robert  - Removidas validacoes campos tabela ZZ3 (composicao fretes - em desuso).
// 26/08/2020 - Robert  - Liberacao temporaria validacao C6_QTDVEN cfe. GLPI 8375
// 03/09/2020 - Robert  - Liberado movimentar retroativo quando tipo MO (para quando nao havia MO em alguma OP)
// 06/11/2020 - Robert  - Nao valida mais D3_TM '550/560/561/562/563/564/565/566/567/568/569' x grupo 069 do ZZU 
//                        (agora temos cadastro de usuarios x TM)
// 12/01/2021 - Claudia - Retirado programa de criação de saldos por endereço (MATA805) da validação de campo 
//                        DB_LOCALIZ/DB_QUANT. GLPI: 9122
// 14/02/2021 - Robert  - Validacoes do D3_COD para programa MATA242 passadas para U_MTA242V e MT242LOk (GLPI 9388)
//                      - Melhoria envio de avisos para TI.
// 12/04/2021 - Robert  - Incluida chamada da procedure VA_SP_VERIFICA_ESTOQUES (testes iniciais) 
//                        para validacao do D3_COD.
// 09/07/2021 - Robert  - Removida chamada da procedure VA_SP_VERIFICA_ESTOQUES 
//                        (cada tela vai chamar seus ptos.entrada) - GLPI 10464.
// 10/08/2021 - Cláudia - Incluida validação na transferencia, para que crie a movimentação de produtos 
//                        de manutençao no AX 02. GLPI: 10379
// 11/01/2022 - Robert  - Criada validacao campo C1_VANF
// 07/03/2022 - Robert  - Melhorada validacao de etiq.jah apontada/estornada no campo D3_VAETIQ (antes olhava campo ZA1_APONT e agora faz query no SD3).
// 25/03/2022 - Robert  - Validacoes adicionais do campos C2_PRODUTO e D3_VAETIQ - GLPI 11825.
// 16/05/2022 - Robert  - Restaurada valid.etiq.jah apontada (ganta alguns segundos do usuario).
// 15/07/2022 - Robert  - Valida grupo 140 do ZZU no campo D3_VAETIQ.
// 01/08/2022 - Robert  - Criada validacao duplicidade B1_CODBAR (GLPI 11994)
// 25/08/2022 - Robert  - Pequena melhoria mensagem validacao etiqueta (D3_VAETIQ)
// 30/08/2022 - Robert  - Atributo ClsAviso:DestinAvis passa a ser tipo string.
// 01/09/2022 - Robert  - Melhorias ClsAviso.
// 22/09/2022 - Robert  - Validacao do campo C2_VABARCX - GLPI 11994
// 02/10/2022 - Robert  - Removido atributo :DiasDeVida da classe ClsAviso.
// 03/10/2022 - Robert  - Trocado grpTI por grupo 122 no envio de avisos.
// 13/10/2022 - Robert  - Melhorias validacao C2_VABARCX
// 24/10/2022 - Robert  - Passa a validar campo A4_EMAIL.
// 26/10/2022 - Robert  - Valida duplicidade de do B1_CODBAR somente "se nao for tudo zero".
// 05/01/2022 - Robert  - Desabilitada validacao D3_TM x ROTINA, pois agora o
//                        sistema controla acessos por TM x usuario.
// 25/05/2023 - Robert  - Validacao TL_DTINICI e TL_DTFIM aberta para o mes
//                        atual do estoque (desde que tipo insumo = mao de obra)
// 06/07/2023 - Robert  - Validar linhas de envase (campos *_VALINEN) - GLPI 13850
// 10/07/2023 - Claudia - Acrescentado novo campo de tipo de operação sisdevin F4_VASITO. GLPI: 13778
// 04/08/2023 - Robert  - Removidas (estavam em desuso) validacos dos campos M->ZZK_ASSOC/M->ZZK_LOJA
// 09/08/2023 - Robert  - Removida validacao B1_CODBAR (Migrada para PE_MATA010)
//

// -------------------------------------------------------------------------------------------------------------------
user function VA_VCpo (_sCampo)
	local _lRet      := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sQuery    := ""
	local _sRetSQL   := ""
	local _i         := 0
	local _oSQL      := NIL
	local _sMsg      := ""
	local _oAviso    := NIL
	local _aRetSQL   := {}
	local _x         := 0
//	local _aApontEtq := {}

	// Verifica a melhor forma de obter o nome do campo a ser validado.
	if _sCampo == NIL
		_sCampo = alltrim (ReadVar ())
	else
		_sCampo = upper (_sCampo)
	endif

	do case

		case _sCampo $ "CNFISCAL/CSERIE/CA100FOR/CLOJA"  // Cabecalho docto. entrada
			if ! empty (CNFISCAL) .and. ! empty (CA100FOR) .and. ! empty (CLOJA)
				_sQuery := ""
				_sQuery += " SELECT COUNT (*)"
				_sQuery +=   " FROM " + RetSQLName ("ZZX") + " ZZX "
				_sQuery +=  " WHERE D_E_L_E_T_ = ''"
				_sQuery +=    " AND ZZX_FILIAL = '" + xfilial ("ZZX") + "'"
				_sQuery +=    " AND ZZX_CLIFOR = '" + ca100For + "'"
				_sQuery +=    " AND ZZX_LOJA   = '" + cLoja   + "'"
				_sQuery +=    " AND ZZX_DOC    like '%" + cNFiscal + "'"
				_sQuery +=    " AND ZZX_SERIE  = '" + cSerie  + "'"
				_sQuery +=    " AND ZZX_TIPONF = '" + cTipo + "'"
				if U_RetSQL (_sQuery) == 0
					_lRet = U_msgYesNo ("O arquivo XML correspondente a este documento ainda nao foi importado no sistema. Deseja continuar assim mesmo?")
				endif
			endif

		case _sCampo == "M->A1_CGC"
			if ! empty (M->A1_CGC)
				_sQuery := ""
				_sQuery += " select  A1_COD + '/' + A1_LOJA + ' - ' + A1_NOME"
				_sQuery += "   from  " + RetSQLName ("SA1")
				_sQuery += "  where  D_E_L_E_T_ = ''"
				_sQuery += "    and  A1_FILIAL  = '" + xfilial ("SA1") + "'"
				_sQuery += "    and  A1_CGC     = '" + M->A1_CGC + "'"
				_sQuery += "    and  D_E_L_E_T_ = ''"
				_sQuery += "    and (A1_COD    != '" + M->A1_cod   + "'"
				_sQuery += "     or  A1_LOJA   != '" + M->A1_loja  + "')"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty (_sRetSQL)
					U_Help ("Este CNPJ ja se encontra associado ao cliente " + _sRetSQL)
					_lRet = .F.
				endif
			endif

		case _sCampo $ "M->A1_EMAIL/M->A1_VAMDANF/M->A2_EMAIL/M->A2_VAMDANF/M->A2_VAMAIL2/M->A3_EMAIL/M->RA_EMAIL/M->U5_EMAIL/M->A1_VAEMLF/M->A4_EMAIL"
			_lRet = U_MailOk (&(_sCampo))

		case _sCampo $ "M->A1_TEL/M->A2_TEL/M->A1_FAX/M->A2_FAX/M->A2_VACELUL"
			_lRet = _VerTel (&(_sCampo))

		case _sCampo == "M->A1_VAEAN"
			if ! empty (M->A1_VAEAN)
				_sQuery := ""
				_sQuery += " select  A1_COD + '/' + A1_LOJA + ' - ' + A1_NOME"
				_sQuery += "   from  " + RetSQLName ("SA1")
				_sQuery += "  where  D_E_L_E_T_ = ''"
				_sQuery += "    and  A1_FILIAL  = '" + xfilial ("SA1") + "'"
				_sQuery += "    and  A1_VAEAN   = '" + m->A1_VAEAN + "'"
				_sQuery += "    and  D_E_L_E_T_ = ''"
				_sQuery += "    and (A1_COD    != '" + m->A1_cod   + "'"
				_sQuery += "     or  A1_LOJA   != '" + m->A1_loja  + "')"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty (_sRetSQL)
					_lRet = U_MsgNoYes ("Este codigo EAN ja' se encontra associado ao cliente '" + _sRetSQL + "'. Confirma?")
				endif
			endif

		case _sCampo == "M->A1_VAFRNEG"
			_lRet = .T.
			if ascan (UsrRetGrp (__cUserId), '000052') == 0
				u_help ("Campo restrito ao grupo 000052 - Logistica")
				_lRet = .F.
			endif

		case _sCampo $ "M->A2_AGENCIA"
			if ! empty(m->a2_agencia)
				if len(alltrim(m->a2_agencia)) < 5
					u_help ("Deve ser preenchido com zeros a esquerda. Tamanho total de 5 digitos.")
					_lRet = .F.
				endif
			endif

		case _sCampo $ "M->A2_NUMCON"
			if ! empty(m->a2_numcon)
				if '-'$ m->a2_numcon
					u_help ("Caraceter invalido.")
					_lRet = .F.
				endif
			endif

//		case _sCampo $ "M->A2_VACAVIS/M->A2_VALAVIS"
//		if empty (m->a2_vaCAvis) .and. ! empty (m->a2_vaLAvis)
//			u_help ("Codigo deve ser informado antes da loja.")
//			_lRet = .F.
//		endif
//		sa2 -> (dbsetorder (1))
//		if _lRet .and. ! sa2 -> (dbseek (xfilial ("SA2") + m->a2_vaCAvis, .F.))
//			u_help ("Fornecedor '" + m->a2_vaCAvis + "' nao cadastrado!")
//			_lRet = .F.
//		endif
//		if _lRet .and. ! empty (m->a2_vaLAvis)
//			if ! sa2 -> (dbseek (xfilial ("SA2") + m->a2_vaCAvis + m->a2_vaLAvis, .F.))
//				u_help ("Fornecedor/loja '" + m->a2_vaCAvis + '/' + m->a2_vaLAvis + "' nao cadastrado!")
//				_lRet = .F.
//			else
//				if ! u_EhAssoc (m->a2_vaCAvis, m->a2_vaLAvis, dDataBase)
//					u_help ("Avisador informado nao consta como associado nesta data.")
//					_lRet = .F.
//				endif
//			endif
//		endif

		case _sCampo $ "M->A2_VACBASE/M->A2_VALBASE"
			if m->a2_vaCBase != m->a2_cod .or. m->a2_vaLBase != m->a2_loja
				if empty (m->a2_vaCBase) .and. ! empty (m->a2_vaLBase)
					u_help ("Codigo deve ser informado antes da loja.")
					_lRet = .F.
				endif
				sa2 -> (dbsetorder (1))
				if _lRet .and. ! sa2 -> (dbseek (xfilial ("SA2") + m->a2_vaCBase, .F.))
					u_help ("Fornecedor '" + m->a2_vaCBase + "' nao cadastrado!")
					_lRet = .F.
				endif
				if _lRet .and. ! empty (m->a2_vaLBase)
					if ! sa2 -> (dbseek (xfilial ("SA2") + m->a2_vaCBase + m->a2_vaLBase, .F.))
						u_help ("Fornecedor/loja '" + m->a2_vaCBase + '/' + m->a2_vaLBase + "' nao cadastrado!")
						_lRet = .F.
					else
						if sa2 -> a2_cgc != m->a2_cgc
							u_help ("CNPJ/CPF do fornecedor/loja '" + m->a2_vaCBase + '/' + m->a2_vaLBase + "' (" + alltrim (sa2 -> a2_cgc) + ") e´ diferente do fornecedor atual (" + alltrim (sa2 -> a2_cgc) + "). Entendo que nao se trate da mesma pessoa.")
							_lRet = .F.
						endif
					endif
				endif
			endif

		case _sCampo $ "M->A2_VALATIT/M->A2_VALONGI"
			for _i = 1 to len (alltrim (&(_sCampo)))
				if ! substr (&(_sCampo), _i, 1) $ '1234567890-.'
					u_help ("Informar somente numeros. O caracter '" + substr (&(_sCampo), _i, 1) + "' nao e´ valido.")
					_lRet = .F.
					exit
				endif
			next

		case _sCampo == "M->A4_CGC"
			if ! empty(M->A4_CGC)
				_sQuery := ""
				_sQuery += " select  A4_COD + ' - ' + A4_NOME"
				_sQuery += "   from  " + RetSQLName("SA4")
				_sQuery += "  where  D_E_L_E_T_ = ''"
				_sQuery += "    and  A4_FILIAL  = '" + xFilial("SA4") + "'"
				_sQuery += "    and  A4_CGC     = '" + M->A4_CGC + "'"
				_sQuery += "    and  A4_COD    <> '" + M->A4_COD + "'"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty(_sRetSQL)
					U_Help ("Este CNPJ ja´ se encontra associado a transportadora '" + AllTrim(_sRetSQL))
					_lRet = .F.
				endif
			endif

		case _sCampo == "M->A5_CODPRF"
			if empty(M->A5_CODPRF)
				U_Help ("Deve ser informado o codigo do produto do fornecedor.")
				_lRet = .F.
			endif


		case _sCampo == "M->TL_DTINICI"
			if _lRet
				if M->TL_TIPOREG == 'M'  // Mao de obra
					if M->TL_DTINICI < getmv ("MV_ULMES") .or. dDataBase > date ()
						U_Help ("Para mao de obra, a data inicial nao pode ser menor do que o ultimo mes fechado, e nem futura.")
						_lRet = .F.
					endif
				else
					if M->TL_DTINICI < Date() -3 .or. dDataBase > date ()
						U_Help ("Data inicial nao pode ser menor do que 3 dias da data de hoje.")
						_lRet = .F.
					endif
				endif
			endif

		case _sCampo == "M->TL_DTFIM"
//			if _lRet .and. (M->TL_DTFIM < Date() -3 .or. dDataBase > date ())
//				U_Help ("Data final nao pode ser menor do que 3 dias da data de hoje.")
//				_lRet = .F.
//			endif
			if _lRet
				if M->TL_TIPOREG == 'M'  // Mao de obra
					if M->TL_DTFIM < getmv ("MV_ULMES") .or. dDataBase > date ()
						U_Help ("Para mao de obra, a data final nao pode ser menor do que o ultimo mes fechado, e nem futura.")
						_lRet = .F.
					endif
				else
					if M->TL_DTFIM < Date() -3 .or. dDataBase > date ()
						U_Help ("Data final nao pode ser menor do que 3 dias da data de hoje.")
						_lRet = .F.
					endif
				endif
			endif

		case _sCampo == "M->ACL_CODPRO" .and. ! GDDeleted ()
			for _i = 1 to len (aCols)
				if ! GDDeleted (_i) .and. ! empty (GDFieldGet ("ACL_VALIPR", _i))
					U_Help ("Ja' existe alguma linha de produto informada. Uma mesma campanha nao pode trabalhar com produtos e com linhas de produtos ao mesmo tempo.")
					_lRet = .F.
					exit
				endif
			next

		case _sCampo == "M->ACL_VALIPR" .and. ! GDDeleted ()
			for _i = 1 to len (aCols)
				if ! GDDeleted (_i) .and. ! empty (GDFieldGet ("ACL_CODPRO", _i))
					U_Help ("Ja' existe algum codigo de produto informado. Uma mesma campanha nao pode trabalhar com produtos e com linhas de produtos ao mesmo tempo.")
					_lRet = .F.
					exit
				endif
			next

		case _sCampo == "M->ADB_TES" .and. ! GDDeleted ()
			if fBuscaCpo ("SF4", 1, xfilial ("SF4") + M->ADB_TES, "F4_ESTOQUE") != 'S' .or. fBuscaCpo ("SF4", 1, xfilial ("SF4") + M->ADB_TES, "F4_DUPLIC") != 'N'
				U_Help ("Venda para entrega futura: TES de remessa deve atualizar estoque e nao deve gerar duplicata.")
				_lRet = .F.
			endif

		case _sCampo == "M->ADB_TESCOB" .and. ! GDDeleted ()
			if fBuscaCpo ("SF4", 1, xfilial ("SF4") + M->ADB_TESCOB, "F4_ESTOQUE") == 'S' .or. fBuscaCpo ("SF4", 1, xfilial ("SF4") + M->ADB_TESCOB, "F4_DUPLIC") == 'N'
				U_Help ("Venda para entrega futura: TES de cobranca nao deve atualizar estoque e deve gerar duplicata.")
				_lRet = .F.
			endif

	// mIGRADO PARA PE_MATA010	case _sCampo == "M->B1_CODBAR"
	// mIGRADO PARA PE_MATA010		if ! empty (m->b1_codbar) .and. ! _SohZeros (m->b1_codbar)
	// mIGRADO PARA PE_MATA010			_oSQL := ClsSQL():New ()
	// mIGRADO PARA PE_MATA010			_oSQL:_sQuery := ""
	// mIGRADO PARA PE_MATA010			_oSQL:_sQuery += " SELECT RTRIM (STRING_AGG (RTRIM (B1_COD) + '-' + RTRIM (B1_DESC), '; '))"
	// mIGRADO PARA PE_MATA010			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB1") + " SB1 "
	// mIGRADO PARA PE_MATA010			_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ = ''"
	// mIGRADO PARA PE_MATA010			_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	// mIGRADO PARA PE_MATA010			_oSQL:_sQuery +=    " AND SB1.B1_CODBAR  = '" + m->b1_codbar + "'"
	// mIGRADO PARA PE_MATA010			_oSQL:_sQuery +=    " AND SB1.B1_COD    != '" + m->b1_cod + "'"
	// mIGRADO PARA PE_MATA010			_oSQL:Log ()
	// mIGRADO PARA PE_MATA010			_sMsg = _oSQL:RetQry (1, .f.)
	// mIGRADO PARA PE_MATA010			if ! empty (_sMsg)
	// mIGRADO PARA PE_MATA010				U_Help ("Codigo de barras ja informado para o(s) seguinte(s) produto (s): " + _sMsg,, .t.)
	// mIGRADO PARA PE_MATA010				_lRet = .F.
	// mIGRADO PARA PE_MATA010			endif
	// mIGRADO PARA PE_MATA010		endif


		case _sCampo == "M->B1_CODPAI"
			if ! empty (M->B1_CODPAI) .and. M->B1_GRUPO != '0400'  // Uvas tem mais de um pai (organ/bordadura, etc.)
				_sQuery := ""
				_sQuery += " select TOP 1 B1_COD"
				_sQuery += "   from " + RetSQLName ("SB1")
				_sQuery += "  where D_E_L_E_T_  = ''"
				_sQuery += "    and B1_FILIAL   = '" + xfilial ("SB1") + "'"
				_sQuery += "    and B1_CODPAI   = '" + m->B1_CODPAI + "'"
				_sQuery += "    and B1_COD     != '" + m->B1_COD + "'"
				_sRetSQL = alltrim (U_RetSQL (_sQuery))
				if ! empty (_sRetSQL)
					_lRet = U_MsgNoYes ("Este codigo pai ja' se encontra associado ao(s) produto(s) '" + alltrim (_sRetSQL) + "'. Confirma assim mesmo?")
				endif
			endif

/* Campos nao existem mais
		case _sCampo $ "M->B1_VACSDAL/M->B1_VACSDLV/M->B1_VACSDJC/M->B1_VACSDSP/M->B1_VACSDSA"
			_sQuery := ""
			_sQuery += " select count (ZX5_FILIAL)"
			_sQuery += "   from " + RetSQLName ("ZX5")
			_sQuery += "  where D_E_L_E_T_ = ''"
			_sQuery += "    and ZX5_FILIAL = (SELECT CASE ZX5_MODO WHEN 'C' THEN '  ' ELSE '" + cFilAnt + "' END"
			_sQuery +=                        " FROM " + RetSQLName ("ZX5")
			_sQuery +=                       " WHERE D_E_L_E_T_ = ''"
			_sQuery +=                         " AND ZX5_FILIAL = '  '"
			_sQuery +=                         " AND ZX5_TABELA = '00'"
			_sQuery +=                         " AND ZX5_CHAVE  = '12')"
			_sQuery += "    and ZX5_TABELA = '12'"
			// Campo excluido --> _sQuery += "    and ZX5_12COOP = '" + right (alltrim (_sCampo), 2) + "'"
			_sQuery += "    and ZX5_12COD = '" + &(_sCampo) + "'"
			if U_RetSQL (_sQuery) == 0
				U_Help ("Codigo do Sisdeclara nao cadastrado para esta filial. Verifique tabela 12 das tabelas genericas.")
				_lRet = .F.
			endif
*/

		case _sCampo $ "M->B1_VALINEN/M->C2_VALINEN/M->C4_VALINEN/M->G5_VALINEN/M->HC_VALINEN"
			sh1 -> (dbsetorder (1))
			if ! sh1 -> (dbseek (xfilial ("SH1") + &(_sCampo), .F.))
				u_help ("Recurso nao cadastrado na tabela SH1.",, .t.)
				_lRet = .F.
			else
				if sh1 -> h1_valinen != 'S'
					u_help ("Este recurso nao trata-se de uma linha de envase.",, .t.)
					_lRet = .F.
				endif
			endif


		case _sCampo $ "M->B1_VARMAAL"
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " select count (*)"
			_oSQL:_sQuery += "   from " + RetSQLName ("ZX5")
			_oSQL:_sQuery += "  where D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "    and ZX5_FILIAL = (SELECT CASE ZX5_MODO WHEN 'C' THEN '  ' ELSE '" + cFilAnt + "' END"
			_oSQL:_sQuery +=                        " FROM " + RetSQLName ("ZX5")
			_oSQL:_sQuery +=                       " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                         " AND ZX5_FILIAL = '  '"
			_oSQL:_sQuery +=                         " AND ZX5_TABELA = '00'"
			_oSQL:_sQuery +=                         " AND ZX5_CHAVE  = '08')"
			_oSQL:_sQuery += "    and ZX5_TABELA = '08'"
			_oSQL:_sQuery += "    and ZX5_08ATIV = 'S'"
			_oSQL:_sQuery += "    and ZX5_08MARC = '" + m->b1_varmaal + "'"
			if _oSQL:RetQry () == 0
				_lRet = U_MsgNoYes ("Registro nao encontrado ou inativo (tabela 08 do arquivo ZX5). Confirma assim mesmo?")
			endif

		case _sCampo $ "M->BE_LOCALIZ/M->BE_LOCAL"
			if m->be_vatanq == 'S'
				if left(m->be_localiz,3)!="T"+cFilAnt
					u_help ("Para tanques deve ser usado o padrao Txx<numero_tanque> onde xx = codigo filial.")
					_lRet = .F.
				endif
				if _lRet .and. ! empty (M->BE_LOCALIZ) .and. ! empty (M->BE_LOCAL)
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT COUNT (*)"
					_oSQL:_sQuery +=   " FROM " + RetSQLName ("SBE")
					_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=    " AND BE_FILIAL  = '" + xfilial ("SBE") + "'"
					_oSQL:_sQuery +=    " AND BE_LOCALIZ = '" + m->be_localiz + "'"
					_oSQL:_sQuery +=    " AND BE_LOCAL  != '" + m->be_local + "'"
					if _oSQL:RetQry (1, .f.) > 0
						u_help ("Este codigo de tanque ja existe em outro almoxarifado.")
						_lRet = .F.
					endif
				endif
			endif


		case _sCampo $ "M->C1_VANF"
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT STRING_AGG (C1_NUM, ',')"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC1")
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND C1_FILIAL  = '" + xfilial ("SC1") + "'"
			_oSQL:_sQuery +=    " AND C1_FORNECE = '" + GDFieldGet ("C1_FORNECE") + "'"
			_oSQL:_sQuery +=    " AND C1_VANF    = '" + m->c1_vanf + "'"
			_sRetSQL := alltrim (_oSQL:RetQry ())
			if ! empty (_sRetSQL)
				_lRet = U_MsgNoYes ("Este numero de NF ja foi informado nas seguintes solicitacoes: " + alltrim (_sRetSQL) + ". Confirma assim mesmo?")
			endif


		case _sCampo $ "M->C2_PRODUTO/M->DA1_CODPRO"
			if alltrim (&(_sCampo)) != 'MANUTENCAO' //necessario para O.S de manutencao.
				sg1 -> (dbsetorder (1))
				if ! sg1 -> (dbseek (xfilial ("SG1") + &(_sCampo), .T.))
					_lRet = U_MsgNoYes ("O produto '" + alltrim (&(_sCampo)) + "' nao tem estrutura no sistema. Sugere-se cadastrar sua estrutura antes de usa-lo aqui. Confirma o uso deste produto assim mesmo?")
				endif
				if fBuscaCpo ("SB1", 1, xfilial ("SB1") + m->c2_produto, 'B1_GRUPO') == '3001'
					u_help ('Itens do grupo de reprocesso nao devem ser produzidos por OP. Somente por transferencia')  // GLPI 5690
					_lRet = .F.
				endif
				if _lRet .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + m->c2_produto, 'B1_VAFULLW') == 'S'
					if ! U_SB1PEF (m->c2_produto)
						u_help ('Produto foi configurado para integrar com FullWMS no campo B1_VAFULLW (' + alltrim (RetTitle ("B1_VAFULLW")) + '), mas ainda falta algum cadastro para poder enviar as etiquetas para o FullWMS.',, .t.)
						_lRet = .F.
					endif
				endif
			endif


		case _sCampo == "M->C2_QUANT"
			_lRet = _ValQtLote ()


		case _sCampo == "M->C2_VABARCX"
			// Por enquanto, somente me interessa se o produto da OP vai ser
			// envasado, e vai para FullWMS, pois nesse caso teremos
			// impressao das barras na caixa, e essas barras serao usadas para
			// validar o apontamento das etiquetas. O retorno padrao eh o
			// proprio codigo DUN14 do item, mas o usuario pode alterar depois
			// caso tenha situacoes especiais como licitacoes, etc. que exijam
			// um codigo de barras diferenciado.
			if _lRet
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + M->C2_PRODUTO, .F.))
					u_help ("Produto da OP nao cadastrado!",, .t.)
					_lRet = .F.
				endif
			endif
			if _lRet .and. sb1 -> b1_vafullw != 'S' .and. ! empty (M->C2_VABARCX)
				u_help ("Este campo aplica-se inicialmente apenas a itens que vao ser guardados pelo FullWMS",, .t.)
				_lRet = .F.
			endif
			if _lRet .and. ! empty (M->C2_VABARCX)
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT STRING_AGG (B1_COD, ',')"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB1")
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND B1_FILIAL  = '" + xfilial ("SB1") + "'"
				_oSQL:_sQuery +=    " AND B1_CODBAR  = '" + sb1 -> b1_codbar + "'"
				_oSQL:_sQuery +=    " AND B1_COD    != '" + sb1 -> b1_cod + "'"
				_oSQL:Log ('[' + procname () + ']')
				_sRetSQL = alltrim  (_oSQL:RetQry (1, .f.))
				if ! empty (_sRetSQL)
					u_help ('Encontrados outros produtos com mesmo codigo de barras, o que vai posteriormente impedir o apontamento de producao: ' + _sRetSQL,, .t.)
					_lRet = .F.
				endif
			endif
			
			// Ateh o momento, a unica excecao que tenho sao as licitacoes para
			// o estado de SP, que exigem EAN128
			if _lRet .and. ! empty (M->C2_VABARCX) .and. alltrim (M->C2_VABARCX) != alltrim (sb1 -> b1_codbar)
				if substring (M->C2_VABARCX, 4, len (alltrim (sb1 -> b1_codbar))) == alltrim (sb1 -> b1_codbar)
					_lRet = .T.
				else
					u_help ("O codigo de barras para impressao da caixa deve ser igual ao GTIN do produto ("+ alltrim (sb1 -> b1_codbar) + "). Excecao para licitacoes para SP, onde o codigo GTIN deve iniciar na posicao 4.",, .t.)
					_lRet = .F.
				endif
			endif


		case _sCampo == "M->C2_VAOPESP"
			if altera
				if sc2 -> c2_valibpr == 'S'
					u_help ("OP ja liberada para producao. Alteracao nao permitida.")
					_lRet = .F.
				endif
				if sc2 -> c2_quje != 0
					u_help ("OP ja teve apontamentos. Alteracao nao permitida.")
					_lRet = .F.
				endif
				if _lRet .and. sc2 -> c2_vaopesp $ 'E/T'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := " SELECT COUNT (*)"
					_oSQL:_sQuery +=   " FROM " + RetSqlName ("SD1") + " SD1"
					_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND SD1.D1_FILIAL   = '" + xFilial ("SD1") + "'"
					_oSQL:_sQuery +=    " AND SD1.D1_OP       = '" + m->c2_num + m->c2_item + m->c2_sequen + m->c2_itemgrd + "'"
					if _oSQL:RetQry () > 0
						u_help ("OP envolvendo servicos em / para terceiros: ja´ existe movimentacao de NF de entrada associada a esta OP.")
						_lRet = .F.
					endif
				endif
				if _lRet .and. sc2 -> c2_vaopesp $ 'E/T'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := " SELECT COUNT (*)"
					_oSQL:_sQuery +=   " FROM " + RetSqlName ("SD2") + " SD2"
					_oSQL:_sQuery +=  " WHERE SD2.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND SD2.D2_FILIAL   = '" + xFilial ("SD2") + "'"
					_oSQL:_sQuery +=    " AND SD2.D2_VAOPT    = '" + m->c2_num + m->c2_item + m->c2_sequen + m->c2_itemgrd + "'"
					if _oSQL:RetQry () > 0
						u_help ("OP envolvendo servicos em / para terceiros: ja´ existe movimentacao de NF de saida associada a esta OP.")
						_lRet = .F.
					endif
				endif
			endif

		case _sCampo == "M->C2_VAREVVD"
			sg5 -> (dbsetorder (1))  // G5_FILIAL+G5_PRODUTO+G5_REVISAO+DTOS(G5_DATAREV)
			if ! sg5 -> (dbseek (xfilial ("SG5") + m->c2_vacodvd + m->c2_varevvd, .F.))
				u_help ("Revisao '" + m->c2_varevvd + "' nao cadastrada para o produto '" + alltrim (m->c2_vacodvd) + "'.")
				_lRet = .F.
			else
				if sg5 -> g5_msblql == '1'
					u_help ("Produto '" + alltrim (m->c2_vacodvd) + "': a revisao '" + m->c2_varevvd + "' encontra-se bloqueada.")
					_lRet = .F.
				endif
			endif

		case _sCampo == "M->C5_BANCO"
			_lRet = _ValMNet ()

		case _sCampo == "M->C5_CLIENTE"
			if type ("_sCodRep") == "C"
				if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->c5_cliente, "A1_VEND") != _sCodRep  // Representante
					if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->c5_cliente, "A1_VEND2") != _sCodRep  // Gerente
						U_Help ("Cliente nao pertence a este representante.")
						_lRet = .F.
					endif
				endif
			endif

		case _sCampo $ "M->C5_COMIS1/M->C5_COMIS2/M->C5_COMIS3/M->C5_COMIS4/M->C5_COMIS5"
			_lRet = _ValMNet ()

		case _sCampo == "M->C5_CONDPAG"
			// desabilitado no inicio da implantacao		_lRet = _ValMNet ()

		case _sCampo == "M->C5_EMISSAO"
			_lRet = _ValMNet ()

		case _sCampo == "M->C5_PEDCLI"
			if ! empty (m->c5_cliente)
				_sQuery := ""
				_sQuery += " select count (C5_FILIAL)"
				_sQuery += "   from " + RetSQLName ("SC5")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and C5_FILIAL  = '" + xfilial ("SC5") + "'"
				_sQuery += "    and C5_CLIENTE = '" + m->c5_cliente + "'"
				_sQuery += "    and C5_LOJACLI = '" + m->c5_lojacli + "'"
				_sQuery += "    and C5_PEDCLI  = '" + m->c5_pedcli  + "'"
				if U_RetSQL (_sQuery) > 0
					_lRet = U_MsgNoYes ("Ordem de compra '" + alltrim (m->c5_pedcli) + "' ja' existe para este cliente. Confirma mesmo assim?", .T.)
				endif
			endif

		case _sCampo == "M->C5_TIPO"
			_lRet = _ValMNet ()

		case _sCampo == "M->C5_TPFRETE"
			// desabilitado no inicio da implantacao				_lRet = _ValMNet ()

		case _sCampo == "M->C5_VADCO"
			zz8 -> (dbsetorder (1))
			if ! zz8 -> (dbseek (xfilial ("ZZ8") + M->C5_VADCO, .F.))
				U_Help ("DCO nao cadastrado.")
				_lRet = .F.
			endif
			if _lRet .and. ! zz8 -> zz8_status == "F"
				U_Help ("DCO nao se encontra em fase de faturamento.")
				_lRet = .F.
			endif

		case _sCampo == "M->C5_VAFEMB"
			// 20130712 - para colocar na variavel todas as filiais que sao depositos (04/14/15/...)
			_empdeps := ''
			DbSelectArea('SX5')
			DbSeek(xFilial('SX5') + 'ZS',.f.)
			Do While !eof() .and. xFilial('SX5') + 'ZS' == SX5->X5_FILIAL + SX5->X5_TABELA
				_empdeps += '01'+alltrim(SX5->X5_CHAVE) + '/'
				DbSelectArea('SX5')
				DbSkip()
			EndDo

			if ! IsInCallStack ("U_VA_GNF5")
				_lRet = .F.
				if ! cEmpAnt + m->c5_vaFEmb $ "0101/0103/0105/0106/0107/0108/0109/0110/0111/0112/0113/0114/0201/1001"
					u_help ("Combinacao invalida de de empresa + filial de embarque.")
				elseif cEmpAnt == '01' .and. ! cEmpAnt + m->c5_vaFEmb $ "0101/"+alltrim(_empdeps)
					u_help ("Filial selecionada deve ser 01 ou 14")
				elseif aviso ("Alteracao de filial de embarque", ;
				"Alterando a filial de embarque, a liberacao do pedido devera´ ser refeita. Confirma?", ;
				{"Confirma", "Cancelar"}, ;
				3, ;
				"Alteracao de filial de embarque") == 1
					U_GrvLibPV (.F.)
					_lRet = .T.
				endif
			endif

		case _sCampo $ "M->C5_VEND1/M->C5_VEND2/M->C5_VEND3/M->C5_VEND4/M->C5_VEND5"
			if fBuscaCpo ("SA3", 1, xfilial ("SA3") + &(_sCampo), "A3_ATIVO") != "S"  // Representante deve estar ativo
				U_Help ("Representante nao esta´ ativo, verifique!")
				_lRet = .F.
			endif
			if _lRet
				_lRet = _ValMNet ()
			endif

		case _sCampo $ "M->C6_COMIS1/M->C6_COMIS2/M->C6_COMIS3/M->C6_COMIS4/M->C6_COMIS5"
			_lRet = _ValMNet ()

		case _sCampo == "M->C6_PRCVEN"
			_lRet = _ValMNet ()

		case _sCampo == "M->C6_PRODUTO"
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + M->C6_PRODUTO, .F.))
				U_Help ("Produto nao cadastrado.")
				_lRet = .F.
			endif
		
			if _lRet
				_lRet = _ValMNet ()
			endif

		case _sCampo == "M->C6_QTDVEN"
			if date () >= stod ('20200826') .and. date () <= stod ('20200904')
				_lRet = .T.
			else
				_lRet = _ValMNet ()
			endif

		case _sCampo == "M->C6_VAOPT"
			sc2 -> (dbsetorder (1))
			if ! sc2 -> (dbseek (xfilial ("SC2") + M->C6_VAOPT, .F.))
				U_Help ("OP nao cadastrada.")
				_lRet = .F.
			else
				if ! sc2 -> c2_vaOPEsp $ 'E/T'
					u_help ("OP nao tem finalidade de terceirizacao.")
					_lRet = .F.
				endif
			endif
			if _lRet
				_lRet = _ValMNet ()
			endif

		case _sCampo $ "M->C6_VAPLIQ/M->C6_VAPBRU"
			if left (GDFieldGet ('C6_PRODUTO'), 1) != '8' .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ('C6_PRODUTO'), "B1_TIPO") $ 'PA/'
				u_help ("Informacao manual de pesos nao permitida para este tipo de produto.")
				_lRet = .F.
			else
				if ! GDFieldGet ("C6_VAALTVP") $ 'AP'
					_lRet = u_msgyesno ("Se voce informar este campo manualmente, os pesos deste item nao serao mais calculados automaticamente. Confirma?", .T.)
				endif
			endif

		case _sCampo $ "M->C6_VAQTVOL"
			if left (GDFieldGet ('C6_PRODUTO'), 1) != '8' .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ('C6_PRODUTO'), "B1_TIPO") $ 'PA/'
				u_help ("Informacao manual de volumes nao permitida para este tipo de produto.")
				_lRet = .F.
			else
				if ! GDFieldGet ("C6_VAALTVP") $ 'AV'
					_lRet = u_msgyesno ("Se voce informar este campo manualmente, os volumes deste item nao serao mais calculados automaticamente. Confirma?", .T.)
				endif
			endif

		case _sCampo == "M->C7_PRECO"
			if ! empty (CA120Forn) .and. ! empty (gdfieldget("C7_PRODUTO")) .and. m->c7_preco != 0
				_aPreco := {}
				_aQuery := {}
				_sQuery := ""
				_msg	:= ""
				_lRet 	:= .T.

				_sQuery += "SELECT TOP 2 C7_PRECO, C7_NUM, C7_FORNECE, C7_LOJA "
				_sQuery += "FROM " + RetSQLName ("SC7") + " SC7 "
				_sQuery += "WHERE D_E_L_E_T_ = '' "
				_sQuery += "AND C7_PRODUTO = '" + gdfieldget("C7_PRODUTO",n) + "' "
				_sQuery += "ORDER BY C7_EMISSAO DESC"

				_aQuery := U_Qry2Array (_sQuery)

				if len(_aQuery) > 1
					for _i = 1 to len(_aQuery)
						if M->C7_PRECO > _aQuery[_i][1]
							_cNomFor := Posicione("SA2",1,xFilial("SA2")+_aQuery[_i][3]+_aQuery[_i][4],"A2_NREDUZ")
							aadd(_aPreco,{_aQuery[_i][1], _aQuery[_i][2], _cNomFor})
						endif
					next _i
				endif

				if len(_aPreco) > 1
					_msg := 'Preco unitario do produto "' + alltrim(gdfieldget("C7_PRODUTO",n)) + '" nas duas ultimas compras foi menor do que o digitado, conforme segue abaixo. Deseja continuar com esse preco ? ' + chr(13) + chr(10)
					_msg += chr(13) + chr(10)
					for _i = 1 to len(_aPreco)
						_msg += "Pedido: " + alltrim(_aPreco[_i][2]) + "     Preco: " + alltrim(transform (_aPreco[_i][1], "@E 9,999,999.99")) + "     Fornecedor: " + alltrim(_cNomFor) + chr(13) + chr(10)
					next
				endif

				if len(_aPreco) > 1
					if U_MsgYesNo(_msg)
						_lRet := .T.
					else
						_lRet := .F.
					endif
				endif
			endif

		case _sCampo == "CA120FORN"  // Fornecedor no pedido de compras.
			if nTipoPed != 2  // Ped. compra
				_sQuery := ""
				_sQuery += " select COUNT (*)"
				_sQuery += "   from " + RetSQLName ("SC3")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and C3_FILIAL  = '" + xfilial ("SC3") + "'"
				_sQuery += "    and C3_FORNECE = '" + &(_sCampo) + "'"
				_sRetSQL = U_RetSQL (_sQuery)
				if _sRetSQL > 0
					U_Help ("LEMBRETE: Este fornecedor possui contratos de parceria. Verifique possibilidade de uso de autorizacao de entrega.")
				endif
			endif

		case _sCampo $ "M->C3_VANUM"
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT DISTINCT 'Contr:' + SC3.C3_NUM + ' Forn:' + SC3.C3_FORNECE + '/' + SC3.C3_LOJA + ' - ' + RTRIM (SA2.A2_NOME)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC3") + " SC3, "
			_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
			_oSQL:_sQuery +=  " WHERE SC3.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SC3.C3_FILIAL  = '" + xfilial ("SC3") + "'"
			_oSQL:_sQuery +=    " AND SC3.C3_VANUM   = '" + &(_sCampo) + "'"
			_oSQL:_sQuery +=    " AND SC3.C3_NUM    != '" + CA125NUM + "'"
			_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
			_oSQL:_sQuery +=    " AND SA2.A2_COD     = SC3.C3_FORNECE"
			_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = SC3.C3_LOJA"
			if ! empty (_oSQL:Qry2Str (1, chr (13) + chr (10)))
				_lRet = U_MsgNoYes ("Contrato numero '" + &(_sCampo) + "' ja´ consta no(s) seguinte(s) contrato(s) de parceria:" + chr (13) + chr (10) + _oSQL:_xRetQry + chr (13) + chr (10) + "Confirma assim mesmo?")
			endif


		case _sCampo $ "M->C5_VAPDFAT"
			// Procura buscar todas as informacoes necessarias numa unica query.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*) AS PEDIDO,"
			_oSQL:_sQuery +=        " SUM (CASE WHEN SC5.C5_LIBEROK != '' THEN 1 ELSE 0 END) AS LIBERADO,"  // Vazio=ainda nao tem 'liberacao comercial' (SC9 gerado).
			_oSQL:_sQuery +=        " SUM (CASE WHEN SC5.C5_CLIENTE = '" + m->c5_cliente + "' AND SC5.C5_LOJACLI = '" + m->c5_loja + "' THEN 1 ELSE 0 END) AS CLIENTE,"
			_oSQL:_sQuery +=        " SUM (CASE WHEN SC5.C5_NOTA LIKE 'XXXXXX%' THEN 0 ELSE 1 END) AS RES_ELIM,"  // Residuo eliminado (nao sei por que as vezes grava com 9 e as vezes com 6 posicoes)
			_oSQL:_sQuery +=        " SUM (CASE WHEN SF4.F4_MARGEM = '1' THEN 1 ELSE 0 END) AS FATURADO"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC5") + " SC5, "
			_oSQL:_sQuery +=              RetSQLName ("SC6") + " SC6, "
			_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4 "
			_oSQL:_sQuery +=  " WHERE SC5.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SC5.C5_FILIAL  = '" + xfilial ("SC5") + "'"
			_oSQL:_sQuery +=    " AND SC5.C5_NUM     = '" + m->c5_vapdfat + "'"
			_oSQL:_sQuery +=    " AND SC6.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SC6.C6_FILIAL  = SC5.C5_FILIAL"
			_oSQL:_sQuery +=    " AND SC6.C6_NUM     = SC5.C5_NUM"
			_oSQL:_sQuery +=    " AND SF4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
			_oSQL:_sQuery +=    " AND SF4.F4_COD     = SC6.C6_TES"
			_oSQL:Log ()
			_aRetSQL := aclone (_oSQL:RetQry (.F., .F.)[1])
			if _aRetSQL [1] == 0
				u_help ("Pedido de faturamento '" + m->c5_vapdfat + "' nao localizado.")
				_lRet = .F.
			elseif _aRetSQL [2] == 0
				u_help ("Pedido de faturamento '" + m->c5_vapdfat + "' ainda nao liberado.")
				_lRet = .F.
			elseif _aRetSQL [3] == 0
				u_help ("Pedido de faturamento '" + m->c5_vapdfat + "' pertence a outro cliente.")
				_lRet = .F.
			elseif _aRetSQL [4] == 0
				u_help ("Pedido de faturamento '" + m->c5_vapdfat + "' teve residuo eliminado.")
				_lRet = .F.
			elseif _aRetSQL [5] == 0
				u_help ("Pedido de faturamento '" + m->c5_vapdfat + "' nao tem TES de faturamento.")
				_lRet = .F.
			endif


		case _sCampo == "M->CJ_TABELA"
			// Verifica se a tabela tem amarracao com o vendedor. Se tivesse amarracao com o cliente,
			// jah teria sido preenchida via gatilho.
			szy -> (dbsetorder (1))  // ZY_FILIAL+ZY_VEND+ZY_FILTAB+ZY_CODTAB
			if ! szy -> (dbseek (xfilial ("SZY") + m->cj_vend1 + xfilial ("DA0") + m->cj_tabela, .F.))
				U_Help ("Tabela de precos deve ter amarracao com o representante. Verifique tabelas disponiveis atraves da tecla F3.", procname ())
				_lRet = .F.
			endif

		case _sCampo == "M->CJ_VAVERBA"
			ack -> (dbsetorder (1))  // ACK_FILIAL+ACK_CODVER+ACK_GRPVEN+ACK_CODVEN+ACK_GRPCLI+ACK_CODCLI+ACK_LOJA+DTOS(ACK_DATINI)+DTOS(ACK_DATFIM)
			if ! ack -> (dbseek (xfilial ("ACK") + M->CJ_VAVERBA, .F.))
				U_Help ("Campanha nao cadastrada.")
				_lRet = .F.
			endif
			if _lRet .and. ! empty (ack -> ack_codcli) .and. m->cJ_cliente + m-> cJ_loja != ack -> ack_codcli + ack -> ack_loja
				U_Help ("Campanha especifica para o cliente " + ack -> ack_codcli + "/" + ack -> ack_loja)
				_lRet = .F.
			endif

		case _sCampo == "DA261DATA"  // Data emissao tela transf mod. II
			_lRet = (da261Data == dDataBase)

		case _sCampo $ "M->D1_COD"
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + M->d1_cod, .F.))
				U_Help ("Produto nao cadastrado.")
				_lRet = .F.
			endif
			
			If _lRet .and. SB1->B1_vaForaL == "S"
				if type ("oMainWnd") == "O"  // Se tem interface com o usuario
					_lRet = U_MsgNoYes ("Produto '" + m->d1_cod + "' fora de linha. Confirma?")
				endif
			endif

		case _sCampo $ "M->D1_MOTDEV"
			_sQuery := ""
			_sQuery += " select count (ZX5_FILIAL)"
			_sQuery += "   from " + RetSQLName ("ZX5")
			_sQuery += "  where D_E_L_E_T_ = ''"
			_sQuery += "    and ZX5_FILIAL = (SELECT CASE ZX5_MODO WHEN 'C' THEN '  ' ELSE '" + cFilAnt + "' END"
			_sQuery +=                        " FROM " + RetSQLName ("ZX5")
			_sQuery +=                       " WHERE D_E_L_E_T_ = ''"
			_sQuery +=                         " AND ZX5_FILIAL = '  '"
			_sQuery +=                         " AND ZX5_TABELA = '00'"
			_sQuery +=                         " AND ZX5_CHAVE  = '02')"
			_sQuery += "    and ZX5_TABELA = '02'"
			_sQuery += "    and ZX5_02ATIV = 'S'"
			_sQuery += "    and ZX5_02MOT  = '" + m->d1_motdev + "'"
			if U_RetSQL (_sQuery) == 0
				U_Help ("Motivo de devolucao nao cadastrado ou inativo.")
				_lRet = .F.
			endif
			
		case _sCampo $ "M->D3_COD"
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + M->d3_cod, .F.))
				U_Help ("Produto nao cadastrado.")
				_lRet = .F.
			endif

			if _lRet .and. sb1 -> b1_msblql == "1"
				U_Help ("Produto bloqueado.")
				_lRet = .F.
			endif
			
			if _lRet .and. sb1 -> b1_vaForaL == "S"
				_lRet = U_MsgYesNo ("Produto fora de linha. Confirma a digitacao?")
			endif

			if _lRet .and. IsInCallStack ("MATA241") .and. cTM == '560'
				if u_zzuvl ('109', __cUserId, .F.)
					if ! sb1 -> b1_tipo $ 'CL/MT/MB/II/MA/EP/MM/MR'
						_lRet = U_MsgNoYes ("Requisicao para CC nao permitida para este tipo de produto. Confirma assim mesmo?")
					endif
				else
					if ! sb1 -> b1_tipo $ 'CL/MT/MB/II/MA/EP/MM/MR'
						_lRet = U_MsgNoYes ("Requisicao para CC nao permitida para este tipo de produto. Confirma assim mesmo?")
					endif
				endif
			endif

			if _lRet .and. (IsInCallStack ("MATA261") .or. IsInCallStack ("MATA260"))
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT "
				_oSQL:_sQuery += " 	  SB1.B1_COD "
				_oSQL:_sQuery += " FROM " + RetSQLName ("SB1") + " AS SB1 "
				_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB2") + " AS SB2 "
				_oSQL:_sQuery += " 	ON SB2.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " 		AND B2_COD = B1_COD "
				_oSQL:_sQuery += " 		AND SB2.B2_QATU > 0
				_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "
				_oSQL:_sQuery += "  AND SB1.B1_COD = '" + m->d3_cod + "'"
				_oSQL:_sQuery += " AND SB1.B1_TIPO in ('MM','MC')  "
				_oSQL:Log ()
				_aSB1:= _oSQL:Qry2Array ()
				
				For _x := 1 to Len(_aSB1)
					CriaSB2 (_aSB1[_x, 1], '02')
				Next
			endif


		case _sCampo $ "M->D3_EMISSAO"
			_lRet = .T.
			if M->D3_EMISSAO != date ()
				if funname () = 'MATA685'  // Tem validacao posterior pelo P.E. MT685TOK.
				elseif funname () = 'MATA241' .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + m->d3_cod, 'B1_TIPO') == 'MO'  // Para nao de obra pode movimentar retroativo.
				else
					_sMsg = "Uso de data retroativa bloqueado para esta rotina."
					if U_ZZUVL ('084', __cUserId, .F.)
						_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
					else
						u_help (_sMsg)
						_lRet = .F.
					endif
				endif
			endif


		case _sCampo == "M->D3_VAETIQ"
				//u_logpcham ()
			za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
			if ! za1 -> (dbseek (xfilial ("ZA1") + m->d3_vaetiq, .F.))
				u_help ("Etiqueta nao encontrada.")
				_lRet = .F.
			endif
			if _lRet .and. za1 -> za1_impres != 'S'
				u_help ("Etiqueta ainda nao impressa.")
				_lRet = .f.
			endif
			if _lRet
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := "SELECT SUM (CASE WHEN D3_ESTORNO != 'S' THEN 1 ELSE 0 END) AS APONTAM"
				_oSQL:_sQuery +=      ", SUM (CASE WHEN D3_ESTORNO  = 'S' THEN 1 ELSE 0 END) AS ESTORNO"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
				_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = '' "
				_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
				_oSQL:_sQuery +=   " AND SD3.D3_VAETIQ  = '" + m->d3_vaetiq + "'"
				_oSQL:_sQuery +=   " AND SD3.D3_CF LIKE 'PR%'"
				//_oSQL:Log ('[' + procname () + ']')
				_aApontEtq = aclone (_oSQL:Qry2Array (.f., .f.))
				if _aApontEtq [1, 1] > 0
					u_help ("Essa etiqueta ja gerou apontamento de producao.",, .t.)
					_lRet = .f.
				endif
				if _aApontEtq [1, 2] > 0
					U_help ("Essa etiqueta ja foi apontada e ESTORNADA. Gere nova etiqueta.",, .t.)
					_lRet = .F.
				endif
			endif
			if _lRet
				// Quero obrigar o pessoal a apontar com coletor, seja web service ou telnet.
				if ! IsInCallStack ("INTEGRAWS") .and. ! IsInCallStack ("U_VTETQAP")
					_lRet = U_ZZUVL ('140', __cUserId, .T.)
				endif
			endif


		case _sCampo $ "M->DB_LOCALIZ/M->DB_QUANT"
			if funname () != 'MATA805' 
				_aQuery := {}
				_aPal := {}

				for _i = 1 to len(aCols)
					if alltrim (M->DB_LOCALIZ) == alltrim(acols[_i][3]) ;
						.and. empty (GDFieldGet ("DB_ESTORNO", _i)) ;
						.and. fBuscaCpo ("SBE", 1, xfilial ("SBE") + m->da_local + GDFieldGet ("DB_LOCALIZ", _i), "BE_VAPROUN") != 'S'
						_lRet = U_MsgNoYes ("Endereco ja informado anteriormente. Confirma assim mesmo?")
					endif
				next _i

				// verifica se o endereco ja esta sendo utilizado
				if _lRet // so faz Validacao se nao achou o mesmo endereco na linha
					_sQuery := ""
					_sQuery += " select BF_QUANT, BF_PRODUTO "
					_sQuery +=   " from " + RetSQLName ("SBF") + " SBF, "
					_sQuery +=              RetSQLName ("SBE") + " SBE "
					_sQuery +=  " where SBF.D_E_L_E_T_  = ''"
					_sQuery +=    " and SBF.BF_FILIAL   = '" + xfilial ("SBF") + "'"
					_sQuery +=    " and SBF.BF_LOCALIZ  = '" + alltrim(M->DB_LOCALIZ) + "'"
					if type ("M->DA_LOCAL") == "C"
						_sQuery +=    " and SBF.BF_LOCAL    = '" + alltrim(M->DA_LOCAL) + "'"
					endif
					if type ("M->DB_LOCAL") == "C"
						_sQuery +=    " and SBF.BF_LOCAL    = '" + alltrim(M->DB_LOCAL) + "'"
					endif
					_sQuery +=    " and SBF.BF_QUANT   != 0"
					_sQuery +=    " and SBE.D_E_L_E_T_  = ''"
					_sQuery +=    " and SBE.BE_FILIAL   = '" + xfilial ("SBE") + "'"
					_sQuery +=    " and SBE.BE_LOCAL    = SBF.BF_LOCAL"
					_sQuery +=    " and SBE.BE_LOCALIZ  = SBF.BF_LOCALIZ"
					_sQuery +=    " and SBE.BE_VAPROUN != 'N'"
					_aQuery := U_Qry2Array(_sQuery)
					if len(_aQuery) > 1
						U_Help("Endereco nao aceita mais de um produto.")
						_lRet := .F.
					elseif len(_aQuery) == 1
						if alltrim(M->DA_PRODUTO) == alltrim(_aQuery[1][2])
							// se for o mesmo produto, verifica se ainda pode transferir quantidade
							_aPal := aclone(U_VA_QTDPAL(M->DA_PRODUTO, 1)) // envia um somente para fazer a Validacao
							if len(_apal) > 0
								if GDFieldGet ("DB_QUANT") > _aPal[1][2]
									U_Help("Quantidade a enderecar maior que o suportado pelo pallet.")
									_lRet := .F.
								endif
							endif
						else
							// se for produto diferente, nao deixa enderecar
							U_Help("Endereco nao aceita mais de um produto.")
							_lRet := .F.
						endif
					endif
				else
					U_Help("Endereco ja existe em uma das linhas acima.")
					_lRet := .F.
				endif
			endif


		case _sCampo $ "M->D4_COD"
			if IsInCallStack ("MATA380") .and. m->d4_cod == fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d4_op, "C2_PRODUTO")
				u_help ("Componente nao pode ser igual ao produto final da OP.")
				_lRet = .F.
			endif
			if IsInCallStack ("MATA381") .and. m->d4_cod == fBuscaCpo ("SC2", 1, xfilial ("SC2") + cOP, "C2_PRODUTO")
				u_help ("Componente nao pode ser igual ao produto final da OP.")
				_lRet = .F.
			endif


		case _sCampo $ "M->D4_OP"
			if IsInCallStack ("MATA380") .and. m->d4_cod == fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d4_op, "C2_PRODUTO")
				u_help ("Componente nao pode ser igual ao produto final da OP.")
				_lRet = .F.
			endif

		case _sCampo $ "M->F4_VASITO"
			if M->F4_TIPO == "E" .AND. !M->F4_VASITO $ getmv("VA_TOSISEN")
				U_Help ("Para TES de Entrada, somente pode ser informada as seguintes operacoes: " + getmv("VA_TOSISEN"))
				_lRet = .F.
			elseif M->F4_TIPO == "S" .AND. !M->F4_VASITO $ getmv("VA_TOSISSA")
				U_Help ("Para TES de Saida, somente pode ser informada as seguintes operacoes: " + getmv("VA_TOSISSA"))
				_lRet = .F.
			endif

		case _sCampo $ "M->L2_PRODUTO"
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + M->l2_produto, .F.))
				U_Help ("Produto nao cadastrado.")
				_lRet = .F.
			endif
			If _lRet .and. SB1->B1_vaForaL == "S"
				u_Help ("Produto '" + m->l2_produto + "' fora de linha.")
				_lRet = .F.
			endif
			if _lRet .and. (sb1 -> b1_locpad != "10" .or. left (m->l2_produto, 1) != "8")
				_lRet = U_MsgNoYes ("O produto nao parece pertencer `a loja. Confirma assim mesmo?")
			endif

		case _sCampo $ "M->LR_DESC"
			_lRet = _ValDescLj ('P')

		case _sCampo $ "M->LR_VALDESC"
			_lRet = _ValDescLj ('V')

		case _sCampo $ "M->N1_VAZX541"
			if empty(M->N1_VAZX541)
				_sQuery := ""
				_sQuery += " select count (ZAH_FILIAL)"
				_sQuery += "   from " + RetSQLName ("ZAH")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and ZAH_FILIAL = '" + xFilial("ZAH") + "'"
				_sQuery += "    and ZAH_CELCOD = '" + AllTrim(M->N1_CBASE) + "'"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty(_sRetSQL)
					U_Help ("Ativo/Maquina " + AllTrim(M->N1_CBASE) + " vinculada a Celula(s) de Producao. Informacao nao pode ser apagada.")
					_lRet = .F.
				endif
			else
				_lRet := U_ExistZX5("41",M->N1_VAZX541)
			endIf

		case _sCampo $ "M->N1_VAZX542"
			if empty(M->N1_VAZX542)
				_sQuery := ""
				_sQuery += " select count (ZAH_FILIAL)"
				_sQuery += "   from " + RetSQLName ("ZAH")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and ZAH_FILIAL = '" + xFilial("ZAH") + "'"
				_sQuery += "    and ZAH_CELCOD = '" + AllTrim(M->N1_CBASE) + "'"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty(_sRetSQL)
					U_Help ("Ativo/Maquina " + AllTrim(M->N1_CBASE) + " vinculada a Celula(s) de Producao. Informacao nao pode ser apagada.")
					_lRet = .F.
				endif
			else
				_lRet := U_ExistZX5("42",M->N1_VAZX542)
			endIf

		case _sCampo $ "M->N1_VAZX543"
			if empty(M->N1_VAZX543)
				_sQuery := ""
				_sQuery += " select count (ZAH_FILIAL)"
				_sQuery += "   from " + RetSQLName ("ZAH")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and ZAH_FILIAL = '" + xFilial("ZAH") + "'"
				_sQuery += "    and ZAH_CELCOD = '" + AllTrim(M->N1_CBASE) + "'"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty(_sRetSQL)
					U_Help ("Ativo/Maquina " + AllTrim(M->N1_CBASE) + " vinculada a Celula(s) de Producao. Informacao nao pode ser apagada.")
					_lRet = .F.
				endif
			else
				_lRet := U_ExistZX5("43",M->N1_VAZX543)
			endIf

		case _sCampo $ "M->N1_VAZX544"
			if empty(M->N1_VAZX544)
				_sQuery := ""
				_sQuery += " select count (ZAH_FILIAL)"
				_sQuery += "   from " + RetSQLName ("ZAH")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and ZAH_FILIAL = '" + xFilial("ZAH") + "'"
				_sQuery += "    and ZAH_CELCOD = '" + AllTrim(M->N1_CBASE) + "'"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty(_sRetSQL)
					U_Help ("Ativo/Maquina " + AllTrim(M->N1_CBASE) + " vinculada a Celula(s) de Producao. Informacao nao pode ser apagada.")
					_lRet = .F.
				endif
			else
				_lRet := U_ExistZX5("44",M->N1_VAZX544)
			endIf

		case _sCampo $ "M->NG_INDUSTR"
			if M->NG_INDUSTR == "N"
				_sQuery := ""
				_sQuery += " select count(N1_GRUPO)"
				_sQuery += "   from " + RetSQLName ("SN1")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and N1_FILIAL  = '" + xFilial("SN1") + "'"
				_sQuery += "    and N1_GRUPO   = '" + AllTrim(M->NG_GRUPO) + "'"
				_sRetSQL = U_RetSQL (_sQuery)
				if ! empty(_sRetSQL)
					U_Help ("Grupo " + AllTrim(M->NG_GRUPO) + " vinculado a Ativos utilizados pelo industrial. Informacao nao pode ser modificada/apagada.")
					_lRet = .F.
				endif
			endif

		case _sCampo $ "M->Z2_INCRA"
			_sQuery := ""
			_sQuery += " select Z2_CADVITI"
			_sQuery += "   from " + RetSQLName ("SZ2")
			_sQuery += "  where D_E_L_E_T_  = ''"
			_sQuery += "    and Z2_FILIAL   = '" + xfilial ("SZ2") + "'"
			_sQuery += "    and Z2_CADVITI != '" + m->z2_cadviti + "'"
			_sQuery += "    and Z2_INCRA    = '" + m->Z2_incra + "'"
			_sRetSQL = U_RetSQL (_sQuery)
			if ! empty (_sRetSQL)
				U_Help ("Numero do INCRA ja consta no cadastro viticola '" + _sRetSQL + "'.")
				_lRet = .F.
			endif


		case _sCampo $ "M->ZA4_CLI"
			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za4_cli, "A1_MSBLQL") = '1'
				U_Help ("Cliente Bloqueado.")
				_lRet = .F.
			endif
			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za4_cli, "A1_VERBA") != '1'
				U_Help ("Cliente nao controla verbas.")
				_lRet = .F.
			endif
			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za4_cli, "A1_VERBA") = '1'
				if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za4_cli, "A1_VACBASE") = ""
					U_Help ("Cliente nao tem codigo MATRIZ associado")
					_lRet = .F.
				endif
				if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za4_cli, "A1_VALBASE") = ""
					U_Help ("Cliente nao tem codigo LOJA MATRIZ associado")
					_lRet = .F.
				endif
			endif

		case _sCampo $ "M->ZA6_CLI"
			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za6_cli, "A1_MSBLQL") = '1'
				U_Help ("Cliente Bloqueado.")
				_lRet = .F.
			endif
			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za6_cli, "A1_VERBA") != '1'
				U_Help ("Cliente nao controla verbas.")
				_lRet = .F.
			endif
			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za6_cli, "A1_VERBA") = '1'
				if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za6_cli, "A1_VACBASE") = ""
					U_Help ("Cliente nao tem codigo MATRIZ associado")
					_lRet = .F.
				endif
				if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za6_cli, "A1_VALBASE") = ""
					U_Help ("Cliente nao tem codigo LOJA MATRIZ associado")
					_lRet = .F.
				endif
			endif

		case _sCampo $ "M->ZA8_COD"
			sz2 -> (dbsetorder (1))  // Z2_FILIAL+Z2_CADVITI
			if ! sz2 -> (dbseek (xfilial ("SZ2") + M->ZA8_COD, .F.))
				u_help ("Nao e' permitido cadastrar propriedades rurais sem que haja um cadastro viticola de mesmo codigo.")
				_lRet = .F.
			endif

		case _sCampo $ "M->ZA9_CLI"
			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za9_cli, "A1_MSBLQL") = '1'
				U_Help ("Cliente bloqueado.")
				_lRet = .F.
			endif

			if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->za9_cli, "A1_COD") = ' '
				U_Help ("Cliente nao cadastrado.")
				_lRet = .F.
			endif

			if fBuscaCpo ("ZA9", 1, xfilial ("ZA9") + _sCodRep + m->za9_cli, "ZA9_PERATE") > '0'
				U_Help ("Dados ja informados para este cliente.")
				_lRet = .F.
			endif

		case _sCampo == "M->ZAH_BEMCOD"
			SN1 -> (dbsetorder (1))
			if ! SN1 -> (dbseek (xfilial ("SN1") + M->ZAH_BEMCOD, .F.))
				U_Help ("Ativo/Maquina " + AllTrim(M->ZAH_BEMCOD) + " nao cadastrada.")
				_lRet = .F.
			else
				if ! SNG -> (dbseek (xfilial ("SNG") + SN1->N1_GRUPO, .F.))
					U_Help ("Grupo de Bens " + AllTrim(SN1->N1_GRUPO) + " nao cadastrado.")
					_lRet = .F.
				else
					if SNG->NG_INDUSTR != "S"
						U_Help ("Grupo " + AllTrim(SN1->N1_GRUPO) + " nao utilizado no industrial.")
						_lRet = .F.
					else
						_sQuery := ""
						_sQuery += " SELECT N3_CUSTBEM"
						_sQuery += "   FROM " + RetSQLName ("SN3")
						_sQuery += "   WHERE D_E_L_E_T_ = ''"
						_sQuery += "   AND N3_CBASE   = " + M->ZAH_BEMCOD
						_sQuery += "   AND N3_TIPO    = '10'"
						_sRetSQL = U_RetSQL(_sQuery)
						if _sRetSQL != _sCenCus
							U_Help ("Maquina pertence ao Centro de Custo '" + _sRetSQL + "'.")
							_lRet = .F.
						endif
					endif
				endif
			endif

		case _sCampo $ "M->ZD_CPF"
		szd -> (dbsetorder (1))  // ZD_FILIAL+ZD_FORNECE+ZD_LOJAFOR+ZD_CPF
		if szd -> (dbseek (xfilial ("SZD") + M->zd_fornece + m->zd_lojafor + m->zd_cpf, .F.))
			U_Help ("CPF ja cadastrado como associado desta cooperativa.")
			_lRet = .F.
		endif

		case _sCampo $ "M->ZD_COD/M->ZD_LOJA"
		szd -> (dbsetorder (3))  // ZD_FILIAL+ZD_FORNECE+ZD_LOJAFOR+ZD_COD+ZD_LOJA
		if szd -> (dbseek (xfilial ("SZD") + M->zd_fornece + m->zd_lojafor + m->zd_cod + m->zd_loja, .F.))
			U_Help ("Codigo de associado ja cadastrado nesta cooperativa.")
			_lRet = .F.
		endif

		case _sCampo == "M->ZE_NFPROD" .and. (inclui .or. altera)  // Na exclusao nao precisa validar nada.
			if LEN(ALLTRIM(m->ze_nfprod))!=tamsx3("ZE_NFPROD")[1]
				u_help ("Numero da NF de produtor deve ter " + cvaltochar (tamsx3("ZE_NFPROD")[1]) + " posicoes (preencher com zeros a esquerda).",, .t.)
				_lRet = .F.
			else
				// Varre as cargas do associado procurando ocorrencias da mesma nota de produtor.
				// Como existe a possibilidade de uso do associado 'generico' (cod. 999999), preciso
				// validar, tambem, pelo nome do associado.
				sze -> (dbsetorder (2))  // ZE_FILIAL+ZE_SAFRA+ZE_COOP+ZE_LOJCOOP+ZE_ASSOC+ZE_LOJASSO
				sze -> (dbseek (xfilial ("SZE") + m->ze_safra + m->ze_coop + m->ze_lojcoop + m->ze_assoc + m->ze_lojasso, .T.))
				do while _lRet ;
				.and. ! sze -> (eof ()) ;
				.and. sze -> ze_filial  == xfilial ("SZE") ;
				.and. sze -> ze_safra   == m->ze_safra ;
				.and. sze -> ze_coop    == m->ze_coop ;
				.and. sze -> ze_lojcoop == m->ze_LojCoop ;
				.and. sze -> ze_assoc   == m->ze_Assoc ;
				.and. sze -> ze_lojAsso == m->ze_LojAsso
					//			if sze -> ze_nfprod == m->ze_NFProd
					//			if sze -> ze_nfprod == m->ze_NFProd .and. sze -> ze_status != 'C'
					if sze -> ze_nfprod == m->ze_NFProd .and. sze -> ze_snfprod == m->ze_SNFProd .and. sze -> ze_status != 'C'
						if m->ze_assoc == "999999"  // Associado 'outros': valida pelo nome.
							_lRet = U_MsgNoYes ("NF de produtor '" + m->ze_NFProd + "' ja informada na carga '" + sze -> ze_carga + "'" + chr (13) + chr (10) + ;
							"em nome de " + sze -> ze_nomasso + chr (13) + chr (10) + ;
							"no dia " + dtoc (sze -> ze_data) + chr (13) + chr (10) + chr (13) + chr (10) + ;
							"Confirma a digitacao assim mesmo?")
						else
							U_Help ("NF de produtor '" + m->ze_NFProd + "' ja informada no dia " + dtoc (sze -> ze_data) + " para a carga '" + sze -> ze_carga + "'",, .T.)
							_lRet = .F.
						endif
					endif
					sze -> (dbskip ())
				enddo
			endif

		case _sCampo == "M->ZE_PESOBRU"
			if type ("_lIntPort") == "L" .and. _lIntPort
				u_help ("Integracao com portaria habilitada. Crie uma 'nova entrada' na rotina de portaria para informar o peso bruto.",, .T.)
				_lRet = .F.
			endif

		case _sCampo == "M->ZE_PESOTAR"
			if IsInCallStack ("U_VA_RUS2") .and. type ("_lIntPort") == "L" .and. _lIntPort
				u_help ("Integracao com portaria habilitada. Use a rotina 'Portaria' para busca do peso tara.",, .T.)
				_lRet = .F.
			endif

		case _sCampo == "M->B9_QINI"
			if ! U_ZZUVL ('108', __cUserId, .F.)
				_lRet = u_msgnoyes ("Saldos iniciais COM QUANTIDADE deveriam ser informados somente no momento de implantacao do sistema. Confirma assim mesmo?")
			endif

		case _sCampo == "M->ZF_PRM02"
			if IsInCallStack ("U_VA_RUS2")
				if fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO"), "B1_VAUVAES") != "S"
					u_help ("Classificacao por grau so' pode ser informada quando a uva destina-se a espumante.",, .T.)
					_lRet = .F.
				endif
			else
				u_help ("Classificacao por grau nao pode ser informada neste momento.",, .T.)
				_lRet = .F.
			endif

		case _sCampo == "M->ZF_PRREAL"
			if M->ZF_PRREAL == m->zf_produto
				u_help (alltrim (RetTitle ("ZF_PRREAL")) + ' nao pode ser a mesma informado no campo ' + alltrim (RetTitle ("ZF_PRODUTO")),, .T.)
				_lRet = .F.
			else
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + m->zf_prreal, .F.)) .or. sb1 -> b1_grupo != '0400'
					u_help ("Produto nao cadastrado (ou nao pertence ao grupo de 'uvas').",, .T.)
					_lRet = .F.
				else
					// Inserir aqui tabela de substituicao de uvas.
				endif
			endif

		case _sCampo $ "M->ZI_ASSOC"
			sa2 -> (dbsetorder (1))
			if ! sa2 -> (dbseek (xfilial ("SA2") + M->zi_assoc, .F.))
				U_Help ("Fornecedor nao cadastrado.")
				_lRet = .F.
			endif

		case _sCampo == "M->ZU_VEND"
			sa3 -> (dbsetorder (1))
			if ! sa3 -> (dbseek (xfilial ("SA3") + &(_sCampo), .F.))
				U_Help ("Vendedor nao cadastrado.")
				_lRet = .F.
			else
				if sa3 -> a3_ativo != "S"
					_lRet = U_MsgYesNo ("Vendedor inativo. Deseja usar assim mesmo?")
				endif
			endif

		case _sCampo == "M->ZV_PRODUTO"
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + &(_sCampo), .F.))
				U_Help ("Produto nao cadastrado.")
				_lRet = .F.
			else
				if sb1 -> b1_vaForaL == "S"
					_lRet = U_MsgYesNo ("Produto fora de linha. Deseja usar assim mesmo?")
				endif
				if _lRet .and. sb1 -> b1_vaGrLp == "99"
					_lRet = U_MsgYesNo ("No cadastro do produto consta grupo para lista de preco (campo '" + alltrim (RetTitle ("B1_VAGRLP")) + "') informado como 'outros'. Deseja usar assim mesmo?")
				endif
				if _lRet .and. empty (sb1 -> b1_vaGrLp)
					U_Help ("Produto nao possui grupo para lista de preco informado no seu cadastro (campo '" + alltrim (RetTitle ("B1_VAGRLP")) + "').")
					_lRet = .F.
				endif
			endif

		case _sCampo == "M->ZX5_17PROD"
			if ! empty(M->ZX5_17PROD)
				// verifica se o B1_GRUPO eh 0400 (0400 = uva)
				_sQuery := ""
				_sQuery += " SELECT B1_COD"
				_sQuery += "   FROM  " + RetSQLName ("SB1")
				_sQuery += "  WHERE  D_E_L_E_T_ = ''"
				_sQuery += "    AND  B1_COD   = '" + M->ZX5_17PROD + "'"
				_sQuery += "    AND  B1_GRUPO = '0400' "
				_sRetSQL = U_RetSQL (_sQuery)
				if empty (_sRetSQL)
					U_Help ("Este Produto nao e uma uva (grupo diferente de 0400)")
					_lRet = .F.
				endif

				if _lRet
					// verifica se a uva eh fina B1_VARUVA = "F"
					_sQuery := ""
					_sQuery += " SELECT B1_COD"
					_sQuery += "   FROM  " + RetSQLName ("SB1")
					_sQuery += "  WHERE  D_E_L_E_T_ = ''"
					_sQuery += "    AND  B1_COD   = '" + M->ZX5_17PROD + "'"
					_sQuery += "    AND  B1_VARUVA = 'F' "
					_sRetSQL = U_RetSQL (_sQuery)
					if empty (_sRetSQL)
						_lRet = U_msgnoyes ("Este Produto nao e uva fina/vinifera. Confirma? ")
					endif
				endif
			endif

		case _sCampo == "_ZZ2COD"
			if ! empty (fBuscaCpo ("ZZ2", 2, xfilial ("ZZ2") + _ZZ2Cod, "ZZ2_COD"))
				U_Help ("Codigo ja' cadastrado.")
				_lRet = .F.
			endif

		case _sCampo == "_ZZ2FILI"
			for _i = 3 to len (alltrim (_zz2Fili)) step 3
				if substr (_ZZ2Fili, _i, 1) != "/"
					U_Help ("Codigos das filiais devem ter 2 posicoes e ser separados por barras (/).")
					_lRet = .F.
				endif
			next

		case _sCampo == "M->ZZ5_CODLOJ"
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + M->zz5_codloj, .F.))
				U_Help ("Produto nao cadastrado.")
				_lRet = .F.
			else
				if sb1 -> b1_vaForaL == "S"
					U_Help ("Produto fora de linha.")
					_lRet = .F.
				else
					if empty (sb1 -> b1_codpai)
						U_Help ("Produto nao possui codigo pai informado (campo '" + alltrim (RetTitle ("B1_CODPAI")) + "').")
						_lRet = .F.
					ENDIF
					//				endif
				endif
			endif

		case _sCampo == "M->ZZ5_QTLOJA"
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + M->zz5_codpai, .F.))
				U_Help ("Produto pai nao cadastrado.")
				_lRet = .F.
			else
				if sb1 -> b1_qtdemb == 0
					U_Help ("Quantidade por embalagem nao informada no produto pai (campo '" + alltrim (RetTitle ("B1_QTDEMB")) + "').")
					_lRet = .F.
				endif
			endif

	//Controle migrado para o NaWeb --->	case _sCampo $ "M->ZZK_ASSOC/M->ZZK_LOJA"
	//Controle migrado para o NaWeb --->		if m->zzk_ano == '2012'
	//Controle migrado para o NaWeb --->			if ! empty (m->zzk_assoc) .and. ! empty (m->zzk_loja) .and. fBuscaCpo ("SA2", 1, xfilial ("SA2") + m->zzk_assoc + m->zzk_loja, "A2_VASTDAP") != "C"
	//Controle migrado para o NaWeb --->				u_help ("Associado deve ter DAP para este ano.")
	//Controle migrado para o NaWeb --->				_lRet = .F.
	//Controle migrado para o NaWeb --->			endif
	//Controle migrado para o NaWeb --->		endif

		case _sCampo $ "M->ZZT_PESENT/M->ZZT_PESSAI"
			if ! empty (m->zzt_safra) .and. ! empty (m->zzt_carga)
				sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
				if sze -> (dbseek (xfilial ("SZE") + m->zzt_safra + m->zzt_carga, .F.))
					if ! empty (sze -> ze_nfger)
						u_help ("A carga ligada a este ticket ja tem contranota gerada.")
						_lRet = .F.
					endif
					if sze -> ze_pesotar != 0
						u_help ("A carga ligada a este ticket ja tem peso tara informado. Zere, antes, o peso tara da carga.")
						_lRet = .F.
					endif
				endif
			endif

		case _sCampo $ "M->E4_CODIGO"
			_wcond = ALLTRIM(M->E4_CODIGO)
			if len (_wcond) !=  3
				U_Help ("Obrigatoriamente usar codigo com 3 digitos")
				_lRet = .F.
			endif

			do case
				case substring(M->E4_CODIGO,1,1) $ "A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/X/W/Y/Z/"
					U_Help ("Nao e´mais permitido cadastrar condicoes de pagamento contendo LETRAS.")
					_lRet = .F.
				case substring(M->E4_CODIGO,2,1) $ "A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/X/W/Y/Z/"
					U_Help ("Nao e´ mais permitido cadastrar condicoes de pagamento contendo LETRAS.")
					_lRet = .F.
				case substring(M->E4_CODIGO,3,1) $ "A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/X/W/Y/Z/"
					U_Help ("Nao e´ mais permitido cadastrar condicoes de pagamento contendo LETRAS.")
					_lRet = .F.

			endcase

		case _sCampo $ "M->E4_MSBLQL"
			if m->e4_msblql != '1'  // Usuario estah desbloqueando. Cond.pag. com letras foram todas bloqueadas no inicio do projeto de implantacao do Mercanet, pois este nao aceita letras.
				if isalpha (substring(M->E4_CODIGO,1,1)) .or. isalpha (substring(M->E4_CODIGO,2,1)) .or. isalpha (substring(M->E4_CODIGO,3,1))
					u_help ("Integracao com Mercanet: nao sera mais permitido uso de letras no codigo da condicao de pagamento.")
					_lRet = .F.
				endif
			endif

		otherwise
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = "Campo '" + _sCampo + "' nao previsto na rotina " + procname ()
			_oAviso:Texto      = _oAviso:Texto
			_oAviso:Origem     = procname ()
			_oAviso:InfoSessao = .T.  // Incluir informacoes adicionais de sessao na mensagem.
			_oAviso:Grava ()

	endcase

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _lRet

// --------------------------------------------------------------------------
static function _VerTel (_sTel)
//	local _lErroTel := .F.
	local _i := 0
	_sTel = rtrim (_sTel)
	if len (_sTel) < 6 .or. len (_sTel) > 14
		u_help ("Telefone deve ter entre 6 e 14 digitos")
		return .F.
	endif
	for _i = 1 to len (_sTel)
		if ! IsDigit (substr (_sTel, _i, 1))
			u_help ("Telefone deve conter apenas numeros")
			return .F.
		endif
	next
return .T.

// --------------------------------------------------------------------------
// Calcula quantidade da OP para fechar com quantidade de lotes.
static function _ValQtLote ()
	local _lRet     := .T.
	local _nQtBase  := 0
	local _oSQL     := NIL
	local _nQtSuger := 0
	local _nQtLotes  := 0
	local _nLoteMult := 0

	sb1 -> (dbsetorder (1))
	if ! empty (m->c2_produto) .and. sb1 -> (dbseek (xfilial ("SB1") + m->c2_produto, .F.))
		_nQtBase = sb1 -> b1_qb
		if _lRet .and. sb1 -> b1_vamaxop > 0 .and. m->c2_quant > sb1 -> b1_vamaxop
			u_help ("Quantidade da OP nao pode ser maior que " + cvaltochar (sb1 -> b1_vamaxop) + " (informado no campo '" + alltrim (RetTitle ("B1_VAMAXOP")) + "' do cadastro do produto).")
			_lRet = .F.
		endif
		if _lRet
			// Para sugestao de quantidade alinhada ao tamanho do lote, busca, antes,
			// o lote da revisao da estrutura do subitem, se tiver.
			_nLoteMult = sb1 -> b1_lm
			_nQtLotes = m->c2_quant / _nLoteMult
			_sMsg = "Lote multiplo de producao informado no campo '" + alltrim (RetTitle ("B1_LM")) + "' do cadastro do produto '" + alltrim (sb1 -> b1_cod) + "' = " + cvaltochar (sb1 -> b1_lm)
			if ! empty (m->c2_vacodvd) .and. ! empty (m->c2_varevvd)
				sg5 -> (dbsetorder (1))  // G5_FILIAL+G5_PRODUTO+G5_REVISAO+DTOS(G5_DATAREV)
				if sg5 -> (dbseek (xfilial ("SG5") + m->c2_vacodvd + m->c2_varevvd, .F.)) .and. sg5 -> g5_valm > 0

					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := " SELECT ISNULL ((SELECT " + cvaltochar (sg5 -> g5_valm) + " / (G1_QUANT * " + cvaltochar (_nQtBase) + ")"
					_oSQL:_sQuery +=                   " FROM " + RetSqlName ("SG1") + " SG1"
					_oSQL:_sQuery +=                  " WHERE SG1.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=                    " AND SG1.G1_FILIAL   = '" + xFilial ("SG1") + "'"
					_oSQL:_sQuery +=                    " AND SG1.G1_COD      = '" + m->c2_produto + "'"
					_oSQL:_sQuery +=                    " AND SG1.G1_COMP     = '" + m->c2_vacodvd + "'"
					_oSQL:_sQuery +=                    " AND SG1.G1_REVINI  <= '" + m->c2_varevvd + "'"
					_oSQL:_sQuery +=                    " AND SG1.G1_REVFIM  >= '" + m->c2_varevvd + "'"
					_oSQL:_sQuery +=               " ), 0)"
					_Osql:lOG ()
					_nLoteMult = _oSQL:RetQry ()
					if _nLoteMult > 0
						_sMsg = "Lote multiplo de producao informado no campo '" + alltrim (RetTitle ("G5_VALM")) + "' do cadastro da revisao '" + m->c2_varevvd + "' do produto '" + alltrim (m->c2_vacodvd) + "' (VD principal) = " + cvaltochar (sg5 -> g5_valm)
						_nQtLotes = m->c2_quant / _nLoteMult
					endif
				endif
			endif
			_nQtSuger = max (1, int (_nQtLotes)) * _nLoteMult
// desfeito em 14/04/20			_nQtSuger = max (1, int (int (_nQtLotes)) * _nLoteMult)  // GLPI 7649
			if _nQtLotes != int (_nQtLotes)
				if m->c2_quant != _nQtSuger  // Para evitar casos em que eu iria sugerir qt. com varios decimais por causa de lotes com decimais, e o usuario jah fez o devido ajuste na quantidade.
					_sMsg += chr (13) + chr (10) + chr (13) + chr (10)
					_sMsg += "A quantidade prevista da OP corresponde a " + alltrim (transform (_nQtLotes, "@E 999999999.9999")) + " lotes."
					_sMsg += chr (13) + chr (10) + chr (13) + chr (10)
					_sMsg += "Sugere-se alterar a quantidade da OP para " + alltrim (transform (_nQtSuger, "@E 999,999,999,999.99")) + " " + sb1 -> b1_um
// desfeito em 14/04/20					_sMsg += "Sugere-se alterar a quantidade da OP para " + alltrim (transform (_nQtSuger, "@E 999,999,999,999")) + " " + sb1 -> b1_um
					_sMsg += chr (13) + chr (10) + chr (13) + chr (10)
					_sMsg += "Confirma assim mesmo?"
					_lRet = U_MsgNoYes (_sMsg)
				endif
			endif
		endif
	endif
return _lRet

// --------------------------------------------------------------------------
// Validacoes para integracao com Mercanet.
static function _ValMNet ()
	local _lRet := .T.

	if ! empty (m->c5_vaPdMer) .and. ! inclui
		if alltrim (ReadVar ()) == 'M->C5_BANCO'
			if m->c5_condpag != '097'
				u_help ("Pedido importado do sistema Mercanet (numero original: " + AllTrim(m->c5_vaPdMer) + "). Alteracao do campo BANCO so deve se feita quando condicao de pagamento a vista.")
				_lRet = .F.
			endif
		else
			U_Help ("Pedido importado do sistema Mercanet (numero original: " + AllTrim(m->c5_vaPdMer) + "). Alteracao de campos chave nao permitida.")
			_lRet = .F.
		endif
	endif

return _lRet
/*
// -------------------------------------------------------------------
// Encontra campos no aHeader
static function _AchaCol (_sCampo, _nQual)
	local _nCol1 := 0
	local _nCol2 := 0
	local _nRet  := 0
	for _nCol1 = 1 to len (aHeader)
		if upper (alltrim (aHeader [_nCol1, 2])) == upper (alltrim (_sCampo))
			if _nQual == 1
				_nRet = _nCol1
				exit
			else
				for _nCol2 = _nCol1 + 1 to len (aHeader)
					if upper (alltrim (aHeader [_nCol2, 2])) == upper (alltrim (_sCampo))
						_nRet = _nCol2
						exit
					endif
				next
				exit
			endif
		endif
	next
	return _nRet
*/
	//--------------------------------------------------------------------
	// valida data de Condicoeso pagamento que obrigatoriamente tem que ser maior do que a data base do sistema

	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("C5_CONPAG"))
		_wTipo = fBuscaCpo ('SE4', 1, xfilial('SE4') + m->c5_cliente + m->c5_lojacli, "SE4_TIPO")
		if _wTipo = '9'
			u_help ("Data do vencimento da parcela deve ser obrigatoriamente maior do que a data base.",, .t.)
			_lRet = .F.
		endif
		if GDFieldGet ("C5_DATA1") < ddatabase
			u_help ("Data do vencimento da parcela deve ser obrigatoriamente maior do que a data base.",, .t.)
			_lRet = .F.
		endif
		if GDFieldGet ("C5_DATA2") < ddatabase
			u_help ("Data do vencimento da parcela deve ser obrigatoriamente maior do que a data base.",, .t.)
			_lRet = .F.
		endif

	endif

// -------------------------------------------------------------------
// Valida desconto item sigaloja.
static function _ValDescLj (_sQual)
	local _lRet  := .F.
	local _nPerc := 0

	if _sQual == 'V'  // Estou no campo do valor. Preciso, entao, calcular o percentual.
		_nPerc = m->lr_valdesc * 100 / (GDFieldGet ("LR_VLRITEM") + m->lr_valdesc)  // Campo LR_VLRITEM jah chega aqui com o desconto.
	else
		_nPerc = m->lr_desc
	endif

	if _nPerc <= 1.5  // Sempre permitido
		_lRet = .T.
	endif
	//	if alltrim (m->lr_produto) $ '8066/8067' .and. _nPerc <= 33.34 .and. date () == stod ('20171124')  // Black friday 24/11/2017
	//		_lRet = .T.
	//	endif
	//	if alltrim (m->lr_produto) $ '8179' .and. _nPerc <= 50 .and. date () == stod ('20171124')  // Black friday 24/11/2017
	//		_lRet = .T.
	//	endif
	//    if _nPerc <= 10 .and. date () >= stod ('20180504') .and. date () <= stod ('20180513')  // Dia das maes 2018
	//    	_lRet = .T.
	//	endif
	if _nPerc <= 40 .and. date () >= stod ('20180622') .and. date () <= stod ('20180623')  // Promocao Pipa Store 2018
		_lRet = .T.
	endif

	if ! _lRet .and. _nPerc <= 5 .and. ! empty (m->lq_contato) .and. date () >= stod ('20171206') .and. date () <= stod ('20171231')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT A2_COD, A2_LOJA "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA2") + " SA2, "
		_oSQL:_sQuery +=             RetSQLName ("SU5") + " SU5 "
		_oSQL:_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=   " AND SA2.A2_CGC     = SU5.U5_CPF"
		_oSQL:_sQuery +=   " AND SU5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SU5.U5_FILIAL  = '" + xfilial ("SU5") + "'"
		_oSQL:_sQuery +=   " AND SU5.U5_CODCONT = '" + m->lq_contato + "'"
		_oSQL:Log ()
		_aAssoc = aclone (_oSQL:Qry2Array ())
		if len (_aAssoc) > 0 .and. U_EhAssoc (_aAssoc [1, 1], _aAssoc [1, 2], date ())
			_lRet = .T.
		else
			u_help ("O contato informado nao consta como associado nesta data.")
		endif
	endif
	if ! _lRet
		u_help ("Desconto acima do permitido")
	endif
return _lRet


// -------------------------------------------------------------------
// Verifica se o texto informado contem somente zeros.
static function _SohZeros (_sStrOrig)
	_lRetZeros := .T.
	do while ! empty (_sStrOrig)
//		U_Log2 ('debug', '[' + procname () + ']testando >>' + _sStrOrig + '<<')
		if left (_sStrOrig, 1) != '0'
			_lRetZeros = .F.
			exit
		endif
		_sStrOrig = substr (_sStrOrig, 2)
	enddo
return _lRetZeros
