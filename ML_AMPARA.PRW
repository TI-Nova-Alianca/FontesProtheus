//  Programa...: ML_AMPARA
//  Autor......: Andre Alves
//  Data.......: 03/08/2018
//  Descricao..: Relatório auxiliar para apuracao AMPARA/RS
//
//  Historico de alteracoes:
//  06/11/2018 - Andre - Filtrado para mostrar somente notas do estado do RS
//  09/11/2018 - Andre - Ajustado para mostrar notas de devolução com valores negatico

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_AMPARA()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE1"
    cDesc1  := "Relatório AMPARA"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório AMPARA"
    cPerg   := "ML_AMPARA"
    wnrel   := "ML_AMPARA"
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
return

Static Function RptDetail()
	local _aCFOP  := {}
	local _nCFOP   := 0
	local _aFILCFOP  := {}
	local _nFILCFOP  := 0
	local _nMaxLin   := 63
	local _sQuery    := ""
	local _aAliasQ   := ""
	local _nValor    := 0
	local _aTotVend  := {}
	local _aTotGer   := {}
	local _sFilial   := ""
	local _aTotFil   := {}
	
    SetRegua(LastRec())
    nTipo   := IIF(aReturn[4]==1,15,18)
    li      := 80
    m_pag   := 1
    cabec1  :="FILIAL   ENTRADA       NFISCAL     SERIE     CLI/FORN     TIPO     C.FISCAL   UF      EMISSAO    ALIQ ICMS      VAL CONTA        BASE ICMS        VAL ICMS          VAL FECP           ICMS RET           V FECP ST"
    cabec2  :=""
     
    _sQuery := " "
    _sQuery += " SELECT SF3.F3_FILIAL AS FILIAL, SF3.F3_ENTRADA AS ENTRADA, SF3.F3_NFISCAL AS NFISCAL,"
	_sQuery += "        SF3.F3_SERIE AS SERIE, SF3.F3_CLIEFOR AS CLIEFOR,"
	_sQuery += " CASE WHEN SA1.A1_TIPO = 'S' THEN 'SOLIDARIO'"
	_sQuery += "	  WHEN SA1.A1_TIPO = 'F' THEN 'CONS. FINAL'"
	_sQuery += "	  WHEN SA1.A1_TIPO = 'L' THEN 'PRODUTOR RURAL'"
	_sQuery += "	  WHEN SA1.A1_TIPO = 'R' THEN 'OUTROS'"
	_sQuery += "	  WHEN SA1.A1_TIPO = 'X' THEN 'EXPORTACAO'"
	_sQuery += " END TIPO,"
	_sQuery += "		SF3.F3_CFO AS CFO,"
	_sQuery += "        SF3.F3_ESTADO AS ESTADO, SF3.F3_EMISSAO AS EMISSAO, SF3.F3_ALIQICM AS ALIQICM,"
	_sQuery += "         CASE WHEN SF3.F3_CFO < '5000' THEN SF3.F3_VALCONT*-1 ELSE  SF3.F3_VALCONT END VALCONT,"
	_sQuery += "         CASE WHEN SF3.F3_CFO < '5000' THEN SF3.F3_BASEICM*-1 ELSE  SF3.F3_BASEICM END BASEICM,"
	_sQuery += "         CASE WHEN SF3.F3_CFO < '5000' THEN SF3.F3_VALICM*-1 ELSE  SF3.F3_VALICM END VALICM,"					
	_sQuery += "         CASE WHEN SF3.F3_CFO < '5000' THEN SF3.F3_VALFECP*-1 ELSE  SF3.F3_VALFECP END VALFECP,"
	_sQuery += "         CASE WHEN SF3.F3_CFO < '5000' THEN SF3.F3_ICMSRET*-1 ELSE  SF3.F3_ICMSRET END ICMRET,"
	_sQuery += "         CASE WHEN SF3.F3_CFO < '5000' THEN SF3.F3_VFECPST*-1 ELSE  SF3.F3_VFECPST END VFECPST"
	_sQuery += "      FROM " + RetSQLName ("SF3") + " AS SF3"
	_sQuery += "		INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
	_sQuery += "			ON ( SA1.D_E_L_E_T_ = ''"
	_sQuery += "			AND SA1.A1_FILIAL = ''"
	_sQuery += "			AND SA1.A1_COD = SF3.F3_CLIEFOR"
	_sQuery += "			AND SA1.A1_LOJA = SF3.F3_LOJA)"
	_sQuery += "      WHERE SF3.D_E_L_E_T_ = ''"
	_sQuery += "        AND SF3.F3_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
