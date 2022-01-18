// Programa.: VA_McPed
// Autor....: Robert Koch
// Data.....: 06/07/2016
// Descricao: Tela de consulta de margem de contribuicao no pedido de venda.
//            Criada com base no A410CONS de Adelar Minuzzo, onde era 'static function'.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta #tela
// #Descricao         #Tela de consulta de margem de contribuicao no pedido de venda.
// #PalavasChave      #margem #consulta_de_margem #pedido_de_venda
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT 
//
// Historico de alteracoes:
//
// 28/01/2017 - Catia   - alteracao para incluir os % de frete e o % financeiro que nao considerava
// 08/06/2017 - Catia   - alterado para buscar o percentual conforme a nova regra de rapel por cliente/linha/item
// 01/12/2017 - Robert  - Mostra percentuais de comissao, frete e financeiro junto com os valores.
//                      - Alterado browse para usar fonte monoespacada (melhor alinhamento).
//                      - Calcula acrescimo financeiro de acordo com as datas das parcelas cfe. cond.pagto.
// 05/12/2017 - Julio   - Tratamento para cond. pagto. com dias fixos.
// 30/01/2018 - Catia   - criada a opcao de base de rape 3 = total nf-st
// 14/02/2018 - Robert  - Criado tratamento para quando a cond.pagto. nao permitia calcular a qt. de meses.
// 16/02/2018 - Catia   - Estava considerado frete FOB para calculo da margem
// 03/07/2018 - Robert  - Passa a receber parametro indicando se deve atualizar cotacao de frete.
//                      - Preferencia pela cotacao de frete da 'nossa' transportadora (soh busca outras se nao
//						  achar valor pela nossa).
//                      - Grava evento descrevendo a cotacao do frete (mostra junto na consulta). 
//                      - Mostra % de PIS/COFINS e descricao do produto
// 18/07/2018 - Robert  - Busca % frete do campo A1_VAFRNEG, quando informado.
// 04/10/2018 - Robert  - Tratamento para novas opcoes de frete: C=CIF;F=FOB;T=Por conta terceiros;R=Por conta remetente;
//						  D=Por conta destinatário;S=Sem frete
// 12/08/2019 - Robert  - Desabilitado uso da funcao MSMM para leitura do ZN_CODMEMO (migrado para campo real).
// 22/11/2019 - Robert  - Removidos tratamentos para PVCond pois nao usamos mais desde 2004.
//                      - Removida leitura parametro ML_BONIF (dava possibilidade de validar bonificacoes 
//						  pelo custo de reposicao, o que nunca foi usado).
// 29/11/2019 - Robert  - Passa a usar [valor mercadorias] e nao mais [valor mercadorias + IPI] como base para frete 
//					      e despesas financeiras (GLPI 7109).
// 12/12/2019 - Andre   - Ajustado calculo financeiro para considerar quantidade de dias e não mês cheio.
// 16/01/2020 - Andre   - Alterado valor do PIS/CONFIS de 3.2 para 9.25 
// 27/01/2020 - Robert  - Quando a cond.pagto/TES nao gera duplicata, dava erro na leitura da maior data de vencimento.
// 05/03/2020 - Andre   - Para calculo financeiro, testa se condição de pagamento é diferente de 007.
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
// 17/08/2020 - Robert  - Passa a buscar percentuais de frete na tabela GU9 (regioes fretes) e nao mais no E-Sales, 
//                        nem historico do cliente (GLPI 8180).
// 17/05/2021 - Claudia - Ajuste no calculo de margem frete. GLPI: 9883
// 04/10/2021 - Claudia - Alterada a função _CalcFrt, conforme GLPI: 11009
// 06/10/2021 - Claudia - Incluido o parametro _lNAWeb para carregar ou nao o array de dados da margem. GLPI: 7792
// 07/10/2021 - Claudia - Incluida gravação dos registros nos eventos, para busca no NaWeb. GLPI 7792
// 26/10/2021 - Claudia - Alterado o modo de gravação do evento SC5009.
// 18/01/2022 - CLaudia - Retirada busca de frete negociado, conforme GLPI: 11482
//
// ------------------------------------------------------------------------------------------------------------------------
#include "VA_Inclu.prw"
#include "rwmake.ch"

