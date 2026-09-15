insert overwrite table dw_xlyun.ods_xlyun_transfer_heartbeat_record_download_log_d_inc partition(ds='${date}')
select
    extdata["@event_name"]                            as event_name
    , extdata["@event_time"]                          as event_time
    , extdata["@user_id"]                             as user_id
    , extdata["@distinct_id"]                         as distinct_id
    , extdata["@ip"]                                  as ip
    , extdata["@dt"]                                  as dt
    , extdata["@server_time"]                         as server_time
    , extdata["@type"]                                as type
    , extdata["service_id"]                           as service_id
    , extdata["service_version"]                      as service_version
    , extdata["product_id"]                           as product_id
    , extdata["product_version"]                      as product_version
    , extdata["peer_id"]                              as peer_id
    , extdata["stat_status"]                          as stat_status
    , extdata["NetWorkType"]                          as network_type
    , extdata["VipType"]                              as vip_type
    , extdata["TaskStartTime"]                        as task_start_time
    , extdata["RecordSeq"]                            as record_seq
    , cast(extdata["Duration"] as bigint)             as duration
    , extdata["OSVersion"]                            as os_version
    , extdata["TraceId"]                              as traceid
    , extdata["TaskType"]                             as task_type
    , extdata["TaskPurpose"]                          as task_purpose
    , extdata["HasPlay"]                              as has_play
    , extdata["HubGcid"]                              as hub_gcid
    , extdata["HashInfo"]                             as hash_info
    , extdata["AppSeqId"]                             as app_seq_id
    , cast(extdata["PhubBytes"] as bigint)            as phub_bytes
    , cast(extdata["PcdnPeerBytes"] as bigint)        as pcdn_peer_bytes
    , cast(extdata["DcdnDownloadBytes"] as bigint)    as dcdn_download_bytes
    , cast(extdata["ServerBytes"] as bigint)          as server_bytes
    , cast(extdata["OriginBytes3D"] as bigint)        as origin_bytes3d
    , cast(extdata["OriginBytesXL"] as bigint)        as origin_bytes_xl
    , extdata["ResourceBytes"]                        as resource_bytes
    , cast(extdata["RecvBytes"] as bigint)            as recv_bytes
    , cast(extdata["AllTaskRecvBytes"] as bigint)     as all_task_recv_bytes
    , ''                                              as content
    , now()                                           as etl_time
    , extdata["NatType"]                              as nat_type
    , extdata
    , extdata["InitialCfgStrategyName"]               as initial_cfg_strategy_name
    , extdata["TaskCfgStrategyName"]                  as task_cfg_strategy_name
from (
    select
        content
        , from_json(content, 'map<string,string>') as extdata
    from
        dw_xlyun.pre_xlyun_transfer_log_t_30733_event_h_inc
    where
        ds = '${date}'
        and get_json_object(content,'$.@event_name') in ('4660', '10015')
) as t
;

-- create table dw_xlyun.ods_xlyun_transfer_heartbeat_record_download_log_d_inc (
--     event_name                string comment '事件名'
--     , event_time              string comment '生成当前上报记录时的本地时间戳，UTC时间'
--     , user_id                 string comment '用户id'
--     , distinct_id             string comment '访客 ID'
--     , ip                      string comment '设备的 IP 地址'
--     , dt                      string comment ''
--     , server_time             string comment ''
--     , type                    string comment '数据的类型'
--     , service_id              string comment '客户端id，用于区分产品名称'
--     , service_version         string comment '客户端版本'
--     , product_id              string comment '传输库id'
--     , product_version         string comment '传输库版本'
--     , peer_id                 string comment '节点id'
--     , stat_status             string comment '上报状态，0：任务开始；1：心跳；2：任务结束'
--     , network_type            string comment '网络类型, 0：断网，1：手机网络，2：2G，3：3G，4：4G，5：5G，9：wifi，10：有线，11：未知'
--     , vip_type                string comment '会员类型，'
--     , task_start_time         string comment '任务开始时间，UTC时间，ms'
--     , record_seq              string comment '任务维度的序号，任务开始为0，每上报一次累加1'
--     , duration                bigint comment '周期时长，单位：s'
--     , os_version              string comment '系统'
--     , traceid                 string comment '行为id'
--     , task_type               string comment '任务类型(p2sp, emule, bt_main, bt_child, magnet，hls)'
--     , task_purpose            string comment '行为类型；download：下载，fetch：取回，vod：播放;下载为主：下载/取回 （不管播多少都下完）   播放为主：播放（播多少下多少）'
--     , has_play                string comment '是否有实际播放请求'
--     , hub_gcid                string comment 'HUB gcid，查询服务端返回的gcid'
--     , hash_info	             string comment '区分不同BT子任务：infohash_fileindex；其他任务类型为空'
--     , app_seq_id              string comment '客户端传下来的任务id，用于合并分片'
--     , phub_bytes              bigint comment '周期内从phub下载的字节数，单位byte'
--     , pcdn_peer_bytes         bigint comment '周期内从pcdn下载的字节数，单位byte'
--     , dcdn_download_bytes     bigint comment '周期内从dcdn下载的字节数，单位byte'
--     , server_bytes            bigint comment '周期内从server镜像下载的字节数，单位byte'
--     , origin_bytes3d          bigint comment '周期内从三方原始链接下载的字节数，单位byte'
--     , origin_bytes_xl         bigint comment '周期内从迅雷原始链接下载的字节数，例如云盘url，单位byte'
--     , resource_bytes          string comment '周期内从不同类型节点下载的字节数，单位byte'
--     , recv_bytes              bigint comment '周期内总的下载字节数，单位byte'
--     , all_task_recv_bytes     bigint comment '周期内全局所有任务总的下载字节数，单位byte'
--     , content                 string comment '【弃用】拓展字段，请使用extdata字段'
--     , etl_time                string comment '跑数时间'

-- ) COMMENT 'ODS-传输库-5im心跳上报-下行-日志明细'
-- PARTITIONED BY (
--   `ds` string COMMENT '日期分区'
-- )
-- stored as parquet;

-- alter table dw_xlyun.ods_xlyun_transfer_heartbeat_record_download_log_d_inc add columns(
--     nat_type  string comment 'NAT类型'
--     , extdata   map<string,string> comment '扩展字段，包含完整json字段'
-- );

--20260720新增上报
-- alter table dw_xlyun.ods_xlyun_transfer_heartbeat_record_download_log_d_inc add columns(
--      initial_cfg_strategy_name string comment '下载库启动时获取到的配置文件策略名称'
--      , task_cfg_strategy_name   string comment '任务开始下载时看到的配置文件策略名称'
-- );