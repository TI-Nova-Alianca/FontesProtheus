// Programa...: LJ010Fil
// Autor......: Robert Koch
// Data.......: 12/06/2008
// Descricao..: P.E. para filtrar as series de notas que o usuario poderah selecionar
//              na geracao de NF no SigaLoja. Executado antes de abrir a tela de
//              selecao para o usuario.
//
// Historico de alteracoes:
// 01/08/2008 - Robert - Passa a gravar evento em vez de enviar e-mail quando altera SX5.
//

// --------------------------------------------------------------------------
user function LJ010Fil ()
	local _sRet     := ""
	local _sSerieLj := "   "
	local _sQuery   := ""
	local _sProxima := ""
	local _oEvento  := NIL

	// Como tivemos alguns casos do sistema puxar numeracao de notas jah existentes,
	// montei este pequeno ajuste no SX5. Provavelmente, nas proximas builds este
	// ajuste poderah ser removido. Robert, 12/06/08 (build 7.00.080703A)
	if sx5 -> (dbseek (xfilial ("SX5") + "01" + _sSerieLj, .F.))
		_sQuery := ""
		_sQuery += " Select max (F2_DOC)"
		_sQuery += "   from " + RetSQLName ("SF2") + " SF2 "
		_sQuery += "  where D_E_L_E_T_ = ''"
		_sQuery += "    and F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_sQuery += "    and F2_SERIE   = '" + _sSerieLj + "'"
		_sProxima = Soma1 (U_RetSQL (_sQuery))
		if alltrim (sx5 -> x5_descri) < _sProxima
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SX5001"
			_oEvento:Texto     = "Alterando numeracao de notas no SX5 de " + alltrim (sx5 -> x5_descri) + " para " + alltrim (_sProxima)
			_oEvento:Grava ()

			reclock ("SX5", .F.)
			sx5 -> x5_descri  = _sProxima
			sx5 -> x5_descspa = _sProxima
			sx5 -> x5_desceng = _sProxima
			msunlock ()
		endif
	endif

return _sRet