User function VA_McPed (_lComTela, _lAtuFrt)
	local _aAmbAnt  := U_SalvaAmb ()
	local _aAreaAnt := U_ML_SRArea ()
	
	u_log2 ('info', 'Iniciando calculo de margem para o pedido ' + m->c5_num)
	
	_lComTela = iif (_lComTela == NIL, .T., _lComTela)

	_AndaLogo (_lComTela, _lAtuFrt)

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
Return
//
// --------------------------------------------------------------------------
static function _AndaLogo (_lMostra, _lAtuFrt)
	local _nValor     := 0
	local _nQuant     := 0
	local _ncusto     := 0
	local _ncomis     := 0
	local _nicm       := 0
	local _nimp       := 0
	local _nrapel     := 0
	local _nfrete     := 0
	local _nfinan     := 0
	local _ntotal     := 0
	local _xtotbonif  := 0
	local _xtotFrete  := 0
	local _aArqTrb    := {}
	local _aCampos    := {}
	local _aCpos      := {}
	local _aNaWeb     := {}
	Local _nPosValor  := aScan(aHeader, {|x| AllTrim(x[2])=="C6_VALOR"})
	Local _nPosTes    := aScan(aHeader, {|x| AllTrim(x[2])=="C6_TES"})
	Local _nPosprd    := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local _nPosqtd    := aScan(aHeader, {|x| AllTrim(x[2])=="C6_QTDVEN"})
	Local _nPosunit   := aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRUNIT"})
	Local _nPoscomis1 := aScan(aHeader, {|x| AllTrim(x[2])=="C6_COMIS1"})
	Local _nPosBlq    := aScan(aHeader, {|x| AllTrim(x[2])=="C6_BLQ"})
	Local _nPosDescr  := aScan(aHeader, {|x| AllTrim(x[2])=="C6_DESCRI"})
	local _oDlg2      := NIL
	local xbonif      := .F.
	local _iX         := 0
	local _nLoop      := 0
	local _nLoops     := 0
	local _aVctos     := {}
	local _nPAcrFin   := 0
	local _DataInfo   := 'N'
	local _sMsgFrt    := ""
	local _lFrtNegoc  := .F.
	local _nPISCOF    := 9.25  // A cooperativa tem reducao de base de calculo. // Era 3.2
	local _pfrete     := 0
	local _x          := 0
	private _oEventoCF := NIL  // Deixar private. Para gravar dados da cotacao de frete, caso necessario.

	u_log2 ('debug', 'Atualizar frete: ' + cvaltochar (_lAtuFrt))

	aadd (_aCampos, {"c6_Produto", "C", 40, 0})
	aadd (_aCampos, {"c6_Quant",   "N", 15, 2})
	aadd (_aCampos, {"c6_Quant2",  "C", 15, 0})
	aadd (_aCampos, {"c6_Preco",   "N", 15, 2})
	aadd (_aCampos, {"c6_Preco2",  "C", 15, 0})
	aadd (_aCampos, {"c6_Custo",   "N", 15, 2})
	aadd (_aCampos, {"c6_Custo2",  "C", 15, 0})
	aadd (_aCampos, {"c6_PerCom",  "N", 6,  2})
	aadd (_aCampos, {"c6_Comis",   "N", 15, 2})
	aadd (_aCampos, {"c6_Comis2",  "C", 20, 0})
	aadd (_aCampos, {"c6_Imp",     "N", 15, 2})
	aadd (_aCampos, {"c6_Imp2",    "C", 17, 0})
	aadd (_aCampos, {"c6_ICM",     "N", 15, 2})
	aadd (_aCampos, {"c6_ICM2",    "C", 15, 0})
	aadd (_aCampos, {"c6_Rapel",   "N", 15, 2})
	aadd (_aCampos, {"c6_Rapel2",  "C", 20, 0})
	// percentuais novos que nao existiam para fechar com a margem calculada/margem de bloqueio no Mercanet
	aadd (_aCampos, {"c6_Frete",   "N", 15, 2})
	aadd (_aCampos, {"c6_Frete2",  "C", 20, 0})
	aadd (_aCampos, {"c6_Finan",   "N", 15, 2})
	aadd (_aCampos, {"c6_Finan2",  "C", 20, 0})
	
	aadd (_aCampos, {"c6_Total",   "N", 15, 2})
	aadd (_aCampos, {"c6_Total2",  "C", 15, 0})
	aadd (_aCampos, {"c6_Mper",    "N", 15, 2})
	aadd (_aCampos, {"c6_Mper2",   "C", 15, 0})

	U_ArqTrb ("Cria", "_trb", _aCampos, {}, @_aArqTrb)

	// Evento para mostrar/gravar historico de cotacao de frete.
	_oEventoCF := ClsEvent():New ()

	if M->C5_TPFRETE $ 'FTDS'  // C=CIF;F=FOB;T=Por conta terceiros;R=Por conta remetente;D=Por conta destinatário;S=Sem frete                                    
		_oEventoCF:Texto += 'Frete FOB/3os/Destinatario/. Considerando percentual zerado.' + chr (13) + chr (10)
		m->c5_mvfre = 0
		_pfrete = 0
	else

		// Se nao vai atualizar a cotacao de frete, busca historico da cotacao no ultimo evento registrado.
		if _lAtuFrt
			
			// Se tiver frete negociado no cliente, nem faz cotacao no entregou.com
			//_pFrete = FBuscaCpo("SA1",1,XFILIAL("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_VAFRNEG")
			//if _pFrete > 0
			//	_lFrtNegoc = .T.
			//	_oEventoCF:Texto += 'Assumindo percentual de frete negociado (' + cvaltochar (_pfrete) + ') conforme cadastro do cliente (campo ' + alltrim (RetTitle ("A1_VAFRNEG")) + ')' + chr (13) + chr (10)
			//else			
				// estamos migrando para tabela fixa de fretes cfe GLPI 8180 --->	m->c5_mvfre = _CalcFrete ()
				m->c5_mvfre = _CalcFrt ()
				u_log2 ('debug', 'm->c5_mvfre apos _CalcFrete(): ' + cvaltochar (m->c5_mvfre))
			//endif
		else
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT TOP 1 R_E_C_N_O_"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZN") + " SZN "
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZN_FILIAL  = '" + xfilial ("SZN") + "'"
			_oSQL:_sQuery +=   " AND ZN_PEDVEND = '" + m->c5_num + "'"
			_oSQL:_sQuery +=   " AND ZN_CODEVEN = 'SC5008'"
			_oSQL:_sQuery +=   " ORDER BY R_E_C_N_O_ DESC"  // Caso tenha mais de um evento, quero o mais recente.
			_nRegSZN = _oSQL:RetQry (1, .F.)

			if _nRegSZN > 0
				szn -> (dbgoto (_nRegSZN))
				_oEventoCF:Texto    = alltrim (szn -> zn_txt) //MSMM (SZN -> ZN_CODMEMO)
				_oEventoCF:CodEven  = 'SC5008'
				_oEventoCF:PedVenda = m->c5_num
				_oEventoCF:Cliente  = m->c5_cliente
				_oEventoCF:LojaCli  = m->c5_lojacli
			else
				u_log2 ('Nao achei evento previo de calculo de margem.')
			endif
		endif

		// Se jah tem valor do frete (provavelmente tenha sido feita selecao de transportadora), posso
		// calcular o percentual de frete. Caso contrario, busco no historico do cliente.
		u_log2 ('debug', 'testando m->c5_mvfre = ' + cvaltochar (m->c5_mvfre))
		if m->c5_mvfre > 0
			_pfrete = 0
			For _ix := 1 To Len(aCols)
				if GDFieldGet ("C6_BLQ", _iX) != 'S'
					_pfrete += GDFieldGet ("C6_PRCVEN", _iX) * GDFieldGet ("C6_QTDVEN", _iX)
				endif
			next
			_pfrete = m->c5_mvfre * 100 / _pfrete
		endif
	endif
	u_log2 ('debug', 'Finalizei com _pfrete = ' + cvaltochar (_pfrete) + ' e m->c5_mvfre = ' + cvaltochar (m->c5_mvfre))

	_wbaserapel := fBuscaCpo("SA1",1,xfilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_VABARAP")

	// Calcula quantidade de 'meses completos' para aplicar % de acrescimo financeiro a cada 30 dias.
	_nDataIni := 0
	_nDataFim := 0
	_nQtdDias := 0
	
	_DataInfo = 'N'
	if .not. Empty(M->C5_DATA1)
		_DataInfo = 'S'
		_nDataIni = (M->C5_DATA1)
		_nDataFim = (M->C5_DATA1)
	endif

	if .not. Empty(M->C5_DATA2)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA2)
	endif

	if .not. Empty(M->C5_DATA3)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA3)
	endif

	if .not. Empty(M->C5_DATA4)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA4)
	endif

	if .not. Empty(M->C5_DATA5)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA5)
	endif

	if .not. Empty(M->C5_DATA6)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA6)
	endif

	if .not. Empty(M->C5_DATA7)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA7)
	endif

	if .not. Empty(M->C5_DATA8)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA8)
	endif

	if .not. Empty(M->C5_DATA9)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATA9)
	endif

	if .not. Empty(M->C5_DATAA)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATAA)
	endif

	if .not. Empty(M->C5_DATAB)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATAB)
	endif

	if .not. Empty(M->C5_DATAC)
		_DataInfo = 'S'
		_nDataFim = (M->C5_DATAC)
	endif

	if _DataInfo = 'N'
		_aVctos = aclone (Condicao (1000, m->c5_condpag,, date ()))
	else
		_aVctos := {}
		AADD (_aVctos,{_nDataIni,1})
		AADD (_aVctos,{_nDataFim,1})
	endif
	
	// Se nao gera duplicata, assume a data atual.
	if len (_aVctos) == 0
		u_log2 ('info', "Condicao de pagamento nao gerou nenhuma parcela. Assumindo data atual.")
		_nDataIni := date ()
		_nDataFim := date ()
	else
		_nDataIni := _aVctos[1,1]
		_nDataFim := _aVctos[Len(_aVctos),1]
	endif
	
	if m->c5_condpag != '007' .and. _nDataIni >= DATE() + 30 
		_nQtdDias = ((_nDataIni - DATE () + _nDataFim - DATE ()) / 2 )
	endif
	
	// Se for uma consulta a partir da consulta de clientes, os calculos soh ficam corretos
	// apos fechar e reabrir a tela. Farei um loop para quebrar o galho. Perdoai, usuarios, este remendo...
	if funname () == "FINC010"
		_nLoops = 2
	else
		_nLoops = 1
	endif

	for _nLoop = 1 to _nLoops
		// Inicializa para buscar valor liquido do item no pedido
		MaFisIni(M->C5_CLIENTE,;				// 1-Codigo Cliente/Fornecedor
		M->C5_LOJACLI,;							// 2-Loja do Cliente/Fornecedor
		IIf(M->C5_TIPO$'DB',"F","C"),;			// 3-C:Cliente , F:Fornecedor
		M->C5_TIPO,;							// 4-Tipo da NF
		M->C5_TIPOCLI,;							// 5-Tipo do Cliente/Fornecedor
		MaFisRelImp("MT100",{"SF2","SD2"}),;	// 6-Relacao de Impostos que suportados no arquivo
		,;						   				// 7-Tipo de complemento
		,;										// 8-Permite Incluir Impostos no Rodape .T./.F.
		"SB1",;									// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
		"MATA410")								// 10-Nome da rotina que esta utilizando a funcao
		_nitem:= 0
		
		For _ix := 1 To Len(aCols)
			// Valida se a Linha Nao estiver deletada
			_ValInclui := _RetType("Inclui")
			_ValAltera := _RetType("Altera")
			
			If ( _ValInclui == "L" .And. Inclui ) .Or. ( _ValAltera == "L" .And. Altera )  
				_lOk := !aCols[_ix,Len(aHeader)+1]
			Else
				_lOk := .T.
			Endif
			
			if  aCols[_ix,_nPosBlq] = "R"
				u_log2 ('debug', 'Bloqueio por residuo na linha ' + cvaltochar (_ix))
				_lOk := .F.
			endif
			
			If _lOk
				xBONIF  := IIF(fBuscaCpo("SF4",1,xFilial("SF4")+aCols[_ix,_nPosTes],"F4_MARGEM")== "3" ,.T.,.F.)
				
				MaFisAdd(aCols[_ix,_nPosprd],;// 1-Codigo do Produto ( Obrigatorio )
				aCols[_ix,_nPosTes],;		  // 2-Codigo do TES ( Opcional )
				aCols[_ix,_nPosqtd],;		  // 3-Quantidade ( Obrigatorio )
				aCols[_ix,_nPosunit],;		  // 4-Preco Unitario ( Obrigatorio )
				0,;                           // 5-Valor do Desconto ( Opcional )
				NIL,;		                  // 6-Numero da NF Original ( Devolucao/Benef )
				NIL,;		                  // 7-Serie da NF Original ( Devolucao/Benef )
				NIL,;			              // 8-RecNo da NF Original no arq SD1/SD2
				0,;							  // 9-Valor do Frete do Item ( Opcional )
				0,;							  // 10-Valor da Despesa do item ( Opcional )
				0,;            				  // 11-Valor do Seguro do item ( Opcional )
				0,;							  // 12-Valor do Frete Autonomo ( Opcional )
				aCols[_ix,_nPosvalor],;       // 13-Valor da Mercadoria ( Obrigatorio )
				0,;							  // 14-Valor da Embalagem ( Opiconal )
				0,;		     				  // 15-RecNo do SB1
				0) 							  // 16-RecNo do SF4
				
				_nitem++
				
				// Soh grava na ultima passagem
				if _nLoop == _nLoops
					If FBuscaCpo("SF4",1,XFILIAL("SF4")+aCols[_ix,_nPosTes],"F4_DUPLIC") <> "N"
						
						// O valor do IPI esta embutido no preco - nao eh destacado
						_xvalmerc:= mafisret(_nitem, "IT_VALMERC")
						_xvalicm := mafisret(_nitem, "IT_VALICM")
						_xvalipi := mafisret(_nitem, "IT_VALIPI")
						_xvalst  := MaFisRet(_nitem, "IT_VALSOL")
											
						reclock ("_trb", .T.)
						_trb -> c6_produto = alltrim (aCols[_ix,_nPosprd]) + ' - ' + alltrim (aCols[_ix,_nPosDescr])
						_trb -> c6_quant   = aCols[_ix,_nPosqtd]
						_trb -> c6_quant2  = transform (c6_quant, "@E 999999.99")
						_trb -> c6_preco   = aCols[_ix,_nPosValor]

						_trb -> c6_preco2  = transform (c6_preco, "@E 999,999.99")
						_trb -> c6_custo   = (_trb-> c6_quant * FBUSCACPO('SB1',1,xFilial('SB1') + aCols[_ix,_nPosprd],'SB1->B1_CUSTD'))
						_trb -> c6_custo2  = transform (c6_custo, "@E 999999.99")
						_trb -> c6_comis   = (_trb -> c6_preco * aCols[_ix,_nPosComis1])/100
						_trb -> c6_comis2  = transform (c6_comis, "@E 999999.99") + ' (' + alltrim (transform (aCols[_ix,_nPosComis1], "@E 99.9")) + '%)'
						_trb -> c6_icm     = _xvalicm
						_trb -> c6_icm2    = transform (c6_icm, "@E 999999.99")
						_trb -> c6_imp     = _trb -> c6_preco * _nPISCOF / 100
						_trb -> c6_imp2    = transform (c6_imp, "@E 999999.99") + ' (' + alltrim (transform (_nPISCOF, "@E 99.9")) + '%)'
						
					
						// -- alterado para buscar o percentual conforme a nova regra de rapel por cliente/linha/item
						_txrapel = 0
						if val(_wbaserapel) > 0   /// 0= nao tem rapel 1= total da nota   2 = total da mercadoria
							// manda pra função pra buscar o percentual
							_txrapel    := u_va_rapel(M->C5_CLIENTE, M->C5_LOJACLI, aCols[_ix,_nPosprd])
							// calcula o valor do rapel com base no percentual e indicador da base
							do case 
								case _wbaserapel == '1' // 1= base nota (merc + st + ipi)
									_trb -> c6_rapel   = ((_trb -> c6_preco + _xvalipi +_xvalst )* _txrapel)/100
								case _wbaserapel == '2' // 2 = base mecadoria									
									_trb -> c6_rapel   = ((_trb -> c6_preco)* _txrapel)/100
								case _wbaserapel == '3' // 2 = total nf - st			
									_trb -> c6_rapel   = ((_trb -> c6_preco + _xvalipi )* _txrapel)/100
							endcase
						else
							_trb -> c6_rapel   = 0
						endif	

						_trb -> c6_rapel2  = transform (c6_rapel, "@E 999999.99") + ' (' + alltrim (transform (_txrapel, "@E 99.9")) + '%)'
						
						// --- percentuais que faltavam para fechar a margem de bloqueio com o Mercanet
						_trb -> c6_frete   = ((_trb -> c6_preco)* _pfrete)/100
						_trb -> c6_frete2  = transform (_trb -> c6_frete, "@E 999999.99") + ' (' + alltrim (transform (_pfrete, "@E 99.9")) + '%)'

						_nPacrFin = 0.05 * _nQtdDias  // 0,05% por dia, após os 30 primeiros
						_trb -> c6_Finan   = (_trb -> c6_preco) * _nPAcrFin / 100
						_trb -> c6_Finan2  = transform (c6_Finan, "@E 999999.99") + ' (' + alltrim (transform (_nPacrFin, "@E 99.9")) + '%)'

						_trb -> c6_total   = _trb-> c6_preco - (_trb -> c6_custo+_trb -> c6_comis + _trb -> c6_imp + _trb -> c6_icm + _trb -> c6_rapel + _trb -> c6_frete + _trb -> c6_finan)
						_trb -> c6_total2  = transform (c6_total, "@E 999,999.99")
						_trb -> c6_mper    = (_trb-> c6_total / _trb -> c6_preco) * 100
						_trb -> c6_mper2   = transform (c6_mper, "@E 999999.99")

						aadd(_aNaWeb, { _trb -> c6_produto	,;
										_trb -> c6_quant2	,;
										_trb -> c6_preco2 	,;
										_trb -> c6_custo2	,;
										_trb -> c6_comis2	,;
										_trb -> c6_icm2		,;
										_trb -> c6_imp2		,;
										_trb -> c6_rapel2	,;
										_trb -> c6_frete2	,;
										_trb -> c6_Finan2	,;
										_trb -> c6_total2 	,;
										_trb -> c6_mper2	})

						
						msunlock()
						_nValor	+= _trb -> c6_preco
						_nQuant	+= _trb -> c6_quant
						_ncusto	+= _trb -> c6_custo
						_ncomis	+= _trb -> c6_comis
						_nicm  	+= _trb -> c6_icm
						_nimp  	+= _trb -> c6_imp
						_nrapel	+= _trb -> c6_rapel
						_nfrete += _trb -> c6_frete
						_nfinan += _trb -> c6_finan
						_ntotal += _trb -> c6_total

					ElseIf XBONIF
						// Soma o ICMS e o IPI da Bonificacao
						_xTOTIMP := mafisret(_nitem,"IT_VALICM") + mafisret(_nitem,"IT_VALIPI")
						_xtotbonif += aCols[_ix,_nPosValor] + _xTOTIMP
					Endif
				endif
			Endif
		Next
		// Limpa variaveis da rotina para valor liquido dos itens do pedido
		MaFisEnd()
	next
	msunlock ()
	
	u_log2 ('debug', 'finalizei loop com _nFrete = ' + cvaltochar (_nFrete))
	// Quando usa % de frete negociado no cadastro do cliente (o valor do frete nao eh buscado no
	// entregou.com e nem estava gravado no pedido), preciso pegar o que foi calculado na montagem da tela.
	if _lAtuFrt .and. _lFrtNegoc
		m->c5_mvfre = _nFrete
	endif 

	//total dos itens
	reclock ("_trb", .T.)
	_trb -> c6_produto = "Total Pedido"
	_trb -> c6_quant   = _nquant
	_trb -> c6_quant2  = transform (c6_quant, "@E 999999.99")
	_trb -> c6_preco   = _nvalor
	_trb -> c6_preco2  = transform (c6_preco, "@E 999,999.99")
	_trb -> c6_custo   = _ncusto
	_trb -> c6_custo2  = transform (c6_custo, "@E 999999.99")
	_trb -> c6_comis   = _ncomis
	_trb -> c6_comis2  = transform (c6_comis, "@E 999999.99")
	_trb -> c6_icm     = _nIcm
	_trb -> c6_icm2    = transform (c6_icm, "@E 999999.99")
	_trb -> c6_imp     = _nimp
	_trb -> c6_imp2    = transform (c6_imp, "@E 999999.99")
	_trb -> c6_rapel   = _nrapel
	_trb -> c6_rapel2  = transform (c6_rapel, "@E 999999.99")
	// percentuais novos que faltavam
	_trb -> c6_frete   = _nfrete
	_trb -> c6_frete2  = transform (c6_frete, "@E 999999.99")
	_trb -> c6_finan   = _nfinan
	_trb -> c6_finan2  = transform (c6_finan, "@E 999999.99")
	_trb -> c6_total   = _ntotal
	_trb -> c6_total2  = transform (c6_total, "@E 999,999.99")
	_trb -> c6_mper    = (_trb-> c6_total / _trb -> c6_preco)* 100
	_trb -> c6_mper2   = transform (c6_mper, "@E 99,999.99")
	msunlock ()
	

	aadd(_aNaWeb, { "Total Pedido"		,;
					_trb -> c6_quant2	,;
					_trb -> c6_preco2 	,;
					_trb -> c6_custo2	,;
					_trb -> c6_comis2	,;
					_trb -> c6_icm2		,;
					_trb -> c6_imp2		,;
					_trb -> c6_rapel2	,;
					_trb -> c6_frete2	,;
					_trb -> c6_Finan2	,;
					_trb -> c6_total2 	,;
					_trb -> c6_mper2	})

				
	// bonificacao
	reclock ("_trb", .T.)
	_trb -> c6_produto = "Bonificacao"
	_trb -> c6_total   = _xtotbonif
	_trb -> c6_total2  = transform (c6_total, "@E 999,999.99")
	_trb -> c6_mper    = (_xtotbonif / _nvalor)*100
	_trb -> c6_mper2   = transform (c6_mper, "@E 99,999.99")
	msunlock ()

	aadd(_aNaWeb, { "Bonificacao"		,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					_trb -> c6_total2 	,;
					_trb -> c6_mper2	})

	
	_xtotFrete :=0
	
	// Total
	reclock ("_trb", .T.)
	_trb -> c6_produto = "Total"
	_trb -> c6_total   = _ntotal   - (_xtotbonif + _xtotFrete)
	_trb -> c6_total2  = transform (c6_total, "@E 999,999.99")
	_trb -> c6_mper    = ((_ntotal - (_xtotbonif + _xtotFrete)) / _nvalor)*100 
	_nTotMrg := ((_ntotal - (_xtotbonif + _xtotFrete)) / _nvalor)*100 
	_trb -> c6_mper2   = transform (c6_mper, "@E 99,999.99")
	msunlock ()

	aadd(_aNaWeb, { "Total"				,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					"0"					,;
					_trb -> c6_total2 	,;
					_trb -> c6_mper2	})

	
	// Define titulos das colunas
	aadd (_aCpos, {"c6_Produto", "Produto"})
	aadd (_aCpos, {"c6_quant2" , "Quantidade"})
	aadd (_aCpos, {"c6_Preco2" , "Venda"})
	aadd (_aCpos, {"c6_Custo2" , "Custo repos"})
	aadd (_aCpos, {"c6_Comis2" , "Comissao"})
	aadd (_aCpos, {"c6_Icm2"   , "ICMS"})
	aadd (_aCpos, {"c6_Imp2"   , "PIS/COF"})
	aadd (_aCpos, {"c6_Rapel2" , "Rapel"})
	aadd (_aCpos, {"c6_Frete2" , "Frete"})
	aadd (_aCpos, {"c6_Finan2" , "Financeiro"})
	aadd (_aCpos, {"c6_Total2" , "Margem Vlr"})
	aadd (_aCpos, {"c6_Mper2"  , "% Margem "})
	
	_trb -> (dbgotop ())

	m->c5_vaMCont = _nTotMrg

	if _lMostra
		_sMsgFrt = _oEventoCF:Texto
		define msdialog _oDlg2 from 0, 0 to oMainWnd:nClientHeight * 0.9, oMainWnd:nClientwidth * 0.98 of oMainWnd pixel title "Margem pedido " + m->c5_num + ' - cliente ' + m->c5_cliente
		_oBrwTrb := IW_Browse (5, 5, _oDlg2:nClientHeight / 3 - 5, _oDlg2:nClientWidth / 2 - 10, '_trb', "", "", _aCpos)
		@ _oDlg2:nClientHeight / 3 + 5, 5 get _sMsgFrt MEMO size (_oDlg2:nClientWidth / 2 - 55), (_oDlg2:nClientHeight / 6 - 10) when .T. object _oGetMemo // Se colocar when .F., nao tem barra de rolagem
		_oGetMemo:oFont := TFont():New ("Courier New", 7, 16)
		@ (_oDlg2:nClientHeight / 2 - 30), (_oDlg2:nClientWidth / 2 - 40) button "OK"                 action (close (_oDlg2))
		activate msdialog _oDlg2 centered
	endif

	If Len(_aNaWeb) > 0
		// Deleta registros já gravados
		// Elimina evento anterior, se houver
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " DELETE FROM " + RetSQLName ("SZN") 
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND ZN_FILIAL  = '" + xfilial ("SZN")     + "'"
		_oSQL:_sQuery += " AND ZN_DATA    = '" + DTOS(m->c5_emissao) + "'"
		_oSQL:_sQuery += " AND ZN_PEDVEND = '" + m->c5_num           + "'"
		_oSQL:_sQuery += " AND ZN_CLIENTE = '" + m->c5_cliente       + "'"
		_oSQL:_sQuery += " AND ZN_LOJACLI = '" + m->c5_lojacli       + "'"
		_oSQL:_sQuery += " AND ZN_CODEVEN = 'SC5009'"
		_oSQL:Exec ()

		For _x:=1 to Len(_aNaWeb)
			_sX := PADL(alltrim(str(_x)),2,'0') 

			_sTxtEvent := _sX + "|" + alltrim(_aNaWeb[_x, 1])
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 2]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 3]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 4]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 5]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 6]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 7]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 8]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x, 9])
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x,10]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x,11]) 
			_sTxtEvent += "|" + alltrim(_aNaWeb[_x,12]) 

			_GravaNaWeb(_sTxtEvent)
		Next 

	EndIf
	
	
	U_ArqTrb ("fechatodos", ,,, @_aArqTrb)
