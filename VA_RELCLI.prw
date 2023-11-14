// Programa...: VA_RELCLI
// Autor......: Cláudia Lionço
// Data.......: 20/10/2023
// Descricao..: Relatório de clientes em planilha. GLPI: 14394
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de clientes em planilha. 
// #PalavasChave      #cadastro_de_cliente #cadastro_cliente 
// #TabelasPrincipais #SA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_RELCLI()
	Local _oSQL   := NIL
	Private cPerg := "VA_RELCLI"

    If ! U_ZZUVL ('156', __cUserID, .T.)
        u_help("Usuário sem permissão no grupo 156!")
		return
	EndIf

	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT DISTINCT "
    _oSQL:_sQuery += " 	   A1_COD AS CLIENTE "
    _oSQL:_sQuery += "    ,A1_NOME AS NOME "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN A1_MSBLQL = 1 THEN 'INATIVO' "
    _oSQL:_sQuery += " 		    ELSE 'ATIVO' "
    _oSQL:_sQuery += " 	    END STATUS "
    _oSQL:_sQuery += "    ,A1_VACBASE AS REDE "
    _oSQL:_sQuery += "    ,A1_CGC AS CNPJ_CPF "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN A1_PESSOA = 'J' THEN 'JURIDICA' "
    _oSQL:_sQuery += " 		    ELSE 'FISICA' "
    _oSQL:_sQuery += " 	    END AS TIPO_PESSOA "
    _oSQL:_sQuery += "    ,A1_MUN AS MINUCIPIO "
    _oSQL:_sQuery += "    ,A1_EST AS ESTADO "
    _oSQL:_sQuery += "    ,A1_REGIAO AS REGIAO "
    _oSQL:_sQuery += "    ,A1_VEND AS VENDEDOR "
    _oSQL:_sQuery += "    ,SA3.A3_NOME AS NOME_VENDEDOR "
    _oSQL:_sQuery += "    ,A1_CODSEG AS SEGMENTO "
    _oSQL:_sQuery += "    ,X5_DESCRI AS DESC_SEGMENTO "
    _oSQL:_sQuery += "    ,A1_CNAE AS CNAE "
    _oSQL:_sQuery += "    ,UPPER(CC3.CC3_DESC) AS DESC_CNAE "
    _oSQL:_sQuery += "    ,A1_TABELA AS TABELA "
    _oSQL:_sQuery += "    ,SUBSTRING(A1_ULTCOM, 7, 2) + '/' + SUBSTRING(A1_ULTCOM, 5, 2) + '/' + SUBSTRING(A1_ULTCOM, 1, 4) AS ULTIMA_COMPRA "
    _oSQL:_sQuery += "    ,A1_VACANAL AS CANAL "
    _oSQL:_sQuery += "    ,ZX518.ZX5_18DESC AS DESC_CANAL "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN A1_VABARAP = 0 THEN 'NAO POSSUI' "
    _oSQL:_sQuery += " 		    WHEN A1_VABARAP = 1 THEN 'BASE NOTA' "
    _oSQL:_sQuery += " 		    WHEN A1_VABARAP = 2 THEN 'BASE MERCADORIA' "
    _oSQL:_sQuery += " 		    WHEN A1_VABARAP = 3 THEN 'TOTAL NF - ST' "
    _oSQL:_sQuery += " 	    END AS BASE_RAPEL "
    _oSQL:_sQuery += " FROM " + RetSqlName("SA1")  + " SA1 "
    _oSQL:_sQuery += " LEFT JOIN " + RetSqlName("SX5")  + " SX5 " 
    _oSQL:_sQuery += " 	ON X5_TABELA = 'T3' "
    _oSQL:_sQuery += " 		AND X5_CHAVE = A1_CODSEG "
    _oSQL:_sQuery += " LEFT JOIN " + RetSqlName("CC3")  + " CC3 "
    _oSQL:_sQuery += " 	ON CC3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND CC3.CC3_COD = A1_CNAE "
    _oSQL:_sQuery += " LEFT JOIN " + RetSqlName("SA3")  + " SA3 "
    _oSQL:_sQuery += " 	ON SA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA3.A3_COD = SA1.A1_VEND "
    _oSQL:_sQuery += " LEFT JOIN " + RetSqlName("ZX5")  + " ZX518 "
    _oSQL:_sQuery += " 	ON ZX518.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ZX518.ZX5_TABELA = '18' "
    _oSQL:_sQuery += " 		AND ZX518.ZX5_CHAVE = A1_VACANAL "
    _oSQL:_sQuery += " WHERE SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SA1.A1_COD BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
    If mv_par03 == 2
        _oSQL:_sQuery += " AND A1_MSBLQL = 2 "
    EndIf
    If mv_par03 == 3
        _oSQL:_sQuery += " AND A1_MSBLQL = 1 "
    EndIf, SA1.A1_COD 
    _oSQL:_sQuery += " ORDER BY SA1.A1_NOME, SA1.A1_COD "

	_oSQL:Log ()
	
	_oSQL:Qry2Xls ()
	
Return
// --------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Cliente de      ", "C", 6, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Cliente até  	", "C", 6, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Status      	", "N", 1, 0,  "",  "   ", {"Ambos", "Ativos","Inativos"},              ""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
