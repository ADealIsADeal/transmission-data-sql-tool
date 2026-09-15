insert overwrite table dw_xlyun.ods_xlyun_transfer_heartbeat_record_upload_log_d_inc partition(ds='${date}')
select
    extdata["@event_name"]                      as event_name
    , extdata["@event_time"]                    as event_time
    , extdata["@user_id"]                       as user_id
    , extdata["@distinct_id"]                   as distinct_id
    , extdata["@ip"]                            as ip
    , extdata["@dt"]                            as dt
    , extdata["@server_time"]                   as server_time
    , extdata["@type"]                          as type
    , extdata["service_id"]                     as service_id
    , extdata["service_version"]                as service_version
    , extdata["product_id"]                     as product_id
    , extdata["product_version"]                as product_version
    , extdata["peer_id"]                        as peer_id
    , extdata["stat_status"]                    as stat_status
    , extdata["NetWorkType"]                    as network_type
    , extdata["VipType"]                        as vip_type
    , extdata["AppStartTime"]                   as app_start_time
    , extdata["RecordSeq"]                      as record_seq
    , cast(extdata["Duration"] as bigint)                       as duration
    , cast(extdata["UploadBytes"] as bigint)                    as upload_bytes
    , cast(extdata["DcacheTaskUploadBytes"] as bigint)          as dcache_task_upload_bytes
    , cast(extdata["DcacheFileUploadBytes"] as bigint)          as dcache_file_upload_bytes
    , cast(extdata["VodTaskUploadBytes"] as bigint)             as vod_task_upload_bytes
    , cast(extdata["VodFileUploadBytes"] as bigint)             as vod_file_upload_bytes
    , cast(extdata["OtherTaskUploadBytes"] as bigint)           as other_task_upload_bytes
    , cast(extdata["OtherFileUploadBytes"] as bigint)           as other_file_upload_bytes
    , extdata["UploadTo"]                                       as upload_to
    , ''                                                        as content
    , now()                                                     as etl_time
    , cast(extdata["UploadDuration"] as bigint)                 as upload_duration
    , extdata["NatType"]                                        as nat_type
    , extdata
    , extdata["InitialCfgStrategyName"]                         as initial_cfg_strategy_name
    , ''                                                        as task_cfg_strategy_name
from (
    select
        content
        , from_json(content, 'map<string,string>') as extdata
    from
        dw_xlyun.pre_xlyun_transfer_log_t_30733_event_h_inc
    where
        ds = '${date}'
        and get_json_object(content,'$.@event_name') in ('4686', '10016')
) as t
;


-- create table dw_xlyun.ods_xlyun_transfer_heartbeat_record_upload_log_d_inc (
--       event_name                    string comment '事件名'
--     , event_time                    string comment '生成当前上报记录时的本地时间戳，UTC时间'
--     , user_id                       string comment '用户id'
--     , distinct_id                   string comment '访客 ID'
--     , ip                            string comment '设备的 IP 地址'
--     , dt                            string comment ''
--     , server_time                   string comment ''
--     , type                          string comment '数据的类型'
--     , service_id                    string comment '客户端id，用于区分产品名称'
--     , service_version               string comment '客户端版本'
--     , product_id                    string comment '传输库id'
--     , product_version               string comment '传输库版本'
--     , peer_id                       string comment '节点id'
--     , stat_status                   string comment '上报状态，0：任务开始；1：心跳；2：任务结束'
--     , network_type                  string comment '网络类型, 0：断网，1：手机网络，2：2G，3：3G，4：4G，5：5G，9：wifi，10：有线，11：未知'
--     , vip_type                      string comment '会员类型，'
--     , app_start_time                string comment '任务开始时间，UTC时间，ms'
--     , record_seq                    string comment '任务维度的序号，任务开始为0，每上报一次累加1'
--     , duration                      bigint comment '周期时长，单位：s'
--     , upload_bytes                  bigint comment '周期内上传的总字节数，单位byte'
--     , dcache_task_upload_bytes      bigint comment '周期内从dcache上传的字节数（正在下载，顺便上传），单位byte'
--     , dcache_file_upload_bytes      bigint comment '周期内从dcache上传的字节数（纯上传），单位byte'
--     , vod_task_upload_bytes         bigint comment '周期内从点播上传的字节数（正在下载，顺便上传），单位byte'
--     , vod_file_upload_bytes         bigint comment '周期内从点播文件上传的字节数（纯上传），单位byte'
--     , other_task_upload_bytes       bigint comment '周期内从其他文件（bt/p2sp下载/取回等）上传的字节数（正在下载，顺便上传），单位byte'
--     , other_file_upload_bytes       bigint comment '周期内从其他文件（bt/p2sp下载/取回等）上传的字节数（纯上传），单位byte'
--     , upload_to                     string comment '上传到哪里'
--     , content                       string comment '【弃用】拓展字段，请使用extdata字段'
--     , etl_time                      string comment '跑数时间'
-- ) COMMENT 'ODS-传输库-5im心跳上报-上行-日志明细'
-- PARTITIONED BY (
--   `ds` string COMMENT '日期分区'
-- )
-- stored as parquet;

--20260528 新增
-- alter table dw_xlyun.ods_xlyun_transfer_heartbeat_record_upload_log_d_inc add columns (
--     upload_duration bigint comment '周期内实际上传时长,单位：s'
-- );


-- alter table dw_xlyun.ods_xlyun_transfer_heartbeat_record_upload_log_d_inc add columns(
--     nat_type                string comment 'NAT类型'
--     , extdata   map<string,string> comment '扩展字段，包含完整json字段'
-- );

--20260720新增上报
-- alter table dw_xlyun.ods_xlyun_transfer_heartbeat_record_upload_log_d_inc add columns(
--     initial_cfg_strategy_name   string comment '下载库启动时获取到的配置文件策略名称'
--     , task_cfg_strategy_name   string comment '任务开始下载时看到的配置文件策略名称'
-- )