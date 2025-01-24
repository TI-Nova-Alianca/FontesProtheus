// Programa...: ZX5_TELAGEN
// Autor......: Cláudia Lionço
// Data.......: 24/01/2025
// Descricao..: Edicao de registros do ZX5 com chave especifica 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #tela
// #Descricao         #Edicao de registros do ZX5 com chave especifica
// #PalavasChave      #ZX5 #tela
// #TabelasPrincipais 
// #Modulos            
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------------
User Function ZX5_TELAGEN(_sTabela, _aCampos,_sLinOk)
	local _aOrd   := _aCampos 

    if empty(_sLinOk)
        _sLinOk := 'U_ZX5_LINOK()'
    EndIf

	U_ZX5A(4, _sTabela, _sLinOk, "allwaystrue ()", .F.,NIL, _aOrd)

return
//
// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_LINOK ()
	local _lRet := .T.
return _lRet
