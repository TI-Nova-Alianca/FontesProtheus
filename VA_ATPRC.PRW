// Programa:   VA_AtPrc
// Autor:      Bruno Silva
// Data:       26/02/2014
// Descricao:  Programa para atualizar a tabela de preço, filtrando por linha do produto.
//
// Historico de alteracoes:
//
// 26/03/2014 - Catia  - incluido filtro de cliente
// 28/01/2015 - Catia  - estava zerando o DA1_ICMS quando rodava o recalculo.
// 29/01/2015 - Catia  - reestruturado o programa todo
// 19/07/2015 - Robert - Removidos tratamentos para diversos campos customizados que foram tirados de uso.
//                     - Incluido recalculo de ST.
// 02/12/2015 - Robert - Exigia % reajuste, mas pode haver casos de nao reajustar, executando apenas para recalculo de ST, opr exemplo.
// 11/01/2016 - Catia  - % a diminuir nao esta funcionando
// 08/12/2016 - Robert - Atualiza dados para Mercanet.
//

// --------------------------------------------------------------------------
User Function VA_ATPRC ()
	PRIVATE cPerg := "VA_ATPRC"
	private _sArqLog := U_NomeLog ()

	_ValidPerg()
	if ! Pergunte (cPerg, .T.)
		Return
	EndIf
	processa ({|| _AndaLogo ()})
return



// --------------------------------------------------------------------------
static function _AndaLogo ()
	local _nFator := 0

	if MV_PAR10 < 0 .or. MV_PAR11 < 0
		u_help ("Nenhum dos dos dois percentuais pode ser negativo.")
		Return
	endif
/*
	if MV_PAR10 == 0 .and. MV_PAR11 == 0
		u_help ("Um dos dois percentuais precisa ser maior do que zero.")
		Return
	endif
*/
	if MV_PAR10 > 0 .and. MV_PAR11 > 0
		u_help ("Apenas um dos dois percentuais pode ser maior do que zero.")
		Return
	endif

	procregua (da1 -> (reccount ()))
	
	sb1 -> (dbsetorder (1))
	da0 -> (dbsetorder (1))  // DA0_FILIAL+DA0_CODTAB
	da1 -> (dbsetorder (1))  // DA1_FILIAL+DA1_CODTAB+DA1_CODPRO+DA1_INDLOT+DA1_ITEM
	da1 -> (dbseek (xfilial ("DA1") + mv_par01, .T.))
	do while ! da1 -> (eof ()) .and. da1 -> da1_filial == xfilial ("DA1") .and. da1 -> da1_codtab <= mv_par02
		incproc ()
		if da1 -> da1_codpro < mv_par05 .or. da1 -> da1_codpro > mv_par06
			da1 -> (dbskip ())
			loop
		endif

		if da1 -> da1_client < mv_par12 .or. da1 -> da1_client > mv_par13
			da1 -> (dbskip ())
			loop
		endif

		if ! da0 -> (dbseek (xfilial ("DA0") + da1 -> da1_codtab, .F.))
			u_help ("Tabela de precos '" + da1 -> da1_codtab + "' nao cadastrada! Nao deveria existir registro no arquivo DA1.")
			da1 -> (dbskip ())
			loop
		endif
		
		if (mv_par07 == 1 .and. da0 -> da0_ativo != '1') .or. (mv_par07 == 2 .and. da0 -> da0_ativo != '2')
			da1 -> (dbskip ())
			loop
		endif

		if ! empty (da1 -> da1_estado)
			if da1 -> da1_estado < mv_par08 .or. da1 -> da1_estado > mv_par09
				da1 -> (dbskip ())
				loop
			endif
		else
			if da0 -> da0_vauf < mv_par08 .or. da0 -> da0_vauf > mv_par09
				da1 -> (dbskip ())
				loop
			endif
		endif

		if ! sb1 -> (dbseek (xfilial ("SB1") + da1 -> da1_codpro, .F.))
			u_help ("Produto '" + da1 -> da1_codpro + "' nao cadastrado!")
			da1 -> (dbskip ())
			loop
		endif

		if sb1 -> b1_codlin < mv_par03 .or. sb1 -> b1_codlin > mv_par04
			da1 -> (dbskip ())
			loop
		endif

		reclock ("DA1", .F.)
		if mv_par10 > 0
			_nFator = (100 - mv_par10) / 100
		else
			_nFator = (100 - mv_par11) / 100						
		endif
		_nPrcAnt = da1 -> da1_prcven
		_nSTAnt = da1 -> da1_vast
		
		if mv_par10 > 0
			da1 -> da1_prcven /= _nFator
		elseif mv_par11 > 0		
			da1 -> da1_prcven *= _nFator
		endif

		// Atualiza o valor da ST.
		da1 -> da1_vast = U_CalcST4 (iif (empty (da1 -> da1_estado), da0 -> da0_vauf, da1 -> da1_estado), da1 -> da1_codpro, da1 -> da1_prcven, da1 -> da1_client, da1 -> da1_loja, 1, '801')

		MsUnlock()
		
		U_AtuMerc ("DA0", da0 -> (recno ()))
		
		u_log (da1 -> da1_codtab, da1 -> da1_codpro, 'preco de', _nPrcAnt, 'para', da1 -> da1_prcven, '   ST de', _nSTAnt, 'para', da1->da1_vast)
		da1 -> (dbskip ())
	enddo
Return


// --------------------------------------------------------------------------
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                  TIPO TAM DEC VALID F3     Opcoes                        Help   
	aadd (_aRegsPerg, {01, "Tabela de preço de   ?","C", 03, 0,  "",   "DA0", {},                              ""})
	aadd (_aRegsPerg, {02, "Tabela de preço até  ?","C", 03, 0,  "",   "DA0", {},                          	   ""})
	aadd (_aRegsPerg, {03, "Linha de produto de  ?","C", 02, 0,  "",   "88 ", {},                     		   ""})
	aadd (_aRegsPerg, {04, "Linha de produto até ?","C", 02, 0,  "",   "88 ", {},              			       ""})
	aadd (_aRegsPerg, {05, "Produto de           ?","C", 04, 0,  "",   "SB1", {},                              ""})
	aadd (_aRegsPerg, {06, "Produto até          ?","C", 04, 0,  "",   "SB1", {},                              ""})
	aadd (_aRegsPerg, {07, "Tabelas              ?","N", 01, 0,  "",   "   ", {"Ativas","Inativas","Ambas"},   ""})
	aadd (_aRegsPerg, {08, "UF de                ?","C", 02, 0,  "",   "   ", {},                         	   ""})
	aadd (_aRegsPerg, {09, "UF até               ?","C", 02, 0,  "",   "   ", {},                         	   ""})
	aadd (_aRegsPerg, {10, "Percentual +         ?","N", 05,02,  "",   "   ", {},                        	   ""})
	aadd (_aRegsPerg, {11, "Percentual -         ?","N", 05,02,  "",   "   ", {},                        	   ""})
	aadd (_aRegsPerg, {12, "Cliente de           ?","C", 06, 0,  "",   "SA1", {},                        	   ""})
	aadd (_aRegsPerg, {13, "Cliente Ate          ?","C", 06, 0,  "",   "SA1", {},                        	   ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return