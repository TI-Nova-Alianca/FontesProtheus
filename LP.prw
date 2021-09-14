// Programa.: LP
// Autor....: Robert Koch - TCX021
// Data.....: 10/03/2011
// Descricao: Execblock generico para lancamentos padronizados.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Execblock auxiliar para uso em lancamentos padronizados da contabilidade.
// #PalavasChave      #lancamento_padrao
// #TabelasPrincipais 
// #Modulos           #CTB
//
// Historico de alteracoes:
// 28/03/2011 - Robert  - Tratamento para ZI_TM = '03'.
// 24/05/2011 - Robert  - tratamento para LPad 678.
// 10/08/2011 - Robert  - Tratamento para novos movtos. conta corrente associados.
// 16/08/2011 - Robert  - Tratamento para novos movtos. conta corrente associados (compensacoes).
// 18/11/2011 - Robetr  - Tratamento para retornar CRED no LPad. 678/015.
//                      - Tratamento para retornar CCD no LPad. 678/000.
// 06/03/2012 - Robert  - Tratamento para compensacao com mov. 16 da conta corrente.
// 13/04/2012 - Robert  - Lanc.padrao 530/004 tinha conta 1110299 fixa.
// 03/01/2012 - Robert  - Tratamento para l.pad. 597/004 (comp.adt.obra)
// 13/10/2014 - Catia   - l.pad. 597/005 - acertado para que trate OBRA, ASSOCIADO e Fornecedor NORMAL
// 27/10/2014 - Catia   - l.pad. 597/005 - acertado ASSOCIADO para que trate as contas setadas no SZI
// 07/11/2014 - Catia   - tirado um msgalert que tinha ficado esquecido.
// 05/05/2015 - Catia   - lançamento padrao 510/200 - tratamento prefixo que deve zerar o valor para nao contabilizar.
// 15/06/2015 - Catia   - feito tratamento para contabilização das NCC de verbas de clientes - 500/004
// 25/06/2015 - Catia   - tratamento para o lancamento padrao 530/001 - buscar a conta debito nos titulos de 
//                        impostos da natureza financeira 
// 02/09/2015 - Catia   - lançamento padrao 510/200 - tratamento prefixo IND
// 01/10/2015 - Robert  - Criado tratamento para o campo A3_vaTpCon.
//                      - Ajustes para novos centros de custos.
// 20/10/2015 - Robert  - Como os novos CC estao demorando a serem habilitados, separei o programa em "novos CC" e "velhos CC"
// 29/10/2015 - Catia   - l.pad. 520 (021 e 022) - estorno provisao de rapel e comissao - rotina para montar o valor
// 29/10/2015 - Catia   - l.pad. 521 (021 e 022) - estorno provisao de rapel e comissao - rotina para montar o valor
// 30/10/2015 - Catia   - l.pad. 596 (002 e 003) - estorno provisao de rapel e comissao - rotina para montar o valor
// 03/11/2015 - Robert  - Alteracoes diversas para contemplar novos CC entram no ar agora.
// 04/11/2015 - Catia   - Desconsiderar o vendedor 240 nos lctos 520/521/596
// 26/01/2016 - Catia   - 520/521 seq 021 - alltrim(e1_vend1)
// 27/01/2016 - Robert  - Novo parametro funcao U_LP2.
// 04/02/2016 - Catia   - Lcto 510/200 - tratamento dos PR estava errado
// 17/03/2016 - Robert  - Criado tratamento para lpad/seq 666/005.
// 26/04/2016 - Robert  - Funcao U_Help alterada para U_AvisaTI para nao parar processos grandes como a contabilizacao do medio.
// 24/05/2016 - Robert  - Recebe doc e serie por parametro.
// 13/07/2016 - Robert  - Tratamento para LPAD 521 e 522 remodelado para atender tambem o 524.
// 14/07/2016 - Robert  - Ajustado retorno do LPAD 596 (que estraguei na manutencao feita ontem).
// 31/08/2016 - Catia   - Lcto 530/004/CRED - estava trazendo no primeiro lcto a conta caixa e deveria 
//                        ser a conta contabil do banco
// 19/10/2016 - Catia   - Alterado teste de vendedores diretos por parametro $GETMV("MV_VENDDIR")
// 13/12/2016 - Robert  - Tratamento para LPAD 666/008
// 13/01/2017 - Catia   - Tratamento para LPAD 666/008 - dava erro quando nao retornava a conta - 
//                        alterei para que retorno em branco
// 13/06/2017 - Catia   - Tratamento para rapel, que busque direto do E1_VARAPEL
// 01/02/2018 - Catia   - LP de baixa de titulos a pagar com PREFIXO ALE
// 13/03/2018 - Catia   - desabilitado o lcto de estorno de rapel - nao deve ser feito estorno pra rapel 
//                        apenas pra comissão
// 23/04/2018 - Robert  - LP 510/200 retornar valor zerado para prefixo FRS (auxilio frete safra a associados).
// 27/09/2018 - Robert  - Ajuste tratamento erro para o LPad 666005.
// 18/10/2018 - Catia   - LP 631/000 - cupons fiscais
// 30/10/2019 - Robert  - diferenciava CC coml/adm/indl usando LEFT em vez de SUBSTR (posicao 3) no LPAD 666/008
// 21/07/2020 - Cláudia -  Ajustada as contas para o LPAD: 500. Conform GLPI: 8094
// 23/10/2020 - Robert  - Tratamento para tipo IA no lpad 666/008
// 23/06/2021 - Claudia - Ajuste no lançamento 520 002. GLPI:10294
// 13/07/2021 - Robert  - Tratamento LP 530 resgate cota capital (GLPI 10481)
// 16/08/2021 - Claudia - Incluida rotina ZB3(Pagar-me) na conta de credito de cartões. GLPI: 9026
// 14/09/2021 - Robert  - Eliminados alguns tratamentos ref.cta.corrente associados (GLPI 10503)
//

