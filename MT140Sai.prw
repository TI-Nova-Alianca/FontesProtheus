// Programa: MT140Sai
// Data:     21/10/2015
// Autor:    Robert Koch
// Funcao:   PE na saida da rotina de atualizacao da pre-nota de entrada.
//
// Historico de alteracoes:
// 17/12/2018  - Andre - Alterada Query para considerar fornecedor, loja, nota, serie e não mais apenas a chave. Pois nem toda PRE NOTA tem chave. 

// --------------------------------------------------------------------------
user function MT140Sai ()
//	private _sArqLog := U_NomeLog ()
//	u_logID ()
		
	if paramixb [1] == 5  // Exclusao
		_AtuZZX (paramixb [1])
	endif
return

// --------------------------------------------------------------------------
// Atualiza status na tabela ZZX.
static function _AtuZZX (_nOpc)
	local _oSQL      := NIL

//	u_logIni ()
	
	if _nOpc == 5
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZZX")
		_oSQL:_sQuery +=    " SET ZZX_STATUS = '3'"  // 1=NF gerada no SF1;2=Pre-NF gerada no SF1;3=NF excluida no SF1
		_oSQL:_sQuery +=  " WHERE ZZX_CLIFOR = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=  " AND ZZX_LOJA  = '" + sf1 -> f1_loja + "'"
		_oSQL:_sQuery +=  " AND ZZX_DOC   = '" + sf1 -> f1_doc + "'"
		_oSQL:_sQuery +=  " AND ZZX_SERIE = '" + sf1 -> f1_serie + "'"
		_oSQL:_sQuery +=  " AND D_E_L_E_T_ = ''"
//		_oSQL:Log ()
		_oSQL:Exec ()
	
	endif 

//	u_logFim ()
return
