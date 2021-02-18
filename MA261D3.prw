// Programa...: MA261D3
// Autor......: Bruno Silva (DWT)
// Data.......: 25/07/2014
// Descricao..: P.E. apos a gravacao da tranferencia (mod.II) de produtos.
//              Criado inicialmente para bloquear lote destino.
//              Deve ser usado em conjunto com os P.E. MA261Cpo e MA261IN.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos a gravacao da tranferencia (mod.II) de produtos
// #PalavasChave      #ponto_de_entrada #transferencias_de_produto
// #TabelasPrincipais #SD3 #SB8 #SE2
// #Modulos           #FIS #EST
//
// Historico de alteracoes:
// 22/08/2014 - Robert  - Passa a chamar funcao U_BlqLot para compatibilizar com MA260D3
// 05/02/2015 - Robert  - Nao chama mais funcao de bloqueio de lotes.
//                      - Gravacao do campo D3_VAMOTIV.
// 08/05/2015 - Robert  - Gravacao dos campos D3_VADTINC e D3_VAHRINC.
// 29/09/2015 - Robert  - Tratamento para remover aspas simples da string com o motivo, para evitar erro no SQL.
// 20/10/2016 - Robert  - Tratamento para gravar campo D3_VALAUDO.
// 11/04/2017 - Robert  - Campos D3_VADTINC e D3_VAHRINC passam a ser alimentados via default do SQL.
// 18/05/2016 - Robert  - Novos parametros funcao LaudoEm().
// 15/10/2018 - Robert  - Gravacao do campo D3_VACHVEX.
// 26/10/2018 - Robert  - Gravacao do campo D3_VAETIQ.
// 04/11/2018 - Robert  - Tratamento para criar laudo de corte via 'merge' quando transf. para lote ja existente.
// 13/11/2019 - Robert  - Nao chamava merge de laudos quando transferencia de um produto para outro.
// 17/02/2021 - Claudia - Incluido parametro filial da chamada do CpLaudo. GLPI:5592
//
// ------------------------------------------------------------------------------------------------------------------
User Function MA261D3 ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _nLinha    := ParamIXB
	local _nPosMotiv := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VAMOTIV'})
	local _nPosChvEx := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VACHVEX'})
	local _nPosEtiq  := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VAETIQ'})
	local _oSQL      := NIL

	if _nPosMotiv > 0 .and. _nPosEtiq > 0 .and. _nPosChvEx > 0
		
		// Como a transferencia gera dois registros no SD3 e o arquivo encontra-se posicionado
		// apenas no registro com movimento DE4, fiz a atualizacao via SQL para pegar os dois registros.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE " + RetSQLName ("SD3")
		_oSQL:_sQuery +=    " SET D3_VAMOTIV = '" + strtran (alltrim (aCols [_nLinha, _nPosMotiv]), "'", "") + "'"
		_oSQL:_sQuery +=       ", D3_VACHVEX = '" + alltrim (aCols [_nLinha, _nPosChvEx]) + "'"
		_oSQL:_sQuery +=       ", D3_VAETIQ  = '" + alltrim (aCols [_nLinha, _nPosEtiq]) + "'"
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND D3_FILIAL  = '" + sd3 -> d3_filial + "'"
		_oSQL:_sQuery +=    " AND D3_EMISSAO = '" + dtos (sd3 -> d3_emissao) + "'"
		_oSQL:_sQuery +=    " AND D3_DOC     = '" + sd3 -> d3_doc    + "'"
		_oSQL:_sQuery +=    " AND D3_NUMSEQ  = '" + sd3 -> d3_numseq + "'"
		_oSQL:Exec ()
	else
		U_AvisaTI ("Os campos esperados nao estao todos disponiveis no aCols. Update do SD3 nao pode ser feito. D3_NUMSEQ = " + sd3 -> d3_numseq) 
	endif

	// Atualiza laudos laboratoriais, caso necessario.
	_AtuLaudo ()

	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
