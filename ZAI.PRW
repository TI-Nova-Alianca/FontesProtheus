//  Programa...: ZAI
//  Autor......: Cláudia Lionço
//  Data.......: 18/01/2022
//  Descricao..: Cadastro de IGPM e INPC
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Cadastro de IGPM e INPC
// #PalavasChave      #IGPM #tabela_IGPM #INPC #tabela_INPC
// #TabelasPrincipais #ZAI 
// #Modulos   		  #FAT
//
//  Historico de alteracoes:
//  07/05/2021 - Claudia - Criado programa baseado no VA_TABIGPM, acrescentando INPC 
//                         e novas funcionalidades. GPI: 11468
//
// ----------------------------------------------------------------------------------------
#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function ZAI()
	Private aRotina   := {}  
	Private cCadastro := "Cadastro de IGPM e INPC"

    AADD(aRotina, {"Importar INPC", "U_ZAIIMP('1')"    , 0, 4})
    AADD(aRotina, {"Importar IGPM", "U_ZAIIMP('2')"    , 0, 4})
                    
    AxCadastro("ZAI",cCadastro,".T.","U_ZAITOK()",aRotina)

Return
//
// --------------------------------------------------------------------------------------
// Importação de tabela via .CSV
//
User Function ZAIIMP(_sTipo)
	Local _aDados 	:= {}
	Local _i 		:= 0
    Local _x        := 0

    // Modelo da tabela: separados por ; e separação de decimais por .
    // Ano, JAN, FEC, MAR, ABR, MAI, JUN, JUL, AGO, SET, OUT, NOV, DEZ
    // 2021;0.27;0.82;0.86;0.38;0.96;0.6;1.02;0.88;1.2;1.16;0.84;0.73;10.16
    // 2020;0.19;0.17;0.18;-0.23;-0.25;0.3;0.44;0.36;0.87;0.89;0.95;1.46;5.45
    // 2019;0.36;0.54;0.77;0.6;0.15;0.01;0.1;0.12;-0.05;0.04;0.54;1.22;4.48
 
    If _sTipo == '1'
        u_help("Inclua a planilha INPC.CSV no local C:\Temp\ para a correta importação!")
	    _aDados = U_LeCSV ('C:\Temp\INPC.csv', ';')
    else
        u_help("Inclua a planilha IGPM.CSV no local C:\Temp\ para a correta importação!")
	    _aDados = U_LeCSV ('C:\Temp\IGPM.csv', ';')
    EndIf

	for _i := 1 to len (_aDados)
		_sAno  := _aDados[_i, 1]    
         
        For _x:=1 to 13
            If _x <> 1
                _sData:= _RetornaData(_sAno, _x)
                _dData := STOD(_sData) 
                dbSelectArea("ZAI")
                dbSetOrder(1) // ZAI_FILIAL+ZAI_DATA  

                If _sTipo == '1'
                    If dbSeek(xFilial("ZAI") + _sData) 
                        Reclock("ZAI",.F.)
                            ZAI->ZAI_INPC := val(_aDados[_i, _x])
                        ZAI->(MsUnlock())
                    Else
                        Reclock("ZAI",.T.)
                            ZAI->ZAI_FILIAL := '  '
                            ZAI->ZAI_DATA   := _dData
                            ZAI->ZAI_IGPM   := 0
                            ZAI->ZAI_INPC   := val(_aDados[_i, _x])
                        ZAI->(MsUnlock())
                    EndIf
                else
                    If dbSeek(xFilial("ZAI") + _sData) 
                        Reclock("ZAI",.F.)
                            ZAI->ZAI_IGPM := val(_aDados[_i, _x])
                        ZAI->(MsUnlock())
                    Else
                        Reclock("ZAI",.T.)
                            ZAI->ZAI_FILIAL := '  '
                            ZAI->ZAI_DATA   := _dData
                            ZAI->ZAI_INPC   := 0
                            ZAI->ZAI_IGPM   := val(_aDados[_i, _x])
                        ZAI->(MsUnlock())
                    EndIf
                EndIf
            EndIf
        Next
	Next
	u_help("Dados importados!")
Return
//
// --------------------------------------------------------------------------
// Retorna data do %
Static Function _RetornaData(_sAno,_nMes)
    Do Case
        Case _nMes == 2 // janeiro
            _sData := alltrim(_sAno) + '0101' 

        Case _nMes == 3 // fevereiro
            _sData := alltrim(_sAno) + '0201' 

        Case _nMes == 4 // março
            _sData := alltrim(_sAno) + '0301' 

        Case _nMes == 5 // abril
            _sData := alltrim(_sAno) + '0401' 

        Case _nMes == 6 // maio
            _sData := alltrim(_sAno) + '0501' 

        Case _nMes == 7 // junho
            _sData := alltrim(_sAno) + '0601' 

        Case _nMes == 8 // julho
            _sData := alltrim(_sAno) + '0701' 

        Case _nMes == 9 // agosto
            _sData := alltrim(_sAno) + '0801' 

        Case _nMes == 10 // setembro
            _sData := alltrim(_sAno) + '0901' 

        Case _nMes == 11 // outubro
            _sData := alltrim(_sAno) + '1001' 

        Case _nMes == 12 // novembro
            _sData := alltrim(_sAno) + '1101' 

        Case _nMes == 13 // dezembro
            _sData := alltrim(_sAno) + '1201' 

    EndCase 
Return _sData
//
// --------------------------------------------------------------------------
// Valida 'Tudo OK'
user function ZAITOK()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	
	if substr( dtos(M->ZAI_DATA) ,7 ,2) != '01' 
		msgalert ("Deve ser usada a data do primeiro dia util do mês.")
		_lRet = .F.
	endif
		
	if _lRet
		ZAI -> (dbsetorder (1))
		if ZAI -> (dbseek (xfilial ("ZAI") + dtos(M->ZAI_DATA), .F.))
			msgalert ("Valor IGPM/INPC já cadastrado para esta data! ")
			_lRet = .F.
		endif
	endif
		
	U_ML_SRArea (_aAreaAnt)
return _lRet
