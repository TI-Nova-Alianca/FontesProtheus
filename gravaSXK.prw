// Programa...: GravaSXK
// Autor......: Cláudia Lionço
// Data.......: 04/11/2020
// Descricao..: Grava parametros na tabela SXK
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Grava parametros na tabela SXK
// #PalavasChave      #parametros #perguntas #automacao #auxiliar #uso_generico
// #TabelasPrincipais #SXK 
// #Modulos           #todos_modulos
//
// Parametros:
// 1 - Grupo de perguntas a atualizar
// 2 - Codigo (ordem) da pergunta
// 3 - Dado a ser gravado
// 4 - Grava ou deleta o registro da SXK - G - Gravar D - Deletar
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------
User Function GravaSXK (_sGrupo, _sPerg, _xValor, _sAcao )
    local _sUserName := ""

    if type ("__cUserId") == "C" .and. ! empty (__cUserId)
			psworder (1)        // Ordena arquivo de senhas por ID do usuario
			PswSeek(__cUserID)  // Pesquisa usuario corrente
			_sUserName := PswRet(1) [1, 1]

            If _sAcao == 'D'
                _DelSXK (_sGrupo, _sPerg, _sUserName, _xValor)
            Else
			    _GrvSXK (_sGrupo, _sPerg, _sUserName, _xValor)
            EndIf
		endif
Return
//
// -------------------------------------------------------------------------------
// Deleta registro SXK
Static Function  _DelSXK (_sGrupo, _sPerg, _sUserName, _xValor)

    _usu := "U"+ ALLTRIM(_sUserName)
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " DELETE FROM SXK010
    _oSQL:_sQuery += " WHERE XK_GRUPO = '"+ _sGrupo +"'"
    _oSQL:_sQuery += " AND XK_SEQ     = '"+ _sPerg  +"'"
    _oSQL:_sQuery += " AND XK_IDUSER  = '"+ _usu +"'"
    _oSQL:_sQuery += " AND XK_CONTEUD = '"+ _xValor +"'"
    _oSQL:Exec ()
Return
//
// -------------------------------------------------------------------------------
// Grava registro SXK
Static Function  _GrvSXK (_sGrupo, _sPerg, _sUserName, _xValor)

    dbSelectArea("SXK")
    dbSetOrder(1) 
    dbGoTop()
    If !dbSeek(_sGrupo + _sPerg + _sUserName)
		Reclock("SXK",.T.)
            SXK->XK_GRUPO   := _sGrupo
            SXK->XK_SEQ     := _sPerg
            SXK->XK_IDUSER  := "U"+ ALLTRIM(_sUserName)
            SXK->XK_CONTEUD := _xValor
        SXK->(MsUnlock())
    EndIf
Return
