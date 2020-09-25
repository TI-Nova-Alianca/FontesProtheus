User Function Lan010()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

SetPrvt("_CALIAS,CONTA,")

* Programa..: LAN010.PRX
* Autor.....: Fernando
* Data......: 10:30am Fev 16,1999
* Nota......: Informa Contas D‚bito Folha de Pagamento
                 
_cAlias :=Alias()
DbselectArea("SRZ")

Conta :=space(15)      

IF  left (SRZ->RZ_CC, 5) >= "50111" .AND. left (SRZ->RZ_CC, 5) <= "50121"  // adm/coml
   Conta := '403010103001'
ELSEIF  left (SRZ->RZ_CC, 5) >= "50131" .AND. left (SRZ->RZ_CC, 5) <= "50132"  // indl
   Conta := '701010203001'
ELSEIF  left (SRZ->RZ_CC, 5) >= "50231" .AND. left (SRZ->RZ_CC, 5) <= "50241"  // livramento
   Conta := '701010203001'
ENDIF

DbselectArea(_cAlias)
Return(Conta)