return _aNaWeb
//
// --------------------------------------------------------------------------
// Calcula valor do frete para posterior uso no calculo da margem de contribuicao.
static function _CalcFrt ()
	local _nRetFrt   := 0
	local _oSQL      := NIL
	local _oEvtAnt   := NIL
	local _nRegSZN   := 0
	local _sTxtEvent := ''
	local _nVlProdut := 0
	local _nLinCols  := 0
	local _x	     := 0
	local _aGUL      := {}
	local _aGU9      := {}
	local _nFrete    := 0

	_sFilial := m->c5_filial
	_sEst    := m->c5_vaest
	_sCEP    := Posicione("SA1",1, xFilial("SA1") + m->c5_cliente, "A1_CEP")

	u_log2 ('info', "FRETE: "+_sFilial+" - "+ _sEst + " - "+ _sCEP)
	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		GUL_VAPFRE "
	_oSQL:_sQuery += " FROM " + RetSQLName ("GUL") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND GUL_FILIAL   = '" + _sFilial + "' "
	_oSQL:_sQuery += " AND '" + _sCEP + "' BETWEEN GUL_CEPINI AND GUL_CEPFIM "
	_aGUL := aclone (_oSQL:Qry2Array ())

	// Se existir na tabela GUL -> 1º opção
	If len(_aGUL) > 0
		For _x := 1 to Len(_aGUL)
			_nFrete := _aGUL[_x, 1]
			_sTxtEvent += "Usado % de frete para CEP '"+ _sCEP +"' "
		Next
		u_log2 ('info', "FRETE: GUL")
	EndIf

	// Se não existir na GUL ou se for zerado, busca da GU9 -> 2º opção
	If _nFrete == 0
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 		GU9_VAPFRE "
		_oSQL:_sQuery += " FROM " + RetSQLName ("GU9") 
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND GU9_FILIAL   = '" + _sFilial + "'"
		_oSQL:_sQuery += " AND GU9_CDUF     = '" + _sEst    + "'"
		_oSQL:_sQuery += " AND GU9_SIT      = '1'"
		_aGU9 := aclone (_oSQL:Qry2Array ())
		u_log2 ('info', "FRETE: GU9 1")
		
		For _x:=1 to Len(_aGU9)
			_nFrete := _aGU9[_x, 1]
			_sTxtEvent += "Usado % de frete para UF '"+ _sEst +"' "
			//u_help (_sTxtEvent,, .t.)
			u_log2 ('info', "FRETE: GU9 2")
		Next
	EndIf

	Do Case
		Case len(_aGUL) == 0 .and. len(_aGU9) == 0 
			_sTxtEvent += "Nao encontrado percentual de frete para a UF '" + _sEst +  "' e/ou CEP '"+ _sCEP +"' na tabela de regioes de fretes (GUL/GU9)."
			u_help (_sTxtEvent,, .t.)

		Case len(_aGUL) > 1 .or. len(_aGU9) > 1
			_sTxtEvent += "Existe mais de um percentual de frete para a UF '" + _sEst +  "' e/ou CEP '"+ _sCEP +"' na tabela de regioes de fretes (GUL/GU9)."
			u_help (_sTxtEvent,, .t.)

		otherwise
			for _nLinCols = 1 to len (aCols)
				u_log2 ('debug', GDFieldGet ("C6_VALOR", _nLinCols))
				if ! GDDeleted (_nLinCols) .and. empty (GDFieldGet ("C6_BLOQ", _nLinCols))
					_nVlProdut += GDFieldGet ("C6_VALOR", _nLinCols)
				endif
			next

			u_log2 ('debug', 'vl prod:' + cvaltochar (_nVlProdut))
			u_log2 ('debug', 'm->c5_vaVlFat:' + cvaltochar (m->c5_vaVlFat))
			_nRetFrt = _nVlProdut * _nFrete / 100
	EndCase

	if _nFrete > 0
		_sTxtEvent += "% frete p/" + cvaltochar (m->c5_vaest) + " e/ou " + _sCEP + " cfe.tabela regioes frete: " + cvaltochar (_nFrete) + " -> valor frete: " + alltrim (GetMv ('MV_SIMB1')) + " " + alltrim (transform (_nRetFrt, "@E 999,999,999.99"))
	endif

	if ! empty (_sTxtEvent)
		_oEventoCF = ClsEvent ():New ()
		_oEventoCF:Texto = _sTxtEvent
		_oEventoCF:CodEven = 'SC5008'
		_oEventoCF:PedVenda = m->c5_num
		_oEventoCF:Cliente = m->c5_cliente
		_oEventoCF:LojaCli = m->c5_lojacli

		// Elimina evento anterior, se houver
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT R_E_C_N_O_"
		_oSQL:_sQuery += " 		FROM " + RetSQLName ("SZN") + " SZN "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND ZN_FILIAL  = '" + xfilial ("SZN") + "'"
		_oSQL:_sQuery += " AND ZN_PEDVEND = '" + m->c5_num + "'"
		_oSQL:_sQuery += " AND ZN_CODEVEN = 'SC5008'"
		_nRegSZN = _oSQL:RetQry (1, .F.)

		if _nRegSZN > 0
			_oEvtAnt := ClsEvent ():New ()
			_oEvtAnt:RecnoSZN = _nRegSZN
			_oEvtAnt:Exclui ()
		endif

		// Grava o novo evento
		_oEventoCF:Grava()
	endif
return _nRetFrt
//
// --------------------------------------------------------------------------
// Retorno do type - type em looling nao é permitido da R25 
Static Function _RetType(_var)
	_type := type(_var)
Return _type
//
// --------------------------------------------------------------------------
// GRava registros de margem para NaWeb
Static Function _GravaNaWeb(_sTxtEvent)

	_oEvento = ClsEvent ():New () 
	_oEvento:Texto    = _sTxtEvent
	_oEvento:CodEven  = 'SC5009'
	_oEvento:PedVenda = m->c5_num
	_oEvento:Cliente  = m->c5_cliente
	_oEvento:LojaCli  = m->c5_lojacli
	_oEvento:DtEvento = m->c5_emissao
	_oEvento:HrEvento = time()
	_oEvento:Grava ()
Return
