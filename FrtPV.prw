// Programa...: FrtPV
// Autor......: Robert Koch
// Data.......: 28/05/2008
// Descricao..: Rotinas a serem executadas no pedido de venda para tratamento de fretes.
//
// Historico de alteracoes:
// 11/07/2008 - Robert  - Gravacao de novos campos no ZZ1
// 14/07/2008 - Robert  - Gravacao de novos campos no ZZ1
//                      - 'Limpa' objeto de fretes no final da rotina.
//                      - Habilitadas todas as validadacoes (antes estava em testes).
// 08/08/2008 - Robert  - Gravacao de novos campos no ZZ1 (menor preco, transp.menor preco e justificativa)
// 20/08/2008 - Robert  - Grava nome do usuario junto com a justificativa no ZZ1.
// 15/08/2011 - Robert  - Envia e-mail quando houver justificativa por usar o frete de menor valor.
// 06/06/2012 - Robert  - Melhorado e-mail de frete acima do menor valor.
// 12/04/2013 - Leandro - gravar ID do usuário no campo ZZ1_USER
// 21/07/2020 - Robert  - Desabilitado envio de aviso "frete com valor maior selecionado".
//                      - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Atualizacoes de dados de frete em pedidos de venda
// #PalavasChave      #frete #pedidos
// #TabelasPrincipais #ZZ1
// #Modulos           #FAT
//

// --------------------------------------------------------------------------
User Function FrtPV (_sQueFazer)
	local _lRet      := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _sFrete := "C"

//	u_logIni ()

	if _sQueFazer == "V"  // Verifica 'Tudo OK'
		if m->c5_tpfrete == "C"
			if type ("_oClsFrtPV") != "O"
				msgalert ("Nao foi feita a selecao de frete. Verifique!", "Funcao " + procname ())
				_lRet = .F.
			endif
			if _lRet
				// Verifica se o usuario alterou algo depois de informar o frete.
				if empty (_oClsFrtPV:_C5TRANSP) .or. empty (_oClsFrtPV:_ZZ1ORIGEM) .or. empty (_oClsFrtPV:_ZZ1DESTIN)
					msgalert ("Dados de frete incompletos, nao informados ou foi feita alguma alteracao no pedido. A selecao de frete deve ser refeita.")
					_lRet = .F.
				endif
			endif
			if _lRet
				// Verifica se o usuario alterou algo depois de informar o frete.
				if _oClsFrtPV:_C5CLIENTE != m->c5_cliente .or. ;
					 _oClsFrtPV:_C5LOJACLI != m->c5_lojacli .or. ;
					 _oClsFrtPV:_C5CLIENT  != m->c5_client  .or. ;
					 _oClsFrtPV:_C5LOJAENT != m->c5_lojaent .or. ;
					 _oClsFrtPV:_C5TRANSP  != m->c5_transp
					msgalert ("Houve alteracao nos campos de cliente / cliente de entrega / transportadora. A selecao de frete deve ser refeita.")
					_lRet = .F.
				endif
			endif
		endif

	elseif _sQueFazer == "I"  // Inclusao do pedido.
        
		if FunName()=='OMSA200'
			_sFrete := Posicione("SC5",1,xFilial("SC5") + DAI->DAI_PEDIDO,"C5_TPFRETE")
		else
			_sFrete := m->c5_tpfrete
		endif      
		
		// Se a variavel nao existe ou nao foi feita selecao de fretes, nada tenho a gravar.
		if _sFrete == "C" .and. type ("_oClsFrtPV") == "O"
			sa4 -> (dbsetorder (1))
			if sa4 -> (dbseek (xfilial ("SA4") + _oClsFrtPV:_C5TRANSP, .F.))
	
				// Caso encontre registro anterior no ZZ1, eh por que o usuario estah alterando o pedido.
				zz1 -> (dbsetorder (1))  // ZZ1_FILIAL + ZZ1_PVENDA
				if zz1 -> (dbseek (xfilial ("ZZ1") + _oClsFrtPV:_C5NUM, .F.))
					reclock ("ZZ1", .F.)
				else
					reclock ("ZZ1", .T.)
				endif
				zz1 -> zz1_filial  = xfilial ("ZZ1")
				zz1 -> zz1_PVenda  = _oClsFrtPV:_C5NUM
				zz1 -> zz1_origem  = _oClsFrtPV:_ZZ1ORIGEM
				zz1 -> zz1_destin  = _oClsFrtPV:_ZZ1DESTIN
				zz1 -> zz1_transp  = _oClsFrtPV:_C5TRANSP
				zz1 -> zz1_fornec  = sa4 -> a4_vaForn
				zz1 -> zz1_lojafo  = sa4 -> a4_vaLoja
				zz1 -> zz1_peso    = _oClsFrtPV:_ZZ1PESO
				zz1 -> zz1_FrtMin  = _oClsFrtPV:_ZZ1FRTMIN
				zz1 -> zz1_PesMin  = _oClsFrtPV:_ZZ1PESMIN
				zz1 -> zz1_UMPeso  = _oClsFrtPV:_ZZ1UMPESO
				zz1 -> zz1_pedag   = _oClsFrtPV:_ZZ1PEDAG
				zz1 -> zz1_QtPedg  = _oClsFrtPV:_ZZ1QTPEDG
				zz1 -> zz1_advalo  = _oClsFrtPV:_ZZ1ADVALO
				zz1 -> zz1_palet   = _oClsFrtPV:_ZZ1PALET
				zz1 -> zz1_cat     = _oClsFrtPV:_ZZ1CAT
				zz1 -> zz1_despac  = _oClsFrtPV:_ZZ1DESPAC
				zz1 -> zz1_gris    = _oClsFrtPV:_ZZ1GRIS
				zz1 -> zz1_VlNego  = _oClsFrtPV:_ZZ1VLNEGO
				zz1 -> zz1_VlCalc  = _oClsFrtPV:_ZZ1VLCALC
				zz1 -> zz1_PFixo1  = _oClsFrtPV:_ZZ1PFixo1
				zz1 -> zz1_PFixo2  = _oClsFrtPV:_ZZ1PFixo2
				zz1 -> zz1_PFixo3  = _oClsFrtPV:_ZZ1PFixo3
				zz1 -> zz1_PFixo4  = _oClsFrtPV:_ZZ1PFixo4
				zz1 -> zz1_PFixo5  = _oClsFrtPV:_ZZ1PFixo5
				zz1 -> zz1_PFixo6  = _oClsFrtPV:_ZZ1PFixo6
				zz1 -> zz1_PFixo7  = _oClsFrtPV:_ZZ1PFixo7
				zz1 -> zz1_PFixo8  = _oClsFrtPV:_ZZ1PFixo8
				zz1 -> zz1_PFixo9  = _oClsFrtPV:_ZZ1PFixo9
				zz1 -> zz1_PFixo10 = _oClsFrtPV:_ZZ1PFixo10
				zz1 -> zz1_VFixo1  = _oClsFrtPV:_ZZ1VFixo1
				zz1 -> zz1_VFixo2  = _oClsFrtPV:_ZZ1VFixo2
				zz1 -> zz1_VFixo3  = _oClsFrtPV:_ZZ1VFixo3
				zz1 -> zz1_VFixo4  = _oClsFrtPV:_ZZ1VFixo4
				zz1 -> zz1_VFixo5  = _oClsFrtPV:_ZZ1VFixo5
				zz1 -> zz1_VFixo6  = _oClsFrtPV:_ZZ1VFixo6
				zz1 -> zz1_VFixo7  = _oClsFrtPV:_ZZ1VFixo7
				zz1 -> zz1_VFixo8  = _oClsFrtPV:_ZZ1VFixo8
				zz1 -> zz1_VFixo9  = _oClsFrtPV:_ZZ1VFixo9
				zz1 -> zz1_VFixo10 = _oClsFrtPV:_ZZ1VFixo10
				zz1 -> zz1_PrcMin  = _oClsFrtPV:_ZZ1PrcMin
				zz1 -> zz1_TrPMin  = _oClsFrtPV:_ZZ1TrPMin
				zz1 -> zz1_Justif  = alltrim (cUserName) + ": " + _oClsFrtPV:_ZZ1Justif
				
				zz1 -> zz1_user := alltrim(__CUSERID)
				msunlock ()
				
