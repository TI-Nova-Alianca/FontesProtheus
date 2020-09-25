/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ MSD2460  ³ Autor ³    Jeferson Rech      ³ Data ³ Dez/2005 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Ponto de Entrada apos Gravacao do Item (SD2) da NF de Saida³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Clientes Microsiga                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
// Historico de alteracoes:
// 23/04/2008 - Robert - Criados logs para analise de performance
// 23/05/2008 - Robert - Criado tratamento para calculo e gravacao de ICMS retido (subst.tributaria).
// 13/06/2008 - Robert - Ajustes gravacao ST
// 18/06/2008 - Robert - Gravacao do campo D2_CLASFIS.
// 02/07/2008 - Robert - Gravacao do campo D2_PVCOND passada do SF2460i para ca'.
// 22/09/2008 - Robert - Soh calcula ST para cliente nao 'ISENTO'
// 03/10/2008 - Robert - Grava campos d2_vaNFEnv, d2_vaSerEn, d2_vaItEnv
// 13/10/2008 - Robert - Nao grava mais campos padrao da ST. Passado para PE M460SOLI.
// 07/11/2008 - Robert - Zera valores quanto TES = 607
// 09/01/2009 - Robert - Gravacao do campo D2_RAPEL.
//                     - Comentariadas funcoes ATUSA7 e ATUSD2
// 02/02/2009 - Robert - Desabilitada gravacao do campo D2_RAPEL por que vamos criar novo controle de prev/realizado.
// 09/03/2009 - Robert - Novos parametros funcao de calculo de ST.
// 14/05/2009 - Robert - Gravacao do campo D2_VALTDCO
// 01/06/2009 - Robert - Campo D2_DESCRI excluido do dicionario de dados.
// 01/07/2009 - Robert - Novo criterio de gravacao do campo F2_VAMSGST
// 31/08/2009 - Robert - Novos parametros funcao de calculo da ST
// 02/09/2009 - Robert - Gravacao campos D2_vaCliOr e D2_vaLojOr.
// 14/10/2009 - Robert - Novos parametros funcao de calculo da ST.
// 28/10/2009 - Robert - Novo parametro para funcao de calculo da ST.
// 12/05/2010 - Robert - Gravacao campo d2_vaCustD.
// 23/09/2010 - Robert - Gravacao campo d2_vaCustD para a Vinicola passa a buscar valor da matriz.
// 11/10/2010 - Robert - Nao regrava mais o campo D2_CLASFIS (B1_ORIGEM foi reduzido de 2 para 1 posicao).
// 19/11/2010 - Robert - Grava D2_CLASFIS com '10' quando tiver calculo de ST ateh descobrirmos por que estah trazendo '00'
// 19/05/2011 - Robert - Regrava campo D2_ALIQSOL com a aliquota interna da UF destino quando tiver ST.
// 30/04/2013 - Robert - Calculo da ST passa a ser feito pela funcao CALCST3 (novos parametros).
// 14/04/2015 - Robert - Desabilitados calculos de ST no ambiente TESTE.
// 04/05/2015 - Catia  - tratamento de atualização do controle de verbas
// 14/04/2015 - Robert - Desabilitados calculos de ST (vamos usar ST pelo padrao do sistema).
// 12/09/2015 - Robert - Removidos tratamentos (jah desabilitados) de calculo e gravacao de ST customizada.
// 14/04/2016 - Robert - Gravacao do campo D2_VAOPT.
// 08/06/2017 - Catia  - Gravar percentual e valor de rapelo no SD2
// 30/01/2018 - Catia  - criada a opcao de base de rape 3 = total nf - dt
// 26/04/2018 - Catia  - ajuste no calculo do rapel quando fosse 3 = total da nota - ST