// -----------------------------------------------------------------------------------------------------------------
// Informar numero e sequencia do lancamento padrao, seguido do campo a ser retornado.
User Function LP (_sLPad, _sSeq, _sQueRet, _sDoc, _sSerie)
	local _aAreaAnt := U_ML_SRArea ()
	local _xRet     := NIL
	local _sQuery   := ""
	local _aRetQry  := {}
	local _oSQL     := NIL
	//local _x        := 0

 	_sQueRet = alltrim (upper (_sQueRet))
 	do case
		case _sLPad == '500' .and. _sSeq='004' .and. IsInCallStack ("U_VA_ZA4")// Inclusao contas a receber
			// seta as contas corretas para contabilizacao da NCC do controle de verbas
			IF alltrim(SE1->E1_PREFIXO) == "CV" .AND. SE1->E1_TIPO=="NCC" .AND. alltrim(SE1->E1_NATUREZ)=="VERBAS"
				// Busca código do tipo da verba
				_wtipo   := fBuscaCpo ('ZA3', 1, xfilial('ZA3') +  m->za4_cod, "ZA3_CTB")
				if _sQueRet == 'CDEB'
					if _wtipo ='6'
						_xRet = "403010201031" // multa contratual
					else
						_xRet = "403010401007" 
					endif
	    		endif

	     		if _sQueRet == 'HIST'
	    			do case
						case _wtipo ='1'
							_xRet = "VERBAS-ENCARTES/P.EXTRA:" + SE1->E1_NUM + ' / ' + alltrim(SE1->E1_NOMCLI) // encartes/ponto extra
						case _wtipo ='2'
							_xRet = "VERBAS-FEIRAS:" + SE1->E1_NUM + ' / ' + alltrim(SE1->E1_NOMCLI)  // feiras
						case _wtipo ='3'
							_xRet = "VERBAS-FRETES:" + SE1->E1_NUM + ' / ' + alltrim(SE1->E1_NOMCLI) // fretes
						case _wtipo ='4'
							_xRet = "VERBAS-CAMPANHA VENDAS:" + SE1->E1_NUM + ' / ' + alltrim(SE1->E1_NOMCLI) // campanha de vendas
						case _wtipo ='5'
							_xRet = "VERBAS - ABERTURA LOJAS:" + SE1->E1_NUM + ' / ' + alltrim(SE1->E1_NOMCLI) // abertura/reinauguracao lojas
						case _wtipo ='6'
							_xRet = "VERBAS - MULTA CONTRATUAL - VERBA NRO/CLIENTE:" + SE1->E1_NUM + ' / ' + SE1->E1_NOMCLI // multa contratual
					endcase
				endif
			ENDIF


	case _sLPad == '510' .and. _sSeq='200' // Inclusao contas a pagar
		_xRet = SE2->E2_VALOR 
//		IF SE2->E2_PREFIXO=="ALE" .OR. SE2->E2_PREFIXO=="COM" .OR. SE2->E2_PREFIXO=="IND" .OR. SE2->E2_PREFIXO=="UNI" .OR. SE2->E2_PREFIXO=="CEL" .OR. SE2->E2_PREFIXO=="ANS" .OR. SE2->E2_PREFIXO=="SEM" .OR. SE2->E2_PREFIXO=="FRS" .OR. SE2->E2_PREFIXO=="DEL" 
		IF SE2->E2_PREFIXO=="COM" .OR. SE2->E2_PREFIXO=="IND" .OR. SE2->E2_PREFIXO=="FRS" .OR. SE2->E2_PREFIXO=="DEL" 
			_xRet = 0
		ENDIF
		IF SE2->E2_TIPO=="PR " .OR. SE2->E2_TIPO=="PRI" // tem que ficar assim com espaço - nao tirar
			_xRet = 0
		ENDIF


	case _sLPad == '510' .and. _sSeq == '202' // Inclusao titulos indenizacao
		do case
		case _sQueRet == 'ITCTAD'
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT TOP 1 A3_COD"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA3") + " SA3 "
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''
			_oSQL:_sQuery +=    " AND A3_FILIAL  = '" + xfilial ("SA3") + "'"
			_oSQL:_sQuery +=    " AND A3_FORNECE = '" + se2 -> e2_fornece + "'"
			_oSQL:_sQuery +=    " AND A3_LOJA    = '" + se2 -> e2_loja + "'"
