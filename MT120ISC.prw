// Programa: MT120ISC
// Autor:    Robert Koch
// Data:     28/05/2012
// Funcao:   PE apos importacao de itens da sol.compra ou contr.parceria para o ped.compra/aut.entrega.
//           Criado inicialmente para preencher o campo C7_VAOBRA.
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE apos importacao de itens da sol.compra ou contr.parceria para o ped.compra/aut.entrega
// #PalavasChave      #pedido_de_compra #dolicitacao_de_compra
// #TabelasPrincipais #SC7 #SC1
// #Modulos 		  #COM         
//
// Historico de alteracoes:
// 04/05/2012 - Robert  - Tratamento para campo C3_VACONTA.
// 25/07/2012 - Robert  - Tratamento para campos relativos ao PCO.
// 07/08/2012 - Robert  - Tratamento para o campo C7_VAZZG.
// 06/02/2018 - Robert  - Desabilitados campos de obra da planta de Lagoa Bela e respectivos financiamentos.
// 08/02/2018 - Catia   - ao gerar o pedido de compra assumir o valor digitado na solicitacao
// 16/10/2018 - Andre   - Ao trazer solicitação de compra, no pedido campo Razão Social é preenchido automaticamente.
// 15/01/2021 - Claudia - GLPI: 8286/8818. Acrescentados os campos C7_VADESTI|C7_VACCDES
// 04/05/2021 - Claudia - Acrescentado o campo C7_SOLICIT. GLPI:9814
// 15/10/2021 - Robert  - Acrescentado campo C7_vaNF.
// 15/02/2023 - Robert  - Alimentar campo C7_CODPRF. 
// 12/09/2023 - Claudia - Preenchimento do campo C7_OPER conforme especificação. GLPI: 14125
//
// -------------------------------------------------------------------------------------------------------------------
User function MT120ISC ()
	local _aAreaAnt := U_ML_SRArea ()

	if nTipoPed != 2  // Ped. compra
		GDFieldPut ("C7_VAPROSE", sc1 -> c1_vaprose)
		GDFieldPut ("C7_PRECO"  , sc1 -> c1_vavluni)
		GDFieldPut ("C7_TOTAL"  , sc1 -> c1_vavluni * sc1-> c1_quant)
		GDFieldPut ("C7_OBS"    , sc1 -> c1_obs)
		GDFieldPut ("C7_VAFNOME", fBuscaCpo ('SA2', 1, xfilial ('SA2') + CA120FORN + CA120LOJ, 'A2_NOME'))
		GDFieldPut ("C7_VADESTI", sc1 -> c1_vadesti)
		GDFieldPut ("C7_VACCDES", fbuscacpo('CTT',1,xfilial('CTT') + sc1 -> c1_cc ,'CTT_DESC01') )
		GDFieldPut ("C7_SOLICIT", sc1 -> c1_solicit)
		GDFieldPut ("C7_VANF"   , sc1 -> c1_vaNF)
		GDFieldPut ("C7_CODPRF" , fbuscacpo('SA5',1,XFILIAL("SA5")+CA120FORN+CA120LOJ+SC1->C1_PRODUTO,'A5_CODPRF') )
		GDFieldPut ("C7_OPER"   , iif(alltrim(sc1 -> c1_vaprose) == 'P','02','11'))
		//GDFieldPut ("C7_OPER"   , sc1 -> c1_vaNF)

	else  // Aut.entrega
		GDFieldPut ("C7_DESCRI",  sc3 -> c3_vadescr	)
		GDFieldPut ("C7_VAPROSE", sc3 -> c3_vaprose	)
		GDFieldPut ("C7_CONTA",   sc3 -> c3_vaConta	)
		GDFieldPut ("C7_CO",      sc3 -> c3_co		)
		GDFieldPut ("C7_CLASSE",  sc3 -> c3_classe	)
		GDFieldPut ("C7_OPER1",   sc3 -> c3_oper1	)
		GDFieldPut ("C7_VAFCOBR", sc3 -> c3_vaFCObr	)
		GDFieldPut ("C7_VAMtInv", sc3 -> c3_vaMtInv	)
		GDFieldPut ("C7_CODPRF", fbuscacpo('SA5',1,XFILIAL("SA5")+CA120FORN+CA120LOJ+SC1->C1_PRODUTO,'A5_CODPRF') )
	endif

	U_ML_SRArea (_aAreaAnt)
Return
