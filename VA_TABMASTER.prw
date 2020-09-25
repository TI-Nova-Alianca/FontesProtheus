// Programa...: VA_TABMASTER
// Autor......: Catia Cardoso
// Data.......: 03/11/2016
// Descricao..: Gera tabela 990 - com o custo dos produtos
//
// ------------------------------------------------------------------------------------
//
// Historico de alteracoes:
// 24/01/2017 - alteracao no conceito - nao vai mais ser usado o valor marjorado e sim o valor do custo.
// 04/07/2019 - Catia  - tirado o tratamento do campo B1 _ SITUACA

#include "rwmake.ch"
#include "topconn.ch"

User Function VA_TABMASTER
	local i	:= 0
	
	if ! 'CATIA' $ alltrim(upper(cusername)) .and. ! 'ADMIN' $ alltrim(upper(cusername))
		msgalert ('Olá, pelo jeito você não é a Catia, portanto não deve continuar. Pare executar programas dos outros.', procname ())
		return
	endif
	
	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	u_logId ()
	
	_lRet = U_MsgNoYes ("Confirma geração tabela 990 - custo ?")
	if _lRet = .F.
		return
	endif
	
	// limpa tabela anterior
	_sSQL := ""
	_sSQL += " DELETE DA1010"
	_sSQL += "  WHERE DA1_CODTAB = '990'"
	
	if TCSQLExec (_sSQL) < 0
        u_showmemo(_sSQL)
        return
    endif 
	
	// busca produtos a gerar na tabela master - tira terceiros, inativos e itens da loja
	_sQuery := ""
	_sQuery += " SELECT SB1.B1_COD, SB1.B1_CUSTD"
  	_sQuery += "   FROM SB1010 AS SB1"
  	_sQuery += "   INNER JOIN ZX5010 AS ZX5"
	_sQuery += "   	ON (ZX5.ZX5_TABELA = '39'"
	_sQuery += "   		AND ZX5.ZX5_39COD = SB1.B1_CODLIN)"
 	_sQuery += "  WHERE SB1.D_E_L_E_T_ = ''"
   	_sQuery += "    AND SB1.B1_TIPO    = 'PA'"
   	_sQuery += "    AND SB1.B1_COD     < '8000'"
   	_sQuery += "    AND SB1.B1_GRUPO  != '1006'"
	_sQuery += " ORDER BY SB1.B1_DESC" 
	_aProdutos := U_Qry2Array(_sQuery)
			
	if len(_aProdutos) > 0
		
		for i = 1 to len(_aProdutos)   		   
			//_wmargem = 35   /// usar a maior margem para alinhar o desconto
			Reclock("DA1",.T.)
				da1->da1_filial	:= xFilial('DA1')
				da1->da1_codtab	:= '990'
				da1->da1_item 	:= strzero(i,4)
				da1->da1_codpro	:= _aProdutos[i,1]
				da1->da1_prcven	:= _aProdutos[i,2]
				da1->da1_ativo	:= "1"
			MsUnlock()
		next
	endif		 

Return