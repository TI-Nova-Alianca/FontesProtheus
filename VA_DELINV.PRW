// Programa.: VA_DELINV
// Autor....: Cláudia Lionço
// Data.....: 22/03/2023
// Descricao: Deleta documento de inventário
// 
// Tags para automatizar catalogo de customizacoes:
// #Programa          #processo
// #Descricao		  #Deleta documento de inventário
// #PalavasChave      #inventario 
// #TabelasPrincipais #SB7 
// #Modulos 		  #CUS 
//
// Historico de alteracoes:
// 25/09/2023 - Claudia - Incluido parametro de almoxarifado. GLPI: 14268
//
// ---------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_DELINV()
	Local cCadastro := "Deleta documento de inventário"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	Private cPerg   := "VA_DELINV"
    
    If u_zzuvl('147', __cUserId, .F.)
        _ValidPerg()
        Pergunte(cPerg,.F.)

        AADD(aSays,cCadastro)
        AADD(aSays,"")
        AADD(aSays,"")
        AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
        AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
        AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
        FormBatch( cCadastro, aSays, aButtons )
        If nOpca == 1
            Processa( { |lEnd| _Gera() } )
        Endif
    else
        u_help("Usuário sem permissão no grupo 147 para exclusão de documentos. ")
    EndIf
return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Gera arquivo
Static Function _Gera()
	local _oSQL := NIL

	procregua (10)
	incproc ("Deletando documento de invetário")

    // Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     B7_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,B7_DOC AS DOCUMENTO "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SB7") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND B7_FILIAL = '"+ mv_par01 +"'"
    _oSQL:_sQuery += " AND B7_DOC    = '"+ mv_par02 +"'"
    if !empty(mv_par03)
        _oSQL:_sQuery += " AND B7_LOCAL  = '"+ mv_par03 +"'"
    endif
	_oSQL:Log ()
	_aDados := aclone (_oSQL:Qry2Array (.t.,.t.))

    If Len(_aDados) // se encontrou documento
        _sFilial := mv_par01
        _sDoc    := mv_par02

        dbSelectArea("SB7")
		dbSetOrder(5) // B7_FILIAL+B7_DOC                                                                                                                                                                                                                                    
		dbGoTop()
		dbSeek(_sFilial + _sDoc)

		do while ! sb7->(eof()) .and. sb7->b7_filial == _sFilial .and. sb7->b7_doc == _sDoc
			Reclock("SB7",.F.)
			sb7->(dbdelete())	
			MsUnlock()
            sb7 -> (dbskip ())
		enddo
    else
        u_help("Documento não encontrado!")
    EndIf
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      						                        Help
    aadd (_aRegsPerg, {01, "Filial          ", "C", 2, 0,  "",  "SM0", {},                         								                    ""})                      								                   
    aadd (_aRegsPerg, {02, "Documento       ", "C", 9, 0,  "",  "   ", {},                         								                    ""})
    aadd (_aRegsPerg, {03, "Local           ", "C", 2, 0,  "",  "NNR", {},                         								                    ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return