//			u_log (_oSQL:_sQuery)
			_xRet = _oSQL:RetQry ()
		endcase

		case _sLPad == '520' .and. _sSeq='002'
			if _sQueRet == 'CRED'
				// cielo 
				if (alltrim(SE5->E5_ORIGEM) =='ZB1' .or. alltrim(SE5->E5_ORIGEM) =='FINA740') .and. alltrim(SE5->E5_TIPO) $ 'CC/CD'				
					if !empty(SE5->E5_ADM) 
						do case
							case SE5->E5_ADM == "100" .or. SE5->E5_ADM =="101"
								_xRet:= "101021101002"
							case SE5->E5_ADM == "200" .or. SE5->E5_ADM =="201"
								_xRet:= "101021101001"
							case SE5->E5_ADM == "300" .or. SE5->E5_ADM =="301"
								_xRet:= "101021101003"
							case SE5->E5_ADM == "400" .or. SE5->E5_ADM =="401"
								_xRet:= "101021101004"
							otherwise
								_xRet:= "101021101005"
						endcase
					else
						do case
							case SE1->E1_ADM == "100" .or. SE1->E1_ADM =="101"
								_xRet:= "101021101002"
							case SE1->E1_ADM == "200" .or. SE1->E1_ADM =="201"
								_xRet:= "101021101001"
							case SE1->E1_ADM == "300" .or. SE1->E1_ADM =="301"
								_xRet:= "101021101003"
							case SE1->E1_ADM == "400" .or. SE1->E1_ADM =="401"
								_xRet:= "101021101004"
							otherwise
								_xRet:= "101021101005"
						endcase
					endif
				else
					// pagar-me
					if alltrim(SE5->E5_ORIGEM) == 'ZB3'
						Do Case
							Case !empty(SE1->E1_ADM) // cartão
								do case
									case SE1->E1_ADM == "100" .or. SE1->E1_ADM =="101"
										_xRet:= "101021101002"
									case SE1->E1_ADM == "200" .or. SE1->E1_ADM =="201"
										_xRet:= "101021101001"
									case SE1->E1_ADM == "300" .or. SE1->E1_ADM =="301"
										_xRet:= "101021101003"
									case SE1->E1_ADM == "400" .or. SE1->E1_ADM =="401"
										_xRet:= "101021101004"
									otherwise
										_xRet:= "101021101005"
								endcase

							Case empty(SE1->E1_ADM) 	// boleto
								_xRet := "101020201001" // conta clientes	

							Otherwise
								_xRet := "101020201001" // conta clientes							
						EndCase
					else
						_xRet := "101020201001"
					endif
				endif  				
			endif

	case _sLpad+_sseq $ ('520002/521002/527002') // ESX - tratamento baixa e cancelamento da baixa para venda futura
		beginsql alias "_qd2"
			SELECT DISTINCT D2_DOC 
			FROM %table:SD2% SD2, %table:SF4% SF4
			WHERE D2_FILIAL = %xfilial:SD2% 
			AND F4_FILIAL = %xfilial:SF4% 
			AND SD2.%notdel% 
			AND SF4.%notdel%
			AND D2_TES = F4_CODIGO 
			AND F4_TOCON = '16'
			AND D2_DOC = %exp:SE1->E1_NUM%
			AND D2_SERIE = %exp:SE1->E1_PREFIXO%
		endsql 

		do case
			case alltrim(_sQueRet) $ 'CRED/DEB' 
				if  _qd2->(eof())
					_xret := '101020201001'
				else
					_xret := '101020201003'
				endif
			endcase
			_qd2->(dbclosearea())

	case _sLPad + _sSeq $ '520003'
		u_help (SE1->E1_TIPO)
		u_help (SE5->E5_VLDESCO)
		u_help (SE5->E5_VADOUTR)

	case _sLPad + _sSeq $ '520021/521021/524021' .and. _sQueRet == 'VL' .and. !alltrim(SE5->E5_ORIGEM) $ 'ZB1/ZB3'// descontos - estorna provisao de comissao
		if SE1->E1_TIPO<>"NCC" .AND. SE5->E5_VLDESCO > 0 .and. SE1->E1_COMIS1>0 .AND. ! alltrim(SE1->E1_VEND1) $ GETMV("MV_VENDDIR")
			// acha a base de comissao do titulo - não da pra considerar a do SE1, por conta do recalculo
			_xbaseComTit = _BComis (SE1->E1_NUM, SE1->E1_PREFIXO, SE1->E1_CLIENTE,SE1->E1_LOJA, SE1->E1_VALOR)
			// proporcionalizar o valor do desconto com a base de comissao do titulo
			_xbase = _xbaseComTit * SE5->E5_VLDESCO / SE1->E1_VALOR 
			// valor do estorno de comissao = valor base de comissao ref ao desconto * percentual de comissao do vendedor
			_xRet = round(_xbase * SE1->E1_COMIS1/100,2)
		else
			_xRet = 0
		endif						
    
	case _sLPad + _sSeq $ '520022/521022/524022' .and. _sQueRet == 'VL' // descontos - estorna provisao de rapel
		_xRet = 0			

	case _sLPad == '520' .and. _sSeq='026'
		if _sQueRet == 'CDEB'
			if alltrim(SE5->E5_ORIGEM) == 'ZB3'
				Do Case
					Case !empty(SE1->E1_ADM) 	// cartão
						_xRet := "403010201052"   

					Case empty(SE1->E1_ADM) 	// boleto e pix
						_xRet := "403010201021" 

					Otherwise
						_xRet := "101020201001" // conta clientes							
				EndCase
			endif
		endif

	case _sLPad == '520' .and. _sSeq='027'
		if _sQueRet == 'CDEB'
			if alltrim(SE5->E5_ORIGEM) $'ZB1/ZB3'
				Do Case
					Case !empty(SE1->E1_ADM) // cartão
						do case
							case SE1->E1_ADM == "100" .or. SE1->E1_ADM =="101"
								_xRet:= "101021101002"
							case SE1->E1_ADM == "200" .or. SE1->E1_ADM =="201"
								_xRet:= "101021101001"
							case SE1->E1_ADM == "300" .or. SE1->E1_ADM =="301"
								_xRet:= "101021101003"
							case SE1->E1_ADM == "400" .or. SE1->E1_ADM =="401"
								_xRet:= "101021101004"
							otherwise
								_xRet:= "101021101005"
						endcase

					Case empty(SE1->E1_ADM) 	// boleto
						_xRet := "101020201001" // conta clientes	

					Otherwise
						_xRet := "101020201001" // conta clientes							
				EndCase
			endif
		endif
		
	case _sLPad == '520' .and. _sSeq='028'
		if _sQueRet == 'CCRED'
			if alltrim(SE5->E5_ORIGEM) $'ZB1/ZB3'
				Do Case
					Case !empty(SE1->E1_ADM) // cartão
						do case
							case SE1->E1_ADM == "100" .or. SE1->E1_ADM =="101"
								_xRet:= "101021101002"
							case SE1->E1_ADM == "200" .or. SE1->E1_ADM =="201"
								_xRet:= "101021101001"
							case SE1->E1_ADM == "300" .or. SE1->E1_ADM =="301"
								_xRet:= "101021101003"
							case SE1->E1_ADM == "400" .or. SE1->E1_ADM =="401"
								_xRet:= "101021101004"
							otherwise
								_xRet:= "101021101005"
						endcase

					Case empty(SE1->E1_ADM) 	// boleto
						_xRet := "101020201001" // conta clientes	

					Otherwise
						_xRet := "101020201001" // conta clientes							
				EndCase
			endif
		endif

	case _sLPad == '530' .and. _sSeq='001' .and. _sQueRet == 'CDEB' // baixa titulo contas a pagar - define conta a debito
		do case
			case se2 -> e2_prefixo = 'RCC'  // GLPI 10481
				_xRet = '201030102001'
			case IsInCallStack("U_SZI") .and. type('_SZI_Deb')=='C'
				_xRet = _SZI_Deb
			case SE2->E2_TIPO=="NDF" 
				_xRet = SA6->A6_CONTA
			case SUBSTR(SE2->E2_TIPO,1,2)=="TX" .or. SUBSTR(SE2->E2_TIPO,1,3)=="FOL"// quanto titulos de IMPOSTOS - usa conta da natureza financeira
				_xRet = SED->ED_CONTA
			case SE2->E2_TIPO=="DP" .and. SE2->E2_PREFIXO=="ALE"
				_xRet = "201030101002" // conta add associados
			case SE2->E2_VAOBRA=="S"
				_xRet = "201090101001" // conta fixa da obra
			otherwise
				_xRet = SA2->A2_CONTA
		endcase
		
	case _sLPad + _sSeq + _sQueRet == '530004CRED'  // Pagto.fornecedor
			if IsInCallStack("U_SZI") .and. type('_SZI_Cred')=='C'
				_xRet = _SZI_Cred
			else
				IF SE5->E5_MOTBX=="DEB"
					_xRet = SA6->A6_CONTA
				else
					IF SE2->E2_TIPO="PA"
						_xRet = SA2->A2_CONTA
					else
						IF EMPTY (SE5->E5_NUMCHEQ) .AND. !SE5->E5_BANCO$"CX1"
							_xRet = SA6->A6_CONTA
						else
							IF SE2->E2_TIPO=="NDF"
								_xRet = SA2->A2_CONTA
							else
								_xRet = SA6->A6_CONTA
							endif
						endif
					endif
				endif
			endif
			
	case _sLPad == '596' 
		_xRet := 0
		if SE5->E5_MOTBX="CMP"
			do case
				case _sSeq='002' .and. _sQueRet == 'VL' // descontos - estorna provisao de comissao
					if  SE1->E1_COMIS1>0 .AND. ! SE1->E1_VEND1 $ GETMV("MV_VENDDIR")
						// acha a base de comissao do titulo - não da pra considerar a do SE1, por conta do recalculo
						_xbaseComTit = _BComis (SE1->E1_NUM, SE1->E1_PREFIXO, SE1->E1_CLIENTE,SE1->E1_LOJA, SE1->E1_VALOR)
						// proporcionalizar o valor do desconto com a base de comissao do titulo
						_xbase = _xbaseComTit * SE5->E5_VALOR / SE1->E1_VALOR 
						// valor do estorno de comissao = valor base de comissao ref ao desconto * percentual de comissao do vendedor
						_xRet = round(_xbase * SE1->E1_COMIS1/100,2)
					endif						
				case _sSeq='003' .and. _sQueRet == 'VL'
					_wrapelPREV = SE1->E1_VARAPEL
					_xret = _Rapel (SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_CLIENTE, SE1->E1_LOJA, SE5->E5_VALOR, _wrapelPREV )
			endcase
		endif		
		
	case _sLPad == '597' .and. _sSeq='005' // Compensacao contas a pagar
	   _wtipo := "NORMAL
	   
	    // Testa se é ASSOCIADO
	    if left (se5 -> e5_vachvex, 3) == "SZI"
           _sQuery := ""
           _sQuery += "SELECT ZI_TM, ZI_HISTOR"
           _sQuery +=   " FROM " + RetSQLName ("SZI") + " SZI"
           _sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
           _sQuery +=    " AND SZI.ZI_FILIAL   = '" + xfilial ("SZI") + "'"
           _sQuery +=    " AND SZI.ZI_ASSOC    = '" + se5 -> e5_clifor + "'"
           _sQuery +=    " AND SZI.ZI_LOJASSO  = '" + se5 -> e5_loja + "'"
           _sQuery +=    " AND SZI.ZI_SEQ      = '" + substr (se5 -> e5_vachvex, 12, 6) + "'"
           _aRetQry = U_Qry2Array (_sQuery)
           if len(_aRetQry) > 0
              _wtipo := "ASSOCIADO"
           endif
       endif
       // testa se é OBRA
       if _EhObra()
            _wtipo = "OBRA" 
       endif
	   // atribui contas
	   do case 
	       case _wtipo = "OBRA"
	           if _sQueRet == 'CDEB'
	               _xRet = "201090101001" // Obrigações Obras em Andamento
	           else     
	               _xRet = "101020801001" // Adiantamentos Obra Nova Unidade Flores
	           endif
	       case _wtipo = "ASSOCIADO"
	           if _sQueRet == 'CDEB'
	               // Se foi setado no programa do conta corrente uma conta debito
	               // usa essa, senão usa "Produtos a Liquidas Associados"
	               // essas contas são setadas no SZI
	               _xRet = iif( type ("_SZI_Deb") == 'C', _SZI_Deb,  "201030101001" )	               
               else 
                  // Se foi setado no programa do conta corrente uma conta debito
                  // usa essa, senão usa "Adiantamentos Associados"
                  // essas contas são setadas no SZI
                  _xRet = iif( type ("_SZI_Cred") == 'C', _SZI_Cred, "101020101002" )
				  // Aqui deveria levar em consideracao o tipo de movimento da conta corrente (ou seja, so quero movtos originados via cta corrente associados. Compra de lenha nao entra aqui)
				  // Seria bom abrir um lcto padrao separado do 'fornecedores normais'
               endif
          case _wtipo = "NORMAL"
               if _sQueRet == 'CDEB'
                  _xRet = sa2 -> a2_conta // Fornecedores conforme o cadastro
               else     
                  _xRet = "101020601001" // Adiantamentos a Fornecedores
               endif
        endcase

    case _sLPad + _sSeq == '631000'  // contabilizacao venda cupons
    	_xRet   = ""
     	if _sQueRet == 'CDEB'
     		_wtipo = ALLTRIM(SL4->L4_FORMA)
     		do case 
     		case _wtipo == 'R$'
     			_xRet = "101010101002" // conta caixa
     		case _wtipo == 'VP'	
     			_xRet = "403010401004" // conta bonificacoes
     		otherwise
     			// se a forma de pagamento nao foi dinheiro - contabiliza usando a conta cliente do titulo
     			// pq no financeiro - o cliente fica a administradora de cartao e la deve estar associada a conta correta
     			_sSQL := ""
     			_sSQL += " SELECT E1_CLIENTE, E1_LOJA"
     			_sSQL += "   FROM SE1010"
     			_sSQL += "  WHERE E1_FILIAL  = '" + SL4->L4_FILIAL + "'" 
     			_sSQL += "    AND E1_NUM     = '" + SF2->F2_DOC + "'"
     			_sSQL += "    AND E1_PREFIXO = '" + SF2->F2_SERIE + "'"
     			_sSQL += "    AND E1_EMISSAO = '" + DTOS(SF2->F2_EMISSAO) + "'" // tem que pegar do F2 no L4 quando eh mais de uma parcela no cartao gera com datas diferentes
     			_sSQL += "    AND E1_TIPO    = '" + SL4->L4_FORMA + "'"
     			_aDados := U_Qry2Array(_sSQL)
     			if len (_aDados) > 0
     				_wcliente = _aDados[1,1]
     				_wloja    = _aDados[1,2]
     				_xRet = fBuscaCpo("SA1",1,xFilial("SA1")+_wcliente+_wloja, "A1_CONTA" )
     			endif	
     		endcase
     	endif
     	if _sQueRet == 'CCD'
     		_wtipo = ALLTRIM(SL4->L4_FORMA)
     		if _wtipo = 'VP'
     			do case
     				case SL4->L4_FILIAL = '03'
     					_xRet = '0334001' 
     				case SL4->L4_FILIAL = '08'
     					_xRet = '084003'
     				case SL4->L4_FILIAL = '10'
     					_xRet = '104003'
     				case SL4->L4_FILIAL = '13'
     					_xRet = '134003'
     		 	endcase
     		endif
     	endif
     	

	case _sLPad + _sSeq == '666005'  // Custeio MO + GGF + apoio.
		_xRet   = ""
		do case
		case _sQueRet = "CRED"
			do case
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1301' ; _xRet = "701011001036"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1302' ; _xRet = "701011001037"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1303' ; _xRet = "701011001045"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1304' ; _xRet = "701011001046"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1401' ; _xRet = "701011001038"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1402' ; _xRet = "701011001039"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1403' ; _xRet = "701011001040"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1404' ; _xRet = "701011001041"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1405' ; _xRet = "701011001042"
			case substr (SD3->D3_COD, 4, 6) == cFilAnt + '1406' ; _xRet = "701011001043"
			otherwise
				//U_AvisaTI ("Sem tratamento para CC '" + substr (SD3->D3_COD, 4, 6) + "' sem tratamento no LPad/seq '" + _sLPad + _sSeq + "' para esta filial. RECNO SD3:" + cvaltochar (sd3 -> (recno ()))
			endcase

		case _sQueRet = "CCD"  // Cfe. prog. antigo 'vendacc.prw':

			// Nao deu para chamar o programa LP2 direto no lcto padrao por que o arquivo SF2 nao encontra-se posicionado para este lcto padrao.
			_xRet = U_LP2 ('CTA_TP_VEND',, fBuscaCpo ("SF2", 1, xfilial ("SF2") + sd2 -> d2_doc + sd2 -> d2_serie, "F2_VEND1"),, _sLPad + _sSeq)
		endcase


	case _sLPad + _sSeq == '666008'  // Custeio requisicoes por CC.
		if _sQueRet = "CDEB"
			_xRet   = ""
			do case
			case SD3->D3_TIPO == 'CL'; _xRet = '701010301001'
			case SD3->D3_TIPO == 'MT'; _xRet = '701010301008'
			case SD3->D3_TIPO == 'MB'; _xRet = '701010301020'
			case SD3->D3_TIPO == 'UC'; _xRet = '403010401016'
			case SD3->D3_TIPO == 'II' .and. sd3 -> d3_grupo == '5000'; _xRet = '701010301009'  // Mat.aux.limpeza producao
