#INCLUDE "rwmake.ch" 
// AxCadastro para os cr�ditos de PIS

User Function AL_CREDPIS()
                                                 

Private cVldAlt := ".T."  // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Private cVldExc := ".T."  // Validacao para permitir a exclusao.  Pode-se utilizar ExecBlock.
Private cString := "ZZY"                                        


dbSelectArea("ZZY")
dbSetOrder(1)

AxCadastro(cString,"Cr�ditos de PIS",cVldAlt,cVldExc)

Return