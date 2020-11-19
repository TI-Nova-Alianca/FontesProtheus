// Programa: MT120ISC
// Autor:    Robert Koch
// Data:     28/05/2012
// Funcao:   PE apos importacao de itens da sol.compra ou contr.parceria para o ped.compra/aut.entrega.
//           Criado inicialmente para preencher o campo C7_VAOBRA.
//
// Historico de alteracoes:
// 04/05/2012 - Robert - Tratamento para campo C3_VACONTA.
// 25/07/2012 - Robert - Tratamento para campos relativos ao PCO.
// 07/08/2012 - Robert - Tratamento para o campo C7_VAZZG.
// 06/02/2018 - Robert - Desabilitados campos de obra da planta de Lagoa Bela e respectivos financiamentos.
// 08/02/2018 - Catia  - ao gerar o pedido de compra assumir o valor digitado na solicitacao
// 16/10/2018 - Andre  - Ao trazer solicitação de compra, no pedido campo Razão Social é preenchido automaticamente.
// --------------------------------------------------------------------------
user function MT120ISC ()
	local _aAreaAnt := U_ML_SRArea ()
	//local _nCampo   := 0

	if nTipoPed != 2  // Ped. compra
		GDFieldPut ("C7_VAPROSE", sc1 -> c1_vaprose)
		GDFieldPut ("C7_PRECO"  , sc1 -> c1_vavluni)
		GDFieldPut ("C7_TOTAL"  , sc1 -> c1_vavluni * sc1-> c1_quant)
		GDFieldPut ("C7_OBS"    , sc1 -> c1_obs)
		GDFieldPut ("C7_VAFNOME", fBuscaCpo ('SA2', 1, xfilial ('SA2') + CA120FORN + CA120LOJ, 'A2_NOME'))
//		GDFieldPut ("C7_VAFNOME", sc1 -> c1_vanomfo)
//		GDFieldPut ("C7_VAOBRA" , sc1 -> c1_vaobra)

	else  // Aut.entrega
		GDFieldPut ("C7_DESCRI",  sc3 -> c3_vadescr)
		GDFieldPut ("C7_VAPROSE", sc3 -> c3_vaprose)
//		GDFieldPut ("C7_VAOBRA",  sc3 -> c3_vaobra)
		GDFieldPut ("C7_CONTA",   sc3 -> c3_vaConta)
		GDFieldPut ("C7_CO",      sc3 -> c3_co)
		GDFieldPut ("C7_CLASSE",  sc3 -> c3_classe)
		GDFieldPut ("C7_OPER1",   sc3 -> c3_oper1)
//		GDFieldPut ("C7_VAZZG",   sc3 -> c3_vaZZG)
//		GDFieldPut ("C7_VAZZGC",  sc3 -> c3_vaZZGC)
//		GDFieldPut ("C7_VAZZG2",  sc3 -> c3_vaZZG2)
		GDFieldPut ("C7_VAFCOBR", sc3 -> c3_vaFCObr)
		GDFieldPut ("C7_VAMtInv", sc3 -> c3_vaMtInv)
	endif

	U_ML_SRArea (_aAreaAnt)
return