//			case SD3->D3_TIPO $ 'II/MA' .and. sd3 -> d3_grupo == '5001'; _xRet = '701010301024'  // Mat.aux.producao
			case SD3->D3_TIPO $ 'II/MA' .and. sd3 -> d3_grupo $ '5001/7001'; _xRet = '701010301024'  // Mat.aux.producao + mat.perigosos
			case SD3->D3_TIPO $ 'II/MA' .and. sd3 -> d3_grupo == '5002'; _xRet = '701010301018'  // Mat.aux.producao - acondicionamento (filme, etc.)
			case SD3->D3_TIPO == 'EP' .and. substr (sd3 -> d3_cc, 3, 1) $ '1/2' ; _xRet = '701010201008'
			case SD3->D3_TIPO == 'EP' .and. substr (sd3 -> d3_cc, 3,1) $ '3/4' ; _xRet = '403010101007'
			case SD3->D3_TIPO == 'MM' ; _xRet = '701010301011'
			case SD3->D3_TIPO == 'MR' ; _xRet = '403010401010'
			case SD3->D3_TIPO == 'IA' ; _xRet = '701010301017'
			otherwise
				U_AvisaTI ("Sem tratamento no LPad/seq '" + _sLPad + _sSeq + "' para produto='" + alltrim (sd3 -> d3_cod) + "' tipo='" + sd3 -> d3_tipo + "' grupo='" + sd3 -> d3_grupo + "' CC='" + sd3 -> d3_cc + "' recnoSD3=" + cvaltochar (sd3 -> (recno ())) + ")")
			endcase
		endif


	case _sLPad + _sSeq == '678000'  // CPV DESPESA
		do case
			case _sQueRet = "CRED"
				_xRet   = ""
				do case
				case SD2->D2_TP=="MP" ; _xRet = "101030101014"
				case SD2->D2_TP=="ME" ; _xRet = "101030101016"
				case SD2->D2_TP=="PA" ; _xRet = "101030101011"
				case SD2->D2_TP=="PS" ; _xRet = "101030101015"
				case SD2->D2_TP=="VD" ; _xRet = "101030101013"
				case SD2->D2_TP=="PI" ; _xRet = "101030101012"
				otherwise
					U_AvisaTI ("Tipo '" + sd2 -> d2_tp + "' sem tratamento no LPad/seq '" + _sLPad + _sSeq + "'")
				endcase

			case _sQueRet = "CCD"  // Cfe. prog. antigo 'vendacc.prw':
				// Acho que estamos chamando esta contabilizacao indevidamente...
				if empty (fBuscaCpo ("SF2", 1, xfilial ("SF2") + _sDoc + _sSerie, "F2_VEND1"))
					u_avisaTI ("Vendedor em branco para doc/serie '" + _sDoc + '/' + _sSerie + "' no LPAD " + _sLPad + _sSeq + _sQueRet) 
				endif
				
				// Nao deu para chamar o programa LP2 direto no lcto padrao por que o arquivo SF2 nao encontra-se posicionado para este lcto padrao.
				_xRet = U_LP2 ('CTA_TP_VEND',, fBuscaCpo ("SF2", 1, xfilial ("SF2") + _sDoc + _sSerie, "F2_VEND1"),, _sLPad + _sSeq)
			endcase

	case _sLPad + _sSeq == '678001'  // REMESSA DE BONIFICACAO
		do case
			case _sQueRet = "CCD"  // Cfe. prog. antigo 'vendacc.prw':

				// Nao deu para chamar o programa LP2 direto no lcto padrao por que o arquivo SF2 nao encontra-se posicionado para este lcto padrao.
				_xRet = U_LP2 ('CTA_TP_VEND',, fBuscaCpo ("SF2", 1, xfilial ("SF2") + sd2 -> d2_doc + sd2 -> d2_serie, "F2_VEND1"),, _sLPad + _sSeq)
			endcase


	case _sLPad + _sSeq == '678015'  // Remessa entrega futura
		do case
			case _sQueRet = "CCD"
				
				// Acho que estamos chamando esta contabilizacao indevidamente...
				if empty (fBuscaCpo ("SF2", 1, xfilial ("SF2") + _sDoc + _sSerie, "F2_VEND1"))
					u_avisaTI ("Vendedor em branco para doc/serie '" + _sDoc + '/' + _sSerie + "' no LPAD " + _sLPad + _sSeq + _sQueRet) 
				endif

				// Nao deu para chamar o programa LP2 direto no lcto padrao por que o arquivo SF2 nao encontra-se posicionado para este lcto padrao.
				_xRet = U_LP2 ('CTA_TP_VEND',, fBuscaCpo ("SF2", 1, xfilial ("SF2") + _sDoc + _sSerie, "F2_VEND1"),, _sLPad + _sSeq)
			endcase
	endcase

	// Tenta dar um tratamento para o caso de nao ter encontrado nada a retornar.
	if _xRet == NIL
		u_AvisaTI ("Lancamento padrao '" + _sLPad + _sSeq + ;
		           "' sem tratamento para o tipo de retorno '" + _sQueRet + ;
		           "' no programa " + procname () + ;
		           ". Pilha de chamadas:" + _Pcham ())
		do case
			case _sQueRet $ "HIST/CRED/DEB/CCC/CCD/ITCTAD"
				_xRet = ""
			case _sQueRet $ "VL/"
				_xRet = 0
		endcase
	endif
	U_ML_SRArea (_aAreaAnt)
