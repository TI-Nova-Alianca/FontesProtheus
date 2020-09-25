// Programa..: ML_CUPCANC
// Autor.....: Catia Cardoso
// Data......: 23/12/2016
// Nota......: Analise Cupons Cancelados

// Historico de alteracoes:

#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_CUPCANC()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SL1"
    cDesc1  := "Analise de Cupons Cancelados"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_CUPCANC"
    titulo  := "Analise de Cupons Cancelados"
    wnrel   := "ML_CUPCANC"
    nTipo   := 0

    _ValidPerg()
    Pergunte(cPerg,.T.)

    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)

    If nLastKey == 27
	   Return
    Endif
    SetDefault(aReturn,cString)
    If nLastKey == 27
	   Return
    Endif

    RptStatus({|| RptDetail()})
Return

Static Function RptDetail()

    SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1 := " FILIAL    EMISSAO        HORA     ORÇAMENTO    CUPOM    SITUAÇAO                           VALOR BRUTO"
    cabec2 := ""
    
    _sQuery := " "
    _sQuery += " SELECT SL1.L1_FILIAL AS FILIAL, SL1.L1_EMISSAO AS EMISSAO, SL1.L1_HORA AS HORA, SL1.L1_NUM AS NUMERO"
    _sQuery += "      , SL1.L1_DOC AS CUPOM, SL1.L1_VALBRUT AS VALOR, SL1.L1_SITUA AS SITUACAO"
    _sQuery += "      , (SELECT TOP 1 SL11.L1_NUM"
	_sQuery += "           FROM SL1010 AS SL11"
	_sQuery += "	      WHERE SL11.L1_FILIAL  = SL1.L1_FILIAL"
	_sQuery += "	        AND SL11.L1_EMISSAO = SL1.L1_EMISSAO"
	_sQuery += "	        AND SL11.L1_VALBRUT = SL1.L1_VALBRUT"
	_sQuery += "	        AND SL11.L1_HORA    > SL1.L1_HORA"
	_sQuery += "	        AND SL11.L1_NUM    != SL1.L1_NUM"
	_sQuery += "	        AND SL11.L1_SITUA   = 'OK') AS SUBSTITUTO"
  	_sQuery += "   FROM SL1010 AS SL1"
 	_sQuery += "  WHERE SL1.D_E_L_E_T_ = ''"
   	_sQuery += "    AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   	_sQuery += "    AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _sQuery += "    AND SL1.L1_SITUA  != 'OK'"
	_sQuery += " ORDER BY SL1.L1_NUM"

    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVenda  = {0,0,0,0,0,0}
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	If li>58
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	    
	    @ li, 002 PSAY (_sAliasQ) -> FILIAL
	    @ li, 011 PSAY stod((_sAliasQ) -> EMISSAO)
	    @ li, 026 PSAY (_sAliasQ) -> HORA
	    @ li, 038 PSAY (_sAliasQ) -> NUMERO
	    @ li, 048 PSAY (_sAliasQ) -> CUPOM
	    @ li, 058 PSAY (_sAliasQ) -> SITUACAO
	    @ li, 088 PSAY (_sAliasQ) -> VALOR  Picture "@E 9,999,999,999.99"
    	if val( (_sAliasQ) -> SUBSTITUTO ) > 0 
    		_wcupom = fbuscacpo ("SL1", 1, (_sAliasQ) -> FILIAL + (_sAliasQ) -> SUBSTITUTO,  "L1_DOC")
			@ li, 128 PSAY "Provável Cupom substituto : " + _wcupom + "    Orçamento: " + (_sAliasQ) -> SUBSTITUTO
		endif
	    
	    li ++
       	_aTotVenda [1] += (_sAliasQ) -> VALOR
       	
	 	(_sAliasQ) -> (dbskip())
     enddo
	 
	 li ++      
     If li>58
     	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif  
     li ++
	 @ li, 005 PSAY "TOTAL CUPONS CANCELADOS:"
	 @ li, 088 PSAY _aTotVenda[1] Picture "@E 9,999,999,999.99"
	 li ++
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
	aadd (_aRegsPerg, {01, "Emissao de         ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {02, "Emissao ate        ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {03, "Filial de                    ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {04, "Filial até                   ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    
   	U_ValPerg (cPerg, _aRegsPerg)
Return