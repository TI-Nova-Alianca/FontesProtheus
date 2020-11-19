// Programa  : VA_DFAT295
// Autor     : Catia Cardos
// Data      : 05/05/2016
// Descricao : Detalhemnto de Faturas - Contas a Pagar
// 
// Historico de alteracoes:
//
// 23/08/2017 - Estava mostrando titulos deletados
// --------------------------------------------------------------------------
User Function VA_DFAT295()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	
	cString := "SE2"
    cDesc1  := "Detalhamento de Faturas a Pagar"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "VA_DFAT295"
    titulo  := "Detalhamento de Faturas a Pagar"
    wnrel   := "VA_DFAT295"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
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
Return

Static Function RptDetail()
	SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    
    cabec1:="FORNECEDOR LOJA NATUREZA    NOME FORNECEDOR          PREFIXO  TITULO         PARCELA  TIPO         EMISSAO  VENCIMENTO    VLR.ORIGINAL         VLR.SALDO"
	cabec2:=""
	
	_sQuery := " "
	_sQuery += " SELECT E2_FORNECE, E2_LOJA, E2_NATUREZ, E2_NOMFOR, E2_PREFIXO, E2_NUM, E2_PARCELA"
    _sQuery += "      , E2_TIPO, E2_EMIS1, E2_VENCREA, E2_VALOR, E2_SALDO"
	_sQuery += "      , E2_FATURA"
  	_sQuery += "   FROM SE2010"
 	_sQuery += "  WHERE E2_FILIAL = '" + xfilial ("SE2")  + "'"
 	_sQuery += "    AND D_E_L_E_T_ = ''"
   	_sQuery += "    AND E2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   	_sQuery += "    AND E2_FORNECE BETWEEN '" + mv_par03 + "' AND '"  + mv_par04 + "'"
   	_sQuery += "    AND E2_LOJA BETWEEN '" + mv_par05 + "' AND '"  + mv_par06 + "'"
   	_sQuery += "    AND E2_NUM BETWEEN '" + mv_par07 + "' AND '"  + mv_par08 + "'"
	_sQuery += " ORDER BY E2_FATURA"
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	
	_wfornecedor = '' 
	(_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
     	_sQuery  = " "
		_sQuery += " SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_EMIS1, E2_VENCREA, E2_VALOR, E2_SALDO"
    	_sQuery += "      , E2_FATURA"
		_sQuery += "   FROM SE2010"
 		_sQuery += "  WHERE E2_FILIAL  = '" + xfilial ("SE2")  + "'"
 		_sQuery += "    AND D_E_L_E_T_ = ''"
 		_sQuery += "    AND E2_FORNECE = '" + (_sAliasQ) -> E2_FORNECE  + "'"
 		_sQuery += "    AND E2_LOJA    = '" + (_sAliasQ) -> E2_LOJA  + "'"
   		_sQuery += "    AND E2_FATURA  = '" + (_sAliasQ) -> E2_NUM  + "'"
   		_sAliasT = GetNextAlias ()
		DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasT,.F.,.F.)
		(_sAliasT) -> (DBGoTop ())
    	Do While ! (_sAliasT) -> (Eof ())
    		// imprime dados do forncedor
    		if _wfornecedor != (_sAliasQ)->E2_FORNECE .or. _wfatura != (_sAliasQ)->E2_NUM
    			If li>65
	       			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    		Endif
	    		@ li, 004 PSAY (_sAliasQ)->E2_FORNECE
				@ li, 013 PSAY (_sAliasQ)->E2_LOJA
				@ li, 018 PSAY SUBSTR(ALLTRIM((_sAliasQ)->E2_NATUREZ),1,6)
				@ li, 028 PSAY SUBSTR((_sAliasQ)->E2_NOMFOR,1,20)
				@ li, 053 PSAY (_sAliasQ)->E2_PREFIXO
				@ li, 063 PSAY ALLTRIM((_sAliasQ)->E2_NUM)
				@ li, 080 PSAY (_sAliasQ)->E2_PARCELA
				@ li, 087 PSAY (_sAliasQ)->E2_TIPO
				@ li, 096 PSAY STOD((_sAliasQ)->E2_EMIS1)
				@ li, 108 PSAY STOD((_sAliasQ)->E2_VENCREA)
				@ li, 120 PSAY (_sAliasQ)->E2_VALOR Picture "@E 999,999,999.99"
				@ li, 138 PSAY (_sAliasQ)->E2_SALDO Picture "@E 999,999,999.99"
    			li ++
    			_wfornecedor = (_sAliasQ)->E2_FORNECE
    			_wfatura     = (_sAliasQ)->E2_NUM
			endif    			
    		// imprime dados da fatura
    		If li>65
	       		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    	Endif
	    	@ li, 053 PSAY ALLTRIM((_sAliasT)->E2_PREFIXO)
			@ li, 063 PSAY ALLTRIM((_sAliasT)->E2_NUM)
			@ li, 080 PSAY (_sAliasT)->E2_PARCELA
			@ li, 087 PSAY (_sAliasT)->E2_TIPO
			@ li, 096 PSAY STOD((_sAliasT)->E2_EMIS1)
			@ li, 108 PSAY STOD((_sAliasT)->E2_VENCREA)   
			@ li, 120 PSAY (_sAliasT)->E2_VALOR Picture "@E 999,999,999.99"
			@ li, 138 PSAY (_sAliasT)->E2_SALDO Picture "@E 999,999,999.99"
			li ++
			(_sAliasT) -> (dbskip())
    	enddo
    	li ++
    	(_sAliasQ) -> (dbskip())
	enddo 
	
	U_ImpParam (65)
	 
	Set Device To Screen

    If aReturn[5]==1
	   Set Printer TO
	   dbcommitAll()
	   ourspool(wnrel)
    Endif

    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)   	
    
RETURN	
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
   // local _aDefaults := {}
    
    aadd (_aRegsPerg, {01, "Data Emissao Fatura de  ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Data Emissao Fatura até ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {03, "Fornecedor de           ?", "C", 6, 0,  "",   "SA2", {},                        "Fornecedor Inicial"})
	aadd (_aRegsPerg, {04, "Fornecedor até          ?", "C", 6, 0,  "",   "SA2", {},                        "Fornecedor Final"})
	aadd (_aRegsPerg, {05, "Loja de                 ?", "C", 2, 0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {06, "Loja ate                ?", "C", 2, 0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {07, "Fatura de               ?", "C", 9, 0,  "",   "   ", {},                        "Número da Fatura"})
	aadd (_aRegsPerg, {08, "Fatura até              ?", "C", 9, 0,  "",   "   ", {},                        "Número da Fatura"})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