return _xRet
//
// --------------------------------------------------------------------------
// Verifica se eh um titulo referente a pagamentos da obra unidade Flores.
static function _EhObra ()
	local _oSQL := NIL
	local _lRet := .F.

	if alltrim (se5 -> e5_tipo) == 'PA'  // SE5 estava posicionado no titulo PA
		if left (se5 -> e5_vachvex, 3) == 'SC7' .and. fBuscaCpo ("SC7", 1, xfilial ("SC7") + substr (se5 -> e5_vachvex, 4), "C7_VAOBRA") == "S"
			_lRet = .T.
		endif
	else  // SE5 estava posicionado no titulo NF
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE5") + " SE5, "
		_oSQL:_sQuery +=              RetSQLName ("SC7") + " SC7 "
		_oSQL:_sQuery +=  " WHERE SE5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND SE5.E5_FILIAL   = '" + xfilial ("SE5") + "'"
		_oSQL:_sQuery +=    " AND SE5.E5_PREFIXO  = '" + substr (STRLCTPAD, 1, 3)  + "'"
		_oSQL:_sQuery +=    " AND SE5.E5_NUMERO   = '" + substr (STRLCTPAD, 4, 6)  + "'"
		_oSQL:_sQuery +=    " AND SE5.E5_PARCELA  = '" + substr (STRLCTPAD, 10, 1) + "'"
		_oSQL:_sQuery +=    " AND SE5.E5_TIPO     = '" + substr (STRLCTPAD, 14, 3) + "'"
		_oSQL:_sQuery +=    " AND SE5.E5_CLIFOR   = '" + substr (STRLCTPAD, 17, 6) + "'"
		_oSQL:_sQuery +=    " AND SE5.E5_LOJA     = '" + substr (STRLCTPAD, 23, 2) + "'"
		_oSQL:_sQuery +=    " AND SE5.E5_SEQ      = '" + se5 -> e5_seq + "'"
		_oSQL:_sQuery +=    " AND SC7.C7_FILIAL   = '" + xfilial ("SC7") + "'"
		_oSQL:_sQuery +=    " AND SC7.C7_NUM      = SUBSTRING (SE5.E5_VACHVEX, 4, 6)"
		_oSQL:_sQuery +=    " AND SC7.C7_ITEM     = SUBSTRING (SE5.E5_VACHVEX, 10, 4)"
		_oSQL:_sQuery +=    " AND SC7.C7_VAOBRA   = 'S'"
		if _oSQL:RetQry (1, .F.) > 0
			_lRet = .T.
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Faz exportacao da pilha de chamadas para uma string.
static function _PCham ()
	local _i      := 2
	local _sPilha := ""
	do while procname (_i) != ""
		_sPilha += procname (_i) + "=>"
		_i++
	enddo
