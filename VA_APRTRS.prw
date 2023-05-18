// Programa...: VA_APRTRS
// Autor......: Claudia Lionço
// Data.......: 16/05/2023
// Descricao..: Aprovação de transferencia em lote
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Aprovação de transferencia em lote
// #PalavasChave      #aprovação_de_transferencia #TRS
// #TabelasPrincipais #SE6
// #Modulos           #FIN
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------
#XTranslate .OK        => 1
#XTranslate .FilOrig   => 2
#XTranslate .FilDest   => 3
#XTranslate .Solicit   => 4
#XTranslate .Dt        => 5
#XTranslate .Titulo    => 6
#XTranslate .Tipo      => 7
#XTranslate .Cliente   => 8
#XTranslate .Valor     => 9

#include "rwmake.ch"
#Include "protheus.ch"   
#include "tbiconn.ch"

User Function VA_APRTRS()

    processa ({|| _Seleciona()})

Return
//
// --------------------------------------------------------------------------------
// Seleciona solicitações para aprovar
Static Function _Seleciona()
	Local _oSQL   := ClsSQL ():New ()
	Local _aDados := {}
	Local _x      := 0

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     ' ' AS OK "
    _oSQL:_sQuery += "    ,E6_FILORIG AS FILIAL_ORIGEM "
    _oSQL:_sQuery += "    ,E6_FILDEB AS FILIAL_DESTINO "
    _oSQL:_sQuery += "    ,E6_NUMSOL AS NUMERO_SOLICITACAO "
    _oSQL:_sQuery += "    ,E6_DATSOL AS DT_SOLICITACAO "
    _oSQL:_sQuery += "    ,E6_NUM + ' ' + E6_PREFIXO + ' ' + E6_PARCELA AS TITULO "
    _oSQL:_sQuery += "    ,E6_TIPO AS TIPO "
    _oSQL:_sQuery += "    ,E6_CLIENTE + ' ' + E6_LOJA + ' - ' + A1_NOME AS CLIENTE "
    _oSQL:_sQuery += "    ,E6_VALOR AS VALOR "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SE6") + " SE6 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND A1_COD = E6_CLIENTE "
    _oSQL:_sQuery += " 		AND A1_LOJA = E6_LOJA "
    _oSQL:_sQuery += " WHERE SE6.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND E6_SITSOL = '1' "
    _oSQL:_sQuery += " ORDER BY  E6_NUMSOL, E6_CLIENTE "
	_aDados := aclone(_oSQL:Qry2Array())

	If Len(_aDados) > 0
		
		// Inicializa coluna de selecao com .F. ('nao selecionada').
		for _x := 1 to len(_aDados)
			_aDados [_x, .Ok] = .F.
		next

		_aCols = {}
		aadd (_aCols, {.FilOrig , 'Filial Origem'   , 20, '@!'				 })
		aadd (_aCols, {.FilDest , 'FIlial Destino'  , 20, '@!'				 })
		aadd (_aCols, {.Solicit , 'Solicitação'     , 20, '@!'				 })
		aadd (_aCols, {.Dt      , 'Data Solicit.'   , 20, '@!'				 })
		aadd (_aCols, {.Titulo  , 'Título'          , 30, '@!'				 })
		aadd (_aCols, {.Tipo    , 'Tipo'            , 10, '@!'				 })
		aadd (_aCols, {.Cliente , 'Cliente'         , 80, '@!'				 })
		aadd (_aCols, {.Valor   , 'Valor'           , 30, "@E 999,999,999.99"})
		
		U_MBArray (@_aDados, 'Solicitações para aprovação', _aCols, 1)

		for _x = 1 to len (_aDados)				
			if _aDados[_x, .Ok]
                U_VA_FINA630(xFilial("SE6"),_aDados[_x, .Solicit] )
			endif			
		next
        u_help("Operação Finalizada!")
	else
		u_help("Sem registros selecionados!")
	endif
Return
//
// --------------------------------------------------------------------------------
// Aprovação de solicitações
User Function VA_FINA630(_sFilial, _sSolicit)
    Local _aSolict := {}
    Local _cChave :=   _sFilial + _sSolicit
    
    lMsErroAuto := .F.

    DbSelectArea("SE6")
    DbSetOrder(3)
    DbGoTop()

    If SE6->(DbSeek(_cChave,.T.))
        _aSolict :=   {{"E6_NUMSOL" ,_sSolicit ,Nil}}
        MSExecAuto({|x,y|   Fina630(x,y)},_aSolict,3)
    Else
        u_help("Registro não encontrado")
        Return
    EndIf

    If lMsErroAuto
        MostraErro()
    Else
        //u_help("Solicitação liberada!")
    Endif
Return
