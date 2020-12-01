#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
//preencha o parâmetro MV_PERCAPD com os percentuais de Tributados no Mercado Interno, 
//Não tributados no Mercado Interno e Exportação, respectivamente.
//apos o usuario preencher ele soma os tres para verificar se está com 100% se não estiver não deixa gravar no parametro.
User Function AL_PERCAPD()
	_TribMerInt    := 0
	_NaoTribMerInt := 0
	_Exportacao    := 0
	  
	@ 000, 000 TO 250, 250 DIALOG oDlg TITLE  ""
	
	@ 006, 020 Say "% Tributados no Mercado Interno"
	@ 016, 020 GET _TribMerInt   Picture "999.99"  SIZE 040, 11
	
	@ 036, 020 Say "% Não tributados no Mercado Interno"
	@ 046, 020 GET _NaoTribMerInt  Picture "999.99"  SIZE 040, 11
	
	@ 066, 020 Say "% Exportação"
	@ 076, 020 GET _Exportacao  Picture "999.99"  SIZE 040, 11
	
	@ 100, 30 BMPBUTTON TYPE 1 ACTION Processa({||_gravapar(_TribMerInt,_NaoTribMerInt,_Exportacao)})  
	
	@ 100, 80 BMPBUTTON TYPE 2 ACTION Close(oDlg)
	ACTIVATE DIALOG oDlg CENTERED          
return                                                                                                                     

//-------------------------------------------------------------------------------------------------------------------------

Static Function _gravapar(_TribMerInt,_NaoTribMerInt,_Exportacao)
	_soma:= _TribMerInt    +_NaoTribMerInt + _Exportacao   
	_montaStr := alltrim(STR(_TribMerInt ))    + "," +alltrim(STR(_NaoTribMerInt)) +","+ alltrim(STR(_Exportacao)) 
	_imp := .f.
	if _soma == 100
		msgalert("Os valores foram gravados com sucesso!")
		PutMV("MV_PERCAPD", _montaStr)                                                               
	    _imp := .t.
	else
		msgalert("Os Valores informados não fecham 100%, por isso essa informação não será gravada.")
	endif
	if _imp
		Close(oDlg)
	endif
Return

