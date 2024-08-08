set @iud="";
delete from nova_cell0.instance_system_metadata where instance_uuid=@iud;
delete from nova_cell0.instance_metadata where instance_uuid=@iud;
delete from nova_cell0.instance_info_caches where instance_uuid=@iud;
delete from nova_cell0.instance_extra where instance_uuid=@iud;
delete from nova_cell0.instances where uuid=@iud;
