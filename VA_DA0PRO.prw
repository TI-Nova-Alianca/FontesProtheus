// Programa: VA_DA0PRO
// Autor...: Cláudia Lionço
// Data....: 16/10/2023
// Funcao..: Exclui produto de tabelas de preço
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Exclui produto de tabela de preço
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0 #DA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "Rwmake.ch"

User Function VA_DA0PRO()
    private cPerg := "VA_DA0PRO"

	//if ! U_ZZUVL ('129', __cUserID, .T.)
	//	return
	//endif

	_ValidPerg ()
	pergunte (cPerg, .T.)

    Processa({|| _ProcessaDel()}, "Excluindo produto das tabelas de preço...")
    u_help("Atualizado!")
Return
//
// ---------------------------------------------------------------------------------------
// Processamento da importação
Static function _ProcessaDel()
    Local _oSQL := ClsSQL():New ()
    Local _x    := 0

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DA1_FILIAL "
    _oSQL:_sQuery += "    ,DA1_CODTAB "
    _oSQL:_sQuery += "    ,DA1_ITEM "
    _oSQL:_sQuery += "    ,DA1_CODPRO "
    _oSQL:_sQuery += " FROM DA1010 "
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND DA1_CODPRO = '"+ MV_PAR01 +"' "
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:= 1 to Len(_aDados)
        _ExcRegistro(_aDados[_x, 1], _aDados[_x, 2], _aDados[_x, 3], _aDados[_x, 4])
    Next

Return
//
// ---------------------------------------------------------------------------------------
// Exclui registros
Static Function _ExcRegistro(_sFilial, _sTabela, _sItem, _sProduto)

    DbSelectArea("DA1")
    DbSetOrder(2) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM                                                                                                                       

    If DbSeek(_sFilial + _sProduto + _sTabela + _sItem ,.F.)
        reclock("DA1", .F.)
            DA1->(DbDelete())                                                                   	                                                                 
        MsUnLock()

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'DA1'
        _oEvento:Texto     = "Produto Excluído "+ _sProduto +". Filial:"+ _sFilial +" Tabela:"+ _sTabela +" Item:"+ _sItem
        _oEvento:Produto   = _sProduto
        _oEvento:CodEven   = "DA0002"
        _oEvento:Grava()
    EndIf        	
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT              TIPO TAM DEC VALID   F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Produto           ", "C", 15, 0,  "",   "SN3", {},      ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
