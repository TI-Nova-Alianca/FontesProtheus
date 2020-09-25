//  Programa...: ML_COMVEND
//  Autor......: Catia Cardoso
//  Data.......: 13/10/2016
//  Descricao..: Consulta Valor de Comissao por Vendedor 
// 
//  Historico de alterações
//  
//  15/08/2018 - Catia - Criada opcao de listar com ou sem correção pelo IGPM  
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_COMVEND()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE3"
    cDesc1  := "Relatório de Comissões"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_COMVEND"
    wnrel   := "ML_COMVEND"
    nTipo   := 0
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 
	
		titulo  := "Relatório demonstrativo de indenização sobre comissoes"
    
    	wnrel:=SetPrint(cString,wnrel,cPerg,titulo ,cDesc1,cDesc2,cDesc3,.F.,"",,tamanho)
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
    
    if mv_par03 == 1 
    	cabec1:=" VENDEDOR                                                FILIAL       DT PAGAMENTO      VALOR COMISSAO           COMISSAO CORRIGIDA              1/2 AVOS"
	else
		cabec1:=" VENDEDOR                                                FILIAL       DT PAGAMENTO      VALOR COMISSAO                  1/2 AVOS"
	endif	    	
    cabec2:=""

	_sQuery := ""
	_sQuery += " SELECT SE3.E3_VEND              AS COD_VEND"
   	_sQuery += "      , SA3.A3_NOME              AS COD_NOME"
   	_sQuery += "      , SE3.E3_FILIAL            AS FILIAL"
   	_sQuery += "      , SE3.E3_DATA			     AS DATA"
   	_sQuery += "      , sum(SE3.E3_COMIS)        AS COMISPAGA"
	_sQuery += "   FROM SE3010 AS SE3"
	_sQuery += "		INNER JOIN SA3010 AS SA3"
	_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA3.A3_COD = SE3.E3_VEND)"
	_sQuery += "  WHERE SE3.D_E_L_E_T_ = ''"
	_sQuery += "	AND SE3.E3_FILIAL  = '" + xfilial ("SE3") + "'"
	_sQuery += "	AND SE3.E3_VEND   BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
	_sQuery += "	AND SE3.E3_DATA  != ''"
	_sQuery += " GROUP BY SE3.E3_FILIAL, SE3.E3_VEND, SA3.A3_NOME, SE3.E3_DATA"
	_sQuery += " ORDER BY SE3.E3_FILIAL, SE3.E3_VEND, SE3.E3_DATA"
	
	//u_showmemo(_sQuery)
	
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVend = {0,0,0}
    _wcol=115
    if mv_par03 == 1
		_wcol=140    	
	endif    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
     	   // imprime totais do vendedor
            If li>65
                cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
            	@li, 02 PSAY ALLTRIM((_sAliasQ) -> COD_VEND)
            	@li, 07 PSAY (_sAliasQ) -> COD_NOME
        	endif
            
            If li>65
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           
           	@li, 61 PSAY (_sAliasQ) -> FILIAL 
           	@li, 72 PSAY stod((_sAliasQ) -> DATA)  
           	@li, 90 PSAY (_sAliasQ) -> COMISPAGA    Picture "@E 9,999,999.99"
           	// calcula valor corrigido ate o mes anterior a data de emissao do relatorio
           	_wdataini  = dtos(stod((_sAliasQ) -> DATA) - 30) 
           	_wvalorcor = (_sAliasQ) -> COMISPAGA
           	if mv_par03 == 1
	           	DbSelectArea('ZAI')
				DbSeek(xFilial('ZAI') + _wdataini,.T.)
				Do While !eof()
					_wigpm = ZAI->ZAI_IGPM
					_wvalorcor = ROUND(_wvalorcor + (_wvalorcor * _wigpm/100) ,4)
					DbSkip()
				EndDo
				@li, 115 PSAY _wvalorcor Picture "@E 9,999,999,999.99"
			endif
			_w12avos = _wvalorcor/12
			// imprime valor da comissao corrigida e os 1/12 avos
			@li, _wcol PSAY _w12avos   Picture "@E 99,999,999.99"
			li ++
            // acumula total
          	_aTotVend [1]  += (_sAliasQ) -> COMISPAGA
          	_aTotVend [2]  += _wvalorcor
          	_aTotVend [3]  += _w12avos
          	(_sAliasQ) -> (dbskip())
     enddo
       	 
     // imprime totais do vendedor
     If li>65
        cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif        
     li++
     @ li, 02 PSAY "TOTAL DO VENDEDOR --> "
     @ li, 90 PSAY _aTotVend [1]  Picture "@E 9,999,999.99"
     if mv_par03 == 1
	     @ li,115 PSAY _aTotVend [2]  Picture "@E 9,999,999,999.99"
	     @ li,140 PSAY _aTotVend [3]  Picture "@E 99,999,999.99"
	 else
	 	@ li,115 PSAY _aTotVend [3]  Picture "@E 99,999,999.99"
	 endif			     
     li++
     
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
    aadd (_aRegsPerg, {01, "Representante de      ?", "C", 6, 0,  "", "SA3", {},  ""})
	aadd (_aRegsPerg, {02, "Representante até     ?", "C", 6, 0,  "", "SA3", {},  ""})
	aadd (_aRegsPerg, {03, "Lista valor corrigido ?", "N", 1,  0,  "", "", {"Sim", "Não"}			, ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return