CREATE OR REPLACE PACKAGE LKM_APTRIB_CPAR IS

  --Parametro Standard
  FUNCTION PARAMETROS RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION NOME RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION MODULO RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION VERSAO RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION DESCRICAO RETURN VARCHAR2;
  
  --Parametro Standard
  FUNCTION TIPO RETURN VARCHAR2;

END LKM_APTRIB_CPAR;
/
CREATE OR REPLACE PACKAGE BODY LKM_APTRIB_CPAR IS

  MCOD_EMPRESA EMPRESA.COD_EMPRESA%TYPE;
  MCOD_USUARIO USUARIO_ESTAB.COD_USUARIO%TYPE;

  FUNCTION PARAMETROS RETURN VARCHAR2 IS
    PSTR VARCHAR2(9000);
  BEGIN
  
    MCOD_EMPRESA := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    MCOD_USUARIO := LIB_PARAMETROS.RECUPERAR('USUARIO');
  
    PSTR := 'VENCIMENTO|1.1 Dia de vencimento|S|  Dia do vencimento|Textlistbox|Varchar2|||'
               ||' select cast(conteudo as varchar(20)) conteudo , cast(valor as varchar(50)) valor from TABLE(LKM_APTRIB_CPROC.FN_VENCIMENTO);';
  
    PSTR := PSTR ||
            'DEPARA_EMP|De/Para do COD_EMPRESA|N| 1 De/Para Codigo da Empresa|Textlistbox|Varchar2|||'
             ||' select Distinct a.cod_empresa codigo,a.cod_empresa descricao from empresa a order by 1;';
  
    PSTR := PSTR || 'DEPARA_ESTAB|De/Para do COD_ESTAB|N| 2 De/Para Codigo do Estabelecimento|Textlistbox|Varchar2||| '
                ||'select distinct a.cod_empresa||''-''||a.cod_estab codigo,a.cod_empresa||''-''||a.razao_social descricao '
                ||' from estabelecimento a order by 2;';
  
    PSTR := PSTR ||
            'COD_DARF_IR|Codigos de DARF para IR|NULL| 3 Filtro DARF para IR|Checklistbox|Varchar2|S||'
              ||' select distinct cod_darf codigo, descricao from X2019_COD_DARF a order by 1;';
  
    PSTR := PSTR ||
            'COD_DARF_PCC|Codigos de DARF para PCC|NULL| 4 Filtro DARF para PCC|Checklistbox|Varchar2|S||'
             ||' select distinct cod_darf codigo, descricao from X2019_COD_DARF a order by 1;';
  
    PSTR := PSTR ||
            'COD_PAGTO_INSS|Codigos de Pagamento para INSS|NULL| 5 Filtro Codigo de Pagamento para INSS|TextListBox|Varchar2|||' ||
            'select distinct cod_pagto codigo, max(dsc_pagto) descricao ' ||
            'from irt_cod_pg_inss GROUP BY cod_pagto order by cod_pagto;';
  
    PSTR := PSTR ||
            'COD_DARF_IRPJ_CSLL|Codigos de DARF para IR|NULL| 6 Codigo DARF para IRPJ e CSLL|Checklistbox|Varchar2|S||' ||
            ' select CAST(B.tipo AS VARCHAR(20)), cod_darf , cod_darf ||''-''||descricao descricao from X2019_COD_DARF ' ||
            ' ,TABLE(LKM_APTRIB_CPROC.FN_TIPO) B' ||
            ' order by cod_darf,B.tipo;';
  
    PSTR := PSTR ||
            'COD_CONTA_DEB|Cadastro de Conta Debito/Fornecedor|S| 7 - Conta Contabil - Debito|Textlistbox|Varchar2||| '
            ||' select cast(a.tipo as varchar(10))||''-''|| b.cod_empresa ||''-''|| c.cod_estab  as IMP_EMP_ESTAB, cast(a.tipo as varchar(10)) as IMP from  TABLE(LKM_APTRIB_CPROC.FN_TIPO_IMP) a, empresa b, estabelecimento c where b.cod_empresa=c.cod_empresa order by b.cod_empresa,c.cod_estab, a.tipo;';
    
    PSTR := PSTR ||
            'COD_CONTA_CRE|Cadastro de Conta Credito/Fornecedor|S| 8 - Conta Contabil - Credito|Textlistbox|Varchar2||| '
            ||' select cast(a.tipo as varchar(10))||''-''|| b.cod_empresa ||''-''|| c.cod_estab  as IMP_EMP_ESTAB, cast(a.tipo as varchar(10)) as IMP from  TABLE(LKM_APTRIB_CPROC.FN_TIPO_IMP) a, empresa b, estabelecimento c where b.cod_empresa=c.cod_empresa order by b.cod_empresa,c.cod_estab, a.tipo;';
    
    PSTR := PSTR ||
            'COD_CUSTO|Cadastro de Centro Custo|S| 9 - Centro de Custo|Textlistbox|Varchar2||| '
            ||' select a.cod_empresa||'' - ''||b.tipo, a.razao_social from empresa a , TABLE(LKM_APTRIB_CPROC.FN_TIPO_IMP) b order by a.cod_empresa,b.tipo ;';
   
   PSTR := PSTR ||
            'COD_LUCRO|Cadastro de Centro Lucro|S|10 - Centro de Lucro|Textlistbox|Varchar2||| '
            ||' select a.cod_empresa||'' - ''||b.tipo, a.razao_social from empresa a , TABLE(LKM_APTRIB_CPROC.FN_TIPO_IMP) b order by a.cod_empresa,b.tipo ;';
  
  
   
    PSTR := PSTR ||
            'COD_CUSTOMER|CUSTOMER|S|11 - CUSTOMER|Textlistbox|Varchar2||| '
            ||'select a.IMP_EMP_ESTAB, codigo, cod_empresa,cod_estab  from TABLE(LKM_APTRIB_CPROC.FN_COGPGTO) a order by a.cod_empresa, a.cod_estab, a.codigo;';
    
    
    PSTR := PSTR ||
            'COD_VENDOR_NO|VENDOR_NO|S|12 - VENDOR_NO|Textlistbox|Varchar2||| '
            ||'select a.IMP_EMP_ESTAB, codigo, cod_empresa,cod_estab  from TABLE(LKM_APTRIB_CPROC.FN_COGPGTO) a order by a.cod_empresa, a.cod_estab, a.codigo;';
  
    
    RETURN PSTR;
  END PARAMETROS;

  
  FUNCTION NOME RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN 'AP-TRIB';
  END NOME;

 
  FUNCTION MODULO RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN 'Processos Customizados';
  END MODULO;

  FUNCTION VERSAO RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN 'V1R1.0';
  END VERSAO;
   
  FUNCTION DESCRICAO RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN NULL;
  END DESCRICAO;
  
 
  FUNCTION TIPO RETURN VARCHAR2 IS
  --Parametro Standard
  BEGIN
    RETURN 'AP-TRIB';
  END;

END LKM_APTRIB_CPAR;
/
