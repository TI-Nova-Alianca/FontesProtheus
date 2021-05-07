//  Programa...: ML_PAGDESC
//  Autor......: Catia Cardoso
//  Data.......: 01/10/2015
//  Cliente....: Alianca
//  Descricao..: Relatório de Analise de Descontos p/Cliente/Rede - Periodo
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Analise de Descontos p/Cliente/Rede - Periodo
// #PalavasChave      #analise_de_desconto #rede
// #TabelasPrincipais #SE1 #SE5 
// #Modulos   		  #CTB #FIN
//
//  Historico de alteracoes:
//  19/04/2016 - Catia   - Incluir a data de vencimento do titulo
//  12/06/2017 - Catia   - Alterações conforme definição rapel no SD2 -
//               tirada a parte que acessava o SF2 - não tem mais necessidade
//  22/02/2018 - Catia   - Incluir total na coluna de valor do titulo
//  23/02/2018 - Catia   - Colocado total na coluna de valor dos titulos
//  23/02/2018 - Catia   - Opcao de gerar planilha
//  07/05/2021 - Claudia - Incluido tags de customizações
//
// ----------------------------------------------------------------------------------

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAYSF11
#ENDIF

User function ML_PAGDESC()
	Private cPerg    := "ML_PAGDESC"
	
	_ValidPerg()
    if Pergunte(cPerg,.T.)
		if mv_par03 = 2
			u_help("Na opção de cliente por REDE, o sistema buscar o codigo do cliente MATRIZ informado no cadastro. Esta informação tem que estar correta para que funcione como o esperado.")
			if mv_par04 != mv_par05
				u_help("Na opção por REDE, os parametros inicial e final de cliente devem ser iguais.")   			
			endif
		endif
		    
    	Processa( { |lEnd| _ExecQuery() } )
        if mv_par12 = 2
           Processa( { |lEnd| _GeraArq() } )
        else
           Processa( { |lEnd| _Lista() } )
        endif
	    
    endif
return
//
// --------------------------------------------------------------------------
Static Function _ExecQuery()
    local  _sQuery    := ""
    public _sAliasQ   := ""
   
	_sQuery := " "
    _sQuery += "SELECT E5_FILIAL   AS FILIAL"
    _sQuery += "     , E5_PREFIXO  AS PREFIXO"
    _sQuery += "     , E5_NUMERO   AS NUMERO"
    _sQuery += "     , E5_PARCELA  AS PARCELA"
    _sQuery += "     , E5_CLIENTE  AS CLIENTE"
    _sQuery += "     , E5_LOJA     AS LOJA"
    _sQuery += "     , A1_NOME     AS NOME"
    _sQuery += "     , E1_VALOR    AS VLR_TIT"
    _sQuery += "     , E5_VALOR    AS VLR_LCTO"
	_sQuery += "     , E5_DATA     AS DT_MOV"
	_sQuery += "     , E5_VARAPEL  AS VLR_RAPEL"
	_sQuery += "     , E5_VAENCAR  AS VLR_ENCAR"
	_sQuery += "     , E5_VAFEIRA  AS VLR_FEIRA"
	_sQuery += "     , E5_VADOUTR  AS VLR_OUTR"
	_sQuery += "     , E5_VADFRET  AS VLR_FRET"
	_sQuery += "     , E5_VADDESC  AS VLR_DESC"
	_sQuery += "     , E5_VADDEVO  AS VLR_DEVO"
	_sQuery += "     , E5_VADCMPV  AS VLR_CMPV"
	_sQuery += "     , E5_VADAREI  AS VLR_AREI"
	_sQuery += "     , E5_VADMULC  AS VLR_MULC"
	_sQuery += "     , E1_VENCTO   AS TIT_VENCTO"
	_sQuery += "  FROM " + RetSQLName ("SE5") + " AS SE5 "
	_sQuery += "     INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
 	_sQuery += "			AND SA1.A1_COD     = SE5.E5_CLIENTE"
 	IF mv_par03 = 2  // opcao por rede 
		_sQuery += "		AND SA1.A1_VACBASE  BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
	ENDIF			
	_sQuery += "			AND SA1.A1_LOJA    = SE5.E5_LOJA)"
	_sQuery += "     INNER JOIN " + RetSQLName ("SE1") + " AS SE1 "
	_sQuery += "		ON (SE1.D_E_L_E_T_ = ''"
 	_sQuery += "			AND SE1.E1_FILIAL  = SE5.E5_FILIAL"
	_sQuery += "			AND SE1.E1_PREFIXO = SE5.E5_PREFIXO"
	_sQuery += "			AND SE1.E1_NUM     = SE5.E5_NUMERO"
	_sQuery += "			AND SE1.E1_PARCELA = SE5.E5_PARCELA"
	_sQuery += "			AND SE1.E1_CLIENTE = SE5.E5_CLIENTE"
	_sQuery += "			AND SE1.E1_VEND1 BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "'"
	_sQuery += "			AND SE1.E1_LOJA    = SE5.E5_LOJA)"
	_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
    _sQuery += "   AND SE5.E5_FILIAL  BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
   	_sQuery += "   AND SE5.E5_DATA    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   	IF mv_par03 = 1  // opcao por cliente
		_sQuery += "   AND SE5.E5_CLIENTE BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
 		_sQuery += "   AND SE5.E5_LOJA    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
 	ENDIF
   	_sQuery += "   AND SE5.E5_RECPAG  = 'R'"
   	_sQuery += "   AND SE5.E5_TIPODOC = 'DC'"
   	_sQuery += "   AND SE5.E5_SITUACA = ''"
   	_sQuery += " ORDER BY E5_DATA, E5_FILIAL, E5_NUMERO, E5_PARCELA"
    
    //u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
