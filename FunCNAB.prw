// Programa:  FunCNAB
// Autor:     Robert Koch
// Data:      05/06/2009
// Cliente:   Alianca
// Descricao: Funcoes auxiliares para geracao de arquivos de CNAB
//            Criado inicialmente para casos onde a formula nao cabe na linha do arquivo de config. do CNAB.
//
// Historico de alteracoes:
// 07/12/2010 - Robert - Considera os campos E1_ACRESC e E1_DECRESC independente do titulo ter baixa parcial.
// 29/06/2017 - Catia  - Teste para que se o E1_VAPJURO estiver zerado assuma o valor do parametro VA_PJURBOL
// 02/10/2017 - Catia  - funcao do calculo do desconto financeiro - deve assumir o valor ja calculado de rapel que vem do E1
// 20/12/2017 - Robert - So usa campos do endereco de cobranca se estiverem todos preenchidos.
//

// --------------------------------------------------------------------------
User Function FunCNAB (_sBanco, _sCampo)
	local _xRet      := NIL
	local _nVlrTit   := 0
	local _aAreaAnt  := U_ML_SRArea ()
	local _lEndCob   := .F.

	// Como o campo do saldo parece nao ser atualizado quando informa-se acrescimo ou decrescimo,
	// calculo a partir do valor original. Quando o titulo sofre alguma baixa parcial, o saldo
	// jah fica atualizado.
	_nVlrTit = round (se1 -> e1_saldo + se1 -> e1_acresc - se1 -> e1_decresc, 2)

	_lEndCob = ! empty (sa1->a1_bairroc) .and. ! empty (sa1->a1_cepc) .and. ! empty (sa1->a1_endcob) .and. ! empty (sa1->a1_estc) .and. ! empty (sa1->a1_munc)

	do case
		case upper (_sCampo) == "BAICOB"
			_xRet = iif (_lEndCob, sa1->a1_bairroc, sa1->a1_bairro)

		case upper (_sCampo) == "CEPCOB"
			_xRet = iif (_lEndCob, sa1->a1_cepc, sa1->a1_cep)

		case upper (_sCampo) == "ENDCOB"
			_xRet = iif (_lEndCob, sa1->a1_endcob, sa1->a1_end)

		case upper (_sCampo) == "ESTCOB"
			_xRet = iif (_lEndCob, sa1->a1_estc, sa1->a1_est)

		case upper (_sCampo) == "MUNCOB"
			_xRet = iif (_lEndCob, sa1->a1_munc, sa1->a1_mun)

		case upper (_sCampo) == "VLJURO"
			_wjuros = se1->e1_vaPJuro
			if _wjuros == 0 
	            // penso que deveria buscar SEMPRE dessa forma, mas como eh setado na emissao da nota o campo e1_vapjuro ele usa de la
	            // no caso das FAT que estamos começando a usar esse campo vem zero entao deve assumir do parametro		 
				_wjuros = GetMv ("VA_PJURBOL")
			endif		
			_xRet = Round( (_nVlrTit*_wjuros)/100/30 ,2)

		case upper (_sCampo) == "VLDESC"
			_xRet = 0
			if se1->e1_vaRapel > 0
				_xRet = se1->e1_vaRapel
			endif
			
		case upper (_sCampo) == "VLRTIT"
			_xRet = _nVlrTit


		otherwise
			final ("Rotina " + procname () + ": Retorno para Banco/campo " + _sBanco + "/" + _sCampo + " nao implementado.")
	endcase

	U_ML_SRArea (_aAreaAnt)
return _xRet