return _sPilha
//
// --------------------------------------------------------------------------
// Função rapel
static function _Rapel (_wnum, _wparcela, _wcliente, _wloja, _wvlrdesco, _wrapelPREV)
	_xvlr :=0
	// busca o valor do rapel ja lançado no titulo/parcela
	_sSQL = ""
	_sSQL += "SELECT SUM(E5_VARAPEL)  AS VLR_RAPEL"
	_sSQL += "  FROM " + RetSQLName ("SE5") + " AS SE5 "
 	_sSQL += " WHERE SE5.D_E_L_E_T_ = ''"
	_sSQL += "   AND SE5.E5_FILIAL  = '" + xfilial ("SE5") + "'" 
	_sSQL += "   AND SE5.E5_CLIENTE = '" + _wcliente + "'"
	_sSQL += "   AND SE5.E5_LOJA    = '" + _wloja + "'"
	_sSQL += "   AND SE5.E5_NUMERO  = '" + _wnum + "'"
	_sSQL += "   AND SE5.E5_PARCELA = '" + _wparcela + "'"
	_sSQL += "   AND SE5.E5_RECPAG  = 'R'"
	_sSQL += "   AND SE5.E5_TIPODOC = 'DC'"
	_sSQL += "   AND SE5.E5_SITUACA = ''"
	_sSQL += "   AND SE5.E5_VARAPEL > 0"
	_rapelTOT  := U_Qry2Array(_sSQL)
	_wrapelTOT := 0
	If len(_rapelTOT) > 0
		_wrapelTOT = _rapelTOT[1,1]
	Endif
	// se ainda nao "gastou" todo o rapel - testa o desconto
	if _wrapelPREV > _wrapelTOT
		_wRestoRapel    = _wrapelPREV -  _wrapelTOT
		_wRapelDesconto = round(_wvlrdesco * _wrapelPREV/100,2)
		if _wRestoRapel > _wRapelDesconto 
			_xvlr = _wRapelDesconto
		endif
		if _wRestoRapel < _wRapelDesconto
			_xvlr = _wRestoRapel
		endif										
	endif
