//  Programa...: ML_PROCOM
//  Autor......: Catia Cardoso
//  Data.......: 13/01/2015
//  Descricao..: Relatório de Provisao de Comissoes
//               Serve de base para conferencia do saldo a debito da conta de provisao de comissoes
//
//  Historico de alteracoes:
//  05/02/2015 - alterada a ordem de impressao para emissao ao inves de vendedor
//  16/02/2015 - alterado o tamanho da letra e quantidade de linha por pagina.
//  24/02/2015 - parametro do codido do vendedor estava pedindo com 6 digitos e deve ser apenas 3
//  20/05/2015 - titulo do relatorio estava errado
//  20/08/2015 - impressao de parametros no final do relatorio
//  20/08/2015 - alterado para que faça provisao apenas sobre VENDA, estava provisionando sobre bonificação.
//  21/08/2015 - alterado layout do relatorio para paisagem
//  28/08/2015 - arredondamento para fechar com a forma que eh feito o lançamento padrao
//  02/09/2015 - tirado o vendedor 135 e 186
//  04/11/2015 - desconsiderar o vendedor 240
//  19/10/2016 - Catia  - Alterado teste de vendedores diretos por parametro $GETMV("MV_VENDDIR")
//
#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_PROCOM()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SD2"
    cDesc1  := "Relatório de Provisão de Comissões"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório de Provisão de Comissões"
    cPerg   := "ML_PROCOM"
    wnrel   := "ML_PROCOM"
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

    SetRegua(LastRec())
    nTipo   := IIF(aReturn[4]==1,15,18)
    li      := 80
    m_pag   := 1
    cabec1  :="DT.EMISSAO  NF/SERIE         BASE CALC.COMISSAO   % COMISSAO   VALOR DA COMISSAO     VENDEDOR "
    cabec2  :=""
    
    _sQuery := " "
  	_sQuery += "SELECT F2_VEND1            AS VENDEDOR"
  	_sQuery += "	 , A3_NOME             AS NOM_VEND"
  	_sQuery += "	 , SD2.D2_EMISSAO      AS DT_EMISSAO"
  	_sQuery += "	 , SD2.D2_DOC          AS NOTA"
  	_sQuery += "	 , SD2.D2_SERIE        AS SERIE"
  	_sQuery += "	 , SUM(SD2.D2_TOTAL)   AS BASE_COM"
  	_sQuery += "	 , SD2.D2_COMIS1       AS PERC_COMIS"
  	_sQuery += "	 , SUM(ROUND(SD2.D2_TOTAL*SD2.D2_COMIS1/100,2)) AS VLR_COM"
  	_sQuery += "	 , SUM(SD2.D2_VALIPI)  AS VLR_IPI"
  	_sQuery += "	 , SUM(SD2.D2_ICMSRET) AS VLR_ST"
  	_sQuery += "	 , SUM(SD2.D2_VALBRUT) AS VLR_BRT"
  	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "		INNER JOIN SF4010 AS SF4"
	_sQuery += "				ON (SF4.D_E_L_E_T_ = ''"
  	_sQuery += "					AND SF4.F4_CODIGO = SD2.D2_TES"
  	_sQuery += "                    AND SF4.F4_MARGEM = '1')"
  	_sQuery += "        INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  	_sQuery += "				ON (SF2.D_E_L_E_T_ = ''" 
  	_sQuery += "					AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
  	_sQuery += "					AND SF2.F2_DOC     = SD2.D2_DOC"
  	_sQuery += "					AND SF2.F2_SERIE   = SD2.D2_SERIE"
  	_sQuery += "					AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
  	_sQuery += "					AND SF2.F2_LOJA    = SD2.D2_LOJA"
  	_sQuery += "					AND SF2.F2_EMISSAO = SD2.D2_EMISSAO"
  	_sQuery += "					AND SF2.F2_VEND1 != ''"
  	_sQuery += "                    AND SF2.F2_VEND1 NOT IN " + FormatIn (alltrim (GetMv ('MV_VENDDIR')), '/') // desconsidera os vendedores diretos
  	_sQuery += "					AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
  	_sQuery += "                INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
  	_sQuery += "						ON (SA3.D_E_L_E_T_ = ''" 
  	_sQuery += "							AND SA3.A3_COD     = SF2.F2_VEND1)"
  	_sQuery += " WHERE SD2.D2_SERIE = '10'"
  	_sQuery += "   AND SD2.D_E_L_E_T_ = ''"
  	_sQuery += "   AND D2_COMIS1 > 0"    
  	_sQuery += "   AND SD2.D2_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
  	_sQuery += "   AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
  	_sQuery += " GROUP BY F2_VEND1, A3_NOME, SD2.D2_EMISSAO, SD2.D2_DOC, SD2.D2_SERIE, SD2.D2_COMIS1 "
  	_sQuery += " ORDER BY D2_EMISSAO, D2_DOC, D2_SERIE "
  	
	//u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVend = {0,0}
    _aTotGer  = {0,0}
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
		If li>58
           cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif
					     
        @li, 00 PSAY  stod((_sAliasQ) -> DT_EMISSAO)
        @li, 12 PSAY (_sAliasQ) -> NOTA
        @li, 23 PSAY (_sAliasQ) -> SERIE
        @li, 29 PSAY (_sAliasQ) -> BASE_COM   Picture "@E 999,999,999,999.99"
        @li, 55 PSAY (_sAliasQ) -> PERC_COMIS Picture "@E 99.99"
        @li, 62 PSAY (_sAliasQ) -> VLR_COM    Picture "@E 999,999,999,999.99"
        @li, 85 PSAY alltrim((_sAliasQ) -> VENDEDOR) + '-' + alltrim((_sAliasQ) -> NOM_VEND)
 		li ++
		   
        // acumula totais
        _aTotGer  [1] += (_sAliasQ) -> BASE_COM
        _aTotGer  [2] += (_sAliasQ) -> VLR_COM
        
        (_sAliasQ) -> (dbskip())
     enddo
     
     if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li, 00 PSAY "TOTAL DO GERAL --> "
        @ li, 29 PSAY _aTotGer [1]  Picture "@E 999,999,999,999.99"
       	@ li, 62 PSAY _aTotGer [2]  Picture "@E 999,999,999,999.99"
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
    aadd (_aRegsPerg, {01, "Filial de                    ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {02, "Filial até                   ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Data de Emissao de           ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {04, "Data de Emissao até          ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {05, "Representante de             ?", "C", 3, 0,  "",   "SA3", {},                        "Representante Inicial"})
    aadd (_aRegsPerg, {06, "Representante ate            ?", "C", 3, 0,  "",   "SA3", {},                        "Represenante Final"})
    aadd (_aRegsPerg, {07, "Nova pagina p/Representante  ?", "S", 1, 0,  "",   "      ", {"Sim", "Nao"}, ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return