//	_sQuery += "        AND SF3.F3_CFO > '5000'"
  	_sQuery += "        AND SF3.F3_ENTRADA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
  	_sQuery += "        AND SF3.F3_DTCANC = ''" 
  	_sQuery += "        AND SF3.F3_ESTADO = '" + mv_par05 + "'"
	_sQuery += "        AND (SF3.F3_VALFECP>0 OR SF3.F3_VFECPST>0)"
	_sQuery += "      ORDER BY SF3.F3_FILIAL, SF3.F3_ENTRADA"
	
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotGer  = {0,0,0,0,0,0,0,0}
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
     	
		   If li>58
           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           Endif        
        		     
           @li,  02 PSAY (_sAliasQ) -> FILIAL
           @li,  08 PSAY stod((_sAliasQ) -> ENTRADA)
           @li,  22 PSAY (_sAliasQ) -> NFISCAL
           @li,  37 PSAY (_sAliasQ) -> SERIE
		   @li,  46 PSAY (_sAliasQ) -> CLIEFOR
           @li,  56 PSAY (_sAliasQ) -> TIPO
           @li,  69 PSAY (_sAliasQ) -> CFO
           @li,  77 PSAY (_sAliasQ) -> ESTADO
           @li,  83 PSAY stod((_sAliasQ) -> EMISSAO)
           @li,  99 PSAY (_sAliasQ) -> ALIQICM
           @li, 107 PSAY (_sAliasQ) -> VALCONT Picture   "@E 99,999,999.99"
           @li, 124 PSAY (_sAliasQ) -> BASEICM Picture   "@E 99,999,999.99"
           @li, 140 PSAY (_sAliasQ) -> VALICM Picture    "@E 99,999,999.99"
           @li, 158 PSAY (_sAliasQ) -> VALFECP Picture   "@E 99,999,999.99"
           @li, 177 PSAY (_sAliasQ) -> ICMRET Picture    "@E 99,999,999.99"
           @li, 197 PSAY (_sAliasQ) -> VFECPST Picture   "@E 99,999,999.99"
           li ++
		   
           // acumula total das emissoes
           _aTotGer[1] += (_sAliasQ) -> VALCONT
           _aTotGer[2] += (_sAliasQ) -> BASEICM
           _aTotGer[3] += (_sAliasQ) -> VALICM
           _aTotGer[4] += (_sAliasQ) -> VALFECP
           _aTotGer[5] += (_sAliasQ) -> ICMRET
           _aTotGer[6] += (_sAliasQ) -> VFECPST
           
            // Acrescenta esta bonificacao `a array para posterior totalizacao por FILIAL / CFOP.
			_nFILCFOP = ascan (_aFILCFOP, {|_aVal| _aVal [1] == (_sAliasQ) -> FILIAL + ' ' +(_sAliasQ) -> CFO })
			if _nFILCFOP == 0
				aadd (_aFILCFOP, { (_sAliasQ) -> FILIAL + ' ' +(_sAliasQ) -> CFO, 0,0,0,0,0,0})
				_nFILCFOP = len (_aFILCFOP)
			endif
			_aFILCFOP [_nFILCFOP, 2] += (_sAliasQ) -> VALCONT
			_aFILCFOP [_nFILCFOP, 3] += (_sAliasQ) -> BASEICM
			_aFILCFOP [_nFILCFOP, 4] += (_sAliasQ) -> VALICM
			_aFILCFOP [_nFILCFOP, 5] += (_sAliasQ) -> VALFECP
            _aFILCFOP [_nFILCFOP, 6] += (_sAliasQ) -> ICMRET
            _aFILCFOP [_nFILCFOP, 7] += (_sAliasQ) -> VFECPST
           
           // Acrescenta esta bonificacao `a array para posterior totalizacao por CFOP.
			_nCFOP = ascan (_aCFOP, {|_aVal| _aVal [1] == (_sAliasQ) -> CFO})
			if _nCFOP == 0
				aadd (_aCFOP, {(_sAliasQ) -> CFO, 0,0,0,0,0,0})
				_nCFOP = len (_aCFOP)
			endif
			_aCFOP [_nCFOP, 2] += (_sAliasQ) -> VALCONT
			_aCFOP [_nCFOP, 3] += (_sAliasQ) -> BASEICM
			_aCFOP [_nCFOP, 4] += (_sAliasQ) -> VALICM
			_aCFOP [_nCFOP, 5] += (_sAliasQ) -> VALFECP
            _aCFOP [_nCFOP, 6] += (_sAliasQ) -> ICMRET
            _aCFOP [_nCFOP, 7] += (_sAliasQ) -> VFECPST
            
           (_sAliasQ) -> (dbskip())
     enddo
     
     if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @li, 00 PSAY "TOTAL DO GERAL --> "
        @li, 110 PSAY _aTotGer[1] Picture "@E 99,999,999.99"
        @li, 130 PSAY _aTotGer[2] Picture "@E 99,999,999.99"
        @li, 149 PSAY _aTotGer[3] Picture "@E 99,999,999.99"
        @li, 168 PSAY _aTotGer[4] Picture "@E 99,999,999.99"
        @li, 187 PSAY _aTotGer[5] Picture "@E 99,999,999.99"
        @li, 207 PSAY _aTotGer[6] Picture "@E 99,999,999.99"
	    
        li++
     Endif
     
	// Gera nova pagina com totais por filial/CFOP.
	if len (_aFILCFOP) > 0
		_aFILCFOP = asort (_aFILCFOP,,, {|_x, _y| _x [1] < _y [1]})
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		@ li, 0 psay "Totais por Filial/CFOP:"
		li += 2
		@ li, 0 psay "CODIGO FILIAL/CFOP                                    VALOR CONTA      BASE ICMS      VALOR ICMS      VALOR FECP        ICMS RET   VALOR FECP ST"
		li ++
		@ li, 0 psay "---------------------------------------------------  ------------   ------------   -------------   -------------   -------------   -------------"
		li ++
		
		_nFILCFOP = 1
		do while _nFILCFOP <= len (_aFILCFOP)
			_sFilial = _aFILCFOP [_nFILCFOP, 1]
			_sFilial = substr(_aFILCFOP [_nFILCFOP, 1],1,2)
			_aTotFil = {0,0,0,0,0,0,0,0}
			do while _nFILCFOP <= len (_aFILCFOP) .and. substr(_aFILCFOP [_nFILCFOP, 1],1,2) == _sFilial
				if li > _nMaxLin - 2
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				@ li,    0 psay _aFILCFOP [_nFILCFOP, 1]
				@ li,   51 psay transform (_aFILCFOP [_nFILCFOP, 2], "@E 999,999,999.99")
				@ li,   66 psay transform (_aFILCFOP [_nFILCFOP, 3], "@E 999,999,999.99")
				@ li,   82 psay transform (_aFILCFOP [_nFILCFOP, 4], "@E 999,999,999.99")
				@ li,   98 psay transform (_aFILCFOP [_nFILCFOP, 5], "@E 999,999,999.99")
				@ li,  114 psay transform (_aFILCFOP [_nFILCFOP, 6], "@E 999,999,999.99")
				@ li,  130 psay transform (_aFILCFOP [_nFILCFOP, 7], "@E 999,999,999.99")
				li ++
				
				// Acumula totais da filial
			   _aTotFil[1] += _aFILCFOP [_nFILCFOP, 2]
			   _aTotFil[2] += _aFILCFOP [_nFILCFOP, 3]
	           _aTotFil[3] += _aFILCFOP [_nFILCFOP, 4]
	           _aTotFil[4] += _aFILCFOP [_nFILCFOP, 5]
	           _aTotFil[5] += _aFILCFOP [_nFILCFOP, 6]
	           _aTotFil[6] += _aFILCFOP [_nFILCFOP, 7]
	           _nFILCFOP ++
	           
	        enddo
			
			// Imprime totais da filial
			@ li, 0 psay "---------------------------------------------------  ------------   ------------   -------------   -------------   -------------   -------------"
			li ++
			@ li,    0 psay "Acumulado por FILIAL/CFOP:"
			@ li,   51 psay transform (_aTotFil [1], "@E 999,999,999.99") // VALOR CONTA
			@ li,   66 psay transform (_aTotFil [2], "@E 999,999,999.99") // BASE ICMS
			@ li,   82 psay transform (_aTotFil [3], "@E 999,999,999.99") // VALOR ICMS
			@ li,   98 psay transform (_aTotFil [4], "@E 999,999,999.99") // VAL FECP
			@ li,  114 psay transform (_aTotFil [5], "@E 999,999,999.99") // ICMS RET
			@ li,  130 psay transform (_aTotFil [6], "@E 999,999,999.99") // V FECP ST
			li += 2
			
		enddo
	
		@ li, 0 psay "---------------------------------------------------  ------------   ------------   -------------   -------------   -------------   -------------"
		li ++
		@ li,    0 psay "TOTAL GERAL -->"
		@ li,   51 psay transform (_aTotGer [1], "@E 999,999,999.99") // VALOR CONTA
		@ li,   66 psay transform (_aTotGer [2], "@E 999,999,999.99") // BASE ICMS
		@ li,   82 psay transform (_aTotGer [3], "@E 999,999,999.99") // VALOR ICMS
		@ li,   98 psay transform (_aTotGer [4], "@E 999,999,999.99") // VAL FECP
		@ li,  114 psay transform (_aTotGer [5], "@E 999,999,999.99") // ICMS RET
		@ li,  130 psay transform (_aTotGer [6], "@E 999,999,999.99") // V FECP ST

	endif     
     
    // Gera nova pagina com totais por CFOP.
	if len (_aCFOP) > 0
		_aCFOP = asort (_aCFOP,,, {|_x, _y| _x [1] < _y [1]})
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		@ li, 0 psay "Totais por CFOP:"
		li += 2
		@ li, 0 psay "CODIGO CFOP                                           VALOR CONTA      BASE ICMS      VALOR ICMS      VALOR FECP        ICMS RET   VALOR FECP ST"
		li ++
		@ li, 0 psay "---------------------------------------------------  ------------   ------------   -------------   -------------   -------------   -------------"
		li ++
		
		for _nCFOP = 1 to len (_aCFOP)
			if li > _nMaxLin - 2
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li,    0 psay _aCFOP [_nCFOP, 1] 
			@ li,   51 psay transform (_aCFOP [_nCFOP, 2], "@E 999,999,999.99")
			@ li,   66 psay transform (_aCFOP [_nCFOP, 3], "@E 999,999,999.99")
			@ li,   82 psay transform (_aCFOP [_nCFOP, 4], "@E 999,999,999.99")
			@ li,   98 psay transform (_aCFOP [_nCFOP, 5], "@E 999,999,999.99")
			@ li,  114 psay transform (_aCFOP [_nCFOP, 6], "@E 999,999,999.99")
			@ li,  130 psay transform (_aCFOP [_nCFOP, 7], "@E 999,999,999.99")
			li ++
		next
		@ li, 0 psay "---------------------------------------------------  ------------   ------------   -------------   -------------   -------------   -------------"
		li ++
		@ li,    0 psay "TOTAL GERAL -->"
		@ li,   51 psay transform (_aTotGer [1], "@E 999,999,999.99") // VALOR CONTA
		@ li,   66 psay transform (_aTotGer [2], "@E 999,999,999.99") // BASE ICMS
		@ li,   82 psay transform (_aTotGer [3], "@E 999,999,999.99") // VALOR ICMS
		@ li,   98 psay transform (_aTotGer [4], "@E 999,999,999.99") // VAL FECP
		@ li,  114 psay transform (_aTotGer [5], "@E 999,999,999.99") // ICMS RET
		@ li,  130 psay transform (_aTotGer [6], "@E 999,999,999.99") // V FECP ST

		li += 2
	endif
	
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
    aadd (_aRegsPerg, {01, "Filial de                    ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {02, "Filial até                   ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Data de Entrada de           ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {04, "Data de Entrada até          ?", "D", 8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {05, "Estado                       ?", "C", 2, 0,  "",   "   ", {},                         ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return