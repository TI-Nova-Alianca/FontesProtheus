#INCLUDE "TOTVS.CH"
#INCLUDE "protheus.ch"

// Programa...: A260GRV
// Autor......: DWT
// Data.......: 29/11/2013
// Descricao..: Ponto de entrada após confirmada a transferencia (MATA260), antes de atualizar qualquer arquivo.
//
// Historico de alteracoes:
// 15/01/2015 - Robert - Passa a chamar a funcao U_PodeMov () para validar troca de produtos.
// 09/05/2018 - Robert - Ignora casos como mosto dessulfitado que volta para sulfitado.
// 14/05/2018 - Robert - Impede transferencia entre produtos diferentes (esta nao permite informar lote destino).
//

// --------------------------------------------------------------------------
User Function A260GRV()
	local _aAreaAnt := U_ML_SRArea ()
	Local _lRet     := .T.
	local _sMsg     := .T.
	if type ('cCodOrig') == 'C'
		if !empty(alltrim(cCodOrig)) .and. !empty(alltrim(cCodDest))

			// Nesta tela nao tem onde informar o lote destino, para o qual existe validacao no MATA261.
			if alltrim(cCodOrig) <> alltrim(cCodDest)
				u_help ("Para transferencia entre produtos diferentes use a tela de transferencias multiplas (mod.II)")
				_lRet = .F. 
			endif
		else
			_lRet := .F.
			u_help ("Um dos produtos está vazio. Favor preencher ambos.")	
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
Return _lRet
