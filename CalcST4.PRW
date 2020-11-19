// Programa:   CalcST4
// Autor:      Robert Koch
// Data:       12/09/2015
// Descricao:  Calculo de ST (Substituicao Tributaria) usando metodo padrao do sistema.
// 
// Historico de alteracoes:
// 19/09/2015 - Robert - Passa a aceitar cliente/loja como parametros.
// 23/10/2015 - Robert - Parametros novos (quantidade e TES).
// 05/01/2016 - Catia  - desabilitadas as mensagens de não encontrar p 

// --------------------------------------------------------------------------
user function CalcST4 (_sUF, _sProduto, _nPreco, _sCliente, _sLoja, _nQuant, _sTES)
	local _aAreaAnt  := U_ML_SRArea ()
	//local _sTES      := ""
	local _nRet      := 0
	local _oSQL      := NIL
	local _lContinua := .T.

	//u_logIni ()
	//u_log (_sUF, _sProduto, _nPreco, _sCliente, _sLoja, _nQuant, _sTES)
	
		// Busca um cliente 'normal' para simular um pedido de venda.
	if _lContinua .and. (_sCliente == NIL .or. _sLoja == NIL .or. empty (_sCliente) .or. empty (_sLoja))
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT TOP 1 A1_COD, A1_LOJA, A1_TIPO"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery +=  " WHERE SA1.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=    " AND SA1.A1_FILIAL   = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery +=    " AND SA1.A1_EST      = '" + _sUF + "'"
		_oSQL:_sQuery +=    " AND SA1.A1_MSBLQL   = '2'"
		_oSQL:_sQuery +=    " AND SA1.A1_PESSOA   = 'J'"
		_oSQL:_sQuery +=    " AND SA1.A1_TIPO     = 'S'"
		_oSQL:_sQuery +=    " AND SA1.A1_CONTRIB != '2'"
		_oSQL:_sQuery +=    " AND SA1.A1_SIMPLES != '1'"
		_oSQL:_sQuery +=    " AND SA1.A1_SIMPNAC != '1'"
		_oSQL:_sQuery +=    " AND SA1.A1_VASTATC != 'I'"
		_oSQL:_sQuery +=  " ORDER BY A1_ULTCOM DESC, A1_COD, A1_LOJA"
		//_oSQL:Log ()
		_aCliente = _oSQL:Qry2Array (.F., .F.)
		if len (_aCliente) == 0
			//u_help ("Nao foi possivel encontrar um cliente do estado '" + _sUF + "' para o calculo de ST: " + _oSQL:_sQuery)
			_nRet = 0
			_lContinua = .F.
		else
			_sCliente = _aCliente [1, 1]
			_sLoja    = _aCliente [1, 2]
			_sTipoCli = _aCliente [1, 3]
		endif
	else
		if ! sa1 -> (dbseek (xfilial ("SA1") + _sCliente + _sLoja, .F.))
			//u_help ("Cliente/loja '" + _sCliente + "/" + _sLoja + "' (que seria usado para calculo de ST) nao foi encontrado no cadastro.")
			_nRet = 0
			_lContinua = .F.
		else
			_sTipoCli = sa1 -> a1_tipo
		endif
	endif

	if _lContinua
		_sTES = iif (_sTES == NIL .or. empty (_sTES), '801', _sTES)
		//u_log ('Simulando pedido de venda para o cliente ', _sCliente, '/', _sLoja, 'para calculo de ST do produto', _sProduto, 'com TES =', _sTES, 'quant =', _nQuant, 'preco =', _nPreco)

		// Inicializa MAFISINI para poder bucar o valor da ST
		MaFisIni (_sCliente, _sLoja, 'C', ;  // C=Cliente, F=Fornecedor
			'N', ;  // Tipo de nota
			_sTipoCli, ;
			MaFisRelImp("MTR700",{"SC5","SC6"}),;	// 6-Relacao de Impostos que suportados no arquivo
			,;						   				// 7-Tipo de complemento
			,;										// 8-Permite Incluir Impostos no Rodape .T./.F.
			"SB1",;									// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
			"MTR700")								// 10-Nome da rotina que esta utilizando a funcao
	
		MaFisAdd (_sProduto, _sTES, _nQuant, _nPreco,;
			0,;
			"",;
			"",;
			"",;
			0,;
			0,;
			0,;
			0,;
			_nPreco,;
			0,;
			0,;
			0)
		_nRet := MaFisRet (1,"IT_VALSOL")
		MaFisEnd ()
	endif
	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
Return _nRet