return
//
// --------------------------------------------------------------------------
// Atualiza laudos laboratoriais, caso necessario.
static function _AtuLaudo ()
	local _sLaudoOri := ""
	local _sLaudoDes := ""
	local _sLoteOri  := ""
	local _sLoteDes  := ""
	local _nSaldoOri := 0
	local _nSaldoDes := 0
	local _aLaudos   := {}
	local _nLinha    := ParamIXB
	local _nPosProOr := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_COD'})
	local _nPosProDs := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_COD'}, _nPosProOr + 1)  // Campo 'destino' encontra-se 'mais adiante' do de origem.
	local _nPosLotOr := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_LOTECTL'})
	local _nPosLotDs := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_LOTECTL'}, _nPosLotOr + 1)  // Campo 'destino' encontra-se 'mais adiante' do de origem.
	local _nPosLocOr := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_LOCAL'})
	local _nPosLocDs := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_LOCAL'}, _nPosLocOr + 1)  // Campo 'destino' encontra-se 'mais adiante' do de origem.
	local _nPosEndOr := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_LOCALIZ'})
	local _nPosEndDs := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_LOCALIZ'}, _nPosEndOr + 1)  // Campo 'destino' encontra-se 'mais adiante' do de origem.
	local _nPosQuant := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_QUANT'})
	local _lContinua := .T.

	// Lote destino, se nao informado, assume o mesmo do lote origem.
	_sLoteOri = aCols [_nLinha, _nPosLotOr]
	_sLoteDes = iif (empty (aCols [_nLinha, _nPosLotDs]), _sLoteOri, aCols [_nLinha, _nPosLotDs])

	// Se o produto nao controla lotes, nao vai ter laudo envolvido.
	if _lContinua .and. (empty (_sLoteOri) .or. empty (_sLoteDes))
	//	u_log2 ('debug', '[' + procname () + '] Lote origem ou destino vazios. Nao vou continuar a geracao de novo laudo.')
		_lContinua = .F.
	endif
		
	// Se estah transferindo o mesmo lote (para outro endereco, por exemplo), nao
	// ha necesidade de envolver laudos.
	if _lContinua .and. _sLoteOri == _sLoteDes
		_lContinua = .F.
	endif

	// Busca o laudo (se houver) do lote de origem.
	if _lContinua
		_sLaudoOri = U_LaudoEm (aCols [_nLinha, _nPosProOr], _sLoteOri, sd3 -> d3_emissao)
		u_log ('Laudo origem:', _sLaudoOri)
		if empty (_sLaudoOri)
			u_log ('Laudo do lote origem nao encontrado.')
			_lContinua = .F.
		endif
	endif

	// Se o lote destino jah tem laudo (estah recebendo saldo de outro lote),
	// faz um merge de ambos. Senao, cria laudo para o lote destino.
	if _lContinua
		_sLaudoDes = U_LaudoEm (aCols [_nLinha, _nPosProDs], _sLoteDes, sd3 -> d3_emissao)
		u_log ("Lote destino jah tem laudo:" + _sLaudoDes)
		if ! empty (_sLaudoDes)
			
			// Verifica o saldo do lotes antes da transferencia, para poder proporcionalizar no merge de laudos.
			sb8 -> (dbsetorder (5))  // B8_FILIAL+B8_PRODUTO+B8_LOTECTL+B8_NUMLOTE+DTOS(B8_DTVALID)
			if sb8 -> (dbseek (xfilial ("SB8") + aCols [_nLinha, _nPosProOr] + _sLoteOri, .F.))
				_nSaldoOri = sb8 -> b8_saldo + aCols [_nLinha, _nPosQuant]
			else
				u_log ('Nao foi possivel determinar o saldo do lote origem.')
				_nSaldoOri = 0
			endif
			if sb8 -> (dbseek (xfilial ("SB8") + aCols [_nLinha, _nPosProDs] + _sLoteDes, .F.))
				_nSaldoDes = sb8 -> b8_saldo - aCols [_nLinha, _nPosQuant]
			else
				u_log ('Nao foi possivel determinar o saldo do lote origem.')
				_nSaldoDes = 0
			endif
			if _nSaldoOri <= 0 .or. _nSaldoDes <= 0
				u_log ('Problema para determinar o saldo dos lotes. Merge de laudos nao pode ser feito.')
				u_log ('Lote origem :', _sLoteOri, 'saldo:', _nSaldoOri)
				u_log ('Lote destino:', _sLoteDes, 'saldo:', _nSaldoDes)
			else
				_aLaudos = {}
				aadd (_aLaudos, {_sLaudoOri, _nSaldoOri})
				aadd (_aLaudos, {_sLaudoDes, _nSaldoDes})
				U_ZAFM (_aLaudos, aCols [_nLinha, _nPosProDs], '', _sLoteDes, aCols [_nLinha, _nPosLocDs], 'Corte gerado pelo doc. ' + sd3 -> d3_doc)
			endif
		else
			u_log ('vou copiar o laudo ', _sLaudoOri)
			U_CpLaudo (cFilAnt, _sLaudoOri, aCols [_nLinha, _nPosProDs], aCols [_nLinha, _nPosLocDs], aCols [_nLinha, _nPosEndDs], _sLoteDes, sd3 -> d3_quant, .T.)
		endif
	endif

return
