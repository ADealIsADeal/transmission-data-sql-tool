------------------------------------------------------------
--  FILE:    dwd_xlyun_transfer_pc_log_h_inc.sql
--  DESC:    传输库 PC 端日志 DWD（小时增量，字段下沉解析，不去重）
--  CHANGE:  20260701 时效切换小时；extdata 业务字段在 DWD 解析
--           PC service_name/service_version 取 extdata partnerid/partnerversion
--           20260914 guid 改取 extdata[' client_peerid']，兼容 extdata['client_peerid']
--  PARAM:   ds='${date}', hour='${hour}'
------------------------------------------------------------

insert overwrite table dw_xlyun.dwd_xlyun_transfer_pc_log_h_inc partition (ds = '${date}', hour = '${hour}', platform = 'pc')
select
    raw.serverinfo as server_info
    , raw.cmdid
    , raw.appid
    , raw.product_version
    , raw.extdata['partnerid'] as service_name
    , coalesce(raw.extdata['partnervesion'], raw.extdata['partnerversion']) as service_version
    , raw.peerid as peer_id
    -- 原始 guid 为空；设备 id 在 extdata，主键带前导空格，少数行无空格
    , coalesce(raw.extdata[' client_peerid'], raw.extdata['client_peerid']) as guid
    , raw.userid as user_id
    , raw.extdata_head
    , raw.processid as process_id
    , raw.eventid as event_id
    , raw.attribute1
    , raw.attribute2
    , raw.cost1
    , raw.cost2
    , raw.cost3
    , raw.cost4
    , raw.extdata_record
    , raw.ts
    , raw.extdata
    , raw.extdata['parentid'] as parent_id
    , raw.extdata['traceid'] as seqid
    , xl_inet_ntoa(xl_htonl(cast(raw.serverinfo[1] as bigint))) as ip
    , if(raw.extdata['result'] = '99%' or raw.extdata['result'] = 'auto_restart', 'restart', raw.extdata['result']) as final_result
    , raw.extdata['type'] as mode
    , xl_urldecode(raw.extdata['filename']) as file_name
    , regexp_extract(raw.extdata['filename'], '\\\.([^.]*)$', 1) as file_suffix
    , cast(raw.extdata['filesize'] as bigint) as file_size
    , cast(raw.extdata['dcdnpeernum'] as bigint) as cdn_res_count
    , cast(raw.extdata['offlinenum'] as bigint) as dcdn_hub_res_num
    , cast(raw.extdata['highnum'] as bigint) as high_res_count
    , raw.extdata['errorcode'] as error_code
    , raw.eventid as task_type
    , if(length(raw.extdata['sgcid']) = 40, raw.extdata['sgcid'], null) as hub_gcid
    , if(length(raw.extdata['gcid']) = 40, raw.extdata['gcid'], null) as real_gcid
    , cast(raw.extdata['duration'] as bigint) as download_time
    , cast(raw.extdata['recvbytes'] as bigint) as recv_bytes
    , raw.extdata['viptype'] as vip_type
    , if(
        (coalesce(cast(raw.extdata['vip_acc_request'] as int), 0) >= 10 and coalesce(cast(raw.extdata['vip_acc_request'] as int), 0) <= 30)
        or (cast(raw.extdata['vip_dcdn_query'] as bigint) >= '10' and cast(raw.extdata['vip_dcdn_query'] as bigint) <= '30')
        or (cast(raw.extdata['dcdn_query_peer_result'] as bigint) in (65, 69, 70, 71))
        or (nvl(cast(raw.extdata['FileProperty'] as int), 0) > 0 and nvl(cast(raw.extdata['FileProperty'] as int), 0) <> 999)
        , '1', '0'
    ) as anti_server
    , raw.extdata['taskorigin'] as task_origin
    , xl_urldecode(xl_urldecode(raw.extdata['refurl'])) as ref_url
    , xl_urldecode(xl_urldecode(raw.extdata['fileurl'])) as file_url
    , if(raw.extdata['avgglobalspeedoftask'] > 0, raw.extdata['avgglobalspeedoftask'], null) as global_speed
    , cast(raw.extdata['downloadstrategy'] as bigint) as download_strategy
    , nvl(raw.extdata['vip_dcdn_token'], raw.extdata['vip_dcdn_token_backup']) as token
    , cast(if(
        nvl(raw.extdata['errorbytes'], 0) > nvl(raw.extdata['eraseddatasize'], 0)
        , nvl(raw.extdata['errorbytes'], 0)
        , nvl(raw.extdata['eraseddatasize'], 0)
    ) as bigint)as error_bytes
    , raw.extdata['indexextradata'] as index_extra_data
    , cast(raw.extdata['vip_vipspeed'] as bigint) as jiasu_vip_speed
    , cast(raw.extdata['vip_superspeed'] as bigint) as jiasu_super_speed
    , cast(raw.extdata['vip_smooth'] as bigint) as jiasu_smooth
    , cast(raw.extdata['vip_zerospeed'] as bigint) as jiasu_zero_speed
    , cast(raw.extdata['vip_group'] as bigint) as jiasu_group
    , cast(raw.extdata['recvbytes'] as bigint) as all_bytes
    , cast(raw.extdata['originbytes'] as bigint) as origin_bytes
    , cast(raw.extdata['p2sbytes'] as bigint) as server_bytes
    , cast(raw.extdata['phubbytes'] as bigint) as phub_bytes
    , cast(raw.extdata['phubnum'] as bigint) as phub_peer
    , cast(raw.extdata['trackerbytes'] as bigint) as tracker_bytes
    , cast(raw.extdata['trackernum'] as bigint) as tracker_peer
    , cast(raw.extdata['dcdnpeerbytes'] as bigint) as dcdn_bytes
    , cast(raw.extdata['dcdnpeernum'] as bigint) as dcdn_peer
    , cast(raw.extdata['pcdnpeerbytes'] as bigint) as pcdn_bytes
    , cast(raw.extdata['pcdnpeernum'] as bigint) as pcdn_peer
    , cast(raw.extdata['phubbonusbytes'] as bigint) as bonus_bytes
    , cast(raw.extdata['phubbonusnum'] as bigint) as bonus_peer
    , cast(raw.extdata['phubcdnpeerbytes'] as bigint) as phub_cdn_bytes
    , cast(raw.extdata['phubdcdnpeerbytes'] as bigint) as phub_dcdn_bytes
    , cast(raw.extdata['phubvcachebytes'] as bigint) as xphub_bytes
    , cast(raw.extdata['superpcdnpeerbytes'] as bigint) as super_pcdn_bytes
    , cast(raw.extdata['superpcdnpeernum'] as bigint) as super_pcdn_peer
    , if(raw.extdata['phubnum'] is null or raw.extdata['phubnum'] = 'NULL' or raw.extdata['phubnum'] = '0', 0, cast(raw.extdata['phubnum'] as bigint)) as phub_res_peer
    , if(raw.extdata['phubusednum'] is null or raw.extdata['phubusednum'] = 'NULL' or raw.extdata['phubusednum'] = '0', 0, cast(raw.extdata['phubusednum'] as bigint)) as phub_insert_peer
    , cast(raw.extdata['avgdownloadingtasknum'] as bigint) as running_task_count_avg
    , cast(raw.extdata['avgdownloadingmaintasknum'] as bigint) as running_user_task_count_avg
    , cast(raw.extdata['globalrecvbytes'] as bigint) as global_all_bytes
    , cast(raw.extdata['globalphubbytes'] as bigint) as global_p2p_bytes
    , cast(raw.extdata['globalp2sbytes'] as bigint) as global_p2s_bytes
    , cast(raw.extdata['globalphubbonusbytes'] as bigint) as global_bonus_bytes
    , cast(raw.extdata['globaldcdnpeerbytes'] as bigint) as global_dcdn_bytes
    , cast(raw.extdata['globaloriginalurlbytes'] as bigint) as global_origin_bytes
    , if(length(raw.extdata['originaletag']) > 0, raw.extdata['originaletag'], null) as etag
    , cast(raw.extdata['queryallhubcount'] as bigint) as query_all_hub_count
    , raw.extdata['queryallhubresult'] as query_all_hub_result
    , cast(str_to_map(raw.extdata['global_speedtarget'], ';', ':')['1'] as bigint) as global_speed_target_1
    , cast(str_to_map(raw.extdata['global_speedtarget'], ';', ':')['64'] as bigint) as global_speed_target_64
    , cast(raw.extdata['firstinsertpcdnpeertime'] as bigint) as first_insert_pcdn_peer_time
    , cast(raw.extdata['takemuchmemorycount'] as bigint) + cast(raw.extdata['takemorememorycount'] as bigint) as alloc_data_buffer_fail_count
    , cast(raw.extdata['globalspeedmaxinwindow'] as bigint) as global_speed_max_in_window
    , cast(raw.extdata['endingspantime'] as bigint) as ending_span_time
    , raw.extdata['isnetdiskfetchtask'] as is_netdisk_fetch_task
    , raw.extdata['firstvideomode'] as first_video_mode
    , '' as action_type
