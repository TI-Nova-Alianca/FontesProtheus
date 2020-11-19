#include "rwmake.ch"

User Function lj010new()

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ LJ010NEW ³ Autor ³     Jeferson Rech     ³ Data ³ Jan/2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Valida Mudanca de Pastas - Venda a Balcao - Sigaloja       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Alianca                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Local _aArea    := GetArea()
Local _nNewOpt  := Paramixb[2]   // Pasta Clicada
Local _cCondPg  := Paramixb[6]   // Condicao de Pagto
Local _xFim     := chr(13)+chr(10)
Local _xRet     := .T.
//Local _xUSUARIO := ""
//Local _xCONT    := 7
//Local _xFLAG    := ""

/*
Do While _xCONT < Len(cUsuario)
	_xFLAG := Substr(cUsuario,_xCONT,1)
	If Empty(_xFLAG)
		_xUSUARIO := Substr(cUsuario,7,(_xCONT-7))
		Exit
	Endif
	_xCONT := _xCONT + 1
Enddo

// Se for usuario Nota Fiscal e cliente padrao (000000) bloqueia
If Alltrim(Upper(_xUSUARIO)) == "NOTA" .And. SA1->A1_COD == "000000"
	MsgInfo("Nao e possivel gerar Notas Fiscais com o Cliente Generico. Verifique.","Atencao!!!")
	_xRet      := .F.
Endif

// Se for usuario Cupom Fiscal e cliente diferente (000000) bloqueia
If Alltrim(Upper(_xUSUARIO)) == "CUPOM" .And. SA1->A1_COD <> "000000"
	MsgInfo("Nao e possivel gerar Cupom Fiscal com o Cliente diferente de Generico. Verifique.","Atencao!!!")
	_xRet      := .F.
Endif
*/
//// Se for usuario Cupom Fiscal e cliente diferente (000000) bloqueia
//If Alltrim(Upper(_xUSUARIO)) == "SHOPPING" .And. SA1->A1_COD <> "000000"
//	MsgInfo("Nao e possivel gerar Cupom Fiscal com o Cliente diferente de Generico. Verifique.","Atencao!!!")
//	_xRet      := .F.
//Endif

// Quando passar para a 3 pasta
If (_nNewOpt == 3)
	_xCLIENTE := SA1->A1_COD
	_xLOJA    := SA1->A1_LOJA
	_xRISCO   := SA1->A1_RISCO
	_xNOME    := SA1->A1_NOME
	If _xRISCO == "E" .And. _cCondPg <> "095"   // A vista (um dia)
		MsgInfo ("Cliente: "+_xCLIENTE+" "+_xLOJA+" "+Trim(_xNOME)+_xFim+;
		"Possui Risco financeiro "+_xRISCO+", portando nao sera permitido digitacao de Venda."+_xFim+;
		"Solucao: "+"Contate Setor Financeiro.";
		,"Atencao!!! Cliente Risco "+_xRISCO )
		_xRet      := .F.
	Endif
Endif

RestArea(_aArea)
Return(_xRet)


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Funcao que Retorna a Condicao de Pagto - Venda a Balcao      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
User Function _CondPagto()

Local _cAlias    := Alias()
Local _xRet      := "097"  // Padrao Cupom
//Local _xUSUARIO  := ""
//Local _xCONT     := 7
//Local _xFLAG     := ""
/*
Do While _xCONT < Len(cUsuario)
	_xFLAG := Substr(cUsuario,_xCONT,1)
	If Empty(_xFLAG)
		_xUSUARIO := Substr(cUsuario,7,(_xCONT-7))
		Exit
	Endif
	_xCONT := _xCONT + 1
Enddo

// Se for usuario Nota Fiscal
If Alltrim(Upper(_xUSUARIO)) == "NOTA"
	_xRet  := "095"      // Padrao N.Fiscal
Endif
*/

DbSelectArea(_cAlias)
Return(_xRet)
