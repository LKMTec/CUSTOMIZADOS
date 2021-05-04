create or replace package MSAF_AJ_CONTA_MM_CPROC is

  -- Autor   : Paulo Ribeiro
  -- Created : 16/07/2019
  -- Purpose : Pacote desenvolvido para correcao de conta contabil
  -- Parametros : Empresa, Estabelecimento, Data Inicio, Data Fim, Tipo

  /* VARIÁVEIS DE CONTROLE DE CABECALHO DA GERACAO */

  function parametros return varchar2;
  function nome return varchar2;
  function tipo return varchar2;
  function versao return varchar2;
  function descricao return varchar2;
  function modulo return varchar2;
  function classificacao return varchar2;

  function executar (pcd_empr      varchar2,
                     pcd_estab     varchar2,
                     pdt_inicio    date,
                     pdt_final     date,
                     p_tipo        varchar2) return integer;

end MSAF_AJ_CONTA_MM_CPROC;
/
create or replace package body MSAF_AJ_CONTA_MM_CPROC is

  mcod_empresa empresa.cod_empresa%TYPE;
  mcod_estab   estabelecimento.cod_estab%TYPE;
  musuario     usuario_estab.cod_usuario%TYPE;


  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    mcod_estab   := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');
    musuario     := LIB_PARAMETROS.Recuperar('USUARIO');

    LIB_PROC.add_param(pstr, 'Empresa', 'Varchar2',
                             'Combobox', 'S', NULL, NULL,
                             'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e where cod_empresa = '''||mcod_empresa||''' order by 1' );

   LIB_PROC.add_param(pstr, 'Estabelecimento'  , 'Varchar2', 'Combobox' , 'S', 'SELECIONE A OPÇÃO', NULL,
                            'select ''TODOS'',''Todos os Estabelecimentos'' from dual union '||
                            'Select distinct cod_estab, cod_estab||'' - ''||razao_social '||
                            'from estabelecimento where cod_empresa = :1 order by 1' );

    LIB_PROC.add_param(pstr,
                       'Data Inicio ',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'dd/mm/yyyy');

    LIB_PROC.add_param(pstr,
                       'Data Final ',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'dd/mm/yyyy');
                                              
     LIB_PROC.add_param(pstr,
                       'Tipo de Ajuste',
                       'Varchar2',
                       'Radiobutton', 'S', NULL, NULL,
                       '1=Ajuste - Conta Contábil x SAFX08,'||
                       '2=Ajuste - NCM - SAFX2013 x SAFX08,'||
                       '3=Ajuste - NCM - SAFX2013 x SAFX52,'||
                       '4=Ajuste - Desc. Funcao do Bem,'||
                       '5=Ajuste - Reg.C120 - SAFX49');
                      
  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'ATENÇÃO: Após a execução do Ajuste de Conta Contábil equalizar o DATA MART. ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'ATENÇÃO: Gerar os scritps sempre em bases mensais. ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'ATENÇÃO: Após a execução ref. Ajuste-SAFX49, Importar os registros via Job Servidor. ', 'varchar2'  , 'text'  , 'N', null   , null) ;  
    RETURN pstr;
  END;

FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processo';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Ajuste - EFD-Marelli';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'V1R1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Ajuste EFD-Contribuiçoes - Marelli';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processos Customizados';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processos Customizados';
  END;

  FUNCTION Executar (pcd_empr      varchar2,
                     pcd_estab     varchar2,
                     pdt_inicio    date,
                     pdt_final     date,
                     p_tipo        varchar2) RETURN INTEGER IS

    /* Variáveis de Trabalho */
    mproc_id         INTEGER;
    vn_contador      number(5);
  
     
---Ajuste Conta Contabil
CURSOR ict_1 is
Select b.rowid,
     b.cod_empresa,
     b.cod_estab,
     b.num_item,
     b.num_docfis,
     b.data_fiscal ,
     c.cod_modelo  ,
     (case when b.cod_empresa = '003' then                           
         (SELECT  p1.ident_conta
        from x2002_plano_contas p1
        where p1.grupo_conta = '003_SAPFU'
        and p1.cod_conta = '0054150000'
        and p1.valid_conta = (select max(p2.valid_conta)
        from x2002_plano_contas p2
        where p2.grupo_conta = p1.grupo_conta
        and   p2.cod_conta = p1.cod_conta))
       when b.cod_empresa in ('004','005') then 
        (SELECT  p1.ident_conta
        from x2002_plano_contas p1
        where p1.grupo_conta = '008'
        and p1.cod_conta = '0054150000'
        and p1.valid_conta = (select max(p2.valid_conta)
        from x2002_plano_contas p2
        where p1.grupo_conta = p2.grupo_conta
        and   p1.cod_conta = p2.cod_conta)) 
        when b.cod_empresa = '026' then 
        (SELECT  p1.ident_conta
        from x2002_plano_contas p1
        where p1.grupo_conta = '026_SAP'
        and p1.cod_conta = '0054150000'
        and p1.valid_conta = (select max(p2.valid_conta)
        from x2002_plano_contas p2
        where p1.grupo_conta = p2.grupo_conta
        and   p1.cod_conta = p2.cod_conta)) 
        when b.cod_empresa = '027' then 
        (SELECT  p1.ident_conta
        from x2002_plano_contas p1
        where p1.grupo_conta = '027_SAP'
        and p1.cod_conta = '0054150000'
        and p1.valid_conta = (select max(p2.valid_conta)
        from x2002_plano_contas p2
        where p1.grupo_conta = p2.grupo_conta
        and   p1.cod_conta = p2.cod_conta))
        when b.cod_empresa = '028' then 
        (SELECT  p1.ident_conta
        from x2002_plano_contas p1
        where p1.grupo_conta = '028_SAP'
        and p1.cod_conta = '0054150000'
        and p1.valid_conta = (select max(p2.valid_conta)
        from x2002_plano_contas p2
        where p1.grupo_conta = p2.grupo_conta
        and   p1.cod_conta = p2.cod_conta))
        when b.cod_empresa = '033' then 
        (SELECT  p1.ident_conta
        from x2002_plano_contas p1
        where p1.grupo_conta = '3301'
        and p1.cod_conta = '0054150000'
        and p1.valid_conta = (select max(p2.valid_conta)
        from x2002_plano_contas p2
        where p1.grupo_conta = p2.grupo_conta
        and   p1.cod_conta = p2.cod_conta)) end) ident_correto

from  x07_docto_fiscal a,
      x08_itens_merc b,
      x2024_modelo_docto c
where a.cod_empresa = b.cod_empresa
and   a.cod_estab = b.cod_estab
and   a.data_fiscal = b.data_fiscal
and   a.ident_fis_jur = b.ident_fis_jur
and   a.norm_dev = b.norm_dev
and   a.ident_docto = b.ident_docto
and   a.movto_e_s = b.movto_e_s
and   a.num_docfis = b.num_docfis
and   a.serie_docfis = b.serie_docfis
and   a.ident_modelo = c.ident_modelo
and   c.cod_modelo in ('57','67')
and   b.ident_conta is null
and   b.cod_empresa  = pcd_empr
and   b.cod_estab = decode(pcd_estab, 'TODOS', b.cod_estab, pcd_estab)
and   b.data_fiscal between pdt_inicio and  pdt_final;

--Ajuste NCM--safx08
CURSOR ict_2 is
SELECT a.ind_produto,
       a.cod_produto,
       a.grupo_produto,
       a.ident_nbm,
       a.ident_produto,
       a.nbm_ref

FROM (select  distinct
        x2013.ind_produto
       ,x2013.cod_produto
       ,x2013.grupo_produto
       ,x08.ident_nbm
       ,(select max(p.ident_produto)
           from x2013_produto p
            where p.ind_produto = x2013.ind_produto
            and   p.cod_produto = x2013.cod_produto
            and   p.grupo_produto = x2013.grupo_produto
            and   p.valid_produto <= pdt_final) ident_produto
       ,(select t.ident_nbm
          from x2013_produto t
          where t.ident_produto = (select max(p.ident_produto)
           from x2013_produto p
            where p.ind_produto = x2013.ind_produto
            and   p.cod_produto = x2013.cod_produto
            and   p.grupo_produto = x2013.grupo_produto
            and   p.valid_produto <= pdt_final)) nbm_ref
    

from x08_itens_merc x08
    ,x2013_produto  x2013
    
where x08.ident_produto = x2013.ident_produto
and   x08.cod_empresa = pcd_empr
and   x08.cod_estab = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
and   x08.data_fiscal  between pdt_inicio and pdt_final) a
where  a.nbm_ref is null;

--Ajuste NCM--safx52
CURSOR ict_3 is
SELECT a.ind_produto,
       a.cod_produto,
       a.grupo_produto,
       a.ident_nbm,
       a.ident_produto,
       a.nbm_ref

FROM (select  distinct
        x2013.ind_produto
       ,x2013.cod_produto
       ,x2013.grupo_produto
       ,x52.ident_nbm
       ,(select max(p.ident_produto)
           from x2013_produto p
            where p.ind_produto = x2013.ind_produto
            and   p.cod_produto = x2013.cod_produto
            and   p.grupo_produto = x2013.grupo_produto
            and   p.valid_produto <= pdt_final) ident_produto
       ,(select t.ident_nbm
          from x2013_produto t
          where t.ident_produto = (select max(p.ident_produto)
           from x2013_produto p
            where p.ind_produto = x2013.ind_produto
            and   p.cod_produto = x2013.cod_produto
            and   p.grupo_produto = x2013.grupo_produto
            and   p.valid_produto <= pdt_final)) nbm_ref
    

from x52_invent_produto x52
    ,x2013_produto  x2013
    
where x52.ident_produto = x2013.ident_produto
and   x52.cod_empresa = pcd_empr
and   x52.cod_estab = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
and   x52.data_inventario = pdt_final) a
where  a.nbm_ref is null;


--Ajuste Desc do Bem
CURSOR ict_4 is
SELECT x13.cod_empresa
      ,x13.cod_estab
      ,x13.cod_bem
      ,x13.cod_inc
      ,x13.descricao
      ,x13.rowid
      
from x13_bem_ativo x13
where x13.cod_empresa = pcd_empr
and   x13.cod_estab = decode(pcd_estab, 'TODOS', x13.cod_estab, pcd_estab)
and   x13.valid_bem between pdt_inicio and pdt_final
and   x13.dsc_funcao is null
and   x13.descricao is not null;

--Ajuste Safx49
CURSOR ict_5 is
(select x08.cod_empresa
      ,x08.cod_estab
      ,x08.num_docfis
      ,x2013.ind_produto
      ,x2013.cod_produto
      ,x2007.cod_medida
      ,x04.ind_fis_jur
      ,x04.cod_fis_jur
      ,x08.num_item
      ,x49.rowid
                               

 from   x08_itens_merc x08
       ,x04_pessoa_fis_jur x04
       ,x2013_produto  x2013
       ,x2012_cod_fiscal x2012
       ,x2007_medida     x2007
       ,safx49 x49

where x08.ident_fis_jur = x04.ident_fis_jur
and   x08.ident_produto = x2013.ident_produto
and   x08.ident_cfo = x2012.ident_cfo
and   x08.ident_medida = x2007.ident_medida
and   x08.cod_empresa = x49.cod_empresa
and   x08.cod_estab = x49.cod_estab
and   x08.num_docfis = x49.num_nf
and   x08.serie_docfis = x49.serie_nf
and  lpad(x08.num_item,5,0) = lpad(x49.num_item,5,0)
and   x2012.cod_cfo between '3000' and '3999'
and   x08.cod_empresa = pcd_empr
and   x08.cod_estab = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
and   x08.data_fiscal between pdt_inicio and pdt_final);


BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('MSAF_AJ_CONTA_MM_CPROC', 48, 150);
    vn_contador := 0;

    BEGIN

  if p_tipo = '1' then

      FOR mreg IN ict_1 LOOP
         
        begin
        update x08_itens_merc x
        set x.ident_conta =   mreg.ident_correto
        where x.cod_empresa = mreg.cod_empresa
        and   x.cod_estab =   mreg.cod_estab
        and   x.data_fiscal = mreg.data_fiscal
        and   x.num_docfis =  mreg.num_docfis
        and   x.num_item =    mreg.num_item
        and   x.rowid =       mreg.rowid;
        end;
        
        
        vn_contador := vn_contador + 1;
        
        END LOOP; 
        
        lib_proc.add_log(vn_contador||' '||'registro(s) alterados(s)',1);

elsif p_tipo = '2' then 

  FOR mreg IN ict_2 LOOP
    
      begin 
        update x2013_produto x
        set x.ident_nbm = mreg.ident_nbm
         where x.ident_produto = mreg.ident_produto
         and   x.ind_produto = mreg.ind_produto
         and   x.cod_produto = mreg.cod_produto
         and   x.grupo_produto = mreg.grupo_produto;
       end;
       
       vn_contador := vn_contador + 1;
        
        END LOOP; 
        
        lib_proc.add_log(vn_contador||' '||'registro(s) alterados(s)',1);
        
elsif p_tipo = '3' then

FOR mreg IN ict_3 LOOP
   
   begin
     update x2013_produto x
     set x.ident_nbm = mreg.ident_nbm
        where x.ident_produto = mreg.ident_produto
         and   x.ind_produto = mreg.ind_produto
         and   x.cod_produto = mreg.cod_produto
         and   x.grupo_produto = mreg.grupo_produto;
       end;
       
       vn_contador := vn_contador + 1;
        
        END LOOP; 
        
        lib_proc.add_log(vn_contador||' '||'registro(s) alterados(s)',1);

elsif p_tipo = '4' then 

FOR mreg in ict_4 Loop
    
    begin 
      update x13_bem_ativo x
        set x.dsc_funcao = mreg.descricao
         where x.rowid = mreg.rowid;
         end;
         
         vn_contador := vn_contador + 1;
        
        END LOOP; 
        
        lib_proc.add_log(vn_contador||' '||'registro(s) alterados(s)',1);

elsif p_tipo = '5' then 

FOR mreg in ict_5 loop
    
    begin
      update safx49 x
      set x.ind_fis_jur = mreg.ind_fis_jur,
          x.cod_fis_jur = mreg.cod_fis_jur,
          x.ind_produto = mreg.ind_produto,
          x.cod_produto = mreg.cod_produto,
          x.cod_medida = mreg.cod_medida,
          x.cod_medida_com = mreg.cod_medida
          
      where x.rowid = mreg.rowid;
          end;
          
       vn_contador := vn_contador + 1;
       
       END LOOP;
       
       lib_proc.add_log(vn_contador||' '||'registro(s) alterados(s)',1);   
         
END IF;


    END;

     LIB_PROC.CLOSE();
     commit;

    RETURN mproc_id;
  END;

END MSAF_AJ_CONTA_MM_CPROC;
/