//				if ! empty (_oClsFrtPV:_ZZ1Justif)
					// Manda e-mail de aviso para responsavel.
//					_AvisaVl (_oClsFrtPV)
//				endif
			endif

			// 'Limpa' o objeto para evitar que o novo pedido use estes valores.
			if FunName() <> 'OMSA200'
				_oClsFrtPV := ClsFrtPV():New ()
			endif

		endif

	elseif _sQueFazer == "E"  // Exclusao do pedido.
		zz1 -> (dbsetorder (1))  // ZZ1_FILIAL + ZZ1_PVENDA
		if zz1 -> (dbseek (xfilial ("ZZ1") + sc5 -> c5_num, .F.))
			reclock ("ZZ1", .F.)
			zz1 -> (dbdelete ())
			msunlock ()
		endif

		// 'Limpa' o objeto para evitar que o novo pedido use estes valores.
		_oClsFrtPV := ClsFrtPV():New ()
	endif

	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return _lRet


/*
// --------------------------------------------------------------------------
// Manda e-mail de aviso para responsavel.
static function _AvisaVl (_oFrete)
	local _sMsg  := ""
	local _n     := N
	local _sCRLF := chr (13) + chr (10)
    
	if FunName() <> 'OMSA200'
		_sMsg += "Pedido de venda: " + _oFrete:_C5NUM + _sCRLF
		_sMsg += " Cliente: " + m->c5_cliente + '/' + m->c5_lojacli + ' - ' + m->c5_nomecli + _sCRLF + _sCRLF
		_sMsg += "Produto(s):" + _sCRLF
		for N = 1 to len (aCols)
			if ! GDDeleted ()
				_sMsg += alltrim (GDFieldGet ("C6_PRODUTO"))
				_sMsg += ' - ' + alltrim (GDFieldGet ("C6_DESCRI"))
				_sMsg += '  (' + cvaltochar (GDFieldGet ("C6_QTDVEN"))
				_sMsg += GDFieldGet ("C6_UM") + ")" + _sCRLF
			endif
		next
		_sMsg += _sCRLF
		_sMsg += "Justificativa: " + alltrim (_oClsFrtPV:_ZZ1Justif)
	
		U_ZZUNU ("007", "Pedido '" + _oFrete:_C5NUM + "' frete com valor maior selecionado.", _sMsg, .F., cEmpAnt, cFilAnt)
	endif
	N := _n
return
*/
