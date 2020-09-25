// Programa..: MATR930A
// Autor.....: Cláudia Lionço
// Data......: 14/05/2020
// Descrição.: O ponto de entrada MATR930A permite a alteração ou complemento das observações do 
//			   Livro Regime de Processamento de Dados.
//
// Historico de alteracoes:
// 14/05/2020 - Claudia - O programa irá mudar a mensagem quando imprimir dados de cupom sob NF
//
// --------------------------------------------------------------------------------------------
//
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MATR930A
	Local aOBSERV := ParamIXB[1]  //Array contendo as observações geradas no sistema
	local _oSQL   := NIL
	Local _aDados := {}
	Local _x	  := 0
	Local _texto  := ""
                                                            
	//aOBSERV[1][1] => Observação a ser impressa                                                            
	//aOBSERV[1][2] => .T.  - Imprime no Relatório   e .F. - Não Imprime no Relatório 
	
	If Len(aOBSERV) == 1  
		nAchou := At( "CF/SERIE:",aOBSERV[1][1])
		
		If nAchou > 0
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := " SELECT F2_DOC, F2_SERIE "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") 
			_oSQL:_sQuery += " WHERE F2_NFCUPOM = '" + sf2->f2_serie + sf2->f2_doc + "'"
			_oSQL:_sQuery += " AND F2_EMISSAO = '" + DTOS(sf2->f2_emissao) + "'"
			_aDados := aclone (_oSQL:Qry2Array (.t.,.t.))
			
			_texto :=  "NFCe: "
			For _x:=2 to len(_aDados)
				_texto += _aDados[_x,1] + " " +_aDados[_x,2] + " "
			Next
			
			aOBSERV[1][1] := _texto  
			aOBSERV[1][2] := .t. 
		EndIf                
	Endif
Return aOBSERV