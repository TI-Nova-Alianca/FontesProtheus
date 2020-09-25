// Programa:  OM200AD2
// Autor:     Robert Koch
// Data:      18/06/2018
// Descricao: Mostra Volumes na Montagem de Carga
//
// Historico de alteracoes:

#Include "Protheus.ch"
#DEFINE CARGA_ENABLE 1
#DEFINE CARGA_COD 2
#DEFINE CARGA_DESC 3
#DEFINE CARGA_PESO 4
#DEFINE CARGA_VALOR 5
#DEFINE CARGA_VOLUM 6
#DEFINE CARGA_QTDLIB 7
#DEFINE CARGA_PTOENT 8
#DEFINE CARGA_VEIC 9
#DEFINE CARGA_MOTOR 10
#DEFINE CARGA_AJUD1 11
#DEFINE CARGA_AJUD2 12
#DEFINE CARGA_AJUD3 13
#DEFINE CARGA_AJUD3 14
#DEFINE CARGA_TRANSP 23
#DEFINE CARGA_USER 24
User Function OM200AD2()
Local aRetCarga := {}
Local oCargas := PARAMIXB[1]
Local aArrayCarga := PARAMIXB[2]
Local aHeaders := PARAMIXB[3]
Local bLine := PARAMIXB[4]
Local oEnable := PARAMIXB[5]
Local oDisable := PARAMIXB[6]

//msgAlert (procname())

aAdd(aArrayCarga[Len(aArrayCarga)],cUserName) // oonteudo do campo incluido
aAdd(aHeaders,"Usuario") // cabecalho
bLine:={ ||{Iif(aArrayCarga[oCargas:nAT,CARGA_ENABLE],oEnable,oDisable),;
aArrayCarga[oCargas:nAT,CARGA_COD],;
aArrayCarga[oCargas:nAT,CARGA_DESC],;
aArrayCarga[oCargas:nAT,CARGA_PESO],;
aArrayCarga[oCargas:nAT,CARGA_VALOR],;
aArrayCarga[oCargas:nAT,CARGA_VOLUM],;
aArrayCarga[oCargas:nAT,CARGA_QTDLIB],;
aArrayCarga[oCargas:nAT,CARGA_PTOENT],;
aArrayCarga[oCargas:nAT,CARGA_TRANSP],;
aArrayCarga[oCargas:nAT,CARGA_VEIC],;
aArrayCarga[oCargas:nAT,CARGA_MOTOR],;
aArrayCarga[oCargas:nAT,CARGA_AJUD1],;
aArrayCarga[oCargas:nAT,CARGA_AJUD2],;
aArrayCarga[oCargas:nAT,CARGA_AJUD3],;
aArrayCarga[oCargas:nAT,CARGA_USER]}} // Campo incluido na ultima posicao.

AAdd(aRetCarga, aArrayCarga)
AAdd(aRetCarga, aHeaders)
AAdd(aRetCarga, bLine)
Return( aRetCarga )

