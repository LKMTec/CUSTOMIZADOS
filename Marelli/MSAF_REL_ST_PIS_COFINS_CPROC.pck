create or replace package MSAF_REL_ST_PIS_COFINS_CPROC is

  -- Autor   : Fabio Freitas
  -- Created : 27/02/2013
  -- Purpose : Relatório de Conferência PIS/COFINS ST
  -- Parametros : Empresa, Estabelecimento, Data Inicio, Data Fim

  /* VARIÁVEIS DE CONTROLE DE CABEÇALHO DE RELATÓRIO */

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
                     pdt_final     date) return integer;

end MSAF_REL_ST_PIS_COFINS_CPROC;
/
create or replace package body MSAF_REL_ST_PIS_COFINS_CPROC is

  mcod_estab   estabelecimento.cod_estab%TYPE;
  mcod_empresa empresa.cod_empresa%TYPE;
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

  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'Antes de gerar o relatório, verifique se o DATA MART está equalizado. '  , 'varchar2'  , 'text'  , 'N', null   , null) ;

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório PIS/COFINS - ST';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'V1R1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório PIS/COFINS - ST';
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
                     pdt_final     date) RETURN INTEGER IS

     -- analitico
     CURSOR cur_1 IS
        select d.cod_empresa,
               d.razao_social,
               e.cod_estab,
               e.cgc      cnpj_estab,
               e.nome_fantasia,
               b.razao_social   razao_cliente,
               b.cpf_cgc        cnpj_cliente,
               b.insc_estadual  ie_cliente,
               a.data_fiscal,
               f.data_emissao,
               a.num_docfis,
               a.serie_docfis,
               g.cod_cfo,
               decode(a.movto_e_s, '9', 'SAIDA', 'ENTRADA') movto_e_s,
               decode(a.norm_dev, '1', 'NORMAL', 'DEVOLUCAO') norm_dev,
               b.cod_municipio,
               b.cidade,
               h.cod_estado,
               j.cod_nbm,
               i.cod_produto,
               i.descricao                                  descr_produto,
               a.vlr_contab_item,
               a.vlr_base_pis_st,
               a.vlr_base_cofins_st,
               a.vlr_pis_st,
               a.vlr_cofins_st,
               a.vlr_aliq_pis_st,
               a.vlr_aliq_cofins_st
        from   x08_itens_merc a,
               x04_pessoa_fis_jur b,
               x2005_tipo_docto   c,
               empresa            d,
               estabelecimento    e,
               x07_docto_fiscal   f,
               x2012_cod_fiscal   g,
               estado             h,
               x2013_produto      i,
               x2043_cod_nbm      j
        where  a.ident_fis_jur    = b.ident_fis_jur
        and    a.ident_docto      = c.ident_docto
        and    a.cod_empresa      = d.cod_empresa
        and    a.cod_empresa      = e.cod_empresa
        and    a.cod_estab        = e.cod_estab
        and    a.cod_empresa      = f.cod_empresa
        and    a.cod_estab        = f.cod_estab
        and    a.data_fiscal      = f.data_fiscal
        and    a.movto_e_s        = f.movto_e_s
        and    a.norm_dev         = f.norm_dev
        and    a.ident_docto      = f.ident_docto
        and    a.ident_fis_jur    = f.ident_fis_jur
        and    a.num_docfis       = f.num_docfis
        and    a.serie_docfis     = f.serie_docfis
        and    a.sub_serie_docfis = f.sub_serie_docfis
        and    a.ident_cfo        = g.ident_cfo(+)
        and    b.ident_estado     = h.ident_estado(+)
        and    a.ident_produto    = i.ident_produto
        and    a.ident_nbm        = j.ident_nbm(+)
        and    a.data_fiscal      between pdt_inicio and pdt_final
        and    a.cod_empresa      = pcd_empr
        and    a.cod_estab        = decode(pcd_estab, 'TODOS', a.cod_estab, pcd_estab)
        and    a.movto_e_s        = '9'
        and   (a.vlr_pis_st       > 0
        or     a.vlr_cofins_st    > 0)
        and    j.cod_nbm in ('40091100','40091210','40091290','40092110','40092190','40092210','40092290','40093100','40093210','40093290','40094100','40094210','40094290','40161010','68132000','68138110','68138190','68138910','68138990','70071100','70072100','70091000','83012000','83023000','84073390','84073490','84082010','84082020','84082030','84082090','84089090','84099111','84099112','84099113','84099114','84099115','84099116','84099117','84099118','84099120','84099130','84099140','84099190','84099912','84099914','84099915','84099917','84099921','84099929','84099930','84099941','84099949','84099951','84099959','84099961','84099969','84099971','84099979','84099991','84099999','84122110','84122190','84123110','84133010','84133020','84133030','84133090','84136019','84148019','84148021','84148022','84149039','84152010','84152090','84212300','84213100','84291110','84291190','84291910','84291990','84292010','84292090','84293000','84294000','84295111','84295119','84295121','84295129','84295191','84295192','84295199','84295211','84295212','84295219','84295220','84295290','84295900','84311010','84311090','84312011','84312019','84312090','84313110','84313190','84313900','84314100','84314200','84314310','84314390','84314910','84314921','84314922','84314923','84314929','84324100','84324200','84328000','84329000','84332010','84332090','84333000','84334000','84335100','84335200','84335300','84335911','84335919','84335990','84339090','84811000','84812090','84818092','84831011','84831019','84831020','84831030','84831040','84831050','84831090','84832000','84833010','84833021','84833029','84833090','84834010','84834090','84835010','84835090','84836011','84836019','85011019','85052010','85052090','85071010','85071090','85111000','85112010','85112090','85113010','85113020','85114000','85115010','85115090','85118010','85118020','85118030','85118090','85119000','85122011','85122019','85122021','85122022','85122023','85122029','85123000','85124010','85124020','85129000','85272100','85272900','85391010','85391090','85443000','87011000','87012000','87013000','87019100','87019200','87019300','87019410','87019490','87019510','87019590','87022000','87023000','87024010','87024090','87029000','87031000','87032100','87032210','87032290','87032310','87032390','87032410','87032490','87033110','87033190','87033210','87033290','87033310','87033390','87034000','87035000','87036000','87037000','87038000','87039000','87041010','87041090','87042110','87042120','87042130','87042190','87042210','87042220','87042230','87042290','87042310','87042320','87042330','87042390','87043110','87043120','87043130','87043190','87043210','87043220','87043230','87043290','87049000','87051010','87051090','87052000','87053000','87054000','87059010','87059090','87060020','87060090','87071000','87079010','87079090','87081000','87082100','87082911','87082912','87082913','87082914','87082919','87082991','87082992','87082993','87082994','87082995','87082999','87083011','87083019','87083090','87084011','87084019','87084080','87084090','87085011','87085012','87085019','87085080','87085091','87085099','87087010','87087090','87088000','87089100','87089200','87089300','87089411','87089412','87089413','87089481','87089482','87089483','87089490','87089510','87089521','87089522','87089529','87089910','87089990','90292010','90299010',
                              '90303321','90318040','90328921','90328922','90328923','90328924','90328925','90328929','91040000','94012000','4016999003','4016999005', '7320100001','8413919001','8481809901','8481809902','8536509001','8702100002','8706001001')
        union all
        select d.cod_empresa,
               d.razao_social,
               e.cod_estab,
               e.cgc      cnpj_estab,
               e.nome_fantasia,
               b.razao_social   razao_cliente,
               b.cpf_cgc        cnpj_cliente,
               b.insc_estadual  ie_cliente,
               a.data_fiscal,
               f.data_emissao,
               a.num_docfis,
               a.serie_docfis,
               g.cod_cfo,
               decode(a.movto_e_s, '9', 'SAIDA', 'ENTRADA') movto_e_s,
               decode(a.norm_dev, '1', 'NORMAL', 'DEVOLUCAO') norm_dev,
               b.cod_municipio,
               b.cidade,
               h.cod_estado,
               j.cod_nbm,
               i.cod_produto,
               i.descricao                                  descr_produto,
               a.vlr_contab_item*-1          vlr_contab_item,
               a.vlr_base_pis_st*-1          vlr_base_pis_st,
               a.vlr_base_cofins_st*-1          vlr_base_cofins_st,
               a.vlr_pis_st*-1            vlr_pis_st,
               a.vlr_cofins_st*-1          vlr_cofins_st,
               a.vlr_aliq_pis_st*-1          vlr_aliq_pis_st,
               a.vlr_aliq_cofins_st*-1                      vlr_aliq_cofins_st
        from   x08_itens_merc a,
               x04_pessoa_fis_jur b,
               x2005_tipo_docto   c,
               empresa            d,
               estabelecimento    e,
               x07_docto_fiscal   f,
               x2012_cod_fiscal   g,
               estado             h,
               x2013_produto      i,
               x2043_cod_nbm      j
        where  a.ident_fis_jur    = b.ident_fis_jur
        and    a.ident_docto      = c.ident_docto
        and    a.cod_empresa      = d.cod_empresa
        and    a.cod_empresa      = e.cod_empresa
        and    a.cod_estab        = e.cod_estab
        and    a.cod_empresa      = f.cod_empresa
        and    a.cod_estab        = f.cod_estab
        and    a.data_fiscal      = f.data_fiscal
        and    a.movto_e_s        = f.movto_e_s
        and    a.norm_dev         = f.norm_dev
        and    a.ident_docto      = f.ident_docto
        and    a.ident_fis_jur    = f.ident_fis_jur
        and    a.num_docfis       = f.num_docfis
        and    a.serie_docfis     = f.serie_docfis
        and    a.sub_serie_docfis = f.sub_serie_docfis
        and    a.ident_cfo        = g.ident_cfo(+)
        and    b.ident_estado     = h.ident_estado(+)
        and    a.ident_produto    = i.ident_produto
        and    a.ident_nbm        = j.ident_nbm(+)
        and    a.data_fiscal      between pdt_inicio and pdt_final
        and    a.cod_empresa      = pcd_empr
        and    a.cod_estab        = decode(pcd_estab, 'TODOS', a.cod_estab, pcd_estab)
        and    a.movto_e_s        <> '9'
        and    g.cod_cfo          in ('2203', '2204','1201','1202','1203','1204','1208','1209','1410','1411','2201','2202','2203','2204','2208','2209','2410','2411')
        and   (a.vlr_pis_st       > 0
        or     a.vlr_cofins_st    > 0)
        and    j.cod_nbm in ('40091100','40091210','40091290','40092110','40092190','40092210','40092290','40093100','40093210','40093290','40094100','40094210','40094290','40161010','68132000','68138110','68138190','68138910','68138990','70071100','70072100','70091000','83012000','83023000','84073390','84073490','84082010','84082020','84082030','84082090','84089090','84099111','84099112','84099113','84099114','84099115','84099116','84099117','84099118','84099120','84099130','84099140','84099190','84099912','84099914','84099915','84099917','84099921','84099929','84099930','84099941','84099949','84099951','84099959','84099961','84099969','84099971','84099979','84099991','84099999','84122110','84122190','84123110','84133010','84133020','84133030','84133090','84136019','84148019','84148021','84148022','84149039','84152010','84152090','84212300','84213100','84291110','84291190','84291910','84291990','84292010','84292090','84293000','84294000','84295111','84295119','84295121','84295129','84295191','84295192','84295199','84295211','84295212','84295219','84295220','84295290','84295900','84311010','84311090','84312011','84312019','84312090','84313110','84313190','84313900','84314100','84314200','84314310','84314390','84314910','84314921','84314922','84314923','84314929','84324100','84324200','84328000','84329000','84332010','84332090','84333000','84334000','84335100','84335200','84335300','84335911','84335919','84335990','84339090','84811000','84812090','84818092','84831011','84831019','84831020','84831030','84831040','84831050','84831090','84832000','84833010','84833021','84833029','84833090','84834010','84834090','84835010','84835090','84836011','84836019','85011019','85052010','85052090','85071010','85071090','85111000','85112010','85112090','85113010','85113020','85114000','85115010','85115090','85118010','85118020','85118030','85118090','85119000','85122011','85122019','85122021','85122022','85122023','85122029','85123000','85124010','85124020','85129000','85272100','85272900','85391010','85391090','85443000','87011000','87012000','87013000','87019100','87019200','87019300','87019410','87019490','87019510','87019590','87022000','87023000','87024010','87024090','87029000','87031000','87032100','87032210','87032290','87032310','87032390','87032410','87032490','87033110','87033190','87033210','87033290','87033310','87033390','87034000','87035000','87036000','87037000','87038000','87039000','87041010','87041090','87042110','87042120','87042130','87042190','87042210','87042220','87042230','87042290','87042310','87042320','87042330','87042390','87043110','87043120','87043130','87043190','87043210','87043220','87043230','87043290','87049000','87051010','87051090','87052000','87053000','87054000','87059010','87059090','87060020','87060090','87071000','87079010','87079090','87081000','87082100','87082911','87082912','87082913','87082914','87082919','87082991','87082992','87082993','87082994','87082995','87082999','87083011','87083019','87083090','87084011','87084019','87084080','87084090','87085011','87085012','87085019','87085080','87085091','87085099','87087010','87087090','87088000','87089100','87089200','87089300','87089411','87089412','87089413','87089481','87089482','87089483','87089490','87089510','87089521','87089522','87089529','87089910','87089990','90292010','90299010',
                              '90303321','90318040','90328921','90328922','90328923','90328924','90328925','90328929','91040000','94012000','4016999003','4016999005', '7320100001','8413919001','8481809901','8481809902','8536509001','8702100002','8706001001');

    /* Variáveis de Trabalho */
    mproc_id         INTEGER;
    mLinha           VARCHAR2(4000);
    v_linha          number(5)  := 0;
    vTab             varchar2(1):= chr(9);
    v_reg            varchar2(7000);
    v_reg_c          varchar2(7000);

  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('MSAF_REL_ST_PIS_COFINS_CPROC', 48, 150);
    LIB_PROC.add_tipo(mproc_id, 2, 'ARQUIVO_PIS_COFINS_ST', 2);

    BEGIN

         v_reg_c := 'COD_EMPRESA'          ||vTab||
                    'RAZAO_SOCIAL'         ||vTab||
                    'COD_ESTAB'            ||vTab||
                    'CNPJ_ESTAB'           ||vTab||
                    'NOME_FANTASIA'        ||vTab||
                    'RAZAO_CLIENTE'        ||vTab||
                    'CNPJ_CLIENTE'         ||vTab||
                    'IE_CLIENTE'           ||vTab||
                    'DATA_FISCAL'          ||vTab||
                    'DATA_EMISSAO'         ||vTab||
                    'NUM_DOCFIS'           ||vTab||
                    'SERIE_DOCFIS'         ||vTab||
                    'COD_CFO'              ||vTab||
                    'MOVTO_E_S'            ||vTab||
                    'NORM_DEV'             ||vTab||
                    'COD_MUNICIPIO'        ||vTab||
                    'CIDADE'               ||vTab||
                    'COD_ESTADO'           ||vTab||
                    'COD_NBM'              ||vTab||
                    'COD_PRODUTO'          ||vTab||
                    'DESCR_PRODUTO'        ||vTab||
                    'VLR_CONTAB_ITEM'      ||vTab||
                    'VLR_BASE_PIS_ST'      ||vTab||
                    'VLR_BASE_COFINS_ST'   ||vTab||
                    'VLR_PIS_ST'           ||vTab||
                    'VLR_COFINS_ST'        ||vTab||
                    'VLR_ALIQ_PIS_ST'      ||vTab||
                    'VLR_ALIQ_COFINS_ST';

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 2);

          LIB_PROC.add(mLinha, null, null, 2);

      FOR mreg IN cur_1 LOOP


           v_reg := mreg.COD_EMPRESA          ||vTab||
                    mreg.RAZAO_SOCIAL         ||vTab||
                    mreg.COD_ESTAB            ||vTab||
                    mreg.CNPJ_ESTAB           ||vTab||
                    mreg.NOME_FANTASIA        ||vTab||
                    mreg.RAZAO_CLIENTE        ||vTab||
                    mreg.CNPJ_CLIENTE         ||vTab||
                    mreg.IE_CLIENTE           ||vTab||
                    mreg.DATA_FISCAL          ||vTab||
                    mreg.DATA_EMISSAO         ||vTab||
                    mreg.NUM_DOCFIS           ||vTab||
                    mreg.SERIE_DOCFIS         ||vTab||
                    mreg.COD_CFO              ||vTab||
                    mreg.MOVTO_E_S            ||vTab||
                    mreg.NORM_DEV             ||vTab||
                    mreg.COD_MUNICIPIO        ||vTab||
                    mreg.CIDADE               ||vTab||
                    mreg.COD_ESTADO           ||vTab||
                    mreg.COD_NBM              ||vTab||
                    mreg.COD_PRODUTO          ||vTab||
                    mreg.DESCR_PRODUTO        ||vTab||
                    replace(ltrim(to_char(nvl(mreg.VLR_CONTAB_ITEM,0), '9999999999d00')), '.', ',')      ||vTab||
                    replace(ltrim(to_char(nvl(mreg.VLR_BASE_PIS_ST,0), '9999999999d00')), '.', ',')      ||vTab||
                    replace(ltrim(to_char(nvl(mreg.VLR_BASE_COFINS_ST,0), '9999999999d00')), '.', ',')   ||vTab||
                    replace(ltrim(to_char(nvl(mreg.VLR_PIS_ST,0), '9999999999d00')), '.', ',')           ||vTab||
                    replace(ltrim(to_char(nvl(mreg.VLR_COFINS_ST,0), '9999999999d00')), '.', ',')        ||vTab||
                    replace(mreg.VLR_ALIQ_PIS_ST,'.', ',')                                               ||vTab||
                    replace(mreg.VLR_ALIQ_COFINS_ST,'.', ',');

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 1);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;

          v_reg := null;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 2);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 2);

    END;

    if v_linha = 0 then
     lib_proc.add_log('Não há registros para processar de acordo com os critérios selecionados. ', 1);
    else
     lib_proc.add_log('Geração do relatório concluída! Foram gravados '||v_linha||' registros ', 1);
    end if;

     LIB_PROC.CLOSE();

    RETURN mproc_id;
  END;

END MSAF_REL_ST_PIS_COFINS_CPROC;
/
