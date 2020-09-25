//  Programa...: ML_PAGRAP
//  Autor......: Catia Cardoso
//  Data.......: 01/10/2015
//  Cliente....: Alianca
//  Descricao..: Relatório de Rapel Pago por Período
//
//  Alterações:
//  19/10/2015 - Catia - criada opcao por REDE para facilitar na conciliação
//  12/06/2017 - Catia - alterações rapel para valor e para buscar direto do SE1 e nao do SF2
//  22/06/2018 - Catia - criada opcao de buscar por data de emissao ou vencimento 
//             - Catia - Alterado o nome do relatorio para relatorio para Rapel Previsto x Realizado

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_PAGRAP()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE1"
    cDesc1  := "Rapel - Previsto x Realizado"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_PAGRAP"
    wnrel   := "ML_PAGRAP"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    
    	if mv_par03 = 2
   			msgalert("Na opção de cliente por REDE, o sistema buscar o codigo do cliente MATRIZ informado no cadastro. Esta informação tem que estar correta para que funcione como o esperado.")
   			if mv_par04 != mv_par05
   				msgalert("Na opção por REDE, os parametros inicial e final de cliente devem ser iguais.")   			
   			endif
   		endif
	
    	
    	titulo  := "Rapel Previsto x Realizado"
    
    	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
    	If nLastKey == 27
       		Return
    	Endif
    
    	SetDefault(aReturn,cString)
    	If nLastKey == 27
       		Return
    	Endif
		
		RptStatus({|| RptDetail()})     		
	endif    	

return

