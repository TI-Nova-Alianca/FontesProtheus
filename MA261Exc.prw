// Programa...: MT261Exc
// Autor......: Robert Koch
// Data.......: 04/03/2017
// Descricao..: P.E. apos estorno transf. internas mod. II
//              Criado inicialmente para atualizar tabela ZAG.
//
// Historico de alteracoes:
// 17/08/2018 - Robert - Grava evento de estorno.
// 30/05/2019 - Andre  - Atualiza STATUS_PROTHEUS para 5 quando feito estorno.
//

// ----------------------------------------------------------------
user function MA261Exc ()
	local _aAreaAnt := U_ML_SRArea ()

	// Verifica se deve gravar evento gerado em P.E. anterior.
	if type ('_oEvtEstF') == 'O'
		if left (sd3 -> d3_cf, 2) == 'RE'  // Este P.E. parece ser chamado uma vez para cada registro RE/DE do SD3
			_oEvtEstF:Grava ()
		endif
	endif

	// Este P.E. parece ser chamado uma vez para cada registro RE/DE do SD3, mas, para atualizar o ZAG, soh preciso de um deles.
	if left (sd3 -> d3_vaChvEx, 3) == 'ZAG' .and. left (sd3 -> d3_cf, 2) == 'RE'
		//U_SendMail ("robert.koch@novaalianca.coop.br", "falta estornar ClsTrEstq no " + procname (), "vai corrigir isso, tche!", {})
		zag -> (dbsetorder (1))
		if zag -> (dbseek (xfilial ("ZAG") + substr (sd3 -> d3_vaChvEx, 4, 10), .F.))
			_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
			if valtype (_oTrEstq) == 'O'
				_oTrEstq:Estorna ()
			endif
		endif
	endif
	_AtuEstor ()  // Atualiza a tabela do Fullsoft como 'Estornado'
	U_ML_SRArea (_aAreaAnt)
return



// --------------------------------------------------------------------------------------------
// Atualiza status no FullWMS.
static function _AtuEstor ()
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " update tb_wms_entrada"
	_oSQL:_sQuery +=    " set status_protheus = '5'"
	_oSQL:_sQuery +=  " where entrada_id = 'ZA1" + sd3->d3_filial + sd3->d3_vaetiq + "'"
	_oSQL:Log()
	_oSQL:Exec ()
	
return
