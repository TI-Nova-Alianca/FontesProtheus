// Programa:  M460Qry
// Autor:     Robert Koch
// Data:      09/11/2010
// Descricao: PE para filtro dos pedidos liberados a faturar - versao SQL
//
//            Obs.: este P.E. deve obrigatoriamente manter a consistencia de retorno com o M460FIL
//
// Historico de alteracoes:
// 05/11/2010 - Robert - Criado campo C9_VABLOQ.
// 29/04/2015 - Robert - Passa a concatenar a expressao de filtro com o conteudo de PARAMIXB [1]
//

// --------------------------------------------------------------------------
User Function M460QRY ()
	local _sRet := alltrim (paramixb [1]) //""
	if IsInCallStack ("MATA460A")  // Faturamento padrao (nao via carga)
		_sRet += " AND C9_VABLOQ = 'N' AND C9_CARGA = ''"
	else  // Faturamento via carga
		_sRet += " AND C9_VABLOQ = 'N' AND C9_CARGA != ''"
	endif
return _sRet
