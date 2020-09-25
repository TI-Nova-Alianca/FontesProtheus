#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function Ml_cnpj()

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � ML_CNPJ  � Autor �    Jeferson Rech      � Data � Out/2004 ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Rel. Gera CNPJ Ficticios                                   ���
�������������������������������������������������������������������������Ĵ��
���Retorno   �                                                            ���
�������������������������������������������������������������������������Ĵ��
���Utilizacao� Especifico para Clientes Microsiga                         ���
�������������������������������������������������������������������������Ĵ��
���   Data   � Programador   �Manutencao Efetuada                         ���
�������������������������������������������������������������������������Ĵ��
���          �               �                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

//��������������������������������������������������������������Ŀ
//� Variaveis utilizadas para parametros                         �
//� mv_par01     // Numero Inicial                               �
//� mv_par02     // Ate qual Numero                              �
//����������������������������������������������������������������
//��������������������������������������������������������������Ŀ
//� Variaveis obrigatorias dos programas de relatorio            �
//����������������������������������������������������������������
cString :="SA1"
cDesc1  :="Este programa tem como objetivo, imprimir relatorio de"
cDesc2  :="CNPJ Ficticios."
cDesc3  :=""
tamanho :="P"
aReturn :={ "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
aLinha  :={ }
nLastKey:=0
cPerg   :="MLCNPJ"
titulo  :=""
wnrel   :="ML_CNPJ"
nTipo   :=0

//��������������������������������������������������������������Ŀ
//� Pergunta no SX1                                              �
//����������������������������������������������������������������
ValidPerg()
Pergunte(cPerg,.F.)

//��������������������������������������������������������������Ŀ
//� Envia controle para a funcao SETPRINT                        �
//����������������������������������������������������������������
wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)

If nLastKey == 27
	Return
Endif
SetDefault(aReturn,cString)
If nLastKey == 27
	Return
Endif

RptStatus({|| RptDetail()})
Return

Static Function RptDetail()
local _iy	:= 0
local _ix	:= 0
local _x	:= 0
local i		:= 0
local j		:= 0
//�����������������������������������������������������������Ŀ
//� Inicializa  regua de impressao                            �
//�������������������������������������������������������������
SetRegua(LastRec())

//�������������������������������������������������������������������Ŀ
//� Inicializa os codigos de caracter Comprimido/Normal da impressora �
//���������������������������������������������������������������������
nTipo := IIF(aReturn[4]==1,15,18)
li    := 80
m_pag := 1

//����������������������������������������������������������Ŀ
//� Cria o cabecalho.                                        �
//������������������������������������������������������������
cabec1 := "CNPJ Validos "
cabec2 := ""
*****       XXXX      X.XXX.XXX.XXX,XX    XXX.XXX.XXX,XX    XXX.XXX.XXX,XX    XXX.XXX.XXX,XX   XXX.XXX.XXX,XX   XXX.XXX.XXX,XX   XXX.XXX.XXX,XX
*****                1         2         3         4         5         6         7         8         9         0         1         2         3
*****      0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012

If mv_par02 > 9999
	MsgInfo("Numero Final Invalido ... Informar Valor inferior a 9999.","Verifique!!!")
	Return
Endif

//��������������������������������������������������������������Ŀ
//� Verifica Dados                                               �
//����������������������������������������������������������������
_aCNPJ  := {}
For _ix := mv_par01 to mv_par02
	IncRegua()              // Termometro de Impressao
	_xMESTRE := StrZero(_ix,12,0)
	For _iy  := 1 to 99
		_xCNPJ := _xMESTRE+StrZero(_iy,2,0)
		If E_CGC(_xCNPJ,.F.)
			Aadd(_aCNPJ, _xCNPJ)
			Exit
		Endif
	Next _iy
Next _ix

_nCol    := 0
_aCol    := Array(3)
_aCol[1] := 0
_aCol[2] := 31
_aCol[3] := 62

For _x := 1 To Len(_aCNPJ)
	_nCol += 1
	If li>60
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif
	@ li, _aCol[_nCol] PSAY _aCNPJ[_x] Picture"@R 99.999.999/9999-99"
	If _nCol >= 3
		_nCol := 0
                li    += 1
	Endif
Next

If li!=80
	Roda(0,"",Tamanho)
Endif

Set Device To Screen

If aReturn[5]==1
	Set Printer TO
	dbcommitAll()
	ourspool(wnrel)
Endif

MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

// Fim

//��������������������������������������������������������������Ŀ
//� Cria Perguntas no SX1                                        �
//����������������������������������������������������������������
Static Function ValidPerg()
local i	:= 0
local j	:= 0
cAlias  := Alias()
aRegs   := {}

// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
AADD(aRegs,{cPerg,"01","Numero Inicial      ?","","","mv_ch1","N",12,0,0,"G","","mv_par01","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"02","Numero Final        ?","","","mv_ch2","N",12,0,0,"G","","mv_par02","","","","","","","","","","","","","","",""})

DbSelectArea("SX1")
DbSetOrder(1)
For i:=1 to Len(aRegs)
	If !DbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j<=Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next
DbSelectArea(cAlias)
Return