return _xvlr		
//
// --------------------------------------------------------------------------
static function _BComis (_wnf, _wserie, _wcliente, _wloja, _wvalor)
	_wbaseCom := 0
	
	// busca dados da nota
	_sQuery := ""
	_sQuery += " SELECT F2_VALBRUT  AS TOTAL_NF"
	_sQuery += "      , F2_VALIPI   AS IPI_NF"
	_sQuery += "      , F2_ICMSRET  AS ST_NF"
	_sQuery += " 	  , ISNULL((SELECT ROUND(SUM(D2_TOTAL),2)"
    _sQuery += "           FROM SD2010 AS SD2"
    _sQuery += "       			INNER JOIN SF4010 AS SF4"
    _sQuery += "						ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "							AND SF4.F4_CODIGO   = SD2.D2_TES"
    _sQuery += "							AND SF4.F4_MARGEM   = '3')"
    _sQuery += "   		  WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL"
    _sQuery += "     		AND SD2.D2_DOC     = SF2.F2_DOC"
    _sQuery += "     		AND SD2.D2_SERIE   = SF2.F2_SERIE"
    _sQuery += "     		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE"
    _sQuery += "     		AND SD2.D2_LOJA    = SF2.F2_LOJA"
    _sQuery += "     		AND SD2.D2_EMISSAO = SF2.F2_EMISSAO"
    _sQuery += "  		 GROUP BY SD2.D2_FILIAL, SD2.D2_DOC, SD2.D2_SERIE),0) AS VLR_BONIFIC"
    _sQuery += "      , F2_FRETE AS FRETE_NF"
    _sQuery += "   FROM " +  RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "  WHERE SF2.F2_FILIAL   = '" + xfilial ("SF2") + "'"
	_sQuery += "    AND SF2.D_E_L_E_T_  = ''"
	_sQuery += "    AND SF2.F2_DOC      =  '" + _wnf + "'"
	_sQuery += "    AND SF2.F2_SERIE    =  '" + _wserie + "'"
	_sQuery += "    AND SF2.F2_CLIENTE  =  '" + _wcliente + "'"
	_sQuery += "    AND SF2.F2_LOJA     =  '" + _wloja + "'"
    
    //u_showmemo(_sQuery)
    
    _Nota := U_Qry2Array(_sQuery)
    If len(_Nota) > 0
    	_brutoNota = _Nota[1,1]
    	_baseNota  = _Nota[1,1] - _Nota[1,2] - _Nota[1,3] - _Nota[1,4] - _Nota[1,5]
    	_wparcST   := 0
    	
    	// se tem ST referenciada na nota - verifica se existi titulo sem separado para pagamento da mesma.
    	if _Nota[1,3] > 0
           	// verifica se a nota tem parcela separada de ST
			_sSQL := ""
		    _sSQL += " SELECT ISNULL(E1_VALOR,0)"
		   	_sSQL += "   FROM " + RetSQLName ("SE1") + " AS SE1A " 
		   	_sSQL += "  WHERE SE1A.E1_FILIAL  = '" + xfilial ("SE1") + "'"
		   	_sSQL += "    AND SE1A.E1_PREFIXO = '" + _wserie + "'"
		   	_sSQL += "    AND SE1A.E1_NUM     = '" + _wnf + "'"
		   	_sSQL += "    AND SE1A.E1_PARCELA = 'A' "
		   	_sSQL += "    AND SE1A.E1_NATUREZ = '110199' "
		   	_sSQL += "    AND SE1A.D_E_L_E_T_ = ''"
   	
   			//u_showmemo(_sSQL)
   			
    		_parcST := U_Qry2Array(_sSQL)
	    	If len(_parcST) > 0
	    		_wparcST = _parcST[1,1]
	    	Endif
	    endif
		// recalcula
		_wbaseCom = (_baseNota * _wvalor) / (_brutoNota - _wparcST - _Nota[1,4] )
	endif
	
return _wbaseCom	    	    
