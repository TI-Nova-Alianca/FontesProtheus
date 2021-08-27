#Include "RwMake.ch" 
#Include "Protheus.ch"
#Include "TBICoNN.ch"
#Include "FILEIo.ch"
#Include "TopCoNN.ch"
#Include 'Totvs.ch'
#Include "Ap5Mail.ch"
#INCLUDE "COLORS.CH"

//Criado por Maurício C. Dani - TOTVS RS - 15/01/2021
// Função que retorna a entidade no caso de atualização manual junto ao sefaz
// 25/08/2021 - Robert - Incluida clausula IE=m0_insc

User Function FBTRS103()
	Local cQuery 	:= ""
	Local cLn    	:= CHR(13) + CHR(10)
	Local cEntManif := ""

	cQuery := " SELECT ID_ENT AS ENTIDADE FROM SPED001 " + cLn
	cQuery += " WHERE D_E_L_E_T_ != '*'" + cLn
	cQuery +=   " AND CNPJ = '" + AllTrim(SM0->M0_CGC) + "' " + cLn
	cQuery +=   " AND IE   = '" + AllTrim(SM0->M0_INSC) + "' " + cLn

	If Select("TRSPED") <> 0
		TRSPED->(dbCloseArea())
	EndIf

	TCQUERY cQuery NEW ALIAS TRSPED

	dbSelectArea("TRSPED")
	TRSPED->(dbGotop())
	cEntManif := AllTrim(TRSPED->ENTIDADE)
	
Return cEntManif