return
//
// --------------------------------------------------------------------------
Static Function _GeraArq()
     incproc ("Gerando arquivo de exportacao")
     DbGoTop()
     processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
     (_sAliasQ) -> (dbclosearea ())
return
//
// --------------------------------------------------------------------------
Static Function _Lista()

    cString := "SE5"
    cDesc1  := "Analise de Descontos Concedidos"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_PAGDESC"
    wnrel   := "ML_PAGDESC"
    nTipo   := 0
    titulo  := "Analise de Descontos Concedidos"
   
    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
    If nLastKey == 27
        Return
    Endif

    SetDefault(aReturn,cString)
    If nLastKey == 27
        Return
    Endif
	
	RptStatus({|| RptDetail()})     
return
//
// --------------------------------------------------------------------------
Static Function RptDetail()

    SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
   	cabec1:="FIL NUMERO      CLIENTE                                 VALOR  DATA     DATA       DESCONTO      RAPEL      ENCARTE       FEIRAS       OUTROS       FRETES     DESC_FIN    DEVOLUCAO     CAMP.VEN    ABER/REIN        MULTA"
   	cabec2:="    TITULO                                             TITULO  VENCTO   DESC 
    _sQuery := " "
    _sQuery += "SELECT E5_FILIAL   AS FILIAL"
    _sQuery += "     , E5_PREFIXO  AS PREFIXO"
    _sQuery += "     , E5_NUMERO   AS NUMERO"
    _sQuery += "     , E5_PARCELA  AS PARCELA"
    _sQuery += "     , E5_CLIENTE  AS CLIENTE"
    _sQuery += "     , E5_LOJA     AS LOJA"
    _sQuery += "     , A1_NOME     AS NOME"
    _sQuery += "     , E1_VALOR    AS VLR_TIT"
    _sQuery += "     , E5_VALOR    AS VLR_LCTO"
	_sQuery += "     , E5_DATA     AS DT_MOV"
	_sQuery += "     , E5_VARAPEL  AS VLR_RAPEL"
	_sQuery += "     , E5_VAENCAR  AS VLR_ENCAR"
	_sQuery += "     , E5_VAFEIRA  AS VLR_FEIRA"
	_sQuery += "     , E5_VADOUTR  AS VLR_OUTR"
	_sQuery += "     , E5_VADFRET  AS VLR_FRET"
	_sQuery += "     , E5_VADDESC  AS VLR_DESC"
	_sQuery += "     , E5_VADDEVO  AS VLR_DEVO"
	_sQuery += "     , E5_VADCMPV  AS VLR_CMPV"
	_sQuery += "     , E5_VADAREI  AS VLR_AREI"
	_sQuery += "     , E5_VADMULC  AS VLR_MULC"
	_sQuery += "     , E1_VENCTO   AS TIT_VENCTO"
	_sQuery += "  FROM " + RetSQLName ("SE5") + " AS SE5 "
	_sQuery += "     INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
 	_sQuery += "			AND SA1.A1_COD     = SE5.E5_CLIENTE"
 	IF mv_par03 = 2  // opcao por rede 
		_sQuery += "		AND SA1.A1_VACBASE  BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
	ENDIF			
	_sQuery += "			AND SA1.A1_LOJA    = SE5.E5_LOJA)"
	_sQuery += "     INNER JOIN " + RetSQLName ("SE1") + " AS SE1 "
	_sQuery += "		ON (SE1.D_E_L_E_T_ = ''"
 	_sQuery += "			AND SE1.E1_FILIAL  = SE5.E5_FILIAL"
	_sQuery += "			AND SE1.E1_PREFIXO = SE5.E5_PREFIXO"
	_sQuery += "			AND SE1.E1_NUM     = SE5.E5_NUMERO"
	_sQuery += "			AND SE1.E1_PARCELA = SE5.E5_PARCELA"
	_sQuery += "			AND SE1.E1_CLIENTE = SE5.E5_CLIENTE"
	_sQuery += "			AND SE1.E1_VEND1 BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "'"
	_sQuery += "			AND SE1.E1_LOJA    = SE5.E5_LOJA)"
	_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
    _sQuery += "   AND SE5.E5_FILIAL  BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
   	_sQuery += "   AND SE5.E5_DATA    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   	IF mv_par03 = 1  // opcao por cliente
		_sQuery += "   AND SE5.E5_CLIENTE BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
 		_sQuery += "   AND SE5.E5_LOJA    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
 	ENDIF
   	_sQuery += "   AND SE5.E5_RECPAG  = 'R'"
   	_sQuery += "   AND SE5.E5_TIPODOC = 'DC'"
   	_sQuery += "   AND SE5.E5_SITUACA = ''"
   	_sQuery += " ORDER BY E5_DATA, E5_FILIAL, E5_NUMERO, E5_PARCELA"
    
    //u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotGer  = {0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    (_sAliasQ) -> (DBGoTop ())
     _vendAnt := ""
     _vendAntnome := ""
     Do While ! (_sAliasQ) -> (Eof ())
			     
	     	If li>58
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           	
           	@li,  00 PSAY (_sAliasQ) -> FILIAL
           	@li,  04 PSAY (_sAliasQ) -> NUMERO + IIF( (_sAliasQ) -> PARCELA !=' ' ,'-' + (_sAliasQ) -> PARCELA, '')
           	@li,  16 PSAY (_sAliasQ) -> CLIENTE + '/' + (_sAliasQ) -> LOJA + ' - ' + LEFT((_sAliasQ) -> NOME,18)
           	@li,  49 PSAY (_sAliasQ) -> VLR_TIT    Picture "@E 9,999,999.99"
           	_wdata = SUBSTR((_sAliasQ) -> TIT_VENCTO,3,6) // data de vencimento
           	@li,  63 PSAY SUBSTR(_wdata,5,2) + "/" + SUBSTR(_wdata,3,2) + "/" + SUBSTR(_wdata,1,2)  
           	_wdata = SUBSTR((_sAliasQ) -> DT_MOV,3,6) // data do desconto
           	@li,  72 PSAY SUBSTR(_wdata,5,2) + "/" + SUBSTR(_wdata,3,2) + "/" + SUBSTR(_wdata,1,2)  
           	@li,  81 PSAY (_sAliasQ) -> VLR_LCTO   Picture "@E 999,999.99"
           	@li,  92 PSAY (_sAliasQ) -> VLR_RAPEL  Picture "@E 999,999.99"
           	@li, 105 PSAY (_sAliasQ) -> VLR_ENCAR  Picture "@E 999,999.99"
			@li, 118 PSAY (_sAliasQ) -> VLR_FEIRA  Picture "@E 999,999.99"
			@li, 131 PSAY (_sAliasQ) -> VLR_OUTR   Picture "@E 999,999.99"
			@li, 144 PSAY (_sAliasQ) -> VLR_FRET   Picture "@E 999,999.99"
			@li, 157 PSAY (_sAliasQ) -> VLR_DESC   Picture "@E 999,999.99"
			@li, 170 PSAY (_sAliasQ) -> VLR_DEVO   Picture "@E 999,999.99"
			@li, 183 PSAY (_sAliasQ) -> VLR_CMPV   Picture "@E 999,999.99"
			@li, 196 PSAY (_sAliasQ) -> VLR_AREI   Picture "@E 999,999.99"
			@li, 209 PSAY (_sAliasQ) -> VLR_MULC   Picture "@E 999,999.99"
	       	li ++
        
           _aTotGer [1]  += (_sAliasQ) -> VLR_LCTO
           _aTotGer [2]  += (_sAliasQ) -> VLR_RAPEL
           _aTotGer [3]  += (_sAliasQ) -> VLR_ENCAR
           _aTotGer [4]  += (_sAliasQ) -> VLR_FEIRA
           _aTotGer [5]  += (_sAliasQ) -> VLR_OUTR
           _aTotGer [6]  += (_sAliasQ) -> VLR_FRET
           _aTotGer [7]  += (_sAliasQ) -> VLR_DESC 
           _aTotGer [8]  += (_sAliasQ) -> VLR_DEVO 
           _aTotGer [9]  += (_sAliasQ) -> VLR_CMPV
           _aTotGer [10] += (_sAliasQ) -> VLR_AREI 
           _aTotGer [11] += (_sAliasQ) -> VLR_MULC 
		   _aTotGer [12] += (_sAliasQ) -> VLR_TIT	
                           
           (_sAliasQ) -> (dbskip())
     enddo
     
 	if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li, 00 PSAY "TOTAIS      --> "
        @ li, 50 PSAY _aTotGer [12]  Picture "@E 9999,999.99"
        @ li, 80 PSAY _aTotGer [1]   Picture "@E 9999,999.99"
        @ li, 91 PSAY _aTotGer [2]   Picture "@E 9999,999.99"
       	@ li,104 PSAY _aTotGer [3]   Picture "@E 9999,999.99"
       	@ li,117 PSAY _aTotGer [4]   Picture "@E 9999,999.99"
       	@ li,130 PSAY _aTotGer [5]   Picture "@E 9999,999.99"
       	@ li,143 PSAY _aTotGer [6]   Picture "@E 9999,999.99"
       	@ li,156 PSAY _aTotGer [7]   Picture "@E 9999,999.99"
       	@ li,169 PSAY _aTotGer [8]   Picture "@E 9999,999.99"
       	@ li,182 PSAY _aTotGer [9]   Picture "@E 9999,999.99"
       	@ li,195 PSAY _aTotGer [10]  Picture "@E 9999,999.99"
       	@ li,208 PSAY _aTotGer [11]  Picture "@E 9999,999.99"
       	li++
       	
       	_wTotGer := _aTotGer [2] + _aTotGer [3] + _aTotGer [4] + _aTotGer [5] + _aTotGer [6] + _aTotGer [7] + _aTotGer [8] + _aTotGer [9] + _aTotGer [10] + _aTotGer [11] 
       	@ li, 00 PSAY "TOTAL DE DESCONTOS CONCEDIDOS --> "
       	@ li,208 PSAY _wTotGer       Picture "@E 9999,999.99"
       	li++
       	
     Endif
     
     U_ImpParam (58)
    
     Set Device To Screen

     If aReturn[5]==1
           Set Printer TO
           dbcommitAll()
           ourspool(wnrel)
     Endif

     MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Baixa Titulos de  ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Data Baixa Titulos até ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {03, "Opção para cliente     ?", "N", 1, 0,  "",   "   ", {"Cliente","Rede"},   ""})
    aadd (_aRegsPerg, {04, "Cliente de             ?", "C", 6, 0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {05, "Cliente ate            ?", "C", 6, 0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {06, "Loja de                ?", "C", 2, 0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {07, "Loja ate               ?", "C", 2, 0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {08, "Filial de              ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {09, "Filial até             ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {10, "Vendedor de            ?", "C", 6, 0,  "",   "SA3", {},                        "Vendedor Inicial"})
	aadd (_aRegsPerg, {11, "Vendedor ate           ?", "C", 6, 0,  "",   "SA3", {},                        "Vendedor Final"})
	aadd (_aRegsPerg, {12, "Gerar                  ?", "N", 1, 0,  "",   "   ", {"Relatório","Planilha"},   ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