Static Function RptDetail()

    SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
   	cabec1:="FIL PRF NUMERO       CLIENTE                                                DT.VENCIMENTO              VALOR      R A P E L      DT.MOVIMENTO        R A P E L"
   	cabec2:="        TITULO                                                                                        TITULO       PREVISTO                          REALIZADO"

	_sQuery = ""
    IF mv_par12 = 3  // opcao por data de vencimento
	   	_sQuery += "SELECT E5_FILIAL    AS FILIAL"
	    _sQuery += "     , E5_PREFIXO   AS PREFIXO"
	    _sQuery += "     , E5_NUMERO    AS NUMERO"
	    _sQuery += "     , E5_PARCELA   AS PARCELA"
	    _sQuery += "     , E5_CLIENTE   AS CLIENTE"
	    _sQuery += "     , E5_LOJA      AS LOJA"
	    _sQuery += "     , A1_NOME      AS NOME"
	    _sQuery += "     , E1_VENCREA   AS VENCTO"
	    _sQuery += "     , E1_VALOR     AS VLR_TIT"
	    _sQuery += "     , E1_VARAPEL   AS VLR1_RAPEL"
		_sQuery += "     , E5_DATA      AS DT_MOV"
		_sQuery += "     , E5_VARAPEL   AS VLR5_RAPEL"
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
	   	_sQuery += "   AND SE5.E5_VARAPEL > 0"
	   	_sQuery += " ORDER BY E5_DATA, E5_FILIAL, E5_NUMERO, E5_PARCELA"
   	ELSE
   		// SE A OPCAO DE DATA FOR POR EMISSAO OU VENCIMENTO
	    _sQuery += "SELECT SE1.E1_FILIAL	AS FILIAL"
	    _sQuery += "	 , SE1.E1_PREFIXO   AS PREFIXO"
	    _sQuery += "     , SE1.E1_NUM       AS NUMERO"
	    _sQuery += "     , SE1.E1_PARCELA   AS PARCELA"
		_sQuery += "     , SE1.E1_CLIENTE   AS CLIENTE"
		_sQuery += "     , SE1.E1_LOJA      AS LOJA"
		_sQuery += "     , SA1.A1_NOME      AS NOME"
	    _sQuery += "     , SE1.E1_VENCREA   AS VENCTO"
	    _sQuery += "     , SE1.E1_VALOR		AS VLR_TIT"
	    _sQuery += "     , SE1.E1_VARAPEL   AS VLR1_RAPEL"
	    _sQuery += "     , ISNULL (SE5.E5_DATA, '')  AS DT_MOV"
		_sQuery += "     , ISNULL( SE5.E5_VARAPEL,0) AS VLR5_RAPEL"
	  	_sQuery += "  FROM SE1010 AS SE1"
		_sQuery += "	INNER JOIN SA1010 AS SA1"
		_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += "			AND SA1.A1_COD = SE1.E1_CLIENTE"
		IF mv_par03 = 2  // opcao por rede 
			_sQuery += "		AND SA1.A1_VACBASE  BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
		ENDIF			
		_sQuery += "			AND SA1.A1_LOJA = SE1.E1_LOJA)"
		_sQuery += "	LEFT JOIN SE5010 AS SE5"
		_sQuery += "		ON (SE5.D_E_L_E_T_ = ''"
		_sQuery += "			AND SE5.E5_FILIAL  = SE1.E1_FILIAL"
		_sQuery += "			AND SE5.E5_NUMERO  = SE1.E1_NUM"
		_sQuery += "			AND SE5.E5_PARCELA = SE1.E1_PARCELA"
		_sQuery += "			AND SE5.E5_RECPAG  = 'R'"
		_sQuery += "			AND SE5.E5_TIPODOC = 'DC'"
		_sQuery += "			AND SE5.E5_SITUACA = ''"
		_sQuery += "			AND SE5.E5_VARAPEL > 0"
		_sQuery += "			AND SE5.E5_CLIENTE = SE1.E1_CLIENTE"
		_sQuery += "			AND SE5.E5_LOJA    = SE1.E1_LOJA)"
	 	_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
	   	_sQuery += "   AND SE1.E1_FILIAL  = '01'"
	   	IF mv_par12 = 1  // opcao por data de emissao
	   		_sQuery += "   AND SE1.E1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		ENDIF
		IF mv_par12 = 2  // opcao por data de vencimento
	   		_sQuery += "   AND SE1.E1_VENCTO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		ENDIF	   		
	    _sQuery += "   AND SE1.E1_VEND1  BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "'"
	   	_sQuery += "   AND SE1.E1_VARAPEL > 0"
	    IF mv_par03 = 1  // opcao por cliente
			_sQuery += "   AND SE1.E1_CLIENTE BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
	 		_sQuery += "   AND SE1.E1_LOJA    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
	 	ENDIF
	 	IF mv_par12 = 1  // opcao por data de emissao
	 		_sQuery += "   ORDER BY SE1.E1_EMISSAO, E1_FILIAL, E1_NUM, E1_PARCELA"
	 	ENDIF
	 	IF mv_par12 = 2  // opcao por data de vencimento
	 		_sQuery += "   ORDER BY SE1.E1_VENCTO, E1_FILIAL, E1_NUM, E1_PARCELA"
	 	ENDIF
   	ENDIF
	
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    if mv_par13 = 2
       (_sAliasQ) -> (DBGoTop ())
     	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
     	return
	endif     	
    
    _aTotGer  = {0,0,0,0,0,0,0}
    (_sAliasQ) -> (DBGoTop ())
     _vendAnt := ""
     _vendAntnome := ""
     Do While ! (_sAliasQ) -> (Eof ())
			     
	     	If li>58
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           	
           	@li,  00 PSAY (_sAliasQ) -> FILIAL
           	@li,  05 PSAY (_sAliasQ) -> PREFIXO
           	@li,  07 PSAY (_sAliasQ) -> NUMERO + IIF( (_sAliasQ) -> PARCELA !=' ' ,'-' + (_sAliasQ) -> PARCELA, '')
           	@li,  20 PSAY (_sAliasQ) -> CLIENTE + '/' + (_sAliasQ) -> LOJA + ' - ' + LEFT((_sAliasQ) -> NOME,38)
           	@li,  78 PSAY stod((_sAliasQ) -> VENCTO)
           	@li,  95 PSAY (_sAliasQ) -> VLR_TIT    Picture "@E 9,999,999.99"
           	@li, 112 PSAY (_sAliasQ) -> VLR1_RAPEL Picture "@E 999,999.99"
           	@li, 130 PSAY stod((_sAliasQ) -> DT_MOV)
           	@li, 148 PSAY (_sAliasQ) -> VLR5_RAPEL  Picture "@E 999,999.99"
           	li ++
        
           _aTotGer [1] += (_sAliasQ) -> VLR_TIT
           _aTotGer [2] += (_sAliasQ) -> VLR1_RAPEL
           _aTotGer [3] += (_sAliasQ) -> VLR5_RAPEL
                           
           (_sAliasQ) -> (dbskip())
     enddo
     
 	if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li,  00 PSAY "TOTAL GERAL --> "
        @ li,  95 PSAY _aTotGer [1]  Picture "@E 99,999,999.99"
        @ li, 112 PSAY _aTotGer [2]  Picture "@E 9999,999.99"
       	@ li, 148 PSAY _aTotGer [3]  Picture "@E 9999,999.99"
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

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Referencial   de  ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Data Referencial   até ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {03, "Opção para cliente     ?", "N", 1,  0,  "",   "   ", {"Cliente","Rede"},   ""})
    aadd (_aRegsPerg, {04, "Cliente de             ?", "C", 6, 0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {05, "Cliente ate            ?", "C", 6, 0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {06, "Loja de                ?", "C", 2, 0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {07, "Loja ate               ?", "C", 2, 0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {08, "Filial de              ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {09, "Filial até             ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {10, "Vendedor de            ?", "C", 6, 0,  "",   "SA3", {},                        "Vendedor Inicial"})
	aadd (_aRegsPerg, {11, "Vendedor ate           ?", "C", 6, 0,  "",   "SA3", {},                        "Vendedor Final"})
	aadd (_aRegsPerg, {12, "Usar data              ?", "N", 1,  0,  "",   "   ", {"Emissao","Vencimento","Pagamento"},   ""})
	aadd (_aRegsPerg, {13, "Gerar Planilha         ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   ""})
    
    
    U_ValPerg (cPerg, _aRegsPerg)
Return