// ----------------------------------------------------------------------------------------------------------
User Function MSD2460()
	local _aAreaAnt  := U_ML_SRArea ()
	local _oEvento   := NIL

	// Posiciona Arquivos
	DbSelectArea("SF4")
	DbSetOrder(1)
	DbSeek(xFilial("SF4")+SD2->D2_TES,.F.)
	
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+SD2->D2_COD,.F.)

	// Atualiza campos do SD2
	RecLock("SD2",.F.)
	sd2 -> d2_vaNFEnv = sc6 -> c6_vaNFEnv
	sd2 -> d2_vaSerEn = sc6 -> c6_vaSerEn
	sd2 -> d2_vaItEnv = sc6 -> c6_vaItEnv
	sd2 -> d2_vaLtDCO = sc6 -> c6_vaLtDCO
	sd2 -> d2_vaCliOr = sc6 -> c6_vaCliOr
	sd2 -> d2_vaLojOr = sc6 -> c6_vaLojOr
	sd2 -> d2_vaCustD = sb1 -> b1_custd
	sd2 -> d2_vaOPT   = sc6 -> c6_vaOPT

	// Grava campo com a diferenca de preco lancada na empresa 02.
	If SC5->C5_PVCOND == 'S' .and. cEmpAnt == '01' .and. sf4 -> f4_duplic == "S" .and. SC6->C6_PVCOND > SC6 -> C6_PRCVEN
		SD2->D2_PVCOND := SC6->C6_PVCOND * SD2->D2_QUANT - SD2->D2_TOTAL
	endif

	// Apos atualizacao do sigafis em 16/11/2010, o campo D2_CLASFIS estah sendo gravado esporadicamente com 00 mesmo quando tem ST.
	if sd2 -> d2_clasfis == "000" .and. sd2 -> d2_bricms > 0 .and. sd2 -> d2_icmsret > 0
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SD2002"
		_oEvento:Texto     = "Regravacao campo D2_CLASFIS item " + alltrim (sd2 -> d2_item) + " (cont.ant.: '" + sd2 -> d2_clasfis + "')-recno:" + cvaltochar (sd2 -> (recno ()))
		_oEvento:NFSaida   = sd2 -> d2_doc
		_oEvento:SerieSaid = sd2 -> d2_serie
		_oEvento:PedVenda  = sd2 -> d2_pedido
		_oEvento:Cliente   = sd2 -> d2_cliente
		_oEvento:LojaCli   = sd2 -> d2_loja
		_oEvento:Produto   = sd2 -> d2_cod
		_oEvento:Grava ()
		sd2 -> d2_clasfis = "010"
	endif
	
	// GRAVA RAPEL
	if sf4 -> f4_margem == '1'  // so calcula rapel sobre vendas
		// verifica no cadastro do cliente se o cliente tem rapel
		_wbaserapel = fBuscaCpo ('SA1', 1, xfilial('SA1') + sd2 -> d2_cliente + sd2 -> d2_loja, "A1_VABARAP")
		if val(_wbaserapel) > 0   /// 0= nao tem rapel 1= total da nota   2 = total da mercadoria
			// manda pra função pra buscar o percentual
			_wperrapel = u_va_rapel(sd2 -> d2_cliente, sd2 -> d2_loja, sd2 -> d2_cod)	
			// calcula o valor do rapel com base no percentual e indicador da base
			do case
				case _wbaserapel == '1'
					_wvlrrapel = ROUND(sd2 -> d2_valbrut * _wperrapel/100,2)
				case _wbaserapel == '2'
					_wvlrrapel = ROUND(sd2 -> d2_total * _wperrapel/100,2)
				case _wbaserapel == '3'
					_wvlrrapel = ROUND( (sd2 -> d2_valbrut -  sd2 -> d2_icmsret) * _wperrapel/100 ,2)				 				
			endcase
			// atualiza D2 com percentual e valor de rapel
			sd2 -> d2_rapel  = _wperrapel
			sd2 -> d2_vrapel = _wvlrrapel
		endif
	endif		
	
	MsUnLock()

	U_ML_SRArea (_aAreaAnt)
	
Return (.T.)
