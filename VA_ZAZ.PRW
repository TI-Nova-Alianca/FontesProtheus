// Programa...: VA_ZAZ
// Autor......: Catia Cardoso
// Data.......: 06/10/2016
// Descricao..: Linhas de Produtos por Embalagem para Forma��o de Pre�o
//
// --------------------------------------------------------------------
//
// Historico de alteracoes:
//
#include "rwmake.ch"
User Function VA_ZAZ()
	AxCadastro("ZAZ","Linha Produto p/Embalagem para Forma��o Pre�o",".T.","U_ZAZVAL()")
Return

// --------------------------------------------------------------------------
// Valida 'Tudo OK'
user function ZAZVAL()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()

	if inclui
		ZAZ -> (dbsetorder (1))
		if ZAZ -> (dbseek (xfilial ("ZAZ") + m->ZAZ_CLINF, .F.))
			u_help ("C�digo j� cadastrado! ")
			_lRet = .F.
		endif
	endif
		
	U_ML_SRArea (_aAreaAnt)
return _lRet
