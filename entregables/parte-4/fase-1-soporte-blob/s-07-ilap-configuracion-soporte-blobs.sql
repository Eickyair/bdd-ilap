-- Autor       : erick
-- Fecha        : 2026-06-07
-- Descripcion  : Configura el soporte BLOB en un nodo de iLap mediante
--                 objetos DIRECTORY y la funcion fx_carga_blob.

whenever sqlerror exit rollback;

prompt Creando objetos para leer datos BLOB
prompt Creando directorios

create or replace directory proyecto_final_facturas_dir
as '/tmp/bdd/proyecto-final/imagenes/facturas';

create or replace directory proyecto_final_laptops_dir
as '/tmp/bdd/proyecto-final/imagenes/laptops';

prompt Creando funcion para leer datos BLOB

create or replace function fx_carga_blob(
    v_directory_name in varchar2,
    v_src_file_name  in varchar2
) return blob is
    v_src_blob      bfile := bfilename(v_directory_name, v_src_file_name);
    v_dest_blob     blob := empty_blob();
    v_src_offset    number := 1;
    v_dest_offset   number := 1;
    v_src_blob_size number;
begin
    if dbms_lob.fileexists(v_src_blob) = 0 then
        raise_application_error(-20001, v_src_file_name || ' El archivo no existe ');
    end if;

    if dbms_lob.isopen(v_src_blob) = 0 then
        dbms_lob.open(v_src_blob, dbms_lob.lob_readonly);
    end if;

    v_src_blob_size := dbms_lob.getlength(v_src_blob);

    dbms_lob.createtemporary(
        lob_loc => v_dest_blob,
        cache   => true,
        dur     => dbms_lob.call
    );

    dbms_lob.loadblobfromfile(
        dest_lob    => v_dest_blob,
        src_bfile   => v_src_blob,
        amount      => dbms_lob.getlength(v_src_blob),
        dest_offset => v_dest_offset,
        src_offset  => v_src_offset
    );

    dbms_lob.close(v_src_blob);

    if v_src_blob_size <> dbms_lob.getlength(v_dest_blob) then
        raise_application_error(
            -20104,
            'Invalid blob size. Expected: ' || v_src_blob_size || ', actual: ' || dbms_lob.getlength(v_dest_blob)
        );
    end if;

    return v_dest_blob;
end;
/
show errors

prompt Soporte BLOB configurado correctamente.