from (
    select
        serverinfo
        , cmdid
        , appid
        , product_version
        , service_name
        , service_version
        , peerid
        , guid
        , userid
        , extdata_head
        , processid
        , eventid
        , attribute1
        , attribute2
        , cost1
        , cost2
        , cost3
        , cost4
        , extdata_record
        , ts
        , if(extdata_record like '%=%', str_to_map(extdata_record, ',', '='), str_to_map(xl_urldecode(extdata_record),',','=')) as extdata --pc端上报，部分加码了，部分未加码
    from
        complat_odl.stat_event
    where
        ds = '${date}'
        and hour = '${hour}'
        and appid = '33'
        and eventid in ('4635', '4636', '4637', '4638', '4639') --任务结束上报对应的eventid
--         and attribute1 <> 'mi_check'
--         and serverinfo[1] rlike '^\\\d+$'
--         and substr(peerid, 1, 15) <> '00D8617888205XS'
) as raw
;

-- create table dw_xlyun.dwd_xlyun_transfer_pc_log_h_inc (
--     server_info            array<string> comment 'serverinfo[1]为客户端ip地址'
--     , cmdid                bigint comment '命令id'
--     , appid                string comment '产品id'
--     , product_version      string comment '下载库版本号'
--     , service_name         string comment '合作方id，extdata[partnerid]'
--     , service_version      string comment '合作方版本，extdata[partnerversion/partnervesion]'
--     , peer_id              string comment 'peerid'
--     , guid                 string comment '设备id；extdata[ client_peerid]，兼容无空格键'
--     , user_id              string comment '用户id'
--     , extdata_head         string comment ''
--     , process_id           bigint comment '进程识别号'
--     , event_id             string comment '事件id'
--     , attribute1           string comment ''
--     , attribute2           string comment ''
--     , cost1                bigint comment ''
--     , cost2                bigint comment ''
--     , cost3                bigint comment ''
--     , cost4                bigint comment ''
--     , extdata_record       string comment '原始扩展字段'
--     , ts                   bigint comment '上报时间'
--     , extdata              map<string, string> comment '拓展字段map'
--     , parent_id            string comment '主任务id'
--     , seqid                string comment '分片id'
--     , ip                   string comment '客户端ip'
--     , final_result         string comment '下载结果'
--     , mode                 string comment '续传类型'
--     , file_name            string comment '文件名'
--     , file_suffix          string comment '文件后缀'
--     , file_size            bigint comment '文件大小'
--     , cdn_res_count        bigint comment 'dcdn peer资源总数'
--     , dcdn_hub_res_num     bigint comment '离线资源总数'
--     , high_res_count       bigint comment '高速资源总数'
--     , error_code           string comment '失败原因code'
--     , task_type            string comment '任务类型'
--     , hub_gcid             string comment 'hub gcid'
--     , real_gcid            string comment 'real gcid'
--     , download_time        bigint comment '下载时长'
--     , recv_bytes           bigint comment '接收字节数'
--     , vip_type             string comment '会员类型'
--     , anti_server          string comment '黄反标记'
--     , task_origin          string comment '任务来源'
--     , ref_url              string comment '访问页url'
--     , file_url             string comment '资源url原始值'
--     , global_speed         string comment '全局速度'
--     , download_strategy    bigint comment '下载策略'
--     , token                string comment 'token'
--     , error_bytes          bigint comment '错误字节数'
--     , index_extra_data     string comment '索引风控信息'
--     , jiasu_vip_speed      bigint comment '会员加速'
--     , jiasu_super_speed    bigint comment '超级加速'
--     , jiasu_smooth         bigint comment '顺畅模式加速'
--     , jiasu_zero_speed     bigint comment '0速度补速'
--     , jiasu_group          bigint comment '抱团加速'
--     , all_bytes            bigint comment '总字节数'
--     , origin_bytes         bigint comment '原始资源字节数'
--     , server_bytes         bigint comment '镜像资源字节数'
--     , phub_bytes           bigint comment 'phub字节数'
--     , phub_peer            bigint comment 'phub资源数'
--     , tracker_bytes        bigint comment 'tracker字节数'
--     , tracker_peer         bigint comment 'tracker资源数'
--     , dcdn_bytes           bigint comment 'dcdn字节数'
--     , dcdn_peer            bigint comment 'dcdn资源数'
--     , pcdn_bytes           bigint comment 'pcdn字节数'
--     , pcdn_peer            bigint comment 'pcdn资源数'
--     , bonus_bytes          bigint comment 'bonus字节数'
--     , bonus_peer           bigint comment 'bonus资源数'
--     , phub_cdn_bytes       bigint comment 'phub cdn字节数'
--     , phub_dcdn_bytes      bigint comment 'phub dcdn字节数'
--     , xphub_bytes          bigint comment '缓存peer字节数'
--     , super_pcdn_bytes     bigint comment 'super pcdn字节数'
--     , super_pcdn_peer      bigint comment 'super pcdn资源数'
--     , phub_res_peer        bigint comment 'phub资源peer数'
--     , phub_insert_peer     bigint comment '创建channel的phub数'
--     , running_task_count_avg      bigint comment '平均并发子任务数'
--     , running_user_task_count_avg bigint comment '平均并发主任务数'
--     , global_all_bytes     bigint comment '全局接收字节数'
--     , global_p2p_bytes     bigint comment '全局phub字节数'
--     , global_p2s_bytes     bigint comment '全局p2s字节数'
--     , global_bonus_bytes   bigint comment '全局bonus字节数'
--     , global_dcdn_bytes    bigint comment '全局dcdn字节数'
--     , global_origin_bytes  bigint comment '全局原始url字节数'
--     , etag                 string comment 'etag'
--     , query_all_hub_count  bigint comment '查种次数'
--     , query_all_hub_result string comment '查种结果'
--     , global_speed_target_1  bigint comment '目标配速-1'
--     , global_speed_target_64 bigint comment '目标配速-64'
--     , first_insert_pcdn_peer_time bigint comment '查peer耗时'
--     , alloc_data_buffer_fail_count bigint comment '磁盘慢限速次数'
--     , global_speed_max_in_window bigint comment '边下边测最大测速'
--     , ending_span_time     bigint comment '写入磁盘耗时'
--     , is_netdisk_fetch_task   string comment '是否网盘取回任务，extdata[isnetdiskfetchtask]'
--     , first_video_mode       string comment '点播模式，extdata[firstvideomode]'
--     , action_type          string comment '【废弃】行为：download:下载，withdraw：取回，play：点播，other：其他'
-- )
-- comment 'dwd_迅雷云_传输库_PC端任务上报_小时增量'
-- partitioned by (
--     ds string comment '日期分区'
--     , hour string comment '小时分区'
--     , platform string comment '端'
-- )
-- stored as parquet